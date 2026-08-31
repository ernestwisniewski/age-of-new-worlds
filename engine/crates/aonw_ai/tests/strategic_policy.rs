//! Feature-complete policy decisions through current public runtime boundaries.

use core::num::NonZeroU32;
use std::collections::BTreeMap;

use aonw_ai::{
    AiDifficulty, AiPersona, AiProfile, PlannedCommand, PlannedCommandFamily, StrategicPlanner,
    StrategicPlannerError, StrategicPlanningOutcome,
};
use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    City, CityId, FogOfWar, GameLengthConfig, GameMode, GameState, HexCoord, KnowledgeState,
    MatchIdentity, MatchLifecycle, MatchRules, MovementUnits, Participant, PlayerCountry,
    PlayerFog, PlayerId, PlayerKind, PlayerResearchState, PlayerTurnState, ResearchState,
    StateRevision, TechnologyId, TurnLifecycle, Unit, UnitId, UnitKind, VictoryRules,
    WonderRegistry,
};
use aonw_local_runtime::{LocalRuntime, OpenSession};

#[test]
fn policy_closes_research_production_and_worker_decisions_before_turn_completion() {
    let (map, rules, state, actor) = fixture();
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(
            map.clone(),
            rules.clone(),
            state,
            actor,
        ))
        .expect("open policy session");

    let report = StrategicPlanner
        .play_turn(
            &mut runtime,
            NonZeroU32::new(64).expect("positive command budget"),
        )
        .expect("autonomous strategic turn");

    assert!(report.completed_turn());
    assert_eq!(report.initial_stamp().revision.get(), 9);
    assert_eq!(report.family_usage()[&PlannedCommandFamily::Research], 1);
    assert_eq!(report.family_usage()[&PlannedCommandFamily::Production], 1);
    assert_eq!(report.family_usage()[&PlannedCommandFamily::Worker], 1);
    assert_eq!(report.family_usage()[&PlannedCommandFamily::Turn], 1);
    assert_eq!(
        report.executed_commands(),
        report.family_usage().values().copied().sum::<u32>()
    );
    let snapshot = runtime.snapshot().expect("policy snapshot");
    assert!(snapshot.turn() > 4);
    let replay = runtime.export_replay_json().expect("policy replay");
    let verification =
        LocalRuntime::verify_replay_json(map, rules, &replay).expect("policy replay verification");
    assert_eq!(verification.final_stamp, *report.final_stamp());
}

#[test]
fn strategic_plan_identity_and_budget_errors_are_explicit() {
    let (map, rules, state, actor) = fixture();
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(map, rules, state, actor))
        .expect("open policy session");
    let StrategicPlanningOutcome::Planned(plan) =
        StrategicPlanner.plan(&mut runtime).expect("plan")
    else {
        panic!("expected plan")
    };
    assert_eq!(plan.state_digest(), plan.stamp().state_digest);
    assert_ne!(plan.fingerprint().as_bytes(), &[0; 32]);
    assert_eq!(plan.profile(), AiProfile::default());
    assert_eq!(plan.assessment().empire().city_count(), 1);
    assert_eq!(plan.assessment().empire().population(), 2);
    assert_eq!(plan.assessment().empire().worker_count(), 1);
    assert_eq!(plan.assessment().empire().settler_count(), 0);
    assert_eq!(plan.assessment().empire().military_count(), 0);
    assert_eq!(plan.assessment().empire().visible_enemy_military_count(), 0);
    assert_eq!(plan.assessment().empire().hostile_relation_count(), 0);
    assert_eq!(plan.assessment().goals().len(), 4);
    assert!(plan.assessment().goals()[0].utility() >= plan.assessment().goals()[1].utility());

    let error = StrategicPlanner
        .play_turn(&mut runtime, NonZeroU32::new(1).expect("budget"))
        .expect_err("one command cannot close this turn");
    assert!(matches!(
        error,
        StrategicPlannerError::CommandBudgetExhausted { maximum }
            if maximum.get() == 1
    ));
    assert_eq!(error.to_string(), "strategic command budget exhausted at 1");

    let rejection = StrategicPlannerError::CommandRejected {
        family: PlannedCommandFamily::Combat,
        rejection: aonw_engine::CommandRejectionCode::UnitBusy,
    };
    assert!(
        rejection
            .to_string()
            .starts_with("planned Combat command was rejected:")
    );
    let closed = StrategicPlanner
        .play_turn(
            &mut LocalRuntime::default(),
            NonZeroU32::new(1).expect("budget"),
        )
        .expect_err("closed runtime");
    assert!(matches!(closed, StrategicPlannerError::Runtime(_)));
    assert!(!closed.to_string().is_empty());
}

#[test]
fn persona_changes_research_selection_on_the_same_revision() {
    let (map, rules, state, actor) = fixture();
    let mut scientific_runtime = LocalRuntime::default();
    scientific_runtime
        .open(OpenSession::from_state(
            map.clone(),
            rules.clone(),
            state.clone(),
            actor.clone(),
        ))
        .expect("scientific session");
    let mut aggressive_runtime = LocalRuntime::default();
    aggressive_runtime
        .open(OpenSession::from_state(map, rules, state, actor))
        .expect("aggressive session");

    let scientific = planned_technology(
        &mut scientific_runtime,
        AiProfile::new(AiDifficulty::VeryHard, AiPersona::Scientific),
    );
    let aggressive = planned_technology(
        &mut aggressive_runtime,
        AiProfile::new(AiDifficulty::VeryHard, AiPersona::Aggressive),
    );
    assert_ne!(scientific, aggressive);
}

fn planned_technology(runtime: &mut LocalRuntime, profile: AiProfile) -> TechnologyId {
    let StrategicPlanningOutcome::Planned(plan) = StrategicPlanner
        .plan_with_profile(runtime, profile)
        .expect("profiled plan")
    else {
        panic!("expected research decision")
    };
    let PlannedCommand::SelectTechnology(request) = plan.command() else {
        panic!("research is the first unresolved family")
    };
    request.technology
}

fn fixture() -> (MapDefinition, RulesetDefinition, GameState, PlayerId) {
    let map = map();
    let rules = RulesetDefinition::standard().clone();
    let actor = player("player-1");
    let foreign = player("player-2");
    let identity = identity(&actor, &foreign);
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (actor.clone(), PlayerTurnState::Active),
            (foreign.clone(), PlayerTurnState::Finished),
        ]),
        [actor.clone()],
        [],
        BTreeMap::new(),
        [],
        [foreign.clone()],
        None,
    )
    .expect("lifecycle");
    let research = ResearchState::try_new([
        (
            actor.clone(),
            PlayerResearchState::try_new([TechnologyId::Agriculture], None, [], 0)
                .expect("actor research"),
        ),
        (foreign.clone(), PlayerResearchState::default()),
    ])
    .expect("research");
    let worker = Unit::builder(
        UnitId::new("worker-1").expect("worker id"),
        actor.clone(),
        UnitKind::Worker,
        "Worker",
        HexCoord::new(1, 1),
        MovementUnits::new(10),
    )
    .with_worker_build_charges(1)
    .build()
    .expect("worker");
    let observer = Unit::builder(
        UnitId::new("observer-1").expect("observer id"),
        foreign.clone(),
        UnitKind::Scout,
        "Observer",
        HexCoord::new(5, 3),
        MovementUnits::new(10),
    )
    .build()
    .expect("observer");
    let city = City::builder(
        CityId::new("city-1").expect("city id"),
        actor.clone(),
        "Capital",
        HexCoord::new(0, 1),
    )
    .with_progression(2, 0, 6, 3)
    .with_controlled_hexes([HexCoord::new(1, 1)])
    .build()
    .expect("city");
    let visible = (0..4)
        .flat_map(|row| (0..6).map(move |col| HexCoord::new(col, row)))
        .collect::<Vec<_>>();
    let fog = FogOfWar::try_new([
        PlayerFog::new(actor.clone(), [], visible),
        PlayerFog::new(foreign.clone(), [], [HexCoord::new(5, 3)]),
    ])
    .expect("fog");
    let state = GameState::builder(
        StateRevision::new(9),
        4,
        map.bounds(),
        rules.occupancy_policy(),
        [worker, observer],
    )
    .with_cities([city])
    .with_fog_of_war(fog)
    .with_knowledge(KnowledgeState::new(research, WonderRegistry::default()))
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state");
    (map, rules, state, actor)
}

fn identity(actor: &PlayerId, foreign: &PlayerId) -> MatchIdentity {
    MatchIdentity::try_new(
        MatchRules::new(
            GameLengthConfig::default(),
            VictoryRules::try_new(
                false,
                false,
                aonw_domain::RuleNumber::new("60").expect("percent"),
                1,
                true,
                Some(20),
                None,
                false,
                1,
                1,
            )
            .expect("victory rules"),
            BTreeMap::new(),
        ),
        [participant(actor), participant(foreign)],
        GameMode::HotSeat,
    )
    .expect("identity")
}

fn map() -> MapDefinition {
    MapDefinition::try_new(
        "ai-strategic-policy",
        GridLayout::OddQFlatTop,
        6,
        4,
        (0..4)
            .flat_map(|row| {
                (0..6).map(move |col| {
                    TileDefinition::try_new_for_simulation(
                        HexCoord::new(col, row),
                        vec![TerrainType::Grassland],
                        Vec::new(),
                        0,
                    )
                    .expect("tile")
                })
            })
            .collect(),
        Vec::new(),
    )
    .expect("map")
}

fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player")
}

fn participant(player: &PlayerId) -> Participant {
    Participant::try_new(
        player.clone(),
        player.as_str(),
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Ai,
        None,
    )
    .expect("participant")
}
