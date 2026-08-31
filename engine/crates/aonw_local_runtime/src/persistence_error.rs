use aonw_contract_mapping::GameStateMappingError;
use aonw_contracts::PersistenceCodecError;
use aonw_domain::IdentifierError;

use crate::{ActorHandoffError, OpenSessionError, RuntimeError};

/// Save or replay validation failure.
#[derive(Debug)]
pub enum PersistenceError {
    /// Strict JSON codec failure.
    Codec(PersistenceCodecError),
    /// JSON serialization failure.
    Serialize(String),
    /// Persisted map identifier differs from supplied content.
    MapIdMismatch,
    /// Persisted map hash differs from supplied content.
    MapHashMismatch,
    /// Persisted ruleset identifier differs from supplied content.
    RulesetIdMismatch,
    /// Persisted ruleset hash differs from supplied content.
    RulesetHashMismatch,
    /// Persisted engine behavior differs from this build.
    BehaviorFingerprintMismatch,
    /// Immutable content identity could not be computed.
    ContentHash(String),
    /// Persisted actor identifier is invalid.
    InvalidActor(IdentifierError),
    /// Persisted command player identifier is invalid.
    InvalidPlayer(IdentifierError),
    /// Persisted command unit identifier is invalid.
    InvalidUnit(IdentifierError),
    /// Persisted command city identifier is invalid.
    InvalidCity(IdentifierError),
    /// Persisted command artifact identifier is invalid.
    InvalidArtifact(IdentifierError),
    /// Persisted trusted turn time is not canonical UTC.
    InvalidTurnTime(Box<str>),
    /// Canonical state contract violates domain invariants.
    State(GameStateMappingError),
    /// Persisted state digest does not identify the decoded canonical state.
    StateDigestMismatch,
    /// Replay entry index is not contiguous.
    ReplayIndexMismatch {
        /// Zero-based replay segment.
        segment: usize,
        /// Required contiguous index.
        expected: u64,
        /// Index present in the document.
        found: u64,
    },
    /// A replay entry index cannot be represented by the wire contract.
    ReplayIndexOverflow,
    /// A segment checkpoint digest does not identify its canonical state.
    ReplayCheckpointDigestMismatch {
        /// Zero-based replay segment.
        segment: usize,
    },
    /// A segment checkpoint does not exactly continue the preceding segment.
    ReplayCheckpointMismatch {
        /// Zero-based replay segment.
        segment: usize,
    },
    /// Recorded trusted context differs from the replayed session.
    ReplayContextMismatch {
        /// Zero-based replay segment.
        segment: usize,
        /// Zero-based replay entry.
        entry: usize,
    },
    /// Recorded outcome differs from deterministic engine execution.
    ReplayResultMismatch {
        /// Zero-based replay segment.
        segment: usize,
        /// Zero-based replay entry.
        entry: usize,
    },
    /// No verified replay is currently open for playback.
    ReplayPlaybackNotOpen,
    /// Requested playback boundary lies beyond the verified replay.
    ReplayPositionOutOfBounds {
        /// Requested number of applied entries.
        requested: u64,
        /// Total number of entries in the replay.
        entry_count: u64,
    },
    /// The requested replay recipient cannot receive this local match.
    ReplayRecipient(ActorHandoffError),
    /// Session preparation failed.
    Open(OpenSessionError),
    /// Command replay failed internally.
    Runtime(RuntimeError),
}

impl core::fmt::Display for PersistenceError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::Codec(source) => source.fmt(formatter),
            Self::Serialize(source) => write!(formatter, "serialization failed: {source}"),
            Self::MapIdMismatch => formatter.write_str("save map id does not match content"),
            Self::MapHashMismatch => formatter.write_str("save map hash does not match content"),
            Self::RulesetIdMismatch => {
                formatter.write_str("save ruleset id does not match content")
            }
            Self::RulesetHashMismatch => {
                formatter.write_str("save ruleset hash does not match content")
            }
            Self::BehaviorFingerprintMismatch => {
                formatter.write_str("persistence behavior fingerprint does not match this build")
            }
            Self::ContentHash(source) => write!(formatter, "content hash failed: {source}"),
            Self::InvalidActor(source) => write!(formatter, "invalid actor: {source}"),
            Self::InvalidPlayer(source) => write!(formatter, "invalid player: {source}"),
            Self::InvalidUnit(source) => write!(formatter, "invalid unit: {source}"),
            Self::InvalidCity(source) => write!(formatter, "invalid city: {source}"),
            Self::InvalidArtifact(source) => write!(formatter, "invalid artifact: {source}"),
            Self::InvalidTurnTime(source) => write!(formatter, "invalid turn time: {source}"),
            Self::State(source) => write!(formatter, "invalid canonical state: {source}"),
            Self::StateDigestMismatch => {
                formatter.write_str("state digest does not match canonical state")
            }
            Self::ReplayIndexMismatch {
                segment,
                expected,
                found,
            } => write!(
                formatter,
                "replay segment {segment} entry index {found} is not the expected index {expected}"
            ),
            Self::ReplayIndexOverflow => {
                formatter.write_str("replay entry index exceeds the wire integer range")
            }
            Self::ReplayCheckpointDigestMismatch { segment } => write!(
                formatter,
                "replay checkpoint digest differs at segment {segment}"
            ),
            Self::ReplayCheckpointMismatch { segment } => {
                write!(
                    formatter,
                    "replay checkpoint chain differs at segment {segment}"
                )
            }
            Self::ReplayContextMismatch { segment, entry } => {
                write!(
                    formatter,
                    "replay context differs at segment {segment} entry {entry}"
                )
            }
            Self::ReplayResultMismatch { segment, entry } => {
                write!(
                    formatter,
                    "replay result differs at segment {segment} entry {entry}"
                )
            }
            Self::ReplayPlaybackNotOpen => formatter.write_str("replay playback is not open"),
            Self::ReplayPositionOutOfBounds {
                requested,
                entry_count,
            } => write!(
                formatter,
                "replay position {requested} exceeds entry count {entry_count}"
            ),
            Self::ReplayRecipient(source) => {
                write!(formatter, "invalid replay recipient: {source}")
            }
            Self::Open(source) => source.fmt(formatter),
            Self::Runtime(source) => source.fmt(formatter),
        }
    }
}

impl std::error::Error for PersistenceError {}

#[cfg(test)]
mod tests {
    use super::PersistenceError;

    #[test]
    fn segmented_replay_errors_identify_the_exact_drift_location() {
        assert_eq!(
            PersistenceError::ReplayCheckpointDigestMismatch { segment: 2 }.to_string(),
            "replay checkpoint digest differs at segment 2"
        );
        assert_eq!(
            PersistenceError::ReplayCheckpointMismatch { segment: 3 }.to_string(),
            "replay checkpoint chain differs at segment 3"
        );
        assert_eq!(
            PersistenceError::ReplayContextMismatch {
                segment: 4,
                entry: 5,
            }
            .to_string(),
            "replay context differs at segment 4 entry 5"
        );
        assert_eq!(
            PersistenceError::ReplayResultMismatch {
                segment: 6,
                entry: 7,
            }
            .to_string(),
            "replay result differs at segment 6 entry 7"
        );
    }
}
