use crate::{ArtifactId, CityId, HexCoord, UnitId};

/// Stable artifact category.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Ord, PartialEq, PartialOrd)]
pub enum WorldArtifactType {
    AncientImperialCrown,
    AstronomersTablets,
    ProphetMask,
    HeroSword,
    MerchantsSeal,
    FirstPeoplesChronicle,
    TempleReliquary,
    QueensMirror,
}

impl WorldArtifactType {
    /// Returns the city defense and hit-point bonus while stored in a city.
    #[must_use]
    pub const fn stored_city_defense_bonus(self) -> i32 {
        match self {
            Self::AncientImperialCrown | Self::TempleReliquary => 1,
            Self::AstronomersTablets
            | Self::ProphetMask
            | Self::HeroSword
            | Self::MerchantsSeal
            | Self::FirstPeoplesChronicle
            | Self::QueensMirror => 0,
        }
    }
}

/// Canonical location of one world artifact.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum WorldArtifactLocation {
    /// Artifact placed on the map.
    Map(HexCoord),
    /// Artifact carried by a unit.
    Carried(UnitId),
    /// Artifact stored in a city.
    Stored(CityId),
    /// Artifact currently excavated by a unit.
    Excavation {
        /// Excavating unit.
        unit_id: UnitId,
        /// Original map coordinate.
        coordinate: HexCoord,
        /// Turns remaining.
        remaining_turns: u32,
    },
}

/// Invalid transition in the current artifact location state machine.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum ArtifactTransitionError {
    /// Excavation duration must be strictly positive.
    InvalidExcavationDuration,
    /// The requested transition does not match the persisted location.
    LocationMismatch,
}

impl core::fmt::Display for ArtifactTransitionError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::InvalidExcavationDuration => {
                formatter.write_str("artifact excavation duration must be positive")
            }
            Self::LocationMismatch => {
                formatter.write_str("artifact transition does not match its current location")
            }
        }
    }
}

impl std::error::Error for ArtifactTransitionError {}

impl WorldArtifactLocation {
    /// Returns a map coordinate when the artifact occupies a tile.
    #[must_use]
    pub const fn map_coordinate(&self) -> Option<HexCoord> {
        match self {
            Self::Map(coordinate) | Self::Excavation { coordinate, .. } => Some(*coordinate),
            Self::Carried(_) | Self::Stored(_) => None,
        }
    }
}

/// Artifact entity owned by the canonical game aggregate.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct WorldArtifact {
    id: ArtifactId,
    artifact_type: WorldArtifactType,
    location: WorldArtifactLocation,
}

impl WorldArtifact {
    /// Creates an artifact from validated value objects.
    #[must_use]
    pub const fn new(
        id: ArtifactId,
        artifact_type: WorldArtifactType,
        location: WorldArtifactLocation,
    ) -> Self {
        Self {
            id,
            artifact_type,
            location,
        }
    }

    /// Returns the artifact identifier.
    #[must_use]
    pub const fn id(&self) -> &ArtifactId {
        &self.id
    }

    /// Returns the stable category.
    #[must_use]
    pub const fn artifact_type(&self) -> WorldArtifactType {
        self.artifact_type
    }

    /// Returns the canonical location.
    #[must_use]
    pub const fn location(&self) -> &WorldArtifactLocation {
        &self.location
    }

    /// Starts excavation from the matching map coordinate.
    ///
    /// # Errors
    /// Returns an error for zero duration or a non-matching map location.
    pub fn try_start_excavation(
        &self,
        unit_id: UnitId,
        coordinate: HexCoord,
        remaining_turns: u32,
    ) -> Result<Self, ArtifactTransitionError> {
        if remaining_turns == 0 {
            return Err(ArtifactTransitionError::InvalidExcavationDuration);
        }
        if self.location != WorldArtifactLocation::Map(coordinate) {
            return Err(ArtifactTransitionError::LocationMismatch);
        }
        let mut updated = self.clone();
        updated.location = WorldArtifactLocation::Excavation {
            unit_id,
            coordinate,
            remaining_turns,
        };
        Ok(updated)
    }

    /// Advances a matching excavation and returns whether it completed.
    ///
    /// # Errors
    /// Returns an error when the unit, coordinate, or duration differs.
    pub fn try_advance_excavation(
        &self,
        unit_id: &UnitId,
        coordinate: HexCoord,
    ) -> Result<(Self, bool), ArtifactTransitionError> {
        let WorldArtifactLocation::Excavation {
            unit_id: excavator,
            coordinate: source,
            remaining_turns,
        } = &self.location
        else {
            return Err(ArtifactTransitionError::LocationMismatch);
        };
        if excavator != unit_id || *source != coordinate || *remaining_turns == 0 {
            return Err(ArtifactTransitionError::LocationMismatch);
        }
        let mut updated = self.clone();
        let completed = *remaining_turns == 1;
        updated.location = if completed {
            WorldArtifactLocation::Carried(unit_id.clone())
        } else {
            WorldArtifactLocation::Excavation {
                unit_id: unit_id.clone(),
                coordinate,
                remaining_turns: remaining_turns - 1,
            }
        };
        Ok((updated, completed))
    }

    /// Restores a matching excavation to its original map coordinate.
    ///
    /// # Errors
    /// Returns an error when another unit owns the excavation.
    pub fn try_cancel_excavation(&self, unit_id: &UnitId) -> Result<Self, ArtifactTransitionError> {
        let WorldArtifactLocation::Excavation {
            unit_id: excavator,
            coordinate,
            ..
        } = &self.location
        else {
            return Err(ArtifactTransitionError::LocationMismatch);
        };
        if excavator != unit_id {
            return Err(ArtifactTransitionError::LocationMismatch);
        }
        let mut updated = self.clone();
        updated.location = WorldArtifactLocation::Map(*coordinate);
        Ok(updated)
    }

    /// Stores an artifact carried by the matching unit.
    ///
    /// # Errors
    /// Returns an error when the artifact is not carried by that unit.
    pub fn try_store(
        &self,
        unit_id: &UnitId,
        city_id: CityId,
    ) -> Result<Self, ArtifactTransitionError> {
        if self.location != WorldArtifactLocation::Carried(unit_id.clone()) {
            return Err(ArtifactTransitionError::LocationMismatch);
        }
        let mut updated = self.clone();
        updated.location = WorldArtifactLocation::Stored(city_id);
        Ok(updated)
    }

    /// Transfers a stored artifact between the matching cities.
    ///
    /// # Errors
    /// Returns an error when the source city does not store the artifact.
    pub fn try_transfer_stored(
        &self,
        source_city_id: &CityId,
        target_city_id: CityId,
    ) -> Result<Self, ArtifactTransitionError> {
        if self.location != WorldArtifactLocation::Stored(source_city_id.clone()) {
            return Err(ArtifactTransitionError::LocationMismatch);
        }
        let mut updated = self.clone();
        updated.location = WorldArtifactLocation::Stored(target_city_id);
        Ok(updated)
    }

    /// Drops an artifact when its combat carrier or storage city was defeated.
    #[must_use]
    pub fn after_combat_loss(
        &self,
        unit_id: Option<&UnitId>,
        city_id: Option<&CityId>,
        coordinate: HexCoord,
    ) -> Self {
        let should_drop = match &self.location {
            WorldArtifactLocation::Carried(value)
            | WorldArtifactLocation::Excavation { unit_id: value, .. } => unit_id == Some(value),
            WorldArtifactLocation::Stored(value) => city_id == Some(value),
            WorldArtifactLocation::Map(_) => false,
        };
        let mut updated = self.clone();
        if should_drop {
            updated.location = WorldArtifactLocation::Map(coordinate);
        }
        updated
    }

    pub(crate) fn restore_excavation(&mut self, unit_id: &UnitId) {
        let WorldArtifactLocation::Excavation {
            unit_id: excavator,
            coordinate,
            ..
        } = &self.location
        else {
            return;
        };
        if excavator == unit_id {
            self.location = WorldArtifactLocation::Map(*coordinate);
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::{ArtifactId, CityId, HexCoord, UnitId};

    use super::{ArtifactTransitionError, WorldArtifact, WorldArtifactLocation, WorldArtifactType};

    #[test]
    fn artifact_location_machine_enforces_valid_transitions() {
        let unit = UnitId::new("unit").expect("unit id");
        let other_unit = UnitId::new("other-unit").expect("unit id");
        let source = CityId::new("source").expect("city id");
        let target = CityId::new("target").expect("city id");
        let coordinate = HexCoord::new(1, 2);
        let artifact = WorldArtifact::new(
            ArtifactId::new("artifact").expect("artifact id"),
            WorldArtifactType::HeroSword,
            WorldArtifactLocation::Map(coordinate),
        );
        assert_eq!(
            artifact.try_start_excavation(unit.clone(), coordinate, 0),
            Err(ArtifactTransitionError::InvalidExcavationDuration)
        );
        assert_eq!(
            ArtifactTransitionError::InvalidExcavationDuration.to_string(),
            "artifact excavation duration must be positive"
        );
        assert_eq!(
            ArtifactTransitionError::LocationMismatch.to_string(),
            "artifact transition does not match its current location"
        );
        assert_eq!(
            artifact.try_start_excavation(unit.clone(), HexCoord::new(2, 2), 2),
            Err(ArtifactTransitionError::LocationMismatch)
        );
        assert_eq!(
            artifact.try_advance_excavation(&unit, coordinate),
            Err(ArtifactTransitionError::LocationMismatch)
        );
        let excavating = artifact
            .try_start_excavation(unit.clone(), coordinate, 2)
            .expect("start excavation");
        assert_eq!(
            excavating.try_advance_excavation(&other_unit, coordinate),
            Err(ArtifactTransitionError::LocationMismatch)
        );
        assert_eq!(
            excavating.try_cancel_excavation(&other_unit),
            Err(ArtifactTransitionError::LocationMismatch)
        );
        assert_eq!(
            excavating
                .try_cancel_excavation(&unit)
                .expect("cancel excavation")
                .location(),
            &WorldArtifactLocation::Map(coordinate)
        );
        let invalid_excavation = WorldArtifact::new(
            ArtifactId::new("invalid-excavation").expect("artifact id"),
            WorldArtifactType::HeroSword,
            WorldArtifactLocation::Excavation {
                unit_id: unit.clone(),
                coordinate,
                remaining_turns: 0,
            },
        );
        assert_eq!(
            invalid_excavation.try_advance_excavation(&unit, coordinate),
            Err(ArtifactTransitionError::LocationMismatch)
        );
        let (continued, completed) = excavating
            .try_advance_excavation(&unit, coordinate)
            .expect("continue excavation");
        assert!(!completed);
        let (carried, completed) = continued
            .try_advance_excavation(&unit, coordinate)
            .expect("complete excavation");
        assert!(completed);
        let stored = carried
            .try_store(&unit, source.clone())
            .expect("store artifact");
        assert_eq!(
            carried.try_store(&other_unit, source.clone()),
            Err(ArtifactTransitionError::LocationMismatch)
        );
        assert_eq!(
            stored.try_transfer_stored(&target, source.clone()),
            Err(ArtifactTransitionError::LocationMismatch)
        );
        assert_eq!(
            stored
                .try_transfer_stored(&source, target.clone())
                .expect("transfer")
                .location(),
            &WorldArtifactLocation::Stored(target)
        );
        assert!(stored.try_cancel_excavation(&unit).is_err());
    }

    #[test]
    fn combat_loss_only_drops_an_artifact_owned_by_the_defeated_entity() {
        let unit = UnitId::new("unit").expect("unit id");
        let city = CityId::new("city").expect("city id");
        let coordinate = HexCoord::new(3, 4);
        for location in [
            WorldArtifactLocation::Carried(unit.clone()),
            WorldArtifactLocation::Excavation {
                unit_id: unit.clone(),
                coordinate: HexCoord::new(1, 2),
                remaining_turns: 1,
            },
            WorldArtifactLocation::Stored(city.clone()),
        ] {
            let artifact = WorldArtifact::new(
                ArtifactId::new("artifact").expect("artifact id"),
                WorldArtifactType::HeroSword,
                location,
            );
            assert_eq!(
                artifact
                    .after_combat_loss(Some(&unit), Some(&city), coordinate)
                    .location(),
                &WorldArtifactLocation::Map(coordinate)
            );
        }

        let map = WorldArtifact::new(
            ArtifactId::new("map-artifact").expect("artifact id"),
            WorldArtifactType::HeroSword,
            WorldArtifactLocation::Map(HexCoord::new(0, 0)),
        );
        assert_eq!(
            map.after_combat_loss(Some(&unit), Some(&city), coordinate)
                .location(),
            map.location()
        );
    }
}
