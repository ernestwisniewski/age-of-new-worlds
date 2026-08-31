use crate::{
    encode_message_category, encode_message_response, encode_message_topic, encode_proposal_kind,
    encode_relation_reason, encode_relation_status, encode_resource,
};
use aonw_contracts::client::{
    PlayerDiplomacyViewDto, PlayerDiplomaticMessageViewDto, PlayerDiplomaticProposalViewDto,
    PlayerDiplomaticRelationViewDto, PlayerResourceTradeAgreementViewDto,
};

use aonw_projection::{
    PlayerDiplomacyView, PlayerDiplomaticMessageView, PlayerDiplomaticProposalView,
    PlayerDiplomaticRelationView, PlayerResourceTradeAgreementView,
};

pub(super) fn diplomacy(value: &PlayerDiplomacyView) -> PlayerDiplomacyViewDto {
    PlayerDiplomacyViewDto {
        relations: value.relations().iter().map(relation).collect(),
        proposals: value.proposals().iter().map(proposal).collect(),
        messages: value.messages().iter().map(message).collect(),
        resource_trade_agreements: value
            .resource_trade_agreements()
            .iter()
            .map(agreement)
            .collect(),
    }
}

fn relation(value: &PlayerDiplomaticRelationView) -> PlayerDiplomaticRelationViewDto {
    PlayerDiplomaticRelationViewDto {
        counterpart_player_id: value.counterpart_player_id().as_str().to_owned(),
        status: encode_relation_status(value.status()),
        relation_score: value.relation_score(),
        status_expires_on_turn: value.status_expires_on_turn(),
        last_changed_turn: value.last_changed_turn(),
        last_change_reason: value.last_change_reason().map(encode_relation_reason),
    }
}

fn proposal(value: &PlayerDiplomaticProposalView) -> PlayerDiplomaticProposalViewDto {
    PlayerDiplomaticProposalViewDto {
        id: value.id().to_owned(),
        from_player_id: value.from_player_id().as_str().to_owned(),
        to_player_id: value.to_player_id().as_str().to_owned(),
        kind: encode_proposal_kind(value.kind()),
        created_turn: value.created_turn(),
        expires_on_turn: value.expires_on_turn(),
        gold_payment: value.gold_payment(),
    }
}

fn message(value: &PlayerDiplomaticMessageView) -> PlayerDiplomaticMessageViewDto {
    PlayerDiplomaticMessageViewDto {
        id: value.id().to_owned(),
        from_player_id: value.from_player_id().as_str().to_owned(),
        to_player_id: value.to_player_id().as_str().to_owned(),
        topic: encode_message_topic(value.topic()),
        category: encode_message_category(value.category()),
        created_turn: value.created_turn(),
        expires_on_turn: value.expires_on_turn(),
        response: value.response().map(encode_message_response),
        responded_turn: value.responded_turn(),
        relation_score_delta: value.relation_score_delta(),
        relation_score_after: value.relation_score_after(),
        promise_due_turn: value.promise_due_turn(),
        promise_broken: value.promise_broken(),
    }
}

fn agreement(value: &PlayerResourceTradeAgreementView) -> PlayerResourceTradeAgreementViewDto {
    PlayerResourceTradeAgreementViewDto {
        id: value.id().to_owned(),
        exporter_player_id: value.exporter_player_id().as_str().to_owned(),
        importer_player_id: value.importer_player_id().as_str().to_owned(),
        resource: encode_resource(value.resource()),
        gold_per_turn: value.gold_per_turn(),
        remaining_turns: value.remaining_turns(),
        amount_per_turn: value.amount_per_turn(),
        exchange_group_id: value.exchange_group_id().map(str::to_owned),
    }
}
