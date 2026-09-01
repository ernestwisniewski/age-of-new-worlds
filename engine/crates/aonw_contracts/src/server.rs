//! Strict DTOs for the stateless multiplayer host boundary.

use serde::{Deserialize, Serialize};

use crate::client::{
    ClientCommandDto, ClientCommandRejectionCodeDto, ClientErrorDto, ClientEventDto,
    ClientEvidenceDto, ClientQueryDto, ClientQueryResultDto, ClientSessionStampDto,
    PlayerViewPatchDto, PlayerViewSnapshotDto,
};
use crate::{GameStateDto, MatchIdentityDto, ReplaySystemCommandDto};

/// The only stateless server-host protocol version accepted by this build.
pub const SERVER_HOST_API_VERSION: u16 = 1;
/// Maximum accepted native host request, including one canonical state.
pub const MAX_SERVER_HOST_REQUEST_JSON_BYTES: usize = 32 * 1024 * 1024;
/// Maximum emitted native host response, including all recipient projections.
pub const MAX_SERVER_HOST_RESPONSE_JSON_BYTES: usize = 64 * 1024 * 1024;

/// Strict request for preparing reusable immutable map and rules content.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PrepareServerWorldRequestDto {
    /// Independently deployed server-host protocol version.
    pub api_version: u16,
    /// Strict current authored map document.
    pub map_document: String,
    /// Current immutable ruleset identifier.
    pub ruleset_id: String,
}

/// Strict request for projecting one canonical state for every participant.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ProjectServerStateRequestDto {
    /// Independently deployed server-host protocol version.
    pub api_version: u16,
    /// Exact map identity stored with the match row.
    pub map_hash: String,
    /// Exact ruleset identity stored with the match row.
    pub ruleset_hash: String,
    /// Canonical state validated by the prepared immutable world.
    pub state: GameStateDto,
}

/// Strict request for constructing a new authoritative multiplayer match.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct CreateServerMatchRequestDto {
    /// Independently deployed server-host protocol version.
    pub api_version: u16,
    /// Exact map identity returned while preparing immutable content.
    pub map_hash: String,
    /// Exact ruleset identity returned while preparing immutable content.
    pub ruleset_hash: String,
    /// Strict current scenario document used only by Rust.
    pub scenario_document: String,
    /// Immutable participants, rules, and multiplayer mode.
    pub match_identity: MatchIdentityDto,
    /// Explicit global fog selection.
    pub fog_enabled: bool,
}

/// Strict request for one authenticated simultaneous-turn submission.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct SubmitTurnServerRequestDto {
    /// Independently deployed server-host protocol version.
    pub api_version: u16,
    /// Actor derived by Serverpod from its authenticated session.
    pub authenticated_actor_player_id: String,
    /// Revision supplied by the remote command.
    pub expected_revision: u64,
    /// Durable event offset immediately before this command.
    pub initial_event_offset: u64,
    /// Exact map identity stored with the match row.
    pub map_hash: String,
    /// Exact ruleset identity stored with the match row.
    pub ruleset_hash: String,
    /// Canonical state locked by the Serverpod transaction.
    pub state: GameStateDto,
}

/// Strict request for one authenticated player command.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerCommandServerRequestDto {
    /// Independently deployed server-host protocol version.
    pub api_version: u16,
    /// Actor derived by Serverpod from its authenticated session.
    pub authenticated_actor_player_id: String,
    /// Closed player command shared with local clients and replay.
    pub command: ClientCommandDto,
    /// Durable event offset immediately before this command.
    pub initial_event_offset: u64,
    /// Exact map identity stored with the match row.
    pub map_hash: String,
    /// Exact ruleset identity stored with the match row.
    pub ruleset_hash: String,
    /// Canonical state locked by the Serverpod transaction.
    pub state: GameStateDto,
}

/// Strict request for one trusted host-owned lifecycle command.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct SystemCommandServerRequestDto {
    /// Independently deployed server-host protocol version.
    pub api_version: u16,
    /// Closed system command unavailable through the player protocol.
    pub command: ReplaySystemCommandDto,
    /// Durable event offset immediately before this command.
    pub initial_event_offset: u64,
    /// Exact map identity stored with the match row.
    pub map_hash: String,
    /// Exact ruleset identity stored with the match row.
    pub ruleset_hash: String,
    /// Canonical state locked by the trusted server transaction.
    pub state: GameStateDto,
}

/// Strict request for one authenticated recipient-safe player query.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerQueryServerRequestDto {
    /// Independently deployed server-host protocol version.
    pub api_version: u16,
    /// Actor derived by Serverpod from its authenticated session.
    pub authenticated_actor_player_id: String,
    /// Closed query shared with local clients.
    pub query: ClientQueryDto,
    /// Exact map identity stored with the match row.
    pub map_hash: String,
    /// Exact ruleset identity stored with the match row.
    pub ruleset_hash: String,
    /// Canonical state loaded by the Serverpod request.
    pub state: GameStateDto,
}

/// Stable error codes emitted by the stateless native host.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum ServerHostErrorCodeDto {
    /// A pointer, UTF-8 buffer, or response handle was invalid.
    InvalidFfiArgument,
    /// Input exceeded the reviewed request bound.
    PayloadTooLarge,
    /// JSON did not match the strict current request shape.
    InvalidRequest,
    /// The independently deployed caller uses another protocol version.
    UnsupportedApiVersion,
    /// The authored map document was invalid.
    InvalidMapDocument,
    /// The authored scenario document was invalid.
    InvalidScenarioDocument,
    /// Immutable match identity violated a current domain invariant.
    InvalidMatchIdentity,
    /// A server match must use the multiplayer game mode.
    UnsupportedGameMode,
    /// A validated scenario could not be bound to the match identity.
    MatchStartFailed,
    /// Only the current reviewed immutable ruleset is accepted.
    UnsupportedRuleset,
    /// Match content identity does not match the prepared immutable world.
    ContentIdentityMismatch,
    /// Canonical DTO validation failed.
    InvalidCanonicalState,
    /// The authenticated actor identifier was invalid.
    InvalidAuthenticatedActor,
    /// Authenticated actor is not a match participant.
    UnknownAuthenticatedActor,
    /// Canonical state has no participants.
    EmptyParticipants,
    /// State bounds do not match prepared map content.
    MapBoundsMismatch,
    /// State occupancy does not match prepared rules.
    OccupancyPolicyMismatch,
    /// Durable offset arithmetic overflowed.
    EventOffsetOverflow,
    /// Engine output exceeded its reviewed event budget.
    EventBudgetExceeded,
    /// Canonical engine validation failed; nothing may be persisted.
    EngineFailure,
    /// Response serialization exceeded its reviewed bound.
    ResponseTooLarge,
    /// A panic was contained at the native ABI boundary.
    NativePanic,
}

/// Machine-readable fail-closed host error.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ServerHostErrorDto {
    /// Stable language-neutral code.
    pub code: ServerHostErrorCodeDto,
    /// Non-sensitive diagnostic for server operations.
    pub message: String,
}

/// One recipient-safe post-command delivery and resync value.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ServerRecipientOutcomeDto {
    /// Participant receiving this projection.
    pub recipient_player_id: String,
    /// Complete value for reconnect and resynchronization.
    pub snapshot: PlayerViewSnapshotDto,
    /// Exact delta from the request state.
    pub patch: PlayerViewPatchDto,
    /// Ordered events safe for this recipient.
    pub events: Vec<ClientEventDto>,
    /// Exact execution evidence filtered for this recipient.
    pub evidence: Option<ClientEvidenceDto>,
}

/// One complete recipient-safe projection used for initial delivery and resync.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ServerRecipientSnapshotDto {
    /// Participant receiving this projection.
    pub recipient_player_id: String,
    /// Complete value safe for only this recipient.
    pub snapshot: PlayerViewSnapshotDto,
}

/// Validated initial projections for one canonical state.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ServerProjectionResultDto {
    /// Canonical identity and immutable content hashes.
    pub stamp: ClientSessionStampDto,
    /// Recipient-safe snapshots for every canonical participant.
    pub recipients: Vec<ServerRecipientSnapshotDto>,
}

/// Canonical state and recipient-safe projections created atomically by Rust.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ServerCreatedMatchDto {
    /// Initial canonical state persisted only by the server.
    pub state: GameStateDto,
    /// Initial recipient-safe snapshots persisted per participant.
    pub projection: ServerProjectionResultDto,
}

/// All-or-nothing current command result for transactional persistence.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ServerCommandResultDto {
    /// Unchanged rejected state or accepted next canonical state.
    pub state: GameStateDto,
    /// Stable player-facing rejection, absent for an accepted command.
    pub rejection: Option<ClientCommandRejectionCodeDto>,
    /// Full authoritative events for server-side persistence.
    pub events: Vec<ClientEventDto>,
    /// Full execution evidence for server-side persistence and diagnostics.
    pub evidence: Option<ClientEvidenceDto>,
    /// Canonical identity and immutable content hashes.
    pub stamp: ClientSessionStampDto,
    /// Durable offset immediately before the command.
    pub initial_event_offset: u64,
    /// Durable offset immediately after the command.
    pub final_event_offset: u64,
    /// Recipient-safe outputs for every canonical participant.
    pub recipients: Vec<ServerRecipientOutcomeDto>,
}

/// Recipient-safe result or stable game rejection from one player query.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "status",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ServerPlayerQueryOutcomeDto {
    /// Query completed against the authenticated recipient context.
    Success {
        /// Exact result shape shared with local clients.
        result: Box<ClientQueryResultDto>,
    },
    /// Query was invalid or rejected without mutating canonical state.
    Failure {
        /// Stable client-facing code and diagnostic.
        error: ClientErrorDto,
    },
}

/// Successful stateless native host result.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ServerHostResponseBodyDto {
    /// Immutable content was validated and prepared.
    WorldPrepared {
        /// Exact canonical map identity.
        map_hash: String,
        /// Exact immutable rules identity.
        ruleset_hash: String,
    },
    /// One canonical state was validated and projected for its participants.
    StateProjected {
        /// Initial recipient-safe projections.
        result: Box<ServerProjectionResultDto>,
    },
    /// A new multiplayer match was constructed and projected by Rust.
    MatchCreated {
        /// Persistable initial state and recipient-safe projections.
        result: Box<ServerCreatedMatchDto>,
    },
    /// One command completed with a persistable outcome.
    CommandApplied {
        /// Transactional command result.
        result: Box<ServerCommandResultDto>,
    },
    /// One read-only authenticated query completed without retaining state.
    PlayerQueryExecuted {
        /// Recipient-safe result or stable query rejection.
        result: Box<ServerPlayerQueryOutcomeDto>,
    },
}

/// Success or contained failure returned by every native operation.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "status",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ServerHostOutcomeDto {
    /// Operation completed successfully.
    Success {
        /// Operation-specific response.
        response: Box<ServerHostResponseBodyDto>,
    },
    /// Operation failed and no state may be persisted.
    Failure {
        /// Stable error code and diagnostic.
        error: ServerHostErrorDto,
    },
}

/// Current response envelope for the native Serverpod boundary.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ServerHostResponseDto {
    /// Independently deployed server-host protocol version.
    pub api_version: u16,
    /// Successful result or contained failure.
    pub outcome: ServerHostOutcomeDto,
}

impl PrepareServerWorldRequestDto {
    /// Parses one bounded strict request.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized or structurally invalid JSON.
    pub fn from_json(input: &str) -> Result<Self, ServerHostCodecError> {
        parse_bounded(input)
    }
}

impl SubmitTurnServerRequestDto {
    /// Parses one bounded strict request.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized or structurally invalid JSON.
    pub fn from_json(input: &str) -> Result<Self, ServerHostCodecError> {
        parse_bounded(input)
    }
}

impl PlayerCommandServerRequestDto {
    /// Parses one bounded strict request.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized or structurally invalid JSON.
    pub fn from_json(input: &str) -> Result<Self, ServerHostCodecError> {
        parse_bounded(input)
    }
}

impl SystemCommandServerRequestDto {
    /// Parses one bounded strict request.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized or structurally invalid JSON.
    pub fn from_json(input: &str) -> Result<Self, ServerHostCodecError> {
        parse_bounded(input)
    }
}

impl PlayerQueryServerRequestDto {
    /// Parses one bounded strict request.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized or structurally invalid JSON.
    pub fn from_json(input: &str) -> Result<Self, ServerHostCodecError> {
        parse_bounded(input)
    }
}

impl ProjectServerStateRequestDto {
    /// Parses one bounded strict request.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized or structurally invalid JSON.
    pub fn from_json(input: &str) -> Result<Self, ServerHostCodecError> {
        parse_bounded(input)
    }
}

impl CreateServerMatchRequestDto {
    /// Parses one bounded strict request.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized or structurally invalid JSON.
    pub fn from_json(input: &str) -> Result<Self, ServerHostCodecError> {
        parse_bounded(input)
    }
}

impl ServerHostResponseDto {
    /// Serializes one bounded compact response.
    ///
    /// # Errors
    ///
    /// Returns an error if serialization fails or exceeds the response bound.
    pub fn to_json(&self) -> Result<String, ServerHostCodecError> {
        let json = serde_json::to_string(self).map_err(ServerHostCodecError::Json)?;
        if json.len() > MAX_SERVER_HOST_RESPONSE_JSON_BYTES {
            return Err(ServerHostCodecError::TooLarge {
                actual: json.len(),
                maximum: MAX_SERVER_HOST_RESPONSE_JSON_BYTES,
            });
        }
        Ok(json)
    }
}

fn parse_bounded<T: for<'de> Deserialize<'de>>(input: &str) -> Result<T, ServerHostCodecError> {
    if input.len() > MAX_SERVER_HOST_REQUEST_JSON_BYTES {
        return Err(ServerHostCodecError::TooLarge {
            actual: input.len(),
            maximum: MAX_SERVER_HOST_REQUEST_JSON_BYTES,
        });
    }
    serde_json::from_str(input).map_err(ServerHostCodecError::Json)
}

/// Strict native host JSON codec failure.
#[derive(Debug)]
pub enum ServerHostCodecError {
    /// Encoded value exceeded its reviewed byte boundary.
    TooLarge {
        /// Actual byte count.
        actual: usize,
        /// Maximum accepted byte count.
        maximum: usize,
    },
    /// JSON serialization or deserialization failed.
    Json(serde_json::Error),
}

impl core::fmt::Display for ServerHostCodecError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::TooLarge { actual, maximum } => {
                write!(formatter, "payload is {actual} bytes; maximum is {maximum}")
            }
            Self::Json(source) => source.fmt(formatter),
        }
    }
}

impl std::error::Error for ServerHostCodecError {}

#[cfg(test)]
mod tests;
