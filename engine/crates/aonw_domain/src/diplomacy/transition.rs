use crate::MatchIdentity;

use super::{
    Diplomacy, DiplomacyStateBuildError, DiplomaticMessage, DiplomaticProposal, DiplomaticRelation,
    DiplomaticScoreEntry, PlayerPair, ResourceTradeAgreement,
};

impl Diplomacy {
    /// Adds one proposal and revalidates the complete diplomacy aggregate.
    ///
    /// # Errors
    /// Returns an error for a duplicate identifier or invalid participant/contact.
    pub fn try_with_proposal(
        &self,
        identity: &MatchIdentity,
        proposal: DiplomaticProposal,
    ) -> Result<Self, DiplomacyStateBuildError> {
        self.rebuild(
            identity,
            self.relations.iter().cloned(),
            self.pending_proposals
                .iter()
                .cloned()
                .chain(core::iter::once(proposal)),
            self.messages.iter().cloned(),
            self.score_history.iter().cloned(),
            self.resource_trade_agreements.iter().cloned(),
        )
    }

    /// Removes one proposal; an absent identifier preserves the current state.
    ///
    /// # Errors
    /// Returns an error only when the retained aggregate is invalid.
    pub fn try_without_proposal(
        &self,
        identity: &MatchIdentity,
        id: &str,
    ) -> Result<Self, DiplomacyStateBuildError> {
        if self.proposal(id).is_none() {
            return Ok(self.clone());
        }
        self.rebuild(
            identity,
            self.relations.iter().cloned(),
            self.pending_proposals
                .iter()
                .filter(|value| value.id() != id)
                .cloned(),
            self.messages.iter().cloned(),
            self.score_history.iter().cloned(),
            self.resource_trade_agreements.iter().cloned(),
        )
    }

    /// Adds one diplomatic message and revalidates its current strict shape.
    ///
    /// # Errors
    /// Returns an error for a duplicate identifier or invalid participant/contact.
    pub fn try_with_message(
        &self,
        identity: &MatchIdentity,
        message: DiplomaticMessage,
    ) -> Result<Self, DiplomacyStateBuildError> {
        self.rebuild(
            identity,
            self.relations.iter().cloned(),
            self.pending_proposals.iter().cloned(),
            self.messages
                .iter()
                .cloned()
                .chain(core::iter::once(message)),
            self.score_history.iter().cloned(),
            self.resource_trade_agreements.iter().cloned(),
        )
    }

    /// Replaces an existing message with the same stable identifier.
    ///
    /// # Errors
    /// Returns an error when the identifier is absent or the replacement is invalid.
    pub fn try_replacing_message(
        &self,
        identity: &MatchIdentity,
        message: DiplomaticMessage,
    ) -> Result<Self, DiplomacyStateBuildError> {
        let message_id = message.id().to_owned();
        if self.message(&message_id).is_none() {
            return Err(DiplomacyStateBuildError::IdNotFound(message_id));
        }
        self.rebuild(
            identity,
            self.relations.iter().cloned(),
            self.pending_proposals.iter().cloned(),
            self.messages
                .iter()
                .filter(|value| value.id() != message_id)
                .cloned()
                .chain(core::iter::once(message)),
            self.score_history.iter().cloned(),
            self.resource_trade_agreements.iter().cloned(),
        )
    }

    /// Removes one message; an absent identifier preserves the current state.
    ///
    /// # Errors
    /// Returns an error only when the retained aggregate is invalid.
    pub fn try_without_message(
        &self,
        identity: &MatchIdentity,
        id: &str,
    ) -> Result<Self, DiplomacyStateBuildError> {
        if self.message(id).is_none() {
            return Ok(self.clone());
        }
        self.rebuild(
            identity,
            self.relations.iter().cloned(),
            self.pending_proposals.iter().cloned(),
            self.messages
                .iter()
                .filter(|value| value.id() != id)
                .cloned(),
            self.score_history.iter().cloned(),
            self.resource_trade_agreements.iter().cloned(),
        )
    }

    /// Inserts or replaces the canonical relation for one normalized pair.
    ///
    /// # Errors
    /// Returns an error when the relation violates participant/contact invariants.
    pub fn try_with_relation(
        &self,
        identity: &MatchIdentity,
        relation: DiplomaticRelation,
    ) -> Result<Self, DiplomacyStateBuildError> {
        let pair = relation.pair().clone();
        self.rebuild(
            identity,
            self.relations
                .iter()
                .filter(|value| value.pair() != &pair)
                .cloned()
                .chain(core::iter::once(relation)),
            self.pending_proposals.iter().cloned(),
            self.messages.iter().cloned(),
            self.score_history.iter().cloned(),
            self.resource_trade_agreements.iter().cloned(),
        )
    }

    /// Appends one score audit entry and rejects a duplicate audit identity.
    ///
    /// # Errors
    /// Returns an error for duplicate pair/turn/source or invalid contact.
    pub fn try_with_score_entry(
        &self,
        identity: &MatchIdentity,
        entry: DiplomaticScoreEntry,
    ) -> Result<Self, DiplomacyStateBuildError> {
        self.rebuild(
            identity,
            self.relations.iter().cloned(),
            self.pending_proposals.iter().cloned(),
            self.messages.iter().cloned(),
            self.score_history
                .iter()
                .cloned()
                .chain(core::iter::once(entry)),
            self.resource_trade_agreements.iter().cloned(),
        )
    }

    /// Replaces the complete active trade set atomically.
    ///
    /// # Errors
    /// Returns an error for duplicate identifiers or invalid participants/terms.
    pub fn try_with_resource_trades(
        &self,
        identity: &MatchIdentity,
        agreements: impl IntoIterator<Item = ResourceTradeAgreement>,
    ) -> Result<Self, DiplomacyStateBuildError> {
        self.rebuild(
            identity,
            self.relations.iter().cloned(),
            self.pending_proposals.iter().cloned(),
            self.messages.iter().cloned(),
            self.score_history.iter().cloned(),
            agreements,
        )
    }

    /// Removes proposals, messages and trades for a pair when war begins.
    ///
    /// # Errors
    /// Returns an error only when the retained aggregate is invalid.
    pub fn try_without_pair_pending_actions(
        &self,
        identity: &MatchIdentity,
        pair: &PlayerPair,
    ) -> Result<Self, DiplomacyStateBuildError> {
        self.rebuild(
            identity,
            self.relations.iter().cloned(),
            self.pending_proposals
                .iter()
                .filter(|value| {
                    !directed_pair_matches(value.from_player_id(), value.to_player_id(), pair)
                })
                .cloned(),
            self.messages
                .iter()
                .filter(|value| {
                    !directed_pair_matches(value.from_player_id(), value.to_player_id(), pair)
                })
                .cloned(),
            self.score_history.iter().cloned(),
            self.resource_trade_agreements
                .iter()
                .filter(|value| {
                    !directed_pair_matches(
                        value.exporter_player_id(),
                        value.importer_player_id(),
                        pair,
                    )
                })
                .cloned(),
        )
    }

    #[allow(clippy::too_many_arguments)]
    fn rebuild(
        &self,
        identity: &MatchIdentity,
        relations: impl IntoIterator<Item = DiplomaticRelation>,
        proposals: impl IntoIterator<Item = DiplomaticProposal>,
        messages: impl IntoIterator<Item = DiplomaticMessage>,
        score_history: impl IntoIterator<Item = DiplomaticScoreEntry>,
        trades: impl IntoIterator<Item = ResourceTradeAgreement>,
    ) -> Result<Self, DiplomacyStateBuildError> {
        Self::try_new(
            identity,
            self.contacts.iter().cloned(),
            relations,
            proposals,
            messages,
            score_history,
            trades,
        )
    }
}

fn directed_pair_matches(
    left: &crate::PlayerId,
    right: &crate::PlayerId,
    expected: &PlayerPair,
) -> bool {
    PlayerPair::new(left.clone(), right.clone()).as_ref() == Some(expected)
}
