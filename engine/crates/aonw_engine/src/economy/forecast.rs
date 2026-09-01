use aonw_domain::{CityId, PlayerId, UnitKind};

use crate::StabilityBand;

/// Revision-bound projection of the actor's next economy settlement.
#[derive(Clone, Copy, Debug)]
pub struct EconomyForecastQuery {
    expected_revision: u64,
}

impl EconomyForecastQuery {
    /// Creates a deterministic actor-owned economy forecast.
    #[must_use]
    pub const fn new(expected_revision: u64) -> Self {
        Self { expected_revision }
    }

    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
}

/// One city's ordinary gold contribution to the next economy settlement.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CityGoldIncomeSource {
    city_id: CityId,
    amount: i64,
}

impl CityGoldIncomeSource {
    pub(crate) const fn new(city_id: CityId, amount: i64) -> Self {
        Self { city_id, amount }
    }

    /// Returns the contributing city.
    #[must_use]
    pub const fn city_id(&self) -> &CityId {
        &self.city_id
    }

    /// Returns this city's non-project gold output.
    #[must_use]
    pub const fn amount(&self) -> i64 {
        self.amount
    }
}

/// One city's continuous wealth-project contribution.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct WealthProjectGoldIncomeSource {
    city_id: CityId,
    amount: i64,
}

impl WealthProjectGoldIncomeSource {
    pub(crate) const fn new(city_id: CityId, amount: i64) -> Self {
        Self { city_id, amount }
    }

    /// Returns the city running the project.
    #[must_use]
    pub const fn city_id(&self) -> &CityId {
        &self.city_id
    }

    /// Returns the project's converted gold output.
    #[must_use]
    pub const fn amount(&self) -> i64 {
        self.amount
    }
}

/// Upkeep charged to paid units of one type.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct UnitUpkeepSource {
    kind: UnitKind,
    paid_unit_count: i64,
    amount: i64,
}

impl UnitUpkeepSource {
    pub(crate) const fn new(kind: UnitKind, paid_unit_count: i64, amount: i64) -> Self {
        Self {
            kind,
            paid_unit_count,
            amount,
        }
    }

    /// Returns the charged unit type.
    #[must_use]
    pub const fn kind(self) -> UnitKind {
        self.kind
    }

    /// Returns how many units of this type are outside the free limit.
    #[must_use]
    pub const fn paid_unit_count(self) -> i64 {
        self.paid_unit_count
    }

    /// Returns the combined upkeep charged for this type.
    #[must_use]
    pub const fn amount(self) -> i64 {
        self.amount
    }
}

/// Exact unit-upkeep allocation used by turn settlement.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct UnitUpkeepBreakdown {
    upkeep_bearing_unit_count: i64,
    free_unit_count: i64,
    paid_unit_count: i64,
    total: i64,
    next_worker_upkeep: i64,
    sources: Box<[UnitUpkeepSource]>,
}

impl UnitUpkeepBreakdown {
    pub(crate) fn new(
        upkeep_bearing_unit_count: i64,
        free_unit_count: i64,
        paid_unit_count: i64,
        total: i64,
        next_worker_upkeep: i64,
        sources: Vec<UnitUpkeepSource>,
    ) -> Self {
        Self {
            upkeep_bearing_unit_count,
            free_unit_count,
            paid_unit_count,
            total,
            next_worker_upkeep,
            sources: sources.into_boxed_slice(),
        }
    }

    /// Returns the count of units participating in upkeep allocation.
    #[must_use]
    pub const fn upkeep_bearing_unit_count(&self) -> i64 {
        self.upkeep_bearing_unit_count
    }

    /// Returns the empire-wide free upkeep limit.
    #[must_use]
    pub const fn free_unit_count(&self) -> i64 {
        self.free_unit_count
    }

    /// Returns the count of upkeep-bearing units outside the free limit.
    #[must_use]
    pub const fn paid_unit_count(&self) -> i64 {
        self.paid_unit_count
    }

    /// Returns total gold charged on the next settlement.
    #[must_use]
    pub const fn total(&self) -> i64 {
        self.total
    }

    /// Returns the displayed marginal upkeep of the next worker.
    #[must_use]
    pub const fn next_worker_upkeep(&self) -> i64 {
        self.next_worker_upkeep
    }

    /// Returns charged unit groups in canonical unit-kind order.
    #[must_use]
    pub const fn sources(&self) -> &[UnitUpkeepSource] {
        &self.sources
    }
}

/// Complete source and cost evidence for the current effective stability.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct StabilityBreakdown {
    base_order: i64,
    building_sources: i64,
    luxury_sources: i64,
    technology_sources: i64,
    artifact_sources: i64,
    wonder_sources: i64,
    city_cost: i64,
    population_cost: i64,
    cohesion_cost: i64,
    conquered_city_cost: i64,
    war_weariness_cost: i64,
    hegemony_tax: i64,
    source_total: i64,
    cost_total: i64,
    relative_standing_adjustment: i64,
    effective_net: i64,
    band: StabilityBand,
}

impl StabilityBreakdown {
    #[allow(clippy::too_many_arguments)]
    pub(crate) const fn new(
        base_order: i64,
        building_sources: i64,
        luxury_sources: i64,
        technology_sources: i64,
        artifact_sources: i64,
        wonder_sources: i64,
        city_cost: i64,
        population_cost: i64,
        cohesion_cost: i64,
        conquered_city_cost: i64,
        war_weariness_cost: i64,
        hegemony_tax: i64,
        source_total: i64,
        cost_total: i64,
        relative_standing_adjustment: i64,
        effective_net: i64,
        band: StabilityBand,
    ) -> Self {
        Self {
            base_order,
            building_sources,
            luxury_sources,
            technology_sources,
            artifact_sources,
            wonder_sources,
            city_cost,
            population_cost,
            cohesion_cost,
            conquered_city_cost,
            war_weariness_cost,
            hegemony_tax,
            source_total,
            cost_total,
            relative_standing_adjustment,
            effective_net,
            band,
        }
    }

    /// Returns the base order source.
    #[must_use]
    pub const fn base_order(&self) -> i64 {
        self.base_order
    }
    /// Returns stability from completed order buildings.
    #[must_use]
    pub const fn building_sources(&self) -> i64 {
        self.building_sources
    }
    /// Returns stability from distinct controlled luxury resources.
    #[must_use]
    pub const fn luxury_sources(&self) -> i64 {
        self.luxury_sources
    }
    /// Returns stability from unlocked order technologies.
    #[must_use]
    pub const fn technology_sources(&self) -> i64 {
        self.technology_sources
    }
    /// Returns stability from distinct stored artifact types.
    #[must_use]
    pub const fn artifact_sources(&self) -> i64 {
        self.artifact_sources
    }
    /// Returns stability from completed wonders.
    #[must_use]
    pub const fn wonder_sources(&self) -> i64 {
        self.wonder_sources
    }
    /// Returns the cost of cities beyond the first.
    #[must_use]
    pub const fn city_cost(&self) -> i64 {
        self.city_cost
    }
    /// Returns the over-threshold population cost.
    #[must_use]
    pub const fn population_cost(&self) -> i64 {
        self.population_cost
    }
    /// Returns the frontier and disconnected-territory cost.
    #[must_use]
    pub const fn cohesion_cost(&self) -> i64 {
        self.cohesion_cost
    }
    /// Returns the conquered-city cost.
    #[must_use]
    pub const fn conquered_city_cost(&self) -> i64 {
        self.conquered_city_cost
    }
    /// Returns accumulated war weariness used by the projection.
    #[must_use]
    pub const fn war_weariness_cost(&self) -> i64 {
        self.war_weariness_cost
    }
    /// Returns the territory hegemony tax.
    #[must_use]
    pub const fn hegemony_tax(&self) -> i64 {
        self.hegemony_tax
    }
    /// Returns the checked sum of positive sources.
    #[must_use]
    pub const fn source_total(&self) -> i64 {
        self.source_total
    }
    /// Returns the checked sum of costs before relative standing.
    #[must_use]
    pub const fn cost_total(&self) -> i64 {
        self.cost_total
    }
    /// Returns the signed adjustment applied for relative territorial standing.
    #[must_use]
    pub const fn relative_standing_adjustment(&self) -> i64 {
        self.relative_standing_adjustment
    }
    /// Returns the effective stability consumed by economy rules.
    #[must_use]
    pub const fn effective_net(&self) -> i64 {
        self.effective_net
    }
    /// Returns the authoritative presentation band.
    #[must_use]
    pub const fn band(&self) -> StabilityBand {
        self.band
    }
}

/// Complete actor-owned gold and stability forecast for the map HUD.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct EconomyForecast {
    player_id: PlayerId,
    treasury: i64,
    city_income: i64,
    project_income: i64,
    gross_income: i64,
    net_per_turn: i64,
    city_sources: Box<[CityGoldIncomeSource]>,
    project_sources: Box<[WealthProjectGoldIncomeSource]>,
    upkeep: UnitUpkeepBreakdown,
    stability: StabilityBreakdown,
}

impl EconomyForecast {
    #[allow(clippy::too_many_arguments)]
    pub(crate) fn new(
        player_id: PlayerId,
        treasury: i64,
        city_income: i64,
        project_income: i64,
        gross_income: i64,
        net_per_turn: i64,
        city_sources: Vec<CityGoldIncomeSource>,
        project_sources: Vec<WealthProjectGoldIncomeSource>,
        upkeep: UnitUpkeepBreakdown,
        stability: StabilityBreakdown,
    ) -> Self {
        Self {
            player_id,
            treasury,
            city_income,
            project_income,
            gross_income,
            net_per_turn,
            city_sources: city_sources.into_boxed_slice(),
            project_sources: project_sources.into_boxed_slice(),
            upkeep,
            stability,
        }
    }

    /// Returns the forecast owner.
    #[must_use]
    pub const fn player_id(&self) -> &PlayerId {
        &self.player_id
    }
    /// Returns the current treasury balance.
    #[must_use]
    pub const fn treasury(&self) -> i64 {
        self.treasury
    }
    /// Returns ordinary city gold income.
    #[must_use]
    pub const fn city_income(&self) -> i64 {
        self.city_income
    }
    /// Returns continuous wealth-project gold income.
    #[must_use]
    pub const fn project_income(&self) -> i64 {
        self.project_income
    }
    /// Returns city and project income before upkeep.
    #[must_use]
    pub const fn gross_income(&self) -> i64 {
        self.gross_income
    }
    /// Returns gross income minus authoritative unit upkeep.
    #[must_use]
    pub const fn net_per_turn(&self) -> i64 {
        self.net_per_turn
    }
    /// Returns ordinary income sources in canonical city order.
    #[must_use]
    pub const fn city_sources(&self) -> &[CityGoldIncomeSource] {
        &self.city_sources
    }
    /// Returns wealth-project sources in canonical city order.
    #[must_use]
    pub const fn project_sources(&self) -> &[WealthProjectGoldIncomeSource] {
        &self.project_sources
    }
    /// Returns exact next-settlement upkeep allocation.
    #[must_use]
    pub const fn upkeep(&self) -> &UnitUpkeepBreakdown {
        &self.upkeep
    }
    /// Returns current authoritative stability evidence.
    #[must_use]
    pub const fn stability(&self) -> &StabilityBreakdown {
        &self.stability
    }
}
