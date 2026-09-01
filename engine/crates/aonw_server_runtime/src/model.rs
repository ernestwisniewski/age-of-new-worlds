use std::sync::Arc;

use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{GameState, PlayerId};
use aonw_engine::{
    CanonicalEngineError, CanonicalQueryError, CommandRejectionCode, CompiledMovementMap,
    CompiledMovementMapError, DomainEvent, ExecutionEvidence, QueryResult,
};
use aonw_projection::{PlayerViewPatch, PlayerViewSnapshot, RecipientDisclosure, SessionStamp};

/// Immutable map and rules compiled once and shared across server commands.
///
/// This value contains no match state. A Serverpod host may safely cache it by
/// map/ruleset identity and clone the handle for concurrent transactions.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PreparedServerWorld {
    compiled: Arc<CompiledMovementMap>,
}

impl PreparedServerWorld {
    /// Validates immutable content and prepares all reusable movement data.
    ///
    /// # Errors
    ///
    /// Returns an error when immutable content identity cannot be computed.
    pub fn try_new(
        map: MapDefinition,
        ruleset: RulesetDefinition,
    ) -> Result<Self, CompiledMovementMapError> {
        CompiledMovementMap::compile_owned(map, ruleset).map(|compiled| Self {
            compiled: Arc::new(compiled),
        })
    }

    /// Returns the exact immutable map identity.
    #[must_use]
    pub fn map_hash(&self) -> aonw_content::ContentHash {
        self.compiled.map_hash()
    }

    /// Returns the exact immutable ruleset identity.
    #[must_use]
    pub fn ruleset_hash(&self) -> aonw_content::ContentHash {
        self.compiled.ruleset_hash()
    }

    pub(crate) fn compiled(&self) -> &CompiledMovementMap {
        &self.compiled
    }
}

/// Complete trusted input for one authenticated simultaneous-turn submission.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct SubmitTurnRequest {
    /// Canonical state locked by the server transaction.
    pub state: GameState,
    /// Immutable map and rules prepared outside the match transaction.
    pub world: PreparedServerWorld,
    /// Player identity derived from the authenticated server session.
    pub authenticated_actor: PlayerId,
    /// Revision supplied by the remote command.
    pub expected_revision: u64,
    /// Durable offset immediately before this command.
    pub initial_event_offset: u64,
}

/// Recipient-safe output ready for persistence and delivery by the server.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct RecipientOutcome {
    /// Recipient derived from canonical match participants.
    pub recipient_player_id: PlayerId,
    /// Complete post-command view used by reconnect and resynchronization.
    pub snapshot: PlayerViewSnapshot,
    /// Delta from the request state to the returned state.
    pub patch: PlayerViewPatch,
    /// Ordered events safe to disclose to this recipient.
    pub events: Box<[DomainEvent]>,
    pub(crate) disclosure: RecipientDisclosure,
}

/// All-or-nothing result returned to the transactional Serverpod boundary.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ServerCommandOutcome {
    /// Unchanged rejected state or accepted next canonical state.
    pub state: GameState,
    /// Stable player-facing rejection, absent for an accepted command.
    pub rejection: Option<CommandRejectionCode>,
    /// Full authoritative events for server-side persistence.
    pub events: Box<[DomainEvent]>,
    /// Full execution evidence for server-side persistence and diagnostics.
    pub evidence: Option<ExecutionEvidence>,
    /// Canonical identity and immutable-content hashes.
    pub stamp: SessionStamp,
    /// Durable offset immediately before the command.
    pub initial_event_offset: u64,
    /// Durable offset immediately after the command.
    pub final_event_offset: u64,
    /// Projection, patch, and filtered events for every canonical participant.
    pub recipients: Box<[RecipientOutcome]>,
}

/// Recipient-safe result from one stateless authenticated query.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ServerPlayerQueryOutcome {
    /// Canonical identity used by the query result.
    pub stamp: SessionStamp,
    /// Engine-owned query result before strict client encoding.
    pub result: QueryResult,
}

/// Failure while executing a stateless authenticated query.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum ServerPlayerQueryError {
    /// Canonical state, content, or actor failed host validation.
    Host(ServerHostError),
    /// Deterministic game rules rejected the read-only query.
    Query(CanonicalQueryError),
}

impl core::fmt::Display for ServerPlayerQueryError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::Host(source) => source.fmt(formatter),
            Self::Query(source) => source.fmt(formatter),
        }
    }
}

impl std::error::Error for ServerPlayerQueryError {}

/// Failure before an outcome can be safely persisted.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum ServerHostError {
    /// Canonical multiplayer state has no participants.
    EmptyParticipants,
    /// The authenticated account does not own a participant in this match.
    UnknownAuthenticatedActor(PlayerId),
    /// Canonical state bounds do not match immutable map content.
    MapBoundsMismatch,
    /// Canonical occupancy policy does not match immutable rules.
    OccupancyPolicyMismatch,
    /// The maximum possible event range cannot fit in the durable offset.
    EventOffsetOverflow,
    /// The engine emitted more events than the reviewed command budget permits.
    EventBudgetExceeded {
        /// Reviewed maximum for this command and state.
        maximum: u64,
        /// Actual event count returned by the engine.
        actual: u64,
    },
    /// Immutable movement content could not be prepared.
    CompiledMovementMap(CompiledMovementMapError),
    /// Recipient economy projection could not be computed.
    Projection(CanonicalQueryError),
    /// The engine encountered corrupt canonical state or content.
    Engine(CanonicalEngineError),
}

impl core::fmt::Display for ServerHostError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::EmptyParticipants => formatter.write_str("match has no participants"),
            Self::UnknownAuthenticatedActor(actor) => write!(
                formatter,
                "authenticated actor `{actor}` is not a participant"
            ),
            Self::MapBoundsMismatch => {
                formatter.write_str("canonical state and map bounds do not match")
            }
            Self::OccupancyPolicyMismatch => {
                formatter.write_str("canonical state and rules occupancy do not match")
            }
            Self::EventOffsetOverflow => formatter.write_str("event offset overflow"),
            Self::EventBudgetExceeded { maximum, actual } => write!(
                formatter,
                "event budget exceeded: maximum {maximum}, actual {actual}"
            ),
            Self::CompiledMovementMap(source) => source.fmt(formatter),
            Self::Projection(source) => write!(formatter, "recipient projection failed: {source}"),
            Self::Engine(source) => source.fmt(formatter),
        }
    }
}

impl std::error::Error for ServerHostError {}

/// Validates canonical state against immutable content before host execution.
pub(crate) fn validate_state(
    state: &GameState,
    world: &PreparedServerWorld,
) -> Result<(), ServerHostError> {
    if state.match_lifecycle().identity().participants().is_empty() {
        return Err(ServerHostError::EmptyParticipants);
    }
    if state.bounds() != world.compiled().bounds() {
        return Err(ServerHostError::MapBoundsMismatch);
    }
    if state.occupancy_policy() != world.compiled().ruleset().occupancy_policy() {
        return Err(ServerHostError::OccupancyPolicyMismatch);
    }
    Ok(())
}
