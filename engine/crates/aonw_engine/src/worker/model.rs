use aonw_domain::{FieldImprovementKind, HexCoord, UnitId};

use crate::UnitMovementExecution;

macro_rules! unit_command {
    ($name:ident) => {
        #[doc = "One revision-bound worker command."]
        #[derive(Clone, Copy, Debug)]
        pub struct $name<'command> {
            expected_revision: u64,
            unit_id: &'command UnitId,
        }
        impl<'command> $name<'command> {
            /// Creates the command.
            #[must_use]
            pub const fn new(expected_revision: u64, unit_id: &'command UnitId) -> Self {
                Self {
                    expected_revision,
                    unit_id,
                }
            }
            pub(crate) const fn expected_revision(self) -> u64 {
                self.expected_revision
            }
            pub(crate) const fn unit_id(self) -> &'command UnitId {
                self.unit_id
            }
        }
    };
}

unit_command!(CancelWorkerJobCommand);
unit_command!(AssignWorkerToHexCommand);
unit_command!(CancelWorkerAssignmentCommand);
unit_command!(BuildRoadCommand);
unit_command!(AutomateWorkerCommand);

/// Selects and immediately starts one legal improvement.
#[derive(Clone, Copy, Debug)]
pub struct SelectWorkerImprovementCommand<'command> {
    expected_revision: u64,
    unit_id: &'command UnitId,
    improvement: FieldImprovementKind,
}

impl<'command> SelectWorkerImprovementCommand<'command> {
    /// Creates the command.
    #[must_use]
    pub const fn new(
        expected_revision: u64,
        unit_id: &'command UnitId,
        improvement: FieldImprovementKind,
    ) -> Self {
        Self {
            expected_revision,
            unit_id,
            improvement,
        }
    }
    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
    pub(crate) const fn unit_id(self) -> &'command UnitId {
        self.unit_id
    }
    pub(crate) const fn improvement(self) -> FieldImprovementKind {
        self.improvement
    }
}

/// Confirms an explicit or matching pending improvement selection.
#[derive(Clone, Copy, Debug)]
pub struct ConfirmWorkerImprovementCommand<'command> {
    expected_revision: u64,
    unit_id: &'command UnitId,
    improvement: Option<FieldImprovementKind>,
}

impl<'command> ConfirmWorkerImprovementCommand<'command> {
    /// Creates the command.
    #[must_use]
    pub const fn new(
        expected_revision: u64,
        unit_id: &'command UnitId,
        improvement: Option<FieldImprovementKind>,
    ) -> Self {
        Self {
            expected_revision,
            unit_id,
            improvement,
        }
    }
    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
    pub(crate) const fn unit_id(self) -> &'command UnitId {
        self.unit_id
    }
    pub(crate) const fn improvement(self) -> Option<FieldImprovementKind> {
        self.improvement
    }
}

/// Revision-bound engine-owned worker options query.
#[derive(Clone, Copy, Debug)]
pub struct WorkerOptionsQuery<'query> {
    expected_revision: u64,
    unit_id: &'query UnitId,
}

impl<'query> WorkerOptionsQuery<'query> {
    /// Creates the query.
    #[must_use]
    pub const fn new(expected_revision: u64, unit_id: &'query UnitId) -> Self {
        Self {
            expected_revision,
            unit_id,
        }
    }
    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
    pub(crate) const fn unit_id(self) -> &'query UnitId {
        self.unit_id
    }
}

/// One improvement accepted by the same rule path used for commands.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct WorkerImprovementOption {
    kind: FieldImprovementKind,
    build_turns: u32,
}

impl WorkerImprovementOption {
    pub(crate) const fn new(kind: FieldImprovementKind, build_turns: u32) -> Self {
        Self { kind, build_turns }
    }
    /// Returns improvement identity.
    #[must_use]
    pub const fn kind(self) -> FieldImprovementKind {
        self.kind
    }
    /// Returns paced duration.
    #[must_use]
    pub const fn build_turns(self) -> u32 {
        self.build_turns
    }
}

/// Deterministic work counters produced by worker automation planning.
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub struct WorkerAutomationMetrics {
    tiles_examined: u32,
    legality_evaluations: u32,
    routes_planned: u32,
}

#[allow(missing_docs)]
impl WorkerAutomationMetrics {
    pub(crate) fn tile(&mut self) {
        self.tiles_examined = self.tiles_examined.saturating_add(1);
    }
    pub(crate) fn legality(&mut self) {
        self.legality_evaluations = self.legality_evaluations.saturating_add(1);
    }
    pub(crate) fn route(&mut self) {
        self.routes_planned = self.routes_planned.saturating_add(1);
    }
    #[must_use]
    pub const fn tiles_examined(self) -> u32 {
        self.tiles_examined
    }
    #[must_use]
    pub const fn legality_evaluations(self) -> u32 {
        self.legality_evaluations
    }
    #[must_use]
    pub const fn routes_planned(self) -> u32 {
        self.routes_planned
    }
}

/// Worker action selected by the deterministic planner.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum WorkerAutomationAction {
    /// Construct an improvement at the target.
    Improve(FieldImprovementKind),
    /// Work an already improved target.
    Assign,
}

/// Engine-selected automation target and bounded work evidence.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct WorkerAutomationOption {
    target: HexCoord,
    action: WorkerAutomationAction,
    movement_cost_units: u32,
    metrics: WorkerAutomationMetrics,
}

/// Exact bounded worker-automation execution evidence.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct WorkerAutomationExecution {
    unit_id: UnitId,
    option: WorkerAutomationOption,
    movement: Option<UnitMovementExecution>,
}

#[allow(missing_docs)]
impl WorkerAutomationExecution {
    pub(crate) const fn new(
        unit_id: UnitId,
        option: WorkerAutomationOption,
        movement: Option<UnitMovementExecution>,
    ) -> Self {
        Self {
            unit_id,
            option,
            movement,
        }
    }
    #[must_use]
    pub const fn unit_id(&self) -> &UnitId {
        &self.unit_id
    }
    #[must_use]
    pub const fn option(&self) -> WorkerAutomationOption {
        self.option
    }
    #[must_use]
    pub const fn movement(&self) -> Option<&UnitMovementExecution> {
        self.movement.as_ref()
    }
}

#[allow(missing_docs)]
impl WorkerAutomationOption {
    pub(crate) const fn new(
        target: HexCoord,
        action: WorkerAutomationAction,
        movement_cost_units: u32,
        metrics: WorkerAutomationMetrics,
    ) -> Self {
        Self {
            target,
            action,
            movement_cost_units,
            metrics,
        }
    }
    #[must_use]
    pub const fn target(self) -> HexCoord {
        self.target
    }
    #[must_use]
    pub const fn action(self) -> WorkerAutomationAction {
        self.action
    }
    #[must_use]
    pub const fn movement_cost_units(self) -> u32 {
        self.movement_cost_units
    }
    #[must_use]
    pub const fn metrics(self) -> WorkerAutomationMetrics {
        self.metrics
    }
}

/// Complete engine-owned options required by a new client.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct WorkerOptions {
    revision: u64,
    unit_id: UnitId,
    coordinate: HexCoord,
    improvements: Box<[WorkerImprovementOption]>,
    can_assign: bool,
    can_build_road: bool,
    automation: Option<WorkerAutomationOption>,
}

#[allow(missing_docs)]
impl WorkerOptions {
    pub(crate) fn new(
        revision: u64,
        unit_id: UnitId,
        coordinate: HexCoord,
        improvements: Vec<WorkerImprovementOption>,
        can_assign: bool,
        can_build_road: bool,
        automation: Option<WorkerAutomationOption>,
    ) -> Self {
        Self {
            revision,
            unit_id,
            coordinate,
            improvements: improvements.into_boxed_slice(),
            can_assign,
            can_build_road,
            automation,
        }
    }
    #[must_use]
    pub const fn revision(&self) -> u64 {
        self.revision
    }
    #[must_use]
    pub const fn unit_id(&self) -> &UnitId {
        &self.unit_id
    }
    #[must_use]
    pub const fn coordinate(&self) -> HexCoord {
        self.coordinate
    }
    #[must_use]
    pub const fn improvements(&self) -> &[WorkerImprovementOption] {
        &self.improvements
    }
    #[must_use]
    pub const fn can_assign(&self) -> bool {
        self.can_assign
    }
    #[must_use]
    pub const fn can_build_road(&self) -> bool {
        self.can_build_road
    }
    #[must_use]
    pub const fn automation(&self) -> Option<WorkerAutomationOption> {
        self.automation
    }
}
