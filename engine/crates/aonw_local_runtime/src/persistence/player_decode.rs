use aonw_contract_mapping::{
    decode_city_building, decode_city_project, decode_city_specialization, decode_city_wonder,
    decode_improvement, decode_resource, decode_troop, decode_unit_kind,
};
use aonw_contracts::ReplayCommandDto;
use aonw_domain::{ArtifactId, CityConquestAction, CityId, PlayerId, UnitId};

use super::{
    PersistenceError, ReplayRuntimeCommand, decode_found_city, decode_merchant_city,
    decode_select_city_expansion_hex, decode_toggle_worked_hex, decode_unit_action,
    decode_worker_unit,
};
use crate::{
    ArtifactCommandRequest, AttackHexRequest, AutoExploreUnitRequest, DetachTroopRequest,
    DiplomacyRequest, MoveUnitRequest, SelectTechnologyRequest,
};
use crate::{ProductionCommandRequest, TurnCommandRequest};

pub(super) fn decode_command(
    command: &ReplayCommandDto,
) -> Result<ReplayRuntimeCommand, PersistenceError> {
    match command {
        command @ ReplayCommandDto::SelectTechnology { .. } => Ok(decode_research_command(command)),
        command @ (ReplayCommandDto::DeclareWar { .. }
        | ReplayCommandDto::SendGoldGift { .. }
        | ReplayCommandDto::OpenResourceTrade { .. }
        | ReplayCommandDto::OpenResourceExchange { .. }
        | ReplayCommandDto::SendDiplomaticProposal { .. }
        | ReplayCommandDto::RespondDiplomaticProposal { .. }
        | ReplayCommandDto::SendDiplomaticMessage { .. }
        | ReplayCommandDto::RespondDiplomaticMessage { .. }) => decode_diplomacy_command(command),
        command @ (ReplayCommandDto::StartArtifactExcavation { .. }
        | ReplayCommandDto::StoreArtifactInCity { .. }
        | ReplayCommandDto::TradeArtifact { .. }) => decode_artifact_command(command),
        command @ (ReplayCommandDto::FoundCity { .. }
        | ReplayCommandDto::ToggleWorkedHex { .. }
        | ReplayCommandDto::SelectCityExpansionHex { .. }) => decode_city_command(command),
        command @ (ReplayCommandDto::StartBuilding { .. }
        | ReplayCommandDto::StartUnitProduction { .. }
        | ReplayCommandDto::StartCityProject { .. }
        | ReplayCommandDto::StartWonder { .. }
        | ReplayCommandDto::SetCitySpecialization { .. }
        | ReplayCommandDto::RushProduction { .. }) => decode_production_command(command),
        command @ (ReplayCommandDto::SelectWorkerImprovement { .. }
        | ReplayCommandDto::ConfirmWorkerImprovement { .. }
        | ReplayCommandDto::CancelWorkerJob { .. }
        | ReplayCommandDto::AssignWorkerToHex { .. }
        | ReplayCommandDto::CancelWorkerAssignment { .. }
        | ReplayCommandDto::BuildRoad { .. }
        | ReplayCommandDto::AutomateWorker { .. }) => decode_worker_command(command),
        ReplayCommandDto::AttackHex {
            expected_revision,
            attacker_unit_id,
            defender,
            city_conquest_action,
        } => Ok(ReplayRuntimeCommand::Attack(AttackHexRequest {
            expected_revision: *expected_revision,
            attacker_unit_id: UnitId::new(attacker_unit_id.clone())
                .map_err(PersistenceError::InvalidUnit)?,
            defender: aonw_domain::HexCoord::new(defender.col, defender.row),
            city_conquest_action: match city_conquest_action {
                aonw_contracts::CityConquestActionDto::Capture => CityConquestAction::Capture,
                aonw_contracts::CityConquestActionDto::Destroy => CityConquestAction::Destroy,
            },
        })),
        ReplayCommandDto::MoveUnit {
            expected_revision,
            unit_id,
            target,
        } => Ok(ReplayRuntimeCommand::Move(MoveUnitRequest {
            expected_revision: *expected_revision,
            unit_id: UnitId::new(unit_id.clone()).map_err(PersistenceError::InvalidUnit)?,
            target: aonw_domain::HexCoord::new(target.col, target.row),
        })),
        ReplayCommandDto::AutoExploreUnit {
            expected_revision,
            unit_id,
        } => Ok(ReplayRuntimeCommand::AutoExplore(AutoExploreUnitRequest {
            expected_revision: *expected_revision,
            unit_id: UnitId::new(unit_id.clone()).map_err(PersistenceError::InvalidUnit)?,
        })),
        ReplayCommandDto::AssignMerchantTradeRoute {
            expected_revision,
            unit_id,
            destination_city_id,
        } => decode_merchant_city(*expected_revision, unit_id, destination_city_id)
            .map(ReplayRuntimeCommand::AssignMerchantRoute),
        ReplayCommandDto::MoveMerchantToCity {
            expected_revision,
            unit_id,
            destination_city_id,
        } => decode_merchant_city(*expected_revision, unit_id, destination_city_id)
            .map(ReplayRuntimeCommand::MoveMerchantToCity),
        ReplayCommandDto::DetachTroop {
            expected_revision,
            unit_id,
            troop_kind,
        } => Ok(ReplayRuntimeCommand::DetachTroop(DetachTroopRequest {
            expected_revision: *expected_revision,
            unit_id: UnitId::new(unit_id.clone()).map_err(PersistenceError::InvalidUnit)?,
            troop_kind: decode_troop(*troop_kind),
        })),
        ReplayCommandDto::CancelUnitAction {
            expected_revision,
            unit_id,
        } => decode_unit_action(*expected_revision, unit_id).map(ReplayRuntimeCommand::Cancel),
        ReplayCommandDto::SkipUnitTurn {
            expected_revision,
            unit_id,
        } => decode_unit_action(*expected_revision, unit_id).map(ReplayRuntimeCommand::Skip),
        ReplayCommandDto::FortifyUnit {
            expected_revision,
            unit_id,
        } => decode_unit_action(*expected_revision, unit_id).map(ReplayRuntimeCommand::Fortify),
        command @ (ReplayCommandDto::EndTurn { .. } | ReplayCommandDto::SubmitTurn { .. }) => {
            Ok(decode_turn_command(command))
        }
    }
}

fn decode_research_command(command: &ReplayCommandDto) -> ReplayRuntimeCommand {
    let ReplayCommandDto::SelectTechnology {
        expected_revision,
        technology_id,
    } = command
    else {
        unreachable!("research decoder receives only research commands")
    };
    ReplayRuntimeCommand::SelectTechnology(SelectTechnologyRequest {
        expected_revision: *expected_revision,
        technology: aonw_contract_mapping::decode_technology(*technology_id),
    })
}

fn decode_diplomacy_command(
    command: &ReplayCommandDto,
) -> Result<ReplayRuntimeCommand, PersistenceError> {
    let request = match command {
        ReplayCommandDto::DeclareWar {
            expected_revision,
            target_player_id,
        } => DiplomacyRequest::DeclareWar {
            expected_revision: *expected_revision,
            target_player_id: PlayerId::new(target_player_id.clone())
                .map_err(PersistenceError::InvalidPlayer)?,
        },
        ReplayCommandDto::SendGoldGift {
            expected_revision,
            target_player_id,
            amount,
        } => DiplomacyRequest::SendGoldGift {
            expected_revision: *expected_revision,
            target_player_id: PlayerId::new(target_player_id.clone())
                .map_err(PersistenceError::InvalidPlayer)?,
            amount: *amount,
        },
        ReplayCommandDto::OpenResourceTrade {
            expected_revision,
            target_player_id,
            resource,
            gold_per_turn,
            duration_turns,
            agreement_id,
        } => DiplomacyRequest::OpenResourceTrade {
            expected_revision: *expected_revision,
            target_player_id: PlayerId::new(target_player_id.clone())
                .map_err(PersistenceError::InvalidPlayer)?,
            resource: decode_resource(*resource),
            gold_per_turn: *gold_per_turn,
            duration_turns: *duration_turns,
            agreement_id: agreement_id.clone(),
        },
        ReplayCommandDto::OpenResourceExchange {
            expected_revision,
            target_player_id,
            offered_resource,
            requested_resource,
            duration_turns,
            agreement_id,
        } => DiplomacyRequest::OpenResourceExchange {
            expected_revision: *expected_revision,
            target_player_id: PlayerId::new(target_player_id.clone())
                .map_err(PersistenceError::InvalidPlayer)?,
            offered_resource: decode_resource(*offered_resource),
            requested_resource: decode_resource(*requested_resource),
            duration_turns: *duration_turns,
            agreement_id: agreement_id.clone(),
        },
        ReplayCommandDto::SendDiplomaticProposal {
            expected_revision,
            target_player_id,
            kind,
            proposal_id,
            gold_payment,
        } => DiplomacyRequest::Send {
            expected_revision: *expected_revision,
            target_player_id: PlayerId::new(target_player_id.clone())
                .map_err(PersistenceError::InvalidPlayer)?,
            kind: aonw_contract_mapping::decode_proposal_kind(*kind),
            proposal_id: proposal_id.clone(),
            gold_payment: *gold_payment,
        },
        ReplayCommandDto::RespondDiplomaticProposal {
            expected_revision,
            proposal_id,
            accepted,
        } => DiplomacyRequest::Respond {
            expected_revision: *expected_revision,
            proposal_id: proposal_id.clone(),
            accepted: *accepted,
        },
        ReplayCommandDto::SendDiplomaticMessage {
            expected_revision,
            target_player_id,
            topic,
            message_id,
        } => DiplomacyRequest::SendMessage {
            expected_revision: *expected_revision,
            target_player_id: PlayerId::new(target_player_id.clone())
                .map_err(PersistenceError::InvalidPlayer)?,
            topic: aonw_contract_mapping::decode_message_topic(*topic),
            message_id: message_id.clone(),
        },
        ReplayCommandDto::RespondDiplomaticMessage {
            expected_revision,
            message_id,
            response,
        } => DiplomacyRequest::RespondMessage {
            expected_revision: *expected_revision,
            message_id: message_id.clone(),
            response: aonw_contract_mapping::decode_message_response(*response),
        },
        _ => unreachable!("diplomacy decoder receives only diplomacy commands"),
    };
    Ok(ReplayRuntimeCommand::Diplomacy(request))
}

fn decode_city_command(
    command: &ReplayCommandDto,
) -> Result<ReplayRuntimeCommand, PersistenceError> {
    match command {
        ReplayCommandDto::FoundCity {
            expected_revision,
            founder_unit_id,
            controlled_hexes,
        } => decode_found_city(*expected_revision, founder_unit_id, controlled_hexes)
            .map(ReplayRuntimeCommand::FoundCity),
        ReplayCommandDto::ToggleWorkedHex {
            expected_revision,
            city_id,
            target,
        } => decode_toggle_worked_hex(*expected_revision, city_id, *target)
            .map(ReplayRuntimeCommand::ToggleWorkedHex),
        ReplayCommandDto::SelectCityExpansionHex {
            expected_revision,
            city_id,
            target,
        } => decode_select_city_expansion_hex(*expected_revision, city_id, *target)
            .map(ReplayRuntimeCommand::SelectCityExpansionHex),
        _ => unreachable!("city decoder received another command family"),
    }
}

fn decode_artifact_command(
    command: &ReplayCommandDto,
) -> Result<ReplayRuntimeCommand, PersistenceError> {
    let request = match command {
        ReplayCommandDto::StartArtifactExcavation {
            expected_revision,
            unit_id,
        } => ArtifactCommandRequest::StartExcavation {
            expected_revision: *expected_revision,
            unit_id: UnitId::new(unit_id.clone()).map_err(PersistenceError::InvalidUnit)?,
        },
        ReplayCommandDto::StoreArtifactInCity {
            expected_revision,
            unit_id,
            city_id,
        } => ArtifactCommandRequest::StoreInCity {
            expected_revision: *expected_revision,
            unit_id: UnitId::new(unit_id.clone()).map_err(PersistenceError::InvalidUnit)?,
            city_id: city_id
                .as_ref()
                .map(|value| CityId::new(value.clone()).map_err(PersistenceError::InvalidCity))
                .transpose()?,
        },
        ReplayCommandDto::TradeArtifact {
            expected_revision,
            target_player_id,
            offered_artifact_id,
            offered_gold,
        } => ArtifactCommandRequest::Trade {
            expected_revision: *expected_revision,
            target_player_id: PlayerId::new(target_player_id.clone())
                .map_err(PersistenceError::InvalidActor)?,
            offered_artifact_id: ArtifactId::new(offered_artifact_id.clone())
                .map_err(PersistenceError::InvalidArtifact)?,
            offered_gold: *offered_gold,
        },
        _ => unreachable!("artifact decoder received another command family"),
    };
    Ok(ReplayRuntimeCommand::Artifact(request))
}

fn decode_production_command(
    command: &ReplayCommandDto,
) -> Result<ReplayRuntimeCommand, PersistenceError> {
    let request = match command {
        ReplayCommandDto::StartBuilding {
            expected_revision,
            city_id,
            building,
        } => ProductionCommandRequest::StartBuilding {
            expected_revision: *expected_revision,
            city_id: decode_city(city_id)?,
            building: decode_city_building(*building),
        },
        ReplayCommandDto::StartUnitProduction {
            expected_revision,
            city_id,
            unit,
            resource_option_index,
        } => ProductionCommandRequest::StartUnitProduction {
            expected_revision: *expected_revision,
            city_id: decode_city(city_id)?,
            unit: decode_unit_kind(*unit),
            resource_option_index: *resource_option_index,
        },
        ReplayCommandDto::StartCityProject {
            expected_revision,
            city_id,
            project,
        } => ProductionCommandRequest::StartCityProject {
            expected_revision: *expected_revision,
            city_id: decode_city(city_id)?,
            project: decode_city_project(*project),
        },
        ReplayCommandDto::StartWonder {
            expected_revision,
            city_id,
            wonder,
        } => ProductionCommandRequest::StartWonder {
            expected_revision: *expected_revision,
            city_id: decode_city(city_id)?,
            wonder: decode_city_wonder(*wonder),
        },
        ReplayCommandDto::SetCitySpecialization {
            expected_revision,
            city_id,
            specialization,
        } => ProductionCommandRequest::SetCitySpecialization {
            expected_revision: *expected_revision,
            city_id: decode_city(city_id)?,
            specialization: decode_city_specialization(*specialization),
        },
        ReplayCommandDto::RushProduction {
            expected_revision,
            city_id,
        } => ProductionCommandRequest::RushProduction {
            expected_revision: *expected_revision,
            city_id: decode_city(city_id)?,
        },
        _ => unreachable!("production decoder received another command family"),
    };
    Ok(ReplayRuntimeCommand::Production(request))
}

fn decode_city(city_id: &str) -> Result<CityId, PersistenceError> {
    CityId::new(city_id.to_owned()).map_err(PersistenceError::InvalidCity)
}

fn decode_turn_command(command: &ReplayCommandDto) -> ReplayRuntimeCommand {
    match command {
        ReplayCommandDto::EndTurn { expected_revision } => {
            ReplayRuntimeCommand::EndTurn(TurnCommandRequest {
                expected_revision: *expected_revision,
            })
        }
        ReplayCommandDto::SubmitTurn { expected_revision } => {
            ReplayRuntimeCommand::SubmitTurn(TurnCommandRequest {
                expected_revision: *expected_revision,
            })
        }
        _ => unreachable!("turn decoder received another command family"),
    }
}

fn decode_worker_command(
    command: &ReplayCommandDto,
) -> Result<ReplayRuntimeCommand, PersistenceError> {
    match command {
        ReplayCommandDto::SelectWorkerImprovement {
            expected_revision,
            unit_id,
            improvement,
        } => Ok(ReplayRuntimeCommand::SelectWorkerImprovement(
            crate::WorkerImprovementRequest {
                expected_revision: *expected_revision,
                unit_id: UnitId::new(unit_id.clone()).map_err(PersistenceError::InvalidUnit)?,
                improvement: Some(decode_improvement(*improvement)),
            },
        )),
        ReplayCommandDto::ConfirmWorkerImprovement {
            expected_revision,
            unit_id,
            improvement,
        } => Ok(ReplayRuntimeCommand::ConfirmWorkerImprovement(
            crate::WorkerImprovementRequest {
                expected_revision: *expected_revision,
                unit_id: UnitId::new(unit_id.clone()).map_err(PersistenceError::InvalidUnit)?,
                improvement: improvement.map(decode_improvement),
            },
        )),
        ReplayCommandDto::CancelWorkerJob {
            expected_revision,
            unit_id,
        } => decode_worker_unit(*expected_revision, unit_id)
            .map(ReplayRuntimeCommand::CancelWorkerJob),
        ReplayCommandDto::AssignWorkerToHex {
            expected_revision,
            unit_id,
        } => decode_worker_unit(*expected_revision, unit_id)
            .map(ReplayRuntimeCommand::AssignWorkerToHex),
        ReplayCommandDto::CancelWorkerAssignment {
            expected_revision,
            unit_id,
        } => decode_worker_unit(*expected_revision, unit_id)
            .map(ReplayRuntimeCommand::CancelWorkerAssignment),
        ReplayCommandDto::BuildRoad {
            expected_revision,
            unit_id,
        } => decode_worker_unit(*expected_revision, unit_id).map(ReplayRuntimeCommand::BuildRoad),
        ReplayCommandDto::AutomateWorker {
            expected_revision,
            unit_id,
        } => decode_worker_unit(*expected_revision, unit_id)
            .map(ReplayRuntimeCommand::AutomateWorker),
        _ => unreachable!("worker decoder received another command family"),
    }
}
