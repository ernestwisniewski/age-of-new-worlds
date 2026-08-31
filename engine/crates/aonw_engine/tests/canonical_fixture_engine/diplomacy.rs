use aonw_contract_mapping::{
    decode_message_response, decode_message_topic, decode_proposal_kind, decode_resource,
};
use aonw_contracts::ReplayCommandDto;
use aonw_domain::PlayerId;
use aonw_engine::{
    DeclareWarCommand, DomainTransition, EngineContext, GameEngine, OpenResourceExchangeCommand,
    OpenResourceTradeCommand, PlayerCommand, RespondDiplomaticMessageCommand,
    RespondDiplomaticProposalCommand, SendDiplomaticMessageCommand, SendDiplomaticProposalCommand,
    SendGoldGiftCommand,
};

use super::{ExecutionError, display_error};

pub(super) fn apply(
    state: aonw_domain::GameState,
    context: EngineContext<'_>,
    command: &ReplayCommandDto,
) -> Result<DomainTransition, ExecutionError> {
    if matches!(
        command,
        ReplayCommandDto::DeclareWar { .. }
            | ReplayCommandDto::SendGoldGift { .. }
            | ReplayCommandDto::OpenResourceTrade { .. }
            | ReplayCommandDto::OpenResourceExchange { .. }
    ) {
        return apply_bilateral_economy(state, context, command);
    }
    apply_conversation(state, context, command)
}

fn apply_bilateral_economy(
    state: aonw_domain::GameState,
    context: EngineContext<'_>,
    command: &ReplayCommandDto,
) -> Result<DomainTransition, ExecutionError> {
    match command {
        ReplayCommandDto::DeclareWar {
            expected_revision,
            target_player_id,
        } => {
            let target = PlayerId::new(target_player_id.as_str()).map_err(display_error)?;
            GameEngine::apply_player_owned(
                state,
                context,
                PlayerCommand::DeclareWar(DeclareWarCommand::new(*expected_revision, &target)),
            )
            .map_err(display_error)
        }
        ReplayCommandDto::SendGoldGift {
            expected_revision,
            target_player_id,
            amount,
        } => {
            let target = PlayerId::new(target_player_id.as_str()).map_err(display_error)?;
            GameEngine::apply_player_owned(
                state,
                context,
                PlayerCommand::SendGoldGift(SendGoldGiftCommand::new(
                    *expected_revision,
                    &target,
                    *amount,
                )),
            )
            .map_err(display_error)
        }
        ReplayCommandDto::OpenResourceTrade {
            expected_revision,
            target_player_id,
            resource,
            gold_per_turn,
            duration_turns,
            agreement_id,
        } => {
            let target = PlayerId::new(target_player_id.as_str()).map_err(display_error)?;
            GameEngine::apply_player_owned(
                state,
                context,
                PlayerCommand::OpenResourceTrade(OpenResourceTradeCommand::new(
                    *expected_revision,
                    &target,
                    decode_resource(*resource),
                    *gold_per_turn,
                    *duration_turns,
                    agreement_id.as_deref(),
                )),
            )
            .map_err(display_error)
        }
        ReplayCommandDto::OpenResourceExchange {
            expected_revision,
            target_player_id,
            offered_resource,
            requested_resource,
            duration_turns,
            agreement_id,
        } => {
            let target = PlayerId::new(target_player_id.as_str()).map_err(display_error)?;
            GameEngine::apply_player_owned(
                state,
                context,
                PlayerCommand::OpenResourceExchange(OpenResourceExchangeCommand::new(
                    *expected_revision,
                    &target,
                    decode_resource(*offered_resource),
                    decode_resource(*requested_resource),
                    *duration_turns,
                    agreement_id.as_deref(),
                )),
            )
            .map_err(display_error)
        }
        _ => Err(ExecutionError("unsupported diplomacy command".to_owned())),
    }
}

fn apply_conversation(
    state: aonw_domain::GameState,
    context: EngineContext<'_>,
    command: &ReplayCommandDto,
) -> Result<DomainTransition, ExecutionError> {
    match command {
        ReplayCommandDto::SendDiplomaticProposal {
            expected_revision,
            target_player_id,
            kind,
            proposal_id,
            gold_payment,
        } => {
            let target = PlayerId::new(target_player_id.as_str()).map_err(display_error)?;
            GameEngine::apply_player_owned(
                state,
                context,
                PlayerCommand::SendDiplomaticProposal(SendDiplomaticProposalCommand::new(
                    *expected_revision,
                    &target,
                    decode_proposal_kind(*kind),
                    proposal_id.as_deref(),
                    *gold_payment,
                )),
            )
            .map_err(display_error)
        }
        ReplayCommandDto::RespondDiplomaticProposal {
            expected_revision,
            proposal_id,
            accepted,
        } => GameEngine::apply_player_owned(
            state,
            context,
            PlayerCommand::RespondDiplomaticProposal(RespondDiplomaticProposalCommand::new(
                *expected_revision,
                proposal_id,
                *accepted,
            )),
        )
        .map_err(display_error),
        ReplayCommandDto::SendDiplomaticMessage {
            expected_revision,
            target_player_id,
            topic,
            message_id,
        } => {
            let target = PlayerId::new(target_player_id.as_str()).map_err(display_error)?;
            GameEngine::apply_player_owned(
                state,
                context,
                PlayerCommand::SendDiplomaticMessage(SendDiplomaticMessageCommand::new(
                    *expected_revision,
                    &target,
                    decode_message_topic(*topic),
                    message_id.as_deref(),
                )),
            )
            .map_err(display_error)
        }
        ReplayCommandDto::RespondDiplomaticMessage {
            expected_revision,
            message_id,
            response,
        } => GameEngine::apply_player_owned(
            state,
            context,
            PlayerCommand::RespondDiplomaticMessage(RespondDiplomaticMessageCommand::new(
                *expected_revision,
                message_id,
                decode_message_response(*response),
            )),
        )
        .map_err(display_error),
        _ => Err(ExecutionError("unsupported diplomacy command".to_owned())),
    }
}
