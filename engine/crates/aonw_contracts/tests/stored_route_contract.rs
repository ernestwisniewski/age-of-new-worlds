//! Private route metadata is strict without changing canonical persistence.
use aonw_contracts::client::{MerchantRouteViewDto, QueuedRouteViewDto};
use aonw_contracts::{MerchantTradeRouteDto, QueuedMovePathDto};
use serde_json::{Value, json};

fn route(merchant: bool) -> Value {
    let mut value = json!({
        "steps": [{"col":0,"row":0,"enterCostUnits":0,"cumulativeCostUnits":0},
            {"col":1,"row":0,"enterCostUnits":2,"cumulativeCostUnits":2}],
        "stepTurns": [1, 2], "roadStepIndices": [1]
    });
    if merchant {
        value["originCityId"] = json!("origin");
        value["destinationCityId"] = json!("destination");
        value["transportNetworkFingerprint"] = json!("network");
    } else {
        value["targetCol"] = json!(1);
        value["targetRow"] = json!(0);
    }
    value
}

fn roundtrip(value: Value, merchant: bool) -> Result<Value, serde_json::Error> {
    if merchant {
        serde_json::to_value(serde_json::from_value::<MerchantRouteViewDto>(value)?)
    } else {
        serde_json::to_value(serde_json::from_value::<QueuedRouteViewDto>(value)?)
    }
}

#[test]
fn private_route_metadata_is_required_and_separate_from_canonical_saves() {
    for merchant in [false, true] {
        let value = route(merchant);
        assert_eq!(roundtrip(value.clone(), merchant).unwrap(), value);
        for key in ["stepTurns", "roadStepIndices"] {
            let mut missing = value.clone();
            missing.as_object_mut().unwrap().remove(key);
            assert!(roundtrip(missing, merchant).is_err());
            for invalid in [
                json!(null),
                json!([true]),
                json!([-1]),
                json!([4_294_967_296_u64]),
            ] {
                let mut malformed = value.clone();
                malformed[key] = invalid;
                assert!(roundtrip(malformed, merchant).is_err());
            }
        }
        let mut canonical = value;
        canonical.as_object_mut().unwrap().remove("stepTurns");
        canonical.as_object_mut().unwrap().remove("roadStepIndices");
        if merchant {
            assert!(serde_json::from_value::<MerchantTradeRouteDto>(canonical).is_ok());
        } else {
            assert!(serde_json::from_value::<QueuedMovePathDto>(canonical).is_ok());
        }
    }
}
