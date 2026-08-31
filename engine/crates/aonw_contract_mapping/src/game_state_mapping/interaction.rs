use aonw_contracts::{
    CityFoundingDraftDto, InteractionStateDto, MAX_MOVEMENT_BALANCE_UNITS, PendingInteractionDto,
};
use aonw_domain::{
    CityFoundingDraft, CityId, InteractionState, MovementUnits, PendingInteraction, PlayerId,
    UnitId,
};

use super::error::GameStateMappingError;
use super::value::{decode_coordinate, decode_improvement, encode_coordinate, encode_improvement};

pub(super) fn decode_interaction(
    dto: InteractionStateDto,
) -> Result<InteractionState, GameStateMappingError> {
    let draft = dto
        .city_founding_draft
        .map(decode_city_founding_draft)
        .transpose()?;
    let pending = dto.pending.map(decode_pending).transpose()?;
    Ok(InteractionState::new(draft, pending))
}

pub(super) fn encode_interaction(interaction: &InteractionState) -> InteractionStateDto {
    InteractionStateDto {
        city_founding_draft: interaction
            .city_founding_draft()
            .map(|draft| CityFoundingDraftDto {
                unit_id: draft.unit_id().as_str().to_owned(),
                owner_player_id: draft.owner_player_id().as_str().to_owned(),
                center: encode_coordinate(draft.center()),
                controlled_hexes: draft
                    .controlled_hexes()
                    .iter()
                    .copied()
                    .map(encode_coordinate)
                    .collect(),
            }),
        pending: interaction.pending().map(encode_pending),
    }
}

fn decode_city_founding_draft(
    dto: CityFoundingDraftDto,
) -> Result<CityFoundingDraft, GameStateMappingError> {
    Ok(CityFoundingDraft::new(
        decode_unit_id("$.interaction.cityFoundingDraft.unitId", dto.unit_id)?,
        decode_player_id(
            "$.interaction.cityFoundingDraft.ownerPlayerId",
            dto.owner_player_id,
        )?,
        decode_coordinate(dto.center),
        dto.controlled_hexes.into_iter().map(decode_coordinate),
    ))
}

fn decode_pending(dto: PendingInteractionDto) -> Result<PendingInteraction, GameStateMappingError> {
    let root = "$.interaction.pending";
    Ok(match dto {
        PendingInteractionDto::ResearchSelection { owner_player_id } => {
            PendingInteraction::ResearchSelection {
                owner_player_id: decode_player_id(
                    &format!("{root}.ownerPlayerId"),
                    owner_player_id,
                )?,
            }
        }
        PendingInteractionDto::CityWorkedHexSelection {
            owner_player_id,
            city_id,
        } => PendingInteraction::CityWorkedHexSelection {
            owner_player_id: decode_player_id(&format!("{root}.ownerPlayerId"), owner_player_id)?,
            city_id: decode_city_id(&format!("{root}.cityId"), city_id)?,
        },
        PendingInteractionDto::CityExpansionSelection {
            owner_player_id,
            city_id,
        } => PendingInteraction::CityExpansionSelection {
            owner_player_id: decode_player_id(&format!("{root}.ownerPlayerId"), owner_player_id)?,
            city_id: decode_city_id(&format!("{root}.cityId"), city_id)?,
        },
        PendingInteractionDto::WorkerActionSelection {
            owner_player_id,
            unit_id,
            improvement,
        } => PendingInteraction::WorkerActionSelection {
            owner_player_id: decode_player_id(&format!("{root}.ownerPlayerId"), owner_player_id)?,
            unit_id: decode_unit_id(&format!("{root}.unitId"), unit_id)?,
            improvement: improvement.map(decode_improvement),
        },
        PendingInteractionDto::MerchantTradeRouteSelection {
            owner_player_id,
            unit_id,
        } => PendingInteraction::MerchantTradeRouteSelection {
            owner_player_id: decode_player_id(&format!("{root}.ownerPlayerId"), owner_player_id)?,
            unit_id: decode_unit_id(&format!("{root}.unitId"), unit_id)?,
        },
        PendingInteractionDto::MerchantMoveToCitySelection {
            owner_player_id,
            unit_id,
        } => PendingInteraction::MerchantMoveToCitySelection {
            owner_player_id: decode_player_id(&format!("{root}.ownerPlayerId"), owner_player_id)?,
            unit_id: decode_unit_id(&format!("{root}.unitId"), unit_id)?,
        },
        PendingInteractionDto::UnitTurnSkip {
            owner_player_id,
            unit_id,
            restore_movement_units,
        } => {
            if restore_movement_units > MAX_MOVEMENT_BALANCE_UNITS {
                return Err(GameStateMappingError::new(
                    format!("{root}.restoreMovementUnits"),
                    format!("exceeds {MAX_MOVEMENT_BALANCE_UNITS}"),
                ));
            }
            PendingInteraction::UnitTurnSkip {
                owner_player_id: decode_player_id(
                    &format!("{root}.ownerPlayerId"),
                    owner_player_id,
                )?,
                unit_id: decode_unit_id(&format!("{root}.unitId"), unit_id)?,
                restore_movement: MovementUnits::new(restore_movement_units),
            }
        }
        PendingInteractionDto::AttackTargeting {
            owner_player_id,
            unit_id,
            defender,
        } => PendingInteraction::AttackTargeting {
            owner_player_id: decode_player_id(&format!("{root}.ownerPlayerId"), owner_player_id)?,
            unit_id: decode_unit_id(&format!("{root}.unitId"), unit_id)?,
            defender: defender.map(decode_coordinate),
        },
        PendingInteractionDto::CommanderMergeSelection {
            owner_player_id,
            unit_id,
        } => PendingInteraction::CommanderMergeSelection {
            owner_player_id: decode_player_id(&format!("{root}.ownerPlayerId"), owner_player_id)?,
            unit_id: decode_unit_id(&format!("{root}.unitId"), unit_id)?,
        },
    })
}

fn encode_pending(pending: &PendingInteraction) -> PendingInteractionDto {
    let owner_player_id = || pending.owner_player_id().as_str().to_owned();
    let unit_id = || {
        pending
            .unit_id()
            .expect("unit interaction has unit id")
            .as_str()
            .to_owned()
    };
    match pending {
        PendingInteraction::ResearchSelection { .. } => PendingInteractionDto::ResearchSelection {
            owner_player_id: owner_player_id(),
        },
        PendingInteraction::CityWorkedHexSelection { city_id, .. } => {
            PendingInteractionDto::CityWorkedHexSelection {
                owner_player_id: owner_player_id(),
                city_id: city_id.as_str().to_owned(),
            }
        }
        PendingInteraction::CityExpansionSelection { city_id, .. } => {
            PendingInteractionDto::CityExpansionSelection {
                owner_player_id: owner_player_id(),
                city_id: city_id.as_str().to_owned(),
            }
        }
        PendingInteraction::WorkerActionSelection { improvement, .. } => {
            PendingInteractionDto::WorkerActionSelection {
                owner_player_id: owner_player_id(),
                unit_id: unit_id(),
                improvement: improvement.map(encode_improvement),
            }
        }
        PendingInteraction::MerchantTradeRouteSelection { .. } => {
            PendingInteractionDto::MerchantTradeRouteSelection {
                owner_player_id: owner_player_id(),
                unit_id: unit_id(),
            }
        }
        PendingInteraction::MerchantMoveToCitySelection { .. } => {
            PendingInteractionDto::MerchantMoveToCitySelection {
                owner_player_id: owner_player_id(),
                unit_id: unit_id(),
            }
        }
        PendingInteraction::UnitTurnSkip {
            restore_movement, ..
        } => PendingInteractionDto::UnitTurnSkip {
            owner_player_id: owner_player_id(),
            unit_id: unit_id(),
            restore_movement_units: restore_movement.get(),
        },
        PendingInteraction::AttackTargeting { defender, .. } => {
            PendingInteractionDto::AttackTargeting {
                owner_player_id: owner_player_id(),
                unit_id: unit_id(),
                defender: defender.map(encode_coordinate),
            }
        }
        PendingInteraction::CommanderMergeSelection { .. } => {
            PendingInteractionDto::CommanderMergeSelection {
                owner_player_id: owner_player_id(),
                unit_id: unit_id(),
            }
        }
    }
}

fn decode_player_id(path: &str, value: String) -> Result<PlayerId, GameStateMappingError> {
    PlayerId::new(value).map_err(|error| GameStateMappingError::new(path, error.to_string()))
}

fn decode_unit_id(path: &str, value: String) -> Result<UnitId, GameStateMappingError> {
    UnitId::new(value).map_err(|error| GameStateMappingError::new(path, error.to_string()))
}

fn decode_city_id(path: &str, value: String) -> Result<CityId, GameStateMappingError> {
    CityId::new(value).map_err(|error| GameStateMappingError::new(path, error.to_string()))
}
