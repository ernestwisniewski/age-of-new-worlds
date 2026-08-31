use aonw_domain::{
    DiplomaticMessage, DiplomaticMessageCategory, DiplomaticMessageResponse,
    DiplomaticMessageTopic, DiplomaticProposal, DiplomaticProposalKind, DiplomaticRelation,
    DiplomaticRelationChangeReason, DiplomaticRelationStatus, GameState, PlayerId,
    ResourceTradeAgreement, ResourceType,
};

/// Complete bilateral diplomacy state visible to the authenticated recipient.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct PlayerDiplomacyView {
    relations: Box<[PlayerDiplomaticRelationView]>,
    proposals: Box<[PlayerDiplomaticProposalView]>,
    messages: Box<[PlayerDiplomaticMessageView]>,
    resource_trade_agreements: Box<[PlayerResourceTradeAgreementView]>,
}

impl PlayerDiplomacyView {
    /// Returns effective relations in counterparty order.
    #[must_use]
    pub const fn relations(&self) -> &[PlayerDiplomaticRelationView] {
        &self.relations
    }

    /// Returns pending proposals involving the recipient in identifier order.
    #[must_use]
    pub const fn proposals(&self) -> &[PlayerDiplomaticProposalView] {
        &self.proposals
    }

    /// Returns messages involving the recipient in identifier order.
    #[must_use]
    pub const fn messages(&self) -> &[PlayerDiplomaticMessageView] {
        &self.messages
    }

    /// Returns active resource agreements involving the recipient in identifier order.
    #[must_use]
    pub const fn resource_trade_agreements(&self) -> &[PlayerResourceTradeAgreementView] {
        &self.resource_trade_agreements
    }
}

/// Effective relation between the recipient and one discovered counterparty.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerDiplomaticRelationView {
    counterpart_player_id: PlayerId,
    status: DiplomaticRelationStatus,
    relation_score: i64,
    status_expires_on_turn: Option<u32>,
    last_changed_turn: Option<u32>,
    last_change_reason: Option<DiplomaticRelationChangeReason>,
}

#[allow(missing_docs)]
impl PlayerDiplomaticRelationView {
    #[must_use]
    pub const fn counterpart_player_id(&self) -> &PlayerId {
        &self.counterpart_player_id
    }
    #[must_use]
    pub const fn status(&self) -> DiplomaticRelationStatus {
        self.status
    }
    #[must_use]
    pub const fn relation_score(&self) -> i64 {
        self.relation_score
    }
    #[must_use]
    pub const fn status_expires_on_turn(&self) -> Option<u32> {
        self.status_expires_on_turn
    }
    #[must_use]
    pub const fn last_changed_turn(&self) -> Option<u32> {
        self.last_changed_turn
    }
    #[must_use]
    pub const fn last_change_reason(&self) -> Option<DiplomaticRelationChangeReason> {
        self.last_change_reason
    }
}

/// Pending proposal visible to its sender and recipient.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerDiplomaticProposalView {
    proposal: DiplomaticProposal,
}

#[allow(missing_docs)]
impl PlayerDiplomaticProposalView {
    #[must_use]
    pub fn id(&self) -> &str {
        self.proposal.id()
    }
    #[must_use]
    pub const fn from_player_id(&self) -> &PlayerId {
        self.proposal.from_player_id()
    }
    #[must_use]
    pub const fn to_player_id(&self) -> &PlayerId {
        self.proposal.to_player_id()
    }
    #[must_use]
    pub const fn kind(&self) -> DiplomaticProposalKind {
        self.proposal.kind()
    }
    #[must_use]
    pub const fn created_turn(&self) -> u32 {
        self.proposal.created_turn()
    }
    #[must_use]
    pub const fn expires_on_turn(&self) -> u32 {
        self.proposal.expires_on_turn()
    }
    #[must_use]
    pub const fn gold_payment(&self) -> i64 {
        self.proposal.gold_payment()
    }
}

/// Diplomatic message visible to its sender and recipient.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerDiplomaticMessageView {
    message: DiplomaticMessage,
}

#[allow(missing_docs)]
impl PlayerDiplomaticMessageView {
    #[must_use]
    pub fn id(&self) -> &str {
        self.message.id()
    }
    #[must_use]
    pub const fn from_player_id(&self) -> &PlayerId {
        self.message.from_player_id()
    }
    #[must_use]
    pub const fn to_player_id(&self) -> &PlayerId {
        self.message.to_player_id()
    }
    #[must_use]
    pub const fn topic(&self) -> DiplomaticMessageTopic {
        self.message.topic()
    }
    #[must_use]
    pub const fn category(&self) -> DiplomaticMessageCategory {
        self.message.category()
    }
    #[must_use]
    pub const fn created_turn(&self) -> u32 {
        self.message.created_turn()
    }
    #[must_use]
    pub const fn expires_on_turn(&self) -> u32 {
        self.message.expires_on_turn()
    }
    #[must_use]
    pub const fn response(&self) -> Option<DiplomaticMessageResponse> {
        self.message.response()
    }
    #[must_use]
    pub const fn responded_turn(&self) -> Option<u32> {
        self.message.responded_turn()
    }
    #[must_use]
    pub const fn relation_score_delta(&self) -> i64 {
        self.message.relation_score_delta()
    }
    #[must_use]
    pub const fn relation_score_after(&self) -> Option<i64> {
        self.message.relation_score_after()
    }
    #[must_use]
    pub const fn promise_due_turn(&self) -> Option<u32> {
        self.message.promise_due_turn()
    }
    #[must_use]
    pub const fn promise_broken(&self) -> bool {
        self.message.promise_broken()
    }
}

/// Active resource agreement visible to its importer and exporter.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerResourceTradeAgreementView {
    agreement: ResourceTradeAgreement,
}

#[allow(missing_docs)]
impl PlayerResourceTradeAgreementView {
    #[must_use]
    pub fn id(&self) -> &str {
        self.agreement.id()
    }
    #[must_use]
    pub const fn exporter_player_id(&self) -> &PlayerId {
        self.agreement.exporter_player_id()
    }
    #[must_use]
    pub const fn importer_player_id(&self) -> &PlayerId {
        self.agreement.importer_player_id()
    }
    #[must_use]
    pub const fn resource(&self) -> ResourceType {
        self.agreement.resource()
    }
    #[must_use]
    pub const fn gold_per_turn(&self) -> i64 {
        self.agreement.gold_per_turn()
    }
    #[must_use]
    pub const fn remaining_turns(&self) -> u32 {
        self.agreement.remaining_turns()
    }
    #[must_use]
    pub const fn amount_per_turn(&self) -> u32 {
        self.agreement.amount_per_turn()
    }
    #[must_use]
    pub fn exchange_group_id(&self) -> Option<&str> {
        self.agreement.exchange_group_id()
    }
}

pub(crate) fn diplomacy_view(state: &GameState, actor: &PlayerId) -> PlayerDiplomacyView {
    let diplomacy = state.diplomacy();
    let mut relations = diplomacy
        .contacts()
        .iter()
        .filter_map(|pair| {
            let counterpart = if pair.first() == actor {
                pair.second()
            } else if pair.second() == actor {
                pair.first()
            } else {
                return None;
            };
            Some(relation_view(
                counterpart,
                diplomacy.relation_between(actor, counterpart),
            ))
        })
        .collect::<Vec<_>>();
    relations.sort_unstable_by(|left, right| {
        left.counterpart_player_id.cmp(&right.counterpart_player_id)
    });
    let proposals = diplomacy
        .pending_proposals()
        .iter()
        .filter(|proposal| proposal.from_player_id() == actor || proposal.to_player_id() == actor)
        .cloned()
        .map(|proposal| PlayerDiplomaticProposalView { proposal })
        .collect();
    let messages = diplomacy
        .messages()
        .iter()
        .filter(|message| message.from_player_id() == actor || message.to_player_id() == actor)
        .cloned()
        .map(|message| PlayerDiplomaticMessageView { message })
        .collect();
    let resource_trade_agreements = diplomacy
        .resource_trade_agreements()
        .iter()
        .filter(|agreement| {
            agreement.exporter_player_id() == actor || agreement.importer_player_id() == actor
        })
        .cloned()
        .map(|agreement| PlayerResourceTradeAgreementView { agreement })
        .collect();
    PlayerDiplomacyView {
        relations: relations.into_boxed_slice(),
        proposals,
        messages,
        resource_trade_agreements,
    }
}

fn relation_view(
    counterpart: &PlayerId,
    relation: Option<&DiplomaticRelation>,
) -> PlayerDiplomaticRelationView {
    PlayerDiplomaticRelationView {
        counterpart_player_id: counterpart.clone(),
        status: relation.map_or(
            DiplomaticRelationStatus::Neutral,
            DiplomaticRelation::status,
        ),
        relation_score: relation.map_or(0, DiplomaticRelation::relation_score),
        status_expires_on_turn: relation.and_then(DiplomaticRelation::status_expires_on_turn),
        last_changed_turn: relation.and_then(DiplomaticRelation::last_changed_turn),
        last_change_reason: relation.and_then(DiplomaticRelation::last_change_reason),
    }
}

#[cfg(test)]
mod tests;
