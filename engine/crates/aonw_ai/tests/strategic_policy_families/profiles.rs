use aonw_ai::{
    AiDifficulty, AiPersona, AiProfile, PlannedCommand, PlannedCommandFamily, StrategicPlanner,
    StrategicPlanningOutcome,
};
use aonw_domain::{
    Diplomacy, DiplomaticProposal, DiplomaticProposalKind, DiplomaticRelation,
    DiplomaticRelationChangeReason, DiplomaticRelationStatus, HexCoord, PlayerPair, UnitKind,
};
use aonw_local_runtime::{LocalRuntime, OpenSession};

use super::{World, unit};

#[test]
fn aggressive_profile_declines_friendship_by_policy() {
    let world = World::new("ai-policy-profile-diplomacy", 4, 4);
    let proposal = DiplomaticProposal::try_new(
        "proposal-1".to_owned(),
        world.foreign.clone(),
        world.actor.clone(),
        DiplomaticProposalKind::Friendship,
        4,
        8,
        0,
    )
    .expect("proposal");
    let contact = PlayerPair::new(world.actor.clone(), world.foreign.clone()).expect("contact");
    let state = world
        .state([], [])
        .with_diplomacy(
            Diplomacy::try_new(&world.identity, [contact], [], [proposal], [], [], [])
                .expect("diplomacy"),
        )
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
    let plan = profiled_plan(
        &mut runtime,
        AiProfile::new(AiDifficulty::Hard, AiPersona::Aggressive),
    );
    assert!(matches!(
        plan.command(),
        PlannedCommand::Diplomacy(aonw_local_runtime::DiplomacyRequest::Respond {
            accepted: false,
            ..
        })
    ));
}

#[test]
fn hard_profile_uses_bounded_search_only_under_visible_hostile_pressure() {
    let world = World::new("ai-policy-selective-search", 5, 1);
    let actor = unit(
        "actor",
        &world.actor,
        UnitKind::Commander,
        HexCoord::new(0, 0),
    );
    let opponent = unit(
        "opponent",
        &world.foreign,
        UnitKind::Commander,
        HexCoord::new(4, 0),
    );
    let pair = PlayerPair::new(world.actor.clone(), world.foreign.clone()).expect("pair");
    let relation = DiplomaticRelation::try_new(
        pair.clone(),
        DiplomaticRelationStatus::War,
        -80,
        None,
        Some(4),
        Some(DiplomaticRelationChangeReason::DeclarationOfWar),
    )
    .expect("war relation");
    let state = world
        .state([actor, opponent], [])
        .with_diplomacy(
            Diplomacy::try_new(&world.identity, [pair], [relation], [], [], [], [])
                .expect("diplomacy"),
        )
        .try_build()
        .expect("state");
    let mut easy = LocalRuntime::default();
    easy.open(OpenSession::from_state(
        world.map.clone(),
        world.rules.clone(),
        state.clone(),
        world.actor.clone(),
    ))
    .expect("easy session");
    let mut hard = LocalRuntime::default();
    hard.open(OpenSession::from_state(
        world.map,
        world.rules,
        state,
        world.actor,
    ))
    .expect("hard session");

    let easy_plan = profiled_plan(
        &mut easy,
        AiProfile::new(AiDifficulty::Easy, AiPersona::Balanced),
    );
    let hard_plan = profiled_plan(
        &mut hard,
        AiProfile::new(AiDifficulty::Hard, AiPersona::Balanced),
    );
    assert_eq!(easy_plan.command().family(), PlannedCommandFamily::Movement);
    assert!(easy_plan.tactical_search().is_none());
    let evidence = hard_plan.tactical_search().expect("hard tactical search");
    assert_eq!(evidence.budget().iterations(), 16);
    assert_eq!(evidence.stats().iterations(), 16);
    assert_ne!(evidence.fingerprint().as_bytes(), &[0; 32]);
}

fn profiled_plan(runtime: &mut LocalRuntime, profile: AiProfile) -> Box<aonw_ai::StrategicPlan> {
    let StrategicPlanningOutcome::Planned(plan) = StrategicPlanner
        .plan_with_profile(runtime, profile)
        .expect("profiled plan")
    else {
        panic!("planned command")
    };
    plan
}
