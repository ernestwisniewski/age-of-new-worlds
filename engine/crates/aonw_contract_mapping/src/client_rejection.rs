use aonw_contracts::client::ClientCommandRejectionCodeDto;
use aonw_engine::CommandRejectionCode;

/// Maps one authoritative rejection to its stable current client code.
#[allow(clippy::too_many_lines)]
#[must_use]
pub const fn encode_command_rejection(
    value: CommandRejectionCode,
) -> ClientCommandRejectionCodeDto {
    match value {
        CommandRejectionCode::StaleRevision => ClientCommandRejectionCodeDto::StaleRevision,
        CommandRejectionCode::MatchFinished => ClientCommandRejectionCodeDto::MatchFinished,
        CommandRejectionCode::UnitNotFound => ClientCommandRejectionCodeDto::UnitNotFound,
        CommandRejectionCode::UnitNotControlled => ClientCommandRejectionCodeDto::UnitNotControlled,
        CommandRejectionCode::UnitUnavailable => ClientCommandRejectionCodeDto::UnitUnavailable,
        CommandRejectionCode::UnitUsesTradeRoutes => {
            ClientCommandRejectionCodeDto::UnitUsesTradeRoutes
        }
        CommandRejectionCode::UnitOutOfBounds => ClientCommandRejectionCodeDto::UnitOutOfBounds,
        CommandRejectionCode::MoveTargetOutOfBounds => {
            ClientCommandRejectionCodeDto::MoveTargetOutOfBounds
        }
        CommandRejectionCode::MoveTargetIsCurrentTile => {
            ClientCommandRejectionCodeDto::MoveTargetIsCurrentTile
        }
        CommandRejectionCode::MoveTargetIsForeignCityCenter => {
            ClientCommandRejectionCodeDto::MoveTargetIsForeignCityCenter
        }
        CommandRejectionCode::MoveTargetOccupied => {
            ClientCommandRejectionCodeDto::MoveTargetOccupied
        }
        CommandRejectionCode::UnitMovementCapacityInsufficient => {
            ClientCommandRejectionCodeDto::UnitMovementCapacityInsufficient
        }
        CommandRejectionCode::MovePathNotFound => ClientCommandRejectionCodeDto::MovePathNotFound,
        CommandRejectionCode::UnitNotScout => ClientCommandRejectionCodeDto::UnitNotScout,
        CommandRejectionCode::UnitExhausted => ClientCommandRejectionCodeDto::UnitExhausted,
        CommandRejectionCode::UnitHasPath => ClientCommandRejectionCodeDto::UnitHasPath,
        CommandRejectionCode::AutoExploreNoTarget => {
            ClientCommandRejectionCodeDto::AutoExploreNoTarget
        }
        CommandRejectionCode::UnitNotMerchant => ClientCommandRejectionCodeDto::UnitNotMerchant,
        CommandRejectionCode::MerchantNotInCity => ClientCommandRejectionCodeDto::MerchantNotInCity,
        CommandRejectionCode::DestinationCityNotFound => {
            ClientCommandRejectionCodeDto::DestinationCityNotFound
        }
        CommandRejectionCode::DestinationCityNotControlled => {
            ClientCommandRejectionCodeDto::DestinationCityNotControlled
        }
        CommandRejectionCode::DestinationCityIsOrigin => {
            ClientCommandRejectionCodeDto::DestinationCityIsOrigin
        }
        CommandRejectionCode::DestinationCityIsCurrent => {
            ClientCommandRejectionCodeDto::DestinationCityIsCurrent
        }
        CommandRejectionCode::MerchantRouteNotFound => {
            ClientCommandRejectionCodeDto::MerchantRouteNotFound
        }
        CommandRejectionCode::MerchantCityPathNotFound => {
            ClientCommandRejectionCodeDto::MerchantCityPathNotFound
        }
        CommandRejectionCode::TroopNotAvailable => ClientCommandRejectionCodeDto::TroopNotAvailable,
        CommandRejectionCode::DetachmentSourceOutOfBounds => {
            ClientCommandRejectionCodeDto::DetachmentSourceOutOfBounds
        }
        CommandRejectionCode::DetachmentDestinationUnavailable => {
            ClientCommandRejectionCodeDto::DetachmentDestinationUnavailable
        }
        CommandRejectionCode::DetachedUnitIdUnavailable => {
            ClientCommandRejectionCodeDto::DetachedUnitIdUnavailable
        }
        CommandRejectionCode::UnitBusy => ClientCommandRejectionCodeDto::UnitBusy,
        CommandRejectionCode::UnitDefinitionMissing => {
            ClientCommandRejectionCodeDto::UnitDefinitionMissing
        }
        CommandRejectionCode::StateRevisionOverflow => {
            ClientCommandRejectionCodeDto::StateRevisionOverflow
        }
        CommandRejectionCode::InvalidQueuedMovementPath => {
            ClientCommandRejectionCodeDto::InvalidQueuedMovementPath
        }
        CommandRejectionCode::InvalidUnit => ClientCommandRejectionCodeDto::InvalidUnit,
        CommandRejectionCode::MovementUnitUpdateFailed => {
            ClientCommandRejectionCodeDto::MovementUnitUpdateFailed
        }
        CommandRejectionCode::TurnPlayerNotControlled => {
            ClientCommandRejectionCodeDto::TurnPlayerNotControlled
        }
        CommandRejectionCode::TurnPlayerNotActive => {
            ClientCommandRejectionCodeDto::TurnPlayerNotActive
        }
        CommandRejectionCode::TurnScopeInvalid => ClientCommandRejectionCodeDto::TurnScopeInvalid,
        CommandRejectionCode::TurnProcessorUnsupported => {
            ClientCommandRejectionCodeDto::TurnProcessorUnsupported
        }
        CommandRejectionCode::TurnNumberOverflow => {
            ClientCommandRejectionCodeDto::TurnNumberOverflow
        }
        CommandRejectionCode::AttackerNotFound => ClientCommandRejectionCodeDto::AttackerNotFound,
        CommandRejectionCode::AttackerNotControlled => {
            ClientCommandRejectionCodeDto::AttackerNotControlled
        }
        CommandRejectionCode::AttackerUnavailable => {
            ClientCommandRejectionCodeDto::AttackerUnavailable
        }
        CommandRejectionCode::AttackerExhausted => ClientCommandRejectionCodeDto::AttackerExhausted,
        CommandRejectionCode::AttackerOutOfBounds => {
            ClientCommandRejectionCodeDto::AttackerOutOfBounds
        }
        CommandRejectionCode::AttackerCannotAttack => {
            ClientCommandRejectionCodeDto::AttackerCannotAttack
        }
        CommandRejectionCode::AttackTargetNotVisible => {
            ClientCommandRejectionCodeDto::AttackTargetNotVisible
        }
        CommandRejectionCode::AttackTargetOutOfBounds => {
            ClientCommandRejectionCodeDto::AttackTargetOutOfBounds
        }
        CommandRejectionCode::AttackTargetNotFound => {
            ClientCommandRejectionCodeDto::AttackTargetNotFound
        }
        CommandRejectionCode::AttackTargetNotEnemy => {
            ClientCommandRejectionCodeDto::AttackTargetNotEnemy
        }
        CommandRejectionCode::AttackTargetProtectedByTreaty => {
            ClientCommandRejectionCodeDto::AttackTargetProtectedByTreaty
        }
        CommandRejectionCode::AttackTargetOutOfRange => {
            ClientCommandRejectionCodeDto::AttackTargetOutOfRange
        }
        CommandRejectionCode::AttackCityHasNoHealth => {
            ClientCommandRejectionCodeDto::AttackCityHasNoHealth
        }
        CommandRejectionCode::CityFounderNotFound => {
            ClientCommandRejectionCodeDto::CityFounderNotFound
        }
        CommandRejectionCode::CityFounderNotControlled => {
            ClientCommandRejectionCodeDto::CityFounderNotControlled
        }
        CommandRejectionCode::CityFounderBusy => ClientCommandRejectionCodeDto::CityFounderBusy,
        CommandRejectionCode::CityFounderInvalid => {
            ClientCommandRejectionCodeDto::CityFounderInvalid
        }
        CommandRejectionCode::CityFounderNoSettlers => {
            ClientCommandRejectionCodeDto::CityFounderNoSettlers
        }
        CommandRejectionCode::CitySiteInvalid => ClientCommandRejectionCodeDto::CitySiteInvalid,
        CommandRejectionCode::CityCenterOccupied => {
            ClientCommandRejectionCodeDto::CityCenterOccupied
        }
        CommandRejectionCode::CityCenterClaimed => ClientCommandRejectionCodeDto::CityCenterClaimed,
        CommandRejectionCode::CityCenterTooClose => {
            ClientCommandRejectionCodeDto::CityCenterTooClose
        }
        CommandRejectionCode::CityControlledHexesInvalid => {
            ClientCommandRejectionCodeDto::CityControlledHexesInvalid
        }
        CommandRejectionCode::CityNotFound => ClientCommandRejectionCodeDto::CityNotFound,
        CommandRejectionCode::CityNotControlled => ClientCommandRejectionCodeDto::CityNotControlled,
        CommandRejectionCode::WorkedHexUnavailable => {
            ClientCommandRejectionCodeDto::WorkedHexUnavailable
        }
        CommandRejectionCode::WorkedHexLimitReached => {
            ClientCommandRejectionCodeDto::WorkedHexLimitReached
        }
        CommandRejectionCode::CityExpansionHexUnavailable => {
            ClientCommandRejectionCodeDto::CityExpansionHexUnavailable
        }
        CommandRejectionCode::BuildingNotAvailable => {
            ClientCommandRejectionCodeDto::BuildingNotAvailable
        }
        CommandRejectionCode::UnitProductionInvalidResourceOption => {
            ClientCommandRejectionCodeDto::UnitProductionInvalidResourceOption
        }
        CommandRejectionCode::UnitProductionNotAvailable => {
            ClientCommandRejectionCodeDto::UnitProductionNotAvailable
        }
        CommandRejectionCode::UnitProductionRequiresResource => {
            ClientCommandRejectionCodeDto::UnitProductionRequiresResource
        }
        CommandRejectionCode::UnitProductionMissingStrategicResource => {
            ClientCommandRejectionCodeDto::UnitProductionMissingStrategicResource
        }
        CommandRejectionCode::UnitProductionRequiresCoast => {
            ClientCommandRejectionCodeDto::UnitProductionRequiresCoast
        }
        CommandRejectionCode::UnitSupplyLimitReached => {
            ClientCommandRejectionCodeDto::UnitSupplyLimitReached
        }
        CommandRejectionCode::WonderNotAvailable => {
            ClientCommandRejectionCodeDto::WonderNotAvailable
        }
        CommandRejectionCode::CitySpecializationLocked => {
            ClientCommandRejectionCodeDto::CitySpecializationLocked
        }
        CommandRejectionCode::CitySpecializationUnchanged => {
            ClientCommandRejectionCodeDto::CitySpecializationUnchanged
        }
        CommandRejectionCode::CitySpecializationMissingBuilding => {
            ClientCommandRejectionCodeDto::CitySpecializationMissingBuilding
        }
        CommandRejectionCode::ProductionQueueEmpty => {
            ClientCommandRejectionCodeDto::ProductionQueueEmpty
        }
        CommandRejectionCode::ProjectCannotBeRushed => {
            ClientCommandRejectionCodeDto::ProjectCannotBeRushed
        }
        CommandRejectionCode::RushProductionUnavailable => {
            ClientCommandRejectionCodeDto::RushProductionUnavailable
        }
        CommandRejectionCode::UnitAlreadyCarryingArtifact => {
            ClientCommandRejectionCodeDto::UnitAlreadyCarryingArtifact
        }
        CommandRejectionCode::ArtifactNotFound => ClientCommandRejectionCodeDto::ArtifactNotFound,
        CommandRejectionCode::UnitNotCarryingArtifact => {
            ClientCommandRejectionCodeDto::UnitNotCarryingArtifact
        }
        CommandRejectionCode::UnitNotInCity => ClientCommandRejectionCodeDto::UnitNotInCity,
        CommandRejectionCode::CityArtifactSlotFull => {
            ClientCommandRejectionCodeDto::CityArtifactSlotFull
        }
        CommandRejectionCode::TechnologyPlayerNotControlled => {
            ClientCommandRejectionCodeDto::TechnologyPlayerNotControlled
        }
        CommandRejectionCode::TechnologyNotAvailable => {
            ClientCommandRejectionCodeDto::TechnologyNotAvailable
        }
        CommandRejectionCode::DiplomacyPlayerNotControlled => {
            ClientCommandRejectionCodeDto::DiplomacyPlayerNotControlled
        }
        CommandRejectionCode::DiplomacyTargetNotDiscovered => {
            ClientCommandRejectionCodeDto::DiplomacyTargetNotDiscovered
        }
        CommandRejectionCode::DiplomacyProposalNotAllowed => {
            ClientCommandRejectionCodeDto::DiplomacyProposalNotAllowed
        }
        CommandRejectionCode::DiplomacyDuplicateProposal => {
            ClientCommandRejectionCodeDto::DiplomacyDuplicateProposal
        }
        CommandRejectionCode::DiplomacyProposalNotFound => {
            ClientCommandRejectionCodeDto::DiplomacyProposalNotFound
        }
        CommandRejectionCode::DiplomacyProposalPaymentUnavailable => {
            ClientCommandRejectionCodeDto::DiplomacyProposalPaymentUnavailable
        }
        CommandRejectionCode::DiplomacyMessageCooldown => {
            ClientCommandRejectionCodeDto::DiplomacyMessageCooldown
        }
        CommandRejectionCode::DiplomacyDuplicateMessage => {
            ClientCommandRejectionCodeDto::DiplomacyDuplicateMessage
        }
        CommandRejectionCode::DiplomacyMessageNotFound => {
            ClientCommandRejectionCodeDto::DiplomacyMessageNotFound
        }
        CommandRejectionCode::DiplomacyMessageUnavailable => {
            ClientCommandRejectionCodeDto::DiplomacyMessageUnavailable
        }
        CommandRejectionCode::DiplomacyTruceActive => {
            ClientCommandRejectionCodeDto::DiplomacyTruceActive
        }
        CommandRejectionCode::DiplomacyWarAlreadyActive => {
            ClientCommandRejectionCodeDto::DiplomacyWarAlreadyActive
        }
        CommandRejectionCode::DiplomacyInvalidGoldAmount => {
            ClientCommandRejectionCodeDto::DiplomacyInvalidGoldAmount
        }
        CommandRejectionCode::DiplomacyGoldGiftBlockedByRelation => {
            ClientCommandRejectionCodeDto::DiplomacyGoldGiftBlockedByRelation
        }
        CommandRejectionCode::DiplomacyGoldUnavailable => {
            ClientCommandRejectionCodeDto::DiplomacyGoldUnavailable
        }
        CommandRejectionCode::DiplomacyGoldGiftUnavailable => {
            ClientCommandRejectionCodeDto::DiplomacyGoldGiftUnavailable
        }
        CommandRejectionCode::InvalidResourceTradeTarget => {
            ClientCommandRejectionCodeDto::InvalidResourceTradeTarget
        }
        CommandRejectionCode::InvalidResourceTradeResource => {
            ClientCommandRejectionCodeDto::InvalidResourceTradeResource
        }
        CommandRejectionCode::InvalidResourceTradeTerms => {
            ClientCommandRejectionCodeDto::InvalidResourceTradeTerms
        }
        CommandRejectionCode::ResourceTradeBlockedByWar => {
            ClientCommandRejectionCodeDto::ResourceTradeBlockedByWar
        }
        CommandRejectionCode::ResourceTradeGoldUnavailable => {
            ClientCommandRejectionCodeDto::ResourceTradeGoldUnavailable
        }
        CommandRejectionCode::ResourceTradeAlreadyActive => {
            ClientCommandRejectionCodeDto::ResourceTradeAlreadyActive
        }
        CommandRejectionCode::InvalidResourceTradeAgreementId => {
            ClientCommandRejectionCodeDto::InvalidResourceTradeAgreementId
        }
        CommandRejectionCode::ResourceTradeAgreementIdConflict => {
            ClientCommandRejectionCodeDto::ResourceTradeAgreementIdConflict
        }
        CommandRejectionCode::ResourceTradeExportUnavailable => {
            ClientCommandRejectionCodeDto::ResourceTradeExportUnavailable
        }
        CommandRejectionCode::ResourceTradeOfferUnavailable => {
            ClientCommandRejectionCodeDto::ResourceTradeOfferUnavailable
        }
        CommandRejectionCode::ResourceTradeRequestUnavailable => {
            ClientCommandRejectionCodeDto::ResourceTradeRequestUnavailable
        }
        CommandRejectionCode::ArtifactTradeActorUnavailable => {
            ClientCommandRejectionCodeDto::ArtifactTradeActorUnavailable
        }
        CommandRejectionCode::ArtifactTradeTargetInvalid => {
            ClientCommandRejectionCodeDto::ArtifactTradeTargetInvalid
        }
        CommandRejectionCode::ArtifactTradeGoldInvalid => {
            ClientCommandRejectionCodeDto::ArtifactTradeGoldInvalid
        }
        CommandRejectionCode::ArtifactTradeBlockedByWar => {
            ClientCommandRejectionCodeDto::ArtifactTradeBlockedByWar
        }
        CommandRejectionCode::ArtifactTradeGoldUnavailable => {
            ClientCommandRejectionCodeDto::ArtifactTradeGoldUnavailable
        }
        CommandRejectionCode::OfferedArtifactUnavailable => {
            ClientCommandRejectionCodeDto::OfferedArtifactUnavailable
        }
        CommandRejectionCode::TargetArtifactSlotUnavailable => {
            ClientCommandRejectionCodeDto::TargetArtifactSlotUnavailable
        }
        CommandRejectionCode::WorkerNotFound => ClientCommandRejectionCodeDto::WorkerNotFound,
        CommandRejectionCode::WorkerNotControlled => {
            ClientCommandRejectionCodeDto::WorkerNotControlled
        }
        CommandRejectionCode::WorkerUnavailable => ClientCommandRejectionCodeDto::WorkerUnavailable,
        CommandRejectionCode::WorkerNoMovementPoints => {
            ClientCommandRejectionCodeDto::WorkerNoMovementPoints
        }
        CommandRejectionCode::WorkerQueuedPathActive => {
            ClientCommandRejectionCodeDto::WorkerQueuedPathActive
        }
        CommandRejectionCode::WorkerImprovementNotSelected => {
            ClientCommandRejectionCodeDto::WorkerImprovementNotSelected
        }
        CommandRejectionCode::WorkerActionNotControlled => {
            ClientCommandRejectionCodeDto::WorkerActionNotControlled
        }
        CommandRejectionCode::WorkerImprovementUnavailable => {
            ClientCommandRejectionCodeDto::WorkerImprovementUnavailable
        }
        CommandRejectionCode::WorkerJobNotActive => {
            ClientCommandRejectionCodeDto::WorkerJobNotActive
        }
        CommandRejectionCode::WorkerAssignmentUnavailable => {
            ClientCommandRejectionCodeDto::WorkerAssignmentUnavailable
        }
        CommandRejectionCode::WorkerAssignmentNotActive => {
            ClientCommandRejectionCodeDto::WorkerAssignmentNotActive
        }
        CommandRejectionCode::WorkerRoadUnavailable => {
            ClientCommandRejectionCodeDto::WorkerRoadUnavailable
        }
        CommandRejectionCode::RoadConstructionExistingRoad => {
            ClientCommandRejectionCodeDto::RoadConstructionExistingRoad
        }
        CommandRejectionCode::RoadConstructionCity => {
            ClientCommandRejectionCodeDto::RoadConstructionCity
        }
        CommandRejectionCode::RoadConstructionEnemyTerritory => {
            ClientCommandRejectionCodeDto::RoadConstructionEnemyTerritory
        }
        CommandRejectionCode::RoadConstructionImpassableTerrain => {
            ClientCommandRejectionCodeDto::RoadConstructionImpassableTerrain
        }
        CommandRejectionCode::WorkerAutomationNotActive => {
            ClientCommandRejectionCodeDto::WorkerAutomationNotActive
        }
        CommandRejectionCode::WorkerAutomationNoTarget => {
            ClientCommandRejectionCodeDto::WorkerAutomationNoTarget
        }
    }
}
