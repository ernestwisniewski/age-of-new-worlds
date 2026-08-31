mod error;
mod message;
mod model;
mod proposal;
mod resource_trade;
pub(crate) mod support;
mod war_gift;

pub use error::DiplomacyError;
pub use model::{
    DeclareWarCommand, OpenResourceExchangeCommand, OpenResourceTradeCommand,
    RespondDiplomaticMessageCommand, RespondDiplomaticProposalCommand,
    SendDiplomaticMessageCommand, SendDiplomaticProposalCommand, SendGoldGiftCommand,
};

pub(crate) use message::{apply_respond_message, apply_send_message};
pub(crate) use model::DiplomacyMutation;
pub(crate) use proposal::{apply_respond_proposal, apply_send_proposal};
pub(crate) use resource_trade::{apply_open_resource_exchange, apply_open_resource_trade};
pub(crate) use war_gift::{apply_declare_war, apply_send_gold_gift};
