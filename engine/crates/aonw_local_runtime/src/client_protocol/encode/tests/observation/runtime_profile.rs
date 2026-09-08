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
