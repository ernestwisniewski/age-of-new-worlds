use super::{ClientDecodeError, decode_city_id, decode_unit_id};
use crate::{
    CityExpansionOptionsRequest, CityFoundingOptionsRequest, CityWorkedHexOptionsRequest,
    CityYieldRequest, ReachableRequest, RoutePlanRequest, RuntimeQuery,
    StrategicResourceProjectionRequest, UnitLogisticsOptionsRequest, WorkerOptionsRequest,
};
use aonw_contracts::client::ClientQueryDto;
use aonw_domain::HexCoord;

pub(crate) fn query(query: ClientQueryDto) -> Result<RuntimeQuery, ClientDecodeError> {
    match query {
        ClientQueryDto::HexInspection {
            expected_revision,
            coordinate,
        } => Ok(RuntimeQuery::HexInspection(crate::HexInspectionRequest {
            expected_revision,
            coordinate: aonw_domain::HexCoord::new(coordinate.col, coordinate.row),
        })),
        ClientQueryDto::ResearchOptions { expected_revision } => Ok(RuntimeQuery::ResearchOptions(
            crate::ResearchOptionsRequest { expected_revision },
        )),
        query @ (ClientQueryDto::CityFoundingOptions { .. }
        | ClientQueryDto::CityWorkedHexOptions { .. }
        | ClientQueryDto::CityExpansionOptions { .. }
        | ClientQueryDto::CityYield { .. }) => city_query(query),
        ClientQueryDto::StrategicResourceProjection { expected_revision } => {
            Ok(RuntimeQuery::StrategicResourceProjection(
                StrategicResourceProjectionRequest { expected_revision },
            ))
        }
        ClientQueryDto::ProductionOptions {
            expected_revision,
            city_id,
        } => Ok(RuntimeQuery::ProductionOptions(
            crate::ProductionOptionsRequest {
                expected_revision,
                city_id: decode_city_id(city_id)?,
            },
        )),
        ClientQueryDto::WorkerOptions {
            expected_revision,
            unit_id,
        } => Ok(RuntimeQuery::WorkerOptions(WorkerOptionsRequest {
            expected_revision,
            unit_id: decode_unit_id(unit_id)?,
        })),
        ClientQueryDto::CombatPreview {
            expected_revision,
            attacker_unit_id,
            defender,
        } => Ok(RuntimeQuery::CombatPreview(crate::CombatPreviewRequest {
            expected_revision,
            attacker_unit_id: decode_unit_id(attacker_unit_id)?,
            defender: HexCoord::new(defender.col, defender.row),
        })),
        ClientQueryDto::Reachable {
            expected_revision,
            unit_id,
        } => Ok(RuntimeQuery::Reachable(ReachableRequest {
            expected_revision,
            unit_id: decode_unit_id(unit_id)?,
        })),
        ClientQueryDto::RoutePlan {
            expected_revision,
            unit_id,
            target,
        } => Ok(RuntimeQuery::RoutePlan(RoutePlanRequest {
            expected_revision,
            unit_id: decode_unit_id(unit_id)?,
            target: HexCoord::new(target.col, target.row),
        })),
        ClientQueryDto::UnitLogisticsOptions {
            expected_revision,
            unit_id,
        } => Ok(RuntimeQuery::UnitLogisticsOptions(
            UnitLogisticsOptionsRequest {
                expected_revision,
                unit_id: decode_unit_id(unit_id)?,
            },
        )),
    }
}

fn city_query(query: ClientQueryDto) -> Result<RuntimeQuery, ClientDecodeError> {
    match query {
        ClientQueryDto::CityFoundingOptions {
            expected_revision,
            founder_unit_id,
        } => Ok(RuntimeQuery::CityFoundingOptions(
            CityFoundingOptionsRequest {
                expected_revision,
                founder_unit_id: decode_unit_id(founder_unit_id)?,
            },
        )),
        ClientQueryDto::CityWorkedHexOptions {
            expected_revision,
            city_id,
        } => Ok(RuntimeQuery::CityWorkedHexOptions(
            CityWorkedHexOptionsRequest {
                expected_revision,
                city_id: decode_city_id(city_id)?,
            },
        )),
        ClientQueryDto::CityExpansionOptions {
            expected_revision,
            city_id,
        } => Ok(RuntimeQuery::CityExpansionOptions(
            CityExpansionOptionsRequest {
                expected_revision,
                city_id: decode_city_id(city_id)?,
            },
        )),
        ClientQueryDto::CityYield {
            expected_revision,
            city_id,
        } => Ok(RuntimeQuery::CityYield(CityYieldRequest {
            expected_revision,
            city_id: decode_city_id(city_id)?,
        })),
        _ => unreachable!("city query dispatcher received another family"),
    }
}
