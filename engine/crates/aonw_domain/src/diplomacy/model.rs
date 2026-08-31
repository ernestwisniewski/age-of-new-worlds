use crate::PlayerId;

use super::{DiplomacyStateBuildError, PlayerPair};

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum DiplomaticRelationStatus {
    Friendly,
    Neutral,
    Hostile,
    Truce,
    War,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum DiplomaticRelationChangeReason {
    Manual,
    UnitAttack,
    CityAttack,
    DeclarationOfWar,
    ProposalAccepted,
    TruceExpired,
    MessageResponse,
    PromiseBroken,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub enum DiplomaticProposalKind {
    Friendship,
    Truce,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum DiplomaticMessageCategory {
    Warning,
    Complaint,
    Request,
    Praise,
    Threat,
    Cooperation,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub enum DiplomaticMessageTopic {
    TroopsNearCities,
    CitiesTooClose,
    BlockedRoutes,
    WithdrawScouts,
    AvoidEscalation,
    CommonEnemy,
    ExpansionProvocation,
    PeacefulPraise,
}

impl DiplomaticMessageTopic {
    /// Returns the category fixed by the current rules.
    #[must_use]
    pub const fn category(self) -> DiplomaticMessageCategory {
        match self {
            Self::TroopsNearCities => DiplomaticMessageCategory::Warning,
            Self::CitiesTooClose => DiplomaticMessageCategory::Complaint,
            Self::BlockedRoutes | Self::WithdrawScouts => DiplomaticMessageCategory::Request,
            Self::AvoidEscalation | Self::CommonEnemy => DiplomaticMessageCategory::Cooperation,
            Self::ExpansionProvocation => DiplomaticMessageCategory::Threat,
            Self::PeacefulPraise => DiplomaticMessageCategory::Praise,
        }
    }
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub enum DiplomaticMessageResponse {
    Conciliatory,
    Neutral,
    Evasive,
    Aggressive,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum DiplomaticScoreChangeReason {
    Manual,
    UnitAttack,
    CityAttack,
    DeclarationOfWar,
    WarmongerPenalty,
    ProposalAccepted,
    ProposalRejected,
    MessageResponse,
    CommonEnemyCooperation,
    GoldGift,
    PromiseBroken,
}

/// Canonical relationship for one normalized player pair.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DiplomaticRelation {
    pair: PlayerPair,
    status: DiplomaticRelationStatus,
    relation_score: i64,
    status_expires_on_turn: Option<u32>,
    last_changed_turn: Option<u32>,
    last_change_reason: Option<DiplomaticRelationChangeReason>,
}

#[allow(missing_docs)]
impl DiplomaticRelation {
    /// Constructs a score-bounded relation.
    ///
    /// # Errors
    ///
    /// Returns an error when the score is outside `-100..=100`.
    pub fn try_new(
        pair: PlayerPair,
        status: DiplomaticRelationStatus,
        relation_score: i64,
        status_expires_on_turn: Option<u32>,
        last_changed_turn: Option<u32>,
        last_change_reason: Option<DiplomaticRelationChangeReason>,
    ) -> Result<Self, DiplomacyStateBuildError> {
        if !(-100..=100).contains(&relation_score) {
            return Err(DiplomacyStateBuildError::RelationScoreOutOfRange(
                relation_score,
            ));
        }
        Ok(Self {
            pair,
            status,
            relation_score,
            status_expires_on_turn,
            last_changed_turn,
            last_change_reason,
        })
    }
    #[must_use]
    pub const fn pair(&self) -> &PlayerPair {
        &self.pair
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

/// Pending bilateral diplomatic proposal.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DiplomaticProposal {
    id: String,
    from_player_id: PlayerId,
    to_player_id: PlayerId,
    kind: DiplomaticProposalKind,
    created_turn: u32,
    expires_on_turn: u32,
    gold_payment: i64,
}

#[allow(missing_docs)]
impl DiplomaticProposal {
    /// Constructs a validated pending proposal.
    ///
    /// # Errors
    ///
    /// Returns an error for an empty identifier, a self-targeted proposal, an invalid
    /// expiry range, or a negative gold payment.
    pub fn try_new(
        id: String,
        from_player_id: PlayerId,
        to_player_id: PlayerId,
        kind: DiplomaticProposalKind,
        created_turn: u32,
        expires_on_turn: u32,
        gold_payment: i64,
    ) -> Result<Self, DiplomacyStateBuildError> {
        validate_id(&id)?;
        validate_direction(&from_player_id, &to_player_id)?;
        if expires_on_turn <= created_turn {
            return Err(DiplomacyStateBuildError::InvalidTurnRange);
        }
        if gold_payment < 0 {
            return Err(DiplomacyStateBuildError::NegativeGold(gold_payment));
        }
        Ok(Self {
            id,
            from_player_id,
            to_player_id,
            kind,
            created_turn,
            expires_on_turn,
            gold_payment,
        })
    }
    #[must_use]
    pub fn id(&self) -> &str {
        &self.id
    }
    #[must_use]
    pub const fn from_player_id(&self) -> &PlayerId {
        &self.from_player_id
    }
    #[must_use]
    pub const fn to_player_id(&self) -> &PlayerId {
        &self.to_player_id
    }
    #[must_use]
    pub const fn kind(&self) -> DiplomaticProposalKind {
        self.kind
    }
    #[must_use]
    pub const fn created_turn(&self) -> u32 {
        self.created_turn
    }
    #[must_use]
    pub const fn expires_on_turn(&self) -> u32 {
        self.expires_on_turn
    }
    #[must_use]
    pub const fn gold_payment(&self) -> i64 {
        self.gold_payment
    }
}

/// Persisted diplomatic message and response outcome.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DiplomaticMessage {
    id: String,
    from_player_id: PlayerId,
    to_player_id: PlayerId,
    topic: DiplomaticMessageTopic,
    category: DiplomaticMessageCategory,
    created_turn: u32,
    expires_on_turn: u32,
    response: Option<DiplomaticMessageResponse>,
    responded_turn: Option<u32>,
    relation_score_delta: i64,
    relation_score_after: Option<i64>,
    promise_due_turn: Option<u32>,
    promise_broken: bool,
}

#[allow(missing_docs)]
impl DiplomaticMessage {
    /// Constructs a structurally coherent message.
    ///
    /// # Errors
    ///
    /// Returns an error when identifiers, participants, turns, category, response,
    /// score, or promise fields form an invalid message.
    #[allow(clippy::too_many_arguments)]
    pub fn try_new(
        id: String,
        from_player_id: PlayerId,
        to_player_id: PlayerId,
        topic: DiplomaticMessageTopic,
        category: DiplomaticMessageCategory,
        created_turn: u32,
        expires_on_turn: u32,
        response: Option<DiplomaticMessageResponse>,
        responded_turn: Option<u32>,
        relation_score_delta: i64,
        relation_score_after: Option<i64>,
        promise_due_turn: Option<u32>,
        promise_broken: bool,
    ) -> Result<Self, DiplomacyStateBuildError> {
        validate_id(&id)?;
        validate_direction(&from_player_id, &to_player_id)?;
        if category != topic.category() {
            return Err(DiplomacyStateBuildError::MessageCategoryMismatch);
        }
        if expires_on_turn <= created_turn {
            return Err(DiplomacyStateBuildError::InvalidTurnRange);
        }
        if response.is_some() != responded_turn.is_some() {
            return Err(DiplomacyStateBuildError::MessageResponseMismatch);
        }
        if let Some(score) = relation_score_after
            && !(-100..=100).contains(&score)
        {
            return Err(DiplomacyStateBuildError::RelationScoreOutOfRange(score));
        }
        if promise_due_turn.is_some() && response.is_none() {
            return Err(DiplomacyStateBuildError::PromiseWithoutResponse);
        }
        if promise_broken && promise_due_turn.is_none() {
            return Err(DiplomacyStateBuildError::BrokenPromiseWithoutDueTurn);
        }
        Ok(Self {
            id,
            from_player_id,
            to_player_id,
            topic,
            category,
            created_turn,
            expires_on_turn,
            response,
            responded_turn,
            relation_score_delta,
            relation_score_after,
            promise_due_turn,
            promise_broken,
        })
    }
    #[must_use]
    pub fn id(&self) -> &str {
        &self.id
    }
    #[must_use]
    pub const fn from_player_id(&self) -> &PlayerId {
        &self.from_player_id
    }
    #[must_use]
    pub const fn to_player_id(&self) -> &PlayerId {
        &self.to_player_id
    }
    #[must_use]
    pub const fn topic(&self) -> DiplomaticMessageTopic {
        self.topic
    }
    #[must_use]
    pub const fn category(&self) -> DiplomaticMessageCategory {
        self.category
    }
    #[must_use]
    pub const fn created_turn(&self) -> u32 {
        self.created_turn
    }
    #[must_use]
    pub const fn expires_on_turn(&self) -> u32 {
        self.expires_on_turn
    }
    #[must_use]
    pub const fn response(&self) -> Option<DiplomaticMessageResponse> {
        self.response
    }
    #[must_use]
    pub const fn responded_turn(&self) -> Option<u32> {
        self.responded_turn
    }
    #[must_use]
    pub const fn relation_score_delta(&self) -> i64 {
        self.relation_score_delta
    }
    #[must_use]
    pub const fn relation_score_after(&self) -> Option<i64> {
        self.relation_score_after
    }
    #[must_use]
    pub const fn promise_due_turn(&self) -> Option<u32> {
        self.promise_due_turn
    }
    #[must_use]
    pub const fn promise_broken(&self) -> bool {
        self.promise_broken
    }
}

/// One canonical relation-score audit entry.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DiplomaticScoreEntry {
    pair: PlayerPair,
    turn: u32,
    delta: i64,
    score_after: i64,
    reason: DiplomaticScoreChangeReason,
    source_id: Option<String>,
}

#[allow(missing_docs)]
impl DiplomaticScoreEntry {
    /// Constructs a score-bounded audit entry.
    ///
    /// # Errors
    ///
    /// Returns an error when the resulting score is outside `-100..=100` or a
    /// supplied source identifier is empty.
    pub fn try_new(
        pair: PlayerPair,
        turn: u32,
        delta: i64,
        score_after: i64,
        reason: DiplomaticScoreChangeReason,
        source_id: Option<String>,
    ) -> Result<Self, DiplomacyStateBuildError> {
        if !(-100..=100).contains(&score_after) {
            return Err(DiplomacyStateBuildError::RelationScoreOutOfRange(
                score_after,
            ));
        }
        if source_id.as_deref().is_some_and(str::is_empty) {
            return Err(DiplomacyStateBuildError::EmptyId);
        }
        Ok(Self {
            pair,
            turn,
            delta,
            score_after,
            reason,
            source_id,
        })
    }
    #[must_use]
    pub const fn pair(&self) -> &PlayerPair {
        &self.pair
    }
    #[must_use]
    pub const fn turn(&self) -> u32 {
        self.turn
    }
    #[must_use]
    pub const fn delta(&self) -> i64 {
        self.delta
    }
    #[must_use]
    pub const fn score_after(&self) -> i64 {
        self.score_after
    }
    #[must_use]
    pub const fn reason(&self) -> DiplomaticScoreChangeReason {
        self.reason
    }
    #[must_use]
    pub fn source_id(&self) -> Option<&str> {
        self.source_id.as_deref()
    }
}

pub(super) fn validate_id(value: &str) -> Result<(), DiplomacyStateBuildError> {
    if value.is_empty() {
        Err(DiplomacyStateBuildError::EmptyId)
    } else {
        Ok(())
    }
}

pub(super) fn validate_direction(
    left: &PlayerId,
    right: &PlayerId,
) -> Result<(), DiplomacyStateBuildError> {
    if left == right {
        Err(DiplomacyStateBuildError::SelfRelation(left.clone()))
    } else {
        Ok(())
    }
}
