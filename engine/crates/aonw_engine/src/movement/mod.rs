mod access;
mod auto_explore;
mod balance;
mod compiled_map;
mod cost;
mod detachment;
mod fog;
mod logistics;
mod merchant;
mod metrics;
mod occupancy;
mod options;
mod planning_view;
mod query;
#[cfg(test)]
mod query_tests;
mod reachable;
mod route_search;
mod terrain_profile;
mod transition;
#[cfg(test)]
mod transition_tests;
mod turn;
mod visibility;
mod workspace;

pub use balance::maximum_movement_units;
pub use compiled_map::{CompiledMovementMap, CompiledMovementMapError};
pub use cost::{MovementCost, terrain_entry_cost};
pub use logistics::{
    AssignMerchantTradeRouteCommand, AutoExploreOption, AutoExploreUnitCommand, DetachTroopCommand,
    DetachmentOption, MerchantDestinationOption, MoveMerchantToCityCommand, MovementLogisticsError,
    UnitLogisticsOptions, UnitLogisticsOptionsQuery,
};
pub use metrics::MovementSearchMetrics;
pub(crate) use occupancy::MovementOccupancy;
pub(crate) use planning_view::MovementPlanningView;
pub use query::{TerrainMovementPlan, TerrainMovementQuery, TerrainMovementQueryError};
pub use reachable::{ReachableMovement, ReachableMovementQuery, ReachableMovementTile};
pub use transition::{MoveUnitCommand, MoveUnitError, UnitMovedEvent, UnitMovementExecution};
pub use visibility::MovementVisibility;
pub use workspace::MovementSearchWorkspace;

pub(crate) use access::MovementAccess;
pub(crate) use auto_explore::apply_auto_explore;
pub(crate) use detachment::apply_detach_troop;
pub(crate) use fog::{
    merge_discovered_contacts, merge_discovered_contacts_after_unit_move, recompute_after_move,
    recompute_after_unit_move,
};
pub(crate) use logistics::MovementLogisticsUpdate;
pub(crate) use merchant::{apply_assign_route, apply_move_to_city};
pub(crate) use options::query_logistics_options;
pub(crate) use query::plan_route_for_unit;
pub(crate) use query::plan_terrain_route;
#[cfg(test)]
pub(crate) use reachable::find_reachable_tiles;
pub(crate) use reachable::find_reachable_tiles_with_workspace;
pub(crate) use route_search::find_route_costs;
pub(crate) use transition::MovementTransition;
pub(crate) use transition::apply_move_unit;
pub(crate) use transition::{movement_from_plan, reachable_path_hits_hidden_blocker};
pub(crate) use turn::{TurnMovementUpdate, advance_turn_movement};
