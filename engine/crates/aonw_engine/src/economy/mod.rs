mod model;
pub(crate) mod rules;
mod turn;

pub use model::{
    CityYieldBreakdown, CityYieldContribution, CityYieldContributionKind, CityYieldQuery,
    StrategicResourceProjection, StrategicResourceProjectionQuery, StrategicResourceSource,
    YieldValue,
};
pub use rules::EconomyQueryError;

pub(crate) use rules::{query_city_yield, query_strategic_resource_projection};
pub(crate) use turn::{
    CombatEconomyOwnerIndex, PreparedEconomyTurn, WarWearinessEventCounts, advance_turn_stability,
    city_turn_output, prepare_turn_economy, settle_turn_income_and_upkeep,
};
