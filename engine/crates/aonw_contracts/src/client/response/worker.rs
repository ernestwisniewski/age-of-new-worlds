use serde::{Deserialize, Serialize};

use crate::{CoordinateDto, FieldImprovementKindDto, TransportConditionDto};

/// Recipient-safe dynamic field improvement.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct FieldImprovementViewDto {
    /// Improved coordinate.
    pub coordinate: CoordinateDto,
    /// Improvement identity.
    pub improvement: FieldImprovementKindDto,
}

/// Recipient-safe dynamic road segment.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct RoadViewDto {
    /// Road coordinate.
    pub coordinate: CoordinateDto,
    /// Current operational condition.
    pub condition: TransportConditionDto,
}

/// Current worker job visible to its recipient.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum WorkerJobViewDto {
    /// Field-improvement construction.
    FieldImprovement {
        /// Job coordinate.
        target: CoordinateDto,
        /// Improvement being built.
        improvement: FieldImprovementKindDto,
        /// Turns remaining.
        remaining_turns: u32,
        /// Original duration.
        total_turns: u32,
    },
    /// Road construction.
    RoadConstruction {
        /// Job coordinate.
        target: CoordinateDto,
        /// Turns remaining.
        remaining_turns: u32,
        /// Original duration.
        total_turns: u32,
    },
}

/// One currently legal field improvement.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct WorkerImprovementOptionDto {
    /// Improvement identity.
    pub improvement: FieldImprovementKindDto,
    /// Paced construction duration.
    pub build_turns: u32,
}

/// Worker action selected by automation.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum WorkerAutomationActionDto {
    /// Build an improvement.
    Improve {
        /// Improvement to build.
        improvement: FieldImprovementKindDto,
    },
    /// Work an existing improvement.
    Assign,
}

/// Bounded deterministic planner counters.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct WorkerAutomationMetricsDto {
    /// Controlled tiles inspected.
    pub tiles_examined: u32,
    /// Shared-rule evaluations performed.
    pub legality_evaluations: u32,
    /// Complete routes planned.
    pub routes_planned: u32,
}

/// Engine-selected worker automation option.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct WorkerAutomationOptionDto {
    /// Selected coordinate.
    pub target: CoordinateDto,
    /// Action performed at the target.
    pub action: WorkerAutomationActionDto,
    /// Fixed-point complete route cost.
    pub movement_cost_units: u32,
    /// Bounded work evidence.
    pub metrics: WorkerAutomationMetricsDto,
}

/// Successful worker construction kind.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum WorkerJobCompletionDto {
    /// A field improvement completed.
    FieldImprovement {
        /// Completed improvement.
        improvement: FieldImprovementKindDto,
    },
    /// A road segment completed.
    Road,
}
