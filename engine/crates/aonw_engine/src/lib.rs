//! Pure entry point for deterministic game rules and queries.
//!
//! Authoritative transitions are added only with reviewed canonical fixtures so
//! an incomplete rule cannot become authoritative by accident.

#![forbid(unsafe_code)]

/// Durable behavior identity shared by local archives and server replay.
///
/// Behavior 2 canonicalizes commander armies by troop kind before state hashing.
pub const ENGINE_BEHAVIOR_FINGERPRINT: &str =
    concat!("aonw-engine/", env!("CARGO_PKG_VERSION"), "/behavior-2");

mod application;
mod artifact;
mod city;
mod city_planning;
mod combat;
mod context;
mod diplomacy;
mod diplomacy_policy;
mod economy;
mod hex_inspection;
mod match_start;
mod movement;
mod outcome;
mod pending_turn_actions;
mod production;
mod research;
mod state_digest;
mod technology_unlock;
mod turn_kernel;
mod unit_action;
mod worker;

use aonw_domain::GameState;

pub use application::{
    AllPlayersSubmittedEvent, ArtifactCarriedEvent, ArtifactExcavationStartedEvent,
    ArtifactStoredEvent, AutoExplorePlannedEvent, CanonicalEngineError, CanonicalQueryError,
    CityBuiltBuildingEvent, CityBuiltWonderEvent, CityClaimedHexEvent, CityFoundedEvent,
    CityProducedUnitEvent, CombatEvent, CommandRejectionCode, DiplomaticMessageRespondedEvent,
    DiplomaticMessageSentEvent, DiplomaticPromiseBrokenEvent, DiplomaticProposalExpiredEvent,
    DiplomaticProposalRespondedEvent, DiplomaticProposalSentEvent, DiplomaticRelationChangedEvent,
    DiplomaticScoreChangedEvent, DomainEvent, DomainRejection, DomainTransition,
    DomainTransitionParts, DominationThresholdReachedEvent, EventBudget, ExecutionEvidence,
    FinalizeTimedOutTurnCommand, GameQuery, KickParticipantCommand, LogisticsExecution,
    MapObjectiveSecuredEvent, MatchEndedEvent, MerchantRouteAssignedEvent,
    MerchantTravelQueuedEvent, PlayerCommand, PlayerKickedEvent, PlayerResignedEvent,
    PlayerTimedOutEvent, ProcessorRequirement, QueryResult, ResearchPointsGainedEvent,
    ResignParticipantCommand, StabilityBand, StabilityBandChangedEvent, SystemCommand,
    TechnologyResearchedEvent, TroopDetachedEvent, TurnCommand, TurnEndedEvent,
    TurnKernelCapabilities, TurnKernelExecution, TurnProcessor, WonderProductionRefundedEvent,
    WorkerCompletedJobEvent, WorkerJobCompletion,
};
pub use artifact::{
    ArtifactError, StartArtifactExcavationCommand, StoreArtifactInCityCommand, TradeArtifactCommand,
};
pub use city::{
    CityExpansionCandidate, CityExpansionOptions, CityExpansionOptionsQuery, CityFoundingOptions,
    CityFoundingOptionsQuery, CityWorkedHexOptions, CityWorkedHexOptionsQuery, FoundCityCommand,
    SelectCityExpansionHexCommand, ToggleWorkedHexCommand,
};
pub use city_planning::{CityPlanning, CityPlanningError, CityPlanningQuery};
pub use combat::{
    AttackHexCommand, CombatExecution, CombatModifier, CombatModifierKind, CombatOutcome,
    CombatPreview, CombatPreviewQuery, CombatRng, CombatRoll, CombatStatTarget, CombatTarget,
    EffectiveCombatStats, unit_max_hit_points, unit_threatened_hexes,
};
pub use context::{EngineContext, SystemContext};
pub use diplomacy::{
    DeclareWarCommand, DiplomacyError, OpenResourceExchangeCommand, OpenResourceTradeCommand,
    RespondDiplomaticMessageCommand, RespondDiplomaticProposalCommand,
    SendDiplomaticMessageCommand, SendDiplomaticProposalCommand, SendGoldGiftCommand,
};
pub use diplomacy_policy::{
    DiplomacyDisclosure, DiplomacyPolicy, DiplomacyPolicyError, DiplomacyPolicyPlayerRole,
    DiplomacyPolicyQuery,
};
pub use economy::{
    CityGoldIncomeSource, CityYieldBreakdown, CityYieldContribution, CityYieldContributionKind,
    CityYieldQuery, EconomyForecast, EconomyForecastQuery, EconomyQueryError, StabilityBreakdown,
    StrategicResourceProjection, StrategicResourceProjectionQuery, StrategicResourceSource,
    TreasuryWarning, UnitUpkeepBreakdown, UnitUpkeepSource, WealthProjectGoldIncomeSource,
    YieldValue, strategic_resource_shortages,
};
pub use hex_inspection::{
    HexAssessmentKind, HexAssessmentScore, HexAssessmentTag, HexImprovementAccess,
    HexImprovementOption, HexInspection, HexInspectionError, HexInspectionQuery, HexRecommendation,
};
pub use match_start::{MatchStartError, start_match};
pub use movement::{
    AssignMerchantTradeRouteCommand, AutoExploreOption, AutoExploreUnitCommand,
    CompiledMovementMap, CompiledMovementMapError, DetachTroopCommand, DetachmentOption,
    MerchantDestinationOption, MoveMerchantToCityCommand, MoveUnitCommand, MoveUnitError,
    MovementCost, MovementLogisticsError, MovementSearchMetrics, MovementSearchWorkspace,
    MovementVisibility, ReachableMovement, ReachableMovementQuery, ReachableMovementTile,
    TerrainMovementPlan, TerrainMovementQuery, TerrainMovementQueryError, UnitLogisticsOptions,
    UnitLogisticsOptionsQuery, UnitMovedEvent, UnitMovementExecution, maximum_movement_units,
    route_road_step_indices, stored_route_step_turns, terrain_entry_cost,
};
pub use outcome::{
    CulturalVictoryProgress, DominationVictoryProgress, MapObjectiveProgress,
    OutcomeResolutionError, VictoryProgress, VictoryStatus, VictoryStatusKind,
    calculate_empire_scores, calculate_victory_progress, resolve_game_outcome,
};
pub use pending_turn_actions::{
    PendingTurnAction, PendingTurnActions, PendingTurnActionsError, PendingTurnActionsQuery,
};
pub use production::{
    CitySpecializationOption, ProductionError, ProductionOption, ProductionOptions,
    ProductionOptionsQuery, RushProductionCommand, SetCitySpecializationCommand,
    StartBuildingCommand, StartCityProjectCommand, StartUnitProductionCommand, StartWonderCommand,
    UnitProductionOption,
};
pub use research::{
    CancelResearchSelectionCommand, ResearchError, ResearchOption, ResearchOptions,
    ResearchOptionsQuery, ResearchRecommendation, ResearchRecommendationReason,
    ScienceYieldBreakdown, ScienceYieldSource, ScienceYieldSourceKind, SelectTechnologyCommand,
};
pub use state_digest::StateDigest;
pub use technology_unlock::{
    TechnologyAvailability, TechnologyCombatModifier, TechnologyCombatStat,
    TechnologyEffectSummary, TechnologyQueryError, TechnologyUnlockQuery,
};
pub use unit_action::{UnitActionCommand, UnitActionError};
pub use worker::{
    AssignWorkerToHexCommand, AutomateWorkerCommand, BuildRoadCommand,
    CancelWorkerAssignmentCommand, CancelWorkerJobCommand, ConfirmWorkerImprovementCommand,
    SelectWorkerImprovementCommand, WorkerAutomationAction, WorkerAutomationExecution,
    WorkerAutomationMetrics, WorkerAutomationOption, WorkerImprovementOption, WorkerOptions,
    WorkerOptionsQuery,
};

/// Stateless deterministic engine facade.
#[derive(Clone, Copy, Debug, Default)]
pub struct GameEngine;

impl GameEngine {
    pub(crate) fn plan_terrain_route(
        state: &GameState,
        context: EngineContext<'_>,
        query: TerrainMovementQuery<'_>,
    ) -> Result<TerrainMovementPlan, TerrainMovementQueryError> {
        movement::plan_terrain_route(state, context, query)
    }

    pub(crate) fn reachable_movement_with_workspace(
        state: &GameState,
        context: EngineContext<'_>,
        query: ReachableMovementQuery<'_>,
        workspace: &mut MovementSearchWorkspace,
    ) -> Result<ReachableMovement, TerrainMovementQueryError> {
        movement::find_reachable_tiles_with_workspace(state, context, query, workspace)
    }

    pub(crate) fn apply_move_unit(
        state: &GameState,
        context: EngineContext<'_>,
        command: MoveUnitCommand<'_>,
    ) -> Result<movement::MovementTransition, MoveUnitError> {
        movement::apply_move_unit(state, context, command)
    }
}

#[cfg(test)]
mod tests;
