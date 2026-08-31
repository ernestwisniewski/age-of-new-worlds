//! Runtime and client-protocol coverage for engine-owned city yields.

use std::collections::BTreeMap;

use aonw_content::{
    GridLayout, MapDefinition, ResourceType as MapResourceType, RulesetDefinition, TerrainType,
    TileDefinition,
};
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientOutcomeDto, ClientQueryDto, ClientQueryResultDto,
    ClientRequestBodyDto, ClientRequestDto, ClientResponseBodyDto,
};
use aonw_contracts::{FieldImprovementKindDto, ResourceTypeDto};
use aonw_domain::{
    City, CityId, EconomyState, FieldImprovement, FieldImprovementKind, GameMode, GameState,
    HexCoord, InfrastructureState, InitialResourceDistribution, KnowledgeState, MatchIdentity,
    MatchLifecycle, MatchRules, Participant, PlayerCountry, PlayerId, PlayerKind,
    PlayerResearchState, PlayerTurnState, ResearchState, ResourceType, StateRevision,
    StrategicResourceStockpile, TechnologyId, TransportNetwork, TurnLifecycle, WonderRegistry,
};
use aonw_engine::YieldValue;
use aonw_local_runtime::{
    CityExpansionOptionsRequest, CityWorkedHexOptionsRequest, CityYieldRequest, ClientProtocol,
    LocalRuntime, OpenSession, RuntimeQuery, RuntimeQueryResult,
};

#[test]
fn runtime_and_protocol_return_the_same_city_yield() {
    let map = map();
    let ruleset = RulesetDefinition::standard().clone();
    let actor = PlayerId::new("player-1").expect("player");
    let city_id = CityId::new("city-1").expect("city");
    let state = state(&map, &ruleset, &actor, &city_id);
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(map, ruleset, state, actor))
        .expect("open");

    let ClientOutcomeDto::Success { response } = ClientProtocol::dispatch(
        &mut runtime,
        ClientRequestDto {
            api_version: CLIENT_API_VERSION,
            request: ClientRequestBodyDto::Snapshot,
        },
    )
    .outcome
    else {
        panic!("snapshot success")
    };
    let ClientResponseBodyDto::Snapshot { snapshot } = *response else {
        panic!("snapshot response")
    };
    assert_eq!(snapshot.economy.gold, 73);
    assert_eq!(snapshot.economy.war_weariness, 5);
    assert_eq!(snapshot.economy.stability_net, -4);
    assert_eq!(snapshot.economy.strategic_resource_stockpile.len(), 1);
    assert_eq!(
        snapshot.economy.strategic_resource_stockpile[0].resource,
        ResourceTypeDto::Oil
    );
    assert_eq!(snapshot.economy.strategic_resource_stockpile[0].amount, 2);
    assert_eq!(snapshot.economy.strategic_resource_output.len(), 1);
    assert_eq!(snapshot.economy.strategic_resource_sources.len(), 1);

    assert_city_query_cache(&mut runtime, &city_id);

    let request = ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request: ClientRequestBodyDto::Query {
            query: ClientQueryDto::CityYield {
                expected_revision: 9,
                city_id: city_id.as_str().to_owned(),
            },
        },
    };
    let ClientOutcomeDto::Success { response } =
        ClientProtocol::dispatch(&mut runtime, request).outcome
    else {
        panic!("protocol success")
    };
    let ClientResponseBodyDto::Query {
        result: ClientQueryResultDto::CityYield { total, .. },
    } = *response
    else {
        panic!("protocol city yield")
    };
    assert_eq!((total.food, total.production, total.gold), (2, 1, 0));

    let projection = ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request: ClientRequestBodyDto::Query {
            query: ClientQueryDto::StrategicResourceProjection {
                expected_revision: 9,
            },
        },
    };
    let ClientOutcomeDto::Success { response } =
        ClientProtocol::dispatch(&mut runtime, projection).outcome
    else {
        panic!("projection success")
    };
    let ClientResponseBodyDto::Query {
        result:
            ClientQueryResultDto::StrategicResourceProjection {
                output, sources, ..
            },
    } = *response
    else {
        panic!("protocol projection")
    };
    assert_eq!(output.len(), 1);
    assert_eq!(output[0].resource, ResourceTypeDto::Oil);
    assert_eq!(output[0].amount, 1);
    assert_eq!(sources.len(), 1);
    assert_eq!(sources[0].city_id, "city-1");
    assert_eq!(
        sources[0].coordinate,
        aonw_contracts::CoordinateDto { col: 0, row: 0 }
    );
    assert_eq!(sources[0].resource, ResourceTypeDto::Oil);
    assert_eq!(sources[0].improvement, FieldImprovementKindDto::OilWell);
    assert_eq!(sources[0].amount_per_turn, 1);
}

fn assert_city_query_cache(runtime: &mut LocalRuntime, city_id: &CityId) {
    let query = RuntimeQuery::CityYield(CityYieldRequest {
        expected_revision: 9,
        city_id: city_id.clone(),
    });
    let RuntimeQueryResult::CityYield { breakdown, .. } =
        runtime.query(&query).expect("runtime query")
    else {
        panic!("city yield result")
    };
    assert_eq!(breakdown.total(), YieldValue::new(2, 1, 0, 0));
    assert_eq!(
        runtime.query(&query).expect("cached query"),
        runtime.query(&query).expect("cached query")
    );
    assert_eq!(runtime.query_cache_stats().hits, 2);
    assert!(matches!(
        runtime
            .query(&RuntimeQuery::CityWorkedHexOptions(
                CityWorkedHexOptionsRequest {
                    expected_revision: 9,
                    city_id: city_id.clone(),
                }
            ))
            .expect("worked options"),
        RuntimeQueryResult::CityWorkedHexOptions { .. }
    ));
    assert!(matches!(
        runtime
            .query(&RuntimeQuery::CityExpansionOptions(
                CityExpansionOptionsRequest {
                    expected_revision: 9,
                    city_id: city_id.clone(),
                }
            ))
            .expect("expansion options"),
        RuntimeQueryResult::CityExpansionOptions { .. }
    ));
}

fn map() -> MapDefinition {
    MapDefinition::try_new(
        "economy-runtime",
        GridLayout::OddQFlatTop,
        1,
        1,
        vec![
            TileDefinition::try_new_for_simulation(
                HexCoord::new(0, 0),
                vec![TerrainType::Plains],
                vec![MapResourceType::Oil],
                0,
            )
            .expect("tile"),
        ],
        Vec::new(),
    )
    .expect("map")
}

fn state(
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    actor: &PlayerId,
    city_id: &CityId,
) -> GameState {
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [Participant::try_new(
            actor.clone(),
            "Player",
            0xff00_0000,
            PlayerCountry::Poland,
            PlayerKind::Human,
            None,
        )
        .expect("participant")],
        GameMode::HotSeat,
    )
    .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([(actor.clone(), PlayerTurnState::Active)]),
        [actor.clone()],
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("turn lifecycle");
    let city = City::builder(
        city_id.clone(),
        actor.clone(),
        "Capital",
        HexCoord::new(0, 0),
    )
    .build()
    .expect("city");
    let infrastructure = InfrastructureState::try_new(
        [FieldImprovement::new(
            HexCoord::new(0, 0),
            FieldImprovementKind::OilWell,
            Some(city_id.clone()),
        )],
        TransportNetwork::default(),
    )
    .expect("infrastructure");
    let research = ResearchState::try_new([(
        actor.clone(),
        PlayerResearchState::try_new([TechnologyId::Combustion], None, [], 0).expect("research"),
    )])
    .expect("research state");
    let economy = EconomyState::try_new(
        &identity,
        map.bounds(),
        BTreeMap::from([(actor.clone(), 73)]),
        BTreeMap::from([(actor.clone(), 5)]),
        BTreeMap::from([(actor.clone(), -4)]),
        BTreeMap::from([(
            actor.clone(),
            StrategicResourceStockpile::try_new(BTreeMap::from([(ResourceType::Oil, 2)]))
                .expect("stockpile"),
        )]),
        InitialResourceDistribution::default(),
    )
    .expect("economy");
    GameState::builder(
        StateRevision::new(9),
        4,
        map.bounds(),
        ruleset.occupancy_policy(),
        [],
    )
    .with_cities([city])
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .with_economy(economy)
    .with_infrastructure(infrastructure)
    .with_knowledge(KnowledgeState::new(research, WonderRegistry::default()))
    .try_build()
    .expect("state")
}
