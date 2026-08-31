use serde::{Deserialize, Serialize};

use crate::client::WorkerAutomationOptionDto;
use crate::{CombatExecutionDto, CoordinateDto, GameStateDto, MovementStepDto};

mod codec;
mod command;
mod event;
mod logistics;

pub use command::{ReplayCommandDto, ReplaySystemCommandDto};
pub use event::ReplayEventDto;
pub use logistics::{ReplayLogisticsEvidenceDto, ReplayUnitMovementExecutionDto};

/// Maximum accepted encoded save document.
pub const MAX_SAVE_GAME_JSON_BYTES: usize = 16 * 1024 * 1024;
/// Maximum accepted encoded replay document.
pub const MAX_REPLAY_LOG_JSON_BYTES: usize = 64 * 1024 * 1024;
/// Maximum commands retained in one replay segment.
pub const MAX_REPLAY_ENTRY_COUNT: usize = 512;
/// Maximum self-contained replay segments retained in one archive.
pub const MAX_REPLAY_SEGMENT_COUNT: usize = 8;
/// Durable save and replay schema version.
pub const PERSISTENCE_FORMAT_VERSION: u16 = 2;

/// Complete canonical save envelope.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct SaveGameDto {
    /// Durable envelope schema version, independent from the client API.
    pub format_version: u16,
    /// Engine behavior identity required to interpret this snapshot.
    pub behavior_fingerprint: String,
    /// Logical map identifier.
    pub map_id: String,
    /// SHA-256 identity of canonical map content.
    pub map_hash: String,
    /// Ruleset identifier.
    pub ruleset_id: String,
    /// SHA-256 identity of immutable rules.
    pub ruleset_hash: String,
    /// Local player whose recipient view is opened.
    pub actor_player_id: String,
    /// Number of authoritative events preceding this snapshot.
    pub event_offset: u64,
    /// Digest of the complete canonical state.
    pub state_digest: String,
    /// Complete canonical game state.
    pub state: GameStateDto,
}

/// Closed replay record boundary distinguishing player and trusted system input.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "recordKind",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ReplayRecordDto {
    /// Authenticated player-authored command.
    Player {
        /// Closed player command payload.
        command: ReplayCommandDto,
    },
    /// Host/scheduler-authored command unavailable to player endpoints.
    System {
        /// Closed trusted command payload.
        command: ReplaySystemCommandDto,
    },
}

/// Trusted command context recorded before execution.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ReplayContextDto {
    /// Authenticated actor for player records; absent for trusted system records.
    pub actor_player_id: Option<String>,
    /// Exact canonical map identity.
    pub map_hash: String,
    /// Exact immutable ruleset identity.
    pub ruleset_hash: String,
    /// State digest before execution.
    pub state_digest: String,
    /// Event offset before execution.
    pub event_offset: u64,
}

/// Exact execution evidence stored in a replay result.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ReplayEvidenceDto {
    /// Exact combat evidence.
    Combat {
        /// Exact combat execution.
        execution: CombatExecutionDto,
    },
    /// Executed movement prefix.
    UnitMovement {
        /// Moved unit.
        unit_id: String,
        /// Position before execution.
        from: CoordinateDto,
        /// Exact executed movement steps.
        steps: Vec<MovementStepDto>,
    },
    /// Exact auto-exploration, merchant, or detachment execution.
    Logistics {
        /// Typed logistics execution.
        execution: ReplayLogisticsEvidenceDto,
    },
    /// Exact partial turn pipeline that executed.
    TurnKernel {
        /// Processor names in execution order.
        processors: Vec<String>,
        /// Cities founded during the pipeline in canonical order.
        founded_city_ids: Vec<String>,
        /// Exact intended-attack resolutions in execution order.
        combat_executions: Vec<CombatExecutionDto>,
        /// Units whose movement phase began, in canonical unit order.
        reset_unit_ids: Vec<String>,
        /// Exact movements performed by turn processors.
        movement_executions: Vec<ReplayUnitMovementExecutionDto>,
        /// Units whose stored movement order became invalid.
        invalidated_order_unit_ids: Vec<String>,
        /// Scouts whose auto-exploration ended without another target.
        finished_auto_explore_unit_ids: Vec<String>,
    },
    /// Exact worker automation execution.
    WorkerAutomation {
        /// Worker receiving the command.
        unit_id: String,
        /// Selected action and deterministic counters.
        option: WorkerAutomationOptionDto,
        /// Executed movement prefix, when any.
        movement: Option<ReplayUnitMovementExecutionDto>,
    },
}

/// Deterministic outcome expected after replaying one command.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ReplayResultDto {
    /// Whether the command was accepted.
    pub accepted: bool,
    /// Stable rejection code when not accepted.
    pub rejection: Option<String>,
    /// Canonical revision after execution.
    pub revision: u64,
    /// Canonical state digest after execution.
    pub state_digest: String,
    /// Ordered authoritative events.
    pub events: Vec<ReplayEventDto>,
    /// Exact execution evidence when produced.
    pub evidence: Option<ReplayEvidenceDto>,
    /// Event offset after execution.
    pub event_offset: u64,
    /// Hash of the exact recipient-safe client command result.
    pub recipient_result_hash: String,
}

/// One deterministic replay step.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ReplayEntryDto {
    /// Zero-based index within this replay segment.
    pub index: u64,
    /// Complete trusted context before execution.
    pub context: ReplayContextDto,
    /// Explicit player or trusted system record.
    pub record: ReplayRecordDto,
    /// Exact authoritative result.
    pub result: ReplayResultDto,
}

/// One self-contained deterministic replay segment and its restore checkpoint.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ReplaySegmentDto {
    /// Event offset at the segment start.
    pub initial_event_offset: u64,
    /// Digest of the initial canonical state.
    pub initial_state_digest: String,
    /// Complete initial canonical state.
    pub initial_state: GameStateDto,
    /// Commands and exact expected outcomes.
    pub entries: Vec<ReplayEntryDto>,
}

/// Bounded replay archive ordered from oldest to newest segment.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ReplayLogDto {
    /// Durable envelope schema version, independent from the client API.
    pub format_version: u16,
    /// Engine behavior identity required to replay this archive.
    pub behavior_fingerprint: String,
    /// Logical map identifier.
    pub map_id: String,
    /// SHA-256 identity of canonical map content.
    pub map_hash: String,
    /// Ruleset identifier.
    pub ruleset_id: String,
    /// SHA-256 identity of immutable rules.
    pub ruleset_hash: String,
    /// Actor used by every recorded context.
    pub actor_player_id: String,
    /// Ordered self-contained replay segments with canonical checkpoints.
    pub segments: Vec<ReplaySegmentDto>,
}

/// Strict save or replay codec failure.
#[derive(Debug)]
pub enum PersistenceCodecError {
    /// Input exceeds its contract byte boundary.
    TooLarge {
        /// Actual input size.
        actual: usize,
        /// Maximum accepted size.
        maximum: usize,
    },
    /// The durable envelope uses another schema version.
    UnsupportedFormatVersion {
        /// Version found in the document.
        found: u16,
        /// Version supported by this build.
        supported: u16,
    },
    /// Replay contains too many commands.
    TooManyReplayEntries {
        /// Actual command count.
        actual: usize,
        /// Maximum accepted command count.
        maximum: usize,
    },
    /// Replay archive does not contain a restore checkpoint.
    EmptyReplayArchive,
    /// Replay archive contains too many retained segments.
    TooManyReplaySegments {
        /// Actual segment count.
        actual: usize,
        /// Maximum accepted segment count.
        maximum: usize,
    },
    /// JSON violates the strict DTO contract.
    Json(serde_json::Error),
}

impl core::fmt::Display for PersistenceCodecError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::TooLarge { actual, maximum } => {
                write!(
                    formatter,
                    "document is {actual} bytes; maximum is {maximum}"
                )
            }
            Self::UnsupportedFormatVersion { found, supported } => write!(
                formatter,
                "unsupported persistence format {found}; expected {supported}"
            ),
            Self::TooManyReplayEntries { actual, maximum } => write!(
                formatter,
                "replay has {actual} entries; maximum is {maximum}"
            ),
            Self::EmptyReplayArchive => formatter.write_str("replay archive has no segments"),
            Self::TooManyReplaySegments { actual, maximum } => write!(
                formatter,
                "replay archive has {actual} segments; maximum is {maximum}"
            ),
            Self::Json(source) => source.fmt(formatter),
        }
    }
}

impl std::error::Error for PersistenceCodecError {}

#[cfg(test)]
mod tests;
