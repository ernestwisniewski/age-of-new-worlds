mod decode;
mod encode;

use core::num::NonZeroU32;
use std::fmt::Write as _;

use aonw_contracts::MatchIdentityDto;
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientCodecError, ClientErrorDto, ClientFogModeDto, ClientOutcomeDto,
    ClientRequestBodyDto, ClientRequestDto, ClientResponseBodyDto, ClientResponseDto,
};

use crate::{AiTurnDriver, LocalRuntime, MAX_AI_TURN_COMMAND_BUDGET, RuntimeError};
use sha2::{Digest, Sha256};

use decode::DecodedCommand;

/// Framework-neutral dispatcher for the shared Godot and Flutter client protocol.
pub struct ClientProtocol;

impl ClientProtocol {
    /// Decodes, dispatches, and encodes one strict client JSON document.
    #[must_use]
    pub fn dispatch_json(runtime: &mut LocalRuntime, input: &str) -> String {
        Self::dispatch_json_inner(runtime, input, None)
    }

    /// Decodes and executes one request with a production AI driver available.
    #[must_use]
    pub fn dispatch_json_with_ai(
        runtime: &mut LocalRuntime,
        input: &str,
        ai_driver: &mut dyn AiTurnDriver,
    ) -> String {
        Self::dispatch_json_inner(runtime, input, Some(ai_driver))
    }

    fn dispatch_json_inner(
        runtime: &mut LocalRuntime,
        input: &str,
        ai_driver: Option<&mut dyn AiTurnDriver>,
    ) -> String {
        let response = match ClientRequestDto::from_json(input) {
            Ok(request) => Self::dispatch_inner(runtime, request, ai_driver),
            Err(error @ ClientCodecError::UnsupportedVersion { .. }) => {
                failure("unsupported_client_api_version", error)
            }
            Err(error) => failure("invalid_client_request", error),
        };
        response
            .to_json()
            .unwrap_or_else(|_| serialization_failure())
    }

    /// Executes one validated current client request against a local runtime.
    #[must_use]
    pub fn dispatch(runtime: &mut LocalRuntime, request: ClientRequestDto) -> ClientResponseDto {
        Self::dispatch_inner(runtime, request, None)
    }

    fn dispatch_inner(
        runtime: &mut LocalRuntime,
        request: ClientRequestDto,
        ai_driver: Option<&mut dyn AiTurnDriver>,
    ) -> ClientResponseDto {
        if request.api_version != CLIENT_API_VERSION {
            return failure(
                "unsupported_client_api_version",
                format!(
                    "unsupported client API version {}; expected {CLIENT_API_VERSION}",
                    request.api_version
                ),
            );
        }

        if let Some(response) = request_state_failure(runtime, &request.request) {
            return response;
        }

        match request.request {
            ClientRequestBodyDto::Capabilities => success(encode::capabilities()),
            ClientRequestBodyDto::InspectMap { map_document } => {
                dispatch_inspect_map(&map_document)
            }
            ClientRequestBodyDto::OpenSession {
                map_document,
                scenario_document,
                actor_player_id,
            } => {
                dispatch_open_session(runtime, &map_document, &scenario_document, &actor_player_id)
            }
            ClientRequestBodyDto::StartMatch {
                map_document,
                scenario_document,
                actor_player_id,
                match_identity,
                fog_mode,
            } => dispatch_start_match(
                runtime,
                &map_document,
                &scenario_document,
                &actor_player_id,
                match_identity,
                fog_mode,
            ),
            ClientRequestBodyDto::CloseSession => {
                runtime.close();
                success(ClientResponseBodyDto::SessionClosed)
            }
            ClientRequestBodyDto::HandoffActor { actor_player_id } => {
                dispatch_handoff(runtime, actor_player_id)
            }
            ClientRequestBodyDto::AdvanceAiTurn {
                actor_player_id,
                command_budget,
            } => dispatch_ai_turn(runtime, actor_player_id, command_budget, ai_driver),
            ClientRequestBodyDto::Snapshot => match runtime.snapshot() {
                Ok(snapshot) => success(ClientResponseBodyDto::Snapshot {
                    snapshot: encode::snapshot(&snapshot),
                }),
                Err(error) => runtime_failure(error),
            },
            ClientRequestBodyDto::Query { query } => match decode::query(query) {
                Ok(query) => match runtime.query(&query) {
                    Ok(result) => success(ClientResponseBodyDto::Query {
                        result: encode::query_result(&result),
                    }),
                    Err(error) => runtime_failure(error),
                },
                Err(error) => error.into_response(),
            },
            ClientRequestBodyDto::Dispatch { command } => match decode::command(command) {
                Ok(command) => dispatch_command(runtime, command),
                Err(error) => error.into_response(),
            },
            persistence @ (ClientRequestBodyDto::ExportSave
            | ClientRequestBodyDto::OpenSave { .. }
            | ClientRequestBodyDto::ExportReplay
            | ClientRequestBodyDto::VerifyReplay { .. }
            | ClientRequestBodyDto::OpenReplay { .. }
            | ClientRequestBodyDto::SeekReplay { .. }) => {
                dispatch_persistence(runtime, persistence)
            }
        }
    }

    /// Encodes one adapter-level failure with the protocol envelope.
    #[must_use]
    pub fn failure_json(code: &str, message: &str) -> String {
        failure(code, message)
            .to_json()
            .unwrap_or_else(|_| serialization_failure())
    }
}

fn request_state_failure(
    runtime: &LocalRuntime,
    request: &ClientRequestBodyDto,
) -> Option<ClientResponseDto> {
    let can_recover_poisoned = matches!(
        request,
        ClientRequestBodyDto::Capabilities
            | ClientRequestBodyDto::InspectMap { .. }
            | ClientRequestBodyDto::OpenSession { .. }
            | ClientRequestBodyDto::StartMatch { .. }
            | ClientRequestBodyDto::CloseSession
            | ClientRequestBodyDto::OpenSave { .. }
            | ClientRequestBodyDto::OpenReplay { .. }
            | ClientRequestBodyDto::VerifyReplay { .. }
    );
    if runtime.is_poisoned() && !can_recover_poisoned {
        return Some(runtime_failure(RuntimeError::SessionPoisoned));
    }
    let allowed_during_replay = matches!(
        request,
        ClientRequestBodyDto::Capabilities
            | ClientRequestBodyDto::InspectMap { .. }
            | ClientRequestBodyDto::OpenSession { .. }
            | ClientRequestBodyDto::StartMatch { .. }
            | ClientRequestBodyDto::OpenSave { .. }
            | ClientRequestBodyDto::OpenReplay { .. }
            | ClientRequestBodyDto::SeekReplay { .. }
            | ClientRequestBodyDto::Snapshot
            | ClientRequestBodyDto::CloseSession
    );
    (runtime.is_replay_playback() && !allowed_during_replay).then(|| {
        failure(
            "replay_read_only",
            "replay playback accepts only snapshot, seek, open, or close operations",
        )
    })
}

fn dispatch_inspect_map(map_document: &str) -> ClientResponseDto {
    match decode::map_document(map_document) {
        Ok(document) => match encode::map(&document) {
            Ok(map) => success(ClientResponseBodyDto::MapInspected { map }),
            Err(error) => failure("map_hash_failed", error),
        },
        Err(error) => error.into_response(),
    }
}

fn dispatch_open_session(
    runtime: &mut LocalRuntime,
    map_document: &str,
    scenario_document: &str,
    actor_player_id: &str,
) -> ClientResponseDto {
    match decode::open_session(map_document, scenario_document, actor_player_id) {
        Ok(request) => match runtime.open(request) {
            Ok(stamp) => success(ClientResponseBodyDto::SessionOpened {
                stamp: encode::stamp(stamp),
            }),
            Err(error) => failure("session_open_failed", error),
        },
        Err(error) => error.into_response(),
    }
}

fn dispatch_start_match(
    runtime: &mut LocalRuntime,
    map_document: &str,
    scenario_document: &str,
    actor_player_id: &str,
    match_identity: MatchIdentityDto,
    fog_mode: ClientFogModeDto,
) -> ClientResponseDto {
    match decode::start_match(
        map_document,
        scenario_document,
        actor_player_id,
        match_identity,
        fog_mode,
    ) {
        Ok(request) => match runtime.open(request) {
            Ok(stamp) => success(ClientResponseBodyDto::SessionOpened {
                stamp: encode::stamp(stamp),
            }),
            Err(error) => failure("match_start_failed", error),
        },
        Err(error) => error.into_response(),
    }
}

fn dispatch_handoff(runtime: &mut LocalRuntime, actor_player_id: String) -> ClientResponseDto {
    match aonw_domain::PlayerId::new(actor_player_id) {
        Ok(actor) => match runtime.handoff_hot_seat_actor(actor) {
            Ok(stamp) => success(ClientResponseBodyDto::ActorHandedOff {
                stamp: encode::stamp(stamp),
            }),
            Err(error) => failure("actor_handoff_failed", error),
        },
        Err(error) => failure("invalid_actor_player_id", error),
    }
}

fn dispatch_ai_turn(
    runtime: &mut LocalRuntime,
    actor_player_id: String,
    command_budget: u32,
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
            match runtime.advance_ai_turn(actor, command_budget, driver) {
                Ok(execution) => success(ClientResponseBodyDto::AiTurnAdvanced {
                    stamp: encode::stamp(execution.stamp),
                    actor_player_id: response_actor,
                    executed_commands: execution.executed_commands,
                    completed_turn: execution.completed_turn,
                }),
                Err(error) => failure("ai_turn_failed", error),
            }
        }
        Err(error) => failure("invalid_actor_player_id", error),
    }
}

fn dispatch_open_save(
    runtime: &mut LocalRuntime,
    map_document: &str,
    save_document: &str,
) -> ClientResponseDto {
    match decode::map(map_document) {
        Ok(map) => match runtime.open_save_json(
            map,
            aonw_content::RulesetDefinition::standard().clone(),
            save_document,
        ) {
            Ok(stamp) => success(ClientResponseBodyDto::SaveOpened {
                stamp: encode::stamp(stamp),
            }),
            Err(error) => failure("save_open_failed", error),
        },
        Err(error) => error.into_response(),
    }
}

fn dispatch_persistence(
    runtime: &mut LocalRuntime,
    request: ClientRequestBodyDto,
) -> ClientResponseDto {
    match request {
        ClientRequestBodyDto::ExportSave => match runtime.export_save_json() {
            Ok(document) => success(ClientResponseBodyDto::SaveExported { document }),
            Err(error) => failure("save_export_failed", error),
        },
        ClientRequestBodyDto::OpenSave {
            map_document,
            save_document,
        } => dispatch_open_save(runtime, &map_document, &save_document),
        ClientRequestBodyDto::ExportReplay => match runtime.export_replay_json() {
            Ok(document) => success(ClientResponseBodyDto::ReplayExported { document }),
            Err(error) => failure("replay_export_failed", error),
        },
        ClientRequestBodyDto::VerifyReplay {
            map_document,
            replay_document,
        } => dispatch_verify_replay(&map_document, &replay_document),
        ClientRequestBodyDto::OpenReplay {
            map_document,
            replay_document,
            recipient_player_id,
        } => dispatch_open_replay(
            runtime,
            &map_document,
            &replay_document,
            recipient_player_id,
        ),
        ClientRequestBodyDto::SeekReplay { position } => match runtime.seek_replay(position) {
            Ok(frame) => success(ClientResponseBodyDto::ReplayFrame {
                position: frame.position,
                entry_count: frame.entry_count,
                snapshot: encode::snapshot(&frame.snapshot),
            }),
            Err(error) => failure("replay_seek_failed", error),
        },
        _ => unreachable!("only persistence requests are routed here"),
    }
}

fn dispatch_verify_replay(map_document: &str, replay_document: &str) -> ClientResponseDto {
    match decode::map(map_document) {
        Ok(map) => match LocalRuntime::verify_replay_json(
            map,
            aonw_content::RulesetDefinition::standard().clone(),
            replay_document,
        ) {
            Ok(verification) => success(ClientResponseBodyDto::ReplayVerified {
                verification: encode::replay_verification(verification),
            }),
            Err(error) => failure("replay_verification_failed", error),
        },
        Err(error) => error.into_response(),
    }
}

fn dispatch_open_replay(
    runtime: &mut LocalRuntime,
    map_document: &str,
    replay_document: &str,
    recipient_player_id: String,
) -> ClientResponseDto {
    let recipient = match aonw_domain::PlayerId::new(recipient_player_id) {
        Ok(recipient) => recipient,
        Err(error) => return failure("invalid_replay_recipient", error),
    };
    match decode::map(map_document) {
        Ok(map) => match runtime.open_replay_json(
            map,
            aonw_content::RulesetDefinition::standard().clone(),
            replay_document,
            recipient,
        ) {
            Ok(frame) => success(ClientResponseBodyDto::ReplayFrame {
                position: frame.position,
                entry_count: frame.entry_count,
                snapshot: encode::snapshot(&frame.snapshot),
            }),
            Err(error) => failure("replay_open_failed", error),
        },
        Err(error) => error.into_response(),
    }
}

pub(crate) fn recipient_result_hash(result: &crate::CommandResult) -> String {
    let encoded = serde_json::to_vec(&encode::command_result(result)).unwrap_or_default();
    let digest = Sha256::digest(encoded);
    let mut output = String::with_capacity(digest.len() * 2);
    for byte in digest {
        let _ = write!(output, "{byte:02x}");
    }
    output
}

fn serialization_failure() -> String {
    format!(
        r#"{{"apiVersion":{CLIENT_API_VERSION},"outcome":{{"status":"failure","error":{{"code":"adapter_serialization_failed","message":"adapter serialization failed"}}}}}}"#
    )
}

fn dispatch_command(runtime: &mut LocalRuntime, command: DecodedCommand) -> ClientResponseDto {
    let result = match command {
        DecodedCommand::SelectTechnology(command) => runtime.select_technology(command),
        DecodedCommand::Diplomacy(command) => runtime.diplomacy(&command),
        DecodedCommand::Artifact(command) => runtime.artifact(&command),
        DecodedCommand::FoundCity(command) => runtime.found_city(&command),
        DecodedCommand::ToggleWorkedHex(command) => runtime.toggle_worked_hex(&command),
        DecodedCommand::SelectCityExpansionHex(command) => {
            runtime.select_city_expansion_hex(&command)
        }
        DecodedCommand::Production(command) => runtime.production(&command),
        DecodedCommand::SelectWorkerImprovement(command) => {
            runtime.select_worker_improvement(&command)
        }
        DecodedCommand::ConfirmWorkerImprovement(command) => {
            runtime.confirm_worker_improvement(&command)
        }
        DecodedCommand::CancelWorkerJob(command) => runtime.cancel_worker_job(&command),
        DecodedCommand::AssignWorkerToHex(command) => runtime.assign_worker_to_hex(&command),
        DecodedCommand::CancelWorkerAssignment(command) => {
            runtime.cancel_worker_assignment(&command)
        }
        DecodedCommand::BuildRoad(command) => runtime.build_road(&command),
        DecodedCommand::AutomateWorker(command) => runtime.automate_worker(&command),
        DecodedCommand::Attack(command) => runtime.attack_hex(&command),
        DecodedCommand::Move(command) => runtime.dispatch(&command),
        DecodedCommand::AutoExplore(command) => runtime.auto_explore_unit(&command),
        DecodedCommand::AssignMerchantRoute(command) => {
            runtime.assign_merchant_trade_route(&command)
        }
        DecodedCommand::MoveMerchantToCity(command) => runtime.move_merchant_to_city(&command),
        DecodedCommand::DetachTroop(command) => runtime.detach_troop(&command),
        DecodedCommand::Cancel(command) => runtime.cancel_unit_action(&command),
        DecodedCommand::Skip(command) => runtime.skip_unit_turn(&command),
        DecodedCommand::Fortify(command) => runtime.fortify_unit(&command),
        DecodedCommand::EndTurn(command) => runtime.end_turn(command),
        DecodedCommand::SubmitTurn(command) => runtime.submit_turn(command),
    };
    match result {
        Ok(result) => success(ClientResponseBodyDto::Command {
            result: Box::new(encode::command_result(&result)),
        }),
        Err(error) => runtime_failure(error),
    }
}

fn runtime_failure(error: RuntimeError) -> ClientResponseDto {
    failure(error.code(), error)
}

fn success(response: ClientResponseBodyDto) -> ClientResponseDto {
    ClientResponseDto {
        api_version: CLIENT_API_VERSION,
        outcome: ClientOutcomeDto::Success {
            response: Box::new(response),
        },
    }
}

fn failure(code: &str, error: impl core::fmt::Display) -> ClientResponseDto {
    ClientResponseDto {
        api_version: CLIENT_API_VERSION,
        outcome: ClientOutcomeDto::Failure {
            error: ClientErrorDto {
                code: code.to_owned(),
                message: error.to_string(),
            },
        },
    }
}

pub(super) struct ClientDecodeError {
    code: &'static str,
    message: String,
}

impl ClientDecodeError {
    pub(super) fn new(code: &'static str, error: impl core::fmt::Display) -> Self {
        Self {
            code,
            message: error.to_string(),
        }
    }

    fn into_response(self) -> ClientResponseDto {
        failure(self.code, self.message)
    }
}
