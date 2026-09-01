use aonw_contracts::ReplayEventDto;
use aonw_engine::{PlayerKickedEvent, PlayerResignedEvent, PlayerTimedOutEvent};

pub(super) fn timed_out(event: &PlayerTimedOutEvent) -> ReplayEventDto {
    ReplayEventDto::PlayerTimedOut {
        turn: event.turn(),
        player_id: event.player_id().as_str().to_owned(),
    }
}

pub(super) fn kicked(event: &PlayerKickedEvent) -> ReplayEventDto {
    ReplayEventDto::PlayerKicked {
        turn: event.turn(),
        player_id: event.player_id().as_str().to_owned(),
        reason: event.reason().to_owned(),
        timeout_streak: event.timeout_streak(),
    }
}

pub(super) fn resigned(event: &PlayerResignedEvent) -> ReplayEventDto {
    ReplayEventDto::PlayerResigned {
        turn: event.turn(),
        player_id: event.player_id().as_str().to_owned(),
    }
}
