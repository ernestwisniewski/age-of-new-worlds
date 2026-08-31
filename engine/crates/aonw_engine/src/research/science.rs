use std::collections::BTreeMap;

use aonw_domain::{CityId, PlayerId};

/// Stable engine-owned category for one per-turn science contribution.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum ScienceYieldSourceKind {
    CityScience,
    CityResearchProject,
    WorldArtifact,
    WorldWonder,
}

/// One display-ready science contribution owned by the canonical engine.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ScienceYieldSource {
    city_id: CityId,
    amount: i64,
    kind: ScienceYieldSourceKind,
}

impl ScienceYieldSource {
    pub(super) const fn new(city_id: CityId, amount: i64, kind: ScienceYieldSourceKind) -> Self {
        Self {
            city_id,
            amount,
            kind,
        }
    }

    /// Returns the contributing city.
    #[must_use]
    pub const fn city_id(&self) -> &CityId {
        &self.city_id
    }

    /// Returns the exact non-negative contribution.
    #[must_use]
    pub const fn amount(&self) -> i64 {
        self.amount
    }

    /// Returns the stable contribution category.
    #[must_use]
    pub const fn kind(&self) -> ScienceYieldSourceKind {
        self.kind
    }
}

/// Complete engine-owned science yield for one participant's next turn.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ScienceYieldBreakdown {
    player_id: PlayerId,
    total: i64,
    by_city_id: BTreeMap<CityId, i64>,
    sources: Box<[ScienceYieldSource]>,
}

impl ScienceYieldBreakdown {
    pub(super) fn new(
        player_id: PlayerId,
        total: i64,
        by_city_id: BTreeMap<CityId, i64>,
        sources: impl Into<Box<[ScienceYieldSource]>>,
    ) -> Self {
        Self {
            player_id,
            total,
            by_city_id,
            sources: sources.into(),
        }
    }

    /// Returns the research owner.
    #[must_use]
    pub const fn player_id(&self) -> &PlayerId {
        &self.player_id
    }

    /// Returns exact science produced by all current sources.
    #[must_use]
    pub const fn total(&self) -> i64 {
        self.total
    }

    /// Returns combined contributions in stable city-id order.
    #[must_use]
    pub const fn by_city_id(&self) -> &BTreeMap<CityId, i64> {
        &self.by_city_id
    }

    /// Returns source details in canonical calculation order.
    #[must_use]
    pub const fn sources(&self) -> &[ScienceYieldSource] {
        &self.sources
    }
}
