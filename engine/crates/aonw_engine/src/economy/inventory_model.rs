use aonw_domain::{CityId, FieldImprovementKind, HexCoord, ResourceType};

use super::StrategicResourceProjection;

/// Recipient-owned strategic balances, including zero and unrevealed kinds.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct StrategicResourceBalance {
    pub resource: ResourceType,
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

impl StrategicResourceBalance {
    /// Creates a zero balance for an explicit resource kind.
    #[must_use]
    pub const fn empty(resource: ResourceType) -> Self {
        Self {
            resource,
            stockpiled: resource.is_stockpiled(),
            controlled_deposits: 0,
            available: 0,
            allocated: 0,
            stored_total: 0,
            domestic_production: 0,
            imports: 0,
            exports: 0,
            net_per_turn: 0,
            source_count: 0,
            shortage: false,
            no_free_stock: false,
        }
    }
}

/// One stockpiled resource already reserved by a recipient-owned city queue.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct StrategicResourceAllocation {
    pub city_id: CityId,
    pub resource: ResourceType,
    pub amount: i64,
}

/// One controlled, revealed deposit, including deposits without extraction.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct StrategicResourceDeposit {
    pub city_id: CityId,
    pub coordinate: HexCoord,
    pub resource: ResourceType,
    pub improvement: Option<FieldImprovementKind>,
    pub amount_per_turn: Option<i64>,
}

/// Complete actor-only inventory; construction does not settle or refund stock.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct StrategicResourceInventory {
    pub balances: [StrategicResourceBalance; 7],
    pub available_type_count: u8,
    pub shortage_type_count: u8,
    pub attention_count: u32,
    pub expiring_trade_ids: Box<[String]>,
    pub allocations: Box<[StrategicResourceAllocation]>,
    pub deposits: Box<[StrategicResourceDeposit]>,
    pub production: StrategicResourceProjection,
}
