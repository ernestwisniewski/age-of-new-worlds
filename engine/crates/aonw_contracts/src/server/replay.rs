use serde::{Deserialize, Serialize};

use super::{ServerHostCodecError, codec::parse_bounded};
use crate::client::{
    ClientCommandDto, ClientCommandResultDto, ClientSessionStampDto, PlayerViewSnapshotDto,
};
use crate::{GameStateDto, ReplaySystemCommandDto};

/// Maximum transitions evaluated in one stateless replay request.
pub const MAX_SERVER_REPLAY_BATCH_STEPS: usize = 256;

/// Trusted server-only checkpoint and journal slice. Never sent to a player.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ServerReplayBatchRequestDto {
    /// Independently deployed host version.
    pub api_version: u16,
    /// Immutable map identity.
    pub map_hash: String,
    /// Immutable rules identity.
    pub ruleset_hash: String,
    /// Behavior identity recorded when the match was created.
    pub behavior_fingerprint: String,
    /// Initial or previously verified canonical checkpoint.
    pub initial_state: GameStateDto,
    /// Expected checkpoint digest.
    pub initial_state_digest: String,
    /// Durable offset at the checkpoint.
    pub initial_event_offset: u64,
    /// Participant selected by authenticated durable membership.
    pub recipient_player_id: String,
    /// Consecutive accepted transitions after the checkpoint.
    pub steps: Vec<ServerReplayStepDto>,
}

/// One transition with independently persisted evidence.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ServerReplayStepDto {
    /// Actual authenticated player or trusted system command.
    pub record: ServerReplayRecordDto,
    /// Expected resulting revision.
    pub revision: u64,
    /// Expected resulting canonical digest.
    pub state_digest: String,
    /// Expected offset before execution.
    pub initial_event_offset: u64,
    /// Expected offset after execution.
    pub final_event_offset: u64,
}

/// Explicit trust boundary retained by the durable server journal.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "kind",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ServerReplayRecordDto {
    /// Authenticated player input.
    Player {
        /// Server-bound actor, independent of command contents.
        actor_player_id: String,
        /// Closed player command.
        command: ClientCommandDto,
    },
    /// Trusted lifecycle input, including exact timeout context.
    System {
        /// Closed system command.
        command: ReplaySystemCommandDto,
    },
}

/// Verified server-only continuation plus a single recipient's presentation.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ServerReplayBatchResultDto {
    /// Canonical continuation retained exclusively by the server.
    pub state: GameStateDto,
    /// Verified final identity.
    pub stamp: ClientSessionStampDto,
    /// Verified final durable offset.
    pub final_event_offset: u64,
    /// Recipient associated with every presentation value.
    pub recipient_player_id: String,
    /// Recipient-safe final snapshot.
    pub snapshot: PlayerViewSnapshotDto,
    /// Last transition for single-step animation; absent for an empty batch.
    pub command: Option<ClientCommandResultDto>,
}

impl ServerReplayBatchRequestDto {
    /// Parses a bounded strict host request.
    ///
    /// # Errors
    /// Returns an error for oversized or structurally invalid JSON.
    pub fn from_json(input: &str) -> Result<Self, ServerHostCodecError> {
        parse_bounded(input)
    }
}
