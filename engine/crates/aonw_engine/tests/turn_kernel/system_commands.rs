use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{GameMode, GameState, PlayerId, StateRevision, UtcTimestamp};
use aonw_engine::{
    CommandRejectionCode, DomainEvent, FinalizeTimedOutTurnCommand, GameEngine,
    KickParticipantCommand, SystemCommand, SystemContext,
};

use super::{map, player, state};

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
