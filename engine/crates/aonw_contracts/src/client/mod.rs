//! Recipient-safe client protocol shared by native adapters.

mod codec;
mod map;
mod request;
mod response;

pub use crate::MapObjectiveTypeDto;
pub use codec::{ClientCodecError, MAX_CLIENT_REQUEST_JSON_BYTES, MAX_CLIENT_RESPONSE_JSON_BYTES};
pub use map::{
    MapGridLayoutDto, MapObjectiveViewDto, MapResourceDto, MapTerrainDto, MapTileViewDto,
    MapViewDto,
};
pub use request::{
    ClientAiRuntimeProfileDto, ClientCommandDto, ClientFogModeDto, ClientQueryDto,
    ClientRequestBodyDto, ClientRequestDto,
};
pub use response::{
    AutoExploreOptionDto, CityExpansionCandidateDto, CityFoundingDraftViewDto,
    CityFoundingJobViewDto, CitySpecializationOptionDto, CityYieldContributionDto,
    CityYieldContributionKindDto, ClientCommandOutcomeDto, ClientCommandRejectionCodeDto,
    ClientCommandResultDto, ClientErrorDto, ClientEventDto, ClientEvidenceDto, ClientFeatureDto,
    ClientLogisticsEvidenceDto, ClientOutcomeDto, ClientParticipantControlDto,
    ClientQueryResultDto, ClientReplayVerificationDto, ClientResponseBodyDto, ClientResponseDto,
    ClientSessionStampDto, CulturalVictoryProgressDto, DetachmentOptionDto,
    DominationVictoryProgressDto, EconomyForecastDto, FieldImprovementViewDto, GoldIncomeSourceDto,
    HexAssessmentKindDto, HexAssessmentScoreDto, HexAssessmentTagDto, HexImprovementAccessDto,
    HexImprovementOptionDto, HexInspectionDto, HexRecommendationDto, MapObjectiveProgressDto,
    MerchantDestinationOptionDto, MerchantRouteViewDto, MovementSearchMetricsDto,
    MovementStepViewDto, OwnedCityDetailsViewDto, OwnedUnitDetailsViewDto, PendingActionViewDto,
    PendingTurnActionDto, PlayerArtifactLocationViewDto, PlayerArtifactViewDto, PlayerCityViewDto,
    PlayerDiplomacyViewDto, PlayerDiplomaticMessageViewDto, PlayerDiplomaticProposalViewDto,
    PlayerDiplomaticRelationViewDto, PlayerEconomyViewDto, PlayerFogViewDto,
    PlayerParticipantViewDto, PlayerResearchViewDto, PlayerResourceTradeAgreementViewDto,
    PlayerTurnLifecycleViewDto, PlayerUnitViewDto, PlayerVictoryViewDto, PlayerViewPatchDto,
    PlayerViewSnapshotDto, ProductionForecastDto, ProductionOptionDto, ProductionRushQuoteDto,
    QueuedRouteViewDto, ReachableTileViewDto, ResearchOptionDto, ResearchRecommendationDto,
    ResearchRecommendationReasonDto, RoadViewDto, ScienceYieldBreakdownDto, ScienceYieldSourceDto,
    ScienceYieldSourceKindDto, StabilityBreakdownDto, StrategicResourceAllocationDto,
    StrategicResourceAmountDto, StrategicResourceBalanceDto, StrategicResourceDepositDto,
    StrategicResourceInventoryDto, StrategicResourceSourceDto, TechnologyAvailabilityDto,
    TechnologyEraDto, TechnologyUnlockDto, TreasuryWarningDto, UnitMovementExecutionDto,
    UnitProductionOptionDto, UnitUpkeepBreakdownDto, UnitUpkeepSourceDto, VictoryStatusDto,
    VictoryStatusKindDto, WorkerAutomationActionDto, WorkerAutomationMetricsDto,
    WorkerAutomationOptionDto, WorkerImprovementOptionDto, WorkerJobCompletionDto,
    WorkerJobViewDto, YieldValueDto,
};

/// The only client protocol version accepted by this build.
pub const CLIENT_API_VERSION: u16 = 30;

/// Largest command series carried by one observed AI response.
pub const MAX_CLIENT_OBSERVED_COMMANDS: usize = 1_024;
