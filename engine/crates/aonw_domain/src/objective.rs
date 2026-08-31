use std::collections::BTreeMap;

use crate::{MatchIdentity, PlayerId};

/// Persisted controller and consecutive hold count for one map objective.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MapObjectiveHoldState {
    objective_id: String,
    player_id: PlayerId,
    hold_turns: u32,
}

impl MapObjectiveHoldState {
    /// Constructs one sparse positive objective hold.
    ///
    /// # Errors
    ///
    /// Returns an error when the objective identifier is blank or the hold count is zero.
    pub fn try_new(
        objective_id: String,
        player_id: PlayerId,
        hold_turns: u32,
    ) -> Result<Self, ObjectiveStateBuildError> {
        if objective_id.trim().is_empty() {
            return Err(ObjectiveStateBuildError::EmptyObjectiveId);
        }
        if hold_turns == 0 {
            return Err(ObjectiveStateBuildError::NonPositiveHoldTurns);
        }
        Ok(Self {
            objective_id,
            player_id,
            hold_turns,
        })
    }

    /// Returns the immutable content identifier of the objective.
    #[must_use]
    pub fn objective_id(&self) -> &str {
        &self.objective_id
    }

    /// Returns the player currently holding the objective.
    #[must_use]
    pub const fn player_id(&self) -> &PlayerId {
        &self.player_id
    }

    /// Returns the positive consecutive hold count.
    #[must_use]
    pub const fn hold_turns(&self) -> u32 {
        self.hold_turns
    }
}

/// Complete persisted victory-progress substrate.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct ObjectiveState {
    domination_hold_turns_by_player_id: BTreeMap<PlayerId, u32>,
    cultural_victory_hold_turns_by_player_id: BTreeMap<PlayerId, u32>,
    map_objective_hold_states: Box<[MapObjectiveHoldState]>,
}

impl ObjectiveState {
    /// Constructs and validates sparse outcome-relevant counters.
    ///
    /// # Errors
    ///
    /// Returns an error for unknown players, zero counters, or duplicate objective IDs.
    pub fn try_new(
        identity: &MatchIdentity,
        domination_hold_turns_by_player_id: BTreeMap<PlayerId, u32>,
        cultural_victory_hold_turns_by_player_id: BTreeMap<PlayerId, u32>,
        map_objective_hold_states: impl IntoIterator<Item = MapObjectiveHoldState>,
    ) -> Result<Self, ObjectiveStateBuildError> {
        let mut map_objective_hold_states =
            map_objective_hold_states.into_iter().collect::<Vec<_>>();
        map_objective_hold_states
            .sort_by(|left, right| left.objective_id().cmp(right.objective_id()));
        for pair in map_objective_hold_states.windows(2) {
            if pair[0].objective_id() == pair[1].objective_id() {
                return Err(ObjectiveStateBuildError::DuplicateObjectiveId(
                    pair[0].objective_id().to_owned(),
                ));
            }
        }
        let state = Self {
            domination_hold_turns_by_player_id,
            cultural_victory_hold_turns_by_player_id,
            map_objective_hold_states: map_objective_hold_states.into_boxed_slice(),
        };
        state.validate_for(identity)?;
        Ok(state)
    }

    /// Validates participant references and sparse positive values.
    ///
    /// # Errors
    ///
    /// Returns an error for an unknown player or a zero counter.
    pub fn validate_for(&self, identity: &MatchIdentity) -> Result<(), ObjectiveStateBuildError> {
        validate_player_holds(identity, &self.domination_hold_turns_by_player_id)?;
        validate_player_holds(identity, &self.cultural_victory_hold_turns_by_player_id)?;
        for hold in &self.map_objective_hold_states {
            if !identity.contains(hold.player_id()) {
                return Err(ObjectiveStateBuildError::PlayerNotFound(
                    hold.player_id().clone(),
                ));
            }
            if hold.hold_turns() == 0 {
                return Err(ObjectiveStateBuildError::NonPositiveHoldTurns);
            }
        }
        Ok(())
    }

    /// Returns sparse domination counters in player-ID order.
    #[must_use]
    pub const fn domination_hold_turns_by_player_id(&self) -> &BTreeMap<PlayerId, u32> {
        &self.domination_hold_turns_by_player_id
    }

    /// Returns sparse cultural-victory counters in player-ID order.
    #[must_use]
    pub const fn cultural_victory_hold_turns_by_player_id(&self) -> &BTreeMap<PlayerId, u32> {
        &self.cultural_victory_hold_turns_by_player_id
    }

    /// Returns map-objective holds in objective-ID order.
    #[must_use]
    pub const fn map_objective_hold_states(&self) -> &[MapObjectiveHoldState] {
        &self.map_objective_hold_states
    }
}

/// Structural objective-progress validation failure.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum ObjectiveStateBuildError {
    /// An objective identifier is blank.
    EmptyObjectiveId,
    /// A player reference is absent from match identity.
    PlayerNotFound(PlayerId),
    /// A sparse hold entry has value zero.
    NonPositiveHoldTurns,
    /// One objective appears more than once.
    DuplicateObjectiveId(String),
}

impl core::fmt::Display for ObjectiveStateBuildError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::EmptyObjectiveId => formatter.write_str("objective identifier must be non-empty"),
            Self::PlayerNotFound(player) => {
                write!(
                    formatter,
                    "objective state references non-participant {player}"
                )
            }
            Self::NonPositiveHoldTurns => {
                formatter.write_str("sparse objective hold turns must be positive")
            }
            Self::DuplicateObjectiveId(id) => write!(formatter, "duplicate objective id: {id}"),
        }
    }
}

impl std::error::Error for ObjectiveStateBuildError {}

fn validate_player_holds(
    identity: &MatchIdentity,
    holds: &BTreeMap<PlayerId, u32>,
) -> Result<(), ObjectiveStateBuildError> {
    for (player, turns) in holds {
        if !identity.contains(player) {
            return Err(ObjectiveStateBuildError::PlayerNotFound(player.clone()));
        }
        if *turns == 0 {
            return Err(ObjectiveStateBuildError::NonPositiveHoldTurns);
        }
    }
    Ok(())
}
