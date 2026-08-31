use aonw_domain::{
    Diplomacy, DiplomaticMessageCategory, DiplomaticMessageResponse, DiplomaticMessageTopic,
    DiplomaticProposalKind, DiplomaticRelationChangeReason, DiplomaticRelationStatus,
    DiplomaticScoreChangeReason,
};

use super::{economy::resource_tag, writer::DigestWriter};

pub(super) fn hash_diplomacy(writer: &mut DigestWriter, state: &Diplomacy) {
    writer.usize(state.contacts().len());
    for pair in state.contacts() {
        hash_pair(writer, pair);
    }
    writer.usize(state.relations().len());
    for value in state.relations() {
        hash_pair(writer, value.pair());
        writer.u8(relation_status_tag(value.status()));
        writer.i64(value.relation_score());
        writer.optional_u32(value.status_expires_on_turn());
        writer.optional_u32(value.last_changed_turn());
        hash_optional_relation_reason(writer, value.last_change_reason());
    }
    writer.usize(state.pending_proposals().len());
    for value in state.pending_proposals() {
        writer.text(value.id());
        writer.text(value.from_player_id().as_str());
        writer.text(value.to_player_id().as_str());
        writer.u8(proposal_kind_tag(value.kind()));
        writer.u32(value.created_turn());
        writer.u32(value.expires_on_turn());
        writer.i64(value.gold_payment());
    }
    writer.usize(state.messages().len());
    for value in state.messages() {
        writer.text(value.id());
        writer.text(value.from_player_id().as_str());
        writer.text(value.to_player_id().as_str());
        writer.u8(message_topic_tag(value.topic()));
        writer.u8(message_category_tag(value.category()));
        writer.u32(value.created_turn());
        writer.u32(value.expires_on_turn());
        hash_optional_message_response(writer, value.response());
        writer.optional_u32(value.responded_turn());
        writer.i64(value.relation_score_delta());
        writer.optional_i64(value.relation_score_after());
        writer.optional_u32(value.promise_due_turn());
        writer.u8(u8::from(value.promise_broken()));
    }
    writer.usize(state.score_history().len());
    for value in state.score_history() {
        hash_pair(writer, value.pair());
        writer.u32(value.turn());
        writer.i64(value.delta());
        writer.i64(value.score_after());
        writer.u8(score_reason_tag(value.reason()));
        writer.optional_text(value.source_id());
    }
    writer.usize(state.resource_trade_agreements().len());
    for value in state.resource_trade_agreements() {
        writer.text(value.id());
        writer.text(value.exporter_player_id().as_str());
        writer.text(value.importer_player_id().as_str());
        writer.u8(resource_tag(value.resource()));
        writer.i64(value.gold_per_turn());
        writer.u32(value.remaining_turns());
        writer.u32(value.amount_per_turn());
        writer.optional_text(value.exchange_group_id());
    }
}

fn hash_pair(writer: &mut DigestWriter, pair: &aonw_domain::PlayerPair) {
    writer.text(pair.first().as_str());
    writer.text(pair.second().as_str());
}

fn hash_optional_relation_reason(
    writer: &mut DigestWriter,
    value: Option<DiplomaticRelationChangeReason>,
) {
    match value {
        None => writer.u8(0),
        Some(value) => {
            writer.u8(1);
            writer.u8(relation_reason_tag(value));
        }
    }
}

fn hash_optional_message_response(
    writer: &mut DigestWriter,
    value: Option<DiplomaticMessageResponse>,
) {
    match value {
        None => writer.u8(0),
        Some(value) => {
            writer.u8(1);
            writer.u8(message_response_tag(value));
        }
    }
}

const fn relation_status_tag(value: DiplomaticRelationStatus) -> u8 {
    match value {
        DiplomaticRelationStatus::Friendly => 0,
        DiplomaticRelationStatus::Neutral => 1,
        DiplomaticRelationStatus::Hostile => 2,
        DiplomaticRelationStatus::Truce => 3,
        DiplomaticRelationStatus::War => 4,
    }
}

const fn relation_reason_tag(value: DiplomaticRelationChangeReason) -> u8 {
    match value {
        DiplomaticRelationChangeReason::Manual => 0,
        DiplomaticRelationChangeReason::UnitAttack => 1,
        DiplomaticRelationChangeReason::CityAttack => 2,
        DiplomaticRelationChangeReason::DeclarationOfWar => 3,
        DiplomaticRelationChangeReason::ProposalAccepted => 4,
        DiplomaticRelationChangeReason::TruceExpired => 5,
        DiplomaticRelationChangeReason::MessageResponse => 6,
        DiplomaticRelationChangeReason::PromiseBroken => 7,
    }
}

const fn proposal_kind_tag(value: DiplomaticProposalKind) -> u8 {
    match value {
        DiplomaticProposalKind::Friendship => 0,
        DiplomaticProposalKind::Truce => 1,
    }
}

const fn message_category_tag(value: DiplomaticMessageCategory) -> u8 {
    match value {
        DiplomaticMessageCategory::Warning => 0,
        DiplomaticMessageCategory::Complaint => 1,
        DiplomaticMessageCategory::Request => 2,
        DiplomaticMessageCategory::Praise => 3,
        DiplomaticMessageCategory::Threat => 4,
        DiplomaticMessageCategory::Cooperation => 5,
    }
}

const fn message_topic_tag(value: DiplomaticMessageTopic) -> u8 {
    match value {
        DiplomaticMessageTopic::TroopsNearCities => 0,
        DiplomaticMessageTopic::CitiesTooClose => 1,
        DiplomaticMessageTopic::BlockedRoutes => 2,
        DiplomaticMessageTopic::WithdrawScouts => 3,
        DiplomaticMessageTopic::AvoidEscalation => 4,
        DiplomaticMessageTopic::CommonEnemy => 5,
        DiplomaticMessageTopic::ExpansionProvocation => 6,
        DiplomaticMessageTopic::PeacefulPraise => 7,
    }
}

const fn message_response_tag(value: DiplomaticMessageResponse) -> u8 {
    match value {
        DiplomaticMessageResponse::Conciliatory => 0,
        DiplomaticMessageResponse::Neutral => 1,
        DiplomaticMessageResponse::Evasive => 2,
        DiplomaticMessageResponse::Aggressive => 3,
    }
}

const fn score_reason_tag(value: DiplomaticScoreChangeReason) -> u8 {
    match value {
        DiplomaticScoreChangeReason::Manual => 0,
        DiplomaticScoreChangeReason::UnitAttack => 1,
        DiplomaticScoreChangeReason::CityAttack => 2,
        DiplomaticScoreChangeReason::DeclarationOfWar => 3,
        DiplomaticScoreChangeReason::WarmongerPenalty => 4,
        DiplomaticScoreChangeReason::ProposalAccepted => 5,
        DiplomaticScoreChangeReason::ProposalRejected => 6,
        DiplomaticScoreChangeReason::MessageResponse => 7,
        DiplomaticScoreChangeReason::CommonEnemyCooperation => 8,
        DiplomaticScoreChangeReason::GoldGift => 9,
        DiplomaticScoreChangeReason::PromiseBroken => 10,
    }
}
