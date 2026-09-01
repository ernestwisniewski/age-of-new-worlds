//! Local runtime lifecycle and movement contract tests.

use aonw_content::{
    GridLayout, MapDefinition, RulesetDefinition, ScenarioDefinition, ScenarioUnitDefinition,
    TerrainType, TileDefinition,
};
use aonw_contract_mapping::decode_game_state;
use aonw_contracts::{ReplayLogDto, SaveGameDto};
use aonw_domain::{
    HexCoord, PlayerCountry, PlayerId, PlayerKind, StateRevision, TurnMode, UnitId, UnitKind,
};
use aonw_local_runtime::{
    LocalRuntime, MoveUnitRequest, OpenSession, OpenSessionError, PendingActionView,
    PersistenceError, ReachableRequest, ReplayVerification, RoutePlanRequest, RuntimeError,
    RuntimeQuery, RuntimeQueryResult, UnitActionRequest,
};
use sha2::{Digest, Sha256};

fn map(id: &str, cols: u16, rows: u16) -> MapDefinition {
    let tiles = (0..rows)
        .flat_map(|row| {
            (0..cols).map(move |col| {
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
    MapDefinition::try_new(id, GridLayout::OddQFlatTop, cols, rows, tiles, Vec::new()).expect("map")
}

fn request() -> OpenSession {
    let (map, ruleset) = content();
    let scenario = ScenarioDefinition::try_new(
        "runtime-scenario",
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
    .expect("open request")
}

fn content() -> (MapDefinition, RulesetDefinition) {
    (
        map("runtime-map", 3, 3),
        RulesetDefinition::standard().clone(),
    )
}

#[test]
fn local_session_supports_snapshot_queries_and_dispatch() {
    let mut runtime = LocalRuntime::default();
    let opened = runtime.open(request()).expect("open");
    assert_eq!(opened.revision, StateRevision::INITIAL);

    let snapshot = runtime.snapshot().expect("snapshot");
    assert_eq!(snapshot.turn(), 1);
    assert_eq!(snapshot.turn_mode(), TurnMode::Sequential);
    assert_eq!(snapshot.participants().len(), 1);
    assert_eq!(snapshot.participants()[0].id().as_str(), "player-1");
    assert_eq!(snapshot.participants()[0].name(), "player-1");
    assert_eq!(snapshot.participants()[0].color_value(), 0xff_42_85_f4);
    assert_eq!(snapshot.participants()[0].country(), PlayerCountry::Poland);
    assert_eq!(snapshot.participants()[0].kind(), PlayerKind::Human);
    assert!(!snapshot.fog().enabled());
    assert!(snapshot.fog().discovered_hexes().is_empty());
    assert!(snapshot.fog().visible_hexes().is_empty());
    assert_eq!(snapshot.pending_action(), None);
    assert_eq!(snapshot.units().len(), 1);
    assert_eq!(snapshot.units()[0].id().as_str(), "unit-1");

    let reachable = runtime
        .query(&RuntimeQuery::Reachable(ReachableRequest {
            expected_revision: 0,
            unit_id: UnitId::new("unit-1").expect("unit id"),
        }))
        .expect("reachable");
    let RuntimeQueryResult::Reachable(reachable) = reachable else {
        panic!("reachable response")
    };
    assert!(!reachable.tiles.is_empty());

    let route = runtime
        .query(&RuntimeQuery::RoutePlan(RoutePlanRequest {
            expected_revision: 0,
            unit_id: UnitId::new("unit-1").expect("unit id"),
            target: HexCoord::new(1, 0),
        }))
        .expect("route");
    let RuntimeQueryResult::RoutePlan(route) = route else {
        panic!("route response")
    };
    assert_eq!(route.destination, HexCoord::new(1, 0));

    let moved = runtime
        .dispatch(&MoveUnitRequest {
            expected_revision: 0,
            unit_id: UnitId::new("unit-1").expect("unit id"),
            target: HexCoord::new(1, 0),
        })
        .expect("dispatch");
    assert!(moved.is_accepted());
    assert_eq!(moved.stamp.revision, StateRevision::new(1));
    assert_eq!(moved.events.len(), 1);
    assert!(moved.evidence.is_some());
    assert_eq!(moved.view_patch.from_revision, 0);
    assert_eq!(moved.view_patch.to_revision, 1);
    assert_eq!(moved.view_patch.turn_mode, TurnMode::Sequential);
    assert_eq!(moved.view_patch.upserted_units[0].col(), 1);
}

#[test]
fn unit_actions_update_canonical_state_and_are_replayable() {
    let mut runtime = LocalRuntime::default();
    runtime.open(request()).expect("open");
    let unit_id = UnitId::new("unit-1").expect("unit id");

    let skipped = runtime
        .skip_unit_turn(&UnitActionRequest {
            expected_revision: 0,
            unit_id: unit_id.clone(),
        })
        .expect("skip");
    assert!(skipped.is_accepted());
    assert_eq!(skipped.view_patch.upserted_units[0].movement_units(), 0);
    assert!(matches!(
        skipped.view_patch.pending_action,
        Some(PendingActionView::UnitTurnSkip { ref unit_id, .. }) if unit_id.as_str() == "unit-1"
    ));

    let cancelled = runtime
        .cancel_unit_action(&UnitActionRequest {
            expected_revision: 1,
            unit_id: unit_id.clone(),
        })
        .expect("cancel");
    assert!(cancelled.is_accepted());
    assert!(cancelled.view_patch.upserted_units[0].movement_units() > 0);
    assert_eq!(cancelled.view_patch.pending_action, None);

    let fortified = runtime
        .fortify_unit(&UnitActionRequest {
            expected_revision: 2,
            unit_id,
        })
        .expect("fortify");
    assert!(fortified.is_accepted());
    assert_eq!(
        fortified.view_patch.upserted_units[0].posture(),
        aonw_domain::UnitPosture::Fortified
    );

    let replay = runtime.export_replay_json().expect("replay");
    let (map, ruleset) = content();
    let verification = LocalRuntime::verify_replay_json(map, ruleset, &replay).expect("verify");
    assert_eq!(verification.entry_count, 3);
    assert_eq!(verification.final_stamp.revision, StateRevision::new(3));
}

#[test]
fn failed_reopen_preserves_session_and_close_is_idempotent() {
    let mut runtime = LocalRuntime::default();
    let original = runtime.open(request()).expect("open");
    let mut save =
        SaveGameDto::from_json(&runtime.export_save_json().expect("save")).expect("save contract");
    save.state.cols = 2;
    save.state.rows = 2;
    let invalid_state = decode_game_state(save.state).expect("valid mismatched state");
    let invalid = OpenSession::from_state(
        map("other-map", 3, 3),
        RulesetDefinition::standard().clone(),
        invalid_state,
        PlayerId::new("player-1").expect("player id"),
    );
    assert_eq!(
        runtime.open(invalid),
        Err(OpenSessionError::MapBoundsMismatch)
    );
    assert_eq!(runtime.snapshot().expect("preserved").stamp(), &original);

    runtime.close();
    runtime.close();
    assert_eq!(runtime.snapshot(), Err(RuntimeError::SessionNotOpen));
}

#[test]
fn exhausted_event_offset_rejects_dispatch_without_closing_session() {
    let mut runtime = LocalRuntime::default();
    let opened = runtime
        .open(request().with_event_offset(u64::MAX))
        .expect("open");

    let result = runtime.dispatch(&MoveUnitRequest {
        expected_revision: 0,
        unit_id: UnitId::new("unit-1").expect("unit id"),
        target: HexCoord::new(1, 0),
    });

    assert_eq!(result, Err(RuntimeError::EventOffsetOverflow));
    assert_eq!(
        runtime.snapshot().expect("session remains open").stamp(),
        &opened
    );
}

#[test]
fn zero_event_command_succeeds_at_exhausted_event_offset() {
    let mut runtime = LocalRuntime::default();
    runtime
        .open(request().with_event_offset(u64::MAX))
        .expect("open");

    let result = runtime
        .fortify_unit(&UnitActionRequest {
            expected_revision: 0,
            unit_id: UnitId::new("unit-1").expect("unit id"),
        })
        .expect("zero-event action");

    assert!(result.is_accepted());
    assert!(result.events.is_empty());
    assert_eq!(result.stamp.revision, StateRevision::new(1));
    let save: SaveGameDto = serde_json::from_str(
        &runtime
            .export_save_json()
            .expect("save at exhausted offset"),
    )
    .expect("save dto");
    assert_eq!(save.event_offset, u64::MAX);
}

#[test]
fn revision_overflow_is_rejected_without_advancing_runtime_counters() {
    let (map, ruleset) = content();
    let mut runtime = LocalRuntime::default();
    runtime.open(request()).expect("open initial state");
    let mut save =
        SaveGameDto::from_json(&runtime.export_save_json().expect("save")).expect("save contract");
    save.state.revision = u64::MAX;
    let exhausted = decode_game_state(save.state).expect("exhausted state");
    runtime.close();
    runtime
        .open(
            OpenSession::from_state(
                map,
                ruleset,
                exhausted,
                PlayerId::new("player-1").expect("player id"),
            )
            .with_event_offset(23),
        )
        .expect("open");

    let result = runtime
        .fortify_unit(&UnitActionRequest {
            expected_revision: u64::MAX,
            unit_id: UnitId::new("unit-1").expect("unit id"),
        })
        .expect("typed rejection");

    assert_eq!(
        result
            .rejection
            .map(aonw_engine::CommandRejectionCode::as_str),
        Some("state_revision_overflow")
    );
    assert!(result.events.is_empty());
    assert_eq!(result.stamp.revision, StateRevision::new(u64::MAX));
    let save = SaveGameDto::from_json(&runtime.export_save_json().expect("save")).expect("dto");
    assert_eq!(save.event_offset, 23);
    assert_eq!(save.state.revision, u64::MAX);
}

#[test]
fn save_round_trip_preserves_complete_state_and_runtime_checkpoint() {
    let mut runtime = LocalRuntime::default();
    runtime.open(request().with_event_offset(11)).expect("open");
    runtime
        .dispatch(&MoveUnitRequest {
            expected_revision: 0,
            unit_id: UnitId::new("unit-1").expect("unit id"),
            target: HexCoord::new(1, 0),
        })
        .expect("move");
    let expected = *runtime.snapshot().expect("snapshot").stamp();
    let save_json = runtime.export_save_json().expect("save");
    let save = SaveGameDto::from_json(&save_json).expect("strict save");
    assert_eq!(save.state.units.len(), 1);
    assert_eq!(save.event_offset, 12);

    let (map, ruleset) = content();
    let mut restored = LocalRuntime::default();
    let actual = restored
        .open_save_json(map, ruleset, &save_json)
        .expect("restore");
    assert_eq!(actual, expected);
    assert_eq!(restored.export_save_json().expect("resave"), save_json);
}

#[test]
fn save_load_is_transactional_and_rejects_identity_or_digest_tampering() {
    let mut runtime = LocalRuntime::default();
    let original = runtime.open(request()).expect("open");
    let save_json = runtime.export_save_json().expect("save");

    let mut wrong_map = SaveGameDto::from_json(&save_json).expect("save dto");
    wrong_map.map_hash = "00".repeat(32);
    let (map, ruleset) = content();
    assert!(matches!(
        runtime.open_save_json(map, ruleset, &wrong_map.to_json().expect("json")),
        Err(PersistenceError::MapHashMismatch)
    ));
    assert_eq!(runtime.snapshot().expect("preserved").stamp(), &original);

    let mut wrong_digest = SaveGameDto::from_json(&save_json).expect("save dto");
    wrong_digest.state_digest = "00".repeat(32);
    let (map, ruleset) = content();
    assert!(matches!(
        runtime.open_save_json(map, ruleset, &wrong_digest.to_json().expect("json")),
        Err(PersistenceError::StateDigestMismatch)
    ));
}

#[test]
fn replay_verifies_accepted_and_rejected_commands_and_detects_drift() {
    let mut runtime = LocalRuntime::default();
    runtime.open(request()).expect("open");
    runtime
        .dispatch(&MoveUnitRequest {
            expected_revision: 0,
            unit_id: UnitId::new("unit-1").expect("unit id"),
            target: HexCoord::new(1, 0),
        })
        .expect("accepted move");
    let rejected = runtime
        .dispatch(&MoveUnitRequest {
            expected_revision: 0,
            unit_id: UnitId::new("unit-1").expect("unit id"),
            target: HexCoord::new(2, 0),
        })
        .expect("domain rejection");
    assert!(!rejected.is_accepted());
    let expected_stamp = *runtime.snapshot().expect("snapshot").stamp();
    let replay_json = runtime.export_replay_json().expect("replay");
    let replay = ReplayLogDto::from_json(&replay_json).expect("strict replay");
    assert_eq!(replay.segments.len(), 1);
    assert_eq!(replay.segments[0].entries.len(), 2);
    assert!(replay.segments[0].entries[0].result.accepted);
    assert!(!replay.segments[0].entries[1].result.accepted);

    let (map, ruleset) = content();
    assert_eq!(
        LocalRuntime::verify_replay_json(map, ruleset, &replay_json).expect("verify"),
        ReplayVerification {
            entry_count: 2,
            final_stamp: expected_stamp,
            final_event_offset: 1,
        }
    );

    let mut reordered = replay.clone();
    reordered.segments[0].entries.swap(0, 1);
    let (map, ruleset) = content();
    assert!(matches!(
        LocalRuntime::verify_replay_json(
            map,
            ruleset,
            &reordered.to_json().expect("reordered replay")
        ),
        Err(PersistenceError::ReplayIndexMismatch {
            segment: 0,
            expected: 0,
            found: 1,
        })
    ));

    let mut reordered_commands = replay.clone();
    let first_record = reordered_commands.segments[0].entries[0].record.clone();
    reordered_commands.segments[0].entries[0].record =
        reordered_commands.segments[0].entries[1].record.clone();
    reordered_commands.segments[0].entries[1].record = first_record;
    let (map, ruleset) = content();
    assert!(matches!(
        LocalRuntime::verify_replay_json(
            map,
            ruleset,
            &reordered_commands
                .to_json()
                .expect("command-reordered replay")
        ),
        Err(PersistenceError::ReplayResultMismatch {
            segment: 0,
            entry: 0
        })
    ));

    let mut tampered_event = replay.clone();
    tampered_event.segments[0].entries[0].result.events.clear();
    let (map, ruleset) = content();
    assert!(matches!(
        LocalRuntime::verify_replay_json(
            map,
            ruleset,
            &tampered_event.to_json().expect("event-tampered replay")
        ),
        Err(PersistenceError::ReplayResultMismatch {
            segment: 0,
            entry: 0
        })
    ));

    let mut tampered = replay;
    tampered.segments[0].entries[0].result.state_digest = "00".repeat(32);
    let (map, ruleset) = content();
    assert!(matches!(
        LocalRuntime::verify_replay_json(
            map,
            ruleset,
            &tampered.to_json().expect("tampered replay")
        ),
        Err(PersistenceError::ReplayResultMismatch {
            segment: 0,
            entry: 0
        })
    ));
}

#[test]
fn deterministic_replay_signature_is_stable() {
    let mut runtime = LocalRuntime::default();
    runtime.open(request()).expect("open");
    let unit_id = UnitId::new("unit-1").expect("unit id");
    runtime
        .dispatch(&MoveUnitRequest {
            expected_revision: 0,
            unit_id: unit_id.clone(),
            target: HexCoord::new(1, 0),
        })
        .expect("move");
    runtime
        .dispatch(&MoveUnitRequest {
            expected_revision: 0,
            unit_id: unit_id.clone(),
            target: HexCoord::new(2, 0),
        })
        .expect("typed stale rejection");
    runtime
        .fortify_unit(&UnitActionRequest {
            expected_revision: 1,
            unit_id,
        })
        .expect("fortify");

    let replay_json = runtime.export_replay_json().expect("replay");
    assert!(!replay_json.contains("rngState"));
    assert!(!replay_json.contains("initialRngState"));
    assert_eq!(
        format!("{:x}", Sha256::digest(replay_json.as_bytes())),
        "8c88e302d47c1557d1bbab4730df598900d186ffcedfe1342b0673f8ed2ec087"
    );
}
