use aonw_content::RulesetDefinition;
use aonw_domain::{
    DiplomaticMessageCategory, DiplomaticMessageResponse, DiplomaticMessageTopic,
    DiplomaticRelationStatus,
};
use aonw_engine::{
    CommandRejectionCode, DomainEvent, EngineContext, GameEngine, PlayerCommand,
    RespondDiplomaticMessageCommand, SendDiplomaticMessageCommand,
};

use super::fixture;

#[test]
fn private_message_is_deterministic_category_cooled_and_duplicate_safe() {
    let fixture = fixture(None, true, (20, 1), false);
    let sent = GameEngine::apply_player_owned(
        fixture.state.clone(),
        EngineContext::canonical(&fixture.p1, &fixture.map, RulesetDefinition::standard()),
        PlayerCommand::SendDiplomaticMessage(SendDiplomaticMessageCommand::new(
            11,
            &fixture.p2,
            DiplomaticMessageTopic::TroopsNearCities,
            Some("warning-1"),
        )),
    )
    .expect("send message");
    assert!(sent.is_accepted());
    let message = sent
        .state()
        .diplomacy()
        .message("warning-1")
        .expect("message");
    assert_eq!(message.category(), DiplomaticMessageCategory::Warning);
    assert_eq!(message.expires_on_turn(), 12);
    assert!(matches!(
        sent.events(),
        [DomainEvent::DiplomaticMessageSent(event)]
            if event.message_id() == "warning-1"
                && event.from_player_id() == &fixture.p1
                && event.to_player_id() == &fixture.p2
    ));

    let cooldown = GameEngine::apply_player_owned(
        sent.state().clone(),
        EngineContext::canonical(&fixture.p1, &fixture.map, RulesetDefinition::standard()),
        PlayerCommand::SendDiplomaticMessage(SendDiplomaticMessageCommand::new(
            12,
            &fixture.p2,
            DiplomaticMessageTopic::TroopsNearCities,
            Some("warning-2"),
        )),
    )
    .expect("cooldown rejection");
    assert_eq!(
        cooldown.rejection().expect("rejection").code(),
        CommandRejectionCode::DiplomacyMessageCooldown
    );
    assert_eq!(cooldown.state(), sent.state());

    let duplicate = GameEngine::apply_player_owned(
        sent.state().clone(),
        EngineContext::canonical(&fixture.p1, &fixture.map, RulesetDefinition::standard()),
        PlayerCommand::SendDiplomaticMessage(SendDiplomaticMessageCommand::new(
            12,
            &fixture.p2,
            DiplomaticMessageTopic::BlockedRoutes,
            Some("warning-1"),
        )),
    )
    .expect("duplicate rejection");
    assert_eq!(
        duplicate.rejection().expect("rejection").code(),
        CommandRejectionCode::DiplomacyDuplicateMessage
    );
    assert_eq!(duplicate.state(), sent.state());
}

#[test]
fn conciliatory_response_updates_score_and_creates_withdrawal_promise() {
    let fixture = fixture(
        Some(DiplomaticRelationStatus::Neutral),
        true,
        (20, 1),
        false,
    );
    let sent = GameEngine::apply_player_owned(
        fixture.state,
        EngineContext::canonical(&fixture.p1, &fixture.map, RulesetDefinition::standard()),
        PlayerCommand::SendDiplomaticMessage(SendDiplomaticMessageCommand::new(
            11,
            &fixture.p2,
            DiplomaticMessageTopic::WithdrawScouts,
            Some("withdraw-1"),
        )),
    )
    .expect("send message");
    let responded = GameEngine::apply_player_owned(
        sent.state().clone(),
        EngineContext::canonical(&fixture.p2, &fixture.map, RulesetDefinition::standard()),
        PlayerCommand::RespondDiplomaticMessage(RespondDiplomaticMessageCommand::new(
            12,
            "withdraw-1",
            DiplomaticMessageResponse::Conciliatory,
        )),
    )
    .expect("respond message");
    assert!(responded.is_accepted());
    let message = responded
        .state()
        .diplomacy()
        .message("withdraw-1")
        .expect("message");
    assert_eq!(
        message.response(),
        Some(DiplomaticMessageResponse::Conciliatory)
    );
    assert_eq!(message.responded_turn(), Some(7));
    assert_eq!(message.relation_score_delta(), 12);
    assert_eq!(message.relation_score_after(), Some(-8));
    assert_eq!(message.promise_due_turn(), Some(10));
    assert!(matches!(
        responded.events(),
        [
            DomainEvent::DiplomaticMessageResponded(event),
            DomainEvent::DiplomaticScoreChanged(_)
        ] if event.message_id() == "withdraw-1"
            && event.relation_delta() == 12
            && event.relation_score_after() == -8
            && event.promise_due_turn() == Some(10)
    ));

    let repeated = GameEngine::apply_player_owned(
        responded.state().clone(),
        EngineContext::canonical(&fixture.p2, &fixture.map, RulesetDefinition::standard()),
        PlayerCommand::RespondDiplomaticMessage(RespondDiplomaticMessageCommand::new(
            13,
            "withdraw-1",
            DiplomaticMessageResponse::Neutral,
        )),
    )
    .expect("unavailable rejection");
    assert_eq!(
        repeated.rejection().expect("rejection").code(),
        CommandRejectionCode::DiplomacyMessageUnavailable
    );
    assert_eq!(repeated.state(), responded.state());
}
