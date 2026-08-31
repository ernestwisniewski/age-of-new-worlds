use aonw_content::{MapDocument, RulesetDefinition, ScenarioDefinition, ScenarioUnitDefinition};
use aonw_contracts::client::{ClientCommandDto, ClientRequestBodyDto, ClientResponseBodyDto};
use aonw_domain::{HexCoord, PlayerId, UnitId, UnitKind};

use crate::{LocalRuntime, OpenSession};

use super::{authored_map, scenario_json, success};

#[test]
fn replay_playback_seeks_across_a_full_segment() {
    let map = authored_map();
    let ruleset = RulesetDefinition::standard().clone();
    let map_document = MapDocument::try_new(map.clone(), 1.0)
        .expect("map document")
        .to_versioned_json()
        .expect("map JSON");
    let mut runtime = LocalRuntime::default();
    success(
        &mut runtime,
        ClientRequestBodyDto::OpenSession {
            map_document: map_document.clone(),
            scenario_document: scenario_json(&map, &ruleset),
            actor_player_id: "player-1".to_owned(),
        },
    );
    let entry_count = aonw_contracts::MAX_REPLAY_ENTRY_COUNT + 1;
    for _ in 0..entry_count {
        success(
            &mut runtime,
            ClientRequestBodyDto::Dispatch {
                command: ClientCommandDto::CancelUnitAction {
                    expected_revision: 0,
                    unit_id: "unit-1".to_owned(),
                },
            },
        );
    }
    let ClientResponseBodyDto::ReplayExported { document } =
        success(&mut runtime, ClientRequestBodyDto::ExportReplay)
    else {
        panic!("replay export")
    };
    let ClientResponseBodyDto::ReplayFrame {
        entry_count: opened_count,
        ..
    } = success(
        &mut runtime,
        ClientRequestBodyDto::OpenReplay {
            map_document,
            replay_document: document,
            recipient_player_id: "player-1".to_owned(),
        },
    )
    else {
        panic!("replay open")
    };
    assert_eq!(
        opened_count,
        u64::try_from(entry_count).expect("entry count")
    );
    let boundary =
        u64::try_from(aonw_contracts::MAX_REPLAY_ENTRY_COUNT).expect("segment entry count");
    success(
        &mut runtime,
        ClientRequestBodyDto::SeekReplay { position: boundary },
    );
    let ClientResponseBodyDto::ReplayFrame { position, .. } = success(
        &mut runtime,
        ClientRequestBodyDto::SeekReplay {
            position: opened_count,
        },
    ) else {
        panic!("final replay frame")
    };
    assert_eq!(position, opened_count);
}

#[test]
fn direct_open_helper_builds_a_strict_session() {
    let map = authored_map();
    let ruleset = RulesetDefinition::standard().clone();
    let scenario = ScenarioDefinition::try_new(
        "direct-client-protocol",
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
    let request = OpenSession::from_scenario(
        map,
        ruleset,
        &scenario,
        PlayerId::new("player-1").expect("player id"),
    )
    .expect("open request");
    let mut runtime = LocalRuntime::default();
    runtime.open(request).expect("open");
    let _ = super::snapshot(&runtime.snapshot().expect("snapshot"));
}
