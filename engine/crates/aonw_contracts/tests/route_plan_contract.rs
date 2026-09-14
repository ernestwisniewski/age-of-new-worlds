//! Shared route timing fixtures and closed client transport shape.
use aonw_contracts::client::{CLIENT_API_VERSION, ClientRequestDto, ClientResponseDto};
use serde_json::{Value, json};

const REQUEST: &str = include_str!("../../../fixtures/client_protocol/route_plan_request.json");
const RESPONSE: &str = include_str!("../../../fixtures/client_protocol/route_plan_response.json");

#[test]
fn route_plan_fixtures_round_trip_without_loss() {
    let request = ClientRequestDto::from_json(REQUEST).unwrap();
    assert_eq!(
        serde_json::to_value(request).unwrap(),
        serde_json::from_str::<Value>(REQUEST).unwrap()
    );
    let response = ClientResponseDto::from_json(RESPONSE).unwrap();
    assert_eq!(serde_json::to_value(response).unwrap(), fixture());
}

#[test]
fn route_timing_is_required_and_strictly_unsigned() {
    let mut missing = fixture();
    missing["outcome"]["response"]["result"]
        .as_object_mut()
        .unwrap()
        .remove("stepTurns");
    assert!(ClientResponseDto::from_json(&missing.to_string()).is_err());
    for replacement in [
        Value::Null,
        json!({}),
        json!([null]),
        json!(["1"]),
        json!([-1]),
        json!([1.5]),
        json!([true]),
        json!([u64::from(u32::MAX) + 1]),
    ] {
        let mut value = fixture();
        value["outcome"]["response"]["result"]["stepTurns"] = replacement;
        assert!(ClientResponseDto::from_json(&value.to_string()).is_err());
    }
    let mut unknown = fixture();
    unknown["outcome"]["response"]["result"]["futureField"] = json!(true);
    assert!(ClientResponseDto::from_json(&unknown.to_string()).is_err());
    for version in [CLIENT_API_VERSION - 1, CLIENT_API_VERSION + 1] {
        let mut value = fixture();
        value["apiVersion"] = json!(version);
        assert!(ClientResponseDto::from_json(&value.to_string()).is_err());
    }
}

fn fixture() -> Value {
    serde_json::from_str(RESPONSE).unwrap()
}
