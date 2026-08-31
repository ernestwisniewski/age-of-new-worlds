//! Revision-scoped local runtime query-cache contract.

use aonw_content::{
    GridLayout, MapDefinition, RulesetDefinition, ScenarioDefinition, ScenarioUnitDefinition,
    TerrainType, TileDefinition,
};
use aonw_domain::{HexCoord, PlayerId, UnitId, UnitKind};
use aonw_local_runtime::{
    LocalRuntime, MoveUnitRequest, OpenSession, ReachableRequest, RoutePlanRequest, RuntimeQuery,
};

#[test]
fn repeated_and_batch_queries_use_bounded_revision_scope() {
    let mut runtime = LocalRuntime::default();
    runtime.open(request()).expect("open");
    let unit_id = UnitId::new("unit-1").expect("unit id");
    let reachable = RuntimeQuery::Reachable(ReachableRequest {
        expected_revision: 0,
        unit_id: unit_id.clone(),
    });
    let route = RuntimeQuery::RoutePlan(RoutePlanRequest {
        expected_revision: 0,
        unit_id: unit_id.clone(),
        target: HexCoord::new(1, 0),
    });

    let results = runtime.query_batch(&[reachable.clone(), route, reachable.clone()]);
    assert!(results.iter().all(Result::is_ok));
    assert_eq!(runtime.query_cache_stats().hits, 1);
    assert_eq!(runtime.query_cache_stats().misses, 2);

    let rejected = runtime
        .dispatch(&MoveUnitRequest {
            expected_revision: 99,
            unit_id: unit_id.clone(),
            target: HexCoord::new(1, 0),
        })
        .expect("stale move rejection");
    assert_eq!(
        rejected.rejection,
        Some(aonw_engine::CommandRejectionCode::StaleRevision)
    );
    runtime
        .query(&reachable)
        .expect("rejection preserves current cache scope");
    assert_eq!(runtime.query_cache_stats().hits, 2);

    runtime
        .dispatch(&MoveUnitRequest {
            expected_revision: 0,
            unit_id: unit_id.clone(),
            target: HexCoord::new(1, 0),
        })
        .expect("move");
    runtime
        .query(&RuntimeQuery::Reachable(ReachableRequest {
            expected_revision: 1,
            unit_id,
        }))
        .expect("new revision starts a cold scope");
    assert_eq!(runtime.query_cache_stats().hits, 2);
    assert_eq!(runtime.query_cache_stats().misses, 3);
}

fn request() -> OpenSession {
    let map = map();
    let ruleset = RulesetDefinition::standard().clone();
    let scenario = ScenarioDefinition::try_new(
        "query-cache-runtime",
        &map,
        &ruleset,
        [ScenarioUnitDefinition::new(
            UnitId::new("unit-1").expect("unit id"),
            PlayerId::new("player-1").expect("player id"),
            UnitKind::Commander,
            "Commander",
            HexCoord::new(0, 0),
        )],
    )
    .expect("scenario");
    OpenSession::from_scenario(
        map,
        ruleset,
        &scenario,
        PlayerId::new("player-1").expect("player id"),
    )
    .expect("request")
}

fn map() -> MapDefinition {
    let tiles = (0..3)
        .flat_map(|row| {
            (0..3).map(move |col| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(col, row),
                    vec![TerrainType::Grassland],
                    Vec::new(),
                    0,
                )
                .expect("tile")
            })
        })
        .collect();
    MapDefinition::try_new(
        "query-cache-map",
        GridLayout::OddQFlatTop,
        3,
        3,
        tiles,
        Vec::new(),
    )
    .expect("map")
}
