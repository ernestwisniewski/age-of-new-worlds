use std::collections::{BTreeMap, BTreeSet};

use aonw_contracts::MapObjectiveHoldStateDto;
use aonw_domain::{MapObjectiveHoldState, MatchIdentity, ObjectiveState, PlayerId};

use super::error::GameStateMappingError;

pub(super) fn decode_objectives(
    identity: &MatchIdentity,
    domination: BTreeMap<String, i64>,
    cultural: BTreeMap<String, i64>,
    map_objectives: Vec<MapObjectiveHoldStateDto>,
) -> Result<ObjectiveState, GameStateMappingError> {
    let domination = decode_player_holds(identity, domination, "$.dominationHoldTurnsByPlayerId")?;
    let cultural = decode_player_holds(identity, cultural, "$.culturalVictoryHoldTurnsByPlayerId")?;
    let mut objective_ids = BTreeSet::new();
    let map_objectives = map_objectives
        .into_iter()
        .enumerate()
        .map(|(index, value)| {
            let path = format!("$.mapObjectiveHoldStates[{index}]");
            if value.objective_id.trim().is_empty() {
                return Err(GameStateMappingError::new(
                    format!("{path}.objectiveId"),
                    "objective identifier must be non-empty",
                ));
            }
            if !objective_ids.insert(value.objective_id.clone()) {
                return Err(GameStateMappingError::new(
                    format!("{path}.objectiveId"),
                    "duplicate objective identifier",
                ));
            }
            let player = decode_player(identity, value.player_id, &format!("{path}.playerId"))?;
            let hold_turns = decode_positive_turns(value.hold_turns, &format!("{path}.holdTurns"))?;
            MapObjectiveHoldState::try_new(value.objective_id, player, hold_turns)
                .map_err(|error| GameStateMappingError::new(path, error.to_string()))
        })
        .collect::<Result<Vec<_>, _>>()?;
    ObjectiveState::try_new(identity, domination, cultural, map_objectives)
        .map_err(|error| GameStateMappingError::new("$.mapObjectiveHoldStates", error.to_string()))
}

#[must_use]
pub(super) fn encode_domination(value: &ObjectiveState) -> BTreeMap<String, i64> {
    encode_player_holds(value.domination_hold_turns_by_player_id())
}

#[must_use]
pub(super) fn encode_cultural(value: &ObjectiveState) -> BTreeMap<String, i64> {
    encode_player_holds(value.cultural_victory_hold_turns_by_player_id())
}

#[must_use]
pub(super) fn encode_map_objectives(value: &ObjectiveState) -> Vec<MapObjectiveHoldStateDto> {
    value
        .map_objective_hold_states()
        .iter()
        .map(|hold| MapObjectiveHoldStateDto {
            objective_id: hold.objective_id().to_owned(),
            player_id: hold.player_id().as_str().to_owned(),
            hold_turns: i64::from(hold.hold_turns()),
        })
        .collect()
}

fn decode_player_holds(
    identity: &MatchIdentity,
    values: BTreeMap<String, i64>,
    path: &str,
) -> Result<BTreeMap<PlayerId, u32>, GameStateMappingError> {
    values
        .into_iter()
        .map(|(key, value)| {
            let entry_path = format!("{path}.{key}");
            let player = decode_player(identity, key, &entry_path)?;
            let turns = decode_positive_turns(value, &entry_path)?;
            Ok((player, turns))
        })
        .collect()
}

fn decode_player(
    identity: &MatchIdentity,
    value: String,
    path: &str,
) -> Result<PlayerId, GameStateMappingError> {
    let player = PlayerId::new(value)
        .map_err(|error| GameStateMappingError::new(path, error.to_string()))?;
    if identity.contains(&player) {
        Ok(player)
    } else {
        Err(GameStateMappingError::new(
            path,
            format!("objective state references non-participant: {player}"),
        ))
    }
}

fn decode_positive_turns(value: i64, path: &str) -> Result<u32, GameStateMappingError> {
    let turns = u32::try_from(value)
        .map_err(|_| GameStateMappingError::new(path, "hold turns must fit unsigned 32-bit"))?;
    if turns == 0 {
        Err(GameStateMappingError::new(
            path,
            "sparse hold turns must be positive",
        ))
    } else {
        Ok(turns)
    }
}

fn encode_player_holds(values: &BTreeMap<PlayerId, u32>) -> BTreeMap<String, i64> {
    values
        .iter()
        .map(|(player, turns)| (player.as_str().to_owned(), i64::from(*turns)))
        .collect()
}
