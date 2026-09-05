use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};

use crate::{
    CityBuildingTypeDto, FieldImprovementKindDto, ResourceTypeDto, TechnologyIdDto, UnitKindDto,
    WonderTypeDto,
};

/// Highest completed research era belonging to the authenticated recipient.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum TechnologyEraDto {
    Foundation,
    Settlement,
    Expansion,
    Specialization,
    Industry,
    Strategy,
}

/// Current engine-owned availability of one technology.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum TechnologyAvailabilityDto {
    Unlocked,
    Active,
    Available,
    LockedByPrerequisites,
    LockedByTechnology,
}

/// One typed capability unlocked by research.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "kind",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum TechnologyUnlockDto {
    Building {
        building_type: CityBuildingTypeDto,
    },
    Improvement {
        improvement: FieldImprovementKindDto,
    },
    ResourceVisibility {
        resource: ResourceTypeDto,
    },
    Unit {
        unit_type: UnitKindDto,
    },
    Wonder {
        wonder_type: WonderTypeDto,
    },
}

/// Stable source category for one engine-owned science contribution.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum ScienceYieldSourceKindDto {
    CityScience,
    CityResearchProject,
    WorldArtifact,
    WorldWonder,
}

/// One display-ready per-turn science contribution.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ScienceYieldSourceDto {
    /// Contributing city.
    pub city_id: String,
    /// Exact non-negative contribution.
    pub amount: i64,
    /// Stable contribution category.
    pub kind: ScienceYieldSourceKindDto,
}

/// Complete engine-owned science preview for the authenticated participant.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ScienceYieldBreakdownDto {
    /// Exact science produced by all current sources.
    pub total: i64,
    /// Combined contributions in stable city-id order.
    pub by_city_id: BTreeMap<String, i64>,
    /// Source details in canonical calculation order.
    pub sources: Vec<ScienceYieldSourceDto>,
}

/// Recipient-owned active research progress and current science forecast.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerResearchViewDto {
    /// Highest era among completed technologies, or foundation before research.
    pub dominant_era: TechnologyEraDto,
    /// Selected technology, when research is active.
    pub active_technology_id: Option<TechnologyIdDto>,
    /// Persisted progress for the active technology.
    pub active_progress: Option<i64>,
    /// Current pace-, city-, and boost-adjusted active cost.
    pub active_effective_cost: Option<u32>,
    /// Stored science available after choosing a technology.
    pub science_overflow: i64,
    /// Complete engine-owned next-turn science forecast.
    pub science_yield: ScienceYieldBreakdownDto,
}

/// Complete selection view of one technology.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ResearchOptionDto {
    /// Stable technology identity.
    pub technology_id: TechnologyIdDto,
    /// Current engine-owned availability.
    pub availability: TechnologyAvailabilityDto,
    /// Exact pace-, city-, and boost-adjusted cost.
    pub effective_cost: u32,
    /// Persisted science progress.
    pub progress: i64,
    /// Best currently fulfilled boost discount.
    pub boost_discount_basis_points: u32,
    /// Required technologies in catalog order.
    pub prerequisites: Vec<TechnologyIdDto>,
    /// Mutually exclusive completed technologies.
    pub blocked_by: Vec<TechnologyIdDto>,
    /// Capabilities granted on completion.
    pub unlocks: Vec<TechnologyUnlockDto>,
}
