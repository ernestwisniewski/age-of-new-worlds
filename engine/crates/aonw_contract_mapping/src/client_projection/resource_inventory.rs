use aonw_contracts::client::{
    StrategicResourceAllocationDto, StrategicResourceBalanceDto, StrategicResourceDepositDto,
    StrategicResourceInventoryDto,
};
use aonw_engine::StrategicResourceBalance;
use aonw_projection::PlayerStrategicResourceInventoryView;

use super::coordinate;

pub(super) fn inventory(
    value: &PlayerStrategicResourceInventoryView,
) -> StrategicResourceInventoryDto {
    StrategicResourceInventoryDto {
        balances: value.balances.map(balance),
        available_type_count: value.available_type_count,
        shortage_type_count: value.shortage_type_count,
        attention_count: value.attention_count,
        expiring_trade_ids: value.expiring_trade_ids.to_vec(),
        allocations: value
            .allocations
            .iter()
            .map(|allocation| StrategicResourceAllocationDto {
                city_id: allocation.city_id.as_str().to_owned(),
                resource: crate::encode_resource(allocation.resource),
                amount: allocation.amount,
            })
            .collect(),
        deposits: value
            .deposits
            .iter()
            .map(|deposit| StrategicResourceDepositDto {
                city_id: deposit.city_id.as_str().to_owned(),
                coordinate: coordinate(deposit.coordinate),
                resource: crate::encode_resource(deposit.resource),
                improvement: deposit.improvement.map(crate::encode_improvement),
                amount_per_turn: deposit.amount_per_turn,
            })
            .collect(),
    }
}

fn balance(value: StrategicResourceBalance) -> StrategicResourceBalanceDto {
    StrategicResourceBalanceDto {
        resource: crate::encode_resource(value.resource),
        stockpiled: value.stockpiled,
        controlled_deposits: value.controlled_deposits,
        available: value.available,
        allocated: value.allocated,
        stored_total: value.stored_total,
        domestic_production: value.domestic_production,
        imports: value.imports,
        exports: value.exports,
        net_per_turn: value.net_per_turn,
        source_count: value.source_count,
        shortage: value.shortage,
        no_free_stock: value.no_free_stock,
    }
}
