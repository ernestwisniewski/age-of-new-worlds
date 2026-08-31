mod scoring;

use std::collections::BTreeMap;

use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{
    EconomyState, GameOutcome, GameOutcomeCondition, GameState, ObjectiveState, PlayerId, Unit,
    UnitMovementDomain, WorldArtifactLocation, WorldArtifactType,
};

use crate::{MovementCost, terrain_entry_cost};

pub use scoring::calculate_empire_scores;

/// Deterministic outcome-resolution failure caused by invalid content or overflow.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct OutcomeResolutionError(Box<str>);

impl OutcomeResolutionError {
    fn new(message: impl Into<Box<str>>) -> Self {
        Self(message.into())
    }
}

impl core::fmt::Display for OutcomeResolutionError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        formatter.write_str(&self.0)
    }
}

impl std::error::Error for OutcomeResolutionError {}

/// Resolves the authoritative outcome represented by one complete canonical state.
///
/// # Errors
///
/// Returns an error when score arithmetic overflows or ruleset content is incomplete.
pub fn resolve_game_outcome(
    state: &GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
) -> Result<GameOutcome, OutcomeResolutionError> {
    resolve_game_outcome_from(
        state,
        map,
        ruleset,
        state.units(),
        state.economy(),
        state.objectives(),
        state.turn(),
    )
}

pub(crate) fn resolve_game_outcome_after_turn(
    state: &GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    units: &[Unit],
    economy: &EconomyState,
    objectives: &ObjectiveState,
    turn: u32,
) -> Result<GameOutcome, OutcomeResolutionError> {
    resolve_game_outcome_from(state, map, ruleset, units, economy, objectives, turn)
}

fn resolve_game_outcome_from(
    state: &GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    units: &[Unit],
    economy: &EconomyState,
    objectives: &ObjectiveState,
    turn: u32,
) -> Result<GameOutcome, OutcomeResolutionError> {
    let identity = state.match_lifecycle().identity();
    let kicked = state.match_lifecycle().turn().kicked_player_ids();
    let players = identity
        .participants()
        .iter()
        .map(aonw_domain::Participant::id)
        .filter(|player| !kicked.contains(*player))
        .collect::<Vec<_>>();
    if players.len() <= 1 {
        return Ok(GameOutcome::ongoing());
    }

    let alive = players
        .iter()
        .copied()
        .filter(|player| {
            units.iter().any(|unit| unit.owner_player_id() == *player)
                || state
                    .cities()
                    .iter()
                    .any(|city| city.owner_player_id() == *player)
        })
        .collect::<Vec<_>>();
    let victory = identity.match_rules().victory();

    if victory.conquest_enabled() && alive.len() == 1 {
        return winner_outcome(identity, GameOutcomeCondition::Conquest, alive[0].clone());
    }
    if victory.domination_enabled()
        && let Some(winner) = domination_winner(state, map, objectives, &alive)?
    {
        return winner_outcome(identity, GameOutcomeCondition::Domination, winner);
    }
    if victory.cultural_enabled()
        && let Some(winner) = cultural_winner(state, objectives, &alive)
    {
        return winner_outcome(identity, GameOutcomeCondition::Cultural, winner);
    }
    if victory.score_fallback_enabled() && victory.turn_limit().is_some_and(|limit| turn >= limit) {
        let scores = scoring::calculate_empire_scores_from(
            state, map, ruleset, units, economy, objectives, &players,
        )?;
        let top_score = scores.values().max().copied();
        let winners = top_score.map_or_else(Vec::new, |top| {
            scores
                .iter()
                .filter(|(_, score)| **score == top)
                .map(|(player, _)| player.clone())
                .collect::<Vec<_>>()
        });
        let (condition, winner) = if winners.len() == 1 {
            (GameOutcomeCondition::Score, winners.into_iter().next())
        } else {
            (GameOutcomeCondition::Draw, None)
        };
        return GameOutcome::try_new(identity, condition, winner, scores)
            .map_err(|error| OutcomeResolutionError::new(error.to_string()));
    }
    Ok(GameOutcome::ongoing())
}

fn domination_winner(
    state: &GameState,
    map: &MapDefinition,
    objectives: &ObjectiveState,
    alive: &[&PlayerId],
) -> Result<Option<PlayerId>, OutcomeResolutionError> {
    let victory = state.match_lifecycle().identity().match_rules().victory();
    let valid_count = u32::try_from(map.tiles().iter().filter(|tile| is_passable(tile)).count())
        .map_err(|_| OutcomeResolutionError::new("domination tile count exceeds u32"))?;
    if valid_count == 0 {
        return Ok(None);
    }
    let candidates = alive.iter().copied().filter_map(|player| {
        let hold = objectives
            .domination_hold_turns_by_player_id()
            .get(player)
            .copied()
            .unwrap_or_default();
        if hold < victory.domination_hold_turns() {
            return None;
        }
        let controlled = u32::try_from(
            state
                .cities()
                .iter()
                .filter(|city| city.owner_player_id() == player)
                .flat_map(|city| {
                    std::iter::once(city.center()).chain(city.controlled_hexes().iter().copied())
                })
                .filter(|coordinate| map.tile_at(*coordinate).is_some_and(is_passable))
                .count(),
        )
        .expect("validated map bounds cap controlled coordinates at u32");
        victory
            .domination_control_percent()
            .percent_requirement_met(controlled, valid_count)
            .then(|| (player.clone(), hold))
    });
    Ok(unique_highest(candidates))
}

fn is_passable(tile: &aonw_content::TileDefinition) -> bool {
    matches!(
        terrain_entry_cost(tile, UnitMovementDomain::Land),
        MovementCost::Passable(_)
    )
}

fn cultural_winner(
    state: &GameState,
    objectives: &ObjectiveState,
    alive: &[&PlayerId],
) -> Option<PlayerId> {
    let victory = state.match_lifecycle().identity().match_rules().victory();
    let candidates = alive.iter().copied().filter_map(|player| {
        let hold = objectives
            .cultural_victory_hold_turns_by_player_id()
            .get(player)
            .copied()
            .unwrap_or_default();
        if hold < victory.cultural_hold_turns() {
            return None;
        }
        let stored_types = state.artifacts().iter().fold(0_u8, |types, artifact| {
            let WorldArtifactLocation::Stored(city_id) = artifact.location() else {
                return types;
            };
            if state
                .city(city_id)
                .is_none_or(|city| city.owner_player_id() != player)
            {
                return types;
            }
            types | artifact_type_bit(artifact.artifact_type())
        });
        (stored_types.count_ones() >= victory.cultural_required_artifacts())
            .then(|| (player.clone(), hold))
    });
    unique_highest(candidates)
}

fn unique_highest(values: impl IntoIterator<Item = (PlayerId, u32)>) -> Option<PlayerId> {
    let mut winner = None;
    let mut tied = false;
    for (player, score) in values {
        match winner.as_ref() {
            None => winner = Some((player, score)),
            Some((_, best)) if score > *best => {
                winner = Some((player, score));
                tied = false;
            }
            Some((_, best)) if score == *best => tied = true,
            Some(_) => {}
        }
    }
    if tied {
        None
    } else {
        winner.map(|(player, _)| player)
    }
}

fn winner_outcome(
    identity: &aonw_domain::MatchIdentity,
    condition: GameOutcomeCondition,
    winner: PlayerId,
) -> Result<GameOutcome, OutcomeResolutionError> {
    GameOutcome::try_new(identity, condition, Some(winner), BTreeMap::new())
        .map_err(|error| OutcomeResolutionError::new(error.to_string()))
}

const fn artifact_type_bit(value: WorldArtifactType) -> u8 {
    1 << match value {
        WorldArtifactType::AncientImperialCrown => 0,
        WorldArtifactType::AstronomersTablets => 1,
        WorldArtifactType::ProphetMask => 2,
        WorldArtifactType::HeroSword => 3,
        WorldArtifactType::MerchantsSeal => 4,
        WorldArtifactType::FirstPeoplesChronicle => 5,
        WorldArtifactType::TempleReliquary => 6,
        WorldArtifactType::QueensMirror => 7,
    }
}
