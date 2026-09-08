//! Strict per-request AI effort shared by native clients.

use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientAiRuntimeProfileDto, ClientRequestBodyDto, ClientRequestDto,
};
use serde_json::{Value, json};

const REQUEST: &str =
    include_str!("../../../fixtures/client_protocol/advance_ai_turn_request.json");

#[test]
fn ai_effort_is_an_explicit_closed_request_field() {
    let source: Value = serde_json::from_str(REQUEST).expect("fixture");
    for (name, profile) in [
        ("standard", ClientAiRuntimeProfileDto::Standard),
        ("batterySaver", ClientAiRuntimeProfileDto::BatterySaver),
    ] {
        let mut value = source.clone();
        value["request"]["runtimeProfile"] = json!(name);
        let request = ClientRequestDto::from_json(&value.to_string()).expect("profile request");
        assert_eq!(
            request.request,
            ClientRequestBodyDto::AdvanceAiTurn {
                actor_player_id: "player-2".to_owned(),
                command_budget: 64,
                runtime_profile: profile,
            }
        );
        assert_eq!(
            serde_json::from_str::<Value>(&request.to_json().expect("encode")).expect("JSON"),
            value
        );
    }
}

#[test]
fn absent_unknown_and_malformed_profiles_and_versions_fail_closed() {
    let source: Value = serde_json::from_str(REQUEST).expect("fixture");
    let mut missing = source.clone();
    missing["request"]
        .as_object_mut()
        .expect("request")
        .remove("runtimeProfile");
    assert!(ClientRequestDto::from_json(&missing.to_string()).is_err());
    for profile in [
        Value::Null,
        json!(true),
        json!(1),
        json!("balanced"),
        json!({"type":"standard"}),
    ] {
        let mut invalid = source.clone();
        invalid["request"]["runtimeProfile"] = profile;
        assert!(ClientRequestDto::from_json(&invalid.to_string()).is_err());
    }
    for version in [CLIENT_API_VERSION - 1, CLIENT_API_VERSION + 1] {
        let mut invalid = source.clone();
        invalid["apiVersion"] = json!(version);
        assert!(ClientRequestDto::from_json(&invalid.to_string()).is_err());
    }
    let duplicate = REQUEST.replace(
        "\"runtimeProfile\":\"batterySaver\"",
        "\"runtimeProfile\":\"batterySaver\",\"runtimeProfile\":\"standard\"",
    );
    assert!(ClientRequestDto::from_json(&duplicate).is_err());
}
