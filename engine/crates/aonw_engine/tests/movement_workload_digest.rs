//! Stable output signatures for the reference movement workload.

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    GameState, HexCoord, MovementUnits, PlayerId, StateRevision, Unit, UnitId, UnitKind,
    UnitOccupancyPolicy,
};
use aonw_engine::{
    CompiledMovementMap, EngineContext, GameEngine, GameQuery, MoveUnitCommand,
    MovementSearchMetrics, MovementSearchWorkspace, PlayerCommand, QueryResult, ReachableMovement,
    ReachableMovementQuery, TerrainMovementPlan, TerrainMovementQuery,
};

#[test]
fn reference_workload_outputs_are_deterministic() {
    let map = map();
    let actor = PlayerId::new("player-1").expect("actor id");
    let mover_id = UnitId::new("unit-0").expect("mover id");
    let state = state(&actor);
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());

    let reachable = query_reachable(&state, context, &mover_id);
    let reachable_signature =
        reachable
            .tiles()
            .iter()
            .fold(0xcbf2_9ce4_8422_2325, |digest, tile| {
                mix(
                    mix(
                        mix(digest, signed(tile.coordinate().col())),
                        signed(tile.coordinate().row()),
                    ),
                    u64::from(tile.cost().get()),
                )
            });

    let route = query_route(&state, context, &mover_id, HexCoord::new(39, 29));
    let route_signature = route
        .steps()
        .iter()
        .fold(0xcbf2_9ce4_8422_2325, |digest, step| {
            mix(
                mix(
                    mix(digest, signed(step.coordinate().col())),
                    signed(step.coordinate().row()),
                ),
                u64::from(step.cumulative_cost().get()),
            )
        });

    let transition = GameEngine::apply_player_owned(
        state.clone(),
        context,
        PlayerCommand::MoveUnit(MoveUnitCommand::new(
            state.revision().get(),
            &mover_id,
            HexCoord::new(1, 0),
        )),
    )
    .expect("apply workload");
    let moved = transition.state().unit(&mover_id).expect("moved unit");
    let apply_signature = mix(
        mix(
            transition.state().revision().get(),
            signed(moved.position().col()),
        ),
        u64::from(moved.movement_units().get()),
    );
    let adjacent = query_route(&state, context, &mover_id, HexCoord::new(1, 0));
    let adjacent_metrics = adjacent.search_metrics();

    assert_eq!(reachable_signature, 0x0640_82dd_455f_87ae);
    assert_eq!(route_signature, 0xd251_05c5_932a_ff07);
    assert_eq!(apply_signature, 0x000a_2a00_0008_9be3);
    assert_eq!(metrics_tuple(reachable.search_metrics()), (6, 5, 18, 6, 0),);
    assert_eq!(
        metrics_tuple(route.search_metrics()),
        (2_824, 2_823, 16_250, 3_021, 3_021),
    );
    assert_eq!(metrics_tuple(adjacent_metrics), (2, 1, 2, 2, 2),);
}

fn query_reachable(
    state: &GameState,
    context: EngineContext<'_>,
    unit_id: &UnitId,
) -> ReachableMovement {
    let result = GameEngine::query(
        state,
        context,
        GameQuery::Reachable(ReachableMovementQuery::new(state.revision().get(), unit_id)),
    )
    .expect("reachable workload");
    let QueryResult::Reachable(result) = result else {
        panic!("reachable result")
    };
    result
}

fn query_route(
    state: &GameState,
    context: EngineContext<'_>,
    unit_id: &UnitId,
    target: HexCoord,
) -> TerrainMovementPlan {
    let result = GameEngine::query(
        state,
        context,
        GameQuery::PlanRoute(TerrainMovementQuery::new(
            state.revision().get(),
            unit_id,
            target,
        )),
    )
    .expect("route workload");
    let QueryResult::Route(result) = result else {
        panic!("route result")
    };
    result
}

const fn metrics_tuple(metrics: MovementSearchMetrics) -> (u64, u64, u64, u64, u64) {
    (
        metrics.frontier_pops(),
        metrics.expanded_tiles(),
        metrics.examined_edges(),
        metrics.heap_pushes(),
        metrics.route_records(),
    )
}

#[test]
fn prepared_and_reused_searches_preserve_reference_results() {
    let map = map();
    let actor = PlayerId::new("player-1").expect("actor id");
    let mover_id = UnitId::new("unit-0").expect("mover id");
    let state = state(&actor);
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let compiled =
        CompiledMovementMap::compile_owned(map.clone(), RulesetDefinition::standard().clone())
            .expect("compiled map");
    let prepared = context.with_compiled_movement_map(&compiled);
    let query = ReachableMovementQuery::new(state.revision().get(), &mover_id);
    let expected =
        GameEngine::query(&state, context, GameQuery::Reachable(query)).expect("raw reachable");
    let mut workspace = MovementSearchWorkspace::default();
    let first = GameEngine::query_with_workspace(
        &state,
        prepared,
        GameQuery::Reachable(query),
        &mut workspace,
    )
    .expect("prepared reachable");
    let reused = GameEngine::query_with_workspace(
        &state,
        prepared,
        GameQuery::Reachable(query),
        &mut workspace,
    )
    .expect("reused reachable");

    assert_eq!(first, expected);
    assert_eq!(reused, expected);
    assert_eq!(compiled.bounds(), map.bounds());
}

fn map() -> MapDefinition {
    let tiles = (0..30)
        .flat_map(|row| {
            (0..40).map(move |col| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(col, row),
                    vec![TerrainType::Grassland],
                    Vec::new(),
                    0,
                )
                .expect("reference tile")
            })
        })
        .collect();
    MapDefinition::try_new(
        "benchmark_40x30",
        GridLayout::OddQFlatTop,
        40,
        30,
        tiles,
        Vec::new(),
    )
    .expect("reference map")
}

fn state(actor: &PlayerId) -> GameState {
    let mut units = vec![unit(
        "unit-0",
        actor,
        UnitKind::Commander,
        HexCoord::new(0, 0),
        10,
    )];
    let positions = (1..30).flat_map(|row| (0..39).map(move |col| HexCoord::new(col, row)));
    for (index, position) in positions.take(63).enumerate() {
        units.push(unit(
            &format!("unit-{}", index + 1),
            actor,
            UnitKind::Warrior,
            position,
            6,
        ));
    }
    GameState::try_new(
        StateRevision::new(1),
        1,
        aonw_domain::HexGridBounds::new(40, 30).expect("bounds"),
        UnitOccupancyPolicy::Exclusive,
        units,
    )
    .expect("reference state")
}

fn unit(id: &str, owner: &PlayerId, kind: UnitKind, position: HexCoord, movement: u32) -> Unit {
    Unit::builder(
        UnitId::new(id).expect("unit id"),
        owner.clone(),
        kind,
        format!("unit.{id}"),
        position,
        MovementUnits::new(movement),
    )
    .build()
    .expect("unit")
}

fn signed(value: i32) -> u64 {
    i64::from(value).cast_unsigned()
}

const fn mix(digest: u64, value: u64) -> u64 {
    (digest ^ value).wrapping_mul(0x0000_0100_0000_01b3)
}
