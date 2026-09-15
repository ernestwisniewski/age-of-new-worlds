//! Strict HUD status transport independent of canonical save state.

use aonw_contracts::client::{TreasuryWarningDto, VictoryStatusDto};
use serde_json::json;

#[test]
fn victory_status_requires_explicit_nullable_leader_and_typed_priority() {
    let valid = json!({"kind":"score", "critical":true, "leaderPlayerId":null});
    let decoded: VictoryStatusDto = serde_json::from_value(valid.clone()).unwrap();
    assert_eq!(serde_json::to_value(decoded).unwrap(), valid);
    for field in ["kind", "critical", "leaderPlayerId"] {
        let mut missing = valid.clone();
        missing.as_object_mut().unwrap().remove(field);
        assert!(
            serde_json::from_value::<VictoryStatusDto>(missing).is_err(),
            "{field}"
        );
    }
    for (field, value) in [
        ("kind", json!("future")),
        ("critical", json!(1)),
        ("leaderPlayerId", json!(false)),
        ("unknown", json!(true)),
    ] {
        let mut invalid = valid.clone();
        invalid[field] = value;
        assert!(serde_json::from_value::<VictoryStatusDto>(invalid).is_err());
    }
}

#[test]
fn treasury_warning_variants_are_explicit_and_unknown_values_fail_closed() {
    for value in ["none", "negativeBalance", "deficitWithinThreeTurns"] {
        let decoded: TreasuryWarningDto = serde_json::from_value(json!(value)).unwrap();
        assert_eq!(serde_json::to_value(decoded).unwrap(), json!(value));
    }
    for invalid in [json!(null), json!(1), json!("negative"), json!({})] {
        assert!(serde_json::from_value::<TreasuryWarningDto>(invalid).is_err());
    }
}
