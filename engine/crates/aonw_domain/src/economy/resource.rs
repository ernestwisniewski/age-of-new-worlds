use std::collections::{BTreeMap, BTreeSet};

use crate::HexCoord;

use super::EconomyStateBuildError;

/// Resource identifier preserved by canonical economy state.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub enum ResourceType {
    Wheat,
    Fish,
    Deer,
    Sheep,
    Rice,
    Cow,
    Apple,
    Banana,
    Citrus,
    Gold,
    Silver,
    Gems,
    Silk,
    Spices,
    Cotton,
    Grapes,
    Ivory,
    Pearls,
    Coffee,
    Cocoa,
    Tobacco,
    Sugar,
    Iron,
    Coal,
    Oil,
    Aluminium,
    Uranium,
    Horses,
    Marble,
}

impl ResourceType {
    /// Returns whether this resource participates in strategic-resource trade.
    #[must_use]
    pub const fn is_strategic(self) -> bool {
        matches!(
            self,
            Self::Iron
                | Self::Coal
                | Self::Oil
                | Self::Aluminium
                | Self::Uranium
                | Self::Horses
                | Self::Marble
        )
    }

    /// Returns whether this resource uses a transferable stockpile.
    #[must_use]
    pub const fn is_stockpiled(self) -> bool {
        matches!(self, Self::Oil | Self::Aluminium)
    }
}

/// Positive stockpiled strategic resource amounts in stable resource order.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct StrategicResourceStockpile(BTreeMap<ResourceType, i64>);

impl StrategicResourceStockpile {
    /// Validates stockpiled resource kinds and positive amounts.
    ///
    /// # Errors
    ///
    /// Returns an error for non-stockpiled resources or non-positive values.
    pub fn try_new(amounts: BTreeMap<ResourceType, i64>) -> Result<Self, EconomyStateBuildError> {
        for (resource, amount) in &amounts {
            if !resource.is_stockpiled() {
                return Err(EconomyStateBuildError::ResourceNotStockpiled(*resource));
            }
            if *amount <= 0 {
                return Err(EconomyStateBuildError::NonPositiveResourceAmount {
                    resource: *resource,
                    amount: *amount,
                });
            }
        }
        Ok(Self(amounts))
    }

    /// Returns positive amounts sorted by resource identity.
    #[must_use]
    pub const fn amounts(&self) -> &BTreeMap<ResourceType, i64> {
        &self.0
    }
}

/// One generated resource placement retained by canonical state.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct InitialResourcePlacement {
    coordinate: HexCoord,
    resource: ResourceType,
}

impl InitialResourcePlacement {
    /// Constructs one placement.
    #[must_use]
    pub const fn new(coordinate: HexCoord, resource: ResourceType) -> Self {
        Self {
            coordinate,
            resource,
        }
    }

    /// Returns map coordinate.
    #[must_use]
    pub const fn coordinate(self) -> HexCoord {
        self.coordinate
    }

    /// Returns placed resource.
    #[must_use]
    pub const fn resource(self) -> ResourceType {
        self.resource
    }
}

/// Persisted deterministic match-start resource placements.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct InitialResourceDistribution {
    seed: i64,
    placements: Box<[InitialResourcePlacement]>,
}

impl InitialResourceDistribution {
    /// Owns ordered placements and rejects duplicate coordinates.
    ///
    /// # Errors
    ///
    /// Returns an error when multiple resources use one coordinate.
    pub fn try_new(
        seed: i64,
        placements: impl IntoIterator<Item = InitialResourcePlacement>,
    ) -> Result<Self, EconomyStateBuildError> {
        let mut placements = placements.into_iter().collect::<Vec<_>>();
        let mut coordinates = BTreeSet::new();
        for placement in &placements {
            if !coordinates.insert(placement.coordinate()) {
                return Err(EconomyStateBuildError::DuplicateInitialResource(
                    placement.coordinate(),
                ));
            }
        }
        placements.sort_unstable_by_key(|placement| placement.coordinate());
        Ok(Self {
            seed,
            placements: placements.into_boxed_slice(),
        })
    }

    /// Returns deterministic generator seed retained for evidence.
    #[must_use]
    pub const fn seed(&self) -> i64 {
        self.seed
    }

    /// Returns placements in canonical contract order.
    #[must_use]
    pub const fn placements(&self) -> &[InitialResourcePlacement] {
        &self.placements
    }
}
