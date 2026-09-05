use super::{
    ClientCommandResultDto, ClientOutcomeDto, ClientResponseBodyDto, ClientResponseDto,
    ClientSessionStampDto,
};
use crate::client::{ClientCodecError, MAX_CLIENT_OBSERVED_COMMANDS};

impl ClientResponseDto {
    pub(crate) fn validate_observation(&self) -> Result<(), ClientCodecError> {
        let ClientOutcomeDto::Success { response } = &self.outcome else {
            return Ok(());
        };
        let valid = match response.as_ref() {
            ClientResponseBodyDto::AiTurnAdvanced {
                stamp,
                executed_commands,
                commands,
                ..
            } => {
                commands.len() <= MAX_CLIENT_OBSERVED_COMMANDS
                    && u32::try_from(commands.len()) == Ok(*executed_commands)
                    && commands
                        .last()
                        .is_none_or(|command| command.stamp == *stamp)
                    && commands.iter().enumerate().all(|(index, command)| {
                        valid_frame(command, stamp)
                            && index.checked_sub(1).is_none_or(|previous| {
                                let previous = &commands[previous].stamp;
                                command.view_patch.from_revision == previous.revision
                                    && (command.stamp.revision != previous.revision
                                        || command.stamp == *previous)
                            })
                    })
            }
            ClientResponseBodyDto::ReplayFrame {
                position,
                entry_count,
                snapshot,
                command,
                ..
            } => {
                position <= entry_count
                    && command.as_ref().is_none_or(|command| {
                        *position > 0
                            && command.stamp == snapshot.stamp
                            && command.view_patch.turn == snapshot.turn
                            && command.view_patch.turn_mode == snapshot.turn_mode
                            && valid_frame(command, &snapshot.stamp)
                    })
            }
            _ => true,
        };
        if valid {
            Ok(())
        } else {
            Err(ClientCodecError::InvalidObservation)
        }
    }
}

fn valid_frame(command: &ClientCommandResultDto, final_stamp: &ClientSessionStampDto) -> bool {
    let patch = &command.view_patch;
    command.stamp.revision == patch.to_revision
        && matches!(
            patch.to_revision.checked_sub(patch.from_revision),
            Some(0 | 1)
        )
        && command.stamp.map_hash == final_stamp.map_hash
        && command.stamp.ruleset_hash == final_stamp.ruleset_hash
}
