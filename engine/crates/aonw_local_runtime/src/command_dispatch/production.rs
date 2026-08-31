use aonw_contract_mapping::{
    encode_city_building, encode_city_project, encode_city_specialization, encode_city_wonder,
    encode_unit_kind,
};
use aonw_contracts::{ReplayCommandDto, ReplayRecordDto};
use aonw_domain::{
    CityBuildingType, CityId, CityProjectType, CitySpecializationType, UnitKind, WonderType,
};
use aonw_engine::{
    PlayerCommand, RushProductionCommand, SetCitySpecializationCommand, StartBuildingCommand,
    StartCityProjectCommand, StartUnitProductionCommand, StartWonderCommand,
};

use super::{CommandResult, dispatch_player};
use crate::RuntimeError;
use crate::session::Session;

/// Current revision-bound production queue and specialization commands.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, Hash, PartialEq)]
pub enum ProductionCommandRequest {
    /// Starts one building.
    StartBuilding {
        expected_revision: u64,
        city_id: CityId,
        building: CityBuildingType,
    },
    /// Starts one unit with an optional strategic-cost alternative.
    StartUnitProduction {
        expected_revision: u64,
        city_id: CityId,
        unit: UnitKind,
        resource_option_index: Option<u32>,
    },
    /// Starts one continuous project.
    StartCityProject {
        expected_revision: u64,
        city_id: CityId,
        project: CityProjectType,
    },
    /// Starts one globally unique wonder.
    StartWonder {
        expected_revision: u64,
        city_id: CityId,
        wonder: WonderType,
    },
    /// Selects one city specialization.
    SetCitySpecialization {
        expected_revision: u64,
        city_id: CityId,
        specialization: CitySpecializationType,
    },
    /// Buys one bounded production increment.
    RushProduction {
        expected_revision: u64,
        city_id: CityId,
    },
}

pub(crate) fn dispatch_production(
    session: &mut Session,
    request: &ProductionCommandRequest,
) -> Result<CommandResult, RuntimeError> {
    let (command, replay) = match request {
        ProductionCommandRequest::StartBuilding {
            expected_revision,
            city_id,
            building,
        } => (
            PlayerCommand::StartBuilding(StartBuildingCommand::new(
                *expected_revision,
                city_id,
                *building,
            )),
            ReplayCommandDto::StartBuilding {
                expected_revision: *expected_revision,
                city_id: city_id.as_str().to_owned(),
                building: encode_city_building(*building),
            },
        ),
        ProductionCommandRequest::StartUnitProduction {
            expected_revision,
            city_id,
            unit,
            resource_option_index,
        } => (
            PlayerCommand::StartUnitProduction(StartUnitProductionCommand::new(
                *expected_revision,
                city_id,
                *unit,
                *resource_option_index,
            )),
            ReplayCommandDto::StartUnitProduction {
                expected_revision: *expected_revision,
                city_id: city_id.as_str().to_owned(),
                unit: encode_unit_kind(*unit),
                resource_option_index: *resource_option_index,
            },
        ),
        ProductionCommandRequest::StartCityProject {
            expected_revision,
            city_id,
            project,
        } => (
            PlayerCommand::StartCityProject(StartCityProjectCommand::new(
                *expected_revision,
                city_id,
                *project,
            )),
            ReplayCommandDto::StartCityProject {
                expected_revision: *expected_revision,
                city_id: city_id.as_str().to_owned(),
                project: encode_city_project(*project),
            },
        ),
        ProductionCommandRequest::StartWonder {
            expected_revision,
            city_id,
            wonder,
        } => (
            PlayerCommand::StartWonder(StartWonderCommand::new(
                *expected_revision,
                city_id,
                *wonder,
            )),
            ReplayCommandDto::StartWonder {
                expected_revision: *expected_revision,
                city_id: city_id.as_str().to_owned(),
                wonder: encode_city_wonder(*wonder),
            },
        ),
        ProductionCommandRequest::SetCitySpecialization {
            expected_revision,
            city_id,
            specialization,
        } => (
            PlayerCommand::SetCitySpecialization(SetCitySpecializationCommand::new(
                *expected_revision,
                city_id,
                *specialization,
            )),
            ReplayCommandDto::SetCitySpecialization {
                expected_revision: *expected_revision,
                city_id: city_id.as_str().to_owned(),
                specialization: encode_city_specialization(*specialization),
            },
        ),
        ProductionCommandRequest::RushProduction {
            expected_revision,
            city_id,
        } => (
            PlayerCommand::RushProduction(RushProductionCommand::new(*expected_revision, city_id)),
            ReplayCommandDto::RushProduction {
                expected_revision: *expected_revision,
                city_id: city_id.as_str().to_owned(),
            },
        ),
    };
    dispatch_player(
        session,
        command,
        ReplayRecordDto::Player { command: replay },
    )
}
