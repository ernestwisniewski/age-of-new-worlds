use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{City, CityId, Diplomacy, FogOfWar, GameState, PlayerCountry, PlayerId, Unit};

use super::rules::founding_job_is_valid;
use crate::movement::{merge_discovered_contacts, recompute_after_move};
use crate::{CityFoundedEvent, DomainEvent};

pub(crate) struct CityFoundingTurnUpdate {
    pub(crate) units: Vec<Unit>,
    pub(crate) cities: Vec<City>,
    pub(crate) fog_of_war: FogOfWar,
    pub(crate) diplomacy: Diplomacy,
    pub(crate) events: Vec<DomainEvent>,
    pub(crate) founded_city_ids: Vec<CityId>,
}

pub(crate) fn advance_city_founding(
    state: &GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    scope: &[PlayerId],
) -> Result<Option<CityFoundingTurnUpdate>, Box<str>> {
    if !state.units().iter().any(|unit| {
        scope.contains(unit.owner_player_id()) && unit.activity().city_founding_job().is_some()
    }) {
        return Ok(None);
    }
    let mut units = state.units().to_vec();
    let mut cities = state.cities().to_vec();
    let mut events = Vec::new();
    let mut founded_city_ids = Vec::new();
    let mut index = 0;
    while index < units.len() {
        let unit = &units[index];
        if !scope.contains(unit.owner_player_id()) {
            index += 1;
            continue;
        }
        let Some(job) = unit.activity().city_founding_job().cloned() else {
            index += 1;
            continue;
        };
        if !founding_job_is_valid(unit, &cities, map, ruleset.city(), &job) {
            units[index] = unit.with_city_founding_job(None);
            index += 1;
            continue;
        }
        if job.remaining_turns() > 1 {
            units[index] = unit
                .with_city_founding_job(Some(job.with_remaining_turns(job.remaining_turns() - 1)));
            index += 1;
            continue;
        }

        let owner = unit.owner_player_id().clone();
        let sequence = cities
            .iter()
            .filter(|city| city.owner_player_id() == &owner)
            .count()
            .saturating_add(1);
        let country = state
            .match_lifecycle()
            .identity()
            .participants()
            .iter()
            .find(|participant| participant.id() == &owner)
            .map_or(PlayerCountry::Poland, aonw_domain::Participant::country);
        let city_id = CityId::new(format!(
            "city_{}_{}_{}",
            owner.as_str(),
            job.center().col(),
            job.center().row()
        ))
        .map_err(|error| error.to_string().into_boxed_str())?;
        let mut controlled_hexes = job.controlled_hexes().to_vec();
        controlled_hexes.sort_unstable();
        let balance = ruleset.city();
        let city = City::builder(
            city_id.clone(),
            owner.clone(),
            ruleset.city_name(country, sequence),
            job.center(),
        )
        .with_founding_owner(Some(owner.clone()))
        .with_progression(
            balance.start_population(),
            balance.start_stored_food(),
            balance.start_max_hexes(),
            balance.start_territory_radius(),
        )
        .with_controlled_hexes(controlled_hexes)
        .build()
        .map_err(|error| error.to_string().into_boxed_str())?;
        cities.push(city);
        founded_city_ids.push(city_id.clone());
        events.push(DomainEvent::CityFounded(CityFoundedEvent::new(
            city_id, owner,
        )));

        if units[index].kind() == aonw_domain::UnitKind::Settler {
            units.remove(index);
        } else {
            units[index] = units[index]
                .after_city_founded()
                .ok_or_else(|| Box::<str>::from("validated commander lost its settler troop"))?;
            index += 1;
        }
    }

    let mut fog_of_war = state.fog_of_war().clone();
    let unit_refs = units.iter().collect::<Vec<_>>();
    for player in scope {
        fog_of_war = recompute_after_move(&fog_of_war, map, player, &unit_refs, &cities);
    }
    let diplomacy = merge_discovered_contacts(state.diplomacy(), &fog_of_war, &unit_refs, &cities);
    Ok(Some(CityFoundingTurnUpdate {
        units,
        cities,
        fog_of_war,
        diplomacy,
        events,
        founded_city_ids,
    }))
}
