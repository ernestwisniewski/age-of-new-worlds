use serde::{Deserialize, Serialize};

use crate::{
    CoordinateDto, FieldImprovementKindDto, ResourceTypeDto, StabilityBandDto, UnitKindDto,
};

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

/// One recipient-owned city contribution to gold income.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct GoldIncomeSourceDto {
    pub city_id: String,
    pub amount: i64,
}

/// Upkeep charged to paid units of one type.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct UnitUpkeepSourceDto {
    pub kind: UnitKindDto,
    pub paid_unit_count: i64,
    pub amount: i64,
}

/// Exact unit-upkeep allocation used by the next turn settlement.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct UnitUpkeepBreakdownDto {
    pub upkeep_bearing_unit_count: i64,
    pub free_unit_count: i64,
    pub paid_unit_count: i64,
    pub total: i64,
    pub next_worker_upkeep: i64,
    pub sources: Vec<UnitUpkeepSourceDto>,
}

/// Complete current stability source and cost evidence.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct StabilityBreakdownDto {
    pub base_order: i64,
    pub building_sources: i64,
    pub luxury_sources: i64,
    pub technology_sources: i64,
    pub artifact_sources: i64,
    pub wonder_sources: i64,
    pub city_cost: i64,
    pub population_cost: i64,
    pub cohesion_cost: i64,
    pub conquered_city_cost: i64,
    pub war_weariness_cost: i64,
    pub hegemony_tax: i64,
    pub source_total: i64,
    pub cost_total: i64,
    pub relative_standing_adjustment: i64,
    pub effective_net: i64,
    pub band: StabilityBandDto,
}

/// Complete gold and stability forecast required by the top resource HUD.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct EconomyForecastDto {
    pub treasury: i64,
    pub city_income: i64,
    pub project_income: i64,
    pub gross_income: i64,
    pub net_per_turn: i64,
    pub city_sources: Vec<GoldIncomeSourceDto>,
    pub project_sources: Vec<GoldIncomeSourceDto>,
    pub upkeep: UnitUpkeepBreakdownDto,
    pub stability: StabilityBreakdownDto,
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
    pub forecast: EconomyForecastDto,
}
