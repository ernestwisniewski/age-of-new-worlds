use aonw_ai::{AiDifficulty, AiPersona, AiProfile, AiRuntimeProfile, StrategicPlanner};
use core::num::NonZeroU32;

use super::profiles::{profiled_plan, tactical_session};

#[test]
fn battery_saver_executes_less_search_work_and_remains_deterministic() {
    for difficulty in [
        AiDifficulty::Normal,
        AiDifficulty::Hard,
        AiDifficulty::VeryHard,
    ] {
        let standard = AiProfile::new(difficulty, AiPersona::Balanced);
        let saver = standard.with_runtime_profile(AiRuntimeProfile::BatterySaver);
        let mut runtime = tactical_session();
        let initial = runtime.snapshot().expect("initial snapshot");
        let full = profiled_plan(&mut runtime, standard);
        let first = profiled_plan(&mut runtime, saver);
        let second = profiled_plan(&mut runtime, saver);
        assert_eq!(runtime.snapshot().expect("after planning"), initial);
        assert_eq!(first, second);
        assert_eq!(first.profile(), saver);
        let evidence = first.tactical_search().expect("battery search");
        let full_evidence = full.tactical_search().expect("standard search");
        assert_eq!(Some(evidence.budget()), saver.tactical_budget());
        assert_eq!(
            evidence.stats().iterations(),
            evidence.budget().iterations()
        );
        assert!(evidence.stats().expanded_nodes() < evidence.budget().max_nodes());
        assert!(evidence.stats().max_depth_reached() <= evidence.budget().max_depth());
        assert!(evidence.stats().executed_commands() < full_evidence.stats().executed_commands());
        assert!(
            first
                .execute(&mut runtime)
                .expect("execute move")
                .is_accepted()
        );
        let report = StrategicPlanner
            .play_turn_with_profile(&mut runtime, NonZeroU32::new(64).expect("budget"), saver)
            .expect("complete tactical turn");
        assert!(report.completed_turn());
    }
}
