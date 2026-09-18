use std::collections::BTreeMap;

use aonw_content::RulesetDefinition;
use aonw_contracts::client::{ClientQueryDto, ClientRequestBodyDto};
use aonw_domain::{
    City, CityBuildingType, CityId, CityProductionQueue, CityProductionTarget, CityProjectType,
    CitySpecializationType, EconomyState, GameMode, GameState, HexCoord,
    InitialResourceDistribution, KnowledgeState, MatchIdentity, MatchLifecycle, MatchRules,
    Participant, PlayerCountry, PlayerId, PlayerKind, PlayerResearchState, PlayerTurnState,
    ResearchState, StateRevision, StrategicResourceStockpile, TechnologyId, TurnLifecycle, Unit,
    UnitId, UnitKind, WonderRegistry,
};
use aonw_local_runtime::{ClientProtocol, LocalRuntime, OpenSession};

use super::{client_request, map, report_with_setup, signature_bytes};

pub(super) fn benchmark(unit_count: usize) {
    for (name, target) in [
        ("idle", None),
        (
            "building",
            Some(CityProductionTarget::Building(CityBuildingType::Housing)),
        ),
        (
            "completed_unit",
            Some(CityProductionTarget::Unit(UnitKind::Warrior)),
        ),
        (
            "project",
            Some(CityProductionTarget::Project(CityProjectType::Research)),
        ),
    ] {
        let base = opened(unit_count, target);
        let request = client_request(ClientRequestBodyDto::Query {
            query: ClientQueryDto::ProductionOptions {
                expected_revision: 0,
                city_id: "capital".to_owned(),
            },
        });
        validate_fixture(base.clone(), &request, unit_count, name);
        report_with_setup(
            &format!("client_json_production_{name}"),
            unit_count,
            || base.clone(),
            |mut runtime| {
                let response = ClientProtocol::dispatch_json(&mut runtime, &request);
                (signature_bytes(&response), response.len())
            },
        );
    }
}

fn validate_fixture(mut runtime: LocalRuntime, request: &str, unit_count: usize, name: &str) {
    let response = ClientProtocol::dispatch_json(&mut runtime, request);
    let value: serde_json::Value = serde_json::from_str(&response).expect("production response");
    let result = &value["outcome"]["response"]["result"];
    assert_eq!(result["type"], "productionOptions");
    assert_eq!(result["buildings"].as_array().expect("buildings").len(), 59);
    assert_eq!(result["units"].as_array().expect("units").len(), 17);
    if name == "completed_unit" {
        let warrior = result["units"]
            .as_array()
            .expect("units")
            .iter()
            .find(|unit| unit["option"]["target"]["unitType"] == "warrior")
            .expect("warrior");
        assert_eq!(
            warrior["option"]["forecast"]["spawnBlocked"],
            unit_count == 512
        );
    }
}

pub(super) fn opened(unit_count: usize, target: Option<CityProductionTarget>) -> LocalRuntime {
    let map = map();
    let ruleset = RulesetDefinition::standard();
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
    let economy = EconomyState::try_new(
        &identity,
        map.bounds(),
        BTreeMap::from([(actor.clone(), 1000)]),
        BTreeMap::new(),
        BTreeMap::new(),
        BTreeMap::new(),
        InitialResourceDistribution::default(),
    )
    .expect("economy");
    let city = City::builder(
        CityId::new("capital").expect("city id"),
        actor.clone(),
        "Capital",
        HexCoord::new(1, 1),
    )
    .with_buildings([CityBuildingType::Granary])
    .with_production(target.map(queue), 3)
    .build()
    .expect("city")
    .with_specialization(Some(CitySpecializationType::Industry));
    let research = ResearchState::try_new([(
        actor.clone(),
        PlayerResearchState::try_new(
            [
                TechnologyId::Craftsmanship,
                TechnologyId::Writing,
                TechnologyId::Logistics,
            ],
            None,
            [],
            0,
        )
        .expect("player research"),
    )])
    .expect("research");
    let units = (0..30)
        .flat_map(|row| (0..40).map(move |col| HexCoord::new(col, row)))
        .take(unit_count)
        .enumerate()
        .map(|(index, position)| {
            Unit::builder(
                UnitId::new(format!("unit-{index}")).expect("unit id"),
                actor.clone(),
                UnitKind::Warrior,
                "Guard",
                position,
                ruleset
                    .unit(UnitKind::Warrior)
                    .expect("unit")
                    .maximum_movement(false),
            )
            .build()
            .expect("unit")
        });
    let state = GameState::builder(
        StateRevision::INITIAL,
        1,
        map.bounds(),
        ruleset.occupancy_policy(),
        units,
    )
    .with_cities([city])
    .with_economy(economy)
    .with_knowledge(KnowledgeState::new(research, WonderRegistry::default()))
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state");
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(map, ruleset.clone(), state, actor))
        .expect("runtime");
    runtime
}

fn queue(target: CityProductionTarget) -> CityProductionQueue {
    let production = RulesetDefinition::standard().production();
    let investment = match target {
        CityProductionTarget::Unit(unit) => production
            .unit_cost(
                production.unit(unit).expect("unit").base_cost(),
                aonw_domain::PaceProfile::Unlimited,
            )
            .expect("cost"),
        CityProductionTarget::Building(_) => 2,
        CityProductionTarget::Project(_) => 0,
        CityProductionTarget::Wonder(_) => unreachable!("benchmark targets"),
    };
    CityProductionQueue::try_new(target, investment, StrategicResourceStockpile::default())
        .expect("queue")
}
