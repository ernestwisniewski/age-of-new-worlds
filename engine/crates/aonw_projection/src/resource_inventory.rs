use aonw_engine::{
    StrategicResourceAllocation, StrategicResourceBalance, StrategicResourceDeposit,
    StrategicResourceInventory,
};

/// Complete recipient-owned inventory, without redundant extraction internals.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerStrategicResourceInventoryView {
    pub balances: [StrategicResourceBalance; 7],
    pub available_type_count: u8,
    pub shortage_type_count: u8,
    pub attention_count: u32,
    pub expiring_trade_ids: Box<[String]>,
    pub allocations: Box<[StrategicResourceAllocation]>,
    pub deposits: Box<[StrategicResourceDeposit]>,
}

impl From<StrategicResourceInventory> for PlayerStrategicResourceInventoryView {
    fn from(value: StrategicResourceInventory) -> Self {
        Self {
            balances: value.balances,
            available_type_count: value.available_type_count,
            shortage_type_count: value.shortage_type_count,
            attention_count: value.attention_count,
            expiring_trade_ids: value.expiring_trade_ids,
            allocations: value.allocations,
            deposits: value.deposits,
        }
    }
}

#[cfg(test)]
impl PlayerStrategicResourceInventoryView {
    pub(crate) fn empty() -> Self {
        use aonw_domain::ResourceType;
        Self {
            balances: [
                ResourceType::Iron,
                ResourceType::Coal,
                ResourceType::Oil,
                ResourceType::Aluminium,
                ResourceType::Uranium,
                ResourceType::Horses,
                ResourceType::Marble,
            ]
            .map(StrategicResourceBalance::empty),
            available_type_count: 0,
            shortage_type_count: 0,
            attention_count: 0,
            expiring_trade_ids: Box::new([]),
            allocations: Box::new([]),
            deposits: Box::new([]),
        }
    }
}
