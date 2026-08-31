//! Coverage for the current all-scope economy turn processor.

use std::collections::BTreeMap;

use aonw_content::RulesetDefinition;
use aonw_domain::{
    EconomyState, GameMode, GameState, InitialResourceDistribution, MatchIdentity, MatchLifecycle,
    MatchRules, PlayerTurnState, StateRevision, TurnLifecycle, UnitOccupancyPolicy,
};
use aonw_engine::{
    EngineContext, GameEngine, PlayerCommand, ProcessorRequirement, TurnCommand, TurnProcessor,
};

use super::{map, participant, player, unit};

#[test]
fn persisted_economy_requirement_is_supported_and_executes() {
    let map = map();
    let rules = RulesetDefinition::standard();
    let player = player("player-2");
    let processor = TurnProcessor::Economy;
    let state = state_requiring_economy();
    assert_eq!(
        processor.requirement(&state, &map, std::slice::from_ref(&player)),
        ProcessorRequirement::RequiredAndSupported,
        "{processor:?} must be supported for every non-empty scope"
    );
    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&player, &map, rules),
        PlayerCommand::SubmitTurn(TurnCommand::new(7, &player)),
    )
    .expect("supported economy finalization");
    assert!(transition.is_accepted());
    assert!(
        transition
            .state()
            .economy()
            .player_war_weariness()
            .is_empty(),
        "peace-time weariness must decay to zero"
    );
}

fn state_requiring_economy() -> GameState {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [
            participant(p1.clone(), "One"),
            participant(p2.clone(), "Two"),
        ],
        GameMode::Multiplayer,
    )
    .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (p1.clone(), PlayerTurnState::Finished),
            (p2.clone(), PlayerTurnState::Active),
        ]),
        [p1.clone(), p2.clone()],
        [p1],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("turn lifecycle");
    let mut builder = GameState::builder(
        StateRevision::new(7),
        7,
        map().bounds(),
        UnitOccupancyPolicy::Exclusive,
        [unit("unit-2", &p2)],
    )
    .with_match_lifecycle(MatchLifecycle::new(identity.clone(), lifecycle));

    builder = builder.with_economy(
        EconomyState::try_new(
            &identity,
            map().bounds(),
            BTreeMap::new(),
            BTreeMap::from([(p2, 1)]),
            BTreeMap::new(),
            BTreeMap::new(),
            InitialResourceDistribution::default(),
        )
        .expect("economy"),
    );
    builder.try_build().expect("state")
}
