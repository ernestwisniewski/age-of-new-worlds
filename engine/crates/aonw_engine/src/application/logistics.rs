use aonw_domain::{CityId, HexCoord, TroopKind, UnitId};

use crate::UnitMovementExecution;

/// Accepted fact that auto-exploration selected an engine-owned target.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct AutoExplorePlannedEvent {
    unit_id: UnitId,
    target: HexCoord,
}

impl AutoExplorePlannedEvent {
    pub(crate) const fn new(unit_id: UnitId, target: HexCoord) -> Self {
        Self { unit_id, target }
    }
    /// Returns the scout identity.
    #[must_use]
    pub const fn unit_id(&self) -> &UnitId {
        &self.unit_id
    }
    /// Returns the selected target.
    #[must_use]
    pub const fn target(&self) -> HexCoord {
        self.target
    }
}

/// Accepted fact that a cyclic merchant route was assigned.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MerchantRouteAssignedEvent {
    unit: UnitId,
    origin_city: CityId,
    destination_city: CityId,
}

impl MerchantRouteAssignedEvent {
    pub(crate) const fn new(
        unit_id: UnitId,
        origin_city_id: CityId,
        destination_city_id: CityId,
    ) -> Self {
        Self {
            unit: unit_id,
            origin_city: origin_city_id,
            destination_city: destination_city_id,
        }
    }
    /// Returns the merchant identity.
    #[must_use]
    pub const fn unit_id(&self) -> &UnitId {
        &self.unit
    }
    /// Returns the route origin.
    #[must_use]
    pub const fn origin_city_id(&self) -> &CityId {
        &self.origin_city
    }
    /// Returns the route destination.
    #[must_use]
    pub const fn destination_city_id(&self) -> &CityId {
        &self.destination_city
    }
}

/// Accepted fact that explicit merchant travel was queued.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MerchantTravelQueuedEvent {
    unit_id: UnitId,
    destination_city_id: CityId,
}

impl MerchantTravelQueuedEvent {
    pub(crate) const fn new(unit_id: UnitId, destination_city_id: CityId) -> Self {
        Self {
            unit_id,
            destination_city_id,
        }
    }
    /// Returns the merchant identity.
    #[must_use]
    pub const fn unit_id(&self) -> &UnitId {
        &self.unit_id
    }
    /// Returns the destination city.
    #[must_use]
    pub const fn destination_city_id(&self) -> &CityId {
        &self.destination_city_id
    }
}

/// Accepted fact that one army troop became an independent unit.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct TroopDetachedEvent {
    source_unit_id: UnitId,
    detached_unit_id: UnitId,
    troop_kind: TroopKind,
    destination: HexCoord,
}

impl TroopDetachedEvent {
    pub(crate) const fn new(
        source_unit_id: UnitId,
        detached_unit_id: UnitId,
        troop_kind: TroopKind,
        destination: HexCoord,
    ) -> Self {
        Self {
            source_unit_id,
            detached_unit_id,
            troop_kind,
            destination,
        }
    }
    /// Returns the source army unit.
    #[must_use]
    pub const fn source_unit_id(&self) -> &UnitId {
        &self.source_unit_id
    }
    /// Returns the new independent unit.
    #[must_use]
    pub const fn detached_unit_id(&self) -> &UnitId {
        &self.detached_unit_id
    }
    /// Returns the detached troop kind.
    #[must_use]
    pub const fn troop_kind(&self) -> TroopKind {
        self.troop_kind
    }
    /// Returns the spawn coordinate.
    #[must_use]
    pub const fn destination(&self) -> HexCoord {
        self.destination
    }
}

/// Exact deterministic evidence for one logistics command.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum LogisticsExecution {
    AutoExplore {
        unit_id: UnitId,
        target: HexCoord,
        movement: Option<UnitMovementExecution>,
    },
    MerchantRouteAssigned {
        unit_id: UnitId,
        origin_city_id: CityId,
        destination_city_id: CityId,
        steps: Box<[aonw_domain::MovementStep]>,
        transport_network_fingerprint: Box<str>,
    },
    MerchantTravelQueued {
        unit_id: UnitId,
        destination_city_id: CityId,
        steps: Box<[aonw_domain::MovementStep]>,
    },
    TroopDetached {
        source_unit_id: UnitId,
        detached_unit_id: UnitId,
        troop_kind: TroopKind,
        destination: HexCoord,
    },
}
