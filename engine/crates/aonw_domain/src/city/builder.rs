use std::collections::BTreeSet;

use crate::{CityId, HexCoord, PlayerId};

use super::{
    City, CityBuildError, CityBuildingType, CityProductionQueue, CitySpecializationType,
    WonderType, entity::validate_numeric_values,
};

/// Builder owning all complete-city construction defaults.
#[derive(Clone, Debug)]
pub struct CityBuilder {
    id: CityId,
    owner_player_id: PlayerId,
    founding_owner_player_id: Option<PlayerId>,
    name: Box<str>,
    population: i64,
    stored_food: i64,
    max_hexes: i64,
    territory_radius: i64,
    center: HexCoord,
    controlled_hexes: Vec<HexCoord>,
    worked_hexes: Vec<HexCoord>,
    buildings: Vec<CityBuildingType>,
    wonders: Vec<WonderType>,
    production_queue: Option<CityProductionQueue>,
    production_overflow: i64,
    specialization: Option<CitySpecializationType>,
    preferred_expansion_hex: Option<HexCoord>,
    hit_points: Option<i64>,
}

impl CityBuilder {
    pub(super) fn new(
        id: CityId,
        owner_player_id: PlayerId,
        name: Box<str>,
        center: HexCoord,
    ) -> Self {
        Self {
            id,
            owner_player_id,
            founding_owner_player_id: None,
            name,
            population: 3,
            stored_food: 0,
            max_hexes: 6,
            territory_radius: 2,
            center,
            controlled_hexes: Vec::new(),
            worked_hexes: Vec::new(),
            buildings: Vec::new(),
            wonders: Vec::new(),
            production_queue: None,
            production_overflow: 0,
            specialization: None,
            preferred_expansion_hex: None,
            hit_points: None,
        }
    }

    /// Sets optional original owner identity.
    #[must_use]
    pub fn with_founding_owner(mut self, owner: Option<PlayerId>) -> Self {
        self.founding_owner_player_id = owner;
        self
    }

    /// Sets persisted city growth and territory counters.
    #[must_use]
    pub fn with_progression(
        mut self,
        population: i64,
        stored_food: i64,
        max_hexes: i64,
        territory_radius: i64,
    ) -> Self {
        self.population = population;
        self.stored_food = stored_food;
        self.max_hexes = max_hexes;
        self.territory_radius = territory_radius;
        self
    }

    /// Sets controlled coordinates in contract order.
    #[must_use]
    pub fn with_controlled_hexes(mut self, values: impl IntoIterator<Item = HexCoord>) -> Self {
        self.controlled_hexes = values.into_iter().collect();
        self
    }

    /// Sets manually worked coordinates in contract order.
    #[must_use]
    pub fn with_worked_hexes(mut self, values: impl IntoIterator<Item = HexCoord>) -> Self {
        self.worked_hexes = values.into_iter().collect();
        self
    }

    /// Sets owned building identities.
    #[must_use]
    pub fn with_buildings(mut self, values: impl IntoIterator<Item = CityBuildingType>) -> Self {
        self.buildings = values.into_iter().collect();
        self
    }

    /// Sets owned wonder identities.
    #[must_use]
    pub fn with_wonders(mut self, values: impl IntoIterator<Item = WonderType>) -> Self {
        self.wonders = values.into_iter().collect();
        self
    }

    /// Sets the optional production queue and overflow.
    #[must_use]
    pub fn with_production(mut self, queue: Option<CityProductionQueue>, overflow: i64) -> Self {
        self.production_queue = queue;
        self.production_overflow = overflow;
        self
    }

    /// Sets optional specialization and preferred expansion coordinate.
    #[must_use]
    pub fn with_planning(
        mut self,
        specialization: Option<CitySpecializationType>,
        preferred_expansion_hex: Option<HexCoord>,
    ) -> Self {
        self.specialization = specialization;
        self.preferred_expansion_hex = preferred_expansion_hex;
        self
    }

    /// Sets persistent combat health.
    #[must_use]
    pub fn with_hit_points(mut self, hit_points: Option<i64>) -> Self {
        self.hit_points = hit_points;
        self
    }

    /// Validates numeric state and list/set topology, then constructs a complete city.
    ///
    /// # Errors
    ///
    /// Returns an error for duplicated or inconsistent city collections.
    pub fn build(self) -> Result<City, CityBuildError> {
        validate_numeric_state(&self)?;
        let controlled = unique_coordinates(
            self.controlled_hexes,
            CityBuildError::DuplicateControlledHex,
        )?;
        if controlled.contains(&self.center) {
            return Err(CityBuildError::CenterInControlledHexes);
        }
        let worked = unique_coordinates(self.worked_hexes, CityBuildError::DuplicateWorkedHex)?;
        for coordinate in &worked {
            if *coordinate == self.center || !controlled.contains(coordinate) {
                return Err(CityBuildError::WorkedHexNotControlled(*coordinate));
            }
        }
        let buildings = unique_values(self.buildings, CityBuildError::DuplicateBuilding)?;
        let wonders = unique_values(self.wonders, CityBuildError::DuplicateWonder)?;
        Ok(City {
            id: self.id,
            owner_player_id: self.owner_player_id,
            founding_owner_player_id: self.founding_owner_player_id,
            name: self.name,
            population: self.population,
            stored_food: self.stored_food,
            max_hexes: self.max_hexes,
            territory_radius: self.territory_radius,
            center: self.center,
            controlled_hexes: controlled.into_boxed_slice(),
            worked_hexes: worked.into_boxed_slice(),
            buildings,
            wonders,
            production_queue: self.production_queue,
            production_overflow: self.production_overflow,
            specialization: self.specialization,
            preferred_expansion_hex: self.preferred_expansion_hex,
            hit_points: self.hit_points,
        })
    }
}

fn validate_numeric_state(builder: &CityBuilder) -> Result<(), CityBuildError> {
    validate_numeric_values(
        builder.population,
        builder.stored_food,
        builder.max_hexes,
        builder.territory_radius,
        builder.production_overflow,
        builder.hit_points,
    )
}

fn unique_coordinates(
    values: Vec<HexCoord>,
    duplicate: impl Fn(HexCoord) -> CityBuildError,
) -> Result<Vec<HexCoord>, CityBuildError> {
    let mut seen = BTreeSet::new();
    for coordinate in &values {
        if !seen.insert(*coordinate) {
            return Err(duplicate(*coordinate));
        }
    }
    Ok(values)
}

fn unique_values<T: Copy + Ord>(
    values: Vec<T>,
    duplicate: impl Fn(T) -> CityBuildError,
) -> Result<BTreeSet<T>, CityBuildError> {
    let mut unique = BTreeSet::new();
    for value in values {
        if !unique.insert(value) {
            return Err(duplicate(value));
        }
    }
    Ok(unique)
}
