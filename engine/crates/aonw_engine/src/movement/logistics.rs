use aonw_domain::{
    CityId, Diplomacy, FogOfWar, HexCoord, InteractionState, StateRevision, TroopKind, Unit, UnitId,
};

use super::MovementSearchMetrics;
use crate::{CommandRejectionCode, DomainEvent, LogisticsExecution};

/// Revision-bound auto-exploration command.
#[derive(Clone, Copy, Debug)]
pub struct AutoExploreUnitCommand<'command> {
    expected_revision: u64,
    unit_id: &'command UnitId,
}

impl<'command> AutoExploreUnitCommand<'command> {
    /// Creates an auto-exploration command.
    #[must_use]
    pub const fn new(expected_revision: u64, unit_id: &'command UnitId) -> Self {
        Self {
            expected_revision,
            unit_id,
        }
    }

    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }

    pub(crate) const fn unit_id(self) -> &'command UnitId {
        self.unit_id
    }
}

/// Revision-bound cyclic merchant-route command.
#[derive(Clone, Copy, Debug)]
pub struct AssignMerchantTradeRouteCommand<'command> {
    expected_revision: u64,
    unit_id: &'command UnitId,
    destination_city_id: &'command CityId,
}

impl<'command> AssignMerchantTradeRouteCommand<'command> {
    /// Creates a merchant-route assignment.
    #[must_use]
    pub const fn new(
        expected_revision: u64,
        unit_id: &'command UnitId,
        destination_city_id: &'command CityId,
    ) -> Self {
        Self {
            expected_revision,
            unit_id,
            destination_city_id,
        }
    }

    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }

    pub(crate) const fn unit_id(self) -> &'command UnitId {
        self.unit_id
    }

    pub(crate) const fn destination_city_id(self) -> &'command CityId {
        self.destination_city_id
    }
}

/// Revision-bound explicit merchant travel command.
#[derive(Clone, Copy, Debug)]
pub struct MoveMerchantToCityCommand<'command> {
    expected_revision: u64,
    unit_id: &'command UnitId,
    destination_city_id: &'command CityId,
}

impl<'command> MoveMerchantToCityCommand<'command> {
    /// Creates explicit merchant travel.
    #[must_use]
    pub const fn new(
        expected_revision: u64,
        unit_id: &'command UnitId,
        destination_city_id: &'command CityId,
    ) -> Self {
        Self {
            expected_revision,
            unit_id,
            destination_city_id,
        }
    }

    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }

    pub(crate) const fn unit_id(self) -> &'command UnitId {
        self.unit_id
    }

    pub(crate) const fn destination_city_id(self) -> &'command CityId {
        self.destination_city_id
    }
}

/// Revision-bound troop-detachment command.
#[derive(Clone, Copy, Debug)]
pub struct DetachTroopCommand<'command> {
    expected_revision: u64,
    unit_id: &'command UnitId,
    troop_kind: TroopKind,
}

impl<'command> DetachTroopCommand<'command> {
    /// Creates a troop-detachment command.
    #[must_use]
    pub const fn new(
        expected_revision: u64,
        unit_id: &'command UnitId,
        troop_kind: TroopKind,
    ) -> Self {
        Self {
            expected_revision,
            unit_id,
            troop_kind,
        }
    }

    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }

    pub(crate) const fn unit_id(self) -> &'command UnitId {
        self.unit_id
    }

    pub(crate) const fn troop_kind(self) -> TroopKind {
        self.troop_kind
    }
}

/// Revision-bound options query for one unit's logistics actions.
#[derive(Clone, Copy, Debug)]
pub struct UnitLogisticsOptionsQuery<'query> {
    expected_revision: u64,
    unit_id: &'query UnitId,
}

impl<'query> UnitLogisticsOptionsQuery<'query> {
    /// Creates one recipient-owned logistics options query.
    #[must_use]
    pub const fn new(expected_revision: u64, unit_id: &'query UnitId) -> Self {
        Self {
            expected_revision,
            unit_id,
        }
    }

    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }

    pub(crate) const fn unit_id(self) -> &'query UnitId {
        self.unit_id
    }
}

/// Deterministic auto-exploration option selected by the engine.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct AutoExploreOption {
    pub(crate) target: HexCoord,
    pub(crate) total_cost_units: u32,
    pub(crate) metrics: MovementSearchMetrics,
}

impl AutoExploreOption {
    /// Returns the selected target.
    #[must_use]
    pub const fn target(self) -> HexCoord {
        self.target
    }
    /// Returns the complete route cost.
    #[must_use]
    pub const fn total_cost_units(self) -> u32 {
        self.total_cost_units
    }
    /// Returns bounded deterministic search counters.
    #[must_use]
    pub const fn search_metrics(self) -> MovementSearchMetrics {
        self.metrics
    }
}

/// One city accepted by merchant routing rules.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MerchantDestinationOption {
    pub(crate) city_id: CityId,
    pub(crate) total_cost_units: u32,
}

impl MerchantDestinationOption {
    /// Returns the city identity.
    #[must_use]
    pub const fn city_id(&self) -> &CityId {
        &self.city_id
    }
    /// Returns the complete route cost.
    #[must_use]
    pub const fn total_cost_units(&self) -> u32 {
        self.total_cost_units
    }
}

/// One exact troop/destination pair accepted for detachment.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct DetachmentOption {
    pub(crate) troop_kind: TroopKind,
    pub(crate) destination: HexCoord,
}

impl DetachmentOption {
    /// Returns the troop kind.
    #[must_use]
    pub const fn troop_kind(self) -> TroopKind {
        self.troop_kind
    }
    /// Returns the deterministic destination.
    #[must_use]
    pub const fn destination(self) -> HexCoord {
        self.destination
    }
}

/// Complete engine-owned options required by a new client.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct UnitLogisticsOptions {
    pub(crate) revision: u64,
    pub(crate) unit_id: UnitId,
    pub(crate) auto_explore: Option<AutoExploreOption>,
    pub(crate) merchant_route_destinations: Box<[MerchantDestinationOption]>,
    pub(crate) merchant_travel_destinations: Box<[MerchantDestinationOption]>,
    pub(crate) detachments: Box<[DetachmentOption]>,
}

impl UnitLogisticsOptions {
    /// Returns the queried revision.
    #[must_use]
    pub const fn revision(&self) -> u64 {
        self.revision
    }
    /// Returns the queried unit.
    #[must_use]
    pub const fn unit_id(&self) -> &UnitId {
        &self.unit_id
    }
    /// Returns the selected auto-exploration option, when legal.
    #[must_use]
    pub const fn auto_explore(&self) -> Option<AutoExploreOption> {
        self.auto_explore
    }
    /// Returns valid cyclic-route destinations in city-id order.
    #[must_use]
    pub const fn merchant_route_destinations(&self) -> &[MerchantDestinationOption] {
        &self.merchant_route_destinations
    }
    /// Returns valid explicit-travel destinations in city-id order.
    #[must_use]
    pub const fn merchant_travel_destinations(&self) -> &[MerchantDestinationOption] {
        &self.merchant_travel_destinations
    }
    /// Returns exact detachment options in troop-kind order.
    #[must_use]
    pub const fn detachments(&self) -> &[DetachmentOption] {
        &self.detachments
    }
}

/// Stable failure shared by logistics commands and options queries.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MovementLogisticsError {
    code: CommandRejectionCode,
}

impl MovementLogisticsError {
    pub(crate) const fn new(code: CommandRejectionCode) -> Self {
        Self { code }
    }

    /// Returns the stable language-neutral rejection code.
    #[must_use]
    pub const fn code(&self) -> CommandRejectionCode {
        self.code
    }
}

impl core::fmt::Display for MovementLogisticsError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        formatter.write_str(self.code.as_str())
    }
}

impl std::error::Error for MovementLogisticsError {}

pub(crate) struct MovementLogisticsUpdate {
    pub(crate) revision: StateRevision,
    pub(crate) units: Vec<Unit>,
    pub(crate) fog_of_war: FogOfWar,
    pub(crate) diplomacy: Diplomacy,
    pub(crate) interaction: InteractionState,
    pub(crate) events: Box<[DomainEvent]>,
    pub(crate) evidence: LogisticsExecution,
}
