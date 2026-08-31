use std::collections::BTreeMap;

use crate::{HexCoord, HexGridBounds, MatchIdentity, PlayerId};

mod resource;

pub use resource::{
    InitialResourceDistribution, InitialResourcePlacement, ResourceType, StrategicResourceStockpile,
};

/// Canonical player economy accounts and initial resource distribution.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct EconomyState {
    player_gold: BTreeMap<PlayerId, i64>,
    player_war_weariness: BTreeMap<PlayerId, i64>,
    player_stability_net: BTreeMap<PlayerId, i64>,
    strategic_resources: BTreeMap<PlayerId, StrategicResourceStockpile>,
    initial_resource_distribution: InitialResourceDistribution,
}

impl EconomyState {
    /// Validates participant ownership and generated placement bounds.
    ///
    /// # Errors
    ///
    /// Returns an error for an unknown player or out-of-bounds placement.
    pub fn try_new(
        identity: &MatchIdentity,
        bounds: HexGridBounds,
        player_gold: BTreeMap<PlayerId, i64>,
        player_war_weariness: BTreeMap<PlayerId, i64>,
        player_stability_net: BTreeMap<PlayerId, i64>,
        mut strategic_resources: BTreeMap<PlayerId, StrategicResourceStockpile>,
        initial_resource_distribution: InitialResourceDistribution,
    ) -> Result<Self, EconomyStateBuildError> {
        strategic_resources.retain(|_, stockpile| !stockpile.amounts().is_empty());
        let state = Self {
            player_gold,
            player_war_weariness,
            player_stability_net,
            strategic_resources,
            initial_resource_distribution,
        };
        state.validate_for(identity, bounds)?;
        Ok(state)
    }

    /// Applies an ordered set of account deltas atomically using checked arithmetic.
    ///
    /// Zero strategic-resource balances are removed from canonical state. A
    /// failure leaves the original state unchanged.
    ///
    /// # Errors
    ///
    /// Returns an error for an unknown player, invalid resource, insufficient
    /// balance, or integer overflow.
    pub fn try_after_changes(
        &self,
        identity: &MatchIdentity,
        bounds: HexGridBounds,
        changes: impl IntoIterator<Item = EconomyAccountChange>,
    ) -> Result<Self, EconomyStateBuildError> {
        let mut updated = self.clone();
        for change in changes {
            updated.apply_change(identity, change)?;
        }
        updated.validate_for(identity, bounds)?;
        Ok(updated)
    }

    fn apply_change(
        &mut self,
        identity: &MatchIdentity,
        change: EconomyAccountChange,
    ) -> Result<(), EconomyStateBuildError> {
        let player = change.player();
        if !identity.contains(player) {
            return Err(EconomyStateBuildError::UnknownPlayer(player.clone()));
        }
        match change {
            EconomyAccountChange::Gold { player, delta } => adjust_non_negative(
                &mut self.player_gold,
                player,
                delta,
                EconomyAccountKind::Gold,
            ),
            EconomyAccountChange::WarWeariness { player, delta } => adjust_non_negative(
                &mut self.player_war_weariness,
                player,
                delta,
                EconomyAccountKind::WarWeariness,
            ),
            EconomyAccountChange::Stability { player, delta } => {
                let current = self.player_stability_net.get(&player).copied().unwrap_or(0);
                let value = current.checked_add(delta).ok_or_else(|| {
                    EconomyStateBuildError::AccountOverflow {
                        player: player.clone(),
                        account: EconomyAccountKind::Stability,
                    }
                })?;
                self.player_stability_net.insert(player, value);
                Ok(())
            }
            EconomyAccountChange::StrategicResource {
                player,
                resource,
                delta,
            } => {
                if !resource.is_stockpiled() {
                    return Err(EconomyStateBuildError::ResourceNotStockpiled(resource));
                }
                let current = self
                    .strategic_resources
                    .get(&player)
                    .and_then(|stockpile| stockpile.amounts().get(&resource))
                    .copied()
                    .unwrap_or(0);
                let value = current.checked_add(delta).ok_or_else(|| {
                    EconomyStateBuildError::AccountOverflow {
                        player: player.clone(),
                        account: EconomyAccountKind::StrategicResource,
                    }
                })?;
                if value < 0 {
                    return Err(EconomyStateBuildError::InsufficientBalance {
                        player,
                        account: EconomyAccountKind::StrategicResource,
                        available: current,
                        requested: delta.saturating_neg(),
                    });
                }
                let mut amounts = self
                    .strategic_resources
                    .get(&player)
                    .map_or_else(BTreeMap::new, |stockpile| stockpile.amounts().clone());
                if value == 0 {
                    amounts.remove(&resource);
                } else {
                    amounts.insert(resource, value);
                }
                if amounts.is_empty() {
                    self.strategic_resources.remove(&player);
                } else {
                    self.strategic_resources
                        .insert(player, StrategicResourceStockpile::try_new(amounts)?);
                }
                Ok(())
            }
        }
    }

    pub(crate) fn validate_for(
        &self,
        identity: &MatchIdentity,
        bounds: HexGridBounds,
    ) -> Result<(), EconomyStateBuildError> {
        for player in self
            .player_gold
            .keys()
            .chain(self.player_war_weariness.keys())
            .chain(self.player_stability_net.keys())
            .chain(self.strategic_resources.keys())
        {
            if !identity.contains(player) {
                return Err(EconomyStateBuildError::UnknownPlayer(player.clone()));
            }
        }
        for (player, value) in &self.player_gold {
            if *value < 0 {
                return Err(EconomyStateBuildError::NegativeGold {
                    player: player.clone(),
                    value: *value,
                });
            }
        }
        for (player, value) in &self.player_war_weariness {
            if *value < 0 {
                return Err(EconomyStateBuildError::NegativeWarWeariness {
                    player: player.clone(),
                    value: *value,
                });
            }
        }
        for placement in self.initial_resource_distribution.placements() {
            if !bounds.contains(placement.coordinate()) {
                return Err(EconomyStateBuildError::InitialResourceOutOfBounds(
                    placement.coordinate(),
                ));
            }
        }
        Ok(())
    }

    /// Returns gold accounts sorted by player identity.
    #[must_use]
    pub const fn player_gold(&self) -> &BTreeMap<PlayerId, i64> {
        &self.player_gold
    }
    /// Returns war-weariness accounts sorted by player identity.
    #[must_use]
    pub const fn player_war_weariness(&self) -> &BTreeMap<PlayerId, i64> {
        &self.player_war_weariness
    }
    /// Returns stability values sorted by player identity.
    #[must_use]
    pub const fn player_stability_net(&self) -> &BTreeMap<PlayerId, i64> {
        &self.player_stability_net
    }
    /// Returns strategic stockpiles sorted by player identity.
    #[must_use]
    pub const fn strategic_resources(&self) -> &BTreeMap<PlayerId, StrategicResourceStockpile> {
        &self.strategic_resources
    }
    /// Returns persisted initial resource placements.
    #[must_use]
    pub const fn initial_resource_distribution(&self) -> &InitialResourceDistribution {
        &self.initial_resource_distribution
    }
}

fn adjust_non_negative(
    accounts: &mut BTreeMap<PlayerId, i64>,
    player: PlayerId,
    delta: i64,
    account: EconomyAccountKind,
) -> Result<(), EconomyStateBuildError> {
    let current = accounts.get(&player).copied().unwrap_or(0);
    let value =
        current
            .checked_add(delta)
            .ok_or_else(|| EconomyStateBuildError::AccountOverflow {
                player: player.clone(),
                account,
            })?;
    if value < 0 {
        return Err(EconomyStateBuildError::InsufficientBalance {
            player,
            account,
            available: current,
            requested: delta.saturating_neg(),
        });
    }
    accounts.insert(player, value);
    Ok(())
}

/// One atomic delta applied to canonical economy accounts.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum EconomyAccountChange {
    Gold {
        player: PlayerId,
        delta: i64,
    },
    WarWeariness {
        player: PlayerId,
        delta: i64,
    },
    Stability {
        player: PlayerId,
        delta: i64,
    },
    StrategicResource {
        player: PlayerId,
        resource: ResourceType,
        delta: i64,
    },
}

impl EconomyAccountChange {
    const fn player(&self) -> &PlayerId {
        match self {
            Self::Gold { player, .. }
            | Self::WarWeariness { player, .. }
            | Self::Stability { player, .. }
            | Self::StrategicResource { player, .. } => player,
        }
    }
}

/// Stable economy account category used by checked-transition failures.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum EconomyAccountKind {
    Gold,
    WarWeariness,
    Stability,
    StrategicResource,
}

/// Structural economy-state failure.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum EconomyStateBuildError {
    /// Economy data references someone outside match participants.
    UnknownPlayer(PlayerId),
    /// Gold accounts cannot contain debt in the canonical economy.
    NegativeGold {
        /// Account owner.
        player: PlayerId,
        /// Invalid balance.
        value: i64,
    },
    /// War weariness is an accumulated non-negative pressure.
    NegativeWarWeariness {
        /// Account owner.
        player: PlayerId,
        /// Invalid accumulated value.
        value: i64,
    },
    /// A stockpile contains a resource using another economy mode.
    ResourceNotStockpiled(ResourceType),
    /// Canonical stockpiles contain positive entries only.
    NonPositiveResourceAmount {
        /// Invalid resource.
        resource: ResourceType,
        /// Invalid amount.
        amount: i64,
    },
    /// Multiple generated resources occupy one coordinate.
    DuplicateInitialResource(HexCoord),
    /// A generated resource is outside logical map bounds.
    InitialResourceOutOfBounds(HexCoord),
    /// A checked account addition exceeded the canonical integer range.
    AccountOverflow {
        /// Account owner.
        player: PlayerId,
        /// Account category.
        account: EconomyAccountKind,
    },
    /// A debit would make a non-negative account negative.
    InsufficientBalance {
        /// Account owner.
        player: PlayerId,
        /// Account category.
        account: EconomyAccountKind,
        /// Current balance.
        available: i64,
        /// Positive requested debit.
        requested: i64,
    },
}

impl core::fmt::Display for EconomyStateBuildError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::UnknownPlayer(player) => {
                write!(formatter, "economy player is not a participant: {player}")
            }
            Self::NegativeGold { player, value } => {
                write!(
                    formatter,
                    "gold for {player} cannot be negative, got {value}"
                )
            }
            Self::NegativeWarWeariness { player, value } => write!(
                formatter,
                "war weariness for {player} cannot be negative, got {value}"
            ),
            Self::ResourceNotStockpiled(resource) => {
                write!(formatter, "resource is not stockpiled: {resource:?}")
            }
            Self::NonPositiveResourceAmount { resource, amount } => write!(
                formatter,
                "resource {resource:?} amount must be positive, got {amount}"
            ),
            Self::DuplicateInitialResource(coordinate) => write!(
                formatter,
                "duplicate initial resource at ({}, {})",
                coordinate.col(),
                coordinate.row()
            ),
            Self::InitialResourceOutOfBounds(coordinate) => write!(
                formatter,
                "initial resource at ({}, {}) is outside the map",
                coordinate.col(),
                coordinate.row()
            ),
            Self::AccountOverflow { player, account } => {
                write!(
                    formatter,
                    "economy account {account:?} overflows for {player}"
                )
            }
            Self::InsufficientBalance {
                player,
                account,
                available,
                requested,
            } => write!(
                formatter,
                "economy account {account:?} for {player} has {available}, cannot debit {requested}"
            ),
        }
    }
}

impl std::error::Error for EconomyStateBuildError {}

#[cfg(test)]
#[path = "economy/tests.rs"]
mod tests;
