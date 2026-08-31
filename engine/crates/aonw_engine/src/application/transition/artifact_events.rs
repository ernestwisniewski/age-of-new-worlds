use aonw_domain::{ArtifactId, CityId, HexCoord, PlayerId, UnitId};

/// Accepted fact that one unit started excavating an artifact.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ArtifactExcavationStartedEvent {
    artifact_id: ArtifactId,
    owner_player_id: PlayerId,
    unit_id: UnitId,
    coordinate: HexCoord,
}

impl ArtifactExcavationStartedEvent {
    pub(crate) const fn new(
        artifact_id: ArtifactId,
        owner_player_id: PlayerId,
        unit_id: UnitId,
        coordinate: HexCoord,
    ) -> Self {
        Self {
            artifact_id,
            owner_player_id,
            unit_id,
            coordinate,
        }
    }

    /// Returns the excavated artifact.
    #[must_use]
    pub const fn artifact_id(&self) -> &ArtifactId {
        &self.artifact_id
    }

    /// Returns the player controlling the excavation.
    #[must_use]
    pub const fn owner_player_id(&self) -> &PlayerId {
        &self.owner_player_id
    }

    /// Returns the excavating unit.
    #[must_use]
    pub const fn unit_id(&self) -> &UnitId {
        &self.unit_id
    }

    /// Returns the excavation coordinate.
    #[must_use]
    pub const fn coordinate(&self) -> HexCoord {
        self.coordinate
    }
}

/// Accepted fact that one completed excavation moved an artifact to a unit.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ArtifactCarriedEvent {
    artifact_id: ArtifactId,
    owner_player_id: PlayerId,
    unit_id: UnitId,
    coordinate: HexCoord,
}

impl ArtifactCarriedEvent {
    pub(crate) const fn new(
        artifact_id: ArtifactId,
        owner_player_id: PlayerId,
        unit_id: UnitId,
        coordinate: HexCoord,
    ) -> Self {
        Self {
            artifact_id,
            owner_player_id,
            unit_id,
            coordinate,
        }
    }

    /// Returns the carried artifact.
    #[must_use]
    pub const fn artifact_id(&self) -> &ArtifactId {
        &self.artifact_id
    }

    /// Returns the player controlling the carrier.
    #[must_use]
    pub const fn owner_player_id(&self) -> &PlayerId {
        &self.owner_player_id
    }

    /// Returns the carrier.
    #[must_use]
    pub const fn unit_id(&self) -> &UnitId {
        &self.unit_id
    }

    /// Returns the carrier coordinate at completion.
    #[must_use]
    pub const fn coordinate(&self) -> HexCoord {
        self.coordinate
    }
}

/// Accepted fact that an artifact moved into one city storage slot.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ArtifactStoredEvent {
    artifact_id: ArtifactId,
    owner_player_id: PlayerId,
    source_unit_id: Option<UnitId>,
    city_id: CityId,
    coordinate: HexCoord,
}

impl ArtifactStoredEvent {
    pub(crate) const fn new(
        artifact_id: ArtifactId,
        owner_player_id: PlayerId,
        source_unit_id: Option<UnitId>,
        city_id: CityId,
        coordinate: HexCoord,
    ) -> Self {
        Self {
            artifact_id,
            owner_player_id,
            source_unit_id,
            city_id,
            coordinate,
        }
    }

    /// Returns the stored artifact.
    #[must_use]
    pub const fn artifact_id(&self) -> &ArtifactId {
        &self.artifact_id
    }

    /// Returns the player owning the destination city.
    #[must_use]
    pub const fn owner_player_id(&self) -> &PlayerId {
        &self.owner_player_id
    }

    /// Returns the carrier for direct storage, absent for a city-to-city trade.
    #[must_use]
    pub const fn source_unit_id(&self) -> Option<&UnitId> {
        self.source_unit_id.as_ref()
    }

    /// Returns the destination city.
    #[must_use]
    pub const fn city_id(&self) -> &CityId {
        &self.city_id
    }

    /// Returns the destination city center.
    #[must_use]
    pub const fn coordinate(&self) -> HexCoord {
        self.coordinate
    }
}
