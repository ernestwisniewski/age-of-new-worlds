use core::fmt;
use core::hash::{Hash, Hasher};

use aonw_domain::PlayerId;
use aonw_local_runtime::SessionStamp;
use sha2::{Digest, Sha256};

use crate::{AiRngTrace, PlannedCommand, PlanningBudget};

/// SHA-256 identity of one deterministic plan for one canonical state.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct PlanFingerprint([u8; 32]);

impl PlanFingerprint {
    pub(crate) fn for_move(
        stamp: SessionStamp,
        recipient: &PlayerId,
        request: &aonw_local_runtime::MoveUnitRequest,
    ) -> Self {
        let mut digest = Sha256::new();
        digest.update(b"aonw-ai-plan");
        hash_context(&mut digest, stamp, recipient);
        hash_move(&mut digest, request);
        Self(digest.finalize().into())
    }

    pub(crate) fn for_command(
        stamp: SessionStamp,
        recipient: &PlayerId,
        command: &PlannedCommand,
    ) -> Self {
        if let PlannedCommand::MoveUnit(request) = command {
            return Self::for_move(stamp, recipient, request);
        }
        let mut digest = Sha256::new();
        digest.update(b"aonw-ai-plan");
        hash_context(&mut digest, stamp, recipient);
        digest.update(b"runtime-command-hash\0");
        command.hash(&mut StableDigest(&mut digest));
        Self(digest.finalize().into())
    }

    /// Returns fingerprint bytes.
    #[must_use]
    pub const fn as_bytes(&self) -> &[u8; 32] {
        &self.0
    }
}

struct StableDigest<'a>(&'a mut Sha256);

impl Hasher for StableDigest<'_> {
    fn finish(&self) -> u64 {
        let bytes = self.0.clone().finalize();
        u64::from_le_bytes(bytes[..8].try_into().expect("SHA-256 prefix"))
    }

    fn write(&mut self, buffer: &[u8]) {
        self.0.update(buffer);
    }

    fn write_u8(&mut self, value: u8) {
        self.write(&[value]);
    }

    fn write_u16(&mut self, value: u16) {
        self.write(&value.to_le_bytes());
    }

    fn write_u32(&mut self, value: u32) {
        self.write(&value.to_le_bytes());
    }

    fn write_u64(&mut self, value: u64) {
        self.write(&value.to_le_bytes());
    }

    fn write_u128(&mut self, value: u128) {
        self.write(&value.to_le_bytes());
    }

    fn write_usize(&mut self, value: usize) {
        self.write_u64(u64::try_from(value).unwrap_or(u64::MAX));
    }

    fn write_i8(&mut self, value: i8) {
        self.write(&value.to_le_bytes());
    }

    fn write_i16(&mut self, value: i16) {
        self.write(&value.to_le_bytes());
    }

    fn write_i32(&mut self, value: i32) {
        self.write(&value.to_le_bytes());
    }

    fn write_i64(&mut self, value: i64) {
        self.write(&value.to_le_bytes());
    }

    fn write_i128(&mut self, value: i128) {
        self.write(&value.to_le_bytes());
    }

    fn write_isize(&mut self, value: isize) {
        self.write_i64(i64::try_from(value).expect("supported Rust targets fit isize in i64"));
    }
}

/// SHA-256 identity of deterministic search inputs, draws, result, and work.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct SearchFingerprint([u8; 32]);

impl SearchFingerprint {
    pub(crate) fn for_search(input: SearchFingerprintInput<'_>) -> Self {
        let mut digest = Sha256::new();
        digest.update(b"aonw-ai-search");
        hash_text(&mut digest, input.strategy);
        hash_context(&mut digest, input.stamp, input.recipient);
        digest.update(input.base_seed.to_le_bytes());
        match input.budget {
            Some(budget) => {
                digest.update([1]);
                digest.update(budget.iterations().to_le_bytes());
                digest.update(budget.max_nodes().to_le_bytes());
                digest.update(budget.max_depth().to_le_bytes());
            }
            None => digest.update([0]),
        }
        digest.update(input.trace.initial_state().to_le_bytes());
        digest.update(input.trace.final_state().to_le_bytes());
        digest.update(
            u64::try_from(input.trace.draws().len())
                .unwrap_or(u64::MAX)
                .to_le_bytes(),
        );
        for draw in input.trace.draws() {
            digest.update(draw.to_le_bytes());
        }
        digest.update(
            u64::try_from(input.counters.len())
                .unwrap_or(u64::MAX)
                .to_le_bytes(),
        );
        for counter in input.counters {
            digest.update(counter.to_le_bytes());
        }
        digest.update(input.plan.as_bytes());
        Self(digest.finalize().into())
    }

    /// Returns fingerprint bytes.
    #[must_use]
    pub const fn as_bytes(&self) -> &[u8; 32] {
        &self.0
    }
}

#[derive(Clone, Copy)]
pub(crate) struct SearchFingerprintInput<'a> {
    pub(crate) stamp: SessionStamp,
    pub(crate) recipient: &'a PlayerId,
    pub(crate) strategy: &'a str,
    pub(crate) base_seed: u32,
    pub(crate) budget: Option<PlanningBudget>,
    pub(crate) trace: &'a AiRngTrace,
    pub(crate) counters: &'a [u64],
    pub(crate) plan: PlanFingerprint,
}

impl fmt::Display for SearchFingerprint {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        write_hex(formatter, &self.0)
    }
}

impl fmt::Display for PlanFingerprint {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        write_hex(formatter, &self.0)
    }
}

fn hash_context(digest: &mut Sha256, stamp: SessionStamp, recipient: &PlayerId) {
    digest.update(stamp.revision.get().to_le_bytes());
    digest.update(stamp.state_digest.as_bytes());
    digest.update(stamp.map_hash.as_bytes());
    digest.update(stamp.ruleset_hash.as_bytes());
    hash_text(digest, recipient.as_str());
}

fn hash_move(digest: &mut Sha256, request: &aonw_local_runtime::MoveUnitRequest) {
    digest.update(b"moveUnit\0");
    digest.update(request.expected_revision.to_le_bytes());
    hash_text(digest, request.unit_id.as_str());
    digest.update(request.target.col().to_le_bytes());
    digest.update(request.target.row().to_le_bytes());
}

fn hash_text(digest: &mut Sha256, value: &str) {
    hash_bytes(digest, value.as_bytes());
}

fn hash_bytes(digest: &mut Sha256, value: &[u8]) {
    digest.update(u64::try_from(value.len()).unwrap_or(u64::MAX).to_le_bytes());
    digest.update(value);
}

fn write_hex(formatter: &mut fmt::Formatter<'_>, bytes: &[u8; 32]) -> fmt::Result {
    for byte in bytes {
        write!(formatter, "{byte:02x}")?;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use core::hash::{Hash, Hasher};

    use aonw_domain::{HexCoord, UnitId};
    use aonw_local_runtime::MoveUnitRequest;
    use sha2::{Digest, Sha256};

    use super::{PlannedCommand, StableDigest};

    #[test]
    fn stable_command_hash_is_repeatable() {
        let command = PlannedCommand::MoveUnit(MoveUnitRequest {
            expected_revision: 7,
            unit_id: UnitId::new("unit-1").expect("unit"),
            target: HexCoord::new(-2, 4),
        });
        let mut first = Sha256::new();
        command.hash(&mut StableDigest(&mut first));
        let mut second = Sha256::new();
        command.hash(&mut StableDigest(&mut second));
        assert_eq!(first.finalize(), second.finalize());
    }

    #[test]
    fn stable_digest_exposes_a_repeatable_prefix() {
        let mut digest = Sha256::new();
        let mut writer = StableDigest(&mut digest);
        writer.write(b"plan");
        writer.write_u8(1);
        writer.write_u16(2);
        writer.write_u32(3);
        writer.write_u64(4);
        writer.write_u128(5);
        writer.write_usize(6);
        writer.write_i8(-1);
        writer.write_i16(-2);
        writer.write_i32(-3);
        writer.write_i64(-4);
        writer.write_i128(-5);
        writer.write_isize(-6);
        assert_eq!(writer.finish(), writer.finish());
        assert_ne!(writer.finish(), 0);
    }
}
