use serde::{Deserialize, Serialize};

use crate::{CoordinateDto, FieldImprovementKindDto, ResourceTypeDto};

/// Exact integer food, production, gold, and defense yield.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct YieldValueDto {
    pub food: i64,
    pub production: i64,
    pub gold: i64,
    pub defense: i64,
}

/// Stable reason why a coordinate contributes to city yield.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum CityYieldContributionKindDto {
    Center,
    Population,
    Worker,
    PassiveImprovement,
    Artifact,
}

/// One engine-owned display contribution.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct CityYieldContributionDto {
    pub kind: CityYieldContributionKindDto,
    pub coordinate: CoordinateDto,
    pub value: YieldValueDto,
}

/// One positive strategic resource amount.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct StrategicResourceAmountDto {
    pub resource: ResourceTypeDto,
    pub amount: i64,
}

/// One exact controlled extraction source.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct StrategicResourceSourceDto {
    pub city_id: String,
    pub coordinate: CoordinateDto,
    pub resource: ResourceTypeDto,
    pub improvement: FieldImprovementKindDto,
    pub amount_per_turn: i64,
}

/// Complete recipient-owned economy state required by the map HUD.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerEconomyViewDto {
    pub gold: i64,
    pub war_weariness: i64,
    pub stability_net: i64,
    pub strategic_resource_stockpile: Vec<StrategicResourceAmountDto>,
    pub strategic_resource_output: Vec<StrategicResourceAmountDto>,
    pub strategic_resource_sources: Vec<StrategicResourceSourceDto>,
}
