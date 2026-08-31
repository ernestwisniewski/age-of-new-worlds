use std::collections::{BTreeMap, BTreeSet};

use aonw_content::{MapDefinition, RulesetDefinition, StabilityValues};
use aonw_domain::{
    CityId, Diplomacy, DiplomaticRelationStatus, EconomyState, GameState, PlayerId, UnitId,
};

use crate::{CombatTarget, DomainEvent, StabilityBandChangedEvent};

use super::EconomyTurnError;

mod calculation;

use calculation::{StabilityFactors, stability_band, stability_net, territory_shares};

/// Ownership retained before simultaneous combat mutates or removes entities.
pub(crate) struct CombatEconomyOwnerIndex {
    units: BTreeMap<UnitId, PlayerId>,
    cities: BTreeMap<CityId, PlayerId>,
}

impl CombatEconomyOwnerIndex {
    pub(crate) fn from_state(state: &GameState) -> Self {
        Self {
            units: state
                .units()
                .iter()
                .map(|unit| (unit.id().clone(), unit.owner_player_id().clone()))
                .collect(),
            cities: state
                .cities()
                .iter()
                .map(|city| (city.id().clone(), city.owner_player_id().clone()))
                .collect(),
        }
    }
}

/// Rule-relevant event counts consumed exactly once by turn stability.
#[derive(Default)]
pub(crate) struct WarWearinessEventCounts {
    attacks_by_player: BTreeMap<PlayerId, u32>,
    cities_lost_by_player: BTreeMap<PlayerId, u32>,
    signed_peace_players: BTreeSet<PlayerId>,
}

impl WarWearinessEventCounts {
    pub(crate) fn from_combat(
        owners: &CombatEconomyOwnerIndex,
        events: &[DomainEvent],
    ) -> Result<Self, EconomyTurnError> {
        let mut counts = Self::default();
        for event in events {
            match event {
                DomainEvent::UnitAttacked(value) | DomainEvent::CityAttacked(value) => {
                    let player = owners.units.get(value.attacker_unit_id()).ok_or_else(|| {
                        EconomyTurnError::new("combat attacker owner is unavailable for economy")
                    })?;
                    increment(&mut counts.attacks_by_player, player)?;
                }
                DomainEvent::CityCaptured(value) | DomainEvent::CityDestroyed(value) => {
                    let CombatTarget::City(city_id) = value.target() else {
                        return Err(EconomyTurnError::new(
                            "city-loss event has a non-city combat target",
                        ));
                    };
                    let player = owners.cities.get(city_id).ok_or_else(|| {
                        EconomyTurnError::new("lost city owner is unavailable for economy")
                    })?;
                    increment(&mut counts.cities_lost_by_player, player)?;
                }
                _ => {}
            }
        }
        Ok(counts)
    }

    pub(crate) fn include_diplomacy_events(&mut self, events: &[DomainEvent]) {
        for event in events {
            let DomainEvent::DiplomaticRelationChanged(value) = event else {
                continue;
            };
            if value.old_status() == DiplomaticRelationStatus::War
                && value.new_status() != DiplomaticRelationStatus::War
            {
                self.signed_peace_players
                    .insert(value.player_a_id().clone());
                self.signed_peace_players
                    .insert(value.player_b_id().clone());
            }
        }
    }
}

pub(crate) struct StabilityTurnPhase {
    pub(crate) economy: EconomyState,
    pub(crate) events: Vec<DomainEvent>,
}

#[allow(clippy::too_many_arguments)]
pub(crate) fn advance_turn_stability(
    state: &GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    economy: &EconomyState,
    diplomacy: &Diplomacy,
    scope: &[PlayerId],
    turn: u32,
    counts: &WarWearinessEventCounts,
) -> Result<StabilityTurnPhase, EconomyTurnError> {
    let values = ruleset.economy().stability_values();
    let war_weariness = advance_war_weariness(economy, diplomacy, scope, turn, counts, values)?;
    let players = state
        .match_lifecycle()
        .identity()
        .participants()
        .iter()
        .map(|participant| participant.id().clone())
        .collect::<BTreeSet<_>>();
    let territory = territory_shares(state, map, &players)?;
    let mut stability = BTreeMap::new();
    let mut events = Vec::new();
    for player in &players {
        let net = stability_net(
            state,
            map,
            ruleset,
            player,
            war_weariness.get(player).copied().unwrap_or_default(),
            StabilityFactors::new(
                players.len(),
                values,
                *territory
                    .get(player)
                    .expect("territory shares cover every participant"),
            ),
        )?;
        stability.insert(player.clone(), net);
        let Some(previous) = economy.player_stability_net().get(player).copied() else {
            continue;
        };
        let previous_band = stability_band(ruleset, previous);
        let new_band = stability_band(ruleset, net);
        if previous_band != new_band {
            events.push(DomainEvent::StabilityBandChanged(
                StabilityBandChangedEvent::new(player.clone(), previous_band, new_band, net),
            ));
        }
    }
    let economy = EconomyState::try_new(
        state.match_lifecycle().identity(),
        state.bounds(),
        economy.player_gold().clone(),
        war_weariness,
        stability,
        economy.strategic_resources().clone(),
        economy.initial_resource_distribution().clone(),
    )
    .map_err(EconomyTurnError::new)?;
    Ok(StabilityTurnPhase { economy, events })
}

fn advance_war_weariness(
    economy: &EconomyState,
    diplomacy: &Diplomacy,
    scope: &[PlayerId],
    turn: u32,
    counts: &WarWearinessEventCounts,
    values: StabilityValues,
) -> Result<BTreeMap<PlayerId, i64>, EconomyTurnError> {
    let mut next = economy.player_war_weariness().clone();
    for player in scope.iter().collect::<BTreeSet<_>>() {
        let current = economy
            .player_war_weariness()
            .get(player)
            .copied()
            .unwrap_or_default();
        let at_war = diplomacy.relations().iter().any(|relation| {
            relation.status() == DiplomaticRelationStatus::War
                && (relation.pair().first() == player || relation.pair().second() == player)
        });
        let signed_peace = counts.signed_peace_players.contains(player)
            || diplomacy.relations().iter().any(|relation| {
                relation.status() == DiplomaticRelationStatus::Truce
                    && relation.last_changed_turn() == Some(turn)
                    && (relation.pair().first() == player || relation.pair().second() == player)
            });
        let attacks = counts
            .attacks_by_player
            .get(player)
            .copied()
            .unwrap_or_default();
        let lost = counts
            .cities_lost_by_player
            .get(player)
            .copied()
            .unwrap_or_default();
        let value = next_war_weariness(current, at_war, attacks, lost, signed_peace, values)?;
        if value == 0 {
            next.remove(player);
        } else {
            next.insert(player.clone(), value);
        }
    }
    Ok(next)
}

fn next_war_weariness(
    current: i64,
    at_war: bool,
    attacks: u32,
    cities_lost: u32,
    signed_peace: bool,
    values: StabilityValues,
) -> Result<i64, EconomyTurnError> {
    let value = if at_war {
        let attacks = attacks.saturating_sub(values.war_weariness_attack_free_per_turn);
        current
            .checked_add(i64::from(attacks))
            .and_then(|value| {
                values
                    .war_weariness_per_city_lost
                    .checked_mul(i64::from(cities_lost))
                    .and_then(|cost| value.checked_add(cost))
            })
            .ok_or_else(|| EconomyTurnError::new("war weariness overflow"))?
    } else {
        current.saturating_sub(if signed_peace {
            values.war_weariness_treaty_decay
        } else {
            values.war_weariness_peace_decay
        })
    };
    Ok(value.clamp(0, values.war_weariness_cap))
}

fn increment(
    counts: &mut BTreeMap<PlayerId, u32>,
    player: &PlayerId,
) -> Result<(), EconomyTurnError> {
    let value = counts.entry(player.clone()).or_default();
    *value = value
        .checked_add(1)
        .ok_or_else(|| EconomyTurnError::new("war weariness event count overflow"))?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use aonw_content::RulesetDefinition;

    use super::next_war_weariness;

    #[test]
    fn war_weariness_charges_after_free_attack_and_city_loss_then_caps() {
        let values = RulesetDefinition::standard().economy().stability_values();
        assert_eq!(
            next_war_weariness(2, true, 3, 1, false, values).expect("weariness"),
            6
        );
        assert_eq!(
            next_war_weariness(i64::MAX, true, 2, 0, false, values)
                .expect_err("checked overflow")
                .to_string(),
            "war weariness overflow"
        );
        assert_eq!(
            next_war_weariness(7, true, 2, 1, false, values).expect("capped weariness"),
            values.war_weariness_cap
        );
    }

    #[test]
    fn peace_and_signed_peace_use_distinct_decay() {
        let values = RulesetDefinition::standard().economy().stability_values();
        assert_eq!(
            next_war_weariness(6, false, 99, 99, false, values).expect("peace decay"),
            5
        );
        assert_eq!(
            next_war_weariness(6, false, 99, 99, true, values).expect("treaty decay"),
            4
        );
        assert_eq!(
            next_war_weariness(1, false, 0, 0, true, values).expect("zero floor"),
            0
        );
    }
}
