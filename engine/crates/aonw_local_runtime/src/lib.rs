//! Lifecycle boundary for one deterministic local game session.

#![forbid(unsafe_code)]

mod client_protocol;
mod command_dispatch;
mod persistence;
mod persistence_error;
mod persistence_file;
mod persistence_validation;
mod prepared_world;
mod query_cache;
mod query_dispatch;
mod session;
mod turn_dispatch;

pub use aonw_projection::{
    CityFoundingDraftView, OwnedCityDetailsView, OwnedUnitDetailsView, PendingActionView,
    PlayerArtifactLocationView, PlayerArtifactView, PlayerCityView, PlayerDiplomacyView,
    PlayerDiplomaticMessageView, PlayerDiplomaticProposalView, PlayerDiplomaticRelationView,
    PlayerFieldImprovementView, PlayerResourceTradeAgreementView, PlayerRoadView,
    PlayerTurnLifecycleView, PlayerUnitView, PlayerViewSnapshot,
};
pub use client_protocol::ClientProtocol;
pub use command_dispatch::{
    ArtifactCommandRequest, AttackHexRequest, AutoExploreUnitRequest, CommandResult,
    DetachTroopRequest, DiplomacyRequest, FoundCityRequest, MerchantCityRequest, MoveUnitRequest,
    PlayerViewPatch, ProductionCommandRequest, SelectCityExpansionHexRequest,
    SelectTechnologyRequest, ToggleWorkedHexRequest, UnitActionRequest, WorkerImprovementRequest,
    WorkerUnitRequest,
};
pub use persistence::{PersistenceError, ReplayVerification};
pub use persistence_file::{PersistenceFileError, PersistenceFileStore, PersistenceRestoreSource};
pub use query_cache::QueryCacheStats;
pub use query_dispatch::{
    AutoExploreOptionView, CityExpansionOptionsRequest, CityFoundingOptionsRequest,
    CityWorkedHexOptionsRequest, CityYieldRequest, CombatPreviewRequest, DetachmentOptionView,
    MerchantDestinationView, MovementStepView, ProductionOptionsRequest, ReachableRequest,
    ReachableResult, ReachableTileView, ResearchOptionsRequest, RoutePlanRequest, RoutePlanResult,
    RuntimeQuery, RuntimeQueryResult, StrategicResourceProjectionRequest,
    UnitLogisticsOptionsRequest, UnitLogisticsOptionsResult, WorkerOptionsRequest,
};
pub use session::{
    ActorHandoffError, AiTurnDriver, AiTurnError, AiTurnExecution, LocalRuntime,
    MAX_AI_TURN_COMMAND_BUDGET, ObservedAiTurn, OpenSession, OpenSessionError, ReplayFrame,
    RuntimeCapabilities, RuntimeError, SessionStamp,
};
pub use turn_dispatch::{
    FinalizeTimedOutTurnRequest, KickParticipantRequest, ResignParticipantRequest,
    TurnCommandRequest,
};
