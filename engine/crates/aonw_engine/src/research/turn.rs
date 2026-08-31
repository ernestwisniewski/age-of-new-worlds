use std::collections::BTreeMap;

use aonw_domain::{
    City, CityId, CitySpecializationType, GameState, KnowledgeState, PlayerId, ResearchState,
    ResearchStateUpdate, WorldArtifactLocation, WorldArtifactType,
};

use super::rules::selection_cost;
use super::{ResearchError, ScienceYieldBreakdown, ScienceYieldSource, ScienceYieldSourceKind};
use crate::production::ResearchProjectScience;
use crate::{
    DomainEvent, EngineContext, ResearchPointsGainedEvent, TechnologyAvailability,
    TechnologyResearchedEvent, TechnologyUnlockQuery,
};

const BASIS_POINTS: i64 = 10_000;

pub(crate) struct ResearchTurnPhase {
    pub(crate) state: GameState,
    pub(crate) events: Vec<DomainEvent>,
}

pub(crate) fn advance_turn_research(
    state: GameState,
    map: &aonw_content::MapDefinition,
    ruleset: &aonw_content::RulesetDefinition,
    scope: &[PlayerId],
    project_science: &[ResearchProjectScience],
) -> Result<ResearchTurnPhase, ResearchError> {
    let mut research = state.research().clone();
    let mut events = Vec::new();
    for player in scope {
        let context = EngineContext::canonical(player, map, ruleset);
        let science = science_yield(&state, context, player, project_science)?;
        if science.total() > 0 {
            events.push(DomainEvent::ResearchPointsGained(
                ResearchPointsGainedEvent::new(player.clone(), science.total()),
            ));
        }

        let current = research.players().get(player).cloned().unwrap_or_default();
        let Some(active) = current.active_technology_id() else {
            continue;
        };
        if TechnologyUnlockQuery::new(ruleset, &current).availability(active)?
            != TechnologyAvailability::Active
        {
            research =
                research.updating_player(player.clone(), current.without_active_technology());
            continue;
        }
        let cost = selection_cost(&state, context, player, active)?;
        let (updated, completed) = current.try_after_science(science.total(), cost)?;
        if updated != current {
            research = research.updating_player(player.clone(), updated);
        }
        if let Some(technology) = completed {
            events.push(DomainEvent::TechnologyResearched(
                TechnologyResearchedEvent::new(player.clone(), technology),
            ));
        }
    }

    let state = replace_research(state, research)?;
    Ok(ResearchTurnPhase { state, events })
}

pub(super) fn science_yield(
    state: &GameState,
    context: EngineContext<'_>,
    player: &PlayerId,
    project_science: &[ResearchProjectScience],
) -> Result<ScienceYieldBreakdown, ResearchError> {
    let effects = TechnologyUnlockQuery::new(context.ruleset(), player_research(state, player))
        .effect_summary()?;
    let wonder_science = wonder_science_per_city(state, context, player)?;
    let mut total = 0_i64;
    let mut by_city_id = BTreeMap::new();
    let mut sources = Vec::new();

    for city in state
        .cities()
        .iter()
        .filter(|city| city.owner_player_id() == player)
    {
        let base = base_city_science(context, city, i64::from(effects.city_science_bonus))?;
        let artifact = artifact_science_for_city(state, city.id())?;
        let amount = checked_sum([base, artifact, wonder_science])?;
        if amount <= 0 {
            continue;
        }
        total = checked_sum([total, amount])?;
        by_city_id.insert(city.id().clone(), amount);
        push_source(
            &mut sources,
            city,
            base,
            ScienceYieldSourceKind::CityScience,
        );
        push_source(
            &mut sources,
            city,
            artifact,
            ScienceYieldSourceKind::WorldArtifact,
        );
        push_source(
            &mut sources,
            city,
            wonder_science,
            ScienceYieldSourceKind::WorldWonder,
        );
    }

    for contribution in project_science
        .iter()
        .filter(|contribution| &contribution.player_id == player && contribution.amount > 0)
    {
        total = checked_sum([total, contribution.amount])?;
        let city_total = by_city_id.entry(contribution.city_id.clone()).or_default();
        *city_total = checked_sum([*city_total, contribution.amount])?;
        sources.push(ScienceYieldSource::new(
            contribution.city_id.clone(),
            contribution.amount,
            ScienceYieldSourceKind::CityResearchProject,
        ));
    }

    Ok(ScienceYieldBreakdown::new(
        player.clone(),
        total,
        by_city_id,
        sources,
    ))
}

fn base_city_science(
    context: EngineContext<'_>,
    city: &City,
    technology_bonus: i64,
) -> Result<i64, ResearchError> {
    let balance = context.ruleset().science_balance();
    let specialization = i64::from(matches!(
        city.specialization(),
        Some(CitySpecializationType::Science)
    )) * 2;
    let buildings = building_science(context, city)?;
    let uncapped = checked_sum([
        balance.base_science_per_city(),
        technology_bonus,
        specialization,
        buildings,
    ])?;
    let cap = balance.max_science_per_city();
    Ok(if cap > 0 { uncapped.min(cap) } else { uncapped })
}

fn building_science(context: EngineContext<'_>, city: &City) -> Result<i64, ResearchError> {
    let mut amounts = city
        .buildings()
        .iter()
        .map(|building| {
            context
                .ruleset()
                .production()
                .building(*building)
                .ok_or_else(|| invalid("completed building is absent from production content"))
                .map(aonw_content::BuildingProductionDefinition::science_per_turn)
        })
        .collect::<Result<Vec<_>, _>>()?;
    amounts.retain(|amount| *amount > 0);
    amounts.sort_unstable_by(|left, right| right.cmp(left));
    let balance = context.ruleset().science_balance();
    amounts
        .into_iter()
        .enumerate()
        .try_fold(0_i64, |total, (index, amount)| {
            let multiplier = match index {
                0 => 10_000,
                1 => balance.second_science_building_multiplier_basis_points(),
                _ => balance.later_science_building_multiplier_basis_points(),
            };
            checked_sum([total, scale_rounded(amount, multiplier)?])
        })
}

fn artifact_science_for_city(state: &GameState, city_id: &CityId) -> Result<i64, ResearchError> {
    i64::try_from(
        state
            .artifacts()
            .iter()
            .filter(|artifact| {
                artifact.artifact_type() == WorldArtifactType::AstronomersTablets
                    && artifact.location() == &WorldArtifactLocation::Stored(city_id.clone())
            })
            .count(),
    )
    .map_err(|_| invalid("stored science artifact count exceeds i64"))
}

fn wonder_science_per_city(
    state: &GameState,
    context: EngineContext<'_>,
    player: &PlayerId,
) -> Result<i64, ResearchError> {
    state
        .wonder_registry()
        .completed_by()
        .iter()
        .filter(|(_, owner)| *owner == player)
        .try_fold(0_i64, |total, (wonder, _)| {
            let amount = context
                .ruleset()
                .production()
                .wonder(*wonder)
                .ok_or_else(|| invalid("completed wonder is absent from production content"))?
                .empire_science_per_city();
            checked_sum([total, amount])
        })
}

fn replace_research(state: GameState, research: ResearchState) -> Result<GameState, ResearchError> {
    if state.research() == &research {
        return Ok(state);
    }
    let update = ResearchStateUpdate {
        revision: state.revision(),
        knowledge: KnowledgeState::new(research, state.wonder_registry().clone()),
        interaction: state.interaction().clone(),
    };
    state
        .into_after_research(update)
        .map_err(|error| invalid(error.to_string()))
}

fn player_research<'state>(
    state: &'state GameState,
    player: &PlayerId,
) -> &'state aonw_domain::PlayerResearchState {
    super::rules::player_research(state, player)
}

fn push_source(
    output: &mut Vec<ScienceYieldSource>,
    city: &City,
    amount: i64,
    kind: ScienceYieldSourceKind,
) {
    if amount > 0 {
        output.push(ScienceYieldSource::new(city.id().clone(), amount, kind));
    }
}

fn scale_rounded(amount: i64, basis_points: u32) -> Result<i64, ResearchError> {
    amount
        .checked_mul(i64::from(basis_points))
        .and_then(|value| value.checked_add(BASIS_POINTS / 2))
        .and_then(|value| value.checked_div(BASIS_POINTS))
        .ok_or_else(|| invalid("science building multiplier overflow"))
}

fn checked_sum(values: impl IntoIterator<Item = i64>) -> Result<i64, ResearchError> {
    values.into_iter().try_fold(0_i64, |sum, value| {
        sum.checked_add(value)
            .ok_or_else(|| invalid("science yield overflow"))
    })
}

fn invalid(message: impl Into<Box<str>>) -> ResearchError {
    ResearchError::InvalidState(message.into())
}
