mod agreement;
mod attack;
mod model;
mod transition;

use crate::{MatchIdentity, PlayerId};

pub use agreement::ResourceTradeAgreement;
pub use model::{
    DiplomaticMessage, DiplomaticMessageCategory, DiplomaticMessageResponse,
    DiplomaticMessageTopic, DiplomaticProposal, DiplomaticProposalKind, DiplomaticRelation,
    DiplomaticRelationChangeReason, DiplomaticRelationStatus, DiplomaticScoreChangeReason,
    DiplomaticScoreEntry,
};

/// Ordered identity of one diplomatic relationship.
#[derive(Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub struct PlayerPair {
    first: PlayerId,
    second: PlayerId,
}

impl PlayerPair {
    /// Constructs a normalized pair, rejecting self-relations.
    #[must_use]
    pub fn new(left: PlayerId, right: PlayerId) -> Option<Self> {
        if left == right {
            return None;
        }
        let (first, second) = if left < right {
            (left, right)
        } else {
            (right, left)
        };
        Some(Self { first, second })
    }

    /// Returns the lexicographically first player.
    #[must_use]
    pub const fn first(&self) -> &PlayerId {
        &self.first
    }

    /// Returns the lexicographically second player.
    #[must_use]
    pub const fn second(&self) -> &PlayerId {
        &self.second
    }
}

/// Complete canonical diplomacy and resource-trade state.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct Diplomacy {
    contacts: Box<[PlayerPair]>,
    relations: Box<[DiplomaticRelation]>,
    pending_proposals: Box<[DiplomaticProposal]>,
    messages: Box<[DiplomaticMessage]>,
    score_history: Box<[DiplomaticScoreEntry]>,
    resource_trade_agreements: Box<[ResourceTradeAgreement]>,
}

impl Diplomacy {
    /// Normalizes discovered contacts.
    #[must_use]
    pub fn new(contacts: impl IntoIterator<Item = PlayerPair>) -> Self {
        let mut contacts = contacts.into_iter().collect::<Vec<_>>();
        contacts.sort_unstable();
        contacts.dedup();
        Self {
            contacts: contacts.into_boxed_slice(),
            relations: Box::default(),
            pending_proposals: Box::default(),
            messages: Box::default(),
            score_history: Box::default(),
            resource_trade_agreements: Box::default(),
        }
    }

    /// Validates all collections and participant references.
    ///
    /// # Errors
    ///
    /// Returns the first duplicate, unknown-player or cross-field violation.
    #[allow(clippy::too_many_arguments)]
    pub fn try_new(
        identity: &MatchIdentity,
        contacts: impl IntoIterator<Item = PlayerPair>,
        relations: impl IntoIterator<Item = DiplomaticRelation>,
        pending_proposals: impl IntoIterator<Item = DiplomaticProposal>,
        messages: impl IntoIterator<Item = DiplomaticMessage>,
        score_history: impl IntoIterator<Item = DiplomaticScoreEntry>,
        resource_trade_agreements: impl IntoIterator<Item = ResourceTradeAgreement>,
    ) -> Result<Self, DiplomacyStateBuildError> {
        let mut contacts = contacts.into_iter().collect::<Vec<_>>();
        contacts.sort_unstable();
        ensure_unique_by(
            &contacts,
            Clone::clone,
            DiplomacyStateBuildError::DuplicateContact,
        )?;

        let mut relations = relations.into_iter().collect::<Vec<_>>();
        relations.sort_by(|left, right| left.pair().cmp(right.pair()));
        ensure_unique_by(
            &relations,
            |value| value.pair().clone(),
            DiplomacyStateBuildError::DuplicateRelation,
        )?;
        let mut pending_proposals = pending_proposals.into_iter().collect::<Vec<_>>();
        pending_proposals.sort_by(|left, right| left.id().cmp(right.id()));
        ensure_unique_ids(&pending_proposals, |value| value.id())?;

        let mut messages = messages.into_iter().collect::<Vec<_>>();
        messages.sort_by(|left, right| left.id().cmp(right.id()));
        ensure_unique_ids(&messages, |value| value.id())?;

        let mut score_history = score_history.into_iter().collect::<Vec<_>>();
        score_history.sort_by(|left, right| {
            left.pair()
                .cmp(right.pair())
                .then_with(|| left.turn().cmp(&right.turn()))
                .then_with(|| {
                    left.source_id()
                        .unwrap_or("")
                        .cmp(right.source_id().unwrap_or(""))
                })
        });
        ensure_unique_by(
            &score_history,
            |value| {
                (
                    value.pair().clone(),
                    value.turn(),
                    value.source_id().map(str::to_owned),
                )
            },
            |(pair, turn, source_id)| DiplomacyStateBuildError::DuplicateScoreEntry {
                pair,
                turn,
                source_id,
            },
        )?;
        let mut trades = resource_trade_agreements.into_iter().collect::<Vec<_>>();
        trades.sort_by(|left, right| left.id().cmp(right.id()));
        ensure_unique_ids(&trades, |value| value.id())?;
        let state = Self {
            contacts: contacts.into_boxed_slice(),
            relations: relations.into_boxed_slice(),
            pending_proposals: pending_proposals.into_boxed_slice(),
            messages: messages.into_boxed_slice(),
            score_history: score_history.into_boxed_slice(),
            resource_trade_agreements: trades.into_boxed_slice(),
        };
        state.validate_for(identity)?;
        Ok(state)
    }

    /// Revalidates every participant and contact reference against a match.
    ///
    /// This is required after aggregate-level composition because normalized
    /// contact-only states can be assembled before the match identity is bound.
    ///
    /// # Errors
    ///
    /// Returns the first unknown-player or missing-contact violation.
    pub fn validate_for(&self, identity: &MatchIdentity) -> Result<(), DiplomacyStateBuildError> {
        for pair in &self.contacts {
            validate_pair(identity, pair)?;
        }
        for relation in &self.relations {
            validate_pair(identity, relation.pair())?;
            require_contact(&self.contacts, relation.pair())?;
        }
        for value in &self.pending_proposals {
            validate_directional_players(identity, value.from_player_id(), value.to_player_id())?;
            require_contact(
                &self.contacts,
                &pair(value.from_player_id(), value.to_player_id())?,
            )?;
        }
        for value in &self.messages {
            validate_directional_players(identity, value.from_player_id(), value.to_player_id())?;
            require_contact(
                &self.contacts,
                &pair(value.from_player_id(), value.to_player_id())?,
            )?;
        }
        for value in &self.score_history {
            validate_pair(identity, value.pair())?;
            require_contact(&self.contacts, value.pair())?;
        }
        for value in &self.resource_trade_agreements {
            validate_directional_players(
                identity,
                value.exporter_player_id(),
                value.importer_player_id(),
            )?;
        }
        Ok(())
    }

    /// Returns all contact pairs in deterministic order.
    #[must_use]
    pub const fn contacts(&self) -> &[PlayerPair] {
        &self.contacts
    }

    /// Returns relations in normalized pair order.
    #[must_use]
    pub const fn relations(&self) -> &[DiplomaticRelation] {
        &self.relations
    }
    /// Returns pending proposals in identifier order.
    #[must_use]
    pub const fn pending_proposals(&self) -> &[DiplomaticProposal] {
        &self.pending_proposals
    }
    /// Returns messages in identifier order.
    #[must_use]
    pub const fn messages(&self) -> &[DiplomaticMessage] {
        &self.messages
    }
    /// Returns score audit entries in pair/turn/source order.
    #[must_use]
    pub const fn score_history(&self) -> &[DiplomaticScoreEntry] {
        &self.score_history
    }
    /// Returns active resource trades in identifier order.
    #[must_use]
    pub const fn resource_trade_agreements(&self) -> &[ResourceTradeAgreement] {
        &self.resource_trade_agreements
    }

    /// Returns whether two players have met.
    #[must_use]
    pub fn has_contact(&self, left: &PlayerId, right: &PlayerId) -> bool {
        PlayerPair::new(left.clone(), right.clone())
            .is_some_and(|pair| self.contacts.binary_search(&pair).is_ok())
    }

    /// Returns the stored relation for a normalized player pair.
    #[must_use]
    pub fn relation_between(
        &self,
        left: &PlayerId,
        right: &PlayerId,
    ) -> Option<&DiplomaticRelation> {
        let pair = PlayerPair::new(left.clone(), right.clone())?;
        self.relations
            .binary_search_by(|relation| relation.pair().cmp(&pair))
            .ok()
            .map(|index| &self.relations[index])
    }

    /// Returns one pending proposal by its stable identifier.
    #[must_use]
    pub fn proposal(&self, id: &str) -> Option<&DiplomaticProposal> {
        self.pending_proposals
            .binary_search_by(|proposal| proposal.id().cmp(id))
            .ok()
            .map(|index| &self.pending_proposals[index])
    }

    /// Returns one diplomatic message by its stable identifier.
    #[must_use]
    pub fn message(&self, id: &str) -> Option<&DiplomaticMessage> {
        self.messages
            .binary_search_by(|message| message.id().cmp(id))
            .ok()
            .map(|index| &self.messages[index])
    }

    /// Returns one active resource trade by its stable identifier.
    #[must_use]
    pub fn resource_trade(&self, id: &str) -> Option<&ResourceTradeAgreement> {
        self.resource_trade_agreements
            .binary_search_by(|agreement| agreement.id().cmp(id))
            .ok()
            .map(|index| &self.resource_trade_agreements[index])
    }

    /// Merges newly discovered contacts.
    #[must_use]
    pub fn merging(&self, contacts: impl IntoIterator<Item = PlayerPair>) -> Self {
        let mut next = self.clone();
        let mut merged = self
            .contacts
            .iter()
            .cloned()
            .chain(contacts)
            .collect::<Vec<_>>();
        merged.sort_unstable();
        merged.dedup();
        next.contacts = merged.into_boxed_slice();
        next
    }
}

#[cfg(test)]
use attack::attack_status_severity;

/// Structural diplomacy-state validation failure.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum DiplomacyStateBuildError {
    /// A local identifier is empty.
    EmptyId,
    /// A directed record points to the same player.
    SelfRelation(PlayerId),
    /// A player reference is absent from match identity.
    PlayerNotFound(PlayerId),
    /// A contact pair appears more than once.
    DuplicateContact(PlayerPair),
    /// A relation pair appears more than once.
    DuplicateRelation(PlayerPair),
    /// An identifier appears more than once in its collection.
    DuplicateId(String),
    /// A requested identifier is absent from its canonical collection.
    IdNotFound(String),
    /// A score entry repeats the same pair, turn and optional source.
    DuplicateScoreEntry {
        /// Related players.
        pair: PlayerPair,
        /// Turn recorded by both entries.
        turn: u32,
        /// Optional source shared by both entries.
        source_id: Option<String>,
    },
    /// A record references a pair without diplomatic contact.
    ContactRequired(PlayerPair),
    /// A relation score is outside `-100..=100`.
    RelationScoreOutOfRange(i64),
    /// An expiry is not later than creation.
    InvalidTurnRange,
    /// A gold value is negative.
    NegativeGold(i64),
    /// Message topic and category disagree.
    MessageCategoryMismatch,
    /// Response and response turn are not both present or both absent.
    MessageResponseMismatch,
    /// A promise exists without a response.
    PromiseWithoutResponse,
    /// A broken promise has no due turn.
    BrokenPromiseWithoutDueTurn,
    /// A trade duration or amount is zero.
    NonPositiveTrade,
}

impl core::fmt::Display for DiplomacyStateBuildError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::EmptyId => formatter.write_str("identifier must be non-empty"),
            Self::SelfRelation(player) => write!(formatter, "self relation for {player}"),
            Self::PlayerNotFound(player) => {
                write!(formatter, "diplomacy references non-participant {player}")
            }
            Self::DuplicateContact(_) => formatter.write_str("duplicate diplomatic contact"),
            Self::DuplicateRelation(_) => formatter.write_str("duplicate diplomatic relation"),
            Self::DuplicateId(id) => write!(formatter, "duplicate diplomacy identifier: {id}"),
            Self::IdNotFound(id) => write!(formatter, "diplomacy identifier not found: {id}"),
            Self::DuplicateScoreEntry {
                pair: _,
                turn,
                source_id,
            } => write!(
                formatter,
                "duplicate diplomacy score entry at turn {turn} from {source_id:?}"
            ),
            Self::ContactRequired(_) => formatter.write_str("diplomatic contact is required"),
            Self::RelationScoreOutOfRange(score) => {
                write!(formatter, "relation score is outside -100..=100: {score}")
            }
            Self::InvalidTurnRange => {
                formatter.write_str("expiry turn must be later than creation")
            }
            Self::NegativeGold(gold) => {
                write!(formatter, "gold value must be non-negative: {gold}")
            }
            Self::MessageCategoryMismatch => {
                formatter.write_str("message category does not match topic")
            }
            Self::MessageResponseMismatch => {
                formatter.write_str("message response and response turn must coexist")
            }
            Self::PromiseWithoutResponse => {
                formatter.write_str("message promise requires a response")
            }
            Self::BrokenPromiseWithoutDueTurn => {
                formatter.write_str("broken promise requires a due turn")
            }
            Self::NonPositiveTrade => {
                formatter.write_str("trade duration and amount must be positive")
            }
        }
    }
}

impl std::error::Error for DiplomacyStateBuildError {}

fn validate_pair(
    identity: &MatchIdentity,
    pair: &PlayerPair,
) -> Result<(), DiplomacyStateBuildError> {
    validate_player(identity, pair.first())?;
    validate_player(identity, pair.second())
}

fn validate_directional_players(
    identity: &MatchIdentity,
    left: &PlayerId,
    right: &PlayerId,
) -> Result<(), DiplomacyStateBuildError> {
    validate_player(identity, left)?;
    validate_player(identity, right)
}

fn validate_player(
    identity: &MatchIdentity,
    player: &PlayerId,
) -> Result<(), DiplomacyStateBuildError> {
    if identity.contains(player) {
        Ok(())
    } else {
        Err(DiplomacyStateBuildError::PlayerNotFound(player.clone()))
    }
}

fn pair(left: &PlayerId, right: &PlayerId) -> Result<PlayerPair, DiplomacyStateBuildError> {
    PlayerPair::new(left.clone(), right.clone())
        .ok_or_else(|| DiplomacyStateBuildError::SelfRelation(left.clone()))
}

fn require_contact(
    contacts: &[PlayerPair],
    pair: &PlayerPair,
) -> Result<(), DiplomacyStateBuildError> {
    if contacts.binary_search(pair).is_ok() {
        Ok(())
    } else {
        Err(DiplomacyStateBuildError::ContactRequired(pair.clone()))
    }
}

fn ensure_unique_by<T, K: Ord + Clone>(
    values: &[T],
    key: impl Fn(&T) -> K,
    error: impl Fn(K) -> DiplomacyStateBuildError,
) -> Result<(), DiplomacyStateBuildError> {
    for pair in values.windows(2) {
        if key(&pair[0]) == key(&pair[1]) {
            return Err(error(key(&pair[0])));
        }
    }
    Ok(())
}

fn ensure_unique_ids<T>(
    values: &[T],
    id: impl Fn(&T) -> &str,
) -> Result<(), DiplomacyStateBuildError> {
    for pair in values.windows(2) {
        if id(&pair[0]) == id(&pair[1]) {
            return Err(DiplomacyStateBuildError::DuplicateId(
                id(&pair[0]).to_owned(),
            ));
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests;
