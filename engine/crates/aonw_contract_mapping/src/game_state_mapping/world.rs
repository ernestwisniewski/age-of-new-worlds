use aonw_contracts::PlayerFogDto;
use aonw_domain::{PlayerFog, PlayerId};

use super::error::GameStateMappingError;
use super::value::{decode_coordinate, encode_coordinate};

pub(super) fn decode_fog(
    index: usize,
    dto: PlayerFogDto,
) -> Result<PlayerFog, GameStateMappingError> {
    let player = PlayerId::new(dto.player_id).map_err(|error| {
        GameStateMappingError::new(format!("$.fogOfWar[{index}].playerId"), error.to_string())
    })?;
    Ok(PlayerFog::new(
        player,
        dto.discovered_hexes.into_iter().map(decode_coordinate),
        dto.visible_hexes.into_iter().map(decode_coordinate),
    ))
}

pub(super) fn encode_fog(fog: &PlayerFog) -> PlayerFogDto {
    PlayerFogDto {
        player_id: fog.player_id().as_str().to_owned(),
        discovered_hexes: fog
            .discovered_hexes()
            .iter()
            .copied()
            .map(encode_coordinate)
            .collect(),
        visible_hexes: fog
            .visible_hexes()
            .iter()
            .copied()
            .map(encode_coordinate)
            .collect(),
    }
}
