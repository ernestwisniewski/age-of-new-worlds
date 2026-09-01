use std::collections::BTreeMap;

use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{
    GameMode, GameOutcomeCondition, GameState, MatchIdentity, MatchLifecycle, MatchRules, PlayerId,
    PlayerTurnState, StateRevision, TurnLifecycle, UnitOccupancyPolicy, UtcTimestamp,
};
use aonw_engine::{
    CommandRejectionCode, DomainEvent, FinalizeTimedOutTurnCommand, GameEngine,
    KickParticipantCommand, ResignParticipantCommand, SystemCommand, SystemContext,
};

use super::{map, participant, player, state};

#[test]
fn trusted_timeout_and_kick_have_no_player_context() {
    let map = map();
    let rules = RulesetDefinition::standard();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let submitted = state(GameMode::Multiplayer, [p1.clone()], None);
    let time = UtcTimestamp::new("2026-08-24T12:00:00Z").expect("UTC");

    let timeout = GameEngine::apply_system_owned(
        submitted.clone(),
        SystemContext::canonical(&map, rules),
        SystemCommand::FinalizeTimedOutTurn(FinalizeTimedOutTurnCommand::new(
            7,
            &[p1.clone(), p2.clone()],
            std::slice::from_ref(&p2),
            Some(&time),
        )),
    )
    .expect("timeout");
    assert!(timeout.is_accepted());
    assert!(matches!(
        timeout.events(),
        [
            DomainEvent::PlayerTimedOut(_),
            DomainEvent::AllPlayersSubmitted(_),
            DomainEvent::TurnEnded(_),
            DomainEvent::TurnEnded(_)
        ]
    ));
    assert_eq!(
        timeout
            .state()
            .match_lifecycle()
            .turn()
            .timeout_streaks_by_player_id()
            .get(&p2),
        Some(&1)
    );
    assert_system_command_rejections(&map, rules, &p1, &p2, submitted, timeout.state());

    let invalid = GameEngine::apply_system_owned(
        timeout.state().clone(),
        SystemContext::canonical(&map, rules),
        SystemCommand::FinalizeTimedOutTurn(FinalizeTimedOutTurnCommand::new(
            8,
            &[p1.clone(), p1.clone()],
            &[],
            None,
        )),
    )
    .expect("invalid scope");
    assert_eq!(
        invalid.rejection().expect("rejection").code(),
        CommandRejectionCode::TurnScopeInvalid
    );

    let kick = KickParticipantCommand::new(8, &p2, "turn_timeout", 3);
    assert_eq!(
        SystemCommand::KickParticipant(kick)
            .event_budget(timeout.state())
            .maximum(),
        1
    );

    let kicked = GameEngine::apply_system_owned(
        timeout.state().clone(),
        SystemContext::canonical(&map, rules),
        SystemCommand::KickParticipant(kick),
    )
    .expect("kick");
    assert!(kicked.is_accepted());
    let [DomainEvent::PlayerKicked(kicked_event)] = kicked.events() else {
        panic!("player kicked event")
    };
    assert_eq!(kicked_event.turn(), 8);
    assert_eq!(kicked_event.player_id(), &p2);
    assert_eq!(kicked_event.reason(), "turn_timeout");
    assert_eq!(kicked_event.timeout_streak(), 3);
    let _ = (kicked.map_hash(), kicked.ruleset_hash());
    let lifecycle = kicked.state().match_lifecycle().turn();
    assert!(lifecycle.kicked_player_ids().contains(&p2));
    assert!(lifecycle.afk_player_ids().contains(&p2));
    assert!(!lifecycle.required_submission_player_ids().contains(&p2));

    let repeated_kick = GameEngine::apply_system_owned(
        kicked.state().clone(),
        SystemContext::canonical(&map, rules),
        SystemCommand::KickParticipant(KickParticipantCommand::new(9, &p2, "turn_timeout", 3)),
    )
    .expect("repeated kick");
    assert!(repeated_kick.is_accepted());
    assert_eq!(repeated_kick.revision(), StateRevision::new(9));
    assert!(repeated_kick.events().is_empty());
}

#[test]
fn authenticated_resignation_ends_a_two_player_match_canonically() {
    let map = map();
    let rules = RulesetDefinition::standard();
    let resigning = player("player-1");
    let winner = player("player-2");
    let initial = state(GameMode::Multiplayer, [], None);
    let command = SystemCommand::ResignParticipant(ResignParticipantCommand::new(7, &resigning));
    assert_eq!(command.event_budget(&initial).maximum(), 2);

    let transition =
        GameEngine::apply_system_owned(initial, SystemContext::canonical(&map, rules), command)
            .expect("resignation");

    assert!(transition.is_accepted());
    assert_eq!(transition.revision(), StateRevision::new(8));
    assert!(matches!(
        transition.events(),
        [DomainEvent::PlayerResigned(_), DomainEvent::MatchEnded(_)]
    ));
    let lifecycle = transition.state().match_lifecycle().turn();
    assert!(lifecycle.resigned_player_ids().contains(&resigning));
    assert!(!lifecycle.kicked_player_ids().contains(&resigning));
    assert_eq!(
        lifecycle.turn_states_by_player_id().get(&resigning),
        Some(&PlayerTurnState::Finished)
    );
    assert_eq!(
        transition.state().outcome().condition(),
        GameOutcomeCondition::Resignation
    );
    assert_eq!(
        transition.state().outcome().winner_player_id(),
        Some(&winner)
    );
}

#[test]
fn resignation_waits_for_one_remaining_participant() {
    let map = map();
    let rules = RulesetDefinition::standard();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let p3 = player("player-3");
    let initial = three_player_state(&[p1.clone(), p2.clone(), p3.clone()]);

    let first = GameEngine::apply_system_owned(
        initial,
        SystemContext::canonical(&map, rules),
        SystemCommand::ResignParticipant(ResignParticipantCommand::new(7, &p1)),
    )
    .expect("first resignation");
    assert!(first.is_accepted());
    assert_eq!(
        first.state().outcome().condition(),
        GameOutcomeCondition::Ongoing
    );
    assert!(matches!(first.events(), [DomainEvent::PlayerResigned(_)]));

    let second = GameEngine::apply_system_owned(
        first.state().clone(),
        SystemContext::canonical(&map, rules),
        SystemCommand::ResignParticipant(ResignParticipantCommand::new(8, &p2)),
    )
    .expect("second resignation");
    assert!(second.is_accepted());
    assert_eq!(
        second.state().outcome().condition(),
        GameOutcomeCondition::Resignation
    );
    assert_eq!(second.state().outcome().winner_player_id(), Some(&p3));
    assert!(matches!(
        second.events(),
        [DomainEvent::PlayerResigned(_), DomainEvent::MatchEnded(_)]
    ));
}

fn three_player_state(players: &[PlayerId; 3]) -> GameState {
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [
            participant(players[0].clone(), "One"),
            participant(players[1].clone(), "Two"),
            participant(players[2].clone(), "Three"),
        ],
        GameMode::Multiplayer,
    )
    .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (players[0].clone(), PlayerTurnState::Active),
            (players[1].clone(), PlayerTurnState::Active),
            (players[2].clone(), PlayerTurnState::Active),
        ]),
        players.clone(),
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("turn lifecycle");
    GameState::builder(
        StateRevision::new(7),
        7,
        map().bounds(),
        UnitOccupancyPolicy::Exclusive,
        [],
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state")
}

fn assert_system_command_rejections(
    map: &MapDefinition,
    rules: &RulesetDefinition,
    p1: &PlayerId,
    p2: &PlayerId,
    submitted: GameState,
    timeout_state: &GameState,
) {
    let time = UtcTimestamp::new("2026-08-24T12:00:00Z").expect("UTC");
    let stale_timeout = GameEngine::apply_system_owned(
        submitted,
        SystemContext::canonical(map, rules),
        SystemCommand::FinalizeTimedOutTurn(FinalizeTimedOutTurnCommand::new(
            6,
            &[p1.clone(), p2.clone()],
            std::slice::from_ref(p2),
            Some(&time),
        )),
    )
    .expect("stale timeout");
    assert_eq!(
        stale_timeout.rejection().expect("rejection").code(),
        CommandRejectionCode::StaleRevision
    );

    let stale_kick = GameEngine::apply_system_owned(
        timeout_state.clone(),
        SystemContext::canonical(map, rules),
        SystemCommand::KickParticipant(KickParticipantCommand::new(7, p2, "turn_timeout", 3)),
    )
    .expect("stale kick");
    assert_eq!(
        stale_kick.rejection().expect("rejection").code(),
        CommandRejectionCode::StaleRevision
    );

    let missing = player("missing-player");
    let missing_kick = GameEngine::apply_system_owned(
        timeout_state.clone(),
        SystemContext::canonical(map, rules),
        SystemCommand::KickParticipant(KickParticipantCommand::new(8, &missing, "turn_timeout", 3)),
    )
    .expect("missing participant kick");
    assert_eq!(
        missing_kick.rejection().expect("rejection").code(),
        CommandRejectionCode::TurnPlayerNotActive
    );
}
