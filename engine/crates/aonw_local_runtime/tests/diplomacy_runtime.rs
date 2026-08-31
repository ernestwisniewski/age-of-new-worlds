//! Current-only diplomacy proposal protocol, replay, and disclosure coverage.

use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_contracts::client::{
    ClientCommandDto, ClientCommandOutcomeDto, ClientEventDto, ClientFeatureDto,
    ClientRequestBodyDto, ClientResponseBodyDto,
};
use aonw_contracts::{DiplomaticProposalKindDto, ResourceTypeDto};
use aonw_domain::{
    DiplomaticMessage, DiplomaticMessageCategory, DiplomaticMessageTopic, DiplomaticProposal,
    DiplomaticProposalKind,
};
use aonw_local_runtime::LocalRuntime;

#[path = "diplomacy_runtime/fixture.rs"]
mod fixture;

use fixture::{
    dispatch, dispatch_body, map, open_runtime, player, resource_trade_state, state,
    state_with_message, verify_one_entry,
};

#[test]
fn proposal_commands_are_recipient_safe_and_replayable() {
    let ruleset = RulesetDefinition::standard().clone();
    let map = map();
    let p1 = player("player-1");
    let p2 = player("player-2");

    let mut sender = open_runtime(&map, &ruleset, state(None), p1.clone());
    let capabilities = dispatch_body(&mut sender, ClientRequestBodyDto::Capabilities);
    let ClientResponseBodyDto::Capabilities { features } = capabilities else {
        panic!("capabilities")
    };
    assert!(features.contains(&ClientFeatureDto::Diplomacy));
    let sent = dispatch(
        &mut sender,
        ClientCommandDto::SendDiplomaticProposal {
            expected_revision: 11,
            target_player_id: p2.as_str().to_owned(),
            kind: DiplomaticProposalKindDto::Friendship,
            proposal_id: Some("friendship-1".to_owned()),
            gold_payment: 99,
        },
    );
    assert_eq!(sent.outcome, ClientCommandOutcomeDto::Accepted);
    assert_eq!(sent.stamp.revision, 12);
    assert!(matches!(
        sent.events.as_slice(),
        [ClientEventDto::DiplomaticProposalSent {
            proposal_id,
            from_player_id,
            to_player_id,
            kind: DiplomaticProposalKindDto::Friendship,
            expires_on_turn: 12,
        }] if proposal_id == "friendship-1"
            && from_player_id == p1.as_str()
            && to_player_id == p2.as_str()
    ));
    verify_one_entry(&sender, map.clone(), ruleset.clone());

    let proposal = DiplomaticProposal::try_new(
        "friendship-1".to_owned(),
        p1.clone(),
        p2.clone(),
        DiplomaticProposalKind::Friendship,
        7,
        12,
        0,
    )
    .expect("proposal");
    let mut recipient = open_runtime(&map, &ruleset, state(Some(proposal)), p2.clone());
    let responded = dispatch(
        &mut recipient,
        ClientCommandDto::RespondDiplomaticProposal {
            expected_revision: 11,
            proposal_id: "friendship-1".to_owned(),
            accepted: false,
        },
    );
    assert_eq!(responded.outcome, ClientCommandOutcomeDto::Accepted);
    assert!(matches!(
        responded.events.as_slice(),
        [
            ClientEventDto::DiplomaticProposalResponded {
                proposal_id,
                accepted: false,
                ..
            },
            ClientEventDto::DiplomaticScoreChanged { delta: -6, .. }
        ] if proposal_id == "friendship-1"
    ));
    verify_one_entry(&recipient, map, ruleset);
}

#[test]
fn message_commands_are_recipient_safe_and_replayable() {
    let ruleset = RulesetDefinition::standard().clone();
    let map = map();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let mut sender = open_runtime(&map, &ruleset, state(None), p1.clone());
    let sent = dispatch(
        &mut sender,
        ClientCommandDto::SendDiplomaticMessage {
            expected_revision: 11,
            target_player_id: p2.as_str().to_owned(),
            topic: aonw_contracts::DiplomaticMessageTopicDto::WithdrawScouts,
            message_id: Some("withdraw-1".to_owned()),
        },
    );
    assert_eq!(sent.outcome, ClientCommandOutcomeDto::Accepted);
    assert!(matches!(
        sent.events.as_slice(),
        [ClientEventDto::DiplomaticMessageSent {
            message_id,
            category: aonw_contracts::DiplomaticMessageCategoryDto::Request,
            ..
        }] if message_id == "withdraw-1"
    ));
    verify_one_entry(&sender, map.clone(), ruleset.clone());

    let message = DiplomaticMessage::try_new(
        "withdraw-1".to_owned(),
        p1,
        p2.clone(),
        DiplomaticMessageTopic::WithdrawScouts,
        DiplomaticMessageCategory::Request,
        7,
        12,
        None,
        None,
        0,
        None,
        None,
        false,
    )
    .expect("message");
    let mut recipient = open_runtime(&map, &ruleset, state_with_message(message), p2);
    let responded = dispatch(
        &mut recipient,
        ClientCommandDto::RespondDiplomaticMessage {
            expected_revision: 11,
            message_id: "withdraw-1".to_owned(),
            response: aonw_contracts::DiplomaticMessageResponseDto::Conciliatory,
        },
    );
    assert_eq!(responded.outcome, ClientCommandOutcomeDto::Accepted);
    assert!(matches!(
        responded.events.as_slice(),
        [
            ClientEventDto::DiplomaticMessageResponded {
                message_id,
                response: aonw_contracts::DiplomaticMessageResponseDto::Conciliatory,
                relation_delta: 12,
                promise_due_turn: Some(10),
                ..
            },
            ClientEventDto::DiplomaticScoreChanged { delta: 12, .. }
        ] if message_id == "withdraw-1"
    ));
    verify_one_entry(&recipient, map, ruleset);
}

#[test]
fn war_and_gold_gift_are_atomic_and_replayable() {
    let ruleset = RulesetDefinition::standard().clone();
    let map = map();
    let p1 = player("player-1");
    let p2 = player("player-2");

    let mut gifting = open_runtime(&map, &ruleset, state(None), p1.clone());
    let gifted = dispatch(
        &mut gifting,
        ClientCommandDto::SendGoldGift {
            expected_revision: 11,
            target_player_id: p2.as_str().to_owned(),
            amount: 10,
        },
    );
    assert_eq!(gifted.outcome, ClientCommandOutcomeDto::Accepted);
    assert!(matches!(
        gifted.events.as_slice(),
        [ClientEventDto::DiplomaticScoreChanged {
            delta: 2,
            reason: aonw_contracts::DiplomaticScoreChangeReasonDto::GoldGift,
            source_id: Some(source),
            ..
        }] if source == "gold_gift.7.player-1.player-2"
    ));
    verify_one_entry(&gifting, map.clone(), ruleset.clone());

    let mut declaring = open_runtime(&map, &ruleset, state(None), p1);
    let war = dispatch(
        &mut declaring,
        ClientCommandDto::DeclareWar {
            expected_revision: 11,
            target_player_id: p2.as_str().to_owned(),
        },
    );
    assert_eq!(war.outcome, ClientCommandOutcomeDto::Accepted);
    assert!(matches!(
        war.events.as_slice(),
        [
            ClientEventDto::DiplomaticRelationChanged {
                new_status: aonw_contracts::DiplomaticRelationStatusDto::War,
                reason: aonw_contracts::DiplomaticRelationChangeReasonDto::DeclarationOfWar,
                ..
            },
            ClientEventDto::DiplomaticScoreChanged {
                delta: -25,
                reason: aonw_contracts::DiplomaticScoreChangeReasonDto::DeclarationOfWar,
                source_id: None,
                ..
            }
        ]
    ));
    verify_one_entry(&declaring, map, ruleset);
}

#[test]
fn resource_trade_commands_are_persisted_and_replayable() {
    let ruleset = RulesetDefinition::standard().clone();
    let map = map();
    let p1 = player("player-1");
    let p2 = player("player-2");

    let mut trade_runtime = open_runtime(&map, &ruleset, resource_trade_state(), p1.clone());
    let opened = dispatch(
        &mut trade_runtime,
        ClientCommandDto::OpenResourceTrade {
            expected_revision: 11,
            target_player_id: p2.as_str().to_owned(),
            resource: ResourceTypeDto::Marble,
            gold_per_turn: 3,
            duration_turns: 5,
            agreement_id: None,
        },
    );
    assert_eq!(opened.outcome, ClientCommandOutcomeDto::Accepted);
    assert!(opened.events.is_empty());
    let diplomacy = opened
        .view_patch
        .diplomacy
        .as_ref()
        .expect("resource agreement patch");
    assert_eq!(diplomacy.resource_trade_agreements.len(), 1);
    assert_eq!(
        diplomacy.resource_trade_agreements[0].id,
        "resource_trade_player-1_player-2_marble_0"
    );
    let snapshot = dispatch_body(&mut trade_runtime, ClientRequestBodyDto::Snapshot);
    let ClientResponseBodyDto::Snapshot { snapshot } = snapshot else {
        panic!("snapshot")
    };
    assert_eq!(snapshot.diplomacy.resource_trade_agreements.len(), 1);
    let save = trade_runtime.export_save_json().expect("save");
    assert!(save.contains("resource_trade_player-1_player-2_marble_0"));
    assert_save_reopens(&mut trade_runtime, map.clone(), ruleset.clone(), &save);
    verify_one_entry(&trade_runtime, map.clone(), ruleset.clone());

    let mut exchange_runtime = open_runtime(&map, &ruleset, resource_trade_state(), p1);
    let exchanged = dispatch(
        &mut exchange_runtime,
        ClientCommandDto::OpenResourceExchange {
            expected_revision: 11,
            target_player_id: p2.as_str().to_owned(),
            offered_resource: ResourceTypeDto::Iron,
            requested_resource: ResourceTypeDto::Marble,
            duration_turns: 6,
            agreement_id: Some("exchange-1".to_owned()),
        },
    );
    assert_eq!(exchanged.outcome, ClientCommandOutcomeDto::Accepted);
    assert_eq!(
        exchanged
            .view_patch
            .diplomacy
            .as_ref()
            .expect("exchange patch")
            .resource_trade_agreements
            .len(),
        2
    );
    let save = exchange_runtime.export_save_json().expect("save");
    assert!(save.contains("exchange-1_offered"));
    assert!(save.contains("exchange-1_requested"));
    assert_save_reopens(&mut exchange_runtime, map.clone(), ruleset.clone(), &save);
    verify_one_entry(&exchange_runtime, map, ruleset);
}

fn assert_save_reopens(
    runtime: &mut LocalRuntime,
    map: MapDefinition,
    ruleset: RulesetDefinition,
    save: &str,
) {
    let expected = runtime.snapshot().expect("source snapshot");
    let mut reopened = LocalRuntime::default();
    reopened
        .open_save_json(map, ruleset, save)
        .expect("reopen diplomacy save");
    assert_eq!(reopened.snapshot().expect("reopened snapshot"), expected);
}
