use std::collections::BTreeMap;

use aonw_domain::{CityId, FieldImprovementKind, HexCoord, PlayerId, ResourceType};

/// Revision-bound query for the complete tile-level yield of one controlled city.
#[derive(Clone, Copy, Debug)]
pub struct CityYieldQuery<'query> {
    expected_revision: u64,
    city_id: &'query CityId,
}

impl<'query> CityYieldQuery<'query> {
    /// Creates a deterministic city-yield query.
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

/// Checked integer food, production, gold, and defense yield.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub struct YieldValue {
    pub food: i64,
    pub production: i64,
    pub gold: i64,
    pub defense: i64,
}

impl From<aonw_content::WorkerYield> for YieldValue {
    fn from(value: aonw_content::WorkerYield) -> Self {
        Self::new(
            i64::from(value.food()),
            i64::from(value.production()),
            i64::from(value.gold()),
            i64::from(value.defense()),
        )
    }
}

impl YieldValue {
    /// Creates one exact integer yield.
    #[must_use]
    pub const fn new(food: i64, production: i64, gold: i64, defense: i64) -> Self {
        Self {
            food,
            production,
            gold,
            defense,
        }
    }
}

/// Stable reason why one coordinate contributes to a city yield.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum CityYieldContributionKind {
    Center,
    Population,
    Worker,
    PassiveImprovement,
    Artifact,
}

/// One display-ready engine-owned yield contribution.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct CityYieldContribution {
    kind: CityYieldContributionKind,
    coordinate: HexCoord,
    value: YieldValue,
}

impl CityYieldContribution {
    pub(crate) const fn new(
        kind: CityYieldContributionKind,
        coordinate: HexCoord,
        value: YieldValue,
    ) -> Self {
        Self {
            kind,
            coordinate,
            value,
        }
    }

    /// Returns the contribution category.
    #[must_use]
    pub const fn kind(self) -> CityYieldContributionKind {
        self.kind
    }
    /// Returns the map coordinate associated with the contribution.
    #[must_use]
    pub const fn coordinate(self) -> HexCoord {
        self.coordinate
    }
    /// Returns the exact contribution value.
    #[must_use]
    pub const fn value(self) -> YieldValue {
        self.value
    }
}

/// Canonically ordered, display-ready tile yield for one city.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CityYieldBreakdown {
    city_id: CityId,
    contributions: Box<[CityYieldContribution]>,
    total: YieldValue,
}

impl CityYieldBreakdown {
    pub(crate) fn new(
        city_id: CityId,
        contributions: Vec<CityYieldContribution>,
        total: YieldValue,
    ) -> Self {
        Self {
            city_id,
            contributions: contributions.into_boxed_slice(),
            total,
        }
    }

    /// Returns the queried city.
    #[must_use]
    pub const fn city_id(&self) -> &CityId {
        &self.city_id
    }
    /// Returns center, population, worker, passive, and artifact contributions.
    #[must_use]
    pub const fn contributions(&self) -> &[CityYieldContribution] {
        &self.contributions
    }
    /// Returns the checked sum of all contributions.
    #[must_use]
    pub const fn total(&self) -> YieldValue {
        self.total
    }
}

/// Revision-bound projection of strategic resource extraction for the actor.
#[derive(Clone, Copy, Debug)]
pub struct StrategicResourceProjectionQuery {
    expected_revision: u64,
}

impl StrategicResourceProjectionQuery {
    /// Creates a deterministic actor-owned resource projection.
    #[must_use]
    pub const fn new(expected_revision: u64) -> Self {
        Self { expected_revision }
    }

    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
}

/// One controlled and technology-visible extraction source.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct StrategicResourceSource {
    city_id: CityId,
    coordinate: HexCoord,
    resource: ResourceType,
    improvement: FieldImprovementKind,
    amount_per_turn: i64,
}

impl StrategicResourceSource {
    pub(crate) const fn new(
        city_id: CityId,
        coordinate: HexCoord,
        resource: ResourceType,
        improvement: FieldImprovementKind,
        amount_per_turn: i64,
    ) -> Self {
        Self {
            city_id,
            coordinate,
            resource,
            improvement,
            amount_per_turn,
        }
    }

    /// Returns the controlling city.
    #[must_use]
    pub const fn city_id(&self) -> &CityId {
        &self.city_id
    }
    /// Returns the improved coordinate.
    #[must_use]
    pub const fn coordinate(&self) -> HexCoord {
        self.coordinate
    }
    /// Returns the extracted resource.
    #[must_use]
    pub const fn resource(&self) -> ResourceType {
        self.resource
    }
    /// Returns the required matching improvement.
    #[must_use]
    pub const fn improvement(&self) -> FieldImprovementKind {
        self.improvement
    }
    /// Returns extraction credited on each economy turn.
    #[must_use]
    pub const fn amount_per_turn(&self) -> i64 {
        self.amount_per_turn
    }
}

/// Checked per-turn strategic resource output with exact source evidence.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct StrategicResourceProjection {
    player_id: PlayerId,
    output: BTreeMap<ResourceType, i64>,
    sources: Box<[StrategicResourceSource]>,
}

impl StrategicResourceProjection {
    pub(crate) fn new(
        player_id: PlayerId,
        output: BTreeMap<ResourceType, i64>,
        sources: Vec<StrategicResourceSource>,
    ) -> Self {
        Self {
            player_id,
            output,
            sources: sources.into_boxed_slice(),
        }
    }

    /// Returns the account owner.
    #[must_use]
    pub const fn player_id(&self) -> &PlayerId {
        &self.player_id
    }
    /// Returns positive output in canonical resource order.
    #[must_use]
    pub const fn output(&self) -> &BTreeMap<ResourceType, i64> {
        &self.output
    }
    /// Returns exact extraction sources in coordinate/resource order.
    #[must_use]
    pub const fn sources(&self) -> &[StrategicResourceSource] {
        &self.sources
    }
}
