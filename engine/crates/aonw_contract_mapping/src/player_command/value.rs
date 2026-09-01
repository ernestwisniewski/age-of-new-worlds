use aonw_domain::{ArtifactId, CityId, PlayerId, UnitId};

use super::PlayerCommandMappingError;

pub(super) fn player_id(value: String) -> Result<PlayerId, PlayerCommandMappingError> {
    PlayerId::new(value)
        .map_err(|error| PlayerCommandMappingError::new("invalid_target_player_id", error))
}

pub(super) fn city_id(value: String) -> Result<CityId, PlayerCommandMappingError> {
    CityId::new(value).map_err(|error| PlayerCommandMappingError::new("invalid_city_id", error))
}

pub(super) fn unit_id(value: String) -> Result<UnitId, PlayerCommandMappingError> {
    UnitId::new(value).map_err(|error| PlayerCommandMappingError::new("invalid_unit_id", error))
}

pub(super) fn artifact_id(value: String) -> Result<ArtifactId, PlayerCommandMappingError> {
    ArtifactId::new(value)
        .map_err(|error| PlayerCommandMappingError::new("invalid_artifact_id", error))
}
