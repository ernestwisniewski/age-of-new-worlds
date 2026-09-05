use aonw_contracts::client::{ClientResponseDto, MAX_CLIENT_OBSERVED_COMMANDS};
use serde_json::{Value, json};

const AI: &str =
    include_str!("../../../../fixtures/client_protocol/observed_ai_turn_response.json");
const REPLAY: &str =
    include_str!("../../../../fixtures/client_protocol/observed_replay_frame_response.json");

#[test]
fn observed_runtime_documents_round_trip_exactly() {
    for source in [AI, REPLAY] {
        assert_eq!(
            ClientResponseDto::from_json(source)
                .expect("runtime document")
                .to_json()
                .expect("encode"),
            source.trim()
        );
    }
}

#[test]
fn observed_ai_rejects_missing_fields_and_incoherent_command_frames() {
    for field in ["recipientPlayerId", "commands"] {
        let mut value = document(AI);
        value["outcome"]["response"]
            .as_object_mut()
            .expect("response")
            .remove(field);
        assert!(
            ClientResponseDto::from_json(&value.to_string()).is_err(),
            "{field}"
        );
    }
    for (path, replacement) in [
        ("/executedCommands", json!(2)),
        ("/commands", json!([])),
        ("/stamp/stateDigest", json!("wrong final digest")),
        ("/commands/0/stamp/revision", json!(7)),
        ("/commands/0/stamp/mapHash", json!("another map")),
        ("/commands/1/stamp/rulesetHash", json!("another ruleset")),
        ("/commands/1/viewPatch/fromRevision", json!(0)),
        ("/commands/1/viewPatch/toRevision", json!(8)),
        ("/commands/2/viewPatch/fromRevision", json!(4)),
    ] {
        let mut value = document(AI);
        *value["outcome"]["response"]
            .pointer_mut(path)
            .expect("field") = replacement;
        assert!(
            ClientResponseDto::from_json(&value.to_string()).is_err(),
            "{path}"
        );
        let typed: ClientResponseDto = serde_json::from_value(value).expect("typed shape");
        assert!(typed.to_json().is_err(), "outbound {path}");
    }
    let mut unknown = document(AI);
    unknown["outcome"]["response"]["commands"][0]["privateTarget"] = json!({"col": 9, "row": 9});
    assert!(ClientResponseDto::from_json(&unknown.to_string()).is_err());
}

#[test]
fn observed_ai_bounds_empty_and_unchanged_command_series() {
    let mut value = document(AI);
    let body = &mut value["outcome"]["response"];
    let mut command = body["commands"][1].clone();
    command["stamp"]["revision"] = json!(0);
    command["viewPatch"]["fromRevision"] = json!(0);
    command["viewPatch"]["toRevision"] = json!(0);
    body["stamp"] = command["stamp"].clone();
    for count in [
        0,
        MAX_CLIENT_OBSERVED_COMMANDS,
        MAX_CLIENT_OBSERVED_COMMANDS + 1,
    ] {
        body["executedCommands"] = json!(count);
        body["commands"] = json!(vec![command.clone(); count]);
        let source = json!({"apiVersion": aonw_contracts::client::CLIENT_API_VERSION, "outcome": {"status": "success", "response": body}});
        assert_eq!(
            ClientResponseDto::from_json(&source.to_string()).is_ok(),
            count <= MAX_CLIENT_OBSERVED_COMMANDS
        );
    }
    body["executedCommands"] = json!(2);
    body["commands"] = json!([command.clone(), command]);
    body["commands"][0]["stamp"]["stateDigest"] = json!("mutated at the same revision");
    assert!(ClientResponseDto::from_json(&value.to_string()).is_err());
}

#[test]
fn replay_requires_explicit_command_and_matching_snapshot_boundary() {
    for (path, replacement) in [
        ("/position", json!(0)),
        ("/entryCount", json!(0)),
        ("/command/stamp/stateDigest", json!("another state")),
        ("/command/viewPatch/turn", json!(99)),
        ("/command/viewPatch/turnMode", json!("simultaneous")),
        ("/command/viewPatch/fromRevision", json!(3)),
    ] {
        let mut value = document(REPLAY);
        *value["outcome"]["response"]
            .pointer_mut(path)
            .expect("field") = replacement;
        assert!(
            ClientResponseDto::from_json(&value.to_string()).is_err(),
            "{path}"
        );
    }
    let mut value = document(REPLAY);
    value["outcome"]["response"]["command"] = Value::Null;
    assert!(ClientResponseDto::from_json(&value.to_string()).is_ok());
    for field in ["command", "recipientPlayerId"] {
        let mut value = document(REPLAY);
        value["outcome"]["response"]
            .as_object_mut()
            .expect("response")
            .remove(field);
        assert!(
            ClientResponseDto::from_json(&value.to_string()).is_err(),
            "{field}"
        );
    }
}

fn document(source: &str) -> Value {
    serde_json::from_str(source).expect("fixture")
}

pub(super) fn replay_response() -> aonw_contracts::client::ClientResponseBodyDto {
    aonw_contracts::client::ClientResponseBodyDto::ReplayFrame {
        position: 3,
        entry_count: 4,
        recipient_player_id: "player-1".to_owned(),
        snapshot: super::player_snapshot(),
        command: None,
    }
}
