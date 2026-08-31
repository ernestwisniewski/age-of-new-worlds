use std::collections::{BTreeMap, BTreeSet};

use aonw_domain::{
    FogVisibility, GameState, PlayerId, RuleNumber, UnitMovementDomain, WorldArtifactLocation,
};

use crate::{EngineContext, MovementCost, terrain_entry_cost};

use super::{OutcomeResolutionError, calculate_empire_scores};

/// Public domination pressure for one active participant.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DominationVictoryProgress {
    player_id: PlayerId,
    controlled_passable_hexes: u32,
    total_passable_hexes: u32,
    hold_turns: u32,
}

impl DominationVictoryProgress {
    /// Returns the participant represented by this entry.
    #[must_use]
    pub const fn player_id(&self) -> &PlayerId {
        &self.player_id
    }

    /// Returns the exact controlled-territory numerator.
    #[must_use]
    pub const fn controlled_passable_hexes(&self) -> u32 {
        self.controlled_passable_hexes
    }

    /// Returns the exact passable-map denominator.
    #[must_use]
    pub const fn total_passable_hexes(&self) -> u32 {
        self.total_passable_hexes
    }

    /// Returns consecutive turns currently held above the threshold.
    #[must_use]
    pub const fn hold_turns(&self) -> u32 {
        self.hold_turns
    }
}

/// Recipient-owned cultural victory pressure.
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub struct CulturalVictoryProgress {
    unique_stored_artifacts: u32,
    hold_turns: u32,
}

impl CulturalVictoryProgress {
    /// Returns distinct artifact types stored in recipient-owned cities.
    #[must_use]
    pub const fn unique_stored_artifacts(self) -> u32 {
        self.unique_stored_artifacts
    }

    /// Returns consecutive turns currently held above the cultural threshold.
    #[must_use]
    pub const fn hold_turns(self) -> u32 {
        self.hold_turns
    }
}

/// Recipient-safe controller state for one authored map objective.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MapObjectiveProgress {
    objective_id: Box<str>,
    controller_player_id: Option<PlayerId>,
    hold_turns: u32,
}

impl MapObjectiveProgress {
    /// Returns the immutable authored objective identifier.
    #[must_use]
    pub const fn objective_id(&self) -> &str {
        &self.objective_id
    }

    /// Returns the controller only when disclosure permits it.
    #[must_use]
    pub const fn controller_player_id(&self) -> Option<&PlayerId> {
        self.controller_player_id.as_ref()
    }

    /// Returns the disclosed controller's consecutive hold count.
    #[must_use]
    pub const fn hold_turns(&self) -> u32 {
        self.hold_turns
    }
}

/// Complete engine-owned victory and live-score projection for one recipient.
#[allow(clippy::struct_excessive_bools)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct VictoryProgress {
    conquest_enabled: bool,
    domination_enabled: bool,
    domination_required_control_percent: RuleNumber,
    domination_required_hold_turns: u32,
    cultural_enabled: bool,
    cultural_required_artifacts: u32,
    cultural_required_hold_turns: u32,
    score_fallback_enabled: bool,
    turn_limit: Option<u32>,
    remaining_turns: Option<u32>,
    score_by_player_id: BTreeMap<PlayerId, i64>,
    domination: Box<[DominationVictoryProgress]>,
    own_cultural: CulturalVictoryProgress,
    map_objectives: Box<[MapObjectiveProgress]>,
}

impl VictoryProgress {
    /// Returns whether eliminating every rival can end the match.
    #[must_use]
    pub const fn conquest_enabled(&self) -> bool {
        self.conquest_enabled
    }

    /// Returns whether territorial domination can end the match.
    #[must_use]
    pub const fn domination_enabled(&self) -> bool {
        self.domination_enabled
    }

    /// Returns the exact configured domination percentage.
    #[must_use]
    pub fn domination_required_control_percent(&self) -> &str {
        self.domination_required_control_percent.as_str()
    }

    /// Returns consecutive domination turns required for victory.
    #[must_use]
    pub const fn domination_required_hold_turns(&self) -> u32 {
        self.domination_required_hold_turns
    }

    /// Returns whether the artifact collection can end the match.
    #[must_use]
    pub const fn cultural_enabled(&self) -> bool {
        self.cultural_enabled
    }

    /// Returns distinct stored artifacts required for cultural victory.
    #[must_use]
    pub const fn cultural_required_artifacts(&self) -> u32 {
        self.cultural_required_artifacts
    }

    /// Returns consecutive cultural turns required for victory.
    #[must_use]
    pub const fn cultural_required_hold_turns(&self) -> u32 {
        self.cultural_required_hold_turns
    }

    /// Returns whether the turn limit falls back to score.
    #[must_use]
    pub const fn score_fallback_enabled(&self) -> bool {
        self.score_fallback_enabled
    }

    /// Returns the configured score turn limit.
    #[must_use]
    pub const fn turn_limit(&self) -> Option<u32> {
        self.turn_limit
    }

    /// Returns turns remaining before score resolution.
    #[must_use]
    pub const fn remaining_turns(&self) -> Option<u32> {
        self.remaining_turns
    }

    /// Returns live public empire scores in participant-ID order.
    #[must_use]
    pub const fn score_by_player_id(&self) -> &BTreeMap<PlayerId, i64> {
        &self.score_by_player_id
    }

    /// Returns public territorial pressure in participant-ID order.
    #[must_use]
    pub const fn domination(&self) -> &[DominationVictoryProgress] {
        &self.domination
    }

    /// Returns cultural pressure for the recipient only.
    #[must_use]
    pub const fn own_cultural(&self) -> CulturalVictoryProgress {
        self.own_cultural
    }

    /// Returns authored objective progress in objective-ID order.
    #[must_use]
    pub const fn map_objectives(&self) -> &[MapObjectiveProgress] {
        &self.map_objectives
    }
}

/// Calculates authoritative live score and recipient-safe victory pressure.
///
/// Rival domination and total scores are public match pressure. Cultural
/// collections remain recipient-private, while map-objective controllers are
/// disclosed only to their controller or while the objective hex is visible.
///
/// # Errors
///
/// Returns an error when score or bounded progress arithmetic cannot be represented.
pub fn calculate_victory_progress(
    state: &GameState,
    context: EngineContext<'_>,
) -> Result<VictoryProgress, OutcomeResolutionError> {
    let actor = context.actor_player_id();
    let identity = state.match_lifecycle().identity();
    if !identity.contains(actor) {
        return Err(OutcomeResolutionError::new(
            "victory projection actor is not a participant",
        ));
    }
    let victory = identity.match_rules().victory();
    let active_players = active_players(state);
    let total_passable_hexes = passable_hex_count(context)?;
    let domination = active_players
        .iter()
        .map(|player| domination_progress(state, context, player, total_passable_hexes))
        .collect::<Result<Vec<_>, _>>()?
        .into_boxed_slice();
    Ok(VictoryProgress {
        conquest_enabled: victory.conquest_enabled(),
        domination_enabled: victory.domination_enabled(),
        domination_required_control_percent: victory.domination_control_percent().clone(),
        domination_required_hold_turns: victory.domination_hold_turns(),
        cultural_enabled: victory.cultural_enabled(),
        cultural_required_artifacts: victory.cultural_required_artifacts(),
        cultural_required_hold_turns: victory.cultural_hold_turns(),
        score_fallback_enabled: victory.score_fallback_enabled(),
        turn_limit: victory.turn_limit(),
        remaining_turns: victory
            .score_fallback_enabled()
            .then(|| {
                victory
                    .turn_limit()
                    .map(|limit| limit.saturating_sub(state.turn()))
            })
            .flatten(),
        score_by_player_id: calculate_empire_scores(state, context.map(), context.ruleset())?,
        domination,
        own_cultural: cultural_progress(state, actor)?,
        map_objectives: map_objective_progress(state, context),
    })
}

fn active_players(state: &GameState) -> Vec<&PlayerId> {
    let kicked = state.match_lifecycle().turn().kicked_player_ids();
    state
        .match_lifecycle()
        .identity()
        .participants()
        .iter()
        .map(aonw_domain::Participant::id)
        .filter(|player| !kicked.contains(*player))
        .collect()
}

fn passable_hex_count(context: EngineContext<'_>) -> Result<u32, OutcomeResolutionError> {
    u32::try_from(
        context
            .map()
            .tiles()
            .iter()
            .filter(|tile| {
                matches!(
                    terrain_entry_cost(tile, UnitMovementDomain::Land),
                    MovementCost::Passable(_)
                )
            })
            .count(),
    )
    .map_err(|_| OutcomeResolutionError::new("victory passable tile count exceeds u32"))
}

fn domination_progress(
    state: &GameState,
    context: EngineContext<'_>,
    player: &PlayerId,
    total_passable_hexes: u32,
) -> Result<DominationVictoryProgress, OutcomeResolutionError> {
    let controlled = state
        .cities()
        .iter()
        .filter(|city| city.owner_player_id() == player)
        .flat_map(|city| {
            std::iter::once(city.center()).chain(city.controlled_hexes().iter().copied())
        })
        .filter(|coordinate| {
            context.map().tile_at(*coordinate).is_some_and(|tile| {
                matches!(
                    terrain_entry_cost(tile, UnitMovementDomain::Land),
                    MovementCost::Passable(_)
                )
            })
        })
        .collect::<BTreeSet<_>>();
    Ok(DominationVictoryProgress {
        player_id: player.clone(),
        controlled_passable_hexes: u32::try_from(controlled.len()).map_err(|_| {
            OutcomeResolutionError::new("controlled victory tile count exceeds u32")
        })?,
        total_passable_hexes,
        hold_turns: state
            .objectives()
            .domination_hold_turns_by_player_id()
            .get(player)
            .copied()
            .unwrap_or_default(),
    })
}

fn cultural_progress(
    state: &GameState,
    actor: &PlayerId,
) -> Result<CulturalVictoryProgress, OutcomeResolutionError> {
    let types = state
        .artifacts()
        .iter()
        .filter_map(|artifact| {
            let WorldArtifactLocation::Stored(city_id) = artifact.location() else {
                return None;
            };
            state
                .city(city_id)
                .is_some_and(|city| city.owner_player_id() == actor)
                .then_some(artifact.artifact_type())
        })
        .collect::<BTreeSet<_>>();
    Ok(CulturalVictoryProgress {
        unique_stored_artifacts: u32::try_from(types.len())
            .map_err(|_| OutcomeResolutionError::new("stored artifact type count exceeds u32"))?,
        hold_turns: state
            .objectives()
            .cultural_victory_hold_turns_by_player_id()
            .get(actor)
            .copied()
            .unwrap_or_default(),
    })
}

fn map_objective_progress(
    state: &GameState,
    context: EngineContext<'_>,
) -> Box<[MapObjectiveProgress]> {
    let actor = context.actor_player_id();
    context
        .map()
        .objectives()
        .iter()
        .map(|objective| {
            let disclosed = state
                .objectives()
                .map_objective_hold_states()
                .iter()
                .find(|hold| hold.objective_id() == objective.id())
                .filter(|hold| {
                    hold.player_id() == actor
                        || state.fog_of_war().visibility(actor, objective.coordinate())
                            == FogVisibility::Visible
                });
            MapObjectiveProgress {
                objective_id: objective.id().into(),
                controller_player_id: disclosed.map(|hold| hold.player_id().clone()),
                hold_turns: disclosed.map_or(0, aonw_domain::MapObjectiveHoldState::hold_turns),
            }
        })
        .collect::<Vec<_>>()
        .into_boxed_slice()
}
