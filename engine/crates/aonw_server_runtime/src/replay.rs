use aonw_contract_mapping::decode_game_state;
use aonw_contracts::client::{ClientCommandOutcomeDto, ClientCommandResultDto};
use aonw_contracts::server::{
    MAX_SERVER_REPLAY_BATCH_STEPS, PlayerCommandServerRequestDto, ServerReplayBatchRequestDto,
    ServerReplayBatchResultDto, ServerReplayRecordDto, SystemCommandServerRequestDto,
};
use aonw_engine::ENGINE_BEHAVIOR_FINGERPRINT;

use crate::{
    PreparedServerWorld, ServerBoundaryError, apply_player_command_dto, apply_system_command_dto,
    project_server_state, require_api_version, validate_content_identity,
};

/// Replays a bounded journal slice through the authoritative command path.
///
/// Canonical output is exclusively for trusted server continuation. Only the
/// selected snapshot and command may be forwarded to the authenticated player.
///
/// # Errors
/// Fails atomically on incompatible content/behavior, invalid checkpoints,
/// unknown recipients, rejected/no-op commands, or any persisted evidence drift.
pub fn replay_server_batch_dto(
    world: &PreparedServerWorld,
    request: ServerReplayBatchRequestDto,
) -> Result<ServerReplayBatchResultDto, ServerBoundaryError> {
    require_api_version(request.api_version)?;
    validate_content_identity(world, &request.map_hash, &request.ruleset_hash)?;
    if request.behavior_fingerprint != ENGINE_BEHAVIOR_FINGERPRINT
        || request.steps.len() > MAX_SERVER_REPLAY_BATCH_STEPS
    {
        return Err(ServerBoundaryError::ReplayMismatch);
    }
    let state = decode_game_state(request.initial_state.clone())
        .map_err(|error| ServerBoundaryError::InvalidCanonicalState(error.to_string()))?;
    let projection = project_server_state(world, &state)?;
    if projection.stamp.state_digest != request.initial_state_digest {
        return Err(ServerBoundaryError::ReplayMismatch);
    }
    let recipient = projection
        .recipients
        .into_iter()
        .find(|recipient| recipient.recipient_player_id == request.recipient_player_id)
        .ok_or(ServerBoundaryError::ReplayMismatch)?;
    let mut result = ServerReplayBatchResultDto {
        state: request.initial_state,
        stamp: projection.stamp,
        final_event_offset: request.initial_event_offset,
        recipient_player_id: request.recipient_player_id,
        snapshot: recipient.snapshot,
        command: None,
    };
    for step in request.steps {
        if result.stamp.revision.checked_add(1) != Some(step.revision)
            || step.initial_event_offset != result.final_event_offset
        {
            return Err(ServerBoundaryError::ReplayMismatch);
        }
        let applied = match step.record {
            ServerReplayRecordDto::Player {
                actor_player_id,
                command,
            } => apply_player_command_dto(
                world.clone(),
                PlayerCommandServerRequestDto {
                    api_version: request.api_version,
                    authenticated_actor_player_id: actor_player_id,
                    command,
                    initial_event_offset: result.final_event_offset,
                    map_hash: request.map_hash.clone(),
                    ruleset_hash: request.ruleset_hash.clone(),
                    state: result.state,
                },
            )?,
            ServerReplayRecordDto::System { command } => apply_system_command_dto(
                world.clone(),
                SystemCommandServerRequestDto {
                    api_version: request.api_version,
                    command,
                    initial_event_offset: result.final_event_offset,
                    map_hash: request.map_hash.clone(),
                    ruleset_hash: request.ruleset_hash.clone(),
                    state: result.state,
                },
            )?,
        };
        if applied.rejection.is_some()
            || applied.stamp.revision != step.revision
            || applied.stamp.state_digest != step.state_digest
            || applied.initial_event_offset != step.initial_event_offset
            || applied.final_event_offset != step.final_event_offset
        {
            return Err(ServerBoundaryError::ReplayMismatch);
        }
        let recipient = applied
            .recipients
            .into_iter()
            .find(|recipient| recipient.recipient_player_id == result.recipient_player_id)
            .ok_or(ServerBoundaryError::ReplayMismatch)?;
        result.state = applied.state;
        result.snapshot = recipient.snapshot;
        result.final_event_offset = applied.final_event_offset;
        result.command = Some(ClientCommandResultDto {
            stamp: applied.stamp.clone(),
            outcome: ClientCommandOutcomeDto::Accepted,
            events: recipient.events,
            evidence: recipient.evidence,
            view_patch: recipient.patch,
        });
        result.stamp = applied.stamp;
    }
    Ok(result)
}
