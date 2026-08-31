use crate::encode_proposal_kind;
use aonw_contracts::client::ClientEventDto;
use aonw_engine::{DiplomaticPromiseBrokenEvent, DiplomaticProposalExpiredEvent};

pub(super) fn proposal_expired(value: &DiplomaticProposalExpiredEvent) -> ClientEventDto {
    ClientEventDto::DiplomaticProposalExpired {
        proposal_id: value.proposal_id().to_owned(),
        from_player_id: value.from_player_id().as_str().to_owned(),
        to_player_id: value.to_player_id().as_str().to_owned(),
        kind: encode_proposal_kind(value.kind()),
    }
}

pub(super) fn promise_broken(value: &DiplomaticPromiseBrokenEvent) -> ClientEventDto {
    ClientEventDto::DiplomaticPromiseBroken {
        message_id: value.message_id().to_owned(),
        player_a_id: value.player_a_id().as_str().to_owned(),
        player_b_id: value.player_b_id().as_str().to_owned(),
        delta: value.delta(),
        score_after: value.score_after(),
    }
}
