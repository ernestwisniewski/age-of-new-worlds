use std::collections::BinaryHeap;

use super::reachable::FrontierNode;

/// Reusable scratch storage for repeated movement queries on one worker thread.
#[derive(Clone, Debug, Default)]
pub struct MovementSearchWorkspace {
    pub(crate) reachable_costs: Vec<u32>,
    pub(crate) reachable_frontier: BinaryHeap<FrontierNode>,
}

impl MovementSearchWorkspace {
    /// Reserves scratch capacity for the supplied tile count.
    pub fn prepare(&mut self, tile_count: usize) {
        if self.reachable_costs.len() < tile_count {
            self.reachable_costs.resize(tile_count, u32::MAX);
        }
        self.reachable_costs[..tile_count].fill(u32::MAX);
        self.reachable_frontier.clear();
    }
}
