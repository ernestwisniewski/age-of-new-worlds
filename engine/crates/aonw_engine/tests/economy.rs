//! Economy account and city-yield acceptance tests.

#[path = "economy/manifest.rs"]
mod manifest;

use std::collections::BTreeMap;

use aonw_content::{
    GridLayout, MapDefinition, ResourceType as MapResourceType, RulesetDefinition, TerrainType,
    TileDefinition,
};
use aonw_domain::{
    ArtifactId, City, CityProductionQueue, CityProductionTarget, CityProjectType, FieldImprovement,
    FieldImprovementKind, HexCoord, InfrastructureState, InitialResourceDistribution,
    InitialResourcePlacement, InteractionState, PlayerResearchState, ResearchState, ResourceType,
    StrategicResourceStockpile, TechnologyId, TransportNetwork, UnitKind, WorldArtifact,
    WorldArtifactLocation, WorldArtifactType,
};
use aonw_engine::{
    CityYieldContributionKind, CityYieldQuery, EconomyForecastQuery, EngineContext, GameEngine,
    GameQuery, QueryResult, StabilityBand, StrategicResourceProjectionQuery, YieldValue,
};

#[path = "city/support.rs"]
#[allow(dead_code)]
mod support;

use support::{city_id, player, state_with_economy_parts, state_with_resource_parts, unit};

#[test]
fn city_yield_query_returns_checked_canonical_breakdown() {
    let map = economy_map();
    let actor = player("player-1");
    let city_id = city_id("city-1");
    let worked_tile = HexCoord::new(1, 0);
    let passive = HexCoord::new(2, 0);
    let city = City::builder(
        city_id.clone(),
        actor.clone(),
        "Capital",
        HexCoord::new(0, 0),
    )
    .with_progression(1, 0, 6, 2)
    .with_controlled_hexes([worked_tile, passive])
    .with_worked_hexes([worked_tile])
    .build()
    .expect("city");
    let worker_unit =
        unit("worker-1", &actor, UnitKind::Worker, worked_tile).after_worker_assigned(worked_tile);
    let infrastructure = InfrastructureState::try_new(
        [
            FieldImprovement::new(
                worked_tile,
                FieldImprovementKind::Farm,
                Some(city_id.clone()),
            ),
            FieldImprovement::new(passive, FieldImprovementKind::Mine, Some(city_id.clone())),
        ],
        TransportNetwork::default(),
    )
    .expect("infrastructure");
    let artifact = WorldArtifact::new(
        ArtifactId::new("artifact-1").expect("artifact id"),
        WorldArtifactType::MerchantsSeal,
        WorldArtifactLocation::Stored(city_id.clone()),
    );
    let state = state_with_economy_parts(
        &map,
        vec![worker_unit],
        vec![city],
        InteractionState::default(),
        infrastructure,
        vec![artifact],
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());

    let QueryResult::CityYield(breakdown) = GameEngine::query(
        &state,
        context,
        GameQuery::CityYield(CityYieldQuery::new(9, &city_id)),
    )
    .expect("yield query") else {
        panic!("city yield result")
    };

    assert_eq!(breakdown.city_id(), &city_id);
    assert_eq!(
        breakdown
            .contributions()
            .iter()
            .map(|contribution| contribution.kind())
            .collect::<Vec<_>>(),
        [
            CityYieldContributionKind::Center,
            CityYieldContributionKind::Population,
            CityYieldContributionKind::Worker,
            CityYieldContributionKind::PassiveImprovement,
            CityYieldContributionKind::Artifact,
        ]
    );
    assert_eq!(
        breakdown
            .contributions()
            .iter()
            .map(|contribution| (contribution.coordinate(), contribution.value()))
            .collect::<Vec<_>>(),
        [
            (HexCoord::new(0, 0), YieldValue::new(2, 1, 0, 0)),
            (worked_tile, YieldValue::new(6, 0, 0, 0)),
            (worked_tile, YieldValue::new(3, 0, 0, 0)),
            (passive, YieldValue::new(0, 1, 0, 0)),
            (HexCoord::new(0, 0), YieldValue::new(0, 0, 2, 0)),
        ]
    );
    assert_eq!(breakdown.total(), YieldValue::new(11, 2, 2, 0));
}

#[test]
fn city_scoring_and_yield_use_the_same_content_balance() {
    let balance = RulesetDefinition::standard().economy();
    assert_eq!(balance.city_center_yield().food(), 2);
    assert_eq!(balance.food_upkeep_per_population(), 1);
    assert_eq!(balance.growth_cost(3, 3), Some(31));
    assert_eq!(
        balance.stability_modifier(0).production_basis_points(),
        10_000
    );
    assert_eq!(balance.stability_modifier(-1).gold_basis_points(), 9_000);
    assert!(balance.stability_modifier(-4).halts_growth());
    assert_eq!(balance.stability_modifier(4).food_bonus(), 1);
}

#[test]
fn economy_forecast_reuses_turn_income_upkeep_and_stability_rules() {
    let map = forecast_map();
    let actor = player("player-1");
    let city_id = city_id("city-1");
    let queue = CityProductionQueue::try_new(
        CityProductionTarget::Project(CityProjectType::Wealth),
        0,
        StrategicResourceStockpile::default(),
    )
    .expect("wealth queue");
    let city = City::builder(
        city_id.clone(),
        actor.clone(),
        "Capital",
        HexCoord::new(0, 0),
    )
    .with_production(Some(queue), 0)
    .build()
    .expect("city");
    let units = [
        UnitKind::Tank,
        UnitKind::Cavalry,
        UnitKind::Settler,
        UnitKind::Warrior,
        UnitKind::Worker,
        UnitKind::Worker,
        UnitKind::Worker,
    ]
    .into_iter()
    .enumerate()
    .map(|(index, kind)| {
        unit(
            &format!("unit-{index}"),
            &actor,
            kind,
            HexCoord::new(i32::try_from(index + 1).expect("position"), 0),
        )
    })
    .collect();
    let artifact = WorldArtifact::new(
        ArtifactId::new("artifact-1").expect("artifact id"),
        WorldArtifactType::MerchantsSeal,
        WorldArtifactLocation::Stored(city_id.clone()),
    );
    let state = state_with_economy_parts(
        &map,
        units,
        vec![city],
        InteractionState::default(),
        InfrastructureState::default(),
        vec![artifact],
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());

    let QueryResult::EconomyForecast(forecast) = GameEngine::query(
        &state,
        context,
        GameQuery::EconomyForecast(EconomyForecastQuery::new(9)),
    )
    .expect("economy forecast") else {
        panic!("economy forecast result")
    };

    assert_eq!(forecast.player_id(), &actor);
    assert_eq!(forecast.treasury(), 0);
    assert_eq!(forecast.city_income(), 2);
    assert_eq!(forecast.project_income(), 1);
    assert_eq!(forecast.gross_income(), 3);
    assert_eq!(forecast.net_per_turn(), -3);
    assert_eq!(forecast.city_sources()[0].city_id(), &city_id);
    assert_eq!(forecast.city_sources()[0].amount(), 2);
    assert_eq!(forecast.project_sources()[0].city_id(), &city_id);
    assert_eq!(forecast.project_sources()[0].amount(), 1);

    let upkeep = forecast.upkeep();
    assert_eq!(upkeep.upkeep_bearing_unit_count(), 7);
    assert_eq!(upkeep.free_unit_count(), 4);
    assert_eq!(upkeep.paid_unit_count(), 3);
    assert_eq!(upkeep.total(), 6);
    assert_eq!(upkeep.next_worker_upkeep(), 4);
    assert_eq!(upkeep.sources().len(), 1);
    assert_eq!(upkeep.sources()[0].kind(), UnitKind::Worker);
    assert_eq!(upkeep.sources()[0].paid_unit_count(), 3);
    assert_eq!(upkeep.sources()[0].amount(), 6);

    let stability = forecast.stability();
    assert_eq!(stability.base_order(), 6);
    assert_eq!(stability.artifact_sources(), 1);
    assert_eq!(stability.source_total(), 7);
    assert_eq!(stability.cost_total(), 0);
    assert_eq!(stability.relative_standing_adjustment(), 3);
    assert_eq!(stability.effective_net(), 10);
    assert_eq!(stability.band(), StabilityBand::Content);
}

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

#[test]
fn strategic_projection_uses_city_ownership_initial_distribution_and_technology_gate() {
    let map = resource_map();
    let actor = player("player-1");
    let city_id = city_id("city-1");
    let oil = HexCoord::new(1, 0);
    let aluminium = HexCoord::new(2, 0);
    let city = City::builder(
        city_id.clone(),
        actor.clone(),
        "Capital",
        HexCoord::new(0, 0),
    )
    .with_controlled_hexes([oil, aluminium])
    .build()
    .expect("city");
    let infrastructure = InfrastructureState::try_new(
        [
            FieldImprovement::new(oil, FieldImprovementKind::OilWell, Some(city_id.clone())),
            FieldImprovement::new(
                aluminium,
                FieldImprovementKind::BauxiteMine,
                Some(city_id.clone()),
            ),
        ],
        TransportNetwork::default(),
    )
    .expect("infrastructure");
    let distribution = InitialResourceDistribution::try_new(
        17,
        [InitialResourcePlacement::new(
            aluminium,
            ResourceType::Aluminium,
        )],
    )
    .expect("distribution");
    let research = ResearchState::try_new([(
        actor.clone(),
        PlayerResearchState::try_new(
            [TechnologyId::Combustion, TechnologyId::Flight],
            None,
            [],
            0,
        )
        .expect("research"),
    )])
    .expect("research state");
    let state = state_with_resource_parts(
        &map,
        Vec::new(),
        vec![city.clone()],
        InteractionState::default(),
        infrastructure.clone(),
        Vec::new(),
        distribution.clone(),
        research,
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let QueryResult::StrategicResourceProjection(projection) = GameEngine::query(
        &state,
        context,
        GameQuery::StrategicResourceProjection(StrategicResourceProjectionQuery::new(9)),
    )
    .expect("projection") else {
        panic!("strategic projection")
    };
    assert_strategic_projection(&projection, oil, aluminium);

    let hidden = state_with_resource_parts(
        &map,
        Vec::new(),
        vec![city],
        InteractionState::default(),
        infrastructure,
        Vec::new(),
        distribution,
        ResearchState::default(),
    );
    let QueryResult::StrategicResourceProjection(hidden) = GameEngine::query(
        &hidden,
        context,
        GameQuery::StrategicResourceProjection(StrategicResourceProjectionQuery::new(9)),
    )
    .expect("hidden projection") else {
        panic!("strategic projection")
    };
    assert!(hidden.output().is_empty());
    assert!(hidden.sources().is_empty());
}

fn assert_strategic_projection(
    projection: &aonw_engine::StrategicResourceProjection,
    oil: HexCoord,
    aluminium: HexCoord,
) {
    assert_eq!(
        projection.output(),
        &BTreeMap::from([(ResourceType::Oil, 1), (ResourceType::Aluminium, 1)])
    );
    assert_eq!(
        projection
            .sources()
            .iter()
            .map(|source| (
                source.city_id().as_str(),
                source.coordinate(),
                source.resource(),
                source.improvement(),
                source.amount_per_turn()
            ))
            .collect::<Vec<_>>(),
        [
            (
                "city-1",
                oil,
                ResourceType::Oil,
                FieldImprovementKind::OilWell,
                1,
            ),
            (
                "city-1",
                aluminium,
                ResourceType::Aluminium,
                FieldImprovementKind::BauxiteMine,
                1,
            ),
        ]
    );
}

fn economy_map() -> MapDefinition {
    let tiles = [
        TileDefinition::try_new_for_simulation(
            HexCoord::new(0, 0),
            vec![TerrainType::Plains],
            Vec::new(),
            0,
        )
        .expect("center"),
        TileDefinition::try_new_for_simulation(
            HexCoord::new(1, 0),
            vec![TerrainType::Grassland, TerrainType::River],
            vec![MapResourceType::Wheat],
            0,
        )
        .expect("worked"),
        TileDefinition::try_new_for_simulation(
            HexCoord::new(2, 0),
            vec![TerrainType::Plains, TerrainType::Hills],
            Vec::new(),
            0,
        )
        .expect("passive"),
    ];
    MapDefinition::try_new(
        "economy-test",
        GridLayout::OddQFlatTop,
        3,
        1,
        tiles.into(),
        Vec::new(),
    )
    .expect("map")
}

fn resource_map() -> MapDefinition {
    let tiles = [
        TileDefinition::try_new_for_simulation(
            HexCoord::new(0, 0),
            vec![TerrainType::Plains],
            Vec::new(),
            0,
        )
        .expect("center"),
        TileDefinition::try_new_for_simulation(
            HexCoord::new(1, 0),
            vec![TerrainType::Plains],
            all_map_resources(),
            0,
        )
        .expect("oil"),
        TileDefinition::try_new_for_simulation(
            HexCoord::new(2, 0),
            vec![TerrainType::Plains],
            Vec::new(),
            0,
        )
        .expect("aluminium"),
    ];
    MapDefinition::try_new(
        "resource-test",
        GridLayout::OddQFlatTop,
        3,
        1,
        tiles.into(),
        Vec::new(),
    )
    .expect("map")
}

fn forecast_map() -> MapDefinition {
    MapDefinition::try_new(
        "forecast-test",
        GridLayout::OddQFlatTop,
        8,
        1,
        (0..8)
            .map(|column| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(column, 0),
                    vec![TerrainType::Plains],
                    Vec::new(),
                    0,
                )
                .expect("forecast tile")
            })
            .collect(),
        Vec::new(),
    )
    .expect("forecast map")
}

fn all_map_resources() -> Vec<MapResourceType> {
    vec![
        MapResourceType::Wheat,
        MapResourceType::Fish,
        MapResourceType::Deer,
        MapResourceType::Sheep,
        MapResourceType::Rice,
        MapResourceType::Cow,
        MapResourceType::Apple,
        MapResourceType::Banana,
        MapResourceType::Citrus,
        MapResourceType::Gold,
        MapResourceType::Silver,
        MapResourceType::Gems,
        MapResourceType::Silk,
        MapResourceType::Spices,
        MapResourceType::Cotton,
        MapResourceType::Grapes,
        MapResourceType::Ivory,
        MapResourceType::Pearls,
        MapResourceType::Coffee,
        MapResourceType::Cocoa,
        MapResourceType::Tobacco,
        MapResourceType::Sugar,
        MapResourceType::Iron,
        MapResourceType::Coal,
        MapResourceType::Oil,
        MapResourceType::Aluminium,
        MapResourceType::Uranium,
        MapResourceType::Horses,
        MapResourceType::Marble,
    ]
}
