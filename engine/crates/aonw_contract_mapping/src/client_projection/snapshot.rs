use aonw_contracts::client::{ClientSessionStampDto, PlayerViewSnapshotDto};

use aonw_projection::{PlayerViewSnapshot, SessionStamp};

use super::{
    artifact, city, diplomacy, encode_pending_action, encode_turn_lifecycle, field_improvement,
    founding_draft, road, unit,
};

/// Maps a recipient-safe session identity stamp to its strict current DTO.
#[must_use]
pub fn encode_client_stamp(value: SessionStamp) -> ClientSessionStampDto {
    ClientSessionStampDto {
        revision: value.revision.get(),
        state_digest: value.state_digest.to_string(),
        map_hash: value.map_hash.to_string(),
        ruleset_hash: value.ruleset_hash.to_string(),
    }
}

/// Maps a complete recipient-safe player projection to its strict current DTO.
#[must_use]
pub fn encode_player_view_snapshot(value: &PlayerViewSnapshot) -> PlayerViewSnapshotDto {
    PlayerViewSnapshotDto {
        stamp: encode_client_stamp(*value.stamp()),
        turn: value.turn(),
        turn_mode: crate::game_state_mapping::encode_turn_mode(value.turn_mode()),
        outcome: crate::encode_game_outcome(value.outcome()),
        turn_lifecycle: encode_turn_lifecycle(*value.turn_lifecycle()),
        pending_action: value.pending_action().map(encode_pending_action),
        city_founding_draft: value.city_founding_draft().map(founding_draft),
        diplomacy: diplomacy(value.diplomacy()),
        units: value.units().iter().map(unit).collect(),
        cities: value.cities().iter().map(city).collect(),
        artifacts: value.artifacts().iter().map(artifact).collect(),
        field_improvements: value
            .field_improvements()
            .iter()
            .copied()
            .map(field_improvement)
            .collect(),
        roads: value.roads().iter().copied().map(road).collect(),
    }
}
