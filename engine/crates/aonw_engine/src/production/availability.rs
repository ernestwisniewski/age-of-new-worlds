use aonw_domain::{City, CityProductionTarget, TechnologyId};

use crate::TechnologyUnlockQuery;

/// Technology and local completion state, independent of the first command blocker.
///
/// A completed world wonder is disclosed here only when it belongs to the queried
/// city. Other players' cities, research and construction queues remain private.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ProductionAvailability {
    required_technology: Option<TechnologyId>,
    technology_unlocked: bool,
    completed_in_city: bool,
}

impl ProductionAvailability {
    pub(super) fn for_target(
        city: &City,
        technology: TechnologyUnlockQuery<'_>,
        target: CityProductionTarget,
    ) -> Self {
        let (required_technology, technology_unlocked, completed_in_city) = match target {
            CityProductionTarget::Building(building) => (
                technology.unlocking_technology_for_building(building),
                technology.is_building_unlocked(building),
                city.buildings().contains(&building),
            ),
            CityProductionTarget::Unit(unit) => (
                technology.unlocking_technology_for_unit(unit),
                technology.is_unit_unlocked(unit),
                false,
            ),
            CityProductionTarget::Wonder(wonder) => (
                technology.unlocking_technology_for_wonder(wonder),
                technology.is_wonder_unlocked(wonder),
                city.wonders().contains(&wonder),
            ),
            CityProductionTarget::Project(_) => (None, true, false),
        };
        Self {
            required_technology,
            technology_unlocked,
            completed_in_city,
        }
    }

    /// Returns the content-defined unlocking technology, if the target has one.
    #[must_use]
    pub const fn required_technology(self) -> Option<TechnologyId> {
        self.required_technology
    }

    /// Returns whether the owner has the target's research capability.
    #[must_use]
    pub const fn technology_unlocked(self) -> bool {
        self.technology_unlocked
    }

    /// Returns whether this city already contains the building or wonder.
    #[must_use]
    pub const fn completed_in_city(self) -> bool {
        self.completed_in_city
    }
}
