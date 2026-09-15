use serde::{Deserialize, Serialize};

use crate::{CoordinateDto, FieldImprovementKindDto, ResourceTypeDto};

/// Complete recipient-owned strategic inventory, including zero balances.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct StrategicResourceInventoryDto {
    pub balances: [StrategicResourceBalanceDto; 7],
    pub available_type_count: u8,
    pub shortage_type_count: u8,
    pub attention_count: u32,
    pub expiring_trade_ids: Vec<String>,
    pub allocations: Vec<StrategicResourceAllocationDto>,
    pub deposits: Vec<StrategicResourceDepositDto>,
}

/// One checked resource balance; quantities and presence have distinct meanings.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct StrategicResourceBalanceDto {
    pub resource: ResourceTypeDto,
    pub stockpiled: bool,
    pub controlled_deposits: i64,
    pub available: i64,
    pub allocated: i64,
    pub stored_total: i64,
    pub domestic_production: i64,
    pub imports: i64,
    pub exports: i64,
    pub net_per_turn: i64,
    pub source_count: i64,
    pub shortage: bool,
    pub no_free_stock: bool,
}

/// One resource already reserved by a recipient-owned production queue.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct StrategicResourceAllocationDto {
    pub city_id: String,
    pub resource: ResourceTypeDto,
    pub amount: i64,
}

/// One revealed recipient-controlled deposit, with optional extraction.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct StrategicResourceDepositDto {
    pub city_id: String,
    pub coordinate: CoordinateDto,
    pub resource: ResourceTypeDto,
    #[serde(deserialize_with = "Option::deserialize")]
    pub improvement: Option<FieldImprovementKindDto>,
    #[serde(deserialize_with = "Option::deserialize")]
    pub amount_per_turn: Option<i64>,
}
