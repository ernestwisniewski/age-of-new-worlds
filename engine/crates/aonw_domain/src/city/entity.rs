use std::collections::BTreeSet;

use crate::{CityId, HexCoord, PlayerId};

use super::{
    CityBuildError, CityBuilder, CityBuildingType, CityProductionQueue, CitySpecializationType,
    WonderType,
};

/// Complete canonical city state.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct City {
    pub(super) id: CityId,
    pub(super) owner_player_id: PlayerId,
    pub(super) founding_owner_player_id: Option<PlayerId>,
    pub(super) name: Box<str>,
    pub(super) population: i64,
    pub(super) stored_food: i64,
    pub(super) max_hexes: i64,
    pub(super) territory_radius: i64,
    pub(super) center: HexCoord,
    pub(super) controlled_hexes: Box<[HexCoord]>,
    pub(super) worked_hexes: Box<[HexCoord]>,
    pub(super) buildings: BTreeSet<CityBuildingType>,
    pub(super) wonders: BTreeSet<WonderType>,
    pub(super) production_queue: Option<CityProductionQueue>,
    pub(super) production_overflow: i64,
    pub(super) specialization: Option<CitySpecializationType>,
    pub(super) preferred_expansion_hex: Option<HexCoord>,
    pub(super) hit_points: Option<i64>,
}

impl City {
    /// Constructs a minimal canonical city with validated defaults.
    #[must_use]
    pub fn new(
        id: CityId,
        owner_player_id: PlayerId,
        center: HexCoord,
        controlled_hexes: impl IntoIterator<Item = HexCoord>,
    ) -> Self {
        let mut controlled_hexes = controlled_hexes.into_iter().collect::<Vec<_>>();
        controlled_hexes.sort_unstable();
        controlled_hexes.dedup();
        controlled_hexes.retain(|coordinate| *coordinate != center);
        Self {
            id,
            owner_player_id,
            founding_owner_player_id: None,
            name: "".into(),
            population: 3,
            stored_food: 0,
            max_hexes: 6,
            territory_radius: 2,
            center,
            controlled_hexes: controlled_hexes.into_boxed_slice(),
            worked_hexes: Box::default(),
            buildings: BTreeSet::new(),
            wonders: BTreeSet::new(),
            production_queue: None,
            production_overflow: 0,
            specialization: None,
            preferred_expansion_hex: None,
            hit_points: None,
        }
    }

    /// Starts construction of a complete city without exposing partial state.
    #[must_use]
    pub fn builder(
        id: CityId,
        owner_player_id: PlayerId,
        name: impl Into<Box<str>>,
        center: HexCoord,
    ) -> CityBuilder {
        CityBuilder::new(id, owner_player_id, name.into(), center)
    }

    /// Returns the city identifier.
    #[must_use]
    pub const fn id(&self) -> &CityId {
        &self.id
    }
    /// Returns the current owner.
    #[must_use]
    pub const fn owner_player_id(&self) -> &PlayerId {
        &self.owner_player_id
    }
    /// Returns the founding owner, when retained by the source snapshot.
    #[must_use]
    pub const fn founding_owner_player_id(&self) -> Option<&PlayerId> {
        self.founding_owner_player_id.as_ref()
    }
    /// Returns the persisted city name.
    #[must_use]
    pub const fn name(&self) -> &str {
        &self.name
    }
    /// Returns city population.
    #[must_use]
    pub const fn population(&self) -> i64 {
        self.population
    }
    /// Returns stored food.
    #[must_use]
    pub const fn stored_food(&self) -> i64 {
        self.stored_food
    }
    /// Returns the territory capacity.
    #[must_use]
    pub const fn max_hexes(&self) -> i64 {
        self.max_hexes
    }
    /// Returns the persisted territory radius.
    #[must_use]
    pub const fn territory_radius(&self) -> i64 {
        self.territory_radius
    }
    /// Returns the city-center coordinate.
    #[must_use]
    pub const fn center(&self) -> HexCoord {
        self.center
    }
    /// Returns controlled coordinates in contract order.
    #[must_use]
    pub const fn controlled_hexes(&self) -> &[HexCoord] {
        &self.controlled_hexes
    }
    /// Returns manually worked coordinates in contract order.
    #[must_use]
    pub const fn worked_hexes(&self) -> &[HexCoord] {
        &self.worked_hexes
    }
    /// Returns owned buildings in stable identity order.
    #[must_use]
    pub const fn buildings(&self) -> &BTreeSet<CityBuildingType> {
        &self.buildings
    }
    /// Returns owned wonders in stable identity order.
    #[must_use]
    pub const fn wonders(&self) -> &BTreeSet<WonderType> {
        &self.wonders
    }
    /// Returns the current production queue.
    #[must_use]
    pub const fn production_queue(&self) -> Option<&CityProductionQueue> {
        self.production_queue.as_ref()
    }
    /// Returns stored production overflow.
    #[must_use]
    pub const fn production_overflow(&self) -> i64 {
        self.production_overflow
    }
    /// Returns optional city specialization.
    #[must_use]
    pub const fn specialization(&self) -> Option<CitySpecializationType> {
        self.specialization
    }
    /// Returns the preferred next expansion coordinate.
    #[must_use]
    pub const fn preferred_expansion_hex(&self) -> Option<HexCoord> {
        self.preferred_expansion_hex
    }
    /// Returns persistent combat health when present.
    #[must_use]
    pub const fn hit_points(&self) -> Option<i64> {
        self.hit_points
    }

    /// Returns whether the city controls a center or territory coordinate.
    #[must_use]
    pub fn controls(&self, coordinate: HexCoord) -> bool {
        self.center == coordinate || self.controlled_hexes.contains(&coordinate)
    }

    pub(crate) fn validate(&self) -> Result<(), CityBuildError> {
        validate_numeric_values(
            self.population,
            self.stored_food,
            self.max_hexes,
            self.territory_radius,
            self.production_overflow,
            self.hit_points,
        )?;
        if self.controlled_hexes.contains(&self.center) {
            return Err(CityBuildError::CenterInControlledHexes);
        }
        if let Some(coordinate) = first_duplicate(&self.controlled_hexes) {
            return Err(CityBuildError::DuplicateControlledHex(coordinate));
        }
        if let Some(coordinate) = first_duplicate(&self.worked_hexes) {
            return Err(CityBuildError::DuplicateWorkedHex(coordinate));
        }
        for coordinate in &self.worked_hexes {
            if *coordinate == self.center || !self.controlled_hexes.contains(coordinate) {
                return Err(CityBuildError::WorkedHexNotControlled(*coordinate));
            }
        }
        Ok(())
    }

    /// Returns the center plus all controlled non-center coordinates.
    #[must_use]
    pub fn territory_hex_count(&self) -> usize {
        self.controlled_hexes.len().saturating_add(1)
    }

    /// Replaces manually worked coordinates after authoritative legality checks.
    #[must_use]
    pub fn with_worked_hexes(&self, worked_hexes: impl Into<Box<[HexCoord]>>) -> Self {
        let mut updated = self.clone();
        updated.worked_hexes = worked_hexes.into();
        updated
    }

    /// Replaces the preferred next expansion coordinate.
    #[must_use]
    pub fn with_preferred_expansion_hex(&self, preferred: Option<HexCoord>) -> Self {
        let mut updated = self.clone();
        updated.preferred_expansion_hex = preferred;
        updated
    }

    /// Replaces the authoritative production queue and non-negative overflow.
    ///
    /// # Errors
    ///
    /// Returns an error when the resulting city violates a structural invariant.
    pub fn try_with_production(
        &self,
        queue: Option<CityProductionQueue>,
        overflow: i64,
    ) -> Result<Self, CityBuildError> {
        let mut updated = self.clone();
        updated.production_queue = queue;
        updated.production_overflow = overflow;
        updated.validate()?;
        Ok(updated)
    }

    /// Replaces checked growth counters and optionally claims one expansion hex.
    ///
    /// # Errors
    ///
    /// Returns an error when the resulting progression or territory is invalid.
    pub fn try_after_growth(
        &self,
        population: i64,
        stored_food: i64,
        max_hexes: i64,
        territory_radius: i64,
        claimed_hex: Option<HexCoord>,
    ) -> Result<Self, CityBuildError> {
        let mut updated = self.clone();
        updated.population = population;
        updated.stored_food = stored_food;
        updated.max_hexes = max_hexes;
        updated.territory_radius = territory_radius;
        if let Some(coordinate) = claimed_hex {
            let mut controlled = updated.controlled_hexes.into_vec();
            controlled.push(coordinate);
            controlled.sort_unstable();
            updated.controlled_hexes = controlled.into_boxed_slice();
            updated.preferred_expansion_hex = None;
        }
        updated.validate()?;
        Ok(updated)
    }

    /// Replaces the authoritative city specialization.
    #[must_use]
    pub fn with_specialization(&self, specialization: Option<CitySpecializationType>) -> Self {
        let mut updated = self.clone();
        updated.specialization = specialization;
        updated
    }

    /// Records a completed building and applies its territory-capacity effect.
    ///
    /// # Errors
    ///
    /// Returns an error for a negative effect or checked-integer overflow.
    pub fn try_with_completed_building(
        &self,
        building: CityBuildingType,
        max_hexes_delta: i64,
    ) -> Result<Self, CityBuildError> {
        if self.buildings.contains(&building) {
            return Err(CityBuildError::DuplicateBuilding(building));
        }
        if max_hexes_delta < 0 {
            return Err(CityBuildError::NegativeMaxHexesDelta(max_hexes_delta));
        }
        let mut updated = self.clone();
        updated.max_hexes = updated
            .max_hexes
            .checked_add(max_hexes_delta)
            .ok_or(CityBuildError::MaxHexesOverflow)?;
        updated.buildings.insert(building);
        Ok(updated)
    }

    /// Records a completed world wonder in its hosting city.
    ///
    /// # Errors
    ///
    /// Returns an error when the city already hosts the wonder.
    pub fn try_with_completed_wonder(&self, wonder: WonderType) -> Result<Self, CityBuildError> {
        if self.wonders.contains(&wonder) {
            return Err(CityBuildError::DuplicateWonder(wonder));
        }
        let mut updated = self.clone();
        updated.wonders.insert(wonder);
        Ok(updated)
    }

    /// Applies an authoritative city-combat result.
    #[must_use]
    pub fn after_combat(&self, owner_player_id: PlayerId, hit_points: Option<i64>) -> Self {
        let mut updated = self.clone();
        updated.owner_player_id = owner_player_id;
        updated.hit_points = hit_points;
        updated
    }
}

pub(super) fn validate_numeric_values(
    population: i64,
    stored_food: i64,
    max_hexes: i64,
    territory_radius: i64,
    production_overflow: i64,
    hit_points: Option<i64>,
) -> Result<(), CityBuildError> {
    if population <= 0 {
        return Err(CityBuildError::NonPositivePopulation(population));
    }
    if stored_food < 0 {
        return Err(CityBuildError::NegativeStoredFood(stored_food));
    }
    if max_hexes <= 0 {
        return Err(CityBuildError::NonPositiveMaxHexes(max_hexes));
    }
    if territory_radius < 0 {
        return Err(CityBuildError::NegativeTerritoryRadius(territory_radius));
    }
    if production_overflow < 0 {
        return Err(CityBuildError::NegativeProductionOverflow(
            production_overflow,
        ));
    }
    if hit_points.is_some_and(|value| value <= 0) {
        return Err(CityBuildError::NonPositiveHitPoints(
            hit_points.unwrap_or_default(),
        ));
    }
    Ok(())
}

fn first_duplicate<T: Copy + Eq>(values: &[T]) -> Option<T> {
    values
        .iter()
        .enumerate()
        .find_map(|(index, value)| values[..index].contains(value).then_some(*value))
}
