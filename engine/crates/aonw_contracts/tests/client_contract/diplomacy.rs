use aonw_contracts::client::{
    ClientCommandDto, ClientEventDto, ClientRequestBodyDto, PlayerDiplomacyViewDto,
    PlayerDiplomaticMessageViewDto, PlayerDiplomaticProposalViewDto,
    PlayerDiplomaticRelationViewDto, PlayerResourceTradeAgreementViewDto,
};
use aonw_contracts::{
    DiplomaticMessageCategoryDto, DiplomaticMessageResponseDto, DiplomaticMessageTopicDto,
    DiplomaticProposalKindDto, DiplomaticRelationChangeReasonDto, DiplomaticRelationStatusDto,
    ResourceTypeDto,
};

pub(super) fn requests() -> [ClientRequestBodyDto; 8] {
    [
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::DeclareWar {
                expected_revision: 8,
                target_player_id: "player-2".to_owned(),
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::SendGoldGift {
                expected_revision: 8,
                target_player_id: "player-2".to_owned(),
                amount: 10,
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::OpenResourceTrade {
                expected_revision: 8,
                target_player_id: "player-2".to_owned(),
                resource: ResourceTypeDto::Iron,
                gold_per_turn: 3,
                duration_turns: 5,
                agreement_id: None,
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::OpenResourceExchange {
                expected_revision: 8,
                target_player_id: "player-2".to_owned(),
                offered_resource: ResourceTypeDto::Iron,
                requested_resource: ResourceTypeDto::Horses,
                duration_turns: 5,
                agreement_id: None,
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::SendDiplomaticProposal {
                expected_revision: 8,
                target_player_id: "player-2".to_owned(),
                kind: DiplomaticProposalKindDto::Friendship,
                proposal_id: None,
                gold_payment: 0,
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::RespondDiplomaticProposal {
                expected_revision: 8,
                proposal_id: "proposal-1".to_owned(),
                accepted: true,
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::SendDiplomaticMessage {
                expected_revision: 8,
                target_player_id: "player-2".to_owned(),
                topic: DiplomaticMessageTopicDto::WithdrawScouts,
                message_id: None,
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::RespondDiplomaticMessage {
                expected_revision: 8,
                message_id: "message-1".to_owned(),
                response: DiplomaticMessageResponseDto::Conciliatory,
            },
        },
    ]
}

#[test]
fn diplomacy_events_round_trip_strictly() {
    let events = [
        ClientEventDto::DiplomaticProposalSent {
            proposal_id: "proposal-1".to_owned(),
            from_player_id: "player-1".to_owned(),
            to_player_id: "player-2".to_owned(),
            kind: DiplomaticProposalKindDto::Friendship,
            expires_on_turn: 12,
        },
        ClientEventDto::DiplomaticProposalResponded {
            proposal_id: "proposal-1".to_owned(),
            from_player_id: "player-1".to_owned(),
            to_player_id: "player-2".to_owned(),
            kind: DiplomaticProposalKindDto::Friendship,
            accepted: true,
        },
        ClientEventDto::DiplomaticProposalExpired {
            proposal_id: "proposal-1".to_owned(),
            from_player_id: "player-1".to_owned(),
            to_player_id: "player-2".to_owned(),
            kind: DiplomaticProposalKindDto::Friendship,
        },
        ClientEventDto::DiplomaticRelationChanged {
            player_a_id: "player-1".to_owned(),
            player_b_id: "player-2".to_owned(),
            old_status: DiplomaticRelationStatusDto::Neutral,
            new_status: DiplomaticRelationStatusDto::Friendly,
            reason: DiplomaticRelationChangeReasonDto::ProposalAccepted,
            expires_on_turn: None,
        },
        ClientEventDto::DiplomaticMessageSent {
            message_id: "message-1".to_owned(),
            from_player_id: "player-1".to_owned(),
            to_player_id: "player-2".to_owned(),
            topic: DiplomaticMessageTopicDto::WithdrawScouts,
            category: DiplomaticMessageCategoryDto::Request,
            expires_on_turn: 12,
        },
        ClientEventDto::DiplomaticMessageResponded {
            message_id: "message-1".to_owned(),
            from_player_id: "player-1".to_owned(),
            to_player_id: "player-2".to_owned(),
            topic: DiplomaticMessageTopicDto::WithdrawScouts,
            response: DiplomaticMessageResponseDto::Conciliatory,
            relation_delta: 12,
            relation_score_after: 12,
            promise_due_turn: Some(10),
        },
        ClientEventDto::DiplomaticPromiseBroken {
            message_id: "message-1".to_owned(),
            player_a_id: "player-1".to_owned(),
            player_b_id: "player-2".to_owned(),
            delta: -15,
            score_after: -3,
        },
    ];

    for event in events {
        let encoded = serde_json::to_string(&event).expect("client event JSON");
        assert_eq!(
            serde_json::from_str::<ClientEventDto>(&encoded).expect("client event"),
            event
        );
        let unknown = encoded.replacen('}', ",\"unexpectedField\":true}", 1);
        assert!(serde_json::from_str::<ClientEventDto>(&unknown).is_err());
    }
}

#[test]
fn recipient_diplomacy_view_round_trips_strictly_without_score_history() {
    let view = PlayerDiplomacyViewDto {
        relations: vec![PlayerDiplomaticRelationViewDto {
            counterpart_player_id: "player-2".to_owned(),
            status: DiplomaticRelationStatusDto::Friendly,
            relation_score: 12,
            status_expires_on_turn: None,
            last_changed_turn: Some(7),
            last_change_reason: Some(DiplomaticRelationChangeReasonDto::ProposalAccepted),
        }],
        proposals: vec![PlayerDiplomaticProposalViewDto {
            id: "proposal-1".to_owned(),
            from_player_id: "player-1".to_owned(),
            to_player_id: "player-2".to_owned(),
            kind: DiplomaticProposalKindDto::Friendship,
            created_turn: 7,
            expires_on_turn: 12,
            gold_payment: 0,
        }],
        messages: vec![PlayerDiplomaticMessageViewDto {
            id: "message-1".to_owned(),
            from_player_id: "player-2".to_owned(),
            to_player_id: "player-1".to_owned(),
            topic: DiplomaticMessageTopicDto::WithdrawScouts,
            category: DiplomaticMessageCategoryDto::Request,
            created_turn: 7,
            expires_on_turn: 12,
            response: Some(DiplomaticMessageResponseDto::Conciliatory),
            responded_turn: Some(8),
            relation_score_delta: 12,
            relation_score_after: Some(12),
            promise_due_turn: Some(10),
            promise_broken: false,
        }],
        resource_trade_agreements: vec![PlayerResourceTradeAgreementViewDto {
            id: "trade-1".to_owned(),
            exporter_player_id: "player-2".to_owned(),
            importer_player_id: "player-1".to_owned(),
            resource: ResourceTypeDto::Iron,
            gold_per_turn: 3,
            remaining_turns: 5,
            amount_per_turn: 1,
            exchange_group_id: None,
        }],
    };

    let encoded = serde_json::to_string(&view).expect("diplomacy view JSON");
    assert_eq!(
        serde_json::from_str::<PlayerDiplomacyViewDto>(&encoded).expect("diplomacy view"),
        view
    );
    assert!(!encoded.contains("scoreHistory"));
    let unknown = encoded.replacen('{', "{\"unexpectedField\":true,", 1);
    assert!(serde_json::from_str::<PlayerDiplomacyViewDto>(&unknown).is_err());
}
