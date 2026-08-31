use aonw_domain::{
    CityId, CityProductionTarget, CitySpecializationType, StrategicResourceStockpile, UnitKind,
};

use crate::CommandRejectionCode;

/// Buys one bounded production increment for a controlled city's finite queue.
#[derive(Clone, Copy, Debug)]
pub struct RushProductionCommand<'command> {
    expected_revision: u64,
    city_id: &'command CityId,
}

impl<'command> RushProductionCommand<'command> {
    /// Creates the revision-bound command.
    #[must_use]
    pub const fn new(expected_revision: u64, city_id: &'command CityId) -> Self {
        Self {
            expected_revision,
            city_id,
        }
    }
    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
    pub(crate) const fn city_id(self) -> &'command CityId {
        self.city_id
    }
}

/// Starts construction of one building in a controlled city.
#[derive(Clone, Copy, Debug)]
pub struct StartBuildingCommand<'command> {
    expected_revision: u64,
    city_id: &'command CityId,
    building: aonw_domain::CityBuildingType,
}

impl<'command> StartBuildingCommand<'command> {
    /// Creates the revision-bound command.
    #[must_use]
    pub const fn new(
        expected_revision: u64,
        city_id: &'command CityId,
        building: aonw_domain::CityBuildingType,
    ) -> Self {
        Self {
            expected_revision,
            city_id,
            building,
        }
    }
    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
    pub(crate) const fn city_id(self) -> &'command CityId {
        self.city_id
    }
    pub(crate) const fn building(self) -> aonw_domain::CityBuildingType {
        self.building
    }
}

/// Starts production of one unit with an optional strategic-cost choice.
#[derive(Clone, Copy, Debug)]
pub struct StartUnitProductionCommand<'command> {
    expected_revision: u64,
    city_id: &'command CityId,
    unit: UnitKind,
    resource_option_index: Option<u32>,
}

impl<'command> StartUnitProductionCommand<'command> {
    /// Creates the revision-bound command.
    #[must_use]
    pub const fn new(
        expected_revision: u64,
        city_id: &'command CityId,
        unit: UnitKind,
        resource_option_index: Option<u32>,
    ) -> Self {
        Self {
            expected_revision,
            city_id,
            unit,
            resource_option_index,
        }
    }
    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
    pub(crate) const fn city_id(self) -> &'command CityId {
        self.city_id
    }
    pub(crate) const fn unit(self) -> UnitKind {
        self.unit
    }
    pub(crate) const fn resource_option_index(self) -> Option<u32> {
        self.resource_option_index
    }
}

/// Starts one continuous city project.
#[derive(Clone, Copy, Debug)]
pub struct StartCityProjectCommand<'command> {
    expected_revision: u64,
    city_id: &'command CityId,
    project: aonw_domain::CityProjectType,
}

impl<'command> StartCityProjectCommand<'command> {
    /// Creates the revision-bound command.
    #[must_use]
    pub const fn new(
        expected_revision: u64,
        city_id: &'command CityId,
        project: aonw_domain::CityProjectType,
    ) -> Self {
        Self {
            expected_revision,
            city_id,
            project,
        }
    }
    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
    pub(crate) const fn city_id(self) -> &'command CityId {
        self.city_id
    }
    pub(crate) const fn project(self) -> aonw_domain::CityProjectType {
        self.project
    }
}

/// Starts construction of one globally unique world wonder.
#[derive(Clone, Copy, Debug)]
pub struct StartWonderCommand<'command> {
    expected_revision: u64,
    city_id: &'command CityId,
    wonder: aonw_domain::WonderType,
}

impl<'command> StartWonderCommand<'command> {
    /// Creates the revision-bound command.
    #[must_use]
    pub const fn new(
        expected_revision: u64,
        city_id: &'command CityId,
        wonder: aonw_domain::WonderType,
    ) -> Self {
        Self {
            expected_revision,
            city_id,
            wonder,
        }
    }
    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
    pub(crate) const fn city_id(self) -> &'command CityId {
        self.city_id
    }
    pub(crate) const fn wonder(self) -> aonw_domain::WonderType {
        self.wonder
    }
}

/// Selects one long-term city specialization.
#[derive(Clone, Copy, Debug)]
pub struct SetCitySpecializationCommand<'command> {
    expected_revision: u64,
    city_id: &'command CityId,
    specialization: CitySpecializationType,
}

impl<'command> SetCitySpecializationCommand<'command> {
    /// Creates the revision-bound command.
    #[must_use]
    pub const fn new(
        expected_revision: u64,
        city_id: &'command CityId,
        specialization: CitySpecializationType,
    ) -> Self {
        Self {
            expected_revision,
            city_id,
            specialization,
        }
    }
    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
    pub(crate) const fn city_id(self) -> &'command CityId {
        self.city_id
    }
    pub(crate) const fn specialization(self) -> CitySpecializationType {
        self.specialization
    }
}

/// Revision-bound query for all engine-owned production choices of one city.
#[derive(Clone, Copy, Debug)]
pub struct ProductionOptionsQuery<'query> {
    expected_revision: u64,
    city_id: &'query CityId,
}

impl<'query> ProductionOptionsQuery<'query> {
    /// Creates the query.
    #[must_use]
    pub const fn new(expected_revision: u64, city_id: &'query CityId) -> Self {
        Self {
            expected_revision,
            city_id,
        }
    }
    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
    pub(crate) const fn city_id(self) -> &'query CityId {
        self.city_id
    }
}

/// One target, exact paced cost, and the first authoritative blocker.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ProductionOption {
    target: CityProductionTarget,
    cost: i64,
    rejection: Option<CommandRejectionCode>,
}

impl ProductionOption {
    pub(crate) const fn new(
        target: CityProductionTarget,
        cost: i64,
        rejection: Option<CommandRejectionCode>,
    ) -> Self {
        Self {
            target,
            cost,
            rejection,
        }
    }
    /// Returns the typed target.
    #[must_use]
    pub const fn target(self) -> CityProductionTarget {
        self.target
    }
    /// Returns the exact pace-adjusted cost; continuous projects use zero.
    #[must_use]
    pub const fn cost(self) -> i64 {
        self.cost
    }
    /// Returns the first blocker, or `None` when the target is legal.
    #[must_use]
    pub const fn rejection(self) -> Option<CommandRejectionCode> {
        self.rejection
    }
    /// Returns whether the command path accepts this target now.
    #[must_use]
    pub const fn is_available(self) -> bool {
        self.rejection.is_none()
    }
}

/// Unit option including ordered strategic alternatives and affordable indices.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct UnitProductionOption {
    option: ProductionOption,
    resource_options: Box<[StrategicResourceStockpile]>,
    affordable_resource_option_indices: Box<[u32]>,
}

impl UnitProductionOption {
    pub(crate) fn new(
        option: ProductionOption,
        resource_options: Vec<StrategicResourceStockpile>,
        affordable_resource_option_indices: Vec<u32>,
    ) -> Self {
        Self {
            option,
            resource_options: resource_options.into_boxed_slice(),
            affordable_resource_option_indices: affordable_resource_option_indices
                .into_boxed_slice(),
        }
    }
    /// Returns target, cost, and primary blocker.
    #[must_use]
    pub const fn option(&self) -> ProductionOption {
        self.option
    }
    /// Returns ordered strategic-resource alternatives.
    #[must_use]
    pub const fn resource_options(&self) -> &[StrategicResourceStockpile] {
        &self.resource_options
    }
    /// Returns alternatives covered after refunding this city's current queue.
    #[must_use]
    pub const fn affordable_resource_option_indices(&self) -> &[u32] {
        &self.affordable_resource_option_indices
    }
}

/// One specialization and its first authoritative blocker.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct CitySpecializationOption {
    specialization: CitySpecializationType,
    required_building: aonw_domain::CityBuildingType,
    rejection: Option<CommandRejectionCode>,
}

impl CitySpecializationOption {
    pub(crate) const fn new(
        specialization: CitySpecializationType,
        required_building: aonw_domain::CityBuildingType,
        rejection: Option<CommandRejectionCode>,
    ) -> Self {
        Self {
            specialization,
            required_building,
            rejection,
        }
    }
    /// Returns specialization identity.
    #[must_use]
    pub const fn specialization(self) -> CitySpecializationType {
        self.specialization
    }
    /// Returns its prerequisite building.
    #[must_use]
    pub const fn required_building(self) -> aonw_domain::CityBuildingType {
        self.required_building
    }
    /// Returns the first blocker, or `None` when selectable.
    #[must_use]
    pub const fn rejection(self) -> Option<CommandRejectionCode> {
        self.rejection
    }
}

/// Complete engine-owned production view for one controlled city.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ProductionOptions {
    revision: u64,
    city_id: CityId,
    current_target: Option<CityProductionTarget>,
    invested_production: i64,
    production_overflow: i64,
    buildings: Box<[ProductionOption]>,
    units: Box<[UnitProductionOption]>,
    projects: Box<[ProductionOption]>,
    wonders: Box<[ProductionOption]>,
    specializations: Box<[CitySpecializationOption]>,
}

impl ProductionOptions {
    #[allow(clippy::too_many_arguments)]
    pub(crate) fn new(
        revision: u64,
        city_id: CityId,
        current_target: Option<CityProductionTarget>,
        invested_production: i64,
        production_overflow: i64,
        buildings: Vec<ProductionOption>,
        units: Vec<UnitProductionOption>,
        projects: Vec<ProductionOption>,
        wonders: Vec<ProductionOption>,
        specializations: Vec<CitySpecializationOption>,
    ) -> Self {
        Self {
            revision,
            city_id,
            current_target,
            invested_production,
            production_overflow,
            buildings: buildings.into_boxed_slice(),
            units: units.into_boxed_slice(),
            projects: projects.into_boxed_slice(),
            wonders: wonders.into_boxed_slice(),
            specializations: specializations.into_boxed_slice(),
        }
    }
    /// Returns the canonical revision used by every option.
    #[must_use]
    pub const fn revision(&self) -> u64 {
        self.revision
    }
    /// Returns the queried city.
    #[must_use]
    pub const fn city_id(&self) -> &CityId {
        &self.city_id
    }
    /// Returns the active target, when present.
    #[must_use]
    pub const fn current_target(&self) -> Option<CityProductionTarget> {
        self.current_target
    }
    /// Returns currently invested production.
    #[must_use]
    pub const fn invested_production(&self) -> i64 {
        self.invested_production
    }
    /// Returns stored production overflow.
    #[must_use]
    pub const fn production_overflow(&self) -> i64 {
        self.production_overflow
    }
    /// Returns every building in canonical content order.
    #[must_use]
    pub const fn buildings(&self) -> &[ProductionOption] {
        &self.buildings
    }
    /// Returns every unit in canonical content order.
    #[must_use]
    pub const fn units(&self) -> &[UnitProductionOption] {
        &self.units
    }
    /// Returns both continuous projects in canonical identity order.
    #[must_use]
    pub const fn projects(&self) -> &[ProductionOption] {
        &self.projects
    }
    /// Returns every wonder in canonical content order.
    #[must_use]
    pub const fn wonders(&self) -> &[ProductionOption] {
        &self.wonders
    }
    /// Returns every specialization and its prerequisite state.
    #[must_use]
    pub const fn specializations(&self) -> &[CitySpecializationOption] {
        &self.specializations
    }
}
