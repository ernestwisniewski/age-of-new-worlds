use crate::AiRuntimeProfile;

use super::{ScriptedDriver, budget, opened, player};

#[test]
fn planning_effort_is_per_request_and_does_not_change_canonical_state() {
    let (_, _, original) = opened();
    let save = original.export_save_json().expect("initial save");
    let mut driver = ScriptedDriver::new(0);
    for runtime_profile in [
        AiRuntimeProfile::Standard,
        AiRuntimeProfile::BatterySaver,
        AiRuntimeProfile::Standard,
    ] {
        let mut runtime = original.clone();
        let observed = runtime
            .advance_ai_turn_observed(player("ai"), budget(1), runtime_profile, &mut driver)
            .expect("observed AI request");
        assert!(observed.commands.is_empty());
        assert_eq!(driver.runtime_profiles.last(), Some(&runtime_profile));
        runtime
            .handoff_hot_seat_actor(player("human"))
            .expect("restore human");
        assert_eq!(runtime.export_save_json().expect("save"), save);
    }
    assert_eq!(
        driver.runtime_profiles,
        [
            AiRuntimeProfile::Standard,
            AiRuntimeProfile::BatterySaver,
            AiRuntimeProfile::Standard
        ]
    );
}

#[test]
fn wire_profile_reaches_the_driver_for_each_request() {
    for (name, expected) in [
        ("standard", AiRuntimeProfile::Standard),
        ("batterySaver", AiRuntimeProfile::BatterySaver),
    ] {
        let (_, _, mut runtime) = opened();
        let mut driver = ScriptedDriver::new(0);
        let response = crate::ClientProtocol::dispatch_json_with_ai(
            &mut runtime,
            &wire_request(&serde_json::json!(name)).to_string(),
            &mut driver,
        );
        let response: serde_json::Value = serde_json::from_str(&response).expect("response");
        assert_eq!(response["outcome"]["status"], "success");
        assert_eq!(
            response["outcome"]["response"]["recipientPlayerId"],
            "human"
        );
        assert_eq!(driver.runtime_profiles, [expected]);
    }
}

#[test]
fn invalid_wire_profiles_do_not_handoff_or_execute_the_driver() {
    for profile in [
        serde_json::Value::Null,
        serde_json::json!(false),
        serde_json::json!("unbounded"),
    ] {
        let (_, _, mut runtime) = opened();
        let before = runtime.snapshot().expect("initial snapshot");
        let save = runtime.export_save_json().expect("save");
        let mut driver = ScriptedDriver::new(0);
        let response = crate::ClientProtocol::dispatch_json_with_ai(
            &mut runtime,
            &wire_request(&profile).to_string(),
            &mut driver,
        );
        let response: serde_json::Value = serde_json::from_str(&response).expect("response");
        assert_eq!(
            response["outcome"]["error"]["code"],
            "invalid_client_request"
        );
        assert!(driver.runtime_profiles.is_empty());
        assert_eq!(runtime.snapshot().expect("after rejection"), before);
        assert_eq!(runtime.export_save_json().expect("unchanged save"), save);
    }
}

fn wire_request(profile: &serde_json::Value) -> serde_json::Value {
    serde_json::json!({"apiVersion": aonw_contracts::client::CLIENT_API_VERSION,
        "request": {"type":"advanceAiTurn", "actorPlayerId":"ai", "commandBudget":3, "runtimeProfile":profile}})
}
