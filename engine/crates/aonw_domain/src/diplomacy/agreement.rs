use crate::{PlayerId, ResourceType};

use super::DiplomacyStateBuildError;
use super::model::{validate_direction, validate_id};

/// Active resource-for-gold transfer agreement.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ResourceTradeAgreement {
    id: String,
    exporter_player_id: PlayerId,
    importer_player_id: PlayerId,
    resource: ResourceType,
    gold_per_turn: i64,
    remaining_turns: u32,
    amount_per_turn: u32,
    exchange_group_id: Option<String>,
}

#[allow(missing_docs)]
impl ResourceTradeAgreement {
    /// Constructs an active validated agreement.
    ///
    /// # Errors
    ///
    /// Returns an error for invalid identifiers or participants, negative gold,
    /// or a zero duration or resource amount.
    #[allow(clippy::too_many_arguments)]
    pub fn try_new(
        id: String,
        exporter_player_id: PlayerId,
        importer_player_id: PlayerId,
        resource: ResourceType,
        gold_per_turn: i64,
        remaining_turns: u32,
        amount_per_turn: u32,
        exchange_group_id: Option<String>,
    ) -> Result<Self, DiplomacyStateBuildError> {
        validate_id(&id)?;
        validate_direction(&exporter_player_id, &importer_player_id)?;
        if gold_per_turn < 0 {
            return Err(DiplomacyStateBuildError::NegativeGold(gold_per_turn));
        }
        if remaining_turns == 0 || amount_per_turn == 0 {
            return Err(DiplomacyStateBuildError::NonPositiveTrade);
        }
        if exchange_group_id.as_deref().is_some_and(str::is_empty) {
            return Err(DiplomacyStateBuildError::EmptyId);
        }
        Ok(Self {
            id,
            exporter_player_id,
            importer_player_id,
            resource,
            gold_per_turn,
            remaining_turns,
            amount_per_turn,
            exchange_group_id,
        })
    }

    #[must_use]
    pub fn id(&self) -> &str {
        &self.id
    }

    #[must_use]
    pub const fn exporter_player_id(&self) -> &PlayerId {
        &self.exporter_player_id
    }

    #[must_use]
    pub const fn importer_player_id(&self) -> &PlayerId {
        &self.importer_player_id
    }

    #[must_use]
    pub const fn resource(&self) -> ResourceType {
        self.resource
    }

    #[must_use]
    pub const fn gold_per_turn(&self) -> i64 {
        self.gold_per_turn
    }

    #[must_use]
    pub const fn remaining_turns(&self) -> u32 {
        self.remaining_turns
    }

    #[must_use]
    pub const fn amount_per_turn(&self) -> u32 {
        self.amount_per_turn
    }

    #[must_use]
    pub fn exchange_group_id(&self) -> Option<&str> {
        self.exchange_group_id.as_deref()
    }

    /// Rebuilds this agreement with a smaller positive remaining duration.
    ///
    /// # Errors
    ///
    /// Returns an error when the replacement duration is zero.
    pub fn try_with_remaining_turns(
        &self,
        remaining_turns: u32,
    ) -> Result<Self, DiplomacyStateBuildError> {
        Self::try_new(
            self.id.clone(),
            self.exporter_player_id.clone(),
            self.importer_player_id.clone(),
            self.resource,
            self.gold_per_turn,
            remaining_turns,
            self.amount_per_turn,
            self.exchange_group_id.clone(),
        )
    }
}
