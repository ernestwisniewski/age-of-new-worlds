use aonw_contracts::client::{
    StrategicResourceBalanceDto, StrategicResourceDepositDto, StrategicResourceInventoryDto,
};
use aonw_contracts::{CoordinateDto, FieldImprovementKindDto, ResourceTypeDto};

pub(super) fn inventory() -> StrategicResourceInventoryDto {
    let balances = [
        ResourceTypeDto::Iron,
        ResourceTypeDto::Coal,
        ResourceTypeDto::Oil,
        ResourceTypeDto::Aluminium,
        ResourceTypeDto::Uranium,
        ResourceTypeDto::Horses,
        ResourceTypeDto::Marble,
    ]
    .map(|resource| {
        let oil = resource == ResourceTypeDto::Oil;
        StrategicResourceBalanceDto {
            resource,
            stockpiled: matches!(resource, ResourceTypeDto::Oil | ResourceTypeDto::Aluminium),
            controlled_deposits: i64::from(oil),
            available: if oil { 4 } else { 0 },
            allocated: 0,
            stored_total: if oil { 4 } else { 0 },
            domestic_production: i64::from(oil),
            imports: 0,
            exports: 0,
            net_per_turn: i64::from(oil),
            source_count: i64::from(oil),
            shortage: false,
            no_free_stock: false,
        }
    });
    StrategicResourceInventoryDto {
        balances,
        available_type_count: 1,
        shortage_type_count: 0,
        attention_count: 0,
        expiring_trade_ids: vec![],
        allocations: vec![],
        deposits: vec![StrategicResourceDepositDto {
            city_id: "city-1".into(),
            coordinate: CoordinateDto { col: 3, row: 4 },
            resource: ResourceTypeDto::Oil,
            improvement: Some(FieldImprovementKindDto::OilWell),
            amount_per_turn: Some(1),
        }],
    }
}
