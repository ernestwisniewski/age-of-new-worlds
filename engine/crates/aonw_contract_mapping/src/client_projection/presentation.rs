use crate::encode_improvement;
use aonw_contracts::client::{PendingActionViewDto, PlayerTurnLifecycleViewDto};
use aonw_domain::PlayerTurnState;

use aonw_projection::{PendingActionView, PlayerTurnLifecycleView};

use super::coordinate;

/// Maps a recipient-safe pending action to the strict current client DTO.
#[must_use]
pub fn encode_pending_action(value: &PendingActionView) -> PendingActionViewDto {
    match value {
        PendingActionView::ResearchSelection => PendingActionViewDto::ResearchSelection,
        PendingActionView::CityWorkedHexSelection { city_id } => {
            PendingActionViewDto::CityWorkedHexSelection {
                city_id: city_id.as_str().to_owned(),
            }
        }
        PendingActionView::CityExpansionSelection { city_id } => {
            PendingActionViewDto::CityExpansionSelection {
                city_id: city_id.as_str().to_owned(),
            }
        }
        PendingActionView::WorkerActionSelection {
            unit_id,
            improvement,
        } => PendingActionViewDto::WorkerActionSelection {
            unit_id: unit_id.as_str().to_owned(),
            improvement: (*improvement).map(encode_improvement),
        },
        PendingActionView::MerchantTradeRouteSelection { unit_id } => {
            PendingActionViewDto::MerchantTradeRouteSelection {
                unit_id: unit_id.as_str().to_owned(),
            }
        }
        PendingActionView::MerchantMoveToCitySelection { unit_id } => {
            PendingActionViewDto::MerchantMoveToCitySelection {
                unit_id: unit_id.as_str().to_owned(),
            }
        }
        PendingActionView::UnitTurnSkip {
            unit_id,
            restore_movement_units,
        } => PendingActionViewDto::UnitTurnSkip {
            unit_id: unit_id.as_str().to_owned(),
            restore_movement_units: *restore_movement_units,
        },
        PendingActionView::AttackTargeting { unit_id, defender } => {
            PendingActionViewDto::AttackTargeting {
                unit_id: unit_id.as_str().to_owned(),
                defender: (*defender).map(coordinate),
            }
        }
        PendingActionView::CommanderMergeSelection { unit_id } => {
            PendingActionViewDto::CommanderMergeSelection {
                unit_id: unit_id.as_str().to_owned(),
            }
        }
    }
}

/// Maps recipient-safe turn lifecycle state to the strict current client DTO.
#[must_use]
pub fn encode_turn_lifecycle(value: PlayerTurnLifecycleView) -> PlayerTurnLifecycleViewDto {
    PlayerTurnLifecycleViewDto {
        own_state: value.own_state().map(|state| match state {
            PlayerTurnState::Active => aonw_contracts::PlayerTurnStateDto::Active,
            PlayerTurnState::Finished => aonw_contracts::PlayerTurnStateDto::Finished,
        }),
        own_submitted: value.own_submitted(),
        required_submission_count: value.required_submission_count(),
        submitted_count: value.submitted_count(),
    }
}
