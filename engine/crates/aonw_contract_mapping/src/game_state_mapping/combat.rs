use aonw_contracts::{CityConquestActionDto, IntendedAttackDto};
use aonw_domain::{
    CityConquestAction, CombatState, HexCoord, HexGridBounds, IntendedAttack, MatchIdentity,
    PlayerId, StateRevision, Unit, UnitId,
};

use super::error::GameStateMappingError;

pub(super) fn decode_combat(
    identity: &MatchIdentity,
    bounds: HexGridBounds,
    units: &[Unit],
    values: Vec<IntendedAttackDto>,
) -> Result<CombatState, GameStateMappingError> {
    let mut attacks = Vec::with_capacity(values.len());
    for (index, value) in values.into_iter().enumerate() {
        let path = format!("$.intendedAttacks[{index}]");
        let attacker = UnitId::new(value.attacker_unit_id).map_err(|error| {
            GameStateMappingError::new(format!("{path}.attackerUnitId"), error.to_string())
        })?;
        let player = PlayerId::new(value.declaring_player_id).map_err(|error| {
            GameStateMappingError::new(format!("{path}.declaringPlayerId"), error.to_string())
        })?;
        if !identity.contains(&player) {
            return Err(GameStateMappingError::new(
                format!("{path}.declaringPlayerId"),
                format!("attack references non-participant: {player}"),
            ));
        }
        let defender = HexCoord::new(value.defender_col, value.defender_row);
        if !bounds.contains(defender) {
            return Err(GameStateMappingError::new(
                format!("{path}.defenderCol"),
                "attack target is outside map bounds",
            ));
        }
        let unit = units
            .iter()
            .find(|unit| unit.id() == &attacker)
            .ok_or_else(|| {
                GameStateMappingError::new(
                    format!("{path}.attackerUnitId"),
                    format!("attack references missing unit: {attacker}"),
                )
            })?;
        if unit.owner_player_id() != &player {
            return Err(GameStateMappingError::new(
                format!("{path}.declaringPlayerId"),
                "declaring player does not own attacker",
            ));
        }
        attacks.push(IntendedAttack::new(
            attacker,
            defender,
            StateRevision::new(value.declared_at_tick),
            player,
            match value.city_conquest_action {
                CityConquestActionDto::Capture => CityConquestAction::Capture,
                CityConquestActionDto::Destroy => CityConquestAction::Destroy,
            },
        ));
    }
    CombatState::try_new(attacks).map_err(|unit| {
        GameStateMappingError::new(
            "$.intendedAttacks",
            format!("duplicate attacker declaration: {unit}"),
        )
    })
}

#[must_use]
pub(super) fn encode_combat(value: &CombatState) -> Vec<IntendedAttackDto> {
    value
        .intended_attacks()
        .iter()
        .map(|attack| IntendedAttackDto {
            attacker_unit_id: attack.attacker_unit_id().as_str().to_owned(),
            defender_col: attack.defender().col(),
            defender_row: attack.defender().row(),
            declared_at_tick: attack.declared_at_tick().get(),
            declaring_player_id: attack.declaring_player_id().as_str().to_owned(),
            city_conquest_action: match attack.city_conquest_action() {
                CityConquestAction::Capture => CityConquestActionDto::Capture,
                CityConquestAction::Destroy => CityConquestActionDto::Destroy,
            },
        })
        .collect()
}
