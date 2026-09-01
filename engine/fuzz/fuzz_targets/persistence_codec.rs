#![no_main]

use aonw_contracts::client::ClientRequestDto;
use aonw_contracts::{ReplayLogDto, SaveGameDto};
use libfuzzer_sys::fuzz_target;

const BASELINE: &str = include_str!("../../fixtures/canonical_commands/fortify-unit-accepted.json");

fuzz_target!(|data: &[u8]| {
    let fixture: serde_json::Value = serde_json::from_str(BASELINE).expect("baseline fixture");
    let state = fixture.pointer("/input/state").expect("baseline state");
    let save = serde_json::json!({
        "mapId": "fuzz-map",
        "mapHash": "fuzz-map-hash",
        "rulesetId": "standard",
        "rulesetHash": "fuzz-ruleset-hash",
        "actorPlayerId": "player-1",
        "eventOffset": 0,
        "stateDigest": "fuzz-state-digest",
        "state": state,
    })
    .to_string();
    let decoded_save = SaveGameDto::from_json(&save).expect("baseline save round-trip");
    let encoded_save = decoded_save.to_json().expect("save encode");
    assert_eq!(
        SaveGameDto::from_json(&encoded_save)
            .expect("encoded save decode")
            .to_json()
            .expect("stable save encode"),
        encoded_save
    );

    let replay = serde_json::json!({
        "mapId": "fuzz-map",
        "mapHash": "fuzz-map-hash",
        "rulesetId": "standard",
        "rulesetHash": "fuzz-ruleset-hash",
        "actorPlayerId": "player-1",
        "segments": [{
            "initialEventOffset": 0,
            "initialStateDigest": "fuzz-state-digest",
            "initialState": state,
            "entries": [],
        }],
    })
    .to_string();
    let decoded_replay = ReplayLogDto::from_json(&replay).expect("replay round-trip");
    let encoded_replay = decoded_replay.to_json().expect("replay encode");
    assert_eq!(
        ReplayLogDto::from_json(&encoded_replay)
            .expect("encoded replay decode")
            .to_json()
            .expect("stable replay encode"),
        encoded_replay
    );

    let input = if data.is_empty() {
        br#"{"apiVersion":13,"request":{"type":"capabilities"}}"#.as_slice()
    } else {
        data
    };
    let Ok(input) = core::str::from_utf8(input) else {
        return;
    };
    let _ = SaveGameDto::from_json(input);
    let _ = ReplayLogDto::from_json(input);
    let _ = ClientRequestDto::from_json(input);
});
