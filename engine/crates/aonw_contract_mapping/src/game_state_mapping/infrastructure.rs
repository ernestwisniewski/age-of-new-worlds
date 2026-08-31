use aonw_contracts::{
    FieldImprovementDto, TransportConditionDto, TransportSegmentDto, TransportSegmentKindDto,
};
use aonw_domain::{
    City, CityId, FieldImprovement, HexCoord, HexGridBounds, MatchIdentity, PlayerId,
    TransportCondition, TransportKind, TransportSegment,
};

use super::error::GameStateMappingError;
use super::value::{decode_coordinate, decode_improvement, encode_coordinate, encode_improvement};

pub(super) fn decode_field_improvement(
    index: usize,
    bounds: HexGridBounds,
    cities: &[City],
    dto: FieldImprovementDto,
) -> Result<FieldImprovement, GameStateMappingError> {
    let path = format!("$.fieldImprovements[{index}]");
    let coordinate = decode_coordinate(dto.coordinate);
    require_in_bounds(bounds, coordinate, &format!("{path}.coordinate"))?;
    let built_by_city_id = dto
        .built_by_city_id
        .map(CityId::new)
        .transpose()
        .map_err(|error| {
            GameStateMappingError::new(format!("{path}.builtByCityId"), error.to_string())
        })?;
    require_city(
        cities,
        built_by_city_id.as_ref(),
        &format!("{path}.builtByCityId"),
    )?;
    Ok(FieldImprovement::new(
        coordinate,
        decode_improvement(dto.kind),
        built_by_city_id,
    ))
}

#[must_use]
pub(super) fn encode_field_improvement(value: &FieldImprovement) -> FieldImprovementDto {
    FieldImprovementDto {
        coordinate: encode_coordinate(value.coordinate()),
        kind: encode_improvement(value.kind()),
        built_by_city_id: value.built_by_city_id().map(|id| id.as_str().to_owned()),
    }
}

pub(super) fn decode_transport(
    index: usize,
    identity: &MatchIdentity,
    bounds: HexGridBounds,
    cities: &[City],
    dto: TransportSegmentDto,
) -> Result<TransportSegment, GameStateMappingError> {
    let path = format!("$.transportNetwork[{index}]");
    let coordinate = decode_coordinate(dto.coordinate);
    require_in_bounds(bounds, coordinate, &format!("{path}.coordinate"))?;
    let built_by_player_id = PlayerId::new(dto.built_by_player_id).map_err(|error| {
        GameStateMappingError::new(format!("{path}.builtByPlayerId"), error.to_string())
    })?;
    if !identity.contains(&built_by_player_id) {
        return Err(GameStateMappingError::new(
            format!("{path}.builtByPlayerId"),
            format!("transport builder is not a participant: {built_by_player_id}"),
        ));
    }
    let built_by_city_id = dto
        .built_by_city_id
        .map(CityId::new)
        .transpose()
        .map_err(|error| {
            GameStateMappingError::new(format!("{path}.builtByCityId"), error.to_string())
        })?;
    require_city(
        cities,
        built_by_city_id.as_ref(),
        &format!("{path}.builtByCityId"),
    )?;
    match dto.kind {
        TransportSegmentKindDto::Road => Ok(TransportSegment::road(
            coordinate,
            match dto.condition {
                TransportConditionDto::Operational => TransportCondition::Operational,
                TransportConditionDto::Pillaged => TransportCondition::Pillaged,
            },
            built_by_player_id,
            built_by_city_id,
        )),
    }
}

#[must_use]
pub(super) fn encode_transport(segment: &TransportSegment) -> TransportSegmentDto {
    TransportSegmentDto {
        coordinate: encode_coordinate(segment.coordinate()),
        kind: match segment.kind() {
            TransportKind::Road => TransportSegmentKindDto::Road,
        },
        condition: match segment.condition() {
            TransportCondition::Operational => TransportConditionDto::Operational,
            TransportCondition::Pillaged => TransportConditionDto::Pillaged,
        },
        built_by_player_id: segment.built_by_player_id().as_str().to_owned(),
        built_by_city_id: segment.built_by_city_id().map(|id| id.as_str().to_owned()),
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
                "infrastructure coordinate is outside the map: ({}, {})",
                coordinate.col(),
                coordinate.row()
            ),
        ))
    }
}

fn require_city(
    cities: &[City],
    city_id: Option<&CityId>,
    path: &str,
) -> Result<(), GameStateMappingError> {
    let Some(city_id) = city_id else {
        return Ok(());
    };
    if cities.iter().any(|city| city.id() == city_id) {
        Ok(())
    } else {
        Err(GameStateMappingError::new(
            path,
            format!("infrastructure references missing city: {city_id}"),
        ))
    }
}
