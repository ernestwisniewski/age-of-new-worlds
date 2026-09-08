use core::num::NonZeroU32;

use crate::{AiRuntimeProfile, AiTurnDriver, LocalRuntime, MAX_AI_TURN_COMMAND_BUDGET};
use aonw_contracts::client::{ClientAiRuntimeProfileDto, ClientResponseBodyDto, ClientResponseDto};

use super::{encode, failure, success};

pub(super) fn dispatch_ai_turn(
    runtime: &mut LocalRuntime,
    actor_player_id: String,
    command_budget: u32,
    runtime_profile: ClientAiRuntimeProfileDto,
    ai_driver: Option<&mut dyn AiTurnDriver>,
) -> ClientResponseDto {
    let Some(driver) = ai_driver else {
        return failure(
            "ai_driver_unavailable",
            "this protocol dispatcher has no AI driver",
        );
    };
    let Some(command_budget) = NonZeroU32::new(command_budget) else {
        return failure(
            "invalid_ai_command_budget",
            "command budget must be positive",
        );
    };
    if command_budget.get() > MAX_AI_TURN_COMMAND_BUDGET {
        return failure(
            "invalid_ai_command_budget",
            format!("command budget must not exceed {MAX_AI_TURN_COMMAND_BUDGET}"),
        );
    }
    match aonw_domain::PlayerId::new(actor_player_id) {
        Ok(actor) => {
            let response_actor = actor.as_str().to_owned();
            match runtime.advance_ai_turn_observed(
                actor,
                command_budget,
                match runtime_profile {
                    ClientAiRuntimeProfileDto::Standard => AiRuntimeProfile::Standard,
                    ClientAiRuntimeProfileDto::BatterySaver => AiRuntimeProfile::BatterySaver,
                },
                driver,
            ) {
                Ok(observed) => success(ClientResponseBodyDto::AiTurnAdvanced {
                    stamp: encode::stamp(observed.execution.stamp),
                    actor_player_id: response_actor,
                    recipient_player_id: observed.recipient_player_id.as_str().to_owned(),
                    executed_commands: observed.execution.executed_commands,
                    completed_turn: observed.execution.completed_turn,
                    commands: observed
                        .commands
                        .iter()
                        .map(encode::command_result)
                        .collect(),
                }),
                Err(error) => failure("ai_turn_failed", error),
            }
        }
        Err(error) => failure("invalid_actor_player_id", error),
    }
}
