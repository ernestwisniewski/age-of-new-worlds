use std::collections::{BTreeMap, BTreeSet};

use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{EconomyState, GameState, ObjectiveState, PlayerId, Unit};

use super::OutcomeResolutionError;

/// Calculates exact empire scores for every active match participant.
///
/// # Errors
///
/// Returns an error when score arithmetic overflows or unit content is incomplete.
pub fn calculate_empire_scores(
    state: &GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
) -> Result<BTreeMap<PlayerId, i64>, OutcomeResolutionError> {
    let turn = state.match_lifecycle().turn();
    let kicked = turn.kicked_player_ids();
    let resigned = turn.resigned_player_ids();
    let players = state
        .match_lifecycle()
        .identity()
        .participants()
        .iter()
        .map(aonw_domain::Participant::id)
        .filter(|player| !kicked.contains(*player) && !resigned.contains(*player))
        .collect::<Vec<_>>();
    calculate_empire_scores_from(
        state,
        map,
        ruleset,
        state.units(),
        state.economy(),
        state.objectives(),
        &players,
    )
}

pub(super) fn calculate_empire_scores_from(
    state: &GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    units: &[Unit],
    economy: &EconomyState,
    objectives: &ObjectiveState,
    players: &[&PlayerId],
) -> Result<BTreeMap<PlayerId, i64>, OutcomeResolutionError> {
    players
        .iter()
        .map(|player| score_player(state, map, ruleset, units, economy, objectives, player))
        .collect()
}

fn score_player(
    state: &GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    units: &[Unit],
    economy: &EconomyState,
    objectives: &ObjectiveState,
    player: &PlayerId,
) -> Result<(PlayerId, i64), OutcomeResolutionError> {
    let balance = ruleset.outcome();
    let cities = state
        .cities()
        .iter()
        .filter(|city| city.owner_player_id() == player)
        .collect::<Vec<_>>();
    let city_ids = cities.iter().map(|city| city.id()).collect::<BTreeSet<_>>();
    let mut score = 0_i64;
    add_weighted(&mut score, cities.len(), balance.city_score(), "city score")?;
    for city in &cities {
        add_i64(
            &mut score,
            city.population()
                .checked_mul(i64::from(balance.population_score()))
                .ok_or_else(|| OutcomeResolutionError::new("population score overflow"))?,
            "population score",
        )?;
        add_weighted(
            &mut score,
            city.controlled_hexes().len().saturating_add(1),
            balance.territory_hex_score(),
            "territory score",
        )?;
        add_weighted(
            &mut score,
            city.buildings().len(),
            balance.building_score(),
            "building score",
        )?;
    }
    for unit in units.iter().filter(|unit| unit.owner_player_id() == player) {
        let definition = ruleset.unit(unit.kind()).ok_or_else(|| {
            OutcomeResolutionError::new(format!("missing unit definition for {:?}", unit.kind()))
        })?;
        add_i64(
            &mut score,
            i64::from(definition.score_value()),
            "unit score",
        )?;
        add_i64(
            &mut score,
            i64::from(unit.experience_points() / balance.experience_point_divisor()),
            "unit experience score",
        )?;
    }
    let technologies = state
        .research()
        .players()
        .get(player)
        .map_or(0, |research| research.unlocked_technology_ids().len());
    add_weighted(
        &mut score,
        technologies,
        balance.technology_score(),
        "technology score",
    )?;
    let improvements = state
        .field_improvements()
        .iter()
        .filter(|improvement| {
            improvement
                .built_by_city_id()
                .is_some_and(|city| city_ids.contains(city))
        })
        .count();
    add_weighted(
        &mut score,
        improvements,
        balance.improvement_score(),
        "improvement score",
    )?;
    let gold = economy
        .player_gold()
        .get(player)
        .copied()
        .unwrap_or_default();
    let gold_score =
        (gold / i64::from(balance.gold_divisor())).min(i64::from(balance.maximum_gold_score()));
    add_i64(&mut score, gold_score, "gold score")?;
    add_i64(
        &mut score,
        map_objective_score(state, map, units, objectives, player)?,
        "map objective score",
    )?;
    Ok((player.clone(), score))
}

fn map_objective_score(
    state: &GameState,
    map: &MapDefinition,
    units: &[Unit],
    objectives: &ObjectiveState,
    player: &PlayerId,
) -> Result<i64, OutcomeResolutionError> {
    let mut score = 0_i64;
    for objective in map.objectives() {
        let Some(hold) = objectives
            .map_objective_hold_states()
            .iter()
            .find(|hold| hold.objective_id() == objective.id())
        else {
            continue;
        };
        if hold.player_id() != player || hold.hold_turns() < objective.required_hold_turns() {
            continue;
        }
        let mut controllers = state
            .cities()
            .iter()
            .filter(|city| city.controls(objective.coordinate()))
            .map(aonw_domain::City::owner_player_id)
            .chain(
                units
                    .iter()
                    .filter(|unit| unit.position() == objective.coordinate())
                    .map(aonw_domain::Unit::owner_player_id),
            )
            .collect::<BTreeSet<_>>();
        if controllers.len() == 1 && controllers.pop_first() == Some(player) {
            add_i64(
                &mut score,
                i64::from(objective.victory_points()),
                "map objective score",
            )?;
        }
    }
    Ok(score)
}

fn add_weighted(
    score: &mut i64,
    count: usize,
    weight: u32,
    label: &'static str,
) -> Result<(), OutcomeResolutionError> {
    let count = i64::try_from(count)
        .map_err(|_| OutcomeResolutionError::new(format!("{label} count overflow")))?;
    let value = count
        .checked_mul(i64::from(weight))
        .ok_or_else(|| OutcomeResolutionError::new(format!("{label} overflow")))?;
    add_i64(score, value, label)
}

fn add_i64(score: &mut i64, value: i64, label: &'static str) -> Result<(), OutcomeResolutionError> {
    *score = score
        .checked_add(value)
        .ok_or_else(|| OutcomeResolutionError::new(format!("{label} overflow")))?;
    Ok(())
}
