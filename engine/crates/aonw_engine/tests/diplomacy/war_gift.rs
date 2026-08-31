use aonw_content::RulesetDefinition;
use aonw_domain::{DiplomaticRelationStatus, DiplomaticScoreChangeReason};
use aonw_engine::{
    CommandRejectionCode, DeclareWarCommand, DomainEvent, EngineContext, GameEngine, PlayerCommand,
    SendGoldGiftCommand,
};

use super::{fixture, fixture_with_observer};

#[test]
fn declaration_of_war_updates_relation_cleans_pair_and_penalizes_known_observers() {
    let fixture = fixture_with_observer(None, true, (20, 1), false, true);
    let transition = GameEngine::apply_player_owned(
        fixture.state.clone(),
        EngineContext::canonical(&fixture.p1, &fixture.map, RulesetDefinition::standard()),
        PlayerCommand::DeclareWar(DeclareWarCommand::new(11, &fixture.p2)),
    )
    .expect("declare war");
    assert!(transition.is_accepted());
    let relation = transition
        .state()
        .diplomacy()
        .relation_between(&fixture.p1, &fixture.p2)
        .expect("war relation");
    assert_eq!(relation.status(), DiplomaticRelationStatus::War);
    assert_eq!(relation.relation_score(), -25);
    let observer = transition
        .state()
        .diplomacy()
        .relation_between(&fixture.p1, &fixture.p3)
        .expect("observer relation");
    assert_eq!(observer.relation_score(), -8);
    assert!(matches!(
        transition.events(),
        [
            DomainEvent::DiplomaticRelationChanged(relation),
            DomainEvent::DiplomaticScoreChanged(primary),
            DomainEvent::DiplomaticScoreChanged(observer)
        ] if relation.old_status() == DiplomaticRelationStatus::Neutral
            && relation.new_status() == DiplomaticRelationStatus::War
            && primary.delta() == -25
            && primary.reason() == DiplomaticScoreChangeReason::DeclarationOfWar
            && primary.source_id().is_none()
            && observer.delta() == -8
            && observer.reason() == DiplomaticScoreChangeReason::WarmongerPenalty
            && observer.source_id()
                == Some("warmonger.7.declarationOfWar.player-1.player-2")
    ));
}

#[test]
fn declaration_of_war_rejections_preserve_precedence_and_state() {
    let hidden = fixture(None, false, (20, 1), false);
    let stale = apply_war(hidden.state.clone(), &hidden, 10);
    assert_rejected(&stale, CommandRejectionCode::StaleRevision, &hidden.state);
    let undiscovered = apply_war(hidden.state.clone(), &hidden, 11);
    assert_rejected(
        &undiscovered,
        CommandRejectionCode::DiplomacyTargetNotDiscovered,
        &hidden.state,
    );

    let truce = fixture(Some(DiplomaticRelationStatus::Truce), true, (20, 1), false);
    let protected = apply_war(truce.state.clone(), &truce, 11);
    assert_rejected(
        &protected,
        CommandRejectionCode::DiplomacyTruceActive,
        &truce.state,
    );

    let war = fixture(Some(DiplomaticRelationStatus::War), true, (20, 1), false);
    let repeated = apply_war(war.state.clone(), &war, 11);
    assert_rejected(
        &repeated,
        CommandRejectionCode::DiplomacyWarAlreadyActive,
        &war.state,
    );
}

#[test]
fn gold_gift_transfers_atomically_scores_and_enforces_cooldown() {
    let fixture = fixture(None, true, (20, 1), false);
    let gifted = apply_gift(fixture.state.clone(), &fixture, 11, 10);
    assert!(gifted.is_accepted());
    assert_eq!(
        gifted.state().economy().player_gold().get(&fixture.p1),
        Some(&10)
    );
    assert_eq!(
        gifted.state().economy().player_gold().get(&fixture.p2),
        Some(&11)
    );
    let relation = gifted
        .state()
        .diplomacy()
        .relation_between(&fixture.p1, &fixture.p2)
        .expect("gift relation");
    assert_eq!(relation.relation_score(), 2);
    assert!(matches!(
        gifted.events(),
        [DomainEvent::DiplomaticScoreChanged(event)]
            if event.delta() == 2
                && event.reason() == DiplomaticScoreChangeReason::GoldGift
                && event.source_id() == Some("gold_gift.7.player-1.player-2")
    ));

    let cooldown = apply_gift(gifted.state().clone(), &fixture, 12, 5);
    assert_rejected(
        &cooldown,
        CommandRejectionCode::DiplomacyGoldGiftUnavailable,
        gifted.state(),
    );
}

#[test]
fn gold_gift_rejections_follow_the_defined_precedence() {
    let war = fixture(Some(DiplomaticRelationStatus::War), true, (20, 1), false);
    let negative = apply_gift(war.state.clone(), &war, 11, -1);
    assert_rejected(
        &negative,
        CommandRejectionCode::DiplomacyInvalidGoldAmount,
        &war.state,
    );
    let blocked = apply_gift(war.state.clone(), &war, 11, 10);
    assert_rejected(
        &blocked,
        CommandRejectionCode::DiplomacyGoldGiftBlockedByRelation,
        &war.state,
    );

    let neutral = fixture(None, true, (20, 1), false);
    let unavailable = apply_gift(neutral.state.clone(), &neutral, 11, 50);
    assert_rejected(
        &unavailable,
        CommandRejectionCode::DiplomacyGoldUnavailable,
        &neutral.state,
    );
    let too_small = apply_gift(neutral.state.clone(), &neutral, 11, 4);
    assert_rejected(
        &too_small,
        CommandRejectionCode::DiplomacyGoldGiftUnavailable,
        &neutral.state,
    );
}

fn apply_war(
    state: aonw_domain::GameState,
    fixture: &super::Fixture,
    expected_revision: u64,
) -> aonw_engine::DomainTransition {
    GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&fixture.p1, &fixture.map, RulesetDefinition::standard()),
        PlayerCommand::DeclareWar(DeclareWarCommand::new(expected_revision, &fixture.p2)),
    )
    .expect("war transition")
}

fn apply_gift(
    state: aonw_domain::GameState,
    fixture: &super::Fixture,
    expected_revision: u64,
    amount: i64,
) -> aonw_engine::DomainTransition {
    GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&fixture.p1, &fixture.map, RulesetDefinition::standard()),
        PlayerCommand::SendGoldGift(SendGoldGiftCommand::new(
            expected_revision,
            &fixture.p2,
            amount,
        )),
    )
    .expect("gift transition")
}

fn assert_rejected(
    transition: &aonw_engine::DomainTransition,
    code: CommandRejectionCode,
    expected_state: &aonw_domain::GameState,
) {
    assert_eq!(transition.rejection().expect("rejection").code(), code);
    assert_eq!(transition.state(), expected_state);
}
