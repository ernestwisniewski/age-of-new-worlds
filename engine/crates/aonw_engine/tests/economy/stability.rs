use super::*;

#[test]
fn cityless_empire_forecast_never_creates_a_negative_city_cost() {
    let map = forecast_map();
    let actor = player("player-1");
    let state = state_with_economy_parts(
        &map,
        vec![unit(
            "commander-1",
            &actor,
            UnitKind::Commander,
            HexCoord::new(0, 0),
        )],
        Vec::new(),
        InteractionState::default(),
        InfrastructureState::default(),
        Vec::new(),
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());

    let QueryResult::EconomyForecast(forecast) = GameEngine::query(
        &state,
        context,
        GameQuery::EconomyForecast(EconomyForecastQuery::new(9)),
    )
    .expect("cityless economy forecast") else {
        panic!("economy forecast result")
    };

    assert_eq!(forecast.stability().city_cost(), 0);
    assert_eq!(forecast.stability().cost_total(), 0);
}
