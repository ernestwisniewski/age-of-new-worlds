use core::num::NonZeroU32;

use aonw_domain::{AiPlayer, GameMode, PlayerId, PlayerKind};

use crate::{ActorHandoffError, CommandResult, LocalRuntime, RuntimeError, SessionStamp};

/// Largest reviewed number of authoritative commands in one AI turn request.
pub const MAX_AI_TURN_COMMAND_BUDGET: u32 = 1_024;

/// Framework-neutral port used by the runtime client protocol to execute AI.
///
/// The implementation lives in `aonw_ai`, keeping the dependency direction
/// from planners toward the runtime and avoiding a crate cycle.
pub trait AiTurnDriver {
    /// Executes a bounded complete turn through public runtime commands.
    ///
    /// # Errors
    ///
    /// Returns a stable diagnostic without exposing canonical state.
    fn play_turn(
        &mut self,
        runtime: &mut LocalRuntime,
        configuration: AiPlayer,
        command_budget: NonZeroU32,
    ) -> Result<AiTurnExecution, Box<str>>;
}

/// Summary of one bounded AI turn.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct AiTurnExecution {
    /// Final authoritative session identity.
    pub stamp: SessionStamp,
    /// Number of normal authoritative commands executed by the planner.
    pub executed_commands: u32,
    /// Whether the planner reached a lifecycle command ending the turn.
    pub completed_turn: bool,
}

/// AI execution and command frames for the recipient watching the turn.
#[derive(Clone, Debug)]
pub struct ObservedAiTurn {
    /// Participant whose projection and disclosure policy each frame uses.
    pub recipient_player_id: PlayerId,
    /// Authoritative driver summary.
    pub execution: AiTurnExecution,
    /// Ordered runtime results; wire encoding applies each disclosure policy.
    pub commands: Box<[CommandResult]>,
}

/// Failure while preparing or executing one AI-controlled turn.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum AiTurnError {
    /// The caller requested more work than one runtime call may perform.
    CommandBudgetTooLarge {
        /// Largest accepted command count.
        maximum: u32,
    },
    /// No local session is open.
    SessionNotOpen,
    /// A prior internal failure invalidated the session.
    SessionPoisoned,
    /// AI execution is only available for local hot-seat ownership.
    NotHotSeat,
    /// Requested participant is absent from the match.
    UnknownPlayer(PlayerId),
    /// Requested participant is human-controlled.
    HumanPlayer(PlayerId),
    /// AI participant does not carry deterministic planner configuration.
    MissingConfiguration(PlayerId),
    /// Recipient handoff failed before planner execution.
    Handoff(ActorHandoffError),
    /// The injected planner failed.
    Driver(Box<str>),
    /// Preparing the observing recipient failed.
    Observation(RuntimeError),
}

impl core::fmt::Display for AiTurnError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::CommandBudgetTooLarge { maximum } => {
                write!(formatter, "AI command budget must not exceed {maximum}")
            }
            Self::SessionNotOpen => formatter.write_str("session is not open"),
            Self::SessionPoisoned => {
                formatter.write_str("session was invalidated by a prior internal failure")
            }
            Self::NotHotSeat => formatter.write_str("AI turn requires a local hot-seat match"),
            Self::UnknownPlayer(player) => write!(formatter, "unknown AI participant: {player}"),
            Self::HumanPlayer(player) => {
                write!(formatter, "participant is human-controlled: {player}")
            }
            Self::MissingConfiguration(player) => {
                write!(formatter, "AI participant has no configuration: {player}")
            }
            Self::Handoff(source) => source.fmt(formatter),
            Self::Driver(source) => write!(formatter, "AI driver failed: {source}"),
            Self::Observation(source) => source.fmt(formatter),
        }
    }
}

impl std::error::Error for AiTurnError {}

impl LocalRuntime {
    /// Executes an AI turn with command frames for the current recipient.
    ///
    /// The planner sees its own projection. Frames retain a separate recipient
    /// projection and visibility before each command. Simulation clones and
    /// persisted replay records do not include observations.
    ///
    /// # Errors
    ///
    /// Returns invalid AI ownership, observer setup, or driver failures. Failed
    /// batches discard their frames; callers may restore the recipient snapshot.
    pub fn advance_ai_turn_observed(
        &mut self,
        actor: PlayerId,
        command_budget: NonZeroU32,
        driver: &mut dyn AiTurnDriver,
    ) -> Result<ObservedAiTurn, AiTurnError> {
        if command_budget.get() > MAX_AI_TURN_COMMAND_BUDGET {
            return Err(AiTurnError::CommandBudgetTooLarge {
                maximum: MAX_AI_TURN_COMMAND_BUDGET,
            });
        }
        let maximum = usize::try_from(command_budget.get()).map_err(|_| {
            AiTurnError::CommandBudgetTooLarge {
                maximum: MAX_AI_TURN_COMMAND_BUDGET,
            }
        })?;
        let recipient_player_id = self
            .start_observing_recipient(maximum)
            .map_err(AiTurnError::Observation)?;
        let execution = self.advance_ai_turn(actor, command_budget, driver);
        let commands = self.finish_observing_recipient();
        execution.map(|execution| ObservedAiTurn {
            recipient_player_id,
            execution,
            commands,
        })
    }

    /// Hands control to one configured AI participant and executes a bounded
    /// complete turn using the supplied planner port.
    ///
    /// # Errors
    ///
    /// Returns an error for invalid ownership, participant configuration, or a
    /// planner/runtime failure.
    pub fn advance_ai_turn(
        &mut self,
        actor: PlayerId,
        command_budget: NonZeroU32,
        driver: &mut dyn AiTurnDriver,
    ) -> Result<AiTurnExecution, AiTurnError> {
        if command_budget.get() > MAX_AI_TURN_COMMAND_BUDGET {
            return Err(AiTurnError::CommandBudgetTooLarge {
                maximum: MAX_AI_TURN_COMMAND_BUDGET,
            });
        }
        if self.poisoned {
            return Err(AiTurnError::SessionPoisoned);
        }
        let configuration = {
            let session = self.session.as_ref().ok_or(AiTurnError::SessionNotOpen)?;
            let identity = session.state().match_lifecycle().identity();
            if identity.game_mode() != GameMode::HotSeat {
                return Err(AiTurnError::NotHotSeat);
            }
            let participant = identity
                .participants()
                .iter()
                .find(|participant| participant.id() == &actor)
                .ok_or_else(|| AiTurnError::UnknownPlayer(actor.clone()))?;
            if participant.kind() != PlayerKind::Ai {
                return Err(AiTurnError::HumanPlayer(actor));
            }
            participant
                .ai()
                .ok_or_else(|| AiTurnError::MissingConfiguration(actor.clone()))?
        };
        self.handoff_hot_seat_actor(actor)
            .map_err(AiTurnError::Handoff)?;
        driver
            .play_turn(self, configuration, command_budget)
            .map_err(AiTurnError::Driver)
    }
}
