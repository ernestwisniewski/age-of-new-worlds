//! Closed hex-inspection protocol schema and cross-language fixtures.
use aonw_contracts::client::{CLIENT_API_VERSION, ClientRequestDto, ClientResponseDto};
use serde_json::{Value, json};

const RESPONSE: &str =
    include_str!("../../../fixtures/client_protocol/hex_inspection_response.json");
const REQUEST: &str = include_str!("../../../fixtures/client_protocol/hex_inspection_request.json");
const PROFILE: &str = "/outcome/response/result/inspection";

#[test]
fn hex_inspection_wire_fixtures_round_trip_exactly() {
    let response = ClientResponseDto::from_json(RESPONSE).expect("response");
    assert_eq!(serde_json::to_value(response).expect("json"), fixture());
    let request = ClientRequestDto::from_json(REQUEST).expect("request");
    assert_eq!(
        serde_json::to_value(request).expect("json"),
        serde_json::from_str::<Value>(REQUEST).expect("fixture")
    );
}

#[test]
fn every_hex_profile_object_rejects_missing_and_unknown_fields() {
    for pointer in [
        "/outcome/response/result".to_owned(),
        PROFILE.to_owned(),
        format!("{PROFILE}/coordinate"),
        format!("{PROFILE}/yieldValue"),
        format!("{PROFILE}/score"),
        format!("{PROFILE}/improvements/0"),
        format!("{PROFILE}/improvements/0/yieldDelta"),
        format!("{PROFILE}/improvementAccess"),
    ] {
        let original = fixture();
        let object = original
            .pointer(&pointer)
            .expect("object")
            .as_object()
            .expect("object");
        for key in object.keys() {
            let mut missing = original.clone();
            missing
                .pointer_mut(&pointer)
                .expect("object")
                .as_object_mut()
                .expect("object")
                .remove(key);
            assert_invalid(&missing, &format!("{pointer}/{key}"));
        }
        let mut unknown = original.clone();
        unknown
            .pointer_mut(&pointer)
            .expect("object")
            .as_object_mut()
            .expect("object")
            .insert("futureField".to_owned(), json!(true));
        assert_invalid(&unknown, &pointer);
    }
}

#[test]
fn unknown_hex_enum_values_and_wrong_scalar_types_fail_closed() {
    for path in [
        "baseTerrain",
        "terrainTags/0",
        "resources/0",
        "kind",
        "recommendation",
        "tags/0",
        "improvementAccess/kind",
        "improvements/0/kind",
        "improvements/0/requiredTechnology",
    ] {
        let mut value = fixture();
        *value
            .pointer_mut(&format!("{PROFILE}/{path}"))
            .expect("field") = json!("futureValue");
        assert_invalid(&value, path);
    }
    for path in [
        "height",
        "hasRiver",
        "canFoundCityOnTerrain",
        "score/city",
        "improvements/0/buildTurns",
        "improvements/0/technologyUnlocked",
    ] {
        let mut value = fixture();
        *value
            .pointer_mut(&format!("{PROFILE}/{path}"))
            .expect("field") = json!("1");
        assert_invalid(&value, path);
    }
}

#[test]
fn hex_access_variants_are_closed_and_explicit_null_technology_is_valid() {
    for access in [
        json!({"kind":"outsideControlledCity"}),
        json!({"kind":"cityCenter"}),
        json!({"kind":"alreadyImproved"}),
        json!({"kind":"controlledCity", "cityId":"city-1"}),
    ] {
        let mut value = fixture();
        *value
            .pointer_mut(&format!("{PROFILE}/improvementAccess"))
            .expect("access") = access;
        *value
            .pointer_mut(&format!("{PROFILE}/improvements/0/requiredTechnology"))
            .expect("technology") = Value::Null;
        ClientResponseDto::from_json(&value.to_string()).expect("valid access and explicit null");
        value
            .pointer_mut(&format!("{PROFILE}/improvementAccess"))
            .expect("access")
            .as_object_mut()
            .expect("object")
            .insert("extra".to_owned(), json!(true));
        assert_invalid(&value, "access extra field");
    }
}

#[test]
fn hex_request_is_revision_bound_and_accepts_only_the_current_api() {
    let original = serde_json::from_str::<Value>(REQUEST).expect("request");
    for key in ["expectedRevision", "coordinate"] {
        let mut value = original.clone();
        value["request"]["query"]
            .as_object_mut()
            .expect("query")
            .remove(key);
        assert!(ClientRequestDto::from_json(&value.to_string()).is_err());
    }
    for version in [CLIENT_API_VERSION - 1, CLIENT_API_VERSION + 1] {
        let mut value = original.clone();
        value["apiVersion"] = json!(version);
        assert!(ClientRequestDto::from_json(&value.to_string()).is_err());
    }
    let mut value = original;
    value["request"]["query"]["actorPlayerId"] = json!("other");
    assert!(ClientRequestDto::from_json(&value.to_string()).is_err());
}

fn fixture() -> Value {
    serde_json::from_str(RESPONSE).expect("fixture")
}
fn assert_invalid(value: &Value, label: &str) {
    assert!(
        ClientResponseDto::from_json(&value.to_string()).is_err(),
        "accepted invalid {label}"
    );
}
