//! Pure entry point for deterministic game rules and queries.
//!
//! Authoritative transitions are added only with reviewed canonical fixtures so
//! an incomplete rule cannot become authoritative by accident.

#![forbid(unsafe_code)]

mod application;
mod artifact;
mod city;
mod combat;
mod context;
mod diplomacy;
mod diplomacy_policy;
mod economy;
mod match_start;
mod movement;
mod outcome;
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
pub use combat::{
    AttackHexCommand, CombatExecution, CombatModifier, CombatModifierKind, CombatOutcome,
    CombatPreview, CombatPreviewQuery, CombatRng, CombatRoll, CombatStatTarget, CombatTarget,
    EffectiveCombatStats, unit_max_hit_points,
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
    UnitUpkeepBreakdown, UnitUpkeepSource, WealthProjectGoldIncomeSource, YieldValue,
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
    terrain_entry_cost,
};
pub use outcome::{
    CulturalVictoryProgress, DominationVictoryProgress, MapObjectiveProgress,
    OutcomeResolutionError, VictoryProgress, calculate_empire_scores, calculate_victory_progress,
    resolve_game_outcome,
};
pub use production::{
    CitySpecializationOption, ProductionError, ProductionOption, ProductionOptions,
    ProductionOptionsQuery, RushProductionCommand, SetCitySpecializationCommand,
    StartBuildingCommand, StartCityProjectCommand, StartUnitProductionCommand, StartWonderCommand,
    UnitProductionOption,
};
pub use research::{
    ResearchError, ResearchOption, ResearchOptions, ResearchOptionsQuery, ScienceYieldBreakdown,
    ScienceYieldSource, ScienceYieldSourceKind, SelectTechnologyCommand,
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
