use std::sync::LazyLock;

use aonw_content::{TechnologyBoostCondition, TechnologyDefinition};
use aonw_domain::{GameState, PlayerId, PlayerResearchState, TechnologyId};

use super::{ResearchError, ResearchOption, ResearchOptions, ResearchOptionsQuery};
use crate::{CommandRejectionCode, EngineContext, TechnologyUnlockQuery};

pub(crate) fn query_options(
    state: &GameState,
    context: EngineContext<'_>,
    query: ResearchOptionsQuery,
) -> Result<ResearchOptions, ResearchError> {
    validate_revision(state, query.expected_revision())?;
    let actor = context.actor_player_id();
    if !state.match_lifecycle().identity().contains(actor) {
        return Err(CommandRejectionCode::TechnologyPlayerNotControlled.into());
    }
    let research = player_research(state, actor);
    let project_science =
        crate::production::selected_research_project_science(state, context, actor)
            .map_err(|error| ResearchError::InvalidState(error.to_string().into()))?;
    let science_yield = super::turn::science_yield(state, context, actor, &project_science)?;
    let city_count = owned_city_count(state, actor)?;
    let pace = state
        .match_lifecycle()
        .identity()
        .match_rules()
        .game_length()
        .pace_profile();
    let unlocks = TechnologyUnlockQuery::new(context.ruleset(), research);
    let mut options = Vec::with_capacity(context.ruleset().technologies().len());
    for definition in context.ruleset().technologies() {
        let technology = definition.id();
        let discount = best_boost_discount(state, context, actor, *definition);
        options.push(ResearchOption::new(
            technology,
            unlocks.availability(technology)?,
            unlocks.effective_cost_with_discount(technology, city_count, discount, pace)?,
            research
                .progress_by_technology_id()
                .get(&technology)
                .copied()
                .unwrap_or(0),
            discount,
            definition
                .prerequisites()
                .iter()
                .map(|required| required.domain())
                .collect::<Vec<_>>(),
            definition
                .blocked_by()
                .iter()
                .map(|blocked| blocked.domain())
                .collect::<Vec<_>>(),
            definition.unlocks().to_vec(),
        ));
    }
    Ok(ResearchOptions::new(
        actor.clone(),
        research.active_technology_id(),
        research.science_overflow(),
        science_yield,
        options,
    ))
}

pub(super) fn selection_cost(
    state: &GameState,
    context: EngineContext<'_>,
    player: &PlayerId,
    technology: TechnologyId,
) -> Result<u32, ResearchError> {
    let definition = context.ruleset().technology(technology).ok_or(
        crate::TechnologyQueryError::TechnologyNotInRuleset(technology),
    )?;
    let discount = best_boost_discount(state, context, player, definition);
    let pace = state
        .match_lifecycle()
        .identity()
        .match_rules()
        .game_length()
        .pace_profile();
    TechnologyUnlockQuery::new(context.ruleset(), player_research(state, player))
        .effective_cost_with_discount(technology, owned_city_count(state, player)?, discount, pace)
        .map_err(Into::into)
}

pub(super) fn player_research<'state>(
    state: &'state GameState,
    player: &PlayerId,
) -> &'state PlayerResearchState {
    state
        .research()
        .players()
        .get(player)
        .unwrap_or_else(|| empty_research())
}

pub(super) fn validate_revision(state: &GameState, expected: u64) -> Result<(), ResearchError> {
    if state.revision().get() == expected {
        Ok(())
    } else {
        Err(CommandRejectionCode::StaleRevision.into())
    }
}

fn owned_city_count(state: &GameState, player: &PlayerId) -> Result<u32, ResearchError> {
    u32::try_from(
        state
            .cities()
            .iter()
            .filter(|city| city.owner_player_id() == player)
            .count(),
    )
    .map_err(|_| ResearchError::InvalidState("owned city count exceeds u32".into()))
}

fn best_boost_discount(
    state: &GameState,
    context: EngineContext<'_>,
    player: &PlayerId,
    definition: TechnologyDefinition,
) -> u32 {
    definition
        .boosts()
        .iter()
        .filter(|boost| boost_is_fulfilled(state, context, player, boost.condition()))
        .map(|boost| boost.discount_basis_points())
        .max()
        .unwrap_or(0)
}

fn boost_is_fulfilled(
    state: &GameState,
    context: EngineContext<'_>,
    player: &PlayerId,
    condition: TechnologyBoostCondition,
) -> bool {
    match condition {
        TechnologyBoostCondition::ImprovementCount { improvement, count } => {
            state
                .field_improvements()
                .iter()
                .filter(|candidate| {
                    candidate.kind() == improvement.domain()
                        && improvement_is_owned(state, player, candidate)
                })
                .count()
                >= usize::try_from(count).unwrap_or(usize::MAX)
        }
        TechnologyBoostCondition::ControlsAnyResource { resources } => state
            .cities()
            .iter()
            .filter(|city| city.owner_player_id() == player)
            .flat_map(|city| {
                std::iter::once(city.center()).chain(city.controlled_hexes().iter().copied())
            })
            .any(|coordinate| {
                crate::economy::rules::resources_at(state, context, coordinate)
                    .iter()
                    .any(|resource| {
                        resources
                            .iter()
                            .any(|candidate| candidate.domain() == *resource)
                    })
            }),
    }
}

fn improvement_is_owned(
    state: &GameState,
    player: &PlayerId,
    improvement: &aonw_domain::FieldImprovement,
) -> bool {
    let built_by_owned_city = improvement.built_by_city_id().is_some_and(|city_id| {
        state
            .city(city_id)
            .is_some_and(|city| city.owner_player_id() == player)
    });
    built_by_owned_city
        || state
            .cities()
            .iter()
            .any(|city| city.owner_player_id() == player && city.controls(improvement.coordinate()))
}

fn empty_research() -> &'static PlayerResearchState {
    static EMPTY: LazyLock<PlayerResearchState> = LazyLock::new(PlayerResearchState::default);
    &EMPTY
}
