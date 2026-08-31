use crate::{ArtifactId, HexCoord};

/// Improvement constructed by a worker job.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub enum FieldImprovementKind {
    Farm,
    RiverFarm,
    Mine,
    LumberMill,
    Pasture,
    Camp,
    Quarry,
    FishingBoats,
    Orchard,
    Plantation,
    Vineyard,
    TradingPost,
    ProspectorCamp,
    HorseRanch,
    PearlDivers,
    CoalShaft,
    OilWell,
    BauxiteMine,
    UraniumMine,
}

/// Long-running worker action.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum WorkerJob {
    /// Construction of a field improvement.
    FieldImprovement {
        /// Target coordinate.
        target: HexCoord,
        /// Improvement being constructed.
        improvement: FieldImprovementKind,
        /// Turns still required.
        remaining_turns: u32,
        /// Original job duration.
        total_turns: u32,
    },
    /// Construction of a road segment.
    RoadConstruction {
        /// Target coordinate.
        target: HexCoord,
        /// Turns still required.
        remaining_turns: u32,
        /// Original job duration.
        total_turns: u32,
    },
}

impl WorkerJob {
    /// Returns the coordinate on which work must remain.
    #[must_use]
    pub const fn target(&self) -> HexCoord {
        match self {
            Self::FieldImprovement { target, .. } | Self::RoadConstruction { target, .. } => {
                *target
            }
        }
    }
    /// Returns turns still required.
    #[must_use]
    pub const fn remaining_turns(&self) -> u32 {
        match self {
            Self::FieldImprovement {
                remaining_turns, ..
            }
            | Self::RoadConstruction {
                remaining_turns, ..
            } => *remaining_turns,
        }
    }
    /// Returns the original duration.
    #[must_use]
    pub const fn total_turns(&self) -> u32 {
        match self {
            Self::FieldImprovement { total_turns, .. }
            | Self::RoadConstruction { total_turns, .. } => *total_turns,
        }
    }
    /// Returns the same job with updated remaining duration.
    #[must_use]
    pub const fn with_remaining_turns(&self, remaining_turns: u32) -> Self {
        match self {
            Self::FieldImprovement {
                target,
                improvement,
                total_turns,
                ..
            } => Self::FieldImprovement {
                target: *target,
                improvement: *improvement,
                remaining_turns,
                total_turns: *total_turns,
            },
            Self::RoadConstruction {
                target,
                total_turns,
                ..
            } => Self::RoadConstruction {
                target: *target,
                remaining_turns,
                total_turns: *total_turns,
            },
        }
    }
}

/// City founding work retained by a settler.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CityFoundingJob {
    center: HexCoord,
    controlled_hexes: Box<[HexCoord]>,
    remaining_turns: u32,
    total_turns: u32,
}

impl CityFoundingJob {
    /// Constructs a city founding job.
    #[must_use]
    pub fn new(
        center: HexCoord,
        controlled_hexes: impl IntoIterator<Item = HexCoord>,
        remaining_turns: u32,
        total_turns: u32,
    ) -> Self {
        Self {
            center,
            controlled_hexes: controlled_hexes.into_iter().collect(),
            remaining_turns,
            total_turns,
        }
    }

    /// Returns the planned city center.
    #[must_use]
    pub const fn center(&self) -> HexCoord {
        self.center
    }

    /// Returns controlled coordinates in canonical order.
    #[must_use]
    pub const fn controlled_hexes(&self) -> &[HexCoord] {
        &self.controlled_hexes
    }

    /// Returns turns still required.
    #[must_use]
    pub const fn remaining_turns(&self) -> u32 {
        self.remaining_turns
    }

    /// Returns the original duration.
    #[must_use]
    pub const fn total_turns(&self) -> u32 {
        self.total_turns
    }

    /// Returns the same job with a new remaining duration.
    #[must_use]
    pub fn with_remaining_turns(&self, remaining_turns: u32) -> Self {
        Self {
            center: self.center,
            controlled_hexes: self.controlled_hexes.clone(),
            remaining_turns,
            total_turns: self.total_turns,
        }
    }
}

/// Concrete activities that make manual movement unavailable.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct UnitActivity {
    worker_job: Option<WorkerJob>,
    city_founding_job: Option<CityFoundingJob>,
    worker_assignment: Option<HexCoord>,
    excavating_artifact_id: Option<ArtifactId>,
}

impl UnitActivity {
    /// Constructs all independently persisted activity slots.
    #[must_use]
    pub const fn new(
        worker_job: Option<WorkerJob>,
        city_founding_job: Option<CityFoundingJob>,
        worker_assignment: Option<HexCoord>,
        excavating_artifact_id: Option<ArtifactId>,
    ) -> Self {
        Self {
            worker_job,
            city_founding_job,
            worker_assignment,
            excavating_artifact_id,
        }
    }

    /// Returns whether an activity blocks manual movement.
    #[must_use]
    pub const fn blocks_manual_movement(&self) -> bool {
        self.worker_job.is_some()
            || self.city_founding_job.is_some()
            || self.worker_assignment.is_some()
            || self.excavating_artifact_id.is_some()
    }

    /// Returns the worker job.
    #[must_use]
    pub const fn worker_job(&self) -> Option<&WorkerJob> {
        self.worker_job.as_ref()
    }

    /// Returns the city founding job.
    #[must_use]
    pub const fn city_founding_job(&self) -> Option<&CityFoundingJob> {
        self.city_founding_job.as_ref()
    }

    /// Returns the assigned worker coordinate.
    #[must_use]
    pub const fn worker_assignment(&self) -> Option<HexCoord> {
        self.worker_assignment
    }

    /// Returns the artifact currently being excavated.
    #[must_use]
    pub const fn excavating_artifact_id(&self) -> Option<&ArtifactId> {
        self.excavating_artifact_id.as_ref()
    }

    /// Replaces city-founding work while preserving independent activity slots.
    #[must_use]
    pub fn with_city_founding_job(&self, job: Option<CityFoundingJob>) -> Self {
        Self {
            worker_job: self.worker_job.clone(),
            city_founding_job: job,
            worker_assignment: self.worker_assignment,
            excavating_artifact_id: self.excavating_artifact_id.clone(),
        }
    }

    /// Replaces worker work and assignment atomically.
    #[must_use]
    pub fn with_worker(
        &self,
        worker_job: Option<WorkerJob>,
        worker_assignment: Option<HexCoord>,
    ) -> Self {
        Self {
            worker_job,
            city_founding_job: self.city_founding_job.clone(),
            worker_assignment,
            excavating_artifact_id: self.excavating_artifact_id.clone(),
        }
    }

    /// Replaces artifact excavation while preserving independent activity slots.
    #[must_use]
    pub fn with_artifact_excavation(&self, artifact_id: Option<ArtifactId>) -> Self {
        Self {
            worker_job: self.worker_job.clone(),
            city_founding_job: self.city_founding_job.clone(),
            worker_assignment: self.worker_assignment,
            excavating_artifact_id: artifact_id,
        }
    }
}
