//! Diagnostic map and movement baseline without a timing gate.

use std::alloc::System;
use std::hint::black_box;

use aonw_content::{MapDefinition, MapDocument};
use aonw_domain::{GameState, HexCoord, PlayerId, UnitId};
use aonw_engine::{
    CanonicalQueryError, CompiledMovementMap, EngineContext, GameEngine, GameQuery,
    MoveUnitCommand, MovementSearchMetrics, MovementSearchWorkspace, PlayerCommand, QueryResult,
    ReachableMovement, ReachableMovementQuery, TerrainMovementPlan, TerrainMovementQuery,
};
use stats_alloc::{INSTRUMENTED_SYSTEM, StatsAlloc};

#[global_allocator]
static GLOBAL: &StatsAlloc<System> = &INSTRUMENTED_SYSTEM;

#[path = "movement/city.rs"]
mod city;
#[path = "movement/combat.rs"]
mod combat;
#[path = "movement/logistics.rs"]
mod logistics;
#[path = "movement/support.rs"]
mod support;
#[path = "movement/worker.rs"]
mod worker;

use support::{
    hidden_blocker_state, map, mix, movement_state, occupied_target_state, report, signature_bytes,
    signed,
};

fn main() {
    println!(
        "workload,tiles,units,iterations,allocations,reallocations,allocated_bytes,payload_bytes,frontier_pops,expanded_tiles,examined_edges,heap_pushes,route_records,signature,median_ns,p95_ns"
    );
    for (cols, rows, unit_counts) in [
        (10, 10, &[1, 10][..]),
        (30, 20, &[1, 64][..]),
        (40, 30, &[1, 64, 512][..]),
    ] {
        benchmark_map(cols, rows, unit_counts);
    }
}

fn benchmark_map(cols: u16, rows: u16, unit_counts: &[usize]) {
    let map = map(cols, rows);
    let document = MapDocument::try_new(map.clone(), 1.0).expect("benchmark map document");
    let json = document.to_versioned_json().expect("benchmark map JSON");
    report(
        "open",
        cols,
        rows,
        0,
        MovementSearchMetrics::default(),
        json.len(),
        || {
            let opened = MapDocument::from_json(black_box(json.as_bytes())).expect("open map");
            signature_bytes(
                opened
                    .map()
                    .content_hash()
                    .expect("content hash")
                    .as_bytes(),
            )
        },
    );
    report(
        "content_hash",
        cols,
        rows,
        0,
        MovementSearchMetrics::default(),
        0,
        || {
            signature_bytes(
                black_box(&map)
                    .content_hash()
                    .expect("content hash")
                    .as_bytes(),
            )
        },
    );
    for &unit_count in unit_counts {
        benchmark_movement(&map, cols, rows, unit_count);
        logistics::benchmark(&map, cols, rows, unit_count);
        combat::benchmark(&map, cols, rows, unit_count);
        city::benchmark(&map, cols, rows, unit_count);
    }
    worker::benchmark(&map, cols, rows);
}

fn benchmark_movement(map: &MapDefinition, cols: u16, rows: u16, unit_count: usize) {
    let actor = PlayerId::new("player-1").expect("actor id");
    let mover_id = UnitId::new("unit-0").expect("mover id");
    let state = movement_state(cols, rows, unit_count, &actor);
    let context =
        EngineContext::canonical(&actor, map, aonw_content::RulesetDefinition::standard());
    let compiled = CompiledMovementMap::compile_owned(
        map.clone(),
        aonw_content::RulesetDefinition::standard().clone(),
    )
    .expect("compiled movement map");
    let prepared_context = context.with_compiled_movement_map(&compiled);
    let target = HexCoord::new(i32::from(cols) - 1, i32::from(rows) - 1);
    let (reachable_metrics, route_metrics, apply_metrics) =
        movement_metrics(&state, context, &mover_id, target);

    benchmark_reachable(
        &state,
        context,
        prepared_context,
        &mover_id,
        (cols, rows, unit_count),
        reachable_metrics,
    );
    benchmark_routes(
        &state,
        context,
        prepared_context,
        &mover_id,
        target,
        (cols, rows, unit_count),
        route_metrics,
    );
    benchmark_apply(
        &state,
        context,
        prepared_context,
        &mover_id,
        (cols, rows, unit_count),
        apply_metrics,
    );
}

fn benchmark_reachable(
    state: &GameState,
    context: EngineContext<'_>,
    prepared_context: EngineContext<'_>,
    mover_id: &UnitId,
    dimensions: (u16, u16, usize),
    metrics: MovementSearchMetrics,
) {
    let (cols, rows, units) = dimensions;
    let signature = |result: &aonw_engine::ReachableMovement| {
        result
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
            })
    };
    report("reachable", cols, rows, units, metrics, 0, || {
        reachable(
            black_box(state),
            context,
            ReachableMovementQuery::new(state.revision().get(), mover_id),
        )
        .map_or_else(
            |error| signature_bytes(error.to_string().as_bytes()),
            |result| signature(&result),
        )
    });
    let mut workspace = MovementSearchWorkspace::default();
    report("prepared_reachable", cols, rows, units, metrics, 0, || {
        reachable_with_workspace(
            black_box(state),
            prepared_context,
            ReachableMovementQuery::new(state.revision().get(), mover_id),
            &mut workspace,
        )
        .map_or_else(
            |error| signature_bytes(error.to_string().as_bytes()),
            |result| signature(&result),
        )
    });
}

fn benchmark_routes(
    state: &GameState,
    context: EngineContext<'_>,
    prepared_context: EngineContext<'_>,
    mover_id: &UnitId,
    target: HexCoord,
    dimensions: (u16, u16, usize),
    metrics: MovementSearchMetrics,
) {
    let (cols, rows, units) = dimensions;
    for (name, selected_context) in [("route", context), ("prepared_route", prepared_context)] {
        report(name, cols, rows, units, metrics, 0, || {
            route(
                black_box(state),
                selected_context,
                TerrainMovementQuery::new(state.revision().get(), mover_id, target),
            )
            .map_or_else(
                |error| signature_bytes(error.code().as_bytes()),
                |result| route_signature(&result),
            )
        });
    }
    let occupied_target = HexCoord::new(i32::from(cols) - 2, i32::from(rows) - 1);
    let occupied_state = occupied_target_state(state, occupied_target);
    let query =
        || TerrainMovementQuery::new(occupied_state.revision().get(), mover_id, occupied_target);
    let occupied_metrics = route(&occupied_state, prepared_context, query()).map_or_else(
        |_| MovementSearchMetrics::default(),
        |result| result.search_metrics(),
    );
    report(
        "occupied_approach",
        cols,
        rows,
        units + 1,
        occupied_metrics,
        0,
        || {
            route(black_box(&occupied_state), prepared_context, query()).map_or_else(
                |error| signature_bytes(error.code().as_bytes()),
                |result| {
                    mix(
                        signed(result.destination().col()),
                        signed(result.destination().row()),
                    )
                },
            )
        },
    );
}

fn benchmark_apply(
    state: &GameState,
    context: EngineContext<'_>,
    prepared_context: EngineContext<'_>,
    mover_id: &UnitId,
    dimensions: (u16, u16, usize),
    metrics: MovementSearchMetrics,
) {
    let (cols, rows, units) = dimensions;
    report("apply", cols, rows, units, metrics, 0, || {
        GameEngine::apply_player_owned(
            black_box(state.clone()),
            context,
            PlayerCommand::MoveUnit(MoveUnitCommand::new(
                state.revision().get(),
                mover_id,
                HexCoord::new(1, 0),
            )),
        )
        .map_or_else(
            |error| signature_bytes(error.to_string().as_bytes()),
            |result| transition_signature(&result, mover_id),
        )
    });
    report("prepared_apply", cols, rows, units, metrics, 0, || {
        GameEngine::apply_player_owned(
            black_box(state.clone()),
            prepared_context,
            PlayerCommand::MoveUnit(MoveUnitCommand::new(
                state.revision().get(),
                mover_id,
                HexCoord::new(1, 0),
            )),
        )
        .map_or_else(
            |error| signature_bytes(error.to_string().as_bytes()),
            |result| transition_signature(&result, mover_id),
        )
    });
    report(
        "prepared_apply_rejected",
        cols,
        rows,
        units,
        MovementSearchMetrics::default(),
        0,
        || {
            GameEngine::apply_player_owned(
                black_box(state.clone()),
                prepared_context,
                PlayerCommand::MoveUnit(MoveUnitCommand::new(
                    state.revision().get() + 1,
                    mover_id,
                    HexCoord::new(1, 0),
                )),
            )
            .map_or_else(
                |error| signature_bytes(error.to_string().as_bytes()),
                |result| result.digest().as_bytes()[0].into(),
            )
        },
    );
    if units == 1 {
        let hidden = hidden_blocker_state(cols, rows, context.actor_player_id());
        report(
            "prepared_apply_hidden_noop",
            cols,
            rows,
            units + 1,
            MovementSearchMetrics::default(),
            0,
            || {
                GameEngine::apply_player_owned(
                    black_box(hidden.clone()),
                    prepared_context,
                    PlayerCommand::MoveUnit(MoveUnitCommand::new(
                        hidden.revision().get(),
                        mover_id,
                        HexCoord::new(1, 0),
                    )),
                )
                .map_or_else(
                    |error| signature_bytes(error.to_string().as_bytes()),
                    |result| transition_signature(&result, mover_id),
                )
            },
        );
    }
}

fn transition_signature(result: &aonw_engine::DomainTransition, mover_id: &UnitId) -> u64 {
    let next = result.state();
    let moved = next.unit(mover_id).expect("moved unit");
    mix(
        mix(next.revision().get(), signed(moved.position().col())),
        u64::from(moved.movement_units().get()),
    )
}

fn route_signature(result: &aonw_engine::TerrainMovementPlan) -> u64 {
    result
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
        })
}

fn movement_metrics(
    state: &GameState,
    context: EngineContext<'_>,
    mover_id: &UnitId,
    target: HexCoord,
) -> (
    MovementSearchMetrics,
    MovementSearchMetrics,
    MovementSearchMetrics,
) {
    let reachable = reachable(
        state,
        context,
        ReachableMovementQuery::new(state.revision().get(), mover_id),
    )
    .map_or_else(
        |_| MovementSearchMetrics::default(),
        |result| result.search_metrics(),
    );
    let route_metrics = route(
        state,
        context,
        TerrainMovementQuery::new(state.revision().get(), mover_id, target),
    )
    .map_or_else(
        |_| MovementSearchMetrics::default(),
        |result| result.search_metrics(),
    );
    let apply_metrics = route(
        state,
        context,
        TerrainMovementQuery::new(state.revision().get(), mover_id, HexCoord::new(1, 0)),
    )
    .map_or_else(
        |_| MovementSearchMetrics::default(),
        |result| result.search_metrics(),
    );
    (reachable, route_metrics, apply_metrics)
}

fn reachable(
    state: &GameState,
    context: EngineContext<'_>,
    query: ReachableMovementQuery<'_>,
) -> Result<ReachableMovement, CanonicalQueryError> {
    match GameEngine::query(state, context, GameQuery::Reachable(query))? {
        QueryResult::Reachable(result) => Ok(result),
        QueryResult::CityFoundingOptions(_)
        | QueryResult::CityWorkedHexOptions(_)
        | QueryResult::CityExpansionOptions(_)
        | QueryResult::CityYield(_)
        | QueryResult::EconomyForecast(_)
        | QueryResult::StrategicResourceProjection(_)
        | QueryResult::ProductionOptions(_)
        | QueryResult::CombatPreview(_)
        | QueryResult::Route(_)
        | QueryResult::UnitLogisticsOptions(_)
        | QueryResult::WorkerOptions(_)
        | QueryResult::ResearchOptions(_) => {
            unreachable!("reachable query returned another result")
        }
    }
}

fn reachable_with_workspace(
    state: &GameState,
    context: EngineContext<'_>,
    query: ReachableMovementQuery<'_>,
    workspace: &mut MovementSearchWorkspace,
) -> Result<ReachableMovement, CanonicalQueryError> {
    match GameEngine::query_with_workspace(state, context, GameQuery::Reachable(query), workspace)?
    {
        QueryResult::Reachable(result) => Ok(result),
        QueryResult::CityFoundingOptions(_)
        | QueryResult::CityWorkedHexOptions(_)
        | QueryResult::CityExpansionOptions(_)
        | QueryResult::CityYield(_)
        | QueryResult::EconomyForecast(_)
        | QueryResult::StrategicResourceProjection(_)
        | QueryResult::ProductionOptions(_)
        | QueryResult::CombatPreview(_)
        | QueryResult::Route(_)
        | QueryResult::UnitLogisticsOptions(_)
        | QueryResult::WorkerOptions(_)
        | QueryResult::ResearchOptions(_) => {
            unreachable!("reachable query returned another result")
        }
    }
}

fn route(
    state: &GameState,
    context: EngineContext<'_>,
    query: TerrainMovementQuery<'_>,
) -> Result<TerrainMovementPlan, CanonicalQueryError> {
    match GameEngine::query(state, context, GameQuery::PlanRoute(query))? {
        QueryResult::Route(result) => Ok(result),
        QueryResult::CityFoundingOptions(_)
        | QueryResult::CityWorkedHexOptions(_)
        | QueryResult::CityExpansionOptions(_)
        | QueryResult::CityYield(_)
        | QueryResult::EconomyForecast(_)
        | QueryResult::StrategicResourceProjection(_)
        | QueryResult::ProductionOptions(_)
        | QueryResult::CombatPreview(_)
        | QueryResult::Reachable(_)
        | QueryResult::UnitLogisticsOptions(_)
        | QueryResult::WorkerOptions(_)
        | QueryResult::ResearchOptions(_) => {
            unreachable!("route query returned another result")
        }
    }
}
