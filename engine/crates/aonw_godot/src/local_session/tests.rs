use aonw_contracts::CoordinateDto;
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientCommandDto, ClientOutcomeDto, ClientRequestBodyDto, ClientRequestDto,
    ClientResponseBodyDto, ClientResponseDto,
};
use aonw_local_runtime::LocalRuntime;
use serde_json::json;
use std::sync::Arc;
use std::sync::atomic::AtomicBool;
use std::sync::mpsc;
use std::thread;
use std::time::Duration;

use super::{
    MAX_OUTSTANDING_JOBS, SessionWorker, WorkerRequest, adapter_build_identity, dispatch_json,
    receive_next_request,
};

#[test]
fn native_adapter_exposes_its_build_identity() {
    let expected = option_env!("AONW_GODOT_BUILD_IDENTITY").unwrap_or("aonw_godot/development");
    assert_eq!(adapter_build_identity(), expected);
    assert!(!adapter_build_identity().trim().is_empty());
}

fn map_json(cols: u16, rows: u16, map_id: &str) -> String {
    let tiles = (0..rows)
        .flat_map(|row| {
            (0..cols).map(move |col| {
                json!({
                    "col": col,
                    "row": row,
                    "terrainTags": ["grassland"],
                    "resources": [],
                    "height": 0,
                })
            })
        })
        .collect::<Vec<_>>();
    json!({
        "schemaVersion": 1,
        "gridLayout": "oddQFlatTop",
        "cols": cols,
        "rows": rows,
        "mapName": map_id,
        "defaultZoom": 1.0,
        "objectives": [],
        "tiles": tiles,
    })
    .to_string()
}

fn scenario_json(unit_count: usize, scenario_id: &str, map_id: &str) -> String {
    let units = (0..unit_count)
        .map(|index| {
            json!({
                "id": format!("unit-{index}"),
                "ownerPlayerId": "player-1",
                "kind": "commander",
                "name": "Commander",
                "col": index % 40,
                "row": index / 40,
            })
        })
        .collect::<Vec<_>>();
    json!({
        "schemaVersion": 1,
        "scenarioId": scenario_id,
        "mapId": map_id,
        "rulesetId": "aonw-standard",
        "initialUnits": units,
    })
    .to_string()
}

fn request(body: ClientRequestBodyDto) -> String {
    ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request: body,
    }
    .to_json()
    .expect("client request")
}

fn response(runtime: &mut LocalRuntime, body: ClientRequestBodyDto) -> ClientResponseBodyDto {
    let response = ClientResponseDto::from_json(&dispatch_json(runtime, &request(body)))
        .expect("client response");
    let ClientOutcomeDto::Success { response } = response.outcome else {
        panic!("successful client response")
    };
    *response
}

#[test]
fn native_adapter_uses_the_shared_client_protocol_end_to_end() {
    let map = map_json(5, 5, "session-test");
    let scenario = scenario_json(1, "session-test", "session-test");
    let mut runtime = LocalRuntime::default();

    let inspected = response(
        &mut runtime,
        ClientRequestBodyDto::InspectMap {
            map_document: map.clone(),
        },
    );
    let ClientResponseBodyDto::MapInspected { map: map_view } = inspected else {
        panic!("map inspection response")
    };
    assert_eq!(map_view.map_id, "session-test");
    assert_eq!(map_view.tiles.len(), 25);
    assert_eq!(
        map_view.tiles[0].coordinate,
        CoordinateDto { col: 0, row: 0 }
    );
    assert_eq!(
        map_view.tiles[24].coordinate,
        CoordinateDto { col: 4, row: 4 }
    );
    assert_eq!(map_view.tiles[0].movement_terrains.len(), 1);
    assert_eq!(map_view.content_hash.len(), 64);

    assert!(matches!(
        response(
            &mut runtime,
            ClientRequestBodyDto::OpenSession {
                map_document: map,
                scenario_document: scenario,
                actor_player_id: "player-1".to_owned(),
            }
        ),
        ClientResponseBodyDto::SessionOpened { .. }
    ));
    assert!(matches!(
        response(&mut runtime, ClientRequestBodyDto::Snapshot),
        ClientResponseBodyDto::Snapshot { .. }
    ));
    assert!(matches!(
        response(
            &mut runtime,
            ClientRequestBodyDto::Dispatch {
                command: ClientCommandDto::MoveUnit {
                    expected_revision: 0,
                    unit_id: "unit-0".to_owned(),
                    target: CoordinateDto { col: 1, row: 0 },
                },
            }
        ),
        ClientResponseBodyDto::Command { .. }
    ));
}

#[test]
fn native_adapter_rejects_non_protocol_and_foreign_version_documents() {
    let mut runtime = LocalRuntime::default();
    for (input, expected_code) in [
        ("{}".to_owned(), "invalid_client_request"),
        (
            json!({"apiVersion": CLIENT_API_VERSION + 1, "request": {"type": "capabilities"}})
                .to_string(),
            "unsupported_client_api_version",
        ),
    ] {
        let response = ClientResponseDto::from_json(&dispatch_json(&mut runtime, &input))
            .expect("failure response");
        let ClientOutcomeDto::Failure { error } = response.outcome else {
            panic!("failure response")
        };
        assert_eq!(error.code, expected_code);
    }
}

#[test]
fn native_worker_prioritizes_queued_interactive_requests() {
    let (background_sender, background_receiver) = mpsc::sync_channel(2);
    let (interactive_sender, interactive_receiver) = mpsc::sync_channel(2);
    background_sender
        .try_send(WorkerRequest {
            job_id: 1,
            input: "background".to_owned(),
            cancelled: Arc::new(AtomicBool::new(false)),
        })
        .expect("queued background request");
    interactive_sender
        .try_send(WorkerRequest {
            job_id: 2,
            input: "interactive".to_owned(),
            cancelled: Arc::new(AtomicBool::new(false)),
        })
        .expect("queued interactive request");
    let shutdown = AtomicBool::new(false);

    let first = receive_next_request(&interactive_receiver, &background_receiver, &shutdown)
        .expect("interactive request");
    let second = receive_next_request(&interactive_receiver, &background_receiver, &shutdown)
        .expect("background request");

    assert_eq!(first.job_id, 2);
    assert_eq!(second.job_id, 1);
}

#[test]
fn native_worker_bounds_and_discards_cancelled_jobs() {
    let mut worker = SessionWorker::new();
    let input = request(ClientRequestBodyDto::Capabilities);
    let job_ids = (0..MAX_OUTSTANDING_JOBS)
        .map(|_| worker.enqueue(input.clone()).expect("bounded worker job"))
        .collect::<Vec<_>>();
    assert!(worker.enqueue(input.clone()).is_none());

    for job_id in job_ids {
        assert!(worker.cancel(job_id));
    }

    let replacement_job = (0..250)
        .find_map(|_| {
            let job_id = worker.enqueue(input.clone());
            if job_id.is_none() {
                thread::sleep(Duration::from_millis(1));
            }
            job_id
        })
        .expect("cancelled jobs release bounded worker capacity");
    assert!(worker.cancel(replacement_job));

    for _ in 0..250 {
        worker.drain();
        if worker.outstanding.is_empty() {
            break;
        }
        thread::sleep(Duration::from_millis(1));
    }

    assert!(worker.outstanding.is_empty());
    assert!(worker.pending.is_empty());
    assert!(worker.cancellation_tokens.is_empty());
}
