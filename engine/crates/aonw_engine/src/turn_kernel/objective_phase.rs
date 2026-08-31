use std::collections::{BTreeMap, BTreeSet};

use aonw_content::{MapDefinition, MapObjective};
use aonw_domain::{
    EconomyAccountChange, EconomyState, GameState, MapObjectiveHoldState, ObjectiveState, PlayerId,
    Unit, UnitMovementDomain, WorldArtifactLocation, WorldArtifactType,
};

use crate::{
    CanonicalEngineError, DomainEvent, DominationThresholdReachedEvent, MapObjectiveSecuredEvent,
    MovementCost, terrain_entry_cost,
};

pub(super) struct ObjectivePhase {
    pub(super) economy: EconomyState,
    pub(super) objectives: ObjectiveState,
    pub(super) events: Vec<DomainEvent>,
}

pub(super) fn processor_is_required(
    state: &GameState,
    map: &MapDefinition,
    scope: &[PlayerId],
) -> bool {
    let owns_scope = |player: &PlayerId| scope.contains(player);
    let victory = state.match_lifecycle().identity().match_rules().victory();
    (!scope.is_empty() && (victory.domination_enabled() || victory.cultural_enabled()))
        || !map.objectives().is_empty()
        || state
            .objectives()
            .domination_hold_turns_by_player_id()
            .keys()
            .any(&owns_scope)
        || state
            .objectives()
            .cultural_victory_hold_turns_by_player_id()
            .keys()
            .any(&owns_scope)
        || state
            .objectives()
            .map_objective_hold_states()
            .iter()
            .any(|hold| owns_scope(hold.player_id()))
}

pub(super) fn advance_turn_objectives(
    state: &GameState,
    map: &MapDefinition,
    economy: EconomyState,
    units: &[Unit],
    scope: &[PlayerId],
) -> Result<ObjectivePhase, CanonicalEngineError> {
    let (map_holds, economy, mut events) =
        advance_map_objectives(state, map, economy, units, scope)?;
    let (domination, domination_events) = advance_domination(state, map, scope)?;
    let cultural = advance_cultural(state, scope)?;
    events.extend(domination_events);
    let objectives = ObjectiveState::try_new(
        state.match_lifecycle().identity(),
        domination,
        cultural,
        map_holds,
    )
    .map_err(objective_error)?;
    Ok(ObjectivePhase {
        economy,
        objectives,
        events,
    })
}

fn advance_map_objectives(
    state: &GameState,
    map: &MapDefinition,
    economy: EconomyState,
    units: &[Unit],
    scope: &[PlayerId],
) -> Result<(Vec<MapObjectiveHoldState>, EconomyState, Vec<DomainEvent>), CanonicalEngineError> {
    if map.objectives().is_empty() {
        return Ok((
            state.objectives().map_objective_hold_states().to_vec(),
            economy,
            Vec::new(),
        ));
    }
    let mut holds = Vec::with_capacity(map.objectives().len());
    let mut events = Vec::new();
    let mut gold_changes = Vec::new();
    for objective in map.objectives() {
        let Some(controller) = objective_controller(state, units, objective) else {
            continue;
        };
        let previous = state
            .objectives()
            .map_objective_hold_states()
            .iter()
            .find(|hold| hold.objective_id() == objective.id());
        let hold_turns = if previous.is_some_and(|hold| hold.player_id() == &controller) {
            previous
                .expect("matching previous hold")
                .hold_turns()
                .checked_add(1)
                .ok_or_else(|| objective_error("map objective hold overflow"))?
        } else {
            1
        };
        let hold = MapObjectiveHoldState::try_new(
            objective.id().to_owned(),
            controller.clone(),
            hold_turns,
        )
        .map_err(objective_error)?;
        if hold_turns >= objective.required_hold_turns() {
            let already_secured = previous.is_some_and(|previous| {
                previous.player_id() == &controller
                    && previous.hold_turns() >= objective.required_hold_turns()
            });
            if !already_secured {
                events.push(DomainEvent::MapObjectiveSecured(
                    MapObjectiveSecuredEvent::new(
                        controller.clone(),
                        objective.id().to_owned(),
                        objective.objective_type(),
                        objective.coordinate(),
                        hold_turns,
                        objective.required_hold_turns(),
                        objective.victory_points(),
                        objective.gold_per_turn(),
                    ),
                ));
            }
            if objective.gold_per_turn() > 0 && scope.contains(&controller) {
                gold_changes.push(EconomyAccountChange::Gold {
                    player: controller,
                    delta: i64::from(objective.gold_per_turn()),
                });
            }
        }
        holds.push(hold);
    }
    let economy = economy
        .try_after_changes(
            state.match_lifecycle().identity(),
            state.bounds(),
            gold_changes,
        )
        .map_err(objective_error)?;
    Ok((holds, economy, events))
}

fn objective_controller(
    state: &GameState,
    units: &[Unit],
    objective: &MapObjective,
) -> Option<PlayerId> {
    let mut players = BTreeSet::new();
    for city in state
        .cities()
        .iter()
        .filter(|city| city.controls(objective.coordinate()))
    {
        players.insert(city.owner_player_id().clone());
    }
    for unit in units
        .iter()
        .filter(|unit| unit.position() == objective.coordinate())
    {
        players.insert(unit.owner_player_id().clone());
    }
    (players.len() == 1).then(|| players.into_iter().next().expect("one controller"))
}

fn advance_domination(
    state: &GameState,
    map: &MapDefinition,
    scope: &[PlayerId],
) -> Result<(BTreeMap<PlayerId, u32>, Vec<DomainEvent>), CanonicalEngineError> {
    let rules = state.match_lifecycle().identity().match_rules().victory();
    if !rules.domination_enabled() {
        return Ok((BTreeMap::new(), Vec::new()));
    }
    let players = scope.iter().cloned().collect::<BTreeSet<_>>();
    let valid = map
        .tiles()
        .iter()
        .filter(|tile| {
            matches!(
                terrain_entry_cost(tile, UnitMovementDomain::Land),
                MovementCost::Passable(_)
            )
        })
        .map(aonw_content::TileDefinition::coordinate)
        .collect::<BTreeSet<_>>();
    let valid_count = u32::try_from(valid.len()).map_err(objective_error)?;
    let mut controlled = players
        .iter()
        .cloned()
        .map(|player| (player, BTreeSet::new()))
        .collect::<BTreeMap<_, _>>();
    for city in state.cities() {
        let Some(coordinates) = controlled.get_mut(city.owner_player_id()) else {
            continue;
        };
        for coordinate in
            std::iter::once(city.center()).chain(city.controlled_hexes().iter().copied())
        {
            if valid.contains(&coordinate) {
                coordinates.insert(coordinate);
            }
        }
    }
    let previous = state.objectives().domination_hold_turns_by_player_id();
    let mut next = BTreeMap::new();
    let mut events = Vec::new();
    for (player, coordinates) in controlled {
        let controlled_count = u32::try_from(coordinates.len()).map_err(objective_error)?;
        if !rules
            .domination_control_percent()
            .percent_requirement_met(controlled_count, valid_count)
        {
            continue;
        }
        let previous_hold = previous.get(&player).copied().unwrap_or_default();
        let hold_turns = previous_hold
            .checked_add(1)
            .ok_or_else(|| objective_error("domination hold overflow"))?;
        next.insert(player.clone(), hold_turns);
        if previous_hold == 0 {
            events.push(DomainEvent::DominationThresholdReached(
                DominationThresholdReachedEvent::new(
                    player,
                    controlled_count,
                    valid_count,
                    rules.domination_control_percent().clone(),
                    hold_turns,
                    rules.domination_hold_turns(),
                ),
            ));
        }
    }
    Ok((next, events))
}

fn advance_cultural(
    state: &GameState,
    scope: &[PlayerId],
) -> Result<BTreeMap<PlayerId, u32>, CanonicalEngineError> {
    let rules = state.match_lifecycle().identity().match_rules().victory();
    if !rules.cultural_enabled() {
        return Ok(state
            .objectives()
            .cultural_victory_hold_turns_by_player_id()
            .clone());
    }
    let players = scope.iter().cloned().collect::<BTreeSet<_>>();
    let mut stored_types = players
        .iter()
        .cloned()
        .map(|player| (player, BTreeSet::<WorldArtifactType>::new()))
        .collect::<BTreeMap<_, _>>();
    for artifact in state.artifacts() {
        let WorldArtifactLocation::Stored(city_id) = artifact.location() else {
            continue;
        };
        let Some(city) = state.city(city_id) else {
            continue;
        };
        if let Some(types) = stored_types.get_mut(city.owner_player_id()) {
            types.insert(artifact.artifact_type());
        }
    }
    let previous = state
        .objectives()
        .cultural_victory_hold_turns_by_player_id();
    let mut next = BTreeMap::new();
    for (player, types) in stored_types {
        if u32::try_from(types.len()).map_err(objective_error)?
            < rules.cultural_required_artifacts()
        {
            continue;
        }
        let hold_turns = previous
            .get(&player)
            .copied()
            .unwrap_or_default()
            .checked_add(1)
            .ok_or_else(|| objective_error("cultural hold overflow"))?;
        next.insert(player, hold_turns);
    }
    Ok(next)
}

fn objective_error(error: impl core::fmt::Display) -> CanonicalEngineError {
    CanonicalEngineError::Objective(error.to_string().into())
}
