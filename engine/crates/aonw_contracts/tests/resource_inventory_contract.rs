//! Strict inventory fields shared by snapshots and patches.

use aonw_contracts::client::{PlayerEconomyViewDto, StrategicResourceInventoryDto};

fn inventory() -> serde_json::Value {
    let fixture: serde_json::Value = serde_json::from_str(include_str!(
        "../../../fixtures/client_protocol/command_result_response.json"
    ))
    .unwrap();
    fixture["outcome"]["response"]["result"]["viewPatch"]["economy"]["strategicResourceInventory"]
        .clone()
}

#[test]
fn inventory_requires_seven_rows_and_every_summary_field() {
    let valid = inventory();
    let parsed: StrategicResourceInventoryDto = serde_json::from_value(valid.clone()).unwrap();
    assert_eq!(parsed.balances.len(), 7);
    assert_eq!(parsed.available_type_count, 1);
    assert_eq!(serde_json::to_value(parsed).unwrap(), valid);
    for key in valid.as_object().unwrap().keys() {
        let mut invalid = valid.clone();
        invalid.as_object_mut().unwrap().remove(key);
        assert!(
            serde_json::from_value::<StrategicResourceInventoryDto>(invalid).is_err(),
            "missing {key}"
        );
    }
    let mut short = valid.clone();
    short["balances"].as_array_mut().unwrap().pop();
    assert!(serde_json::from_value::<StrategicResourceInventoryDto>(short).is_err());
    let mut unknown = valid;
    unknown["extra"] = true.into();
    assert!(serde_json::from_value::<StrategicResourceInventoryDto>(unknown).is_err());
}

#[test]
fn inventory_requires_balance_fields_and_explicit_nullable_source_fields() {
    let valid = inventory();
    for (list, index) in [("balances", 0), ("deposits", 0)] {
        for key in valid[list][index].as_object().unwrap().keys() {
            let mut invalid = valid.clone();
            invalid[list][index].as_object_mut().unwrap().remove(key);
            assert!(
                serde_json::from_value::<StrategicResourceInventoryDto>(invalid).is_err(),
                "missing {key}"
            );
        }
    }
    let mut unimproved = valid;
    unimproved["deposits"][0]["improvement"] = serde_json::Value::Null;
    unimproved["deposits"][0]["amountPerTurn"] = serde_json::Value::Null;
    let result: StrategicResourceInventoryDto = serde_json::from_value(unimproved).unwrap();
    assert!(result.deposits[0].improvement.is_none());
    assert!(result.deposits[0].amount_per_turn.is_none());
}

#[test]
fn economy_rejects_the_previous_shape_without_inventory() {
    let fixture: serde_json::Value = serde_json::from_str(include_str!(
        "../../../fixtures/client_protocol/command_result_response.json"
    ))
    .unwrap();
    let mut economy = fixture["outcome"]["response"]["result"]["viewPatch"]["economy"].clone();
    assert!(serde_json::from_value::<PlayerEconomyViewDto>(economy.clone()).is_ok());
    economy
        .as_object_mut()
        .unwrap()
        .remove("strategicResourceInventory");
    assert!(serde_json::from_value::<PlayerEconomyViewDto>(economy).is_err());
}
