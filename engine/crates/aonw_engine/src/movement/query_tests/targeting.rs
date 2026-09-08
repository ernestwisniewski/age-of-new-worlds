use super::*;
use aonw_domain::QueuedMovePath;

#[test]
fn targeting_distinguishes_exhaustion_from_suspended_manual_control() {
    let actor = PlayerId::new("player-1").expect("actor");
    let map = map(2, 1, &[], &[]);
    for (posture, movement, can_start, can_retain) in [
        (UnitPosture::Active, 6, true, true),
        (UnitPosture::Active, 0, false, true),
        (UnitPosture::Fortified, 0, true, true),
        (UnitPosture::AutoExploring, 6, false, false),
        (UnitPosture::AutoWorking, 6, false, false),
    ] {
        let unit = unit_builder(
            "unit-1",
            &actor,
            HexCoord::new(0, 0),
            movement,
            UnitKind::Warrior,
        )
        .with_posture(posture)
        .build()
        .expect("unit");
        let state = state(3, &map, [unit]);
        let unit_id = UnitId::new("unit-1").expect("id");
        let reachable = find_reachable_tiles(
            &state,
            EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
            ReachableMovementQuery::new(3, &unit_id),
        )
        .expect("reachable");
        assert_eq!(reachable.can_start_targeting(), can_start, "{posture:?}");
        assert_eq!(reachable.can_retain_targeting(), can_retain, "{posture:?}");
    }
}

#[test]
fn queued_route_prevents_new_and_retained_targeting() {
    let actor = PlayerId::new("player-1").expect("actor");
    let map = map(3, 1, &[], &[]);
    let unit_id = UnitId::new("unit-1").expect("id");
    let initial = state(3, &map, [unit("unit-1", &actor, HexCoord::new(0, 0), 6)]);
    let plan = plan_terrain_route(
        &initial,
        EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
        TerrainMovementQuery::new(3, &unit_id, HexCoord::new(2, 0)),
    )
    .expect("route");
    let path = QueuedMovePath::try_new(HexCoord::new(2, 0), plan.steps().to_vec()).expect("path");
    let queued = unit_builder("unit-1", &actor, HexCoord::new(0, 0), 6, UnitKind::Warrior)
        .with_queued_path(Some(path))
        .build()
        .expect("queued unit");
    let state = state(3, &map, [queued]);
    let reachable = find_reachable_tiles(
        &state,
        EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
        ReachableMovementQuery::new(3, &unit_id),
    )
    .expect("reachable");
    assert!(!reachable.can_start_targeting());
    assert!(!reachable.can_retain_targeting());
}

#[test]
fn targeting_query_does_not_expose_foreign_or_trade_route_unit_options() {
    let actor = PlayerId::new("player-1").expect("actor");
    let other = PlayerId::new("player-2").expect("other");
    let map = map(2, 1, &[], &[]);
    let unit_id = UnitId::new("unit-1").expect("id");
    for (owner, kind, error) in [
        (
            &other,
            UnitKind::Warrior,
            TerrainMovementQueryError::UnitNotControlled,
        ),
        (
            &actor,
            UnitKind::Merchant,
            TerrainMovementQueryError::UnitUsesTradeRoutes,
        ),
    ] {
        let unit = unit_builder("unit-1", owner, HexCoord::new(0, 0), 6, kind)
            .build()
            .expect("unit");
        let state = state(3, &map, [unit]);
        assert_eq!(
            find_reachable_tiles(
                &state,
                EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
                ReachableMovementQuery::new(3, &unit_id)
            ),
            Err(error)
        );
    }
}
