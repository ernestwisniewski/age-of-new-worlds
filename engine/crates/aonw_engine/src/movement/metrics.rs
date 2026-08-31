/// Deterministic work counters emitted by one movement search.
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub struct MovementSearchMetrics {
    frontier_pops: u64,
    expanded_tiles: u64,
    examined_edges: u64,
    heap_pushes: u64,
    route_records: u64,
}

impl MovementSearchMetrics {
    /// Returns the number of heap entries removed from the frontier.
    #[must_use]
    pub const fn frontier_pops(self) -> u64 {
        self.frontier_pops
    }

    /// Returns the number of nodes whose outgoing edges were inspected.
    #[must_use]
    pub const fn expanded_tiles(self) -> u64 {
        self.expanded_tiles
    }

    /// Returns the number of neighboring edges inspected.
    #[must_use]
    pub const fn examined_edges(self) -> u64 {
        self.examined_edges
    }

    /// Returns the number of entries inserted into the frontier heap.
    #[must_use]
    pub const fn heap_pushes(self) -> u64 {
        self.heap_pushes
    }

    /// Returns the number of retained route-search records.
    #[must_use]
    pub const fn route_records(self) -> u64 {
        self.route_records
    }

    pub(super) fn popped(&mut self) {
        self.frontier_pops = self.frontier_pops.saturating_add(1);
    }

    pub(super) fn expanded(&mut self) {
        self.expanded_tiles = self.expanded_tiles.saturating_add(1);
    }

    pub(super) fn examined_edge(&mut self) {
        self.examined_edges = self.examined_edges.saturating_add(1);
    }

    pub(super) fn pushed(&mut self) {
        self.heap_pushes = self.heap_pushes.saturating_add(1);
    }

    pub(super) fn retained_record(&mut self) {
        self.route_records = self.route_records.saturating_add(1);
    }
}
