//! Current-only production protocol, runtime, save, and replay coverage.

use std::collections::BTreeMap;

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientCommandDto, ClientCommandOutcomeDto, ClientEventDto,
    ClientOutcomeDto, ClientQueryDto, ClientQueryResultDto, ClientRequestBodyDto, ClientRequestDto,
    ClientResponseBodyDto, ClientResponseDto,
};
use aonw_contracts::{
    CityBuildingTypeDto, CityProjectTypeDto, CitySpecializationTypeDto, UnitKindDto, WonderTypeDto,
};
use aonw_domain::{
    City, CityBuildingType, CityId, CityProductionQueue, CityProductionTarget, EconomyState,
    GameMode, GameState, HexCoord, InitialResourceDistribution, KnowledgeState, MatchIdentity,
    MatchLifecycle, MatchRules, Participant, PlayerCountry, PlayerId, PlayerKind,
    PlayerResearchState, PlayerTurnState, ProductionStateUpdate, ResearchState, StateRevision,
    StrategicResourceStockpile, TechnologyId, TurnLifecycle, UnitKind, WonderRegistry, WonderType,
};
use aonw_local_runtime::{ClientProtocol, LocalRuntime, OpenSession};

#[test]
fn production_protocol_query_commands_save_and_replay_are_exact() {
    let query = dispatch_client(
        &mut opened_runtime(),
        ClientRequestBodyDto::Query {
            query: ClientQueryDto::ProductionOptions {
                expected_revision: 9,
                city_id: "capital".to_owned(),
            },
        },
    );
    let ClientResponseBodyDto::Query {
        result:
            ClientQueryResultDto::ProductionOptions {
                buildings,
                units,
                projects,
                wonders,
                specializations,
                ..
            },
    } = query
    else {
        panic!("production options response")
    };
    assert_eq!(
        (
            buildings.len(),
            units.len(),
            projects.len(),
            wonders.len(),
            specializations.len()
        ),
        (59, 17, 2, 11, 5)
    );

    for command in production_commands() {
        let response = dispatch_client(
            &mut opened_runtime(),
            ClientRequestBodyDto::Dispatch { command },
        );
        let ClientResponseBodyDto::Command { result } = response else {
            panic!("production command response")
        };
        assert_eq!(result.outcome, ClientCommandOutcomeDto::Accepted);
    }

    let (map, rules, state, actor) = fixture();
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(
            map.clone(),
            rules.clone(),
            state,
            actor,
        ))
        .expect("open replay runtime");
    let response = dispatch_client(
        &mut runtime,
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::RushProduction {
                expected_revision: 9,
                city_id: "capital".to_owned(),
            },
        },
    );
    assert!(matches!(response, ClientResponseBodyDto::Command { .. }));
    let save = runtime.export_save_json().expect("production save");
    let replay = runtime.export_replay_json().expect("production replay");
    let verification =
        LocalRuntime::verify_replay_json(map.clone(), rules.clone(), &replay).expect("replay");
    assert_eq!(verification.entry_count, 1);
    let mut reopened = LocalRuntime::default();
    reopened
        .open_save_json(map, rules, &save)
        .expect("production save reopen");
    assert_eq!(
        reopened.snapshot().expect("reopened snapshot").stamp(),
        runtime.snapshot().expect("source snapshot").stamp()
    );
}

#[test]
fn unit_and_wonder_completion_events_are_exact_through_client_and_replay() {
    let (map, rules, state, actor) = fixture();
    let unit_events = rush_events(
        map.clone(),
        rules.clone(),
        queued_completion_state(
            state,
            &rules,
            &actor,
            CityProductionTarget::Unit(UnitKind::Warrior),
            false,
        ),
        actor.clone(),
    );
    assert!(matches!(
        unit_events.as_slice(),
        [ClientEventDto::CityProducedUnit {
            unit_type: UnitKindDto::Warrior,
            ..
        }]
    ));

    let (_, _, state, _) = fixture();
    let wonder_events = rush_events(
        map,
        rules.clone(),
        queued_completion_state(
            state,
            &rules,
            &actor,
            CityProductionTarget::Wonder(WonderType::GreatLibrary),
            true,
        ),
        actor,
    );
    assert!(matches!(
        wonder_events.as_slice(),
        [
            ClientEventDto::CityBuiltWonder { .. },
            ClientEventDto::TechnologyResearched { .. },
            ClientEventDto::WonderProductionRefunded {
                refunded_production: 7,
                ..
            }
        ]
    ));
}

fn rush_events(
    map: MapDefinition,
    rules: RulesetDefinition,
    state: GameState,
    actor: PlayerId,
) -> Vec<ClientEventDto> {
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(
            map.clone(),
            rules.clone(),
            state,
            actor,
        ))
        .expect("open completion runtime");
    let response = dispatch_client(
        &mut runtime,
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::RushProduction {
                expected_revision: 9,
                city_id: "capital".to_owned(),
            },
        },
    );
    let ClientResponseBodyDto::Command { result } = response else {
        panic!("completion command response")
    };
    assert_eq!(result.outcome, ClientCommandOutcomeDto::Accepted);
    let replay = runtime.export_replay_json().expect("completion replay");
    assert_eq!(
        LocalRuntime::verify_replay_json(map, rules, &replay)
            .expect("completion replay verification")
            .entry_count,
        1
    );
    result.events
}

fn queued_completion_state(
    state: GameState,
    rules: &RulesetDefinition,
    actor: &PlayerId,
    target: CityProductionTarget,
    add_losing_wonder_queue: bool,
) -> GameState {
    let cost = match target {
        CityProductionTarget::Unit(unit) => rules.production().unit(unit).and_then(|definition| {
            rules
                .production()
                .unit_cost(definition.base_cost(), aonw_domain::PaceProfile::Unlimited)
        }),
        CityProductionTarget::Wonder(wonder) => {
            rules.production().wonder(wonder).and_then(|definition| {
                rules
                    .production()
                    .building_cost(definition.base_cost(), aonw_domain::PaceProfile::Unlimited)
            })
        }
        CityProductionTarget::Building(_) | CityProductionTarget::Project(_) => None,
    }
    .expect("finite completion cost");
    let queue =
        CityProductionQueue::try_new(target, cost - 1, StrategicResourceStockpile::default())
            .expect("completion queue");
    let mut cities = state.cities().to_vec();
    let capital = cities
        .iter_mut()
        .find(|city| city.id().as_str() == "capital")
        .expect("capital");
    *capital = capital
        .try_with_production(Some(queue), 0)
        .expect("replace queue");
    if add_losing_wonder_queue {
        let loser_queue =
            CityProductionQueue::try_new(target, 7, StrategicResourceStockpile::default())
                .expect("losing queue");
        cities.push(
            City::builder(
                CityId::new("loser").expect("city id"),
                actor.clone(),
                "Loser",
                HexCoord::new(4, 4),
            )
            .with_production(Some(loser_queue), 0)
            .build()
            .expect("losing city"),
        );
    }
    let knowledge = if target == CityProductionTarget::Wonder(WonderType::GreatLibrary) {
        KnowledgeState::new(
            ResearchState::try_new([(
                actor.clone(),
                PlayerResearchState::try_new(
                    [
                        TechnologyId::Craftsmanship,
                        TechnologyId::Writing,
                        TechnologyId::Specialization,
                    ],
                    Some(TechnologyId::Mathematics),
                    [(TechnologyId::Mathematics, 3)],
                    0,
                )
                .expect("active research"),
            )])
            .expect("research state"),
            WonderRegistry::default(),
        )
    } else {
        state.knowledge().clone()
    };
    let update = ProductionStateUpdate {
        revision: state.revision(),
        units: state.units().to_vec(),
        cities,
        economy: state.economy().clone(),
        knowledge,
        fog_of_war: state.fog_of_war().clone(),
        diplomacy: state.diplomacy().clone(),
    };
    state
        .into_after_production(update)
        .expect("completion state")
}

fn production_commands() -> [ClientCommandDto; 6] {
    [
        ClientCommandDto::StartBuilding {
            expected_revision: 9,
            city_id: "capital".to_owned(),
            building: CityBuildingTypeDto::Workshop,
        },
        ClientCommandDto::StartUnitProduction {
            expected_revision: 9,
            city_id: "capital".to_owned(),
            unit: UnitKindDto::Warrior,
            resource_option_index: None,
        },
        ClientCommandDto::StartCityProject {
            expected_revision: 9,
            city_id: "capital".to_owned(),
            project: CityProjectTypeDto::Research,
        },
        ClientCommandDto::StartWonder {
            expected_revision: 9,
            city_id: "capital".to_owned(),
            wonder: WonderTypeDto::GreatLibrary,
        },
        ClientCommandDto::SetCitySpecialization {
            expected_revision: 9,
            city_id: "capital".to_owned(),
            specialization: CitySpecializationTypeDto::Growth,
        },
        ClientCommandDto::RushProduction {
            expected_revision: 9,
            city_id: "capital".to_owned(),
        },
    ]
}

fn dispatch_client(
    runtime: &mut LocalRuntime,
    request: ClientRequestBodyDto,
) -> ClientResponseBodyDto {
    let document = ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request,
    }
    .to_json()
    .expect("client request JSON");
    let response = ClientResponseDto::from_json(&ClientProtocol::dispatch_json(runtime, &document))
        .expect("client response JSON");
    let ClientOutcomeDto::Success { response } = response.outcome else {
        panic!("client protocol failure: {:?}", response.outcome)
    };
    *response
}

fn opened_runtime() -> LocalRuntime {
    let (map, rules, state, actor) = fixture();
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(map, rules, state, actor))
        .expect("open production runtime");
    runtime
}

fn fixture() -> (MapDefinition, RulesetDefinition, GameState, PlayerId) {
    let map = map();
    let rules = RulesetDefinition::standard().clone();
    let actor = PlayerId::new("player-1").expect("player");
    let participant = Participant::try_new(
        actor.clone(),
        "Player",
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Human,
        None,
    )
    .expect("participant");
    let identity = MatchIdentity::try_new(MatchRules::default(), [participant], GameMode::HotSeat)
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
    .expect("lifecycle");
    let housing_cost = rules
        .production()
        .building(CityBuildingType::Housing)
        .and_then(|definition| {
            rules
                .production()
                .building_cost(definition.base_cost(), aonw_domain::PaceProfile::Unlimited)
        })
        .expect("housing cost");
    let queue = CityProductionQueue::try_new(
        CityProductionTarget::Building(CityBuildingType::Housing),
        housing_cost - 1,
        StrategicResourceStockpile::default(),
    )
    .expect("production queue");
    let city = City::builder(
        CityId::new("capital").expect("city id"),
        actor.clone(),
        "Capital",
        HexCoord::new(2, 2),
    )
    .with_buildings([CityBuildingType::Granary])
    .with_production(Some(queue), 0)
    .build()
    .expect("city");
    let research = ResearchState::try_new([(
        actor.clone(),
        PlayerResearchState::try_new(
            [
                TechnologyId::Craftsmanship,
                TechnologyId::Writing,
                TechnologyId::Specialization,
            ],
            None,
            [],
            0,
        )
        .expect("research"),
    )])
    .expect("research state");
    let economy = EconomyState::try_new(
        &identity,
        map.bounds(),
        BTreeMap::from([(actor.clone(), 100)]),
        BTreeMap::new(),
        BTreeMap::new(),
        BTreeMap::new(),
        InitialResourceDistribution::default(),
    )
    .expect("economy");
    let state = GameState::builder(
        StateRevision::new(9),
        4,
        map.bounds(),
        rules.occupancy_policy(),
        [],
    )
    .with_cities([city])
    .with_economy(economy)
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .with_knowledge(KnowledgeState::new(research, WonderRegistry::default()))
    .try_build()
    .expect("state");
    (map, rules, state, actor)
}

fn map() -> MapDefinition {
    MapDefinition::try_new(
        "production-runtime",
        GridLayout::OddQFlatTop,
        5,
        5,
        (0..5)
            .flat_map(|row| {
                (0..5).map(move |col| {
                    TileDefinition::try_new_for_simulation(
                        HexCoord::new(col, row),
                        vec![TerrainType::Plains],
                        Vec::new(),
                        0,
                    )
                    .expect("tile")
                })
            })
            .collect(),
        Vec::new(),
    )
    .expect("map")
}
