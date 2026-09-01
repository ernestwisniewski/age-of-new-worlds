use aonw_content::{GridLayout, MapDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    GameState, HexCoord, MovementUnits, PlayerId, StateRevision, Unit, UnitActivity, UnitId,
    UnitKind, UnitOccupancyPolicy, UnitPosture,
};

use super::{
    ReachableMovementQuery, TerrainMovementQuery, TerrainMovementQueryError, find_reachable_tiles,
    plan_terrain_route,
};
use crate::{EngineContext, movement::MovementPlanningView};

fn map(cols: u16, rows: u16, rough: &[HexCoord], blocked: &[HexCoord]) -> MapDefinition {
    let mut tiles = Vec::new();
    for row in 0..rows {
        for col in 0..cols {
            let coordinate = HexCoord::new(i32::from(col), i32::from(row));
            let terrains = if blocked.contains(&coordinate) {
                vec![TerrainType::Mountain]
            } else if rough.contains(&coordinate) {
                vec![TerrainType::Plains, TerrainType::Hills]
            } else {
                vec![TerrainType::Plains]
            };
            tiles.push(
                TileDefinition::try_new_for_simulation(coordinate, terrains, Vec::new(), 0)
                    .expect("valid tile"),
            );
        }
    }
    MapDefinition::try_new(
        "movement-fixture",
        GridLayout::OddQFlatTop,
        cols,
        rows,
        tiles,
        Vec::new(),
    )
    .expect("valid map")
}

fn unit(id: &str, owner: &PlayerId, position: HexCoord, movement: u32) -> Unit {
    unit_builder(id, owner, position, movement, UnitKind::Warrior)
        .build()
        .expect("valid unit")
}

fn unit_builder(
    id: &str,
    owner: &PlayerId,
    position: HexCoord,
    movement: u32,
    kind: UnitKind,
) -> aonw_domain::UnitBuilder {
    Unit::builder(
        UnitId::new(id).expect("valid unit id"),
        owner.clone(),
        kind,
        format!("unit.{id}"),
        position,
        MovementUnits::new(movement),
    )
}

fn state(revision: u64, map: &MapDefinition, units: impl IntoIterator<Item = Unit>) -> GameState {
    GameState::try_new(
        StateRevision::new(revision),
        1,
        map.bounds(),
        UnitOccupancyPolicy::Exclusive,
        units,
    )
    .expect("valid state")
}

#[test]
fn route_is_deterministic_when_equal_cost_paths_exist() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let map = map(3, 3, &[], &[]);
    let state = state(7, &map, [unit("unit-1", &actor, HexCoord::new(0, 1), 6)]);
    let unit_id = UnitId::new("unit-1").expect("valid unit id");
    let context = EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled());

    let first = plan_terrain_route(
        &state,
        context,
        TerrainMovementQuery::new(7, &unit_id, HexCoord::new(2, 1)),
    )
    .expect("route exists");
    let second = plan_terrain_route(
        &state,
        context,
        TerrainMovementQuery::new(7, &unit_id, HexCoord::new(2, 1)),
    )
    .expect("route exists");

    assert_eq!(first, second);
    assert_eq!(
        first
            .steps()
            .iter()
            .map(|step| step.coordinate())
            .collect::<Vec<_>>(),
        [
            HexCoord::new(0, 1),
            HexCoord::new(1, 0),
            HexCoord::new(2, 1)
        ]
    );
}

#[test]
fn route_reports_rough_cost_and_executable_turn_prefix() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let map = map(4, 1, &[HexCoord::new(1, 0)], &[]);
    let state = state(3, &map, [unit("unit-1", &actor, HexCoord::new(0, 0), 3)]);
    let unit_id = UnitId::new("unit-1").expect("valid unit id");

    let plan = plan_terrain_route(
        &state,
        EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
        TerrainMovementQuery::new(3, &unit_id, HexCoord::new(3, 0)),
    )
    .expect("route exists");

    assert_eq!(plan.total_cost(), MovementUnits::new(8));
    assert_eq!(plan.reachable_steps().len(), 2);
    assert_eq!(plan.remaining_movement(), MovementUnits::ZERO);
    assert_eq!(plan.estimated_turns(), 2);
    assert!(!plan.target_reachable_this_turn());
}

#[test]
fn query_rejects_blocked_occupied_and_out_of_bounds_targets() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let map = map(3, 1, &[], &[HexCoord::new(1, 0)]);
    let mover = unit("unit-1", &actor, HexCoord::new(0, 0), 6);
    let blocker = unit("unit-2", &actor, HexCoord::new(2, 0), 6);
    let state = state(5, &map, [mover, blocker]);
    let unit_id = UnitId::new("unit-1").expect("valid unit id");
    let context = EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled());

    assert_eq!(
        plan_terrain_route(
            &state,
            context,
            TerrainMovementQuery::new(5, &unit_id, HexCoord::new(2, 0)),
        ),
        Err(TerrainMovementQueryError::TargetOccupied)
    );
    assert_eq!(
        plan_terrain_route(
            &state,
            context,
            TerrainMovementQuery::new(5, &unit_id, HexCoord::new(1, 0)),
        ),
        Err(TerrainMovementQueryError::PathNotFound)
    );
    assert_eq!(
        plan_terrain_route(
            &state,
            context,
            TerrainMovementQuery::new(5, &unit_id, HexCoord::new(3, 0)),
        ),
        Err(TerrainMovementQueryError::TargetOutOfBounds)
    );
}

#[test]
fn stale_revision_fails_before_route_work() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let map = map(2, 1, &[], &[]);
    let state = state(9, &map, [unit("unit-1", &actor, HexCoord::new(0, 0), 6)]);
    let unit_id = UnitId::new("unit-1").expect("valid unit id");

    assert_eq!(
        plan_terrain_route(
            &state,
            EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
            TerrainMovementQuery::new(8, &unit_id, HexCoord::new(1, 0)),
        ),
        Err(TerrainMovementQueryError::StaleRevision {
            expected: 8,
            actual: 9,
        })
    );
}

#[test]
fn command_guards_keep_rejection_precedence() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let other = PlayerId::new("player-2").expect("valid player");
    let map = map(2, 1, &[], &[]);
    let unit_id = UnitId::new("unit-1").expect("valid unit id");

    let foreign = state(4, &map, [unit("unit-1", &other, HexCoord::new(0, 0), 6)]);
    assert_eq!(
        plan_terrain_route(
            &foreign,
            EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
            TerrainMovementQuery::new(4, &unit_id, HexCoord::new(1, 0)),
        ),
        Err(TerrainMovementQueryError::UnitNotControlled)
    );

    let working_unit = unit_builder("unit-1", &actor, HexCoord::new(0, 0), 6, UnitKind::Warrior)
        .with_activity(UnitActivity::new(
            None,
            None,
            Some(HexCoord::new(0, 0)),
            None,
        ))
        .build()
        .expect("valid working unit");
    let working = state(4, &map, [working_unit]);
    assert_eq!(
        plan_terrain_route(
            &working,
            EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
            TerrainMovementQuery::new(4, &unit_id, HexCoord::new(1, 0)),
        ),
        Err(TerrainMovementQueryError::UnitUnavailable)
    );

    let merchant = unit_builder("unit-1", &actor, HexCoord::new(0, 0), 6, UnitKind::Merchant)
        .build()
        .expect("valid merchant");
    let merchant_state = state(4, &map, [merchant]);
    assert_eq!(
        plan_terrain_route(
            &merchant_state,
            EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
            TerrainMovementQuery::new(4, &unit_id, HexCoord::new(1, 0)),
        ),
        Err(TerrainMovementQueryError::UnitUsesTradeRoutes)
    );
}

#[test]
fn fortified_unit_uses_restored_capacity_for_preview() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let map = map(2, 1, &[], &[]);
    let unit_id = UnitId::new("unit-1").expect("valid unit id");
    let fortified = unit_builder("unit-1", &actor, HexCoord::new(0, 0), 0, UnitKind::Warrior)
        .with_posture(UnitPosture::Fortified)
        .build()
        .expect("valid fortified unit");
    let state = state(2, &map, [fortified]);

    let plan = plan_terrain_route(
        &state,
        EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
        TerrainMovementQuery::new(2, &unit_id, HexCoord::new(1, 0)),
    )
    .expect("fortified unit can wake and move");

    assert_eq!(plan.available_movement(), MovementUnits::new(6));
    assert!(plan.target_reachable_this_turn());
}

#[test]
fn route_search_handles_the_maximum_supported_map() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let map = map(40, 30, &[], &[]);
    let unit_id = UnitId::new("unit-1").expect("valid unit id");
    let state = state(11, &map, [unit("unit-1", &actor, HexCoord::new(0, 0), 6)]);

    let plan = plan_terrain_route(
        &state,
        EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
        TerrainMovementQuery::new(11, &unit_id, HexCoord::new(39, 29)),
    )
    .expect("route exists");

    assert_eq!(
        plan.steps().first().map(|step| step.coordinate()),
        Some(HexCoord::new(0, 0))
    );
    assert_eq!(
        plan.steps().last().map(|step| step.coordinate()),
        Some(HexCoord::new(39, 29))
    );
}

#[test]
fn oversized_movement_balance_is_bounded_before_route_search() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let map = map(2, 1, &[], &[]);
    let unit_id = UnitId::new("unit-1").expect("valid unit id");
    let state = state(
        12,
        &map,
        [unit("unit-1", &actor, HexCoord::new(0, 0), u32::MAX)],
    );

    let plan = plan_terrain_route(
        &state,
        EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
        TerrainMovementQuery::new(12, &unit_id, HexCoord::new(1, 0)),
    )
    .expect("oversized balance is bounded before search");

    assert_eq!(plan.destination(), HexCoord::new(1, 0));
    assert_eq!(plan.available_movement(), MovementUnits::new(6));
}

#[test]
fn fog_aware_planning_does_not_reveal_unknown_blockers() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let other = PlayerId::new("player-2").expect("valid player");
    let map = map(3, 3, &[], &[]);
    let mover = unit("unit-1", &actor, HexCoord::new(0, 1), 6);
    let hidden = unit("unit-hidden", &other, HexCoord::new(1, 0), 6);
    let state = state(3, &map, [mover, hidden]);
    let unit_id = UnitId::new("unit-1").expect("valid unit id");
    let no_known_units: Vec<UnitId> = Vec::new();

    let plan = plan_terrain_route(
        &state,
        EngineContext::new(
            &actor,
            &map,
            MovementPlanningView::known_units(&no_known_units),
        ),
        TerrainMovementQuery::new(3, &unit_id, HexCoord::new(2, 1)),
    )
    .expect("unknown blockers do not affect the actor-visible route");

    assert!(
        plan.steps()
            .iter()
            .any(|step| step.coordinate() == HexCoord::new(1, 0))
    );
}

#[test]
fn friendly_occupancy_is_known_even_when_visibility_ids_omit_it() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let map = map(3, 1, &[], &[]);
    let mover = unit("unit-1", &actor, HexCoord::new(0, 0), 6);
    let friendly = unit("unit-2", &actor, HexCoord::new(1, 0), 6);
    let state = GameState::try_new(
        StateRevision::new(3),
        1,
        map.bounds(),
        UnitOccupancyPolicy::FriendlyStacking,
        [mover, friendly],
    )
    .expect("valid state");
    let unit_id = UnitId::new("unit-1").expect("valid unit id");
    let no_known_units: Vec<UnitId> = Vec::new();

    assert_eq!(
        plan_terrain_route(
            &state,
            EngineContext::new(
                &actor,
                &map,
                MovementPlanningView::known_units(&no_known_units),
            ),
            TerrainMovementQuery::new(3, &unit_id, HexCoord::new(2, 0)),
        ),
        Err(TerrainMovementQueryError::PathNotFound)
    );
}

#[test]
fn occupied_target_uses_deterministic_approach_policy() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let other = PlayerId::new("player-2").expect("valid player");
    let map = map(3, 3, &[], &[]);
    let mover = unit("unit-1", &actor, HexCoord::new(0, 1), 6);
    let enemy = unit("unit-2", &other, HexCoord::new(2, 1), 6);
    let state = state(4, &map, [mover, enemy]);
    let unit_id = UnitId::new("unit-1").expect("valid unit id");

    let plan = plan_terrain_route(
        &state,
        EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
        TerrainMovementQuery::new(4, &unit_id, HexCoord::new(2, 1)),
    )
    .expect("enemy target produces an approach route");

    assert_eq!(plan.target(), HexCoord::new(2, 1));
    assert_eq!(plan.destination(), HexCoord::new(1, 0));
}

#[test]
fn action_permission_preserves_not_controlled_precedence() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let map = map(2, 1, &[], &[]);
    let blocked = unit_builder("unit-1", &actor, HexCoord::new(0, 0), 6, UnitKind::Warrior)
        .with_activity(UnitActivity::new(
            None,
            None,
            Some(HexCoord::new(0, 0)),
            None,
        ))
        .build()
        .expect("valid blocked unit");
    let state = state(4, &map, [blocked]);
    let unit_id = UnitId::new("unit-1").expect("valid unit id");

    assert_eq!(
        plan_terrain_route(
            &state,
            EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled())
                .with_action_permission(false),
            TerrainMovementQuery::new(4, &unit_id, HexCoord::new(1, 0)),
        ),
        Err(TerrainMovementQueryError::UnitNotControlled)
    );
}

#[test]
fn reachable_query_performs_one_bounded_row_major_search() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let map = map(4, 1, &[HexCoord::new(1, 0), HexCoord::new(2, 0)], &[]);
    let state = state(6, &map, [unit("unit-1", &actor, HexCoord::new(0, 0), 3)]);
    let unit_id = UnitId::new("unit-1").expect("valid unit id");

    let reachable = find_reachable_tiles(
        &state,
        EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
        ReachableMovementQuery::new(6, &unit_id),
    )
    .expect("reachable query succeeds");

    assert_eq!(reachable.tiles().len(), 1);
    assert_eq!(reachable.tiles()[0].coordinate(), HexCoord::new(1, 0));
    assert_eq!(reachable.tiles()[0].cost(), MovementUnits::new(4));
    assert!(reachable.tiles()[0].exhausts_movement());
}
