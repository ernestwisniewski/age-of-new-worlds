use aonw_contracts::client::ClientCommandDto;
use aonw_engine::{
    DeclareWarCommand, OpenResourceExchangeCommand, OpenResourceTradeCommand, PlayerCommand,
    RespondDiplomaticMessageCommand, RespondDiplomaticProposalCommand,
    SendDiplomaticMessageCommand, SendDiplomaticProposalCommand, SendGoldGiftCommand,
};

use super::{PlayerCommandMappingError, value};

#[allow(clippy::too_many_lines)]
pub(super) fn decode<R>(
    command: ClientCommandDto,
    apply: impl for<'command> FnOnce(PlayerCommand<'command>) -> R,
) -> Result<R, PlayerCommandMappingError> {
    match command {
        ClientCommandDto::DeclareWar {
            expected_revision,
            target_player_id,
        } => {
            let target = value::player_id(target_player_id)?;
            Ok(apply(PlayerCommand::DeclareWar(DeclareWarCommand::new(
                expected_revision,
                &target,
            ))))
        }
        ClientCommandDto::SendGoldGift {
            expected_revision,
            target_player_id,
            amount,
        } => {
            let target = value::player_id(target_player_id)?;
            Ok(apply(PlayerCommand::SendGoldGift(
                SendGoldGiftCommand::new(expected_revision, &target, amount),
            )))
        }
        ClientCommandDto::OpenResourceTrade {
            expected_revision,
            target_player_id,
            resource,
            gold_per_turn,
            duration_turns,
            agreement_id,
        } => {
            let target = value::player_id(target_player_id)?;
            Ok(apply(PlayerCommand::OpenResourceTrade(
                OpenResourceTradeCommand::new(
                    expected_revision,
                    &target,
                    crate::decode_resource(resource),
                    gold_per_turn,
                    duration_turns,
                    agreement_id.as_deref(),
                ),
            )))
        }
        ClientCommandDto::OpenResourceExchange {
            expected_revision,
            target_player_id,
            offered_resource,
            requested_resource,
            duration_turns,
            agreement_id,
        } => {
            let target = value::player_id(target_player_id)?;
            Ok(apply(PlayerCommand::OpenResourceExchange(
                OpenResourceExchangeCommand::new(
                    expected_revision,
                    &target,
                    crate::decode_resource(offered_resource),
                    crate::decode_resource(requested_resource),
                    duration_turns,
                    agreement_id.as_deref(),
                ),
            )))
        }
        ClientCommandDto::SendDiplomaticProposal {
            expected_revision,
            target_player_id,
            kind,
            proposal_id,
            gold_payment,
        } => {
            let target = value::player_id(target_player_id)?;
            Ok(apply(PlayerCommand::SendDiplomaticProposal(
                SendDiplomaticProposalCommand::new(
                    expected_revision,
                    &target,
                    crate::decode_proposal_kind(kind),
                    proposal_id.as_deref(),
                    gold_payment,
                ),
            )))
        }
        ClientCommandDto::RespondDiplomaticProposal {
            expected_revision,
            proposal_id,
            accepted,
        } => Ok(apply(PlayerCommand::RespondDiplomaticProposal(
            RespondDiplomaticProposalCommand::new(expected_revision, &proposal_id, accepted),
        ))),
        ClientCommandDto::SendDiplomaticMessage {
            expected_revision,
            target_player_id,
            topic,
            message_id,
        } => {
            let target = value::player_id(target_player_id)?;
            Ok(apply(PlayerCommand::SendDiplomaticMessage(
                SendDiplomaticMessageCommand::new(
                    expected_revision,
                    &target,
                    crate::decode_message_topic(topic),
                    message_id.as_deref(),
                ),
            )))
        }
        ClientCommandDto::RespondDiplomaticMessage {
            expected_revision,
            message_id,
            response,
        } => Ok(apply(PlayerCommand::RespondDiplomaticMessage(
            RespondDiplomaticMessageCommand::new(
                expected_revision,
                &message_id,
                crate::decode_message_response(response),
            ),
        ))),
        _ => unreachable!("diplomacy decoder receives only diplomacy commands"),
    }
}
