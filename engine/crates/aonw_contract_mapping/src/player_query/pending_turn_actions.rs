use aonw_contracts::CoordinateDto;
use aonw_contracts::client::{ClientQueryResultDto, PendingTurnActionDto};
use aonw_engine::{PendingTurnAction, PendingTurnActions};
use aonw_projection::SessionStamp;

/// Encodes actor-owned turn work without changing its authoritative order.
#[must_use]
pub fn encode_pending_turn_actions(
    stamp: SessionStamp,
    value: &PendingTurnActions,
) -> ClientQueryResultDto {
    ClientQueryResultDto::PendingTurnActions {
        stamp: crate::encode_client_stamp(stamp),
        can_activate: value.can_activate,
        actions: value
            .actions
            .iter()
            .map(|action| match action {
                PendingTurnAction::Unit {
                    unit_id,
                    coordinate,
                } => PendingTurnActionDto::Unit {
                    unit_id: unit_id.as_str().to_owned(),
                    coordinate: CoordinateDto {
                        col: coordinate.col(),
                        row: coordinate.row(),
                    },
                },
                PendingTurnAction::CityProduction {
                    city_id,
                    coordinate,
                } => PendingTurnActionDto::CityProduction {
                    city_id: city_id.as_str().to_owned(),
                    coordinate: CoordinateDto {
                        col: coordinate.col(),
                        row: coordinate.row(),
                    },
                },
                PendingTurnAction::Research => PendingTurnActionDto::Research {},
            })
            .collect(),
    }
}
