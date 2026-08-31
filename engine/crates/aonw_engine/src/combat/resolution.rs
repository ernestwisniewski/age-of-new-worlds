use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{
    CityConquestAction, CombatBatchStepUpdate, CombatCityStateChange, CombatUnitStateChange,
    GameState, HexCoord, Unit, UnitKind, WorldArtifactLocation,
};

use crate::{
    CommandRejectionCode, DomainEvent, EngineContext, MovementCost,
    movement::{merge_discovered_contacts, recompute_after_move},
    terrain_entry_cost,
};

use super::{
    CombatApplyError, CombatExecution, CombatOutcome, CombatRoll, CombatTarget, CombatUpdate,
    IntendedCombatUpdate, PreparedCombat, PreparedTarget, damage, retaliation_percent,
    scale_damage,
};

mod support;

use support::observer_id;

struct RolledCombat {
    seed: u32,
    rolls: Vec<CombatRoll>,
    outcome: CombatOutcome,
}

struct WorldAfterCombat {
    units: Vec<Unit>,
    cities: Vec<aonw_domain::City>,
    artifacts: Vec<aonw_domain::WorldArtifact>,
    attacker_gains: u32,
    defender_gains: u32,
}

struct CombatWorldChanges {
    unit_changes: Vec<CombatUnitStateChange>,
    city_changes: Vec<CombatCityStateChange>,
    artifact_changes: Vec<aonw_domain::WorldArtifact>,
    visibility_players: Vec<aonw_domain::PlayerId>,
    attacker_gains: u32,
    defender_gains: u32,
}

pub(super) fn resolve(
    state: &GameState,
    context: EngineContext<'_>,
    prepared: PreparedCombat,
    city_action: CityConquestAction,
) -> Result<CombatUpdate, CombatApplyError> {
    let rolled = roll_combat(state, context, &prepared);
    build_update(state, context, prepared, city_action, rolled)
}

pub(super) fn resolve_intended(
    state: &GameState,
    context: EngineContext<'_>,
    prepared: PreparedCombat,
    city_action: CityConquestAction,
) -> Result<IntendedCombatUpdate, CombatApplyError> {
    let rolled = roll_combat(state, context, &prepared);
    let changes = world_changes(
        state,
        context.ruleset(),
        &prepared,
        city_action,
        &rolled.outcome,
    );
    let (diplomacy, score_events) = update_diplomacy(state, &prepared)?;
    let events = combat_events(
        state,
        &prepared,
        city_action,
        &rolled.outcome,
        changes.attacker_gains,
        changes.defender_gains,
        score_events,
    );
    let evidence = CombatExecution {
        seed: rolled.seed,
        rolls: rolled.rolls.into_boxed_slice(),
        preview: prepared.preview,
        outcome: rolled.outcome,
    };
    Ok(IntendedCombatUpdate {
        state_update: CombatBatchStepUpdate {
            unit_changes: changes.unit_changes,
            city_changes: changes.city_changes,
            artifact_changes: changes.artifact_changes,
            diplomacy,
        },
        visibility_players: changes.visibility_players.into_boxed_slice(),
        events: events.into_boxed_slice(),
        evidence,
    })
}

fn roll_combat(
    state: &GameState,
    context: EngineContext<'_>,
    prepared: &PreparedCombat,
) -> RolledCombat {
    let attacker = &state.units()[prepared.attacker_index];
    let defender_id = match &prepared.preview.target {
        CombatTarget::Unit(id) => id.as_str(),
        CombatTarget::City(id) => id.as_str(),
    };
    let mut rng = super::CombatRng::from_turn(state.turn(), attacker.id().as_str(), defender_id);
    let seed = rng.seed();
    let variance = context.ruleset().combat().variance();
    let attack_roll = rng.signed(variance);
    let outgoing_damage = damage(
        prepared.preview.attacker.attack,
        prepared.preview.defender.defense,
        attack_roll,
    );
    let mut rolls = vec![CombatRoll { value: attack_roll }];
    let (attacker_before, defender_before) = combatant_hit_points(state, prepared);
    let defender_max = prepared.preview.defender.hit_points;
    let mut defender_after =
        defender_before.saturating_sub(i32::try_from(outgoing_damage).unwrap_or(i32::MAX));
    let mut defender_killed = defender_after <= 0;
    let mut retreat = None;
    if let PreparedTarget::Unit(index) = prepared.target
        && defender_after > 0
        && prepared.preview.defender.attack > 0
        && prepared.preview.defender.mobility >= 1
        && i64::from(defender_after) * 100
            < i64::from(defender_max)
                * i64::from(context.ruleset().combat().retreat_threshold_percent())
    {
        retreat = retreat_destination(
            state,
            context.map(),
            context.ruleset(),
            &state.units()[index],
            attacker.position(),
        );
        if retreat.is_some() {
            defender_after = defender_after.max(1);
            defender_killed = false;
        }
    }
    let retaliation_percent = (!defender_killed && retreat.is_none())
        .then(|| {
            retaliation_percent(
                &prepared.preview.defender,
                prepared.preview.distance,
                context.ruleset(),
            )
        })
        .flatten();
    let mut retaliation_damage = 0;
    if let Some(percent) = retaliation_percent {
        let retaliation_roll = rng.signed(variance);
        rolls.push(CombatRoll {
            value: retaliation_roll,
        });
        retaliation_damage = scale_damage(
            damage(
                prepared.preview.defender.attack,
                prepared.preview.attacker.defense,
                retaliation_roll,
            ),
            percent,
        );
    }
    let attacker_after =
        attacker_before.saturating_sub(i32::try_from(retaliation_damage).unwrap_or(i32::MAX));
    let attacker_killed = attacker_after <= 0;
    RolledCombat {
        seed,
        rolls,
        outcome: CombatOutcome {
            attacker_hit_points: attacker_after,
            defender_hit_points: defender_after,
            attacker_killed,
            defender_killed,
            defender_retreat: retreat,
            outgoing_damage,
            retaliation_damage,
        },
    }
}

fn combatant_hit_points(state: &GameState, prepared: &PreparedCombat) -> (i32, i32) {
    let attacker_max = prepared.preview.attacker.hit_points;
    let defender_max = prepared.preview.defender.hit_points;
    let attacker = &state.units()[prepared.attacker_index];
    let attacker_hit_points = i32::try_from(
        attacker
            .hit_points()
            .unwrap_or(attacker_max)
            .min(attacker_max),
    )
    .unwrap_or(i32::MAX);
    let defender_hit_points = match prepared.target {
        PreparedTarget::Unit(index) => i32::try_from(
            state.units()[index]
                .hit_points()
                .unwrap_or(defender_max)
                .min(defender_max),
        )
        .unwrap_or(i32::MAX),
        PreparedTarget::City(index) => {
            let maximum = i64::from(defender_max);
            i32::try_from(
                state.cities()[index]
                    .hit_points()
                    .unwrap_or(maximum)
                    .clamp(0, maximum),
            )
            .unwrap_or(i32::MAX)
        }
    };
    (attacker_hit_points, defender_hit_points)
}

fn build_update(
    state: &GameState,
    context: EngineContext<'_>,
    prepared: PreparedCombat,
    city_action: CityConquestAction,
    rolled: RolledCombat,
) -> Result<CombatUpdate, CombatApplyError> {
    let changes = world_changes(
        state,
        context.ruleset(),
        &prepared,
        city_action,
        &rolled.outcome,
    );
    let world = materialize_world(state, changes);
    let (fog, diplomacy, score_events) =
        update_visibility_and_diplomacy(state, context, &prepared, &world.units, &world.cities)?;
    let revision = state
        .revision()
        .checked_next()
        .ok_or(CombatApplyError::Rejected(
            CommandRejectionCode::StateRevisionOverflow,
        ))?;
    let events = combat_events(
        state,
        &prepared,
        city_action,
        &rolled.outcome,
        world.attacker_gains,
        world.defender_gains,
        score_events,
    );
    let evidence = CombatExecution {
        seed: rolled.seed,
        rolls: rolled.rolls.into_boxed_slice(),
        preview: prepared.preview,
        outcome: rolled.outcome,
    };
    Ok(CombatUpdate {
        revision,
        units: world.units,
        cities: world.cities,
        artifacts: world.artifacts,
        combat: state.combat().clone(),
        fog_of_war: fog,
        diplomacy,
        events: events.into_boxed_slice(),
        evidence,
    })
}

fn world_changes(
    state: &GameState,
    ruleset: &RulesetDefinition,
    prepared: &PreparedCombat,
    city_action: CityConquestAction,
    outcome: &CombatOutcome,
) -> CombatWorldChanges {
    let attacker = &state.units()[prepared.attacker_index];
    let (unit_changes, attacker_gains, defender_gains) =
        combat_unit_changes(state, ruleset, prepared, outcome);
    let (city_changes, destroyed_city) =
        combat_city_changes(state, prepared, city_action, outcome, attacker);
    let artifact_changes =
        combat_artifact_changes(state, prepared, outcome, attacker, destroyed_city.as_ref());
    let visibility_players =
        combat_visibility_players(state, prepared, city_action, outcome, attacker);
    CombatWorldChanges {
        unit_changes,
        city_changes,
        artifact_changes,
        visibility_players,
        attacker_gains,
        defender_gains,
    }
}

fn combat_unit_changes(
    state: &GameState,
    ruleset: &RulesetDefinition,
    prepared: &PreparedCombat,
    outcome: &CombatOutcome,
) -> (Vec<CombatUnitStateChange>, u32, u32) {
    let attacker = &state.units()[prepared.attacker_index];
    let attacker_gains = experience_gain(
        ruleset,
        attacker.kind(),
        !outcome.attacker_killed,
        outcome.defender_killed,
    );
    let defender_gains = match prepared.target {
        PreparedTarget::Unit(index) if !outcome.defender_killed => experience_gain(
            ruleset,
            state.units()[index].kind(),
            true,
            outcome.attacker_killed,
        ),
        PreparedTarget::Unit(_) | PreparedTarget::City(_) => 0,
    };
    let mut unit_changes = Vec::with_capacity(2);
    unit_changes.push(if outcome.attacker_killed {
        CombatUnitStateChange::Remove(attacker.id().clone())
    } else {
        CombatUnitStateChange::Replace(Box::new(attacker.after_combat(
            attacker.position(),
            canonical_hp(
                outcome.attacker_hit_points,
                prepared.preview.attacker.hit_points,
            ),
            attacker.experience_points().saturating_add(attacker_gains),
            true,
        )))
    });
    if let PreparedTarget::Unit(index) = prepared.target {
        let defender = &state.units()[index];
        unit_changes.push(if outcome.defender_killed {
            CombatUnitStateChange::Remove(defender.id().clone())
        } else {
            CombatUnitStateChange::Replace(Box::new(defender.after_combat(
                outcome.defender_retreat.unwrap_or(defender.position()),
                canonical_hp(
                    outcome.defender_hit_points,
                    prepared.preview.defender.hit_points,
                ),
                defender.experience_points().saturating_add(defender_gains),
                outcome.defender_retreat.is_some(),
            )))
        });
    }
    (unit_changes, attacker_gains, defender_gains)
}

fn combat_city_changes(
    state: &GameState,
    prepared: &PreparedCombat,
    city_action: CityConquestAction,
    outcome: &CombatOutcome,
    attacker: &Unit,
) -> (Vec<CombatCityStateChange>, Option<aonw_domain::CityId>) {
    let mut destroyed_city = None;
    let mut city_changes = Vec::with_capacity(1);
    if let PreparedTarget::City(index) = prepared.target {
        let city = &state.cities()[index];
        if outcome.defender_killed {
            if city_action == CityConquestAction::Capture {
                let captured_hp = i64::from(prepared.preview.defender.hit_points.div_ceil(2));
                city_changes.push(CombatCityStateChange::Replace(Box::new(
                    city.after_combat(attacker.owner_player_id().clone(), Some(captured_hp)),
                )));
            } else {
                destroyed_city = Some(city.id().clone());
                city_changes.push(CombatCityStateChange::Remove(city.id().clone()));
            }
        } else {
            city_changes.push(CombatCityStateChange::Replace(Box::new(city.after_combat(
                city.owner_player_id().clone(),
                Some(i64::from(outcome.defender_hit_points)),
            ))));
        }
    }
    (city_changes, destroyed_city)
}

fn combat_artifact_changes(
    state: &GameState,
    prepared: &PreparedCombat,
    outcome: &CombatOutcome,
    attacker: &Unit,
    destroyed_city: Option<&aonw_domain::CityId>,
) -> Vec<aonw_domain::WorldArtifact> {
    let defeated_unit = match prepared.target {
        PreparedTarget::Unit(index) if outcome.defender_killed => Some(state.units()[index].id()),
        _ => None,
    };
    let attacker_loss = outcome.attacker_killed.then_some(attacker.id());
    let target_coordinate = match prepared.target {
        PreparedTarget::Unit(index) => state.units()[index].position(),
        PreparedTarget::City(index) => state.cities()[index].center(),
    };
    state
        .artifacts()
        .iter()
        .filter_map(|artifact| {
            let affected = match artifact.location() {
                WorldArtifactLocation::Carried(unit_id)
                | WorldArtifactLocation::Excavation { unit_id, .. } => {
                    defeated_unit == Some(unit_id) || attacker_loss == Some(unit_id)
                }
                WorldArtifactLocation::Stored(city_id) => destroyed_city == Some(city_id),
                WorldArtifactLocation::Map(_) => false,
            };
            if !affected {
                return None;
            }
            let dropped =
                artifact.after_combat_loss(defeated_unit, destroyed_city, target_coordinate);
            let updated = dropped.after_combat_loss(attacker_loss, None, attacker.position());
            (updated != *artifact).then_some(updated)
        })
        .collect()
}

fn combat_visibility_players(
    state: &GameState,
    prepared: &PreparedCombat,
    city_action: CityConquestAction,
    outcome: &CombatOutcome,
    attacker: &Unit,
) -> Vec<aonw_domain::PlayerId> {
    let mut visibility_players = Vec::with_capacity(2);
    if outcome.attacker_killed {
        visibility_players.push(attacker.owner_player_id().clone());
    }
    match prepared.target {
        PreparedTarget::Unit(index)
            if outcome.defender_killed || outcome.defender_retreat.is_some() =>
        {
            visibility_players.push(state.units()[index].owner_player_id().clone());
        }
        PreparedTarget::City(index) if outcome.defender_killed => {
            visibility_players.push(state.cities()[index].owner_player_id().clone());
            if city_action == CityConquestAction::Capture {
                visibility_players.push(attacker.owner_player_id().clone());
            }
        }
        PreparedTarget::Unit(_) | PreparedTarget::City(_) => {}
    }
    visibility_players.sort_unstable();
    visibility_players.dedup();
    visibility_players
}

fn materialize_world(state: &GameState, changes: CombatWorldChanges) -> WorldAfterCombat {
    let mut units = state.units().to_vec();
    for change in changes.unit_changes {
        let (id, replacement) = match change {
            CombatUnitStateChange::Replace(unit) => (unit.id().clone(), Some(*unit)),
            CombatUnitStateChange::Remove(id) => (id, None),
        };
        let index = units
            .binary_search_by(|unit| unit.id().cmp(&id))
            .expect("prepared combat unit change belongs to the source state");
        if let Some(replacement) = replacement {
            units[index] = replacement;
        } else {
            units.remove(index);
        }
    }
    let mut cities = state.cities().to_vec();
    for change in changes.city_changes {
        let (id, replacement) = match change {
            CombatCityStateChange::Replace(city) => (city.id().clone(), Some(*city)),
            CombatCityStateChange::Remove(id) => (id, None),
        };
        let index = cities
            .binary_search_by(|city| city.id().cmp(&id))
            .expect("prepared combat city change belongs to the source state");
        if let Some(replacement) = replacement {
            cities[index] = replacement;
        } else {
            cities.remove(index);
        }
    }
    let mut artifacts = state.artifacts().to_vec();
    for replacement in changes.artifact_changes {
        let index = artifacts
            .binary_search_by(|artifact| artifact.id().cmp(replacement.id()))
            .expect("prepared combat artifact change belongs to the source state");
        artifacts[index] = replacement;
    }
    WorldAfterCombat {
        units,
        cities,
        artifacts,
        attacker_gains: changes.attacker_gains,
        defender_gains: changes.defender_gains,
    }
}

fn update_visibility_and_diplomacy(
    state: &GameState,
    context: EngineContext<'_>,
    prepared: &PreparedCombat,
    units: &[Unit],
    cities: &[aonw_domain::City],
) -> Result<
    (
        aonw_domain::FogOfWar,
        aonw_domain::Diplomacy,
        Vec<DomainEvent>,
    ),
    CombatApplyError,
> {
    let (attacked_diplomacy, score_events) = update_diplomacy(state, prepared)?;
    let (fog, diplomacy) =
        recompute_visibility(state, context.map(), units, cities, &attacked_diplomacy);
    Ok((fog, diplomacy, score_events))
}

fn update_diplomacy(
    state: &GameState,
    prepared: &PreparedCombat,
) -> Result<(aonw_domain::Diplomacy, Vec<DomainEvent>), CombatApplyError> {
    let attacker = &state.units()[prepared.attacker_index];
    let attacked_diplomacy = match prepared.target {
        PreparedTarget::Unit(_) => state.diplomacy().after_unit_attack(
            state.match_lifecycle().identity(),
            attacker.owner_player_id(),
            &prepared.target_owner,
            state.turn(),
            attacker.id().as_str(),
        ),
        PreparedTarget::City(_) => state.diplomacy().after_city_attack(
            state.match_lifecycle().identity(),
            attacker.owner_player_id(),
            &prepared.target_owner,
            state.turn(),
            attacker.id().as_str(),
        ),
    }
    .map_err(CombatApplyError::Diplomacy)?;
    let mut warmonger_entries = attacked_diplomacy
        .score_history()
        .iter()
        .filter(|entry| {
            entry.reason() == aonw_domain::DiplomaticScoreChangeReason::WarmongerPenalty
                && !state.diplomacy().score_history().contains(entry)
        })
        .collect::<Vec<_>>();
    warmonger_entries.sort_by(|left, right| {
        observer_id(left, attacker.owner_player_id())
            .cmp(observer_id(right, attacker.owner_player_id()))
    });
    let score_events = warmonger_entries
        .into_iter()
        .map(|entry| {
            DomainEvent::DiplomaticScoreChanged(
                crate::application::DiplomaticScoreChangedEvent::from_entry(entry),
            )
        })
        .collect();
    Ok((attacked_diplomacy, score_events))
}

fn recompute_visibility(
    state: &GameState,
    map: &MapDefinition,
    units: &[Unit],
    cities: &[aonw_domain::City],
    diplomacy: &aonw_domain::Diplomacy,
) -> (aonw_domain::FogOfWar, aonw_domain::Diplomacy) {
    let players = state
        .match_lifecycle()
        .identity()
        .participants()
        .iter()
        .map(aonw_domain::Participant::id);
    recompute_visibility_for_players(state, map, units, cities, diplomacy, players)
}

fn recompute_visibility_for_players<'player>(
    state: &GameState,
    map: &MapDefinition,
    units: &[Unit],
    cities: &[aonw_domain::City],
    diplomacy: &aonw_domain::Diplomacy,
    players: impl IntoIterator<Item = &'player aonw_domain::PlayerId>,
) -> (aonw_domain::FogOfWar, aonw_domain::Diplomacy) {
    let refs = units.iter().collect::<Vec<_>>();
    let mut fog = state.fog_of_war().clone();
    for player in players {
        fog = recompute_after_move(&fog, map, player, &refs, cities);
    }
    let diplomacy = merge_discovered_contacts(diplomacy, &fog, &refs, cities);
    (fog, diplomacy)
}

pub(super) fn refresh_batch_visibility(
    state: &GameState,
    map: &MapDefinition,
    players: &[aonw_domain::PlayerId],
) -> (Option<aonw_domain::FogOfWar>, aonw_domain::Diplomacy) {
    if players.is_empty() {
        let refs = state.units().iter().collect::<Vec<_>>();
        let diplomacy =
            merge_discovered_contacts(state.diplomacy(), state.fog_of_war(), &refs, state.cities());
        return (None, diplomacy);
    }
    let (fog, diplomacy) = recompute_visibility_for_players(
        state,
        map,
        state.units(),
        state.cities(),
        state.diplomacy(),
        players,
    );
    (Some(fog), diplomacy)
}

fn combat_events(
    state: &GameState,
    prepared: &PreparedCombat,
    city_action: CityConquestAction,
    outcome: &CombatOutcome,
    attacker_gains: u32,
    defender_gains: u32,
    score_events: Vec<DomainEvent>,
) -> Vec<DomainEvent> {
    let attacker = &state.units()[prepared.attacker_index];
    let target = prepared.preview.target.clone();
    let event = || crate::application::CombatEvent::new(attacker.id().clone(), target.clone());
    let unit_event = |unit_id: &aonw_domain::UnitId| {
        crate::application::CombatEvent::for_unit(
            attacker.id().clone(),
            target.clone(),
            unit_id.clone(),
        )
    };
    let attack_started = match prepared.target {
        PreparedTarget::Unit(_) => DomainEvent::UnitAttacked(event()),
        PreparedTarget::City(_) => DomainEvent::CityAttacked(event()),
    };
    let mut events = vec![attack_started, DomainEvent::CombatResolved(event())];
    events.extend(score_events);
    if outcome.defender_retreat.is_some() {
        let PreparedTarget::Unit(index) = prepared.target else {
            unreachable!("only a unit can retreat")
        };
        events.push(DomainEvent::UnitRetreated(unit_event(
            state.units()[index].id(),
        )));
    }
    if outcome.attacker_killed {
        events.push(DomainEvent::UnitKilled(unit_event(attacker.id())));
    } else if attacker_gains > 0 {
        events.push(DomainEvent::UnitGainedExperience(unit_event(attacker.id())));
    }
    if let PreparedTarget::Unit(index) = prepared.target {
        let defender_id = state.units()[index].id();
        if outcome.defender_killed {
            events.push(DomainEvent::UnitKilled(unit_event(defender_id)));
        } else if defender_gains > 0 {
            events.push(DomainEvent::UnitGainedExperience(unit_event(defender_id)));
        }
    }
    if matches!(prepared.target, PreparedTarget::City(_)) && outcome.defender_killed {
        events.push(match city_action {
            CityConquestAction::Capture => DomainEvent::CityCaptured(event()),
            CityConquestAction::Destroy => DomainEvent::CityDestroyed(event()),
        });
    }
    events
}

fn retreat_destination(
    state: &GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    defender: &Unit,
    attacker: HexCoord,
) -> Option<HexCoord> {
    let domain = ruleset
        .unit(defender.kind())?
        .capabilities()
        .movement_domain
        .domain();
    let mut candidates = state
        .bounds()
        .neighbors(defender.position())
        .filter(|coordinate| {
            map.tile_at(*coordinate).is_some_and(|tile| {
                matches!(terrain_entry_cost(tile, domain), MovementCost::Passable(_))
            }) && !state
                .units_at(*coordinate)
                .any(|unit| unit.id() != defender.id())
        })
        .collect::<Vec<_>>();
    candidates.sort_unstable_by(|left, right| {
        right
            .distance_to(attacker)
            .cmp(&left.distance_to(attacker))
            .then_with(|| left.cmp(right))
    });
    candidates.into_iter().next()
}

fn experience_gain(
    ruleset: &RulesetDefinition,
    kind: UnitKind,
    survived: bool,
    defeated: bool,
) -> u32 {
    if !ruleset
        .unit(kind)
        .is_some_and(|definition| definition.capabilities().gains_experience())
    {
        return 0;
    }
    u32::from(survived) + if defeated { 2 } else { 0 }
}

fn canonical_hp(value: i32, maximum: u32) -> Option<u32> {
    let value = u32::try_from(value.max(1)).unwrap_or(u32::MAX).min(maximum);
    (value < maximum).then_some(value)
}

#[cfg(test)]
mod tests;
