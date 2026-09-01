use aonw_contract_mapping::decode_game_state;
use aonw_contracts::ReplaySystemCommandDto;
use aonw_contracts::server::{ServerCommandResultDto, SystemCommandServerRequestDto};
use aonw_domain::{PlayerId, UtcTimestamp};
use aonw_engine::{
    FinalizeTimedOutTurnCommand, KickParticipantCommand, ResignParticipantCommand, SystemCommand,
};

use crate::{
    PreparedServerWorld, ServerBoundaryError, SystemCommandRequest, apply_system_command,
    encode_server_command_result, require_api_version, validate_content_identity,
};

/// Applies one strict current trusted-system-command DTO.
///
/// # Errors
///
/// Returns an error before persistence for invalid command values, canonical
/// state, content identity, offset capacity, or engine failure.
pub fn apply_system_command_dto(
    world: PreparedServerWorld,
    request: SystemCommandServerRequestDto,
) -> Result<ServerCommandResultDto, ServerBoundaryError> {
    require_api_version(request.api_version)?;
    validate_content_identity(&world, &request.map_hash, &request.ruleset_hash)?;
    let state = decode_game_state(request.state)
        .map_err(|error| ServerBoundaryError::InvalidCanonicalState(error.to_string()))?;
    let initial_event_offset = request.initial_event_offset;
    let outcome = match request.command {
        ReplaySystemCommandDto::FinalizeTimedOutTurn {
            expected_revision,
            player_ids,
            skipped_player_ids,
            next_turn_started_at,
        } => {
            let player_ids = decode_player_ids(player_ids)?;
            let skipped_player_ids = decode_player_ids(skipped_player_ids)?;
            let next_turn_started_at = next_turn_started_at
                .map(UtcTimestamp::new)
                .transpose()
                .map_err(|error| ServerBoundaryError::InvalidSystemCommand(error.to_string()))?;
            apply_system_command(SystemCommandRequest {
                state,
                world,
                command: SystemCommand::FinalizeTimedOutTurn(FinalizeTimedOutTurnCommand::new(
                    expected_revision,
                    &player_ids,
                    &skipped_player_ids,
                    next_turn_started_at.as_ref(),
                )),
                initial_event_offset,
            })
        }
        ReplaySystemCommandDto::KickParticipant {
            expected_revision,
            player_id,
            reason,
            timeout_streak,
        } => {
            let player_id = decode_player_id(player_id)?;
            validate_kick(&reason, timeout_streak)?;
            apply_system_command(SystemCommandRequest {
                state,
                world,
                command: SystemCommand::KickParticipant(KickParticipantCommand::new(
                    expected_revision,
                    &player_id,
                    &reason,
                    timeout_streak,
                )),
                initial_event_offset,
            })
        }
        ReplaySystemCommandDto::ResignParticipant {
            expected_revision,
            player_id,
        } => {
            let player_id = decode_player_id(player_id)?;
            apply_system_command(SystemCommandRequest {
                state,
                world,
                command: SystemCommand::ResignParticipant(ResignParticipantCommand::new(
                    expected_revision,
                    &player_id,
                )),
                initial_event_offset,
            })
        }
    }
    .map_err(ServerBoundaryError::Host)?;
    Ok(encode_server_command_result(&outcome))
}

fn validate_kick(reason: &str, timeout_streak: i64) -> Result<(), ServerBoundaryError> {
    if reason.trim().is_empty() {
        return Err(ServerBoundaryError::InvalidSystemCommand(
            "kick reason must not be empty".to_owned(),
        ));
    }
    if timeout_streak < 0 {
        return Err(ServerBoundaryError::InvalidSystemCommand(
            "timeout streak must not be negative".to_owned(),
        ));
    }
    Ok(())
}

fn decode_player_ids(values: Vec<String>) -> Result<Vec<PlayerId>, ServerBoundaryError> {
    values.into_iter().map(decode_player_id).collect()
}

fn decode_player_id(value: String) -> Result<PlayerId, ServerBoundaryError> {
    PlayerId::new(value)
        .map_err(|error| ServerBoundaryError::InvalidSystemCommand(error.to_string()))
}
