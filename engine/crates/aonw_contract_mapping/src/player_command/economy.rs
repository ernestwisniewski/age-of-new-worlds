use aonw_contracts::client::ClientCommandDto;
use aonw_domain::HexCoord;
use aonw_engine::{
    AssignWorkerToHexCommand, AutomateWorkerCommand, BuildRoadCommand,
    CancelWorkerAssignmentCommand, CancelWorkerJobCommand, ConfirmWorkerImprovementCommand,
    FoundCityCommand, PlayerCommand, RushProductionCommand, SelectCityExpansionHexCommand,
    SelectTechnologyCommand, SelectWorkerImprovementCommand, SetCitySpecializationCommand,
    StartArtifactExcavationCommand, StartBuildingCommand, StartCityProjectCommand,
    StartUnitProductionCommand, StartWonderCommand, StoreArtifactInCityCommand,
    ToggleWorkedHexCommand, TradeArtifactCommand,
};

use super::{PlayerCommandMappingError, value};

#[allow(clippy::too_many_lines)]
pub(super) fn decode<R>(
    command: ClientCommandDto,
    apply: impl for<'command> FnOnce(PlayerCommand<'command>) -> R,
) -> Result<R, PlayerCommandMappingError> {
    match command {
        ClientCommandDto::SelectTechnology {
            expected_revision,
            technology_id,
        } => Ok(apply(PlayerCommand::SelectTechnology(
            SelectTechnologyCommand::new(
                expected_revision,
                crate::decode_technology(technology_id),
            ),
        ))),
        ClientCommandDto::StartArtifactExcavation {
            expected_revision,
            unit_id,
        } => {
            let unit = value::unit_id(unit_id)?;
            Ok(apply(PlayerCommand::StartArtifactExcavation(
                StartArtifactExcavationCommand::new(expected_revision, &unit),
            )))
        }
        ClientCommandDto::StoreArtifactInCity {
            expected_revision,
            unit_id,
            city_id,
        } => {
            let unit = value::unit_id(unit_id)?;
            let city = city_id.map(value::city_id).transpose()?;
            Ok(apply(PlayerCommand::StoreArtifactInCity(
                StoreArtifactInCityCommand::new(expected_revision, &unit, city.as_ref()),
            )))
        }
        ClientCommandDto::TradeArtifact {
            expected_revision,
            target_player_id,
            offered_artifact_id,
            offered_gold,
        } => {
            let target = value::player_id(target_player_id)?;
            let artifact = value::artifact_id(offered_artifact_id)?;
            Ok(apply(PlayerCommand::TradeArtifact(
                TradeArtifactCommand::new(expected_revision, &target, &artifact, offered_gold),
            )))
        }
        ClientCommandDto::FoundCity {
            expected_revision,
            founder_unit_id,
            controlled_hexes,
        } => {
            let founder = value::unit_id(founder_unit_id)?;
            let controlled = controlled_hexes
                .into_iter()
                .map(|coordinate| HexCoord::new(coordinate.col, coordinate.row))
                .collect::<Vec<_>>();
            Ok(apply(PlayerCommand::FoundCity(FoundCityCommand::new(
                expected_revision,
                &founder,
                &controlled,
            ))))
        }
        ClientCommandDto::ToggleWorkedHex {
            expected_revision,
            city_id,
            target,
        } => {
            let city = value::city_id(city_id)?;
            Ok(apply(PlayerCommand::ToggleWorkedHex(
                ToggleWorkedHexCommand::new(
                    expected_revision,
                    &city,
                    HexCoord::new(target.col, target.row),
                ),
            )))
        }
        ClientCommandDto::SelectCityExpansionHex {
            expected_revision,
            city_id,
            target,
        } => {
            let city = value::city_id(city_id)?;
            Ok(apply(PlayerCommand::SelectCityExpansionHex(
                SelectCityExpansionHexCommand::new(
                    expected_revision,
                    &city,
                    HexCoord::new(target.col, target.row),
                ),
            )))
        }
        ClientCommandDto::StartBuilding {
            expected_revision,
            city_id,
            building,
        } => {
            let city = value::city_id(city_id)?;
            Ok(apply(PlayerCommand::StartBuilding(
                StartBuildingCommand::new(
                    expected_revision,
                    &city,
                    crate::decode_city_building(building),
                ),
            )))
        }
        ClientCommandDto::StartUnitProduction {
            expected_revision,
            city_id,
            unit,
            resource_option_index,
        } => {
            let city = value::city_id(city_id)?;
            Ok(apply(PlayerCommand::StartUnitProduction(
                StartUnitProductionCommand::new(
                    expected_revision,
                    &city,
                    crate::decode_unit_kind(unit),
                    resource_option_index,
                ),
            )))
        }
        ClientCommandDto::StartCityProject {
            expected_revision,
            city_id,
            project,
        } => {
            let city = value::city_id(city_id)?;
            Ok(apply(PlayerCommand::StartCityProject(
                StartCityProjectCommand::new(
                    expected_revision,
                    &city,
                    crate::decode_city_project(project),
                ),
            )))
        }
        ClientCommandDto::StartWonder {
            expected_revision,
            city_id,
            wonder,
        } => {
            let city = value::city_id(city_id)?;
            Ok(apply(PlayerCommand::StartWonder(StartWonderCommand::new(
                expected_revision,
                &city,
                crate::decode_city_wonder(wonder),
            ))))
        }
        ClientCommandDto::SetCitySpecialization {
            expected_revision,
            city_id,
            specialization,
        } => {
            let city = value::city_id(city_id)?;
            Ok(apply(PlayerCommand::SetCitySpecialization(
                SetCitySpecializationCommand::new(
                    expected_revision,
                    &city,
                    crate::decode_city_specialization(specialization),
                ),
            )))
        }
        ClientCommandDto::RushProduction {
            expected_revision,
            city_id,
        } => {
            let city = value::city_id(city_id)?;
            Ok(apply(PlayerCommand::RushProduction(
                RushProductionCommand::new(expected_revision, &city),
            )))
        }
        ClientCommandDto::SelectWorkerImprovement {
            expected_revision,
            unit_id,
            improvement,
        } => {
            let unit = value::unit_id(unit_id)?;
            Ok(apply(PlayerCommand::SelectWorkerImprovement(
                SelectWorkerImprovementCommand::new(
                    expected_revision,
                    &unit,
                    crate::decode_improvement(improvement),
                ),
            )))
        }
        ClientCommandDto::ConfirmWorkerImprovement {
            expected_revision,
            unit_id,
            improvement,
        } => {
            let unit = value::unit_id(unit_id)?;
            Ok(apply(PlayerCommand::ConfirmWorkerImprovement(
                ConfirmWorkerImprovementCommand::new(
                    expected_revision,
                    &unit,
                    improvement.map(crate::decode_improvement),
                ),
            )))
        }
        ClientCommandDto::CancelWorkerJob {
            expected_revision,
            unit_id,
        } => worker_unit(unit_id, |unit| {
            apply(PlayerCommand::CancelWorkerJob(CancelWorkerJobCommand::new(
                expected_revision,
                unit,
            )))
        }),
        ClientCommandDto::AssignWorkerToHex {
            expected_revision,
            unit_id,
        } => worker_unit(unit_id, |unit| {
            apply(PlayerCommand::AssignWorkerToHex(
                AssignWorkerToHexCommand::new(expected_revision, unit),
            ))
        }),
        ClientCommandDto::CancelWorkerAssignment {
            expected_revision,
            unit_id,
        } => worker_unit(unit_id, |unit| {
            apply(PlayerCommand::CancelWorkerAssignment(
                CancelWorkerAssignmentCommand::new(expected_revision, unit),
            ))
        }),
        ClientCommandDto::BuildRoad {
            expected_revision,
            unit_id,
        } => worker_unit(unit_id, |unit| {
            apply(PlayerCommand::BuildRoad(BuildRoadCommand::new(
                expected_revision,
                unit,
            )))
        }),
        ClientCommandDto::AutomateWorker {
            expected_revision,
            unit_id,
        } => worker_unit(unit_id, |unit| {
            apply(PlayerCommand::AutomateWorker(AutomateWorkerCommand::new(
                expected_revision,
                unit,
            )))
        }),
        _ => unreachable!("economy decoder receives only economy commands"),
    }
}

fn worker_unit<R>(
    unit_id: String,
    apply: impl for<'command> FnOnce(&'command aonw_domain::UnitId) -> R,
) -> Result<R, PlayerCommandMappingError> {
    let unit = value::unit_id(unit_id)?;
    Ok(apply(&unit))
}
