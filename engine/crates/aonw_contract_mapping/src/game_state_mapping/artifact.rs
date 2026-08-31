use aonw_contracts::{WorldArtifactDto, WorldArtifactLocationDto, WorldArtifactTypeDto};
use aonw_domain::{
    ArtifactId, CityId, UnitId, WorldArtifact, WorldArtifactLocation, WorldArtifactType,
};

use super::error::GameStateMappingError;
use super::value::{decode_coordinate, encode_coordinate};

pub(super) fn decode_artifact(
    index: usize,
    dto: WorldArtifactDto,
) -> Result<WorldArtifact, GameStateMappingError> {
    let path = format!("$.artifacts[{index}]");
    let id = ArtifactId::new(dto.id)
        .map_err(|error| GameStateMappingError::new(format!("{path}.id"), error.to_string()))?;
    let location = match dto.location {
        WorldArtifactLocationDto::Map { coordinate } => {
            WorldArtifactLocation::Map(decode_coordinate(coordinate))
        }
        WorldArtifactLocationDto::Carried { unit_id } => {
            WorldArtifactLocation::Carried(UnitId::new(unit_id).map_err(|error| {
                GameStateMappingError::new(format!("{path}.location.unitId"), error.to_string())
            })?)
        }
        WorldArtifactLocationDto::Stored { city_id } => {
            WorldArtifactLocation::Stored(CityId::new(city_id).map_err(|error| {
                GameStateMappingError::new(format!("{path}.location.cityId"), error.to_string())
            })?)
        }
        WorldArtifactLocationDto::Excavation {
            unit_id,
            coordinate,
            remaining_turns,
        } => WorldArtifactLocation::Excavation {
            unit_id: UnitId::new(unit_id).map_err(|error| {
                GameStateMappingError::new(format!("{path}.location.unitId"), error.to_string())
            })?,
            coordinate: decode_coordinate(coordinate),
            remaining_turns,
        },
    };
    Ok(WorldArtifact::new(
        id,
        decode_artifact_type(dto.artifact_type),
        location,
    ))
}

pub(super) fn encode_artifact(artifact: &WorldArtifact) -> WorldArtifactDto {
    WorldArtifactDto {
        id: artifact.id().as_str().to_owned(),
        artifact_type: encode_artifact_type(artifact.artifact_type()),
        location: match artifact.location() {
            WorldArtifactLocation::Map(coordinate) => WorldArtifactLocationDto::Map {
                coordinate: encode_coordinate(*coordinate),
            },
            WorldArtifactLocation::Carried(unit_id) => WorldArtifactLocationDto::Carried {
                unit_id: unit_id.as_str().to_owned(),
            },
            WorldArtifactLocation::Stored(city_id) => WorldArtifactLocationDto::Stored {
                city_id: city_id.as_str().to_owned(),
            },
            WorldArtifactLocation::Excavation {
                unit_id,
                coordinate,
                remaining_turns,
            } => WorldArtifactLocationDto::Excavation {
                unit_id: unit_id.as_str().to_owned(),
                coordinate: encode_coordinate(*coordinate),
                remaining_turns: *remaining_turns,
            },
        },
    }
}

const fn decode_artifact_type(value: WorldArtifactTypeDto) -> WorldArtifactType {
    match value {
        WorldArtifactTypeDto::AncientImperialCrown => WorldArtifactType::AncientImperialCrown,
        WorldArtifactTypeDto::AstronomersTablets => WorldArtifactType::AstronomersTablets,
        WorldArtifactTypeDto::ProphetMask => WorldArtifactType::ProphetMask,
        WorldArtifactTypeDto::HeroSword => WorldArtifactType::HeroSword,
        WorldArtifactTypeDto::MerchantsSeal => WorldArtifactType::MerchantsSeal,
        WorldArtifactTypeDto::FirstPeoplesChronicle => WorldArtifactType::FirstPeoplesChronicle,
        WorldArtifactTypeDto::TempleReliquary => WorldArtifactType::TempleReliquary,
        WorldArtifactTypeDto::QueensMirror => WorldArtifactType::QueensMirror,
    }
}

const fn encode_artifact_type(value: WorldArtifactType) -> WorldArtifactTypeDto {
    match value {
        WorldArtifactType::AncientImperialCrown => WorldArtifactTypeDto::AncientImperialCrown,
        WorldArtifactType::AstronomersTablets => WorldArtifactTypeDto::AstronomersTablets,
        WorldArtifactType::ProphetMask => WorldArtifactTypeDto::ProphetMask,
        WorldArtifactType::HeroSword => WorldArtifactTypeDto::HeroSword,
        WorldArtifactType::MerchantsSeal => WorldArtifactTypeDto::MerchantsSeal,
        WorldArtifactType::FirstPeoplesChronicle => WorldArtifactTypeDto::FirstPeoplesChronicle,
        WorldArtifactType::TempleReliquary => WorldArtifactTypeDto::TempleReliquary,
        WorldArtifactType::QueensMirror => WorldArtifactTypeDto::QueensMirror,
    }
}
