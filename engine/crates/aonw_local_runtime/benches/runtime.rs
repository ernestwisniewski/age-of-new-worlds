//! Diagnostic local-runtime and JSON-adapter baseline without a timing gate.

use std::alloc::System;
use std::hint::black_box;
use std::time::Instant;

use aonw_content::{
    GridLayout, MapDefinition, MapDocument, RulesetDefinition, ScenarioDefinition,
    ScenarioUnitDefinition, TerrainType, TileDefinition,
};
use aonw_contracts::CoordinateDto;
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientCommandDto, ClientRequestBodyDto, ClientRequestDto,
};
use aonw_domain::{
    FogOfWar, GameState, HexCoord, PlayerFog, PlayerId, StateRevision, Unit, UnitId, UnitKind,
};
use aonw_local_runtime::{
    ClientProtocol, FinalizeTimedOutTurnRequest, KickParticipantRequest, LocalRuntime,
    MoveUnitRequest, OpenSession, TurnCommandRequest,
};
use serde_json::json;
use stats_alloc::{INSTRUMENTED_SYSTEM, Region, Stats, StatsAlloc};

#[global_allocator]
static GLOBAL: &StatsAlloc<System> = &INSTRUMENTED_SYSTEM;

#[path = "runtime/combat_support.rs"]
mod combat_support;
#[path = "runtime/turn_support.rs"]
mod turn_support;

const COLS: u16 = 40;
const ROWS: u16 = 30;
const ITERATIONS: usize = 20;

fn main() {
    println!(
        "workload,tiles,units,iterations,allocations,reallocations,allocated_bytes,payload_bytes,signature,median_ns,p95_ns"
    );
    for unit_count in [1, 64, 512] {
        benchmark_runtime(unit_count);
        benchmark_turn_kernel(unit_count);
        combat_support::benchmark(unit_count);
    }
}

fn benchmark_turn_kernel(unit_count: usize) {
    let map = map();
    let ruleset = RulesetDefinition::standard().clone();
    let (base, first, second) =
        turn_support::opened_turn_runtime(map.clone(), ruleset.clone(), unit_count);
    let submit = TurnCommandRequest {
        expected_revision: 0,
    };
    report_with_setup(
        "runtime_turn_submit_partial",
        unit_count,
        || base.clone(),
        |mut runtime| {
            let result = runtime.submit_turn(submit).expect("submit turn");
            (command_signature(&result), 0)
        },
    );

    let timeout = FinalizeTimedOutTurnRequest {
        expected_revision: 1,
        player_ids: vec![first.clone(), second.clone()].into_boxed_slice(),
        skipped_player_ids: vec![second.clone()].into_boxed_slice(),
        next_turn_started_at: None,
    };
    report_with_setup(
        "runtime_turn_timeout_finalization",
        unit_count,
        || {
            let mut runtime = base.clone();
            runtime.submit_turn(submit).expect("prepare partial turn");
            runtime
        },
        |mut runtime| {
            let result = runtime
                .finalize_timed_out_turn(&timeout)
                .expect("finalize timeout");
            (command_signature(&result), 0)
        },
    );

    let kick = KickParticipantRequest {
        expected_revision: 0,
        player_id: second,
        reason: "benchmark_timeout".into(),
        timeout_streak: 3,
    };
    report_with_setup(
        "runtime_turn_kick_participant",
        unit_count,
        || base.clone(),
        |mut runtime| {
            let result = runtime.kick_participant(&kick).expect("kick participant");
            (command_signature(&result), 0)
        },
    );

    let request = client_request(ClientRequestBodyDto::Dispatch {
        command: ClientCommandDto::SubmitTurn {
            expected_revision: 0,
        },
    });
    report_with_setup(
        "client_json_turn_submit_partial",
        unit_count,
        || base.clone(),
        |mut runtime| {
            let response = ClientProtocol::dispatch_json(&mut runtime, &request);
            (signature_bytes(&response), response.len())
        },
    );

    report_with_setup(
        "turn_replay_verify",
        unit_count,
        || {
            let mut runtime = base.clone();
            runtime.submit_turn(submit).expect("prepare replay submit");
            runtime
                .finalize_timed_out_turn(&timeout)
                .expect("prepare replay timeout");
            runtime.export_replay_json().expect("replay JSON")
        },
        |replay| {
            let verified = LocalRuntime::verify_replay_json(map.clone(), ruleset.clone(), &replay)
                .expect("verify replay");
            (
                mix(
                    u64::try_from(verified.entry_count).unwrap_or(u64::MAX),
                    verified.final_event_offset,
                ),
                replay.len(),
            )
        },
    );
}

fn benchmark_runtime(unit_count: usize) {
    let map = map();
    let ruleset = RulesetDefinition::standard().clone();
    let actor = PlayerId::new("player-1").expect("actor");
    let scenario = scenario(&map, &ruleset, unit_count, &actor);
    let open = OpenSession::from_scenario(map.clone(), ruleset.clone(), &scenario, actor.clone())
        .expect("open request");
    report_with_setup(
        "runtime_open",
        unit_count,
        || open.clone(),
        |request| {
            let mut runtime = LocalRuntime::default();
            let stamp = runtime.open(request).expect("open runtime");
            (stamp_signature(&stamp), 0)
        },
    );

    let base = opened(open);
    benchmark_snapshot(&base, unit_count);
    let accepted = MoveUnitRequest {
        expected_revision: 0,
        unit_id: UnitId::new("unit-0").expect("unit id"),
        target: HexCoord::new(1, 0),
    };
    report_with_setup(
        "runtime_dispatch_accepted",
        unit_count,
        || base.clone(),
        |mut runtime| {
            let result = runtime.dispatch(&accepted).expect("dispatch");
            (command_signature(&result), 0)
        },
    );
    let rejected = MoveUnitRequest {
        expected_revision: 1,
        ..accepted.clone()
    };
    report_with_setup(
        "runtime_dispatch_rejected",
        unit_count,
        || base.clone(),
        |mut runtime| {
            let result = runtime.dispatch(&rejected).expect("dispatch");
            (command_signature(&result), 0)
        },
    );

    if unit_count == 1 {
        let hidden_base = opened(hidden_open(map.clone(), ruleset.clone(), actor));
        report_with_setup(
            "runtime_dispatch_hidden_noop",
            2,
            || hidden_base.clone(),
            |mut runtime| {
                let result = runtime.dispatch(&accepted).expect("dispatch");
                (command_signature(&result), 0)
            },
        );
    }

    let accepted_json = client_request(ClientRequestBodyDto::Dispatch {
        command: ClientCommandDto::MoveUnit {
            expected_revision: 0,
            unit_id: "unit-0".to_owned(),
            target: CoordinateDto { col: 1, row: 0 },
        },
    });
    report_with_setup(
        "client_json_dispatch_accepted",
        unit_count,
        || base.clone(),
        |mut runtime| {
            let response = ClientProtocol::dispatch_json(&mut runtime, &accepted_json);
            (signature_bytes(&response), response.len())
        },
    );
    let open_json = client_request(ClientRequestBodyDto::OpenSession {
        map_document: MapDocument::try_new(map, 1.0)
            .expect("map document")
            .to_versioned_json()
            .expect("map JSON"),
        scenario_document: scenario_json(unit_count),
        actor_player_id: "player-1".to_owned(),
    });
    report_with_setup(
        "client_json_open",
        unit_count,
        LocalRuntime::default,
        |mut runtime| {
            let response = ClientProtocol::dispatch_json(&mut runtime, &open_json);
            (signature_bytes(&response), response.len())
        },
    );
}

fn benchmark_snapshot(base: &LocalRuntime, unit_count: usize) {
    report_with_setup(
        "runtime_snapshot",
        unit_count,
        || base.clone(),
        |runtime| {
            let snapshot = runtime.snapshot().expect("snapshot");
            (
                mix(
                    stamp_signature(snapshot.stamp()),
                    u64::try_from(snapshot.units().len()).unwrap_or(u64::MAX),
                ),
                0,
            )
        },
    );
}

fn report_with_setup<T>(
    workload: &str,
    units: usize,
    mut setup: impl FnMut() -> T,
    mut operation: impl FnMut(T) -> (u64, usize),
) {
    for _ in 0..3 {
        black_box(operation(setup()));
    }
    let mut samples = Vec::with_capacity(ITERATIONS);
    let mut signature = 0;
    let mut payload_bytes = 0;
    let mut allocation_stats: Option<Stats> = None;
    for _ in 0..ITERATIONS {
        let input = setup();
        let region = Region::new(GLOBAL);
        let started = Instant::now();
        let output = black_box(operation(input));
        samples.push(started.elapsed().as_nanos());
        let observed = region.change();
        if let Some(expected) = allocation_stats {
            assert_eq!(
                observed, expected,
                "allocation sample drifted for {workload}"
            );
        } else {
            allocation_stats = Some(observed);
        }
        signature = output.0;
        payload_bytes = output.1;
    }
    let allocations = allocation_stats.expect("at least one allocation sample");
    samples.sort_unstable();
    let median = samples[samples.len() / 2];
    let p95 = samples[(samples.len() * 95 / 100).min(samples.len() - 1)];
    println!(
        "{workload},{},{units},{ITERATIONS},{},{},{},{payload_bytes},{signature:016x},{median},{p95}",
        usize::from(COLS) * usize::from(ROWS),
        allocations.allocations,
        allocations.reallocations,
        allocations.bytes_allocated,
    );
}

fn map() -> MapDefinition {
    let tiles = (0..ROWS)
        .flat_map(|row| {
            (0..COLS).map(move |col| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(i32::from(col), i32::from(row)),
                    vec![TerrainType::Grassland],
                    Vec::new(),
                    0,
                )
                .expect("tile")
            })
        })
        .collect();
    MapDefinition::try_new(
        "runtime_benchmark",
        GridLayout::OddQFlatTop,
        COLS,
        ROWS,
        tiles,
        Vec::new(),
    )
    .expect("map")
}

fn scenario(
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    unit_count: usize,
    actor: &PlayerId,
) -> ScenarioDefinition {
    ScenarioDefinition::try_new(
        "runtime_benchmark",
        map,
        ruleset,
        scenario_units(unit_count, actor),
    )
    .expect("scenario")
}

fn scenario_units(unit_count: usize, actor: &PlayerId) -> Vec<ScenarioUnitDefinition> {
    let positions =
        core::iter::once(HexCoord::new(0, 0)).chain((1..ROWS).flat_map(|row| {
            (0..COLS).map(move |col| HexCoord::new(i32::from(col), i32::from(row)))
        }));
    positions
        .take(unit_count)
        .enumerate()
        .map(|(index, position)| {
            ScenarioUnitDefinition::new(
                UnitId::new(format!("unit-{index}")).expect("unit id"),
                actor.clone(),
                UnitKind::Commander,
                "Commander",
                position,
            )
        })
        .collect()
}

fn scenario_json(unit_count: usize) -> String {
    let actor = PlayerId::new("player-1").expect("actor");
    let units = scenario_units(unit_count, &actor)
        .into_iter()
        .map(|unit| {
            json!({
                "id": unit.id().as_str(),
                "ownerPlayerId": unit.owner_player_id().as_str(),
                "kind": "commander",
                "name": unit.name(),
                "col": unit.position().col(),
                "row": unit.position().row(),
            })
        })
        .collect::<Vec<_>>();
    json!({
        "schemaVersion": 1,
        "scenarioId": "runtime_benchmark",
        "mapId": "runtime_benchmark",
        "rulesetId": "aonw-standard",
        "initialUnits": units,
    })
    .to_string()
}

fn hidden_open(map: MapDefinition, ruleset: RulesetDefinition, actor: PlayerId) -> OpenSession {
    let definition = ruleset
        .unit(UnitKind::Commander)
        .expect("commander definition");
    let unit = |id: &str, owner: PlayerId, position: HexCoord| {
        Unit::builder(
            UnitId::new(id).expect("unit id"),
            owner,
            UnitKind::Commander,
            "Commander",
            position,
            definition.maximum_movement(false),
        )
        .build()
        .expect("unit")
    };
    let fog = FogOfWar::try_new([PlayerFog::new(actor.clone(), [], [])]).expect("fog");
    let state = GameState::builder(
        StateRevision::INITIAL,
        0,
        map.bounds(),
        ruleset.occupancy_policy(),
        [
            unit("unit-0", actor.clone(), HexCoord::new(0, 0)),
            unit(
                "hidden-blocker",
                PlayerId::new("player-2").expect("owner"),
                HexCoord::new(1, 0),
            ),
        ],
    )
    .with_fog_of_war(fog)
    .try_build()
    .expect("state");
    OpenSession::from_state(map, ruleset, state, actor)
}

fn opened(request: OpenSession) -> LocalRuntime {
    let mut runtime = LocalRuntime::default();
    runtime.open(request).expect("open runtime");
    runtime
}

fn client_request(body: ClientRequestBodyDto) -> String {
    ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request: body,
    }
    .to_json()
    .expect("client request")
}

fn command_signature(result: &aonw_local_runtime::CommandResult) -> u64 {
    let accepted = u64::from(result.is_accepted());
    mix(
        mix(result.stamp.revision.get(), accepted),
        u64::from(result.stamp.state_digest.as_bytes()[0]),
    )
}

fn stamp_signature(stamp: &aonw_local_runtime::SessionStamp) -> u64 {
    mix(
        stamp.revision.get(),
        u64::from(stamp.state_digest.as_bytes()[0]),
    )
}

fn signature_bytes(value: &str) -> u64 {
    value.bytes().fold(0xcbf2_9ce4_8422_2325, |digest, byte| {
        mix(digest, u64::from(byte))
    })
}

const fn mix(digest: u64, value: u64) -> u64 {
    (digest ^ value).wrapping_mul(0x0000_0100_0000_01b3)
}
