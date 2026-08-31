use aonw_contract_mapping::{
    encode_message_response, encode_message_topic, encode_proposal_kind, encode_resource,
};
use aonw_contracts::{ReplayCommandDto, ReplayRecordDto};
use aonw_domain::{
    DiplomaticMessageResponse, DiplomaticMessageTopic, DiplomaticProposalKind, PlayerId,
    ResourceType,
};
use aonw_engine::{
    DeclareWarCommand, OpenResourceExchangeCommand, OpenResourceTradeCommand, PlayerCommand,
    RespondDiplomaticMessageCommand, RespondDiplomaticProposalCommand,
    SendDiplomaticMessageCommand, SendDiplomaticProposalCommand, SendGoldGiftCommand,
};

use super::{CommandResult, dispatch_player};
use crate::RuntimeError;
use crate::session::Session;

/// Current authenticated proposal command.
#[derive(Clone, Debug, Eq, Hash, PartialEq)]
pub enum DiplomacyRequest {
    /// Declares war on one discovered participant.
    DeclareWar {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Discovered bilateral target.
        target_player_id: PlayerId,
    },
    /// Transfers a gold gift to one discovered participant.
    SendGoldGift {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Discovered bilateral target.
        target_player_id: PlayerId,
        /// Requested transfer amount.
        amount: i64,
    },
    /// Opens one resource-for-gold agreement.
    OpenResourceTrade {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Discovered exporter.
        target_player_id: PlayerId,
        /// Strategic resource delivered by the exporter.
        resource: ResourceType,
        /// Gold paid by the actor on each settlement.
        gold_per_turn: i64,
        /// Positive agreement duration.
        duration_turns: i64,
        /// Optional deterministic agreement identity.
        agreement_id: Option<String>,
    },
    /// Opens one atomic two-resource exchange.
    OpenResourceExchange {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Discovered exchange counterparty.
        target_player_id: PlayerId,
        /// Strategic resource exported by the actor.
        offered_resource: ResourceType,
        /// Strategic resource exported by the counterparty.
        requested_resource: ResourceType,
        /// Positive agreement duration.
        duration_turns: i64,
        /// Optional deterministic exchange-group identity.
        agreement_id: Option<String>,
    },
    /// Sends one friendship or truce proposal.
    Send {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Discovered bilateral target.
        target_player_id: PlayerId,
        /// Friendship or truce.
        kind: DiplomaticProposalKind,
        /// Optional proposal identity; omission selects an engine-generated identity.
        proposal_id: Option<String>,
        /// Requested truce payment.
        gold_payment: i64,
    },
    /// Accepts or rejects one proposal addressed to the actor.
    Respond {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Existing proposal identity.
        proposal_id: String,
        /// Recipient decision.
        accepted: bool,
    },
    /// Sends one private bilateral message.
    SendMessage {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Discovered bilateral target.
        target_player_id: PlayerId,
        /// Current message topic.
        topic: DiplomaticMessageTopic,
        /// Optional deterministic identity.
        message_id: Option<String>,
    },
    /// Responds to one recipient-owned message.
    RespondMessage {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Existing message identity.
        message_id: String,
        /// Selected response tone.
        response: DiplomaticMessageResponse,
    },
}

pub(crate) fn dispatch_diplomacy(
    session: &mut Session,
    command: &DiplomacyRequest,
) -> Result<CommandResult, RuntimeError> {
    match command {
        DiplomacyRequest::DeclareWar {
            expected_revision,
            target_player_id,
        } => dispatch_declare_war(session, *expected_revision, target_player_id),
        DiplomacyRequest::SendGoldGift {
            expected_revision,
            target_player_id,
            amount,
        } => dispatch_gold_gift(session, *expected_revision, target_player_id, *amount),
        DiplomacyRequest::OpenResourceTrade {
            expected_revision,
            target_player_id,
            resource,
            gold_per_turn,
            duration_turns,
            agreement_id,
        } => dispatch_resource_trade(
            session,
            *expected_revision,
            target_player_id,
            *resource,
            *gold_per_turn,
            *duration_turns,
            agreement_id.as_deref(),
        ),
        DiplomacyRequest::OpenResourceExchange {
            expected_revision,
            target_player_id,
            offered_resource,
            requested_resource,
            duration_turns,
            agreement_id,
        } => dispatch_resource_exchange(
            session,
            *expected_revision,
            target_player_id,
            *offered_resource,
            *requested_resource,
            *duration_turns,
            agreement_id.as_deref(),
        ),
        DiplomacyRequest::Send {
            expected_revision,
            target_player_id,
            kind,
            proposal_id,
            gold_payment,
        } => dispatch_proposal(
            session,
            *expected_revision,
            target_player_id,
            *kind,
            proposal_id.as_deref(),
            *gold_payment,
        ),
        DiplomacyRequest::Respond {
            expected_revision,
            proposal_id,
            accepted,
        } => dispatch_proposal_response(session, *expected_revision, proposal_id, *accepted),
        DiplomacyRequest::SendMessage {
            expected_revision,
            target_player_id,
            topic,
            message_id,
        } => dispatch_message(
            session,
            *expected_revision,
            target_player_id,
            *topic,
            message_id.as_deref(),
        ),
        DiplomacyRequest::RespondMessage {
            expected_revision,
            message_id,
            response,
        } => dispatch_message_response(session, *expected_revision, message_id, *response),
    }
}

fn dispatch_proposal(
    session: &mut Session,
    expected_revision: u64,
    target: &PlayerId,
    kind: DiplomaticProposalKind,
    proposal_id: Option<&str>,
    gold_payment: i64,
) -> Result<CommandResult, RuntimeError> {
    dispatch_player(
        session,
        PlayerCommand::SendDiplomaticProposal(SendDiplomaticProposalCommand::new(
            expected_revision,
            target,
            kind,
            proposal_id,
            gold_payment,
        )),
        ReplayRecordDto::Player {
            command: ReplayCommandDto::SendDiplomaticProposal {
                expected_revision,
                target_player_id: target.as_str().to_owned(),
                kind: encode_proposal_kind(kind),
                proposal_id: proposal_id.map(str::to_owned),
                gold_payment,
            },
        },
    )
}

fn dispatch_proposal_response(
    session: &mut Session,
    expected_revision: u64,
    proposal_id: &str,
    accepted: bool,
) -> Result<CommandResult, RuntimeError> {
    dispatch_player(
        session,
        PlayerCommand::RespondDiplomaticProposal(RespondDiplomaticProposalCommand::new(
            expected_revision,
            proposal_id,
            accepted,
        )),
        ReplayRecordDto::Player {
            command: ReplayCommandDto::RespondDiplomaticProposal {
                expected_revision,
                proposal_id: proposal_id.to_owned(),
                accepted,
            },
        },
    )
}

fn dispatch_message(
    session: &mut Session,
    expected_revision: u64,
    target: &PlayerId,
    topic: DiplomaticMessageTopic,
    message_id: Option<&str>,
) -> Result<CommandResult, RuntimeError> {
    dispatch_player(
        session,
        PlayerCommand::SendDiplomaticMessage(SendDiplomaticMessageCommand::new(
            expected_revision,
            target,
            topic,
            message_id,
        )),
        ReplayRecordDto::Player {
            command: ReplayCommandDto::SendDiplomaticMessage {
                expected_revision,
                target_player_id: target.as_str().to_owned(),
                topic: encode_message_topic(topic),
                message_id: message_id.map(str::to_owned),
            },
        },
    )
}

fn dispatch_message_response(
    session: &mut Session,
    expected_revision: u64,
    message_id: &str,
    response: DiplomaticMessageResponse,
) -> Result<CommandResult, RuntimeError> {
    dispatch_player(
        session,
        PlayerCommand::RespondDiplomaticMessage(RespondDiplomaticMessageCommand::new(
            expected_revision,
            message_id,
            response,
        )),
        ReplayRecordDto::Player {
            command: ReplayCommandDto::RespondDiplomaticMessage {
                expected_revision,
                message_id: message_id.to_owned(),
                response: encode_message_response(response),
            },
        },
    )
}

fn dispatch_resource_trade(
    session: &mut Session,
    expected_revision: u64,
    target: &PlayerId,
    resource: ResourceType,
    gold_per_turn: i64,
    duration_turns: i64,
    agreement_id: Option<&str>,
) -> Result<CommandResult, RuntimeError> {
    dispatch_player(
        session,
        PlayerCommand::OpenResourceTrade(OpenResourceTradeCommand::new(
            expected_revision,
            target,
            resource,
            gold_per_turn,
            duration_turns,
            agreement_id,
        )),
        ReplayRecordDto::Player {
            command: ReplayCommandDto::OpenResourceTrade {
                expected_revision,
                target_player_id: target.as_str().to_owned(),
                resource: encode_resource(resource),
                gold_per_turn,
                duration_turns,
                agreement_id: agreement_id.map(str::to_owned),
            },
        },
    )
}

fn dispatch_resource_exchange(
    session: &mut Session,
    expected_revision: u64,
    target: &PlayerId,
    offered_resource: ResourceType,
    requested_resource: ResourceType,
    duration_turns: i64,
    agreement_id: Option<&str>,
) -> Result<CommandResult, RuntimeError> {
    dispatch_player(
        session,
        PlayerCommand::OpenResourceExchange(OpenResourceExchangeCommand::new(
            expected_revision,
            target,
            offered_resource,
            requested_resource,
            duration_turns,
            agreement_id,
        )),
        ReplayRecordDto::Player {
            command: ReplayCommandDto::OpenResourceExchange {
                expected_revision,
                target_player_id: target.as_str().to_owned(),
                offered_resource: encode_resource(offered_resource),
                requested_resource: encode_resource(requested_resource),
                duration_turns,
                agreement_id: agreement_id.map(str::to_owned),
            },
        },
    )
}

fn dispatch_declare_war(
    session: &mut Session,
    expected_revision: u64,
    target: &PlayerId,
) -> Result<CommandResult, RuntimeError> {
    dispatch_player(
        session,
        PlayerCommand::DeclareWar(DeclareWarCommand::new(expected_revision, target)),
        ReplayRecordDto::Player {
            command: ReplayCommandDto::DeclareWar {
                expected_revision,
                target_player_id: target.as_str().to_owned(),
            },
        },
    )
}

fn dispatch_gold_gift(
    session: &mut Session,
    expected_revision: u64,
    target: &PlayerId,
    amount: i64,
) -> Result<CommandResult, RuntimeError> {
    dispatch_player(
        session,
        PlayerCommand::SendGoldGift(SendGoldGiftCommand::new(expected_revision, target, amount)),
        ReplayRecordDto::Player {
            command: ReplayCommandDto::SendGoldGift {
                expected_revision,
                target_player_id: target.as_str().to_owned(),
                amount,
            },
        },
    )
}
