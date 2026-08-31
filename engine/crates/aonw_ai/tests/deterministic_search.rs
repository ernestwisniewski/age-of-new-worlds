//! Deterministic random and MCTS planning through public runtime transitions.

use core::num::NonZeroU32;
use std::collections::BTreeMap;

use aonw_ai::{
    MctsPlan, MctsPlanner, MctsPlanningOutcome, PlanningBudget, RandomPlan, RandomPlanner,
    RandomPlanningOutcome, SearchFingerprint, StrategicPlanner,
};
use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    GameLengthConfig, GameMode, GameState, HexCoord, MatchIdentity, MatchLifecycle, MatchRules,
    MovementUnits, Participant, PlayerCountry, PlayerId, PlayerKind, PlayerTurnState, RuleNumber,
    StateRevision, TurnLifecycle, Unit, UnitId, UnitKind, VictoryRules,
};
use aonw_local_runtime::{
    FinalizeTimedOutTurnRequest, LocalRuntime, OpenSession, SessionStamp, TurnCommandRequest,
    UnitActionRequest,
};

#[test]
fn random_planner_replays_seed_and_ordered_draw_exactly() {
    let mut first_runtime = opened_runtime();
    let mut second_runtime = opened_runtime();
    let first = random_plan(&mut first_runtime, 77);
    let second = random_plan(&mut second_runtime, 77);

    assert_eq!(first, second);
    assert_eq!(first.rng_trace().draws().len(), 1);
    assert_ne!(
        first.rng_trace().initial_state(),
        first.rng_trace().final_state()
    );
    assert_eq!(first.search_fingerprint().as_bytes().len(), 32);
    assert_eq!(first.state_digest(), first.stamp().state_digest);
    assert_eq!(first.fingerprint().as_bytes().len(), 32);
    assert_eq!(first.command().expected_revision(), 0);

    let different_seed = (78..128)
        .map(|seed| random_plan(&mut opened_runtime(), seed))
        .find(|candidate| candidate.command() != first.command())
        .expect("another seed selects another legal action");
    assert_ne!(
        first.search_fingerprint(),
        different_seed.search_fingerprint()
    );
    assert_ne!(first.command(), different_seed.command());

    let mut execution_runtime = opened_runtime();
    let execution_plan = random_plan(&mut execution_runtime, 77);
    assert!(
        execution_plan
            .execute(&mut execution_runtime)
            .expect("public random dispatch")
            .is_accepted()
    );
}

#[test]
fn mcts_is_identical_for_the_same_state_seed_and_budget() {
    let budget = PlanningBudget::try_new(24, 12, 3).expect("budget");
    let mut first_runtime = opened_runtime();
    let mut second_runtime = opened_runtime();
    let before = first_runtime.snapshot().expect("before planning");

    let first = mcts_plan(&mut first_runtime, 101, budget);
    let second = mcts_plan(&mut second_runtime, 101, budget);

    assert_eq!(first, second);
    assert_eq!(first_runtime.snapshot().expect("after planning"), before);
    assert_eq!(first.state_digest(), first.stamp().state_digest);
    assert_eq!(first.command().expected_revision(), 0);
    assert_eq!(first.fingerprint().as_bytes().len(), 32);
    assert_eq!(first.stats().iterations(), budget.iterations());
    assert!(first.stats().expanded_nodes() < budget.max_nodes());
    assert!(first.stats().executed_commands() >= budget.iterations());
    assert!(first.stats().rollout_commands() > 0);
    assert_eq!(first.stats().rejected_commands(), 0);
    assert!(first.stats().max_depth_reached() <= budget.max_depth());
    assert!(!first.rng_trace().draws().is_empty());
    assert_eq!(first.search_fingerprint().to_string().len(), 64);
}

#[test]
fn planners_return_typed_no_command_after_movement_is_exhausted() {
    let mut runtime = opened_runtime();
    runtime
        .skip_unit_turn(&UnitActionRequest {
            expected_revision: 0,
            unit_id: UnitId::new("unit-1").expect("unit id"),
        })
        .expect("exhaust movement");

    assert!(matches!(
        RandomPlanner::new(7).plan(&mut runtime).expect("random outcome"),
        RandomPlanningOutcome::NoLegalCommand { revision } if revision.get() == 1
    ));
    let budget = PlanningBudget::try_new(4, 4, 2).expect("budget");
    assert!(matches!(
        MctsPlanner::new(7, budget).plan(&mut runtime).expect("MCTS outcome"),
        MctsPlanningOutcome::NoLegalCommand { revision } if revision.get() == 1
    ));
}

#[test]
fn node_and_iteration_limits_are_exact_and_part_of_search_identity() {
    let small_budget = PlanningBudget::try_new(7, 2, 2).expect("small budget");
    let larger_budget = PlanningBudget::try_new(8, 4, 2).expect("larger budget");
    let small = mcts_plan(&mut opened_runtime(), 9, small_budget);
    let larger = mcts_plan(&mut opened_runtime(), 9, larger_budget);

    assert_eq!(small.stats().iterations(), 7);
    assert_eq!(small.stats().expanded_nodes(), 1);
    assert_eq!(small.budget(), small_budget);
    assert_eq!(larger.stats().iterations(), 8);
    assert!(larger.stats().expanded_nodes() <= 3);
    assert_ne!(small.search_fingerprint(), larger.search_fingerprint());
}

#[test]
fn searched_command_executes_normally_and_stale_plan_is_non_mutating() {
    let budget = PlanningBudget::try_new(12, 8, 2).expect("budget");
    let mut accepted_runtime = opened_runtime();
    let accepted = mcts_plan(&mut accepted_runtime, 7, budget);
    let result = accepted
        .execute(&mut accepted_runtime)
        .expect("public dispatch");
    assert!(result.is_accepted());

    let mut stale_runtime = opened_runtime();
    let stale = mcts_plan(&mut stale_runtime, 7, budget);
    stale_runtime
        .skip_unit_turn(&UnitActionRequest {
            expected_revision: 0,
            unit_id: UnitId::new("unit-1").expect("unit id"),
        })
        .expect("advance revision");
    let newer = stale_runtime.snapshot().expect("newer snapshot");
    let rejected = stale.execute(&mut stale_runtime).expect("typed rejection");
    assert_eq!(
        rejected.rejection,
        Some(aonw_engine::CommandRejectionCode::StaleRevision)
    );
    assert_eq!(stale_runtime.snapshot().expect("preserved"), newer);
}

#[test]
fn multi_turn_ai_soak_replays_digest_and_rng_evidence_exactly() {
    let first = run_ai_soak();
    let second = run_ai_soak();

    assert_eq!(first, second);
    assert!(first.1.len() >= 12);
    let verification = LocalRuntime::verify_replay_json(map(), ruleset(), &first.2)
        .expect("verify AI command replay");
    assert_eq!(verification.final_stamp, first.0);
}

#[test]
fn strategic_policy_completes_a_turn_without_manual_commands_and_replays_exactly() {
    let mut first = opened_runtime();
    let mut second = opened_runtime();
    let budget = NonZeroU32::new(64).expect("positive budget");

    let first_report = StrategicPlanner
        .play_turn(&mut first, budget)
        .expect("first autonomous turn");
    let second_report = StrategicPlanner
        .play_turn(&mut second, budget)
        .expect("second autonomous turn");

    assert_eq!(first_report, second_report);
    assert!(first_report.completed_turn());
    assert!(first_report.executed_commands() >= 3);
    assert_eq!(
        first_report
            .family_usage()
            .get(&aonw_ai::PlannedCommandFamily::Research),
        Some(&1)
    );
    assert_eq!(
        first_report
            .family_usage()
            .get(&aonw_ai::PlannedCommandFamily::Turn),
        Some(&1)
    );
    let replay = first.export_replay_json().expect("policy replay");
    let verification =
        LocalRuntime::verify_replay_json(map(), ruleset(), &replay).expect("verify policy replay");
    assert_eq!(verification.final_stamp, *first_report.final_stamp());
}

fn random_plan(runtime: &mut LocalRuntime, seed: u32) -> Box<RandomPlan> {
    let RandomPlanningOutcome::Planned(plan) =
        RandomPlanner::new(seed).plan(runtime).expect("plan")
    else {
        panic!("random command")
    };
    plan
}

fn mcts_plan(runtime: &mut LocalRuntime, seed: u32, budget: PlanningBudget) -> Box<MctsPlan> {
    let MctsPlanningOutcome::Planned(plan) = MctsPlanner::new(seed, budget)
        .plan(runtime)
        .expect("search")
    else {
        panic!("MCTS command")
    };
    plan
}

fn run_ai_soak() -> (SessionStamp, Vec<(SearchFingerprint, u32)>, String) {
    let mut runtime = opened_runtime();
    let budget = PlanningBudget::try_new(8, 6, 2).expect("budget");
    let mut evidence = Vec::new();
    let actor = PlayerId::new("player-1").expect("actor");
    let opponent = PlayerId::new("player-2").expect("opponent");
    for _ in 0..6 {
        for _ in 0..4 {
            match MctsPlanner::new(1_001, budget)
                .plan(&mut runtime)
                .expect("soak search")
            {
                MctsPlanningOutcome::Planned(plan) => {
                    evidence.push((plan.search_fingerprint(), plan.rng_trace().final_state()));
                    assert!(
                        plan.execute(&mut runtime)
                            .expect("soak command")
                            .is_accepted()
                    );
                }
                MctsPlanningOutcome::NoLegalCommand { .. } => break,
            }
        }
        let revision = runtime.snapshot().expect("turn snapshot").stamp().revision;
        let submitted = runtime
            .submit_turn(TurnCommandRequest {
                expected_revision: revision.get(),
            })
            .expect("submit AI turn");
        assert!(submitted.is_accepted(), "submit rejected: {submitted:?}");
        let finalized = runtime
            .finalize_timed_out_turn(&FinalizeTimedOutTurnRequest {
                expected_revision: submitted.stamp.revision.get(),
                player_ids: vec![actor.clone(), opponent.clone()].into_boxed_slice(),
                skipped_player_ids: vec![opponent.clone()].into_boxed_slice(),
                next_turn_started_at: None,
            })
            .expect("finalize opponent timeout");
        assert!(
            finalized.is_accepted(),
            "finalization rejected: {finalized:?}"
        );
    }
    let final_snapshot = runtime.snapshot().expect("final snapshot");
    assert!(
        final_snapshot.outcome().is_terminal(),
        "match remained active at turn {}",
        final_snapshot.turn()
    );
    let stamp = *final_snapshot.stamp();
    let replay = runtime.export_replay_json().expect("AI replay");
    (stamp, evidence, replay)
}

fn opened_runtime() -> LocalRuntime {
    let map = map();
    let ruleset = ruleset();
    let actor = PlayerId::new("player-1").expect("actor");
    let opponent = PlayerId::new("player-2").expect("opponent");
    let identity = MatchIdentity::try_new(
        match_rules(),
        [
            participant(actor.clone(), "AI", PlayerCountry::Poland),
            participant(opponent.clone(), "Opponent", PlayerCountry::Germany),
        ],
        GameMode::Multiplayer,
    )
    .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (actor.clone(), PlayerTurnState::Active),
            (opponent.clone(), PlayerTurnState::Active),
        ]),
        [actor.clone(), opponent.clone()],
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle");
    let unit = Unit::builder(
        UnitId::new("unit-1").expect("unit id"),
        actor.clone(),
        UnitKind::Commander,
        "Commander",
        HexCoord::new(1, 1),
        MovementUnits::new(6),
    )
    .build()
    .expect("unit");
    let opponent_unit = Unit::builder(
        UnitId::new("unit-2").expect("unit id"),
        opponent,
        UnitKind::Commander,
        "Opponent",
        HexCoord::new(3, 3),
        MovementUnits::new(6),
    )
    .build()
    .expect("opponent unit");
    let state = GameState::builder(
        StateRevision::INITIAL,
        0,
        map.bounds(),
        ruleset.occupancy_policy(),
        [unit, opponent_unit],
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state");
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(map, ruleset, state, actor))
        .expect("open");
    runtime
}

fn ruleset() -> RulesetDefinition {
    RulesetDefinition::standard().clone()
}

fn match_rules() -> MatchRules {
    let victory = VictoryRules::try_new(
        false,
        false,
        RuleNumber::new("60").expect("percent"),
        1,
        true,
        Some(6),
        None,
        false,
        1,
        1,
    )
    .expect("victory rules");
    MatchRules::new(GameLengthConfig::default(), victory, BTreeMap::new())
}

fn participant(id: PlayerId, name: &str, country: PlayerCountry) -> Participant {
    Participant::try_new(id, name, 0xff00_0000, country, PlayerKind::Ai, None).expect("participant")
}

fn map() -> MapDefinition {
    let tiles = (0..4)
        .flat_map(|row| {
            (0..4).map(move |col| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(col, row),
                    vec![TerrainType::Grassland],
                    Vec::new(),
                    0,
                )
                .expect("tile")
            })
        })
        .collect();
    MapDefinition::try_new(
        "ai-search-map",
        GridLayout::OddQFlatTop,
        4,
        4,
        tiles,
        Vec::new(),
    )
    .expect("map")
}
