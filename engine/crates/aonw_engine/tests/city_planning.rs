//! Planning candidates must not become an oracle for undiscovered cities.
use aonw_content::{
    GridLayout, MapDefinition, RulesetDefinition, TerrainProfile, TerrainType, TileDefinition,
};
use aonw_domain::{City, FogOfWar, GameState, HexCoord, InteractionState, PlayerFog, UnitKind};
use aonw_engine::{CityPlanning, CityPlanningError, CityPlanningQuery, EngineContext, GameEngine};

#[path = "city/support.rs"]
#[allow(dead_code)]
mod support;
use support::{city_id, player, unit};

#[test]
fn terrain_markings_match_founding_rules_but_growth_allows_water_and_mountains() {
    let terrains = [
        TerrainType::Plains,
        TerrainType::Coast,
        TerrainType::Ocean,
        TerrainType::Lake,
        TerrainType::Mountain,
        TerrainType::Forest,
    ];
    let map = MapDefinition::try_new(
        "planning",
        GridLayout::OddQFlatTop,
        6,
        1,
        terrains
            .into_iter()
            .enumerate()
            .map(|(col, terrain)| {
                TileDefinition::try_new(
                    HexCoord::new(i32::try_from(col).unwrap(), 0),
                    TerrainProfile::try_new(vec![terrain]).unwrap(),
                    vec![],
                    0,
                )
                .unwrap()
            })
            .collect(),
        vec![],
    )
    .unwrap();
    let state = fixture(&map, vec![]);
    let before = state.clone();
    let result = inspect(&state, &map, "player-1");
    assert_eq!(result.city_sites, vec![hex(0, 0), hex(1, 0), hex(5, 0)]);
    assert_eq!(
        result.growth_tiles,
        (0..6).map(|col| hex(col, 0)).collect::<Vec<_>>()
    );
    assert_eq!(state, before);
}

#[test]
fn known_cities_exclude_territory_and_enforce_configured_center_distance() {
    let map = support::map(8, 4);
    let city = city("player-2");
    let state = fixture(&map, vec![city]);
    let result = inspect(&state, &map, "player-1");
    assert!(!result.growth_tiles.contains(&hex(3, 0)));
    assert!(!result.growth_tiles.contains(&hex(2, 0)));
    assert!(result.growth_tiles.contains(&hex(3, 1)));
    let minimum = u64::from(
        RulesetDefinition::standard()
            .city()
            .minimum_center_distance(),
    );
    for candidate in &result.city_sites {
        assert!(candidate.distance_to(hex(3, 0)) >= minimum);
    }
    assert!(result.city_sites.contains(&hex(7, 3)));
    assert!(result.city_sites.windows(2).all(|pair| pair[0] < pair[1]));
    assert!(result.growth_tiles.windows(2).all(|pair| pair[0] < pair[1]));
}

#[test]
fn hidden_foreign_cities_cannot_change_any_disclosed_candidate() {
    let map = support::map(8, 4);
    let known = vec![hex(0, 0), hex(2, 0), hex(3, 1)];
    let absent = with_fog(&fixture(&map, vec![]), known.clone());
    let hidden = with_fog(&fixture(&map, vec![city("player-2")]), known);
    let public = inspect(&absent, &map, "player-1");
    assert_eq!(inspect(&hidden, &map, "player-1"), public);
    assert_eq!(public.city_sites, vec![hex(0, 0), hex(2, 0), hex(3, 1)]);
    assert_eq!(public.city_sites, public.growth_tiles);
    let disclosed = with_fog(&hidden, vec![hex(0, 0), hex(2, 0), hex(3, 0), hex(3, 1)]);
    let marked = inspect(&disclosed, &map, "player-1");
    assert!(!marked.growth_tiles.contains(&hex(2, 0)));
    assert!(!marked.city_sites.contains(&hex(3, 1)));
}

#[test]
fn owned_city_remains_known_and_an_undiscovered_tile_never_has_a_marker() {
    let map = support::map(8, 4);
    let state = with_fog(
        &fixture(&map, vec![city("player-1")]),
        vec![hex(2, 0), hex(3, 1)],
    );
    let result = inspect(&state, &map, "player-1");
    assert!(!result.growth_tiles.contains(&hex(2, 0)));
    assert_eq!(result.growth_tiles, vec![hex(3, 1)]);
    assert!(result.city_sites.is_empty());
    assert_ne!(result, inspect(&state, &map, "player-2"));
}

#[test]
fn revision_and_membership_fail_closed() {
    let map = support::map(8, 4);
    let state = fixture(&map, vec![]);
    for (actor, revision, error) in [
        ("player-1", 8, CityPlanningError::StaleRevision),
        ("outsider", 9, CityPlanningError::PlayerNotInMatch),
    ] {
        assert_eq!(
            GameEngine::city_planning(
                &state,
                EngineContext::canonical(&player(actor), &map, RulesetDefinition::standard()),
                CityPlanningQuery::new(revision)
            ),
            Err(error)
        );
    }
}

fn hex(col: i32, row: i32) -> HexCoord {
    HexCoord::new(col, row)
}

fn inspect(state: &GameState, map: &MapDefinition, actor: &str) -> CityPlanning {
    GameEngine::city_planning(
        state,
        EngineContext::canonical(&player(actor), map, RulesetDefinition::standard()),
        CityPlanningQuery::new(9),
    )
    .unwrap()
}

fn city(owner: &str) -> City {
    City::builder(city_id("city-1"), player(owner), "City", hex(3, 0))
        .with_controlled_hexes([hex(2, 0)])
        .build()
        .unwrap()
}

fn fixture(map: &MapDefinition, cities: Vec<City>) -> GameState {
    support::state(
        map,
        vec![
            unit(
                "unit-1",
                &player("player-1"),
                UnitKind::Commander,
                hex(0, 0),
            ),
            unit(
                "unit-2",
                &player("player-2"),
                UnitKind::Commander,
                hex(1, 0),
            ),
        ],
        cities,
        InteractionState::default(),
    )
}

fn with_fog(state: &GameState, known: Vec<HexCoord>) -> GameState {
    let fog = FogOfWar::try_new([
        PlayerFog::new(player("player-1"), known, []),
        PlayerFog::new(player("player-2"), [hex(0, 0)], []),
    ])
    .unwrap();
    GameState::builder(
        state.revision(),
        state.turn(),
        state.bounds(),
        state.occupancy_policy(),
        state.units().to_vec(),
    )
    .with_match_lifecycle(state.match_lifecycle().clone())
    .with_cities(state.cities().to_vec())
    .with_fog_of_war(fog)
    .try_build()
    .unwrap()
}
