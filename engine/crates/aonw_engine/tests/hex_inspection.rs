//! Recipient disclosure and canonical hex-inspection acceptance tests.
use aonw_content::{
    GridLayout, MapDefinition, ResourceType as Resource, RulesetDefinition, TerrainProfile,
    TerrainType, TileDefinition,
};
use aonw_domain::{
    City, FieldImprovement, FieldImprovementKind, FogOfWar, GameState, HexCoord,
    InfrastructureState, InitialResourceDistribution, InitialResourcePlacement, InteractionState,
    KnowledgeState, PlayerFog, PlayerResearchState, ResearchState, ResourceType, TechnologyId,
    TransportNetwork, UnitKind, WonderRegistry,
};
use aonw_engine::{
    EngineContext, GameEngine, HexAssessmentKind, HexImprovementAccess, HexInspection,
    HexInspectionError, HexInspectionQuery,
};

#[path = "city/support.rs"]
#[allow(dead_code)]
mod support;
use support::{city_id, player, state_with_resource_parts, unit};

const TARGET: HexCoord = HexCoord::new(1, 0);

#[test]
fn hidden_resources_cannot_change_classification_yield_tags_or_improvements() {
    let public_map = map(vec![Resource::Deer]);
    let secret_map = map(vec![Resource::Deer, Resource::Coal, Resource::Oil]);
    let state = fixture(
        &public_map,
        vec![],
        InfrastructureState::default(),
        ResearchState::default(),
        InitialResourceDistribution::default(),
    );
    let before = state.clone();
    let plain = inspect(&state, &public_map);
    let secret = inspect(&state, &secret_map);
    assert_eq!(plain, secret);
    assert_eq!(secret.resources, vec![Resource::Deer]);
    assert!(!secret.improvements.iter().any(|option| matches!(
        option.kind,
        FieldImprovementKind::CoalShaft | FieldImprovementKind::OilWell
    )));
    assert_eq!(state, before);
}

#[test]
fn disclosed_resources_and_improvement_requirements_follow_actor_research() {
    let map = map(vec![Resource::Deer, Resource::Coal, Resource::Oil]);
    let state = fixture(
        &map,
        vec![],
        InfrastructureState::default(),
        research(),
        InitialResourceDistribution::default(),
    );
    let result = inspect(&state, &map);
    assert_eq!(
        result.resources,
        vec![Resource::Deer, Resource::Coal, Resource::Oil]
    );
    assert_eq!(result.kind, HexAssessmentKind::ForestForge);
    let coal = result
        .improvements
        .iter()
        .find(|option| option.kind == FieldImprovementKind::CoalShaft)
        .expect("coal option");
    assert_eq!(coal.required_technology, Some(TechnologyId::CoalMining));
    assert!(coal.technology_unlocked);
    let actor = player("player-2");
    let other = GameEngine::inspect_hex(
        &state,
        EngineContext::canonical(&actor, &map, RulesetDefinition::standard()),
        HexInspectionQuery::new(9, TARGET),
    )
    .expect("other recipient");
    assert_eq!(other.resources, vec![Resource::Deer]);
    assert_eq!(other.kind, HexAssessmentKind::ForestBackline);
}

#[test]
fn match_start_resources_are_filtered_and_deduplicated_with_authored_resources() {
    let map = map(vec![Resource::Deer, Resource::Coal]);
    let placements = InitialResourceDistribution::try_new(
        7,
        [InitialResourcePlacement::new(TARGET, ResourceType::Coal)],
    )
    .expect("placements");
    let empty = fixture(
        &map,
        vec![],
        InfrastructureState::default(),
        ResearchState::default(),
        placements.clone(),
    );
    assert_eq!(inspect(&empty, &map).resources, vec![Resource::Deer]);
    let unlocked = fixture(
        &map,
        vec![],
        InfrastructureState::default(),
        research(),
        placements,
    );
    assert_eq!(
        inspect(&unlocked, &map).resources,
        vec![Resource::Deer, Resource::Coal]
    );
    let no_authored_coal = map_without_coal();
    assert_eq!(
        inspect(&unlocked, &no_authored_coal),
        inspect(&unlocked, &map)
    );
}

#[test]
fn hidden_foreign_infrastructure_does_not_change_the_public_inspection() {
    let map = map(vec![]);
    let foreign_city = city("player-2");
    let infrastructure = InfrastructureState::try_new(
        [FieldImprovement::new(
            TARGET,
            FieldImprovementKind::LumberMill,
            Some(foreign_city.id().clone()),
        )],
        TransportNetwork::default(),
    )
    .expect("infrastructure");
    let hidden = with_fog(
        &fixture(
            &map,
            vec![foreign_city],
            infrastructure,
            ResearchState::default(),
            InitialResourceDistribution::default(),
        ),
        false,
    );
    let absent = with_fog(
        &fixture(
            &map,
            vec![],
            InfrastructureState::default(),
            ResearchState::default(),
            InitialResourceDistribution::default(),
        ),
        false,
    );
    assert_eq!(inspect(&hidden, &map), inspect(&absent, &map));
    let discovered = with_fog(&hidden, true);
    assert_eq!(
        inspect(&discovered, &map).improvement_access,
        HexImprovementAccess::AlreadyImproved
    );
}

#[test]
fn owned_city_and_improvements_remain_inspectable_without_fog_disclosure() {
    let map = map(vec![]);
    let owned = city("player-1");
    let state = with_fog(
        &fixture(
            &map,
            vec![owned.clone()],
            InfrastructureState::default(),
            ResearchState::default(),
            InitialResourceDistribution::default(),
        ),
        false,
    );
    assert_eq!(
        inspect(&state, &map).improvement_access,
        HexImprovementAccess::ControlledCity(owned.id().clone())
    );
    let infrastructure = InfrastructureState::try_new(
        [FieldImprovement::new(
            TARGET,
            FieldImprovementKind::LumberMill,
            Some(owned.id().clone()),
        )],
        TransportNetwork::default(),
    )
    .expect("infrastructure");
    let improved = with_fog(
        &fixture(
            &map,
            vec![owned],
            infrastructure,
            ResearchState::default(),
            InitialResourceDistribution::default(),
        ),
        false,
    );
    assert_eq!(
        inspect(&improved, &map).improvement_access,
        HexImprovementAccess::AlreadyImproved
    );
}

#[test]
fn inspection_rejects_wrong_revision_actor_and_coordinates() {
    let map = map(vec![]);
    let state = fixture(
        &map,
        vec![],
        InfrastructureState::default(),
        ResearchState::default(),
        InitialResourceDistribution::default(),
    );
    let actor = player("player-1");
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    assert_eq!(
        GameEngine::inspect_hex(&state, context, HexInspectionQuery::new(8, TARGET)),
        Err(HexInspectionError::StaleRevision)
    );
    assert_eq!(
        GameEngine::inspect_hex(
            &state,
            context,
            HexInspectionQuery::new(9, HexCoord::new(99, 0))
        ),
        Err(HexInspectionError::HexOutsideMap)
    );
    let other = player("not-a-participant");
    let context = EngineContext::canonical(&other, &map, RulesetDefinition::standard());
    assert_eq!(
        GameEngine::inspect_hex(&state, context, HexInspectionQuery::new(9, TARGET)),
        Err(HexInspectionError::PlayerNotInMatch)
    );
}

#[test]
fn authored_terrain_precedence_preserves_river_and_height_facts() {
    let tile = TileDefinition::try_new(
        TARGET,
        TerrainProfile::try_new(vec![TerrainType::River, TerrainType::Forest]).expect("terrain"),
        vec![Resource::Deer],
        4,
    )
    .expect("tile");
    let map = map_with_tile(tile);
    let state = fixture(
        &map,
        vec![],
        InfrastructureState::default(),
        ResearchState::default(),
        InitialResourceDistribution::default(),
    );
    let result = inspect(&state, &map);
    assert_eq!(result.base_terrain, TerrainType::Forest);
    assert_eq!(
        result.terrain_tags,
        [TerrainType::River, TerrainType::Forest]
    );
    assert_eq!(result.kind, HexAssessmentKind::RichWilds);
    assert!(result.has_river);
    assert_eq!(result.height, 4);
}

#[test]
fn available_improvements_are_ranked_first_only_inside_a_controlled_city() {
    let world_map = map(vec![Resource::Deer]);
    let research = ResearchState::try_new([(
        player("player-1"),
        PlayerResearchState::try_new([TechnologyId::Hunting], None, [], 0).expect("research"),
    )])
    .expect("research state");
    let outside = fixture(
        &world_map,
        vec![],
        InfrastructureState::default(),
        research.clone(),
        InitialResourceDistribution::default(),
    );
    let controlled = fixture(
        &world_map,
        vec![city("player-1")],
        InfrastructureState::default(),
        research,
        InitialResourceDistribution::default(),
    );
    assert_eq!(
        inspect(&outside, &world_map).improvements[0].kind,
        FieldImprovementKind::LumberMill
    );
    let options = inspect(&controlled, &world_map).improvements;
    assert_eq!(options[0].kind, FieldImprovementKind::Camp);
    assert!(options[0].technology_unlocked);
    assert_eq!(
        options[0].yield_delta,
        aonw_engine::YieldValue::new(1, 1, 0, 0)
    );
    assert_eq!(options[0].required_technology, Some(TechnologyId::Hunting));
}

#[test]
fn a_foreign_city_center_is_disclosed_only_on_known_terrain() {
    let world_map = map(vec![]);
    let city = City::builder(city_id("city-1"), player("player-2"), "City", TARGET)
        .build()
        .expect("city");
    let hidden = with_fog(
        &fixture(
            &world_map,
            vec![city],
            InfrastructureState::default(),
            ResearchState::default(),
            InitialResourceDistribution::default(),
        ),
        false,
    );
    assert_eq!(
        inspect(&hidden, &world_map).improvement_access,
        HexImprovementAccess::OutsideControlledCity
    );
    let discovered = with_fog(&hidden, true);
    assert_eq!(
        inspect(&discovered, &world_map).improvement_access,
        HexImprovementAccess::CityCenter
    );
}

fn inspect(state: &GameState, map: &MapDefinition) -> HexInspection {
    let actor = player("player-1");
    GameEngine::inspect_hex(
        state,
        EngineContext::canonical(&actor, map, RulesetDefinition::standard()),
        HexInspectionQuery::new(9, TARGET),
    )
    .expect("inspection")
}

fn map(resources: Vec<Resource>) -> MapDefinition {
    map_with_tile(
        TileDefinition::try_new(
            TARGET,
            TerrainProfile::try_new(vec![TerrainType::Forest]).expect("terrain"),
            resources,
            0,
        )
        .expect("tile"),
    )
}

fn map_without_coal() -> MapDefinition {
    map(vec![Resource::Deer])
}

fn map_with_tile(target: TileDefinition) -> MapDefinition {
    let mut tiles = support::map(3, 2).tiles().to_vec();
    *tiles
        .iter_mut()
        .find(|tile| tile.coordinate() == TARGET)
        .expect("target") = target;
    MapDefinition::try_new("inspection", GridLayout::OddQFlatTop, 3, 2, tiles, vec![]).expect("map")
}

fn city(owner: &str) -> City {
    City::builder(
        city_id("city-1"),
        player(owner),
        "City",
        HexCoord::new(2, 1),
    )
    .with_controlled_hexes([TARGET])
    .build()
    .expect("city")
}

fn research() -> ResearchState {
    ResearchState::try_new([(
        player("player-1"),
        PlayerResearchState::try_new(
            [TechnologyId::CoalMining, TechnologyId::Combustion],
            None,
            [],
            0,
        )
        .expect("research"),
    )])
    .expect("research state")
}

fn fixture(
    map: &MapDefinition,
    cities: Vec<City>,
    infrastructure: InfrastructureState,
    research: ResearchState,
    distribution: InitialResourceDistribution,
) -> GameState {
    state_with_resource_parts(
        map,
        vec![
            unit(
                "unit-1",
                &player("player-1"),
                UnitKind::Commander,
                HexCoord::new(0, 0),
            ),
            unit(
                "unit-2",
                &player("player-2"),
                UnitKind::Commander,
                HexCoord::new(2, 0),
            ),
        ],
        cities,
        InteractionState::default(),
        infrastructure,
        vec![],
        distribution,
        research,
    )
}

fn with_fog(state: &GameState, discovered: bool) -> GameState {
    let known = if discovered { vec![TARGET] } else { vec![] };
    let fog = FogOfWar::try_new([
        PlayerFog::new(player("player-1"), known, [HexCoord::new(0, 0)]),
        PlayerFog::new(player("player-2"), [], [HexCoord::new(2, 0)]),
    ])
    .expect("fog");
    GameState::builder(
        state.revision(),
        state.turn(),
        state.bounds(),
        state.occupancy_policy(),
        state.units().to_vec(),
    )
    .with_match_lifecycle(state.match_lifecycle().clone())
    .with_cities(state.cities().to_vec())
    .with_infrastructure(state.infrastructure().clone())
    .with_economy(state.economy().clone())
    .with_knowledge(KnowledgeState::new(
        state.research().clone(),
        WonderRegistry::default(),
    ))
    .with_fog_of_war(fog)
    .try_build()
    .expect("state with fog")
}
