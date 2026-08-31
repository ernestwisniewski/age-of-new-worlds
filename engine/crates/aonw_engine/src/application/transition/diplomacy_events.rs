use aonw_domain::{
    DiplomaticMessage, DiplomaticMessageCategory, DiplomaticMessageResponse,
    DiplomaticMessageTopic, DiplomaticProposal, DiplomaticProposalKind,
    DiplomaticRelationChangeReason, DiplomaticRelationStatus, PlayerId, PlayerPair,
};

/// Accepted fact that one private bilateral proposal was sent.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DiplomaticProposalSentEvent {
    proposal_id: String,
    from_player_id: PlayerId,
    to_player_id: PlayerId,
    kind: DiplomaticProposalKind,
    expires_on_turn: u32,
}

impl DiplomaticProposalSentEvent {
    pub(crate) fn from_proposal(proposal: &DiplomaticProposal) -> Self {
        Self {
            proposal_id: proposal.id().to_owned(),
            from_player_id: proposal.from_player_id().clone(),
            to_player_id: proposal.to_player_id().clone(),
            kind: proposal.kind(),
            expires_on_turn: proposal.expires_on_turn(),
        }
    }
    /// Returns the proposal identity.
    #[must_use]
    pub fn proposal_id(&self) -> &str {
        &self.proposal_id
    }
    /// Returns the sender.
    #[must_use]
    pub const fn from_player_id(&self) -> &PlayerId {
        &self.from_player_id
    }
    /// Returns the recipient.
    #[must_use]
    pub const fn to_player_id(&self) -> &PlayerId {
        &self.to_player_id
    }
    /// Returns the proposal kind.
    #[must_use]
    pub const fn kind(&self) -> DiplomaticProposalKind {
        self.kind
    }
    /// Returns the last actionable turn boundary.
    #[must_use]
    pub const fn expires_on_turn(&self) -> u32 {
        self.expires_on_turn
    }
}

/// Accepted fact that the proposal recipient made a decision.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DiplomaticProposalRespondedEvent {
    proposal_id: String,
    from_player_id: PlayerId,
    to_player_id: PlayerId,
    kind: DiplomaticProposalKind,
    accepted: bool,
}

impl DiplomaticProposalRespondedEvent {
    pub(crate) fn from_proposal(proposal: &DiplomaticProposal, accepted: bool) -> Self {
        Self {
            proposal_id: proposal.id().to_owned(),
            from_player_id: proposal.from_player_id().clone(),
            to_player_id: proposal.to_player_id().clone(),
            kind: proposal.kind(),
            accepted,
        }
    }
    /// Returns the proposal identity.
    #[must_use]
    pub fn proposal_id(&self) -> &str {
        &self.proposal_id
    }
    /// Returns the original sender.
    #[must_use]
    pub const fn from_player_id(&self) -> &PlayerId {
        &self.from_player_id
    }
    /// Returns the responding recipient.
    #[must_use]
    pub const fn to_player_id(&self) -> &PlayerId {
        &self.to_player_id
    }
    /// Returns the original proposal kind.
    #[must_use]
    pub const fn kind(&self) -> DiplomaticProposalKind {
        self.kind
    }
    /// Returns whether the proposal was accepted.
    #[must_use]
    pub const fn accepted(&self) -> bool {
        self.accepted
    }
}

/// Accepted fact that one unanswered bilateral proposal expired.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DiplomaticProposalExpiredEvent {
    proposal_id: String,
    from_player_id: PlayerId,
    to_player_id: PlayerId,
    kind: DiplomaticProposalKind,
}

impl DiplomaticProposalExpiredEvent {
    pub(crate) fn from_proposal(proposal: &DiplomaticProposal) -> Self {
        Self {
            proposal_id: proposal.id().to_owned(),
            from_player_id: proposal.from_player_id().clone(),
            to_player_id: proposal.to_player_id().clone(),
            kind: proposal.kind(),
        }
    }
    /// Returns the expired proposal identity.
    #[must_use]
    pub fn proposal_id(&self) -> &str {
        &self.proposal_id
    }
    /// Returns the original sender.
    #[must_use]
    pub const fn from_player_id(&self) -> &PlayerId {
        &self.from_player_id
    }
    /// Returns the original recipient.
    #[must_use]
    pub const fn to_player_id(&self) -> &PlayerId {
        &self.to_player_id
    }
    /// Returns the expired proposal kind.
    #[must_use]
    pub const fn kind(&self) -> DiplomaticProposalKind {
        self.kind
    }
}

/// Accepted fact that one private bilateral message was sent.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DiplomaticMessageSentEvent {
    message_id: String,
    from_player_id: PlayerId,
    to_player_id: PlayerId,
    topic: DiplomaticMessageTopic,
    category: DiplomaticMessageCategory,
    expires_on_turn: u32,
}

impl DiplomaticMessageSentEvent {
    pub(crate) fn from_message(message: &DiplomaticMessage) -> Self {
        Self {
            message_id: message.id().to_owned(),
            from_player_id: message.from_player_id().clone(),
            to_player_id: message.to_player_id().clone(),
            topic: message.topic(),
            category: message.category(),
            expires_on_turn: message.expires_on_turn(),
        }
    }
    /// Returns the message identity.
    #[must_use]
    pub fn message_id(&self) -> &str {
        &self.message_id
    }
    /// Returns the sender.
    #[must_use]
    pub const fn from_player_id(&self) -> &PlayerId {
        &self.from_player_id
    }
    /// Returns the recipient.
    #[must_use]
    pub const fn to_player_id(&self) -> &PlayerId {
        &self.to_player_id
    }
    /// Returns the message topic.
    #[must_use]
    pub const fn topic(&self) -> DiplomaticMessageTopic {
        self.topic
    }
    /// Returns the category fixed by the topic.
    #[must_use]
    pub const fn category(&self) -> DiplomaticMessageCategory {
        self.category
    }
    /// Returns the last actionable turn boundary.
    #[must_use]
    pub const fn expires_on_turn(&self) -> u32 {
        self.expires_on_turn
    }
}

/// Accepted fact that the recipient responded to one diplomatic message.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DiplomaticMessageRespondedEvent {
    message_id: String,
    from_player_id: PlayerId,
    to_player_id: PlayerId,
    topic: DiplomaticMessageTopic,
    response: DiplomaticMessageResponse,
    relation_delta: i64,
    relation_score_after: i64,
    promise_due_turn: Option<u32>,
}

impl DiplomaticMessageRespondedEvent {
    pub(crate) fn from_message(message: &DiplomaticMessage) -> Self {
        Self {
            message_id: message.id().to_owned(),
            from_player_id: message.from_player_id().clone(),
            to_player_id: message.to_player_id().clone(),
            topic: message.topic(),
            response: message.response().expect("responded message"),
            relation_delta: message.relation_score_delta(),
            relation_score_after: message.relation_score_after().expect("responded score"),
            promise_due_turn: message.promise_due_turn(),
        }
    }
    /// Returns the message identity.
    #[must_use]
    pub fn message_id(&self) -> &str {
        &self.message_id
    }
    /// Returns the original sender.
    #[must_use]
    pub const fn from_player_id(&self) -> &PlayerId {
        &self.from_player_id
    }
    /// Returns the responding recipient.
    #[must_use]
    pub const fn to_player_id(&self) -> &PlayerId {
        &self.to_player_id
    }
    /// Returns the original topic.
    #[must_use]
    pub const fn topic(&self) -> DiplomaticMessageTopic {
        self.topic
    }
    /// Returns the selected response tone.
    #[must_use]
    pub const fn response(&self) -> DiplomaticMessageResponse {
        self.response
    }
    /// Returns the applied relation-score delta.
    #[must_use]
    pub const fn relation_delta(&self) -> i64 {
        self.relation_delta
    }
    /// Returns the relation score after the response.
    #[must_use]
    pub const fn relation_score_after(&self) -> i64 {
        self.relation_score_after
    }
    /// Returns the optional withdrawal-promise deadline.
    #[must_use]
    pub const fn promise_due_turn(&self) -> Option<u32> {
        self.promise_due_turn
    }
}

/// Accepted fact that one withdrawal promise was broken.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DiplomaticPromiseBrokenEvent {
    message_id: String,
    pair: PlayerPair,
    delta: i64,
    score_after: i64,
}

impl DiplomaticPromiseBrokenEvent {
    pub(crate) fn new(message_id: String, pair: PlayerPair, delta: i64, score_after: i64) -> Self {
        Self {
            message_id,
            pair,
            delta,
            score_after,
        }
    }
    /// Returns the broken promise identity.
    #[must_use]
    pub fn message_id(&self) -> &str {
        &self.message_id
    }
    /// Returns the canonical first participant.
    #[must_use]
    pub const fn player_a_id(&self) -> &PlayerId {
        self.pair.first()
    }
    /// Returns the canonical second participant.
    #[must_use]
    pub const fn player_b_id(&self) -> &PlayerId {
        self.pair.second()
    }
    /// Returns the bounded score delta.
    #[must_use]
    pub const fn delta(&self) -> i64 {
        self.delta
    }
    /// Returns the relation score after the penalty.
    #[must_use]
    pub const fn score_after(&self) -> i64 {
        self.score_after
    }
}

/// Accepted fact that a bilateral relation status changed.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DiplomaticRelationChangedEvent {
    pair: PlayerPair,
    old_status: DiplomaticRelationStatus,
    new_status: DiplomaticRelationStatus,
    reason: DiplomaticRelationChangeReason,
    expires_on_turn: Option<u32>,
}

impl DiplomaticRelationChangedEvent {
    pub(crate) const fn new(
        pair: PlayerPair,
        old_status: DiplomaticRelationStatus,
        new_status: DiplomaticRelationStatus,
        reason: DiplomaticRelationChangeReason,
        expires_on_turn: Option<u32>,
    ) -> Self {
        Self {
            pair,
            old_status,
            new_status,
            reason,
            expires_on_turn,
        }
    }
    /// Returns the canonical first participant.
    #[must_use]
    pub const fn player_a_id(&self) -> &PlayerId {
        self.pair.first()
    }
    /// Returns the canonical second participant.
    #[must_use]
    pub const fn player_b_id(&self) -> &PlayerId {
        self.pair.second()
    }
    /// Returns the status before the transition.
    #[must_use]
    pub const fn old_status(&self) -> DiplomaticRelationStatus {
        self.old_status
    }
    /// Returns the status after the transition.
    #[must_use]
    pub const fn new_status(&self) -> DiplomaticRelationStatus {
        self.new_status
    }
    /// Returns why the status changed.
    #[must_use]
    pub const fn reason(&self) -> DiplomaticRelationChangeReason {
        self.reason
    }
    /// Returns an optional expiry for temporary statuses.
    #[must_use]
    pub const fn expires_on_turn(&self) -> Option<u32> {
        self.expires_on_turn
    }
}
