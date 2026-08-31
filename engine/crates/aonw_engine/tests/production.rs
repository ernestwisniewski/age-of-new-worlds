//! Production options and queue-command acceptance tests.

use std::collections::BTreeMap;

use aonw_content::{
    GridLayout, MapDefinition, ResourceType as ContentResourceType, RulesetDefinition,
    TechnologyKey, TerrainType, TileDefinition,
};
use aonw_domain::{
    City, CityBuildingType, CityId, CityProductionQueue, CityProductionTarget, CityProjectType,
    CitySpecializationType, EconomyState, FogOfWar, GameMode, GameState, HexCoord,
    InitialResourceDistribution, KnowledgeState, MatchIdentity, MatchLifecycle, MatchRules,
    MovementUnits, Participant, PlayerCountry, PlayerId, PlayerKind, PlayerResearchState,
    PlayerTurnState, ResearchState, ResourceType, StateRevision, StrategicResourceStockpile,
    TechnologyId, TurnLifecycle, Unit, UnitId, UnitKind, UnitOccupancyPolicy, WonderRegistry,
    WonderType,
};
use aonw_engine::{
    CanonicalEngineError, CommandRejectionCode, EngineContext, GameEngine, GameQuery,
    PlayerCommand, ProductionError, ProductionOptionsQuery, QueryResult,
    SetCitySpecializationCommand, StartBuildingCommand, StartCityProjectCommand,
    StartUnitProductionCommand, StartWonderCommand,
};

#[path = "production/constraints.rs"]
mod constraints;
#[path = "production/rush.rs"]
mod rush;

#[test]
fn options_and_start_commands_share_costs_gates_and_idempotence() {
    let map = map();
    let actor = player();
    let city_id = CityId::new("capital").expect("city id");
    let city = City::builder(
        city_id.clone(),
        actor.clone(),
        "Capital",
        HexCoord::new(2, 2),
    )
    .with_controlled_hexes([HexCoord::new(2, 1), HexCoord::new(1, 2)])
    .build()
    .expect("city");
    let state = state(&map, &actor, city, [], BTreeMap::new());
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());

    let QueryResult::ProductionOptions(options) = GameEngine::query(
        &state,
        context,
        GameQuery::ProductionOptions(ProductionOptionsQuery::new(9, &city_id)),
    )
    .expect("production options") else {
        panic!("production options result")
    };
    assert_eq!(options.buildings().len(), 59);
    assert_eq!(options.units().len(), 17);
    assert_eq!(options.projects().len(), 2);
    assert_eq!(options.wonders().len(), 11);
    assert_eq!(options.specializations().len(), 5);
    assert_eq!(options.revision(), 9);
    assert_eq!(options.city_id(), &city_id);
    assert_eq!(options.current_target(), None);
    assert_eq!(options.invested_production(), 0);
    assert_eq!(options.production_overflow(), 0);
    let granary = options
        .buildings()
        .iter()
        .find(|option| option.target() == CityProductionTarget::Building(CityBuildingType::Granary))
        .expect("granary");
    assert!(granary.is_available());
    assert_eq!(granary.cost(), 9);
    let started = GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::StartBuilding(StartBuildingCommand::new(
            9,
            &city_id,
            CityBuildingType::Granary,
        )),
    )
    .expect("start building");
    assert!(started.is_accepted());
    assert_eq!(started.revision().get(), 10);
    let queue = started
        .state()
        .city(&city_id)
        .expect("city")
        .production_queue()
        .expect("queue");
    assert_eq!(queue.target(), granary.target());

    let identity = GameEngine::apply_player_owned(
        started.state().clone(),
        context,
        PlayerCommand::StartBuilding(StartBuildingCommand::new(
            10,
            &city_id,
            CityBuildingType::Granary,
        )),
    )
    .expect("same target");
    assert!(identity.is_accepted());
    assert_eq!(identity.revision().get(), 10);

    let project = GameEngine::apply_player_owned(
        identity.state().clone(),
        context,
        PlayerCommand::StartCityProject(StartCityProjectCommand::new(
            10,
            &city_id,
            CityProjectType::Research,
        )),
    )
    .expect("start project");
    assert_eq!(project.revision().get(), 11);
    assert_eq!(
        project
            .state()
            .city(&city_id)
            .expect("city")
            .production_queue()
            .expect("queue")
            .target(),
        CityProductionTarget::Project(CityProjectType::Research)
    );
}

#[test]
fn locked_building_query_and_command_share_the_same_rejection() {
    let map = map();
    let actor = player();
    let city_id = CityId::new("capital").expect("city id");
    let city = City::new(city_id.clone(), actor.clone(), HexCoord::new(2, 2), []);
    let state = state(&map, &actor, city, [], BTreeMap::new());
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let QueryResult::ProductionOptions(options) = GameEngine::query(
        &state,
        context,
        GameQuery::ProductionOptions(ProductionOptionsQuery::new(9, &city_id)),
    )
    .expect("production options") else {
        panic!("production options result")
    };
    let workshop = options
        .buildings()
        .iter()
        .find(|option| {
            option.target() == CityProductionTarget::Building(CityBuildingType::Workshop)
        })
        .expect("workshop");
    assert_eq!(
        workshop.rejection(),
        Some(CommandRejectionCode::BuildingNotAvailable)
    );
    let rejected = GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::StartBuilding(StartBuildingCommand::new(
            9,
            &city_id,
            CityBuildingType::Workshop,
        )),
    )
    .expect("locked building rejection");
    assert_eq!(
        rejected.rejection().expect("rejection").code(),
        CommandRejectionCode::BuildingNotAvailable
    );
}

#[test]
fn strategic_reservation_is_refunded_and_replaced_atomically() {
    let map = map();
    let actor = player();
    let city_id = CityId::new("capital").expect("city id");
    let city = City::new(city_id.clone(), actor.clone(), HexCoord::new(2, 2), []);
    let research = [TechnologyId::MassProduction];
    let mut oil = BTreeMap::new();
    oil.insert(ResourceType::Oil, 2);
    let stockpile = StrategicResourceStockpile::try_new(oil).expect("oil");
    let mut strategic = BTreeMap::new();
    strategic.insert(actor.clone(), stockpile);
    let state = state(&map, &actor, city, research, strategic);
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());

    let started = GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::StartUnitProduction(StartUnitProductionCommand::new(
            9,
            &city_id,
            UnitKind::Tank,
            Some(0),
        )),
    )
    .expect("start tank");
    assert!(started.is_accepted());
    assert!(started.state().economy().strategic_resources().is_empty());
    assert_eq!(
        started
            .state()
            .city(&city_id)
            .expect("city")
            .production_queue()
            .expect("queue")
            .resource_allocation()
            .amounts()
            .get(&ResourceType::Oil),
        Some(&2)
    );

    let switched = GameEngine::apply_player_owned(
        started.state().clone(),
        context,
        PlayerCommand::StartUnitProduction(StartUnitProductionCommand::new(
            10,
            &city_id,
            UnitKind::Warrior,
            None,
        )),
    )
    .expect("switch unit");
    assert!(switched.is_accepted());
    assert_eq!(
        switched
            .state()
            .economy()
            .strategic_resources()
            .get(&actor)
            .expect("refunded")
            .amounts()
            .get(&ResourceType::Oil),
        Some(&2)
    );

    let invalid = GameEngine::apply_player_owned(
        switched.state().clone(),
        context,
        PlayerCommand::StartUnitProduction(StartUnitProductionCommand::new(
            11,
            &city_id,
            UnitKind::Warrior,
            Some(0),
        )),
    )
    .expect("normal rejection");
    assert_eq!(
        invalid.rejection().expect("invalid option").code(),
        CommandRejectionCode::UnitProductionInvalidResourceOption
    );
    assert_eq!(invalid.state(), switched.state());
}

#[test]
fn wonder_and_specialization_use_the_same_technology_gate_as_options() {
    let map = map();
    let actor = player();
    let city_id = CityId::new("capital").expect("city id");
    let city = City::builder(
        city_id.clone(),
        actor.clone(),
        "Capital",
        HexCoord::new(2, 2),
    )
    .with_buildings([CityBuildingType::Granary])
    .build()
    .expect("city");
    let state = state(
        &map,
        &actor,
        city,
        [TechnologyId::Writing, TechnologyId::Specialization],
        BTreeMap::new(),
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let specialized = GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::SetCitySpecialization(SetCitySpecializationCommand::new(
            9,
            &city_id,
            CitySpecializationType::Growth,
        )),
    )
    .expect("specialize");
    assert!(specialized.is_accepted());
    assert_eq!(
        specialized
            .state()
            .city(&city_id)
            .expect("city")
            .specialization(),
        Some(CitySpecializationType::Growth)
    );

    let wonder = GameEngine::apply_player_owned(
        specialized.state().clone(),
        context,
        PlayerCommand::StartWonder(StartWonderCommand::new(
            10,
            &city_id,
            WonderType::GreatLibrary,
        )),
    )
    .expect("start wonder");
    assert!(wonder.is_accepted());
    assert_eq!(
        wonder
            .state()
            .city(&city_id)
            .expect("city")
            .production_queue()
            .expect("queue")
            .target(),
        CityProductionTarget::Wonder(WonderType::GreatLibrary)
    );

    let unchanged = GameEngine::apply_player_owned(
        wonder.state().clone(),
        context,
        PlayerCommand::SetCitySpecialization(SetCitySpecializationCommand::new(
            11,
            &city_id,
            CitySpecializationType::Growth,
        )),
    )
    .expect("unchanged specialization rejection");
    assert_eq!(
        unchanged.rejection().expect("rejection").code(),
        CommandRejectionCode::CitySpecializationUnchanged
    );
}

fn state(
    map: &MapDefinition,
    actor: &PlayerId,
    city: City,
    unlocked: impl IntoIterator<Item = TechnologyId>,
    strategic_resources: BTreeMap<PlayerId, StrategicResourceStockpile>,
) -> GameState {
    state_with(
        map,
        actor,
        vec![city],
        Vec::new(),
        unlocked,
        strategic_resources,
    )
}

fn state_with(
    map: &MapDefinition,
    actor: &PlayerId,
    cities: Vec<City>,
    units: Vec<Unit>,
    unlocked: impl IntoIterator<Item = TechnologyId>,
    strategic_resources: BTreeMap<PlayerId, StrategicResourceStockpile>,
) -> GameState {
    let participant = Participant::try_new(
        actor.clone(),
        "Player",
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Human,
        None,
    )
    .expect("participant");
    let identity =
        MatchIdentity::try_new(MatchRules::default(), [participant], GameMode::Multiplayer)
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
    let unlocked = unlocked.into_iter().collect::<Vec<_>>();
    let research = if unlocked.is_empty() {
        ResearchState::default()
    } else {
        ResearchState::try_new([(
            actor.clone(),
            PlayerResearchState::try_new(unlocked, None, [], 0).expect("research"),
        )])
        .expect("research state")
    };
    let economy = EconomyState::try_new(
        &identity,
        map.bounds(),
        BTreeMap::new(),
        BTreeMap::new(),
        BTreeMap::new(),
        strategic_resources,
        InitialResourceDistribution::default(),
    )
    .expect("economy");
    GameState::builder(
        StateRevision::new(9),
        4,
        map.bounds(),
        UnitOccupancyPolicy::Exclusive,
        units,
    )
    .with_cities(cities)
    .with_economy(economy)
    .with_knowledge(KnowledgeState::new(research, WonderRegistry::default()))
    .with_fog_of_war(FogOfWar::default())
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state")
}

fn map() -> MapDefinition {
    MapDefinition::try_new(
        "production-test",
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

fn rich_map(center_terrain: TerrainType) -> MapDefinition {
    MapDefinition::try_new(
        "production-rich-test",
        GridLayout::OddQFlatTop,
        5,
        5,
        (0..5)
            .flat_map(|row| {
                (0..5).map(move |col| {
                    let coordinate = HexCoord::new(col, row);
                    let terrain = match (col, row) {
                        (2, 2) => vec![center_terrain],
                        (2, 1) => vec![TerrainType::Coast],
                        (2, 0) => vec![TerrainType::Ocean],
                        (1, 2) => vec![TerrainType::Mountain],
                        (3, 2) => vec![TerrainType::Plains, TerrainType::River],
                        _ => vec![TerrainType::Plains],
                    };
                    let resources = if (col, row) == (2, 1) {
                        ContentResourceType::ALL.to_vec()
                    } else {
                        Vec::new()
                    };
                    TileDefinition::try_new_for_simulation(coordinate, terrain, resources, 0)
                        .expect("tile")
                })
            })
            .collect(),
        Vec::new(),
    )
    .expect("map")
}

fn player() -> PlayerId {
    PlayerId::new("player-1").expect("player")
}
