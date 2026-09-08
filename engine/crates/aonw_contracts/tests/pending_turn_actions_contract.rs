//! Closed pending-turn-action protocol and shared wire fixtures.
use aonw_contracts::client::{CLIENT_API_VERSION, ClientRequestDto, ClientResponseDto};
use serde_json::{Value, json};

const RESPONSE: &str =
    include_str!("../../../fixtures/client_protocol/pending_turn_actions_response.json");
const REQUEST: &str =
    include_str!("../../../fixtures/client_protocol/pending_turn_actions_request.json");

#[test]
fn pending_turn_actions_wire_fixtures_round_trip_exactly() {
    let response = ClientResponseDto::from_json(RESPONSE).expect("response");
    assert_eq!(serde_json::to_value(response).expect("json"), fixture());
    let request = ClientRequestDto::from_json(REQUEST).expect("request");
    assert_eq!(
        serde_json::to_value(request).expect("json"),
        serde_json::from_str::<Value>(REQUEST).expect("fixture")
    );
}

#[test]
fn every_turn_action_object_rejects_missing_and_unknown_fields() {
    for pointer in [
        "/outcome/response/result",
        "/outcome/response/result/stamp",
        "/outcome/response/result/actions/0",
        "/outcome/response/result/actions/0/coordinate",
        "/outcome/response/result/actions/1",
        "/outcome/response/result/actions/1/coordinate",
        "/outcome/response/result/actions/2",
    ] {
        let original = fixture();
        for key in original
            .pointer(pointer)
            .expect("object")
            .as_object()
            .expect("object")
            .keys()
        {
            let mut missing = original.clone();
            missing
                .pointer_mut(pointer)
                .expect("object")
                .as_object_mut()
                .expect("object")
                .remove(key);
            invalid(&missing);
        }
        let mut unknown = original.clone();
        unknown
            .pointer_mut(pointer)
            .expect("object")
            .as_object_mut()
            .expect("object")
            .insert("futureField".to_owned(), json!(true));
        invalid(&unknown);
    }
}

#[test]
fn turn_action_types_scalars_and_versions_fail_closed() {
    for (pointer, replacement) in [
        (
            "/outcome/response/result/actions/0/type",
            json!("futureAction"),
        ),
        ("/outcome/response/result/actions/0/unitId", json!(3)),
        ("/outcome/response/result/actions/1/cityId", Value::Null),
        ("/outcome/response/result/canActivate", json!(1)),
        ("/outcome/response/result/actions", Value::Null),
        (
            "/outcome/response/result/actions/0/coordinate/col",
            json!(0.5),
        ),
        ("/apiVersion", json!(CLIENT_API_VERSION - 1)),
        ("/apiVersion", json!(CLIENT_API_VERSION + 1)),
    ] {
        let mut value = fixture();
        *value.pointer_mut(pointer).expect("field") = replacement;
        invalid(&value);
    }
    let mut value = fixture();
    value["outcome"]["response"]["result"]["actions"] = json!([]);
    value["outcome"]["response"]["result"]["canActivate"] = json!(false);
    assert!(ClientResponseDto::from_json(&value.to_string()).is_ok());
}

#[test]
fn turn_query_rejects_client_owned_actor_and_ordering() {
    for query in [
        json!({"type":"pendingTurnActions"}),
        json!({"type":"pendingTurnActions", "expectedRevision": -1}),
        json!({"type":"pendingTurnActions", "expectedRevision": 0, "actorPlayerId":"other"}),
        json!({"type":"pendingTurnActions", "expectedRevision": 0, "actions":[]}),
    ] {
        let value =
            json!({"apiVersion": CLIENT_API_VERSION, "request":{"type":"query", "query":query}});
        assert!(ClientRequestDto::from_json(&value.to_string()).is_err());
    }
}

fn fixture() -> Value {
    serde_json::from_str(RESPONSE).expect("fixture")
}
fn invalid(value: &Value) {
    assert!(
        ClientResponseDto::from_json(&value.to_string()).is_err(),
        "{value}"
    );
}
