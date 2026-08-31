use aonw_domain::{
    City, CityProductionTarget, EconomyAccountChange, EconomyState, GameState, KnowledgeState,
    PlayerId, WonderType,
};

use super::ProductionError;
use super::support::{invalid, pace};
use crate::{
    CityBuiltWonderEvent, DomainEvent, EngineContext, TechnologyResearchedEvent,
    WonderProductionRefundedEvent,
};

pub(super) struct WonderResolution {
    pub cities: Vec<City>,
    pub economy: EconomyState,
    pub knowledge: KnowledgeState,
    pub events: Vec<DomainEvent>,
}

pub(super) fn resolve_completed_for_player(
    state: &GameState,
    context: EngineContext<'_>,
    cities: Vec<City>,
    economy: EconomyState,
    player: &PlayerId,
) -> Result<WonderResolution, ProductionError> {
    resolve_completed(state, context, cities, economy, Some(player))
}

pub(super) fn resolve_completed(
    state: &GameState,
    context: EngineContext<'_>,
    mut cities: Vec<City>,
    mut economy: EconomyState,
    player: Option<&PlayerId>,
) -> Result<WonderResolution, ProductionError> {
    let mut knowledge = state.knowledge().clone();
    let mut events = Vec::new();
    for index in 0..cities.len() {
        let city = cities[index].clone();
        if player.is_some_and(|player| city.owner_player_id() != player) {
            continue;
        }
        let Some(queue) = city.production_queue() else {
            continue;
        };
        let CityProductionTarget::Wonder(wonder) = queue.target() else {
            continue;
        };
        let definition = context
            .ruleset()
            .production()
            .wonder(wonder)
            .ok_or_else(|| invalid("queued wonder is absent from production content"))?;
        let cost = context
            .ruleset()
            .production()
            .building_cost(definition.base_cost(), pace(state))
            .ok_or_else(|| invalid("wonder production cost overflow"))?;
        if queue.invested_production() < cost {
            continue;
        }
        if knowledge
            .wonder_registry()
            .completed_by()
            .contains_key(&wonder)
        {
            cities[index] = refund_city(&city, wonder, &mut events)?;
            continue;
        }

        let owner = city.owner_player_id().clone();
        events.push(DomainEvent::CityBuiltWonder(CityBuiltWonderEvent::new(
            city.id().clone(),
            owner.clone(),
            wonder,
        )));
        if definition.grants_free_active_technology()
            && let Some(current) = knowledge.research().players().get(&owner)
        {
            let (updated, completed) = current.after_unlocking_active();
            if let Some(technology) = completed {
                let research = knowledge.research().updating_player(owner.clone(), updated);
                knowledge = KnowledgeState::new(research, knowledge.wonder_registry().clone());
                events.push(DomainEvent::TechnologyResearched(
                    TechnologyResearchedEvent::new(owner.clone(), technology),
                ));
            }
        }
        if definition.grant_gold() > 0 {
            economy = economy
                .try_after_changes(
                    state.match_lifecycle().identity(),
                    state.bounds(),
                    [EconomyAccountChange::Gold {
                        player: owner.clone(),
                        delta: definition.grant_gold(),
                    }],
                )
                .map_err(|error| invalid(error.to_string()))?;
        }
        let registry = knowledge
            .wonder_registry()
            .try_with_completed(wonder, owner)
            .map_err(|error| invalid(error.to_string()))?;
        knowledge = KnowledgeState::new(knowledge.research().clone(), registry);

        settle_wonder_queues(
            &mut cities,
            index,
            wonder,
            cost,
            definition.production_burst(),
            &mut events,
        )?;
    }
    Ok(WonderResolution {
        cities,
        economy,
        knowledge,
        events,
    })
}

fn settle_wonder_queues(
    cities: &mut [City],
    winner_index: usize,
    wonder: WonderType,
    cost: i64,
    production_burst: i64,
    events: &mut Vec<DomainEvent>,
) -> Result<(), ProductionError> {
    for (candidate_index, slot) in cities.iter_mut().enumerate() {
        let candidate = slot.clone();
        let matches = candidate
            .production_queue()
            .is_some_and(|queue| queue.target() == CityProductionTarget::Wonder(wonder));
        if !matches {
            continue;
        }
        if candidate_index == winner_index {
            let invested = candidate
                .production_queue()
                .expect("wonder host queue")
                .invested_production();
            let overflow = invested
                .saturating_sub(cost)
                .checked_add(production_burst)
                .ok_or_else(|| invalid("wonder completion overflow"))?;
            *slot = candidate
                .try_with_completed_wonder(wonder)
                .and_then(|completed| completed.try_with_production(None, overflow))
                .map_err(|error| invalid(error.to_string()))?;
        } else {
            *slot = refund_city(&candidate, wonder, events)?;
        }
    }
    Ok(())
}

fn refund_city(
    city: &City,
    wonder: WonderType,
    events: &mut Vec<DomainEvent>,
) -> Result<City, ProductionError> {
    let queue = city
        .production_queue()
        .ok_or_else(|| invalid("wonder refund queue disappeared"))?;
    let refunded = queue.invested_production();
    let overflow = city
        .production_overflow()
        .checked_add(refunded)
        .ok_or_else(|| invalid("wonder refund overflow"))?;
    events.push(DomainEvent::WonderProductionRefunded(
        WonderProductionRefundedEvent::new(
            city.id().clone(),
            city.owner_player_id().clone(),
            wonder,
            refunded,
        ),
    ));
    city.try_with_production(None, overflow)
        .map_err(|error| invalid(error.to_string()))
}
