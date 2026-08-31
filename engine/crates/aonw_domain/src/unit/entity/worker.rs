use crate::{HexCoord, MovementUnits, UnitPosture};

use super::{Unit, WorkerJob};

impl Unit {
    /// Starts worker construction and clears conflicting worker orders.
    #[must_use]
    pub fn after_worker_job_started(&self, job: WorkerJob) -> Self {
        let mut updated = self.clone();
        updated.activity = updated.activity.with_worker(Some(job), None);
        updated.movement_units = MovementUnits::ZERO;
        updated.queued_path = None;
        updated.posture = UnitPosture::Active;
        updated
    }

    /// Advances or clears worker construction without changing unrelated state.
    #[must_use]
    pub fn with_worker_job(&self, job: Option<WorkerJob>) -> Self {
        let mut updated = self.clone();
        let assignment = updated.activity.worker_assignment();
        updated.activity = updated.activity.with_worker(job, assignment);
        updated.queued_path = None;
        updated
    }

    /// Assigns this worker to its current improved coordinate.
    #[must_use]
    pub fn after_worker_assigned(&self, coordinate: HexCoord) -> Self {
        let mut updated = self.clone();
        updated.activity = updated.activity.with_worker(None, Some(coordinate));
        updated.movement_units = MovementUnits::ZERO;
        updated.queued_path = None;
        updated.posture = UnitPosture::Active;
        updated
    }

    /// Clears a worker assignment and stale route.
    #[must_use]
    pub fn after_worker_assignment_cancelled(&self) -> Self {
        let mut updated = self.clone();
        updated.activity = updated
            .activity
            .with_worker(updated.activity.worker_job().cloned(), None);
        updated.queued_path = None;
        updated
    }

    /// Completes an improvement, consuming one charge when available.
    #[must_use]
    pub fn after_worker_improvement_completed(&self) -> Option<Self> {
        if self.worker_build_charges <= 1 {
            return None;
        }
        let mut updated = self.clone();
        updated.worker_build_charges -= 1;
        updated.activity = updated.activity.with_worker(None, None);
        updated.queued_path = None;
        updated.posture = UnitPosture::Active;
        Some(updated)
    }

    /// Enters persistent worker automation while preserving its planned route.
    #[must_use]
    pub fn after_worker_automation_started(&self) -> Self {
        let mut updated = self.clone();
        updated.merchant_trade_route = None;
        updated.posture = UnitPosture::AutoWorking;
        updated
    }

    /// Stops worker automation when no target remains.
    #[must_use]
    pub fn after_worker_automation_finished(&self) -> Self {
        let mut updated = self.clone();
        updated.queued_path = None;
        updated.posture = UnitPosture::Active;
        updated
    }
}
