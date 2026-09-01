use aonw_contracts::CityConquestActionDto;
use aonw_contracts::client::ClientCommandDto;
use aonw_domain::{CityConquestAction, HexCoord};
use aonw_engine::{
    AssignMerchantTradeRouteCommand, AttackHexCommand, AutoExploreUnitCommand, DetachTroopCommand,
    MoveMerchantToCityCommand, MoveUnitCommand, PlayerCommand, UnitActionCommand,
};

use super::{PlayerCommandMappingError, value};

pub(super) fn decode<R>(
    command: ClientCommandDto,
    apply: impl for<'command> FnOnce(PlayerCommand<'command>) -> R,
) -> Result<R, PlayerCommandMappingError> {
    match command {
        ClientCommandDto::AttackHex {
            expected_revision,
            attacker_unit_id,
            defender,
            city_conquest_action,
        } => {
            let attacker = value::unit_id(attacker_unit_id)?;
            let conquest = match city_conquest_action {
                CityConquestActionDto::Capture => CityConquestAction::Capture,
                CityConquestActionDto::Destroy => CityConquestAction::Destroy,
            };
            Ok(apply(PlayerCommand::AttackHex(
                AttackHexCommand::new(
                    expected_revision,
                    &attacker,
                    HexCoord::new(defender.col, defender.row),
                )
                .with_city_conquest_action(conquest),
            )))
        }
        ClientCommandDto::MoveUnit {
            expected_revision,
            unit_id,
            target,
        } => unit(unit_id, |unit| {
            apply(PlayerCommand::MoveUnit(MoveUnitCommand::new(
                expected_revision,
                unit,
                HexCoord::new(target.col, target.row),
            )))
        }),
        ClientCommandDto::AutoExploreUnit {
            expected_revision,
            unit_id,
        } => unit(unit_id, |unit| {
            apply(PlayerCommand::AutoExploreUnit(AutoExploreUnitCommand::new(
                expected_revision,
                unit,
            )))
        }),
        ClientCommandDto::AssignMerchantTradeRoute {
            expected_revision,
            unit_id,
            destination_city_id,
        } => merchant(unit_id, destination_city_id, |unit, city| {
            apply(PlayerCommand::AssignMerchantTradeRoute(
                AssignMerchantTradeRouteCommand::new(expected_revision, unit, city),
            ))
        }),
        ClientCommandDto::MoveMerchantToCity {
            expected_revision,
            unit_id,
            destination_city_id,
        } => merchant(unit_id, destination_city_id, |unit, city| {
            apply(PlayerCommand::MoveMerchantToCity(
                MoveMerchantToCityCommand::new(expected_revision, unit, city),
            ))
        }),
        ClientCommandDto::DetachTroop {
            expected_revision,
            unit_id,
            troop_kind,
        } => unit(unit_id, |unit| {
            apply(PlayerCommand::DetachTroop(DetachTroopCommand::new(
                expected_revision,
                unit,
                crate::decode_troop(troop_kind),
            )))
        }),
        ClientCommandDto::CancelUnitAction {
            expected_revision,
            unit_id,
        } => unit_action(unit_id, expected_revision, apply, UnitActionKind::Cancel),
        ClientCommandDto::SkipUnitTurn {
            expected_revision,
            unit_id,
        } => unit_action(unit_id, expected_revision, apply, UnitActionKind::Skip),
        ClientCommandDto::FortifyUnit {
            expected_revision,
            unit_id,
        } => unit_action(unit_id, expected_revision, apply, UnitActionKind::Fortify),
        _ => unreachable!("movement decoder receives only movement commands"),
    }
}

fn unit<R>(
    unit_id: String,
    apply: impl for<'command> FnOnce(&'command aonw_domain::UnitId) -> R,
) -> Result<R, PlayerCommandMappingError> {
    let unit = value::unit_id(unit_id)?;
    Ok(apply(&unit))
}

fn merchant<R>(
    unit_id: String,
    city_id: String,
    apply: impl for<'command> FnOnce(&'command aonw_domain::UnitId, &'command aonw_domain::CityId) -> R,
) -> Result<R, PlayerCommandMappingError> {
    let unit = value::unit_id(unit_id)?;
    let city = value::city_id(city_id)?;
    Ok(apply(&unit, &city))
}

#[derive(Clone, Copy)]
enum UnitActionKind {
    Cancel,
    Skip,
    Fortify,
}

fn unit_action<R>(
    unit_id: String,
    expected_revision: u64,
    apply: impl for<'command> FnOnce(PlayerCommand<'command>) -> R,
    kind: UnitActionKind,
) -> Result<R, PlayerCommandMappingError> {
    unit(unit_id, |unit| {
        let command = UnitActionCommand::new(expected_revision, unit);
        apply(match kind {
            UnitActionKind::Cancel => PlayerCommand::CancelUnitAction(command),
            UnitActionKind::Skip => PlayerCommand::SkipUnitTurn(command),
            UnitActionKind::Fortify => PlayerCommand::FortifyUnit(command),
        })
    })
}
