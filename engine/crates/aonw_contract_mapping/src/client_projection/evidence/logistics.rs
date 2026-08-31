use aonw_contracts::client::{ClientLogisticsEvidenceDto, UnitMovementExecutionDto};
use aonw_engine::{LogisticsExecution, UnitMovementExecution};

use crate::encode_troop;

use super::super::coordinate;
use super::movement;

pub(super) fn logistics_evidence(value: &LogisticsExecution) -> ClientLogisticsEvidenceDto {
    match value {
        LogisticsExecution::AutoExplore {
            unit_id,
            target,
            movement,
        } => ClientLogisticsEvidenceDto::AutoExplore {
            unit_id: unit_id.as_str().to_owned(),
            target: coordinate(*target),
            movement: movement.as_ref().map(movement_execution),
        },
        LogisticsExecution::MerchantRouteAssigned {
            unit_id,
            origin_city_id,
            destination_city_id,
            steps,
            transport_network_fingerprint,
        } => ClientLogisticsEvidenceDto::MerchantRouteAssigned {
            unit_id: unit_id.as_str().to_owned(),
            origin_city_id: origin_city_id.as_str().to_owned(),
            destination_city_id: destination_city_id.as_str().to_owned(),
            steps: steps.iter().map(movement::step).collect(),
            transport_network_fingerprint: transport_network_fingerprint.to_string(),
        },
        LogisticsExecution::MerchantTravelQueued {
            unit_id,
            destination_city_id,
            steps,
        } => ClientLogisticsEvidenceDto::MerchantTravelQueued {
            unit_id: unit_id.as_str().to_owned(),
            destination_city_id: destination_city_id.as_str().to_owned(),
            steps: steps.iter().map(movement::step).collect(),
        },
        LogisticsExecution::TroopDetached {
            source_unit_id,
            detached_unit_id,
            troop_kind,
            destination,
        } => ClientLogisticsEvidenceDto::TroopDetached {
            source_unit_id: source_unit_id.as_str().to_owned(),
            detached_unit_id: detached_unit_id.as_str().to_owned(),
            troop_kind: encode_troop(*troop_kind),
            destination: coordinate(*destination),
        },
    }
}

pub(super) fn movement_execution(value: &UnitMovementExecution) -> UnitMovementExecutionDto {
    UnitMovementExecutionDto {
        unit_id: value.unit_id().as_str().to_owned(),
        from: coordinate(value.from()),
        steps: value.steps().iter().map(movement::step).collect(),
    }
}
