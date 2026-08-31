use aonw_content::{MapDefinition, MapDocument, RulesetDefinition, ScenarioDefinition};
use aonw_contract_mapping::decode_match_identity;
use aonw_contracts::client::{ClientCommandDto, ClientFogModeDto, ClientQueryDto};
use aonw_contracts::{CityConquestActionDto, CoordinateDto, MatchIdentityDto};
use aonw_domain::{ArtifactId, CityConquestAction, CityId, HexCoord, PlayerId};

use crate::{
    ArtifactCommandRequest, AttackHexRequest, AutoExploreUnitRequest, CityExpansionOptionsRequest,
    CityFoundingOptionsRequest, CityWorkedHexOptionsRequest, CityYieldRequest, DetachTroopRequest,
    DiplomacyRequest, FoundCityRequest, MerchantCityRequest, MoveUnitRequest, OpenSession,
    ProductionCommandRequest, ReachableRequest, RoutePlanRequest, RuntimeQuery,
    SelectCityExpansionHexRequest, SelectTechnologyRequest, StrategicResourceProjectionRequest,
    ToggleWorkedHexRequest, TurnCommandRequest, UnitActionRequest, UnitLogisticsOptionsRequest,
    WorkerImprovementRequest, WorkerOptionsRequest, WorkerUnitRequest,
};

use super::ClientDecodeError;

mod diplomacy;
mod identity;

use identity::{decode_city_id, decode_unit_id};

pub(super) enum DecodedCommand {
    SelectTechnology(SelectTechnologyRequest),
    Diplomacy(DiplomacyRequest),
    Artifact(ArtifactCommandRequest),
    FoundCity(FoundCityRequest),
    ToggleWorkedHex(ToggleWorkedHexRequest),
    SelectCityExpansionHex(SelectCityExpansionHexRequest),
    Production(ProductionCommandRequest),
    SelectWorkerImprovement(WorkerImprovementRequest),
    ConfirmWorkerImprovement(WorkerImprovementRequest),
    CancelWorkerJob(WorkerUnitRequest),
    AssignWorkerToHex(WorkerUnitRequest),
    CancelWorkerAssignment(WorkerUnitRequest),
    BuildRoad(WorkerUnitRequest),
    AutomateWorker(WorkerUnitRequest),
    Attack(AttackHexRequest),
    Move(MoveUnitRequest),
    AutoExplore(AutoExploreUnitRequest),
    AssignMerchantRoute(MerchantCityRequest),
    MoveMerchantToCity(MerchantCityRequest),
    DetachTroop(DetachTroopRequest),
    Cancel(UnitActionRequest),
    Skip(UnitActionRequest),
    Fortify(UnitActionRequest),
    EndTurn(TurnCommandRequest),
    SubmitTurn(TurnCommandRequest),
}

pub(super) fn open_session(
    map_document: &str,
    scenario_document: &str,
    actor_player_id: &str,
) -> Result<OpenSession, ClientDecodeError> {
    let map = map(map_document)?;
    let ruleset = RulesetDefinition::standard().clone();
    let scenario = ScenarioDefinition::from_json(scenario_document.as_bytes(), &map, &ruleset)
        .map_err(|error| ClientDecodeError::new("invalid_scenario", error))?;
    let actor = PlayerId::new(actor_player_id)
        .map_err(|error| ClientDecodeError::new("invalid_actor_player_id", error))?;
    OpenSession::from_scenario(map, ruleset, &scenario, actor)
        .map_err(|error| ClientDecodeError::new("invalid_session", error))
}

pub(super) fn start_match(
    map_document: &str,
    scenario_document: &str,
    actor_player_id: &str,
    match_identity: MatchIdentityDto,
    fog_mode: ClientFogModeDto,
) -> Result<OpenSession, ClientDecodeError> {
    let map = map(map_document)?;
    let ruleset = RulesetDefinition::standard().clone();
    let scenario = ScenarioDefinition::from_json(scenario_document.as_bytes(), &map, &ruleset)
        .map_err(|error| ClientDecodeError::new("invalid_scenario", error))?;
    let actor = PlayerId::new(actor_player_id)
        .map_err(|error| ClientDecodeError::new("invalid_actor_player_id", error))?;
    let identity = decode_match_identity(match_identity)
        .map_err(|error| ClientDecodeError::new("invalid_match_identity", error))?;
    OpenSession::from_scenario_with_match(
        map,
        ruleset,
        &scenario,
        actor,
        identity,
        matches!(fog_mode, ClientFogModeDto::Enabled),
    )
    .map_err(|error| ClientDecodeError::new("invalid_match_start", error))
}

pub(super) fn map(document: &str) -> Result<MapDefinition, ClientDecodeError> {
    map_document(document).map(|document| document.map().clone())
}

pub(super) fn map_document(document: &str) -> Result<MapDocument, ClientDecodeError> {
    MapDocument::from_json(document.as_bytes())
        .map_err(|error| ClientDecodeError::new("invalid_map", error))
}

pub(super) fn query(query: ClientQueryDto) -> Result<RuntimeQuery, ClientDecodeError> {
    match query {
        ClientQueryDto::ResearchOptions { expected_revision } => Ok(RuntimeQuery::ResearchOptions(
            crate::ResearchOptionsRequest { expected_revision },
        )),
        ClientQueryDto::CityFoundingOptions {
            expected_revision,
            founder_unit_id,
        } => Ok(RuntimeQuery::CityFoundingOptions(
            CityFoundingOptionsRequest {
                expected_revision,
                founder_unit_id: decode_unit_id(founder_unit_id)?,
            },
        )),
        ClientQueryDto::CityWorkedHexOptions {
            expected_revision,
            city_id,
        } => Ok(RuntimeQuery::CityWorkedHexOptions(
            CityWorkedHexOptionsRequest {
                expected_revision,
                city_id: decode_city_id(city_id)?,
            },
        )),
        ClientQueryDto::CityExpansionOptions {
            expected_revision,
            city_id,
        } => Ok(RuntimeQuery::CityExpansionOptions(
            CityExpansionOptionsRequest {
                expected_revision,
                city_id: decode_city_id(city_id)?,
            },
        )),
        ClientQueryDto::CityYield {
            expected_revision,
            city_id,
        } => Ok(RuntimeQuery::CityYield(CityYieldRequest {
            expected_revision,
            city_id: decode_city_id(city_id)?,
        })),
        ClientQueryDto::StrategicResourceProjection { expected_revision } => {
            Ok(RuntimeQuery::StrategicResourceProjection(
                StrategicResourceProjectionRequest { expected_revision },
            ))
        }
        ClientQueryDto::ProductionOptions {
            expected_revision,
            city_id,
        } => Ok(RuntimeQuery::ProductionOptions(
            crate::ProductionOptionsRequest {
                expected_revision,
                city_id: decode_city_id(city_id)?,
            },
        )),
        ClientQueryDto::WorkerOptions {
            expected_revision,
            unit_id,
        } => Ok(RuntimeQuery::WorkerOptions(WorkerOptionsRequest {
            expected_revision,
            unit_id: decode_unit_id(unit_id)?,
        })),
        ClientQueryDto::CombatPreview {
            expected_revision,
            attacker_unit_id,
            defender,
        } => Ok(RuntimeQuery::CombatPreview(crate::CombatPreviewRequest {
            expected_revision,
            attacker_unit_id: decode_unit_id(attacker_unit_id)?,
            defender: HexCoord::new(defender.col, defender.row),
        })),
        ClientQueryDto::Reachable {
            expected_revision,
            unit_id,
        } => Ok(RuntimeQuery::Reachable(ReachableRequest {
            expected_revision,
            unit_id: decode_unit_id(unit_id)?,
        })),
        ClientQueryDto::RoutePlan {
            expected_revision,
            unit_id,
            target,
        } => Ok(RuntimeQuery::RoutePlan(RoutePlanRequest {
            expected_revision,
            unit_id: decode_unit_id(unit_id)?,
            target: HexCoord::new(target.col, target.row),
        })),
        ClientQueryDto::UnitLogisticsOptions {
            expected_revision,
            unit_id,
        } => Ok(RuntimeQuery::UnitLogisticsOptions(
            UnitLogisticsOptionsRequest {
                expected_revision,
                unit_id: decode_unit_id(unit_id)?,
            },
        )),
    }
}

#[allow(clippy::too_many_lines)]
pub(super) fn command(command: ClientCommandDto) -> Result<DecodedCommand, ClientDecodeError> {
    match command {
        ClientCommandDto::SelectTechnology {
            expected_revision,
            technology_id,
        } => Ok(DecodedCommand::SelectTechnology(SelectTechnologyRequest {
            expected_revision,
            technology: aonw_contract_mapping::decode_technology(technology_id),
        })),
        command @ (ClientCommandDto::DeclareWar { .. }
        | ClientCommandDto::SendGoldGift { .. }
        | ClientCommandDto::OpenResourceTrade { .. }
        | ClientCommandDto::OpenResourceExchange { .. }
        | ClientCommandDto::SendDiplomaticProposal { .. }
        | ClientCommandDto::RespondDiplomaticProposal { .. }
        | ClientCommandDto::SendDiplomaticMessage { .. }
        | ClientCommandDto::RespondDiplomaticMessage { .. }) => {
            diplomacy::command(command).map(DecodedCommand::Diplomacy)
        }
        ClientCommandDto::StartArtifactExcavation {
            expected_revision,
            unit_id,
        } => Ok(DecodedCommand::Artifact(
            ArtifactCommandRequest::StartExcavation {
                expected_revision,
                unit_id: decode_unit_id(unit_id)?,
            },
        )),
        ClientCommandDto::StoreArtifactInCity {
            expected_revision,
            unit_id,
            city_id,
        } => Ok(DecodedCommand::Artifact(
            ArtifactCommandRequest::StoreInCity {
                expected_revision,
                unit_id: decode_unit_id(unit_id)?,
                city_id: city_id.map(decode_city_id).transpose()?,
            },
        )),
        ClientCommandDto::TradeArtifact {
            expected_revision,
            target_player_id,
            offered_artifact_id,
            offered_gold,
        } => Ok(DecodedCommand::Artifact(ArtifactCommandRequest::Trade {
            expected_revision,
            target_player_id: PlayerId::new(target_player_id)
                .map_err(|error| ClientDecodeError::new("invalid_target_player_id", error))?,
            offered_artifact_id: ArtifactId::new(offered_artifact_id)
                .map_err(|error| ClientDecodeError::new("invalid_artifact_id", error))?,
            offered_gold,
        })),
        ClientCommandDto::FoundCity {
            expected_revision,
            founder_unit_id,
            controlled_hexes,
        } => found_city(expected_revision, founder_unit_id, controlled_hexes)
            .map(DecodedCommand::FoundCity),
        ClientCommandDto::ToggleWorkedHex {
            expected_revision,
            city_id,
            target,
        } => toggle_worked_hex(expected_revision, city_id, target)
            .map(DecodedCommand::ToggleWorkedHex),
        ClientCommandDto::SelectCityExpansionHex {
            expected_revision,
            city_id,
            target,
        } => select_city_expansion_hex(expected_revision, city_id, target)
            .map(DecodedCommand::SelectCityExpansionHex),
        ClientCommandDto::StartBuilding {
            expected_revision,
            city_id,
            building,
        } => Ok(DecodedCommand::Production(
            ProductionCommandRequest::StartBuilding {
                expected_revision,
                city_id: decode_city_id(city_id)?,
                building: aonw_contract_mapping::decode_city_building(building),
            },
        )),
        ClientCommandDto::StartUnitProduction {
            expected_revision,
            city_id,
            unit,
            resource_option_index,
        } => Ok(DecodedCommand::Production(
            ProductionCommandRequest::StartUnitProduction {
                expected_revision,
                city_id: decode_city_id(city_id)?,
                unit: aonw_contract_mapping::decode_unit_kind(unit),
                resource_option_index,
            },
        )),
        ClientCommandDto::StartCityProject {
            expected_revision,
            city_id,
            project,
        } => Ok(DecodedCommand::Production(
            ProductionCommandRequest::StartCityProject {
                expected_revision,
                city_id: decode_city_id(city_id)?,
                project: aonw_contract_mapping::decode_city_project(project),
            },
        )),
        ClientCommandDto::StartWonder {
            expected_revision,
            city_id,
            wonder,
        } => Ok(DecodedCommand::Production(
            ProductionCommandRequest::StartWonder {
                expected_revision,
                city_id: decode_city_id(city_id)?,
                wonder: aonw_contract_mapping::decode_city_wonder(wonder),
            },
        )),
        ClientCommandDto::SetCitySpecialization {
            expected_revision,
            city_id,
            specialization,
        } => Ok(DecodedCommand::Production(
            ProductionCommandRequest::SetCitySpecialization {
                expected_revision,
                city_id: decode_city_id(city_id)?,
                specialization: aonw_contract_mapping::decode_city_specialization(specialization),
            },
        )),
        ClientCommandDto::RushProduction {
            expected_revision,
            city_id,
        } => Ok(DecodedCommand::Production(
            ProductionCommandRequest::RushProduction {
                expected_revision,
                city_id: decode_city_id(city_id)?,
            },
        )),
        ClientCommandDto::SelectWorkerImprovement {
            expected_revision,
            unit_id,
            improvement,
        } => Ok(DecodedCommand::SelectWorkerImprovement(
            WorkerImprovementRequest {
                expected_revision,
                unit_id: decode_unit_id(unit_id)?,
                improvement: Some(aonw_contract_mapping::decode_improvement(improvement)),
            },
        )),
        ClientCommandDto::ConfirmWorkerImprovement {
            expected_revision,
            unit_id,
            improvement,
        } => Ok(DecodedCommand::ConfirmWorkerImprovement(
            WorkerImprovementRequest {
                expected_revision,
                unit_id: decode_unit_id(unit_id)?,
                improvement: improvement.map(aonw_contract_mapping::decode_improvement),
            },
        )),
        ClientCommandDto::CancelWorkerJob {
            expected_revision,
            unit_id,
        } => worker_unit(expected_revision, unit_id).map(DecodedCommand::CancelWorkerJob),
        ClientCommandDto::AssignWorkerToHex {
            expected_revision,
            unit_id,
        } => worker_unit(expected_revision, unit_id).map(DecodedCommand::AssignWorkerToHex),
        ClientCommandDto::CancelWorkerAssignment {
            expected_revision,
            unit_id,
        } => worker_unit(expected_revision, unit_id).map(DecodedCommand::CancelWorkerAssignment),
        ClientCommandDto::BuildRoad {
            expected_revision,
            unit_id,
        } => worker_unit(expected_revision, unit_id).map(DecodedCommand::BuildRoad),
        ClientCommandDto::AutomateWorker {
            expected_revision,
            unit_id,
        } => worker_unit(expected_revision, unit_id).map(DecodedCommand::AutomateWorker),
        ClientCommandDto::AttackHex {
            expected_revision,
            attacker_unit_id,
            defender,
            city_conquest_action,
        } => Ok(DecodedCommand::Attack(AttackHexRequest {
            expected_revision,
            attacker_unit_id: decode_unit_id(attacker_unit_id)?,
            defender: HexCoord::new(defender.col, defender.row),
            city_conquest_action: match city_conquest_action {
                CityConquestActionDto::Capture => CityConquestAction::Capture,
                CityConquestActionDto::Destroy => CityConquestAction::Destroy,
            },
        })),
        ClientCommandDto::MoveUnit {
            expected_revision,
            unit_id,
            target,
        } => Ok(DecodedCommand::Move(MoveUnitRequest {
            expected_revision,
            unit_id: decode_unit_id(unit_id)?,
            target: HexCoord::new(target.col, target.row),
        })),
        ClientCommandDto::AutoExploreUnit {
            expected_revision,
            unit_id,
        } => Ok(DecodedCommand::AutoExplore(AutoExploreUnitRequest {
            expected_revision,
            unit_id: decode_unit_id(unit_id)?,
        })),
        ClientCommandDto::AssignMerchantTradeRoute {
            expected_revision,
            unit_id,
            destination_city_id,
        } => merchant_city(expected_revision, unit_id, destination_city_id)
            .map(DecodedCommand::AssignMerchantRoute),
        ClientCommandDto::MoveMerchantToCity {
            expected_revision,
            unit_id,
            destination_city_id,
        } => merchant_city(expected_revision, unit_id, destination_city_id)
            .map(DecodedCommand::MoveMerchantToCity),
        ClientCommandDto::DetachTroop {
            expected_revision,
            unit_id,
            troop_kind,
        } => Ok(DecodedCommand::DetachTroop(DetachTroopRequest {
            expected_revision,
            unit_id: decode_unit_id(unit_id)?,
            troop_kind: aonw_contract_mapping::decode_troop(troop_kind),
        })),
        ClientCommandDto::CancelUnitAction {
            expected_revision,
            unit_id,
        } => unit_action(expected_revision, unit_id).map(DecodedCommand::Cancel),
        ClientCommandDto::SkipUnitTurn {
            expected_revision,
            unit_id,
        } => unit_action(expected_revision, unit_id).map(DecodedCommand::Skip),
        ClientCommandDto::FortifyUnit {
            expected_revision,
            unit_id,
        } => unit_action(expected_revision, unit_id).map(DecodedCommand::Fortify),
        ClientCommandDto::EndTurn { expected_revision } => {
            Ok(DecodedCommand::EndTurn(TurnCommandRequest {
                expected_revision,
            }))
        }
        ClientCommandDto::SubmitTurn { expected_revision } => {
            Ok(DecodedCommand::SubmitTurn(TurnCommandRequest {
                expected_revision,
            }))
        }
    }
}

fn found_city(
    expected_revision: u64,
    founder_unit_id: String,
    controlled_hexes: Vec<CoordinateDto>,
) -> Result<FoundCityRequest, ClientDecodeError> {
    Ok(FoundCityRequest {
        expected_revision,
        founder_unit_id: decode_unit_id(founder_unit_id)?,
        controlled_hexes: controlled_hexes
            .into_iter()
            .map(|coordinate| HexCoord::new(coordinate.col, coordinate.row))
            .collect(),
    })
}

fn toggle_worked_hex(
    expected_revision: u64,
    city_id: String,
    target: CoordinateDto,
) -> Result<ToggleWorkedHexRequest, ClientDecodeError> {
    Ok(ToggleWorkedHexRequest {
        expected_revision,
        city_id: decode_city_id(city_id)?,
        target: HexCoord::new(target.col, target.row),
    })
}

fn select_city_expansion_hex(
    expected_revision: u64,
    city_id: String,
    target: CoordinateDto,
) -> Result<SelectCityExpansionHexRequest, ClientDecodeError> {
    Ok(SelectCityExpansionHexRequest {
        expected_revision,
        city_id: decode_city_id(city_id)?,
        target: HexCoord::new(target.col, target.row),
    })
}

fn unit_action(
    expected_revision: u64,
    unit_id: String,
) -> Result<UnitActionRequest, ClientDecodeError> {
    Ok(UnitActionRequest {
        expected_revision,
        unit_id: decode_unit_id(unit_id)?,
    })
}

fn worker_unit(
    expected_revision: u64,
    unit_id: String,
) -> Result<WorkerUnitRequest, ClientDecodeError> {
    Ok(WorkerUnitRequest {
        expected_revision,
        unit_id: decode_unit_id(unit_id)?,
    })
}

fn merchant_city(
    expected_revision: u64,
    unit_id: String,
    destination_city_id: String,
) -> Result<MerchantCityRequest, ClientDecodeError> {
    Ok(MerchantCityRequest {
        expected_revision,
        unit_id: decode_unit_id(unit_id)?,
        destination_city_id: CityId::new(destination_city_id)
            .map_err(|error| ClientDecodeError::new("invalid_city_id", error))?,
    })
}
