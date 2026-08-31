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
    ClientCommandDto, ClientFogModeDto, ClientQueryDto, ClientRequestBodyDto, ClientRequestDto,
};
pub use response::{
    AutoExploreOptionDto, CityExpansionCandidateDto, CityFoundingDraftViewDto,
    CityFoundingJobViewDto, CitySpecializationOptionDto, CityYieldContributionDto,
    CityYieldContributionKindDto, ClientCommandOutcomeDto, ClientCommandRejectionCodeDto,
    ClientCommandResultDto, ClientErrorDto, ClientEventDto, ClientEvidenceDto, ClientFeatureDto,
    ClientLogisticsEvidenceDto, ClientOutcomeDto, ClientParticipantControlDto,
    ClientQueryResultDto, ClientReplayVerificationDto, ClientResponseBodyDto, ClientResponseDto,
    ClientSessionStampDto, DetachmentOptionDto, FieldImprovementViewDto,
    MerchantDestinationOptionDto, MovementSearchMetricsDto, MovementStepViewDto,
    OwnedCityDetailsViewDto, OwnedUnitDetailsViewDto, PendingActionViewDto,
    PlayerArtifactLocationViewDto, PlayerArtifactViewDto, PlayerCityViewDto,
    PlayerDiplomacyViewDto, PlayerDiplomaticMessageViewDto, PlayerDiplomaticProposalViewDto,
    PlayerDiplomaticRelationViewDto, PlayerEconomyViewDto, PlayerFogViewDto,
    PlayerParticipantViewDto, PlayerResourceTradeAgreementViewDto, PlayerTurnLifecycleViewDto,
    PlayerUnitViewDto, PlayerViewPatchDto, PlayerViewSnapshotDto, ProductionOptionDto,
    ReachableTileViewDto, ResearchOptionDto, RoadViewDto, ScienceYieldBreakdownDto,
    ScienceYieldSourceDto, ScienceYieldSourceKindDto, StrategicResourceAmountDto,
    StrategicResourceSourceDto, TechnologyAvailabilityDto, TechnologyUnlockDto,
    UnitMovementExecutionDto, UnitProductionOptionDto, WorkerAutomationActionDto,
    WorkerAutomationMetricsDto, WorkerAutomationOptionDto, WorkerImprovementOptionDto,
    WorkerJobCompletionDto, WorkerJobViewDto, YieldValueDto,
};

/// The only client protocol version accepted by this build.
pub const CLIENT_API_VERSION: u16 = 8;
