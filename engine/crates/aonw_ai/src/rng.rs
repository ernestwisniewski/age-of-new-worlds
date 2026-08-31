use core::num::NonZeroUsize;

use aonw_domain::PlayerId;

const MULTIPLIER: u32 = 1_664_525;
const INCREMENT: u32 = 1_013_904_223;

/// Explicit deterministic LCG32 stream used only for AI planning.
///
/// The seed derivation and draw transition define the deterministic AI contract. The
/// type is immutable so every draw makes the next state and value explicit.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct AiRng {
    state: u32,
}

impl AiRng {
    /// Starts a stream from one explicit normalized seed.
    #[must_use]
    pub const fn new(seed: u32) -> Self {
        Self { state: seed }
    }

    /// Derives one AI stream from the authoritative turn, recipient, and seed.
    #[must_use]
    pub fn from_turn(turn: u32, player_id: &PlayerId, base_seed: u32) -> Self {
        let mut hash = mix32(base_seed);
        hash = mix32(hash ^ turn);
        for code_unit in player_id.as_str().encode_utf16() {
            hash = mix32(hash ^ u32::from(code_unit));
        }
        Self::new(hash)
    }

    /// Advances the stream once and returns a bounded index.
    #[must_use]
    pub fn next_index(self, maximum: NonZeroUsize) -> AiRngDraw {
        let next_state = self.state.wrapping_mul(MULTIPLIER).wrapping_add(INCREMENT);
        AiRngDraw {
            rng: Self::new(next_state),
            value: usize::try_from(next_state).unwrap_or(usize::MAX) % maximum.get(),
        }
    }

    /// Returns the normalized 32-bit stream state.
    #[must_use]
    pub const fn state(self) -> u32 {
        self.state
    }
}

/// One ordered AI RNG draw and the advanced stream.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct AiRngDraw {
    rng: AiRng,
    value: usize,
}

impl AiRngDraw {
    /// Returns the advanced immutable stream.
    #[must_use]
    pub const fn rng(self) -> AiRng {
        self.rng
    }

    /// Returns the selected zero-based index.
    #[must_use]
    pub const fn value(self) -> usize {
        self.value
    }
}

/// Complete bounded evidence for one planner's ordered AI draws.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct AiRngTrace {
    initial_state: u32,
    final_state: u32,
    draws: Box<[u32]>,
}

impl AiRngTrace {
    pub(crate) fn new(initial_state: u32, final_state: u32, draws: Vec<u32>) -> Self {
        Self {
            initial_state,
            final_state,
            draws: draws.into_boxed_slice(),
        }
    }

    /// Returns the stream state before the first draw.
    #[must_use]
    pub const fn initial_state(&self) -> u32 {
        self.initial_state
    }

    /// Returns the stream state after the final draw.
    #[must_use]
    pub const fn final_state(&self) -> u32 {
        self.final_state
    }

    /// Returns every raw post-transition state in draw order.
    #[must_use]
    pub const fn draws(&self) -> &[u32] {
        &self.draws
    }
}

pub(crate) fn draw_index(rng: &mut AiRng, maximum: NonZeroUsize, draws: &mut Vec<u32>) -> usize {
    let draw = rng.next_index(maximum);
    *rng = draw.rng();
    draws.push(rng.state());
    draw.value()
}

const fn mix32(mut hash: u32) -> u32 {
    hash ^= hash >> 16;
    hash = hash.wrapping_mul(0x7FEB_352D);
    hash ^= hash >> 15;
    hash = hash.wrapping_mul(0x846C_A68B);
    hash ^ (hash >> 16)
}

#[cfg(test)]
mod tests {
    use super::{AiRng, NonZeroUsize};
    use aonw_domain::PlayerId;

    #[test]
    fn direct_seed_produces_expected_lcg32_draws() {
        let first = AiRng::new(42).next_index(NonZeroUsize::new(3).expect("positive"));
        assert_eq!(first.rng().state(), 1_083_814_273);
        assert_eq!(first.value(), 1);

        let second = first
            .rng()
            .next_index(NonZeroUsize::new(100).expect("positive"));
        assert_eq!(second.rng().state(), 378_494_188);
        assert_eq!(second.value(), 88);
    }

    #[test]
    fn turn_derivation_matches_the_utf16_reference_vector() {
        let player = PlayerId::new("player_2").expect("player id");
        assert_eq!(AiRng::from_turn(7, &player, 99).state(), 2_385_559_860);

        let non_bmp = PlayerId::new("ai_🚀").expect("player id");
        assert_eq!(AiRng::from_turn(17, &non_bmp, 5).state(), 1_237_866_286);
    }
}
