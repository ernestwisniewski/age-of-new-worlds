use super::*;

#[test]
fn policy_reports_a_terminal_match_without_dispatching() {
    let world = World::new("ai-policy-terminal", 2, 1);
    let outcome = GameOutcome::try_new(
        &world.identity,
        GameOutcomeCondition::Conquest,
        Some(world.actor.clone()),
        BTreeMap::new(),
    )
    .expect("terminal outcome");
    let state = world
        .state([], [])
        .with_outcome(outcome)
        .try_build()
        .expect("state");
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(
            world.map,
            world.rules,
            state,
            world.actor,
        ))
        .expect("open");
    assert!(matches!(
        StrategicPlanner.plan(&mut runtime).expect("terminal plan"),
        StrategicPlanningOutcome::MatchFinished { revision } if revision.get() == 9
    ));
    assert!(
        runtime
            .export_replay_json()
            .expect("replay")
            .contains("\"entries\":[]")
    );
}
