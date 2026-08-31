use aonw_contracts::{
    DiplomaticMessageResponseDto, DiplomaticMessageTopicDto, DiplomaticProposalKindDto,
};
use aonw_domain::{
    DiplomaticMessageResponse, DiplomaticMessageTopic, DiplomaticProposalKind,
    DiplomaticScoreChangeReason,
};

use super::{
    decode_message_response, decode_message_topic, decode_proposal_kind, encode_message_category,
    encode_message_response, encode_message_topic, encode_proposal_kind, encode_score_reason,
};

#[test]
fn proposal_kind_mapping_is_bijective_and_total() {
    for (domain, dto) in [
        (
            DiplomaticProposalKind::Friendship,
            DiplomaticProposalKindDto::Friendship,
        ),
        (
            DiplomaticProposalKind::Truce,
            DiplomaticProposalKindDto::Truce,
        ),
    ] {
        assert_eq!(encode_proposal_kind(domain), dto);
        assert_eq!(decode_proposal_kind(dto), domain);
    }
}

#[test]
fn message_mapping_is_bijective_and_total() {
    for (domain, dto) in [
        (
            DiplomaticMessageTopic::TroopsNearCities,
            DiplomaticMessageTopicDto::TroopsNearCities,
        ),
        (
            DiplomaticMessageTopic::CitiesTooClose,
            DiplomaticMessageTopicDto::CitiesTooClose,
        ),
        (
            DiplomaticMessageTopic::BlockedRoutes,
            DiplomaticMessageTopicDto::BlockedRoutes,
        ),
        (
            DiplomaticMessageTopic::WithdrawScouts,
            DiplomaticMessageTopicDto::WithdrawScouts,
        ),
        (
            DiplomaticMessageTopic::AvoidEscalation,
            DiplomaticMessageTopicDto::AvoidEscalation,
        ),
        (
            DiplomaticMessageTopic::CommonEnemy,
            DiplomaticMessageTopicDto::CommonEnemy,
        ),
        (
            DiplomaticMessageTopic::ExpansionProvocation,
            DiplomaticMessageTopicDto::ExpansionProvocation,
        ),
        (
            DiplomaticMessageTopic::PeacefulPraise,
            DiplomaticMessageTopicDto::PeacefulPraise,
        ),
    ] {
        assert_eq!(encode_message_topic(domain), dto);
        assert_eq!(decode_message_topic(dto), domain);
        let _ = encode_message_category(domain.category());
    }
    for (domain, dto) in [
        (
            DiplomaticMessageResponse::Conciliatory,
            DiplomaticMessageResponseDto::Conciliatory,
        ),
        (
            DiplomaticMessageResponse::Neutral,
            DiplomaticMessageResponseDto::Neutral,
        ),
        (
            DiplomaticMessageResponse::Evasive,
            DiplomaticMessageResponseDto::Evasive,
        ),
        (
            DiplomaticMessageResponse::Aggressive,
            DiplomaticMessageResponseDto::Aggressive,
        ),
    ] {
        assert_eq!(encode_message_response(domain), dto);
        assert_eq!(decode_message_response(dto), domain);
    }
}

#[test]
fn score_reason_mapping_covers_every_domain_value() {
    for value in [
        DiplomaticScoreChangeReason::Manual,
        DiplomaticScoreChangeReason::UnitAttack,
        DiplomaticScoreChangeReason::CityAttack,
        DiplomaticScoreChangeReason::DeclarationOfWar,
        DiplomaticScoreChangeReason::WarmongerPenalty,
        DiplomaticScoreChangeReason::ProposalAccepted,
        DiplomaticScoreChangeReason::ProposalRejected,
        DiplomaticScoreChangeReason::MessageResponse,
        DiplomaticScoreChangeReason::CommonEnemyCooperation,
        DiplomaticScoreChangeReason::GoldGift,
        DiplomaticScoreChangeReason::PromiseBroken,
    ] {
        let _ = encode_score_reason(value);
    }
}
