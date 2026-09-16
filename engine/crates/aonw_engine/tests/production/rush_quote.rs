use aonw_domain::{
    City, CityBuildingType, CityId, CityProductionTarget, CityProjectType, UnitKind, WonderType,
};
use aonw_engine::{
    CommandRejectionCode, EngineContext, GameEngine, GameQuery, PlayerCommand,
    ProductionOptionsQuery, ProductionRushQuote, QueryResult, RushProductionCommand,
};

use super::{
    map, paced_building_cost, paced_unit_cost, paced_wonder_cost, player, queued_city,
    state_with_accounts,
};

#[test]
fn displayed_rush_prices_match_building_unit_and_wonder_commands() {
    let map = map();
    let actor = player();
    let id = CityId::new("capital").expect("city id");
    let context =
        EngineContext::canonical(&actor, &map, aonw_content::RulesetDefinition::standard());
    for (target, cost) in [
        (
            CityProductionTarget::Building(CityBuildingType::Housing),
            paced_building_cost(CityBuildingType::Housing),
        ),
        (
            CityProductionTarget::Unit(UnitKind::Warrior),
            paced_unit_cost(UnitKind::Warrior),
        ),
        (
            CityProductionTarget::Wonder(WonderType::GreatWall),
            paced_wonder_cost(WonderType::GreatWall),
        ),
    ] {
        for invested in [0, cost - 1] {
            let city = queued_city(&id, &actor, target, invested);
            let state = state_with_accounts(&map, &actor, vec![city], Vec::new(), 1000, None);
            let quote = query_quote(&state, context, &id);
            assert_eq!(quote.rejection(), None);
            assert!(quote.production() > 0 && quote.production() <= cost - invested);
            let result = GameEngine::apply_player_owned(
                state,
                context,
                PlayerCommand::RushProduction(RushProductionCommand::new(9, &id)),
            )
            .expect("rush");
            assert!(result.is_accepted());
            assert_eq!(
                result.state().economy().player_gold().get(&actor),
                Some(&(1000 - quote.gold_cost()))
            );
            if let Some(queue) = result.state().city(&id).expect("city").production_queue() {
                assert_eq!(queue.invested_production(), invested + quote.production());
            } else {
                assert_eq!(invested + quote.production(), cost);
            }
        }
    }
}

#[test]
fn unaffordable_quotes_keep_the_price_and_match_command_rejection() {
    let map = map();
    let actor = player();
    let id = CityId::new("capital").expect("city id");
    let target = CityProductionTarget::Building(CityBuildingType::Housing);
    let context =
        EngineContext::canonical(&actor, &map, aonw_content::RulesetDefinition::standard());
    let city = queued_city(
        &id,
        &actor,
        target,
        paced_building_cost(CityBuildingType::Housing) - 1,
    );
    let state = state_with_accounts(&map, &actor, vec![city], Vec::new(), 1, None);
    let quote = query_quote(&state, context, &id);
    assert_eq!(quote.production(), 1);
    assert_eq!(quote.gold_cost(), 2);
    assert_eq!(
        quote.rejection(),
        Some(CommandRejectionCode::RushProductionUnavailable)
    );
    let result = GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::RushProduction(RushProductionCommand::new(9, &id)),
    )
    .expect("rush rejection");
    assert_eq!(
        result.rejection().map(aonw_engine::DomainRejection::code),
        quote.rejection()
    );
    assert_eq!(result.state().economy().player_gold().get(&actor), Some(&1));
}

#[test]
fn empty_continuous_and_completed_queues_have_no_rush_price() {
    let map = map();
    let actor = player();
    let id = CityId::new("capital").expect("city id");
    let context =
        EngineContext::canonical(&actor, &map, aonw_content::RulesetDefinition::standard());
    for (city, rejection) in [
        (
            City::new(
                id.clone(),
                actor.clone(),
                aonw_domain::HexCoord::new(2, 2),
                [],
            ),
            CommandRejectionCode::ProductionQueueEmpty,
        ),
        (
            queued_city(
                &id,
                &actor,
                CityProductionTarget::Project(CityProjectType::Wealth),
                0,
            ),
            CommandRejectionCode::ProjectCannotBeRushed,
        ),
        (
            queued_city(
                &id,
                &actor,
                CityProductionTarget::Building(CityBuildingType::Housing),
                paced_building_cost(CityBuildingType::Housing),
            ),
            CommandRejectionCode::RushProductionUnavailable,
        ),
    ] {
        let state = state_with_accounts(&map, &actor, vec![city], Vec::new(), 1000, None);
        let quote = query_quote(&state, context, &id);
        assert_eq!(quote.production(), 0);
        assert_eq!(quote.gold_cost(), 0);
        assert_eq!(quote.rejection(), Some(rejection));
        let result = GameEngine::apply_player_owned(
            state,
            context,
            PlayerCommand::RushProduction(RushProductionCommand::new(9, &id)),
        )
        .expect("rush rejection");
        assert_eq!(
            result.rejection().map(aonw_engine::DomainRejection::code),
            quote.rejection()
        );
    }
}

fn query_quote(
    state: &aonw_domain::GameState,
    context: EngineContext<'_>,
    city_id: &CityId,
) -> ProductionRushQuote {
    let QueryResult::ProductionOptions(options) = GameEngine::query(
        state,
        context,
        GameQuery::ProductionOptions(ProductionOptionsQuery::new(9, city_id)),
    )
    .expect("production query") else {
        panic!("production options")
    };
    options.rush_quote()
}
