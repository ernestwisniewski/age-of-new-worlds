use aonw_contracts::client::ClientQueryDto;
use aonw_domain::HexCoord;
use aonw_engine::{
    CityExpansionOptionsQuery, CityFoundingOptionsQuery, CityWorkedHexOptionsQuery, CityYieldQuery,
    CombatPreviewQuery, GameQuery, ProductionOptionsQuery, ReachableMovementQuery,
    StrategicResourceProjectionQuery, TerrainMovementQuery, UnitLogisticsOptionsQuery,
    WorkerOptionsQuery,
};

use super::{PlayerQueryMappingError, city_id, unit_id};

pub(super) fn city<R>(
    query: ClientQueryDto,
    execute: impl for<'query> FnOnce(GameQuery<'query>) -> R,
) -> Result<R, PlayerQueryMappingError> {
    match query {
        ClientQueryDto::CityFoundingOptions {
            expected_revision,
            founder_unit_id,
        } => {
            let unit = unit_id(founder_unit_id)?;
            Ok(execute(GameQuery::CityFoundingOptions(
                CityFoundingOptionsQuery::new(expected_revision, &unit),
            )))
        }
        ClientQueryDto::CityWorkedHexOptions {
            expected_revision,
            city_id: value,
        } => {
            let city = city_id(value)?;
            Ok(execute(GameQuery::CityWorkedHexOptions(
                CityWorkedHexOptionsQuery::new(expected_revision, &city),
            )))
        }
        ClientQueryDto::CityExpansionOptions {
            expected_revision,
            city_id: value,
        } => {
            let city = city_id(value)?;
            Ok(execute(GameQuery::CityExpansionOptions(
                CityExpansionOptionsQuery::new(expected_revision, &city),
            )))
        }
        ClientQueryDto::CityYield {
            expected_revision,
            city_id: value,
        } => {
            let city = city_id(value)?;
            Ok(execute(GameQuery::CityYield(CityYieldQuery::new(
                expected_revision,
                &city,
            ))))
        }
        _ => unreachable!("city query dispatcher received another family"),
    }
}

pub(super) fn economy<R>(
    query: ClientQueryDto,
    execute: impl for<'query> FnOnce(GameQuery<'query>) -> R,
) -> Result<R, PlayerQueryMappingError> {
    match query {
        ClientQueryDto::StrategicResourceProjection { expected_revision } => {
            Ok(execute(GameQuery::StrategicResourceProjection(
                StrategicResourceProjectionQuery::new(expected_revision),
            )))
        }
        ClientQueryDto::ProductionOptions {
            expected_revision,
            city_id: value,
        } => {
            let city = city_id(value)?;
            Ok(execute(GameQuery::ProductionOptions(
                ProductionOptionsQuery::new(expected_revision, &city),
            )))
        }
        _ => unreachable!("economy query dispatcher received another family"),
    }
}

pub(super) fn unit<R>(
    query: ClientQueryDto,
    execute: impl for<'query> FnOnce(GameQuery<'query>) -> R,
) -> Result<R, PlayerQueryMappingError> {
    match query {
        ClientQueryDto::WorkerOptions {
            expected_revision,
            unit_id: value,
        } => {
            let unit = unit_id(value)?;
            Ok(execute(GameQuery::WorkerOptions(WorkerOptionsQuery::new(
                expected_revision,
                &unit,
            ))))
        }
        ClientQueryDto::CombatPreview {
            expected_revision,
            attacker_unit_id,
            defender,
        } => {
            let unit = unit_id(attacker_unit_id)?;
            Ok(execute(GameQuery::CombatPreview(CombatPreviewQuery::new(
                expected_revision,
                &unit,
                HexCoord::new(defender.col, defender.row),
            ))))
        }
        ClientQueryDto::Reachable {
            expected_revision,
            unit_id: value,
        } => {
            let unit = unit_id(value)?;
            Ok(execute(GameQuery::Reachable(ReachableMovementQuery::new(
                expected_revision,
                &unit,
            ))))
        }
        ClientQueryDto::RoutePlan {
            expected_revision,
            unit_id: value,
            target,
        } => {
            let unit = unit_id(value)?;
            Ok(execute(GameQuery::PlanRoute(TerrainMovementQuery::new(
                expected_revision,
                &unit,
                HexCoord::new(target.col, target.row),
            ))))
        }
        ClientQueryDto::UnitLogisticsOptions {
            expected_revision,
            unit_id: value,
        } => {
            let unit = unit_id(value)?;
            Ok(execute(GameQuery::UnitLogisticsOptions(
                UnitLogisticsOptionsQuery::new(expected_revision, &unit),
            )))
        }
        _ => unreachable!("unit query dispatcher received another family"),
    }
}
