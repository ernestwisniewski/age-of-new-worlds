use aonw_contracts::{
    CityBuildingTypeDto, CityDto, CityProductionQueueDto, CityProductionTargetDto,
    CityProjectTypeDto, CitySpecializationTypeDto, WonderTypeDto,
};
use aonw_domain::{
    City, CityBuildError, CityBuildingType, CityId, CityProductionQueue, CityProductionTarget,
    CityProjectType, CitySpecializationType, HexCoord, HexGridBounds, MatchIdentity, PlayerId,
    WonderType,
};

use crate::{decode_unit_kind, encode_unit_kind};

use super::economy::{decode_stockpile, encode_stockpile};
use super::error::GameStateMappingError;
use super::value::{decode_coordinate, encode_coordinate};

pub(super) fn decode_city(
    index: usize,
    identity: &MatchIdentity,
    bounds: HexGridBounds,
    dto: CityDto,
) -> Result<City, GameStateMappingError> {
    let path = format!("$.cities[{index}]");
    require_in_bounds(
        bounds,
        decode_coordinate(dto.center),
        &format!("{path}.center"),
    )?;
    for (coordinate_index, coordinate) in dto.controlled_hexes.iter().enumerate() {
        require_in_bounds(
            bounds,
            decode_coordinate(*coordinate),
            &format!("{path}.controlledHexes[{coordinate_index}]"),
        )?;
    }
    for (coordinate_index, coordinate) in dto.worked_hexes.iter().enumerate() {
        require_in_bounds(
            bounds,
            decode_coordinate(*coordinate),
            &format!("{path}.workedHexes[{coordinate_index}]"),
        )?;
    }
    if let Some(coordinate) = dto.preferred_expansion_hex {
        require_in_bounds(
            bounds,
            decode_coordinate(coordinate),
            &format!("{path}.preferredExpansionHex"),
        )?;
    }
    let id = CityId::new(dto.id)
        .map_err(|error| GameStateMappingError::new(format!("{path}.id"), error.to_string()))?;
    let owner = player_id(dto.owner_player_id, &format!("{path}.ownerPlayerId"))?;
    require_participant(identity, &owner, &format!("{path}.ownerPlayerId"))?;
    let founding_owner = dto
        .founding_owner_player_id
        .map(|value| player_id(value, &format!("{path}.foundingOwnerPlayerId")))
        .transpose()?;
    if let Some(founding_owner) = &founding_owner {
        require_participant(
            identity,
            founding_owner,
            &format!("{path}.foundingOwnerPlayerId"),
        )?;
    }
    let queue = dto
        .production_queue
        .map(|queue| decode_queue(queue, &format!("{path}.productionQueue")))
        .transpose()?;
    City::builder(id, owner, dto.name, decode_coordinate(dto.center))
        .with_founding_owner(founding_owner)
        .with_progression(
            dto.population,
            dto.stored_food,
            dto.max_hexes,
            dto.territory_radius,
        )
        .with_controlled_hexes(dto.controlled_hexes.into_iter().map(decode_coordinate))
        .with_worked_hexes(dto.worked_hexes.into_iter().map(decode_coordinate))
        .with_buildings(dto.buildings.into_iter().map(decode_building))
        .with_wonders(dto.wonders.into_iter().map(decode_wonder))
        .with_production(queue, dto.production_overflow)
        .with_planning(
            dto.specialization.map(decode_specialization),
            dto.preferred_expansion_hex.map(decode_coordinate),
        )
        .with_hit_points(dto.hit_points)
        .build()
        .map_err(|error| map_city_error(&path, &error))
}

#[must_use]
pub(super) fn encode_city(city: &City) -> CityDto {
    CityDto {
        id: city.id().as_str().to_owned(),
        owner_player_id: city.owner_player_id().as_str().to_owned(),
        founding_owner_player_id: city
            .founding_owner_player_id()
            .map(|value| value.as_str().to_owned()),
        name: city.name().to_owned(),
        population: city.population(),
        stored_food: city.stored_food(),
        max_hexes: city.max_hexes(),
        territory_radius: city.territory_radius(),
        center: encode_coordinate(city.center()),
        controlled_hexes: city
            .controlled_hexes()
            .iter()
            .copied()
            .map(encode_coordinate)
            .collect(),
        worked_hexes: city
            .worked_hexes()
            .iter()
            .copied()
            .map(encode_coordinate)
            .collect(),
        buildings: city
            .buildings()
            .iter()
            .copied()
            .map(encode_building)
            .collect(),
        wonders: city.wonders().iter().copied().map(encode_wonder).collect(),
        production_queue: city.production_queue().map(encode_queue),
        production_overflow: city.production_overflow(),
        specialization: city.specialization().map(encode_specialization),
        preferred_expansion_hex: city.preferred_expansion_hex().map(encode_coordinate),
        hit_points: city.hit_points(),
    }
}

fn decode_queue(
    dto: CityProductionQueueDto,
    path: &str,
) -> Result<CityProductionQueue, GameStateMappingError> {
    CityProductionQueue::try_new(
        decode_target(dto.target),
        dto.invested_production,
        decode_stockpile(
            dto.resource_allocation,
            &format!("{path}.resourceAllocation"),
        )?,
    )
    .map_err(|error| {
        GameStateMappingError::new(format!("{path}.investedProduction"), error.to_string())
    })
}

fn encode_queue(value: &CityProductionQueue) -> CityProductionQueueDto {
    CityProductionQueueDto {
        target: encode_target(value.target()),
        invested_production: value.invested_production(),
        resource_allocation: encode_stockpile(value.resource_allocation()),
    }
}

/// Converts a validated city production queue into its stable wire representation.
#[must_use]
pub fn encode_city_production_queue(value: &CityProductionQueue) -> CityProductionQueueDto {
    encode_queue(value)
}

const fn decode_target(value: CityProductionTargetDto) -> CityProductionTarget {
    match value {
        CityProductionTargetDto::Building { building_type } => {
            CityProductionTarget::Building(decode_building(building_type))
        }
        CityProductionTargetDto::Unit { unit_type } => {
            CityProductionTarget::Unit(decode_unit_kind(unit_type))
        }
        CityProductionTargetDto::Project { project_type } => {
            CityProductionTarget::Project(decode_project(project_type))
        }
        CityProductionTargetDto::Wonder { wonder_type } => {
            CityProductionTarget::Wonder(decode_wonder(wonder_type))
        }
    }
}

const fn encode_target(value: CityProductionTarget) -> CityProductionTargetDto {
    match value {
        CityProductionTarget::Building(building_type) => CityProductionTargetDto::Building {
            building_type: encode_building(building_type),
        },
        CityProductionTarget::Unit(unit_type) => CityProductionTargetDto::Unit {
            unit_type: encode_unit_kind(unit_type),
        },
        CityProductionTarget::Project(project_type) => CityProductionTargetDto::Project {
            project_type: encode_project(project_type),
        },
        CityProductionTarget::Wonder(wonder_type) => CityProductionTargetDto::Wonder {
            wonder_type: encode_wonder(wonder_type),
        },
    }
}

fn player_id(value: String, path: &str) -> Result<PlayerId, GameStateMappingError> {
    PlayerId::new(value).map_err(|error| GameStateMappingError::new(path, error.to_string()))
}

fn require_participant(
    identity: &MatchIdentity,
    player: &PlayerId,
    path: &str,
) -> Result<(), GameStateMappingError> {
    if identity.contains(player) {
        Ok(())
    } else {
        Err(GameStateMappingError::new(
            path,
            format!("city player is not a participant: {player}"),
        ))
    }
}

fn require_in_bounds(
    bounds: HexGridBounds,
    coordinate: HexCoord,
    path: &str,
) -> Result<(), GameStateMappingError> {
    if bounds.contains(coordinate) {
        Ok(())
    } else {
        Err(GameStateMappingError::new(
            path,
            format!(
                "city coordinate is outside the map: ({}, {})",
                coordinate.col(),
                coordinate.row()
            ),
        ))
    }
}

fn map_city_error(path: &str, error: &CityBuildError) -> GameStateMappingError {
    let field = match error {
        CityBuildError::NonPositivePopulation(_) => "population",
        CityBuildError::NegativeStoredFood(_) => "storedFood",
        CityBuildError::NonPositiveMaxHexes(_)
        | CityBuildError::NegativeMaxHexesDelta(_)
        | CityBuildError::MaxHexesOverflow => "maxHexes",
        CityBuildError::NegativeTerritoryRadius(_) => "territoryRadius",
        CityBuildError::NegativeProductionOverflow(_) => "productionOverflow",
        CityBuildError::NonPositiveHitPoints(_) => "hitPoints",
        CityBuildError::DuplicateControlledHex(_) | CityBuildError::CenterInControlledHexes => {
            "controlledHexes"
        }
        CityBuildError::DuplicateWorkedHex(_) | CityBuildError::WorkedHexNotControlled(_) => {
            "workedHexes"
        }
        CityBuildError::DuplicateBuilding(_) => "buildings",
        CityBuildError::DuplicateWonder(_) => "wonders",
    };
    GameStateMappingError::new(format!("{path}.{field}"), error.to_string())
}

macro_rules! enum_mapping {
    ($decode:ident, $encode:ident, $dto:ident, $domain:ident; $($variant:ident),+ $(,)?) => {
        const fn $decode(value: $dto) -> $domain {
            match value {
                $($dto::$variant => $domain::$variant),+
            }
        }

        const fn $encode(value: $domain) -> $dto {
            match value {
                $($domain::$variant => $dto::$variant),+
            }
        }
    };
}

enum_mapping!(
    decode_project,
    encode_project,
    CityProjectTypeDto,
    CityProjectType;
    Wealth,
    Research,
);

enum_mapping!(
    decode_specialization,
    encode_specialization,
    CitySpecializationTypeDto,
    CitySpecializationType;
    Growth,
    Industry,
    Commerce,
    Science,
    Military,
);

enum_mapping!(
    decode_wonder,
    encode_wonder,
    WonderTypeDto,
    WonderType;
    GreatLibrary,
    HangingGardens,
    GreatWall,
    Petra,
    CentralBank,
    ImperialUniversity,
    GrandCathedral,
    MotherFactory,
    NationalObservatory,
    SvalbardSeedVault,
    GrandExposition,
);

enum_mapping!(
    decode_building,
    encode_building,
    CityBuildingTypeDto,
    CityBuildingType;
    Granary,
    WaterMill,
    Workshop,
    Storehouse,
    Housing,
    MerchantHall,
    Stonemason,
    Barracks,
    Marketplace,
    Port,
    Aqueduct,
    Forge,
    Stable,
    Bank,
    BuildersGuild,
    Factory,
    Lighthouse,
    TrainingGrounds,
    TownHall,
    Monument,
    Archive,
    Academy,
    University,
    Observatory,
    Laboratory,
    Reactor,
    Courthouse,
    Court,
    GovernorsOffice,
    SurveyorsOffice,
    PlanningOffice,
    Apothecary,
    PublicBaths,
    Hospital,
    Ministries,
    Walls,
    Armory,
    SiegeWorkshop,
    Citadel,
    WarCollege,
    ConscriptionOffice,
    BorderFort,
    Airfield,
    ArtisansGuild,
    MasterWorkshop,
    Steelworks,
    RailDepot,
    PowerPlant,
    AssemblyPlant,
    Refinery,
    MapRoom,
    Shipyard,
    DryDock,
    NavalAcademy,
    HarborCustoms,
    Museum,
    Parliament,
    BroadcastTower,
    WorldFairGrounds,
);

/// Converts a current client building identity into the domain identity.
#[must_use]
pub const fn decode_city_building(value: CityBuildingTypeDto) -> CityBuildingType {
    decode_building(value)
}

/// Converts a domain building identity into the current client identity.
#[must_use]
pub const fn encode_city_building(value: CityBuildingType) -> CityBuildingTypeDto {
    encode_building(value)
}

/// Converts a current client project identity into the domain identity.
#[must_use]
pub const fn decode_city_project(value: CityProjectTypeDto) -> CityProjectType {
    decode_project(value)
}

/// Converts a domain project identity into the current client identity.
#[must_use]
pub const fn encode_city_project(value: CityProjectType) -> CityProjectTypeDto {
    encode_project(value)
}

/// Converts a current client specialization identity into the domain identity.
#[must_use]
pub const fn decode_city_specialization(
    value: CitySpecializationTypeDto,
) -> CitySpecializationType {
    decode_specialization(value)
}

/// Converts a domain specialization identity into the current client identity.
#[must_use]
pub const fn encode_city_specialization(
    value: CitySpecializationType,
) -> CitySpecializationTypeDto {
    encode_specialization(value)
}

/// Converts a current client wonder identity into the domain identity.
#[must_use]
pub const fn decode_city_wonder(value: WonderTypeDto) -> WonderType {
    decode_wonder(value)
}

/// Converts a domain wonder identity into the current client identity.
#[must_use]
pub const fn encode_city_wonder(value: WonderType) -> WonderTypeDto {
    encode_wonder(value)
}
