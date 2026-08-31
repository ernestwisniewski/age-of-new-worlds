use crate::{StrategicResourceStockpile, UnitKind};

use super::{CityBuildingType, CityProjectType, WonderType};

/// One typed city production target.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum CityProductionTarget {
    /// A city building.
    Building(CityBuildingType),
    /// A producible unit kind.
    Unit(UnitKind),
    /// A repeatable project.
    Project(CityProjectType),
    /// A world wonder.
    Wonder(WonderType),
}

/// Persisted production investment and reserved strategic resources.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CityProductionQueue {
    target: CityProductionTarget,
    invested_production: i64,
    resource_allocation: StrategicResourceStockpile,
}

impl CityProductionQueue {
    /// Constructs a typed production queue with non-negative investment.
    ///
    /// # Errors
    ///
    /// Returns an error when persisted production investment is negative.
    pub fn try_new(
        target: CityProductionTarget,
        invested_production: i64,
        resource_allocation: StrategicResourceStockpile,
    ) -> Result<Self, CityProductionQueueBuildError> {
        if invested_production < 0 {
            return Err(CityProductionQueueBuildError::NegativeInvestedProduction(
                invested_production,
            ));
        }
        Ok(Self {
            target,
            invested_production,
            resource_allocation,
        })
    }

    /// Returns the current target.
    #[must_use]
    pub const fn target(&self) -> CityProductionTarget {
        self.target
    }

    /// Returns invested production without applying gameplay rules.
    #[must_use]
    pub const fn invested_production(&self) -> i64 {
        self.invested_production
    }

    /// Returns strategic resources reserved by the queue.
    #[must_use]
    pub const fn resource_allocation(&self) -> &StrategicResourceStockpile {
        &self.resource_allocation
    }

    /// Replaces accumulated investment while preserving target and reservation.
    ///
    /// # Errors
    ///
    /// Returns an error when the replacement investment is negative.
    pub fn try_with_invested_production(
        &self,
        invested_production: i64,
    ) -> Result<Self, CityProductionQueueBuildError> {
        Self::try_new(
            self.target,
            invested_production,
            self.resource_allocation.clone(),
        )
    }
}

/// Structural production-queue validation failure.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum CityProductionQueueBuildError {
    /// Accumulated production cannot be negative.
    NegativeInvestedProduction(i64),
}

impl core::fmt::Display for CityProductionQueueBuildError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::NegativeInvestedProduction(value) => {
                write!(
                    formatter,
                    "invested production cannot be negative, got {value}"
                )
            }
        }
    }
}

impl std::error::Error for CityProductionQueueBuildError {}
