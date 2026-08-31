//! Persistence corruption, rollover, and checkpoint-chain tests.

use std::fs;
use std::path::PathBuf;
use std::sync::atomic::{AtomicU64, Ordering};

use aonw_content::{
    GridLayout, MapDefinition, RulesetDefinition, ScenarioDefinition, ScenarioUnitDefinition,
    TerrainType, TileDefinition,
};
use aonw_contracts::{
    MAX_REPLAY_ENTRY_COUNT, MAX_REPLAY_SEGMENT_COUNT, MAX_SAVE_GAME_JSON_BYTES, ReplayLogDto,
    SaveGameDto,
};
use aonw_domain::{HexCoord, PlayerId, UnitId, UnitKind};
use aonw_local_runtime::{
    LocalRuntime, MoveUnitRequest, OpenSession, PersistenceError, PersistenceFileStore,
    PersistenceRestoreSource, ReplayVerification,
};

static TEST_DIRECTORY_SEQUENCE: AtomicU64 = AtomicU64::new(0);

#[test]
fn persistence_manifest_is_strict_and_bounded() {
    let manifest: serde_json::Value =
        serde_json::from_str(include_str!("../../../fixtures/persistence/manifest.json"))
            .expect("persistence manifest");
    assert_eq!(manifest["capability"], "save-and-replay-hardened");
    assert_eq!(manifest["limits"]["replayEntriesPerSegment"], 512);
    assert_eq!(manifest["limits"]["replaySegments"], 8);
    let cases = manifest["cases"].as_array().expect("case list");
    assert_eq!(cases.len(), 15);
    assert!(
        cases
            .windows(2)
            .all(|pair| pair[0].as_str() < pair[1].as_str())
    );
}

#[test]
fn corrupt_save_corpus_never_replaces_the_open_session() {
    let mut runtime = LocalRuntime::default();
    let expected = runtime.open(request()).expect("open");
    let save_json = runtime.export_save_json().expect("save");
    let mut hash_mismatch = SaveGameDto::from_json(&save_json).expect("save DTO");
    hash_mismatch.map_hash = "00".repeat(32);
    let inputs = [
        save_json[..save_json.len() - 1].to_owned(),
        save_json.replacen("\"state\":", "\"unknown\":true,\"state\":", 1),
        save_json.replacen("\"mapId\":", "\"mapId\":\"duplicate\",\"mapId\":", 1),
        hash_mismatch.to_json().expect("hash mismatch JSON"),
        "x".repeat(MAX_SAVE_GAME_JSON_BYTES + 1),
    ];

    for input in inputs {
        let (map, ruleset) = content();
        assert!(runtime.open_save_json(map, ruleset, &input).is_err());
        assert_eq!(runtime.snapshot().expect("preserved").stamp(), &expected);
    }
}

#[test]
fn save_and_replay_reject_every_content_identity_mismatch() {
    let mut runtime = LocalRuntime::default();
    let expected = runtime.open(request()).expect("open");
    let save =
        SaveGameDto::from_json(&runtime.export_save_json().expect("save")).expect("save DTO");
    let replay = ReplayLogDto::from_json(&runtime.export_replay_json().expect("replay"))
        .expect("replay DTO");

    let mut wrong_map_id = save.clone();
    wrong_map_id.map_id = "other-map".to_owned();
    assert_save_error(&mut runtime, &wrong_map_id, |error| {
        matches!(error, PersistenceError::MapIdMismatch)
    });
    let mut wrong_map_hash = save.clone();
    wrong_map_hash.map_hash = "00".repeat(32);
    assert_save_error(&mut runtime, &wrong_map_hash, |error| {
        matches!(error, PersistenceError::MapHashMismatch)
    });
    let mut wrong_ruleset_id = save.clone();
    wrong_ruleset_id.ruleset_id = "other-ruleset".to_owned();
    assert_save_error(&mut runtime, &wrong_ruleset_id, |error| {
        matches!(error, PersistenceError::RulesetIdMismatch)
    });
    let mut wrong_ruleset_hash = save;
    wrong_ruleset_hash.ruleset_hash = "00".repeat(32);
    assert_save_error(&mut runtime, &wrong_ruleset_hash, |error| {
        matches!(error, PersistenceError::RulesetHashMismatch)
    });
    assert_eq!(
        runtime.snapshot().expect("preserved session").stamp(),
        &expected
    );

    let mut wrong_map_id = replay.clone();
    wrong_map_id.map_id = "other-map".to_owned();
    assert_replay_error(&wrong_map_id, |error| {
        matches!(error, PersistenceError::MapIdMismatch)
    });
    let mut wrong_map_hash = replay.clone();
    wrong_map_hash.map_hash = "00".repeat(32);
    assert_replay_error(&wrong_map_hash, |error| {
        matches!(error, PersistenceError::MapHashMismatch)
    });
    let mut wrong_ruleset_id = replay.clone();
    wrong_ruleset_id.ruleset_id = "other-ruleset".to_owned();
    assert_replay_error(&wrong_ruleset_id, |error| {
        matches!(error, PersistenceError::RulesetIdMismatch)
    });
    let mut wrong_ruleset_hash = replay;
    wrong_ruleset_hash.ruleset_hash = "00".repeat(32);
    assert_replay_error(&wrong_ruleset_hash, |error| {
        matches!(error, PersistenceError::RulesetHashMismatch)
    });
}

#[test]
fn replay_rollover_restores_each_checkpoint_and_reports_exact_drift() {
    let mut runtime = LocalRuntime::default();
    let expected = runtime.open(request()).expect("open");
    for _ in 0..=MAX_REPLAY_ENTRY_COUNT {
        let result = runtime
            .dispatch(&MoveUnitRequest {
                expected_revision: 1,
                unit_id: UnitId::new("unit-1").expect("unit id"),
                target: HexCoord::new(1, 0),
            })
            .expect("typed rejection");
        assert!(!result.is_accepted());
    }

    let replay_json = runtime.export_replay_json().expect("replay");
    let replay = ReplayLogDto::from_json(&replay_json).expect("strict replay");
    assert_eq!(replay.segments.len(), 2);
    assert_eq!(replay.segments[0].entries.len(), MAX_REPLAY_ENTRY_COUNT);
    assert_eq!(replay.segments[1].entries.len(), 1);
    assert_eq!(replay.segments[1].entries[0].index, 0);

    let (map, ruleset) = content();
    assert_eq!(
        LocalRuntime::verify_replay_json(map, ruleset, &replay_json).expect("verify archive"),
        ReplayVerification {
            entry_count: MAX_REPLAY_ENTRY_COUNT + 1,
            final_stamp: expected,
            final_event_offset: 0,
        }
    );

    let mut broken_chain = replay.clone();
    broken_chain.segments[1].initial_event_offset = 1;
    let (map, ruleset) = content();
    assert!(matches!(
        LocalRuntime::verify_replay_json(
            map,
            ruleset,
            &broken_chain.to_json().expect("broken chain")
        ),
        Err(PersistenceError::ReplayCheckpointMismatch { segment: 1 })
    ));

    let mut broken_digest = replay;
    broken_digest.segments[1].initial_state_digest = "00".repeat(32);
    let (map, ruleset) = content();
    assert!(matches!(
        LocalRuntime::verify_replay_json(
            map,
            ruleset,
            &broken_digest.to_json().expect("broken digest")
        ),
        Err(PersistenceError::ReplayCheckpointDigestMismatch { segment: 1 })
    ));
}

#[test]
fn replay_archive_codec_enforces_segment_and_entry_bounds() {
    let mut runtime = LocalRuntime::default();
    runtime.open(request()).expect("open");
    let mut replay = ReplayLogDto::from_json(&runtime.export_replay_json().expect("replay"))
        .expect("replay DTO");
    replay.segments = vec![replay.segments[0].clone(); MAX_REPLAY_SEGMENT_COUNT + 1];
    assert!(replay.to_json().is_err());

    replay.segments.truncate(1);
    let entry = rejected_entry();
    replay.segments[0].entries = vec![entry; MAX_REPLAY_ENTRY_COUNT + 1];
    assert!(replay.to_json().is_err());
}

#[test]
fn atomic_host_save_preserves_backup_and_repairs_a_corrupt_primary() {
    let scratch = ScratchDirectory::new();
    let store = PersistenceFileStore::new(scratch.path().join("session.aonw-save"));
    let mut runtime = LocalRuntime::default();
    let initial_stamp = runtime.open(request()).expect("open");

    store.write_save(&runtime).expect("initial write");
    let initial_document = fs::read_to_string(store.primary_path()).expect("initial document");
    let moved = runtime
        .dispatch(&MoveUnitRequest {
            expected_revision: 0,
            unit_id: UnitId::new("unit-1").expect("unit id"),
            target: HexCoord::new(1, 0),
        })
        .expect("move");
    assert!(moved.is_accepted());
    store.write_save(&runtime).expect("replacement write");
    assert_eq!(
        fs::read_to_string(store.backup_path()).expect("backup"),
        initial_document
    );

    let (map, ruleset) = content();
    let mut primary_restore = LocalRuntime::default();
    let (stamp, source) = store
        .restore_save(&mut primary_restore, map, ruleset)
        .expect("primary restore");
    assert_eq!(source, PersistenceRestoreSource::Primary);
    assert_eq!(stamp, moved.stamp);

    fs::write(store.primary_path(), "{\"truncated\":")
        .expect("inject corrupt primary for recovery drill");
    let (map, ruleset) = content();
    let mut backup_restore = LocalRuntime::default();
    let (stamp, source) = store
        .restore_save(&mut backup_restore, map, ruleset)
        .expect("backup restore");
    assert_eq!(source, PersistenceRestoreSource::Backup);
    assert_eq!(stamp, initial_stamp);
    assert_eq!(
        fs::read_to_string(store.primary_path()).expect("repaired primary"),
        initial_document
    );

    fs::remove_file(store.primary_path()).expect("remove primary for missing-primary drill");
    let (map, ruleset) = content();
    let mut missing_primary_restore = LocalRuntime::default();
    let (stamp, source) = store
        .restore_save(&mut missing_primary_restore, map, ruleset)
        .expect("missing primary falls back to backup");
    assert_eq!(source, PersistenceRestoreSource::Backup);
    assert_eq!(stamp, initial_stamp);
    assert_eq!(
        fs::read_to_string(store.primary_path()).expect("recreated primary"),
        initial_document
    );

    let preserved = backup_restore.snapshot().expect("preserved snapshot");
    fs::write(store.primary_path(), "invalid").expect("corrupt primary");
    fs::write(store.backup_path(), "invalid").expect("corrupt backup");
    let (map, ruleset) = content();
    assert!(
        store
            .restore_save(&mut backup_restore, map, ruleset)
            .is_err()
    );
    assert_eq!(
        backup_restore.snapshot().expect("transactional restore"),
        preserved
    );
}

fn rejected_entry() -> aonw_contracts::ReplayEntryDto {
    let mut runtime = LocalRuntime::default();
    runtime.open(request()).expect("open");
    runtime
        .dispatch(&MoveUnitRequest {
            expected_revision: 1,
            unit_id: UnitId::new("unit-1").expect("unit id"),
            target: HexCoord::new(1, 0),
        })
        .expect("typed rejection");
    ReplayLogDto::from_json(&runtime.export_replay_json().expect("replay"))
        .expect("replay DTO")
        .segments
        .remove(0)
        .entries
        .remove(0)
}

fn assert_save_error(
    runtime: &mut LocalRuntime,
    save: &SaveGameDto,
    expected: impl FnOnce(&PersistenceError) -> bool,
) {
    let (map, ruleset) = content();
    let error = runtime
        .open_save_json(map, ruleset, &save.to_json().expect("save JSON"))
        .expect_err("identity mismatch");
    assert!(expected(&error), "unexpected save error: {error}");
}

fn assert_replay_error(replay: &ReplayLogDto, expected: impl FnOnce(&PersistenceError) -> bool) {
    let (map, ruleset) = content();
    let error =
        LocalRuntime::verify_replay_json(map, ruleset, &replay.to_json().expect("replay JSON"))
            .expect_err("identity mismatch");
    assert!(expected(&error), "unexpected replay error: {error}");
}

fn request() -> OpenSession {
    let (map, ruleset) = content();
    let scenario = ScenarioDefinition::try_new(
        "persistence-hardening",
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
    let map = MapDefinition::try_new(
        "runtime-map",
        GridLayout::OddQFlatTop,
        3,
        3,
        tiles,
        Vec::new(),
    )
    .expect("map");
    (map, RulesetDefinition::standard().clone())
}

struct ScratchDirectory(PathBuf);

impl ScratchDirectory {
    fn new() -> Self {
        let path = std::env::temp_dir().join(format!(
            "aonw-persistence-{}-{}",
            std::process::id(),
            TEST_DIRECTORY_SEQUENCE.fetch_add(1, Ordering::Relaxed)
        ));
        fs::create_dir(&path).expect("create scratch directory");
        Self(path)
    }

    fn path(&self) -> &std::path::Path {
        &self.0
    }
}

impl Drop for ScratchDirectory {
    fn drop(&mut self) {
        fs::remove_dir_all(&self.0).expect("remove scratch directory");
    }
}
