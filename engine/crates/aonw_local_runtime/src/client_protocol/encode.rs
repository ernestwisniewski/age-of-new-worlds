use aonw_contract_mapping::{
    encode_client_event, encode_command_rejection, encode_player_view_patch,
    encode_recipient_evidence,
};
use aonw_contracts::client::{ClientCommandOutcomeDto, ClientCommandResultDto};

use crate::CommandResult;

mod capability;
mod map_view;
mod query;
mod research;
mod simple;
#[cfg(test)]
mod tests;

pub(super) use aonw_contract_mapping::{
    encode_client_stamp as stamp, encode_player_view_snapshot as snapshot,
};
pub(super) use capability::capabilities;
pub(super) use map_view::map;
#[cfg(test)]
use map_view::{objective_type, resource, terrain};
pub(super) use query::query_result;
#[cfg(test)]
use query::{merchant_destination, movement_metrics};
pub(super) use simple::replay_verification;

pub(crate) fn command_result(value: &CommandResult) -> ClientCommandResultDto {
    ClientCommandResultDto {
        stamp: stamp(value.stamp),
        outcome: value
            .rejection
            .map_or(ClientCommandOutcomeDto::Accepted, |code| {
                ClientCommandOutcomeDto::Rejected {
                    code: encode_command_rejection(code),
                }
            }),
        events: value
            .events
            .iter()
            .filter(|event| value.recipient_disclosure.allows_event(event))
            .map(encode_client_event)
            .collect(),
        evidence: value
            .evidence
            .as_ref()
            .and_then(|evidence| encode_recipient_evidence(evidence, &value.recipient_disclosure)),
        view_patch: encode_player_view_patch(&value.view_patch),
    }
}
