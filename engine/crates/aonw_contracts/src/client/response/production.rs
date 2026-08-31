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
