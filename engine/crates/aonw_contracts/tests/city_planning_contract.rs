//! Shared, independently specified planning fixture and closed query schema.
use aonw_contracts::client::{CLIENT_API_VERSION, ClientRequestDto, ClientResponseDto};
use serde_json::{Value, json};

const REQUEST: &str = include_str!("../../../fixtures/client_protocol/city_planning_request.json");
const RESPONSE: &str =
    include_str!("../../../fixtures/client_protocol/city_planning_response.json");

#[test]
fn city_planning_fixtures_round_trip_without_loss() {
    let request = ClientRequestDto::from_json(REQUEST).unwrap();
    assert_eq!(
        serde_json::to_value(request).unwrap(),
        serde_json::from_str::<Value>(REQUEST).unwrap()
    );
    let response = ClientResponseDto::from_json(RESPONSE).unwrap();
    assert_eq!(serde_json::to_value(response).unwrap(), fixture());
}

#[test]
fn every_planning_object_rejects_missing_and_unknown_fields() {
    for pointer in [
        "/outcome/response/result",
        "/outcome/response/result/stamp",
        "/outcome/response/result/citySites/0",
        "/outcome/response/result/growthTiles/0",
    ] {
        let original = fixture();
        for key in original
            .pointer(pointer)
            .unwrap()
            .as_object()
            .unwrap()
            .keys()
        {
            let mut value = original.clone();
            value
                .pointer_mut(pointer)
                .unwrap()
                .as_object_mut()
                .unwrap()
                .remove(key);
            assert!(
                ClientResponseDto::from_json(&value.to_string()).is_err(),
                "missing {pointer}/{key}"
            );
        }
        let mut value = original;
        value
            .pointer_mut(pointer)
            .unwrap()
            .as_object_mut()
            .unwrap()
            .insert("futureField".into(), json!(true));
        assert!(
            ClientResponseDto::from_json(&value.to_string()).is_err(),
            "unknown {pointer}"
        );
    }
}

#[test]
fn planning_rejects_wrong_types_and_untrusted_query_fields() {
    for (pointer, replacement) in [
        ("/outcome/response/result/citySites", Value::Null),
        ("/outcome/response/result/growthTiles", json!({})),
        ("/outcome/response/result/citySites/0/col", json!(0.5)),
        ("/outcome/response/result/type", json!("futurePlanning")),
        ("/apiVersion", json!(CLIENT_API_VERSION - 1)),
        ("/apiVersion", json!(CLIENT_API_VERSION + 1)),
    ] {
        let mut value = fixture();
        *value.pointer_mut(pointer).unwrap() = replacement;
        assert!(ClientResponseDto::from_json(&value.to_string()).is_err());
    }
    for query in [
        json!({"type":"cityPlanning"}),
        json!({"type":"cityPlanning","expectedRevision":-1}),
        json!({"type":"cityPlanning","expectedRevision":0,"actorPlayerId":"other"}),
        json!({"type":"cityPlanning","expectedRevision":0,"visibleHexes":[]}),
    ] {
        let request =
            json!({"apiVersion":CLIENT_API_VERSION,"request":{"type":"query","query":query}});
        assert!(ClientRequestDto::from_json(&request.to_string()).is_err());
    }
    let mut empty = fixture();
    empty["outcome"]["response"]["result"]["citySites"] = json!([]);
    empty["outcome"]["response"]["result"]["growthTiles"] = json!([]);
    assert!(ClientResponseDto::from_json(&empty.to_string()).is_ok());
}

fn fixture() -> Value {
    serde_json::from_str(RESPONSE).unwrap()
}
