use serde::{Deserialize, Serialize};

use crate::{
    CityBuildingTypeDto, CityProductionTargetDto, CitySpecializationTypeDto,
    StrategicResourceStockpileDto,
};

use super::ClientCommandRejectionCodeDto;

/// One production target, exact cost, and first authoritative blocker.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ProductionOptionDto {
    pub target: CityProductionTargetDto,
    pub cost: i64,
    pub rejection: Option<ClientCommandRejectionCodeDto>,
    pub forecast: ProductionForecastDto,
}

/// Current-rate progress and output for one production target.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ProductionForecastDto {
    pub invested_production: i64,
    pub production_per_turn: i64,
    #[serde(deserialize_with = "Option::deserialize")]
    pub estimated_turns: Option<u64>,
    #[serde(deserialize_with = "Option::deserialize")]
    pub project_output: Option<i64>,
    pub spawn_blocked: bool,
}

/// Exact production increment, gold price and availability of a rush command.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ProductionRushQuoteDto {
    pub production: i64,
    pub gold_cost: i64,
    #[serde(deserialize_with = "Option::deserialize")]
    pub rejection: Option<ClientCommandRejectionCodeDto>,
}

/// Unit option including ordered strategic-resource alternatives.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct UnitProductionOptionDto {
    pub option: ProductionOptionDto,
    pub resource_options: Vec<StrategicResourceStockpileDto>,
    pub affordable_resource_option_indices: Vec<u32>,
}

/// One city specialization and its prerequisite state.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct CitySpecializationOptionDto {
    pub specialization: CitySpecializationTypeDto,
    pub required_building: CityBuildingTypeDto,
    pub rejection: Option<ClientCommandRejectionCodeDto>,
}
