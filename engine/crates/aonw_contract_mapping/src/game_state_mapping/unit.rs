use aonw_contracts::{
    ArmyTroopDto, CityFoundingJobDto, MAX_MOVEMENT_BALANCE_UNITS, MAX_QUEUED_PATH_STEP_COUNT,
    MerchantTradeRouteDto, UnitActivityDto, UnitDto, WorkerJobDto,
};
use aonw_domain::{
    ArmyTroop, ArtifactId, CityFoundingJob, CityId, HexCoord, MerchantTradeRoute, MovementUnits,
    PlayerId, Unit, UnitActivity, UnitId, WorkerJob,
};

use crate::{
    decode_queued_path, decode_unit_kind, decode_unit_posture, encode_queued_path,
    encode_unit_kind, encode_unit_posture,
};

use super::error::GameStateMappingError;
use super::value::{
    decode_coordinate, decode_improvement, decode_step, decode_troop, encode_coordinate,
    encode_improvement, encode_step, encode_troop,
};

pub(super) fn decode_unit(index: usize, dto: UnitDto) -> Result<Unit, GameStateMappingError> {
    let path = format!("$.units[{index}]");
    if dto.movement_units > MAX_MOVEMENT_BALANCE_UNITS {
        return Err(GameStateMappingError::new(
            format!("{path}.movementUnits"),
            format!("exceeds {MAX_MOVEMENT_BALANCE_UNITS}"),
        ));
    }
    if dto
        .queued_path
        .as_ref()
        .is_some_and(|route| route.steps.len() > MAX_QUEUED_PATH_STEP_COUNT)
    {
        return Err(GameStateMappingError::new(
            format!("{path}.queuedPath.steps"),
            format!("exceeds {MAX_QUEUED_PATH_STEP_COUNT}"),
        ));
    }
    let id = UnitId::new(dto.id)
        .map_err(|error| GameStateMappingError::new(format!("{path}.id"), error.to_string()))?;
    let owner = PlayerId::new(dto.owner_player_id).map_err(|error| {
        GameStateMappingError::new(format!("{path}.ownerPlayerId"), error.to_string())
    })?;
    let queued_path = dto
        .queued_path
        .map(decode_queued_path)
        .transpose()
        .map_err(|error| {
            GameStateMappingError::new(format!("{path}.queuedPath"), error.to_string())
        })?;
    let merchant_route = dto
        .merchant_trade_route
        .map(|route| decode_merchant(&path, route))
        .transpose()?;
    let activity = decode_activity(&path, dto.activity)?;
    let artifact = dto
        .carried_artifact_id
        .map(ArtifactId::new)
        .transpose()
        .map_err(|error| {
            GameStateMappingError::new(format!("{path}.carriedArtifactId"), error.to_string())
        })?;
    Unit::builder(
        id,
        owner,
        decode_unit_kind(dto.kind),
        dto.name,
        HexCoord::new(dto.col, dto.row),
        MovementUnits::new(dto.movement_units),
    )
    .with_army(
        dto.army
            .into_iter()
            .map(|troop| ArmyTroop::new(decode_troop(troop.kind), troop.count)),
    )
    .with_queued_path(queued_path)
    .with_merchant_trade_route(merchant_route)
    .with_activity(activity)
    .with_worker_build_charges(dto.worker_build_charges)
    .with_hit_points(dto.hit_points)
    .with_experience_points(dto.experience_points)
    .with_posture(decode_unit_posture(dto.posture))
    .with_carried_artifact(artifact)
    .build()
    .map_err(|error| GameStateMappingError::new(path, error.to_string()))
}

pub(super) fn encode_unit(unit: &Unit) -> UnitDto {
    UnitDto {
        id: unit.id().as_str().to_owned(),
        owner_player_id: unit.owner_player_id().as_str().to_owned(),
        kind: encode_unit_kind(unit.kind()),
        name: unit.name().to_owned(),
        col: unit.position().col(),
        row: unit.position().row(),
        movement_units: unit.movement_units().get(),
        army: unit
            .army()
            .iter()
            .map(|troop| ArmyTroopDto {
                kind: encode_troop(troop.kind()),
                count: troop.count(),
            })
            .collect(),
        queued_path: unit.queued_path().map(encode_queued_path),
        merchant_trade_route: unit.merchant_trade_route().map(encode_merchant_trade_route),
        activity: encode_unit_activity(unit.activity()),
        worker_build_charges: unit.worker_build_charges(),
        hit_points: unit.hit_points(),
        experience_points: unit.experience_points(),
        posture: encode_unit_posture(unit.posture()),
        carried_artifact_id: unit.carried_artifact_id().map(|id| id.as_str().to_owned()),
    }
}

fn decode_merchant(
    path: &str,
    dto: MerchantTradeRouteDto,
) -> Result<MerchantTradeRoute, GameStateMappingError> {
    if dto.steps.len() > MAX_QUEUED_PATH_STEP_COUNT {
        return Err(GameStateMappingError::new(
            format!("{path}.merchantTradeRoute.steps"),
            "route is too long",
        ));
    }
    Ok(MerchantTradeRoute::new(
        CityId::new(dto.origin_city_id).map_err(|error| {
            GameStateMappingError::new(
                format!("{path}.merchantTradeRoute.originCityId"),
                error.to_string(),
            )
        })?,
        CityId::new(dto.destination_city_id).map_err(|error| {
            GameStateMappingError::new(
                format!("{path}.merchantTradeRoute.destinationCityId"),
                error.to_string(),
            )
        })?,
        dto.steps.into_iter().map(decode_step),
        dto.transport_network_fingerprint,
    ))
}

/// Converts a validated merchant route into its stable wire representation.
#[must_use]
pub fn encode_merchant_trade_route(route: &MerchantTradeRoute) -> MerchantTradeRouteDto {
    MerchantTradeRouteDto {
        origin_city_id: route.origin_city_id().as_str().to_owned(),
        destination_city_id: route.destination_city_id().as_str().to_owned(),
        steps: route
            .steps()
            .iter()
            .map(|step| encode_step(*step))
            .collect(),
        transport_network_fingerprint: route.transport_network_fingerprint().to_owned(),
    }
}

fn decode_activity(
    path: &str,
    dto: UnitActivityDto,
) -> Result<UnitActivity, GameStateMappingError> {
    let worker_job = dto.worker_job.map(|job| match job {
        WorkerJobDto::FieldImprovement {
            target,
            improvement,
            remaining_turns,
            total_turns,
        } => WorkerJob::FieldImprovement {
            target: decode_coordinate(target),
            improvement: decode_improvement(improvement),
            remaining_turns,
            total_turns,
        },
        WorkerJobDto::RoadConstruction {
            target,
            remaining_turns,
            total_turns,
        } => WorkerJob::RoadConstruction {
            target: decode_coordinate(target),
            remaining_turns,
            total_turns,
        },
    });
    let founding = dto.city_founding_job.map(|job| {
        CityFoundingJob::new(
            decode_coordinate(job.center),
            job.controlled_hexes.into_iter().map(decode_coordinate),
            job.remaining_turns,
            job.total_turns,
        )
    });
    let excavating = dto
        .excavating_artifact_id
        .map(ArtifactId::new)
        .transpose()
        .map_err(|error| {
            GameStateMappingError::new(
                format!("{path}.activity.excavatingArtifactId"),
                error.to_string(),
            )
        })?;
    Ok(UnitActivity::new(
        worker_job,
        founding,
        dto.worker_assignment.map(decode_coordinate),
        excavating,
    ))
}

/// Converts complete validated unit activity into its stable wire representation.
#[must_use]
pub fn encode_unit_activity(activity: &UnitActivity) -> UnitActivityDto {
    let worker_job = activity.worker_job().map(|job| match job {
        WorkerJob::FieldImprovement {
            target,
            improvement,
            remaining_turns,
            total_turns,
        } => WorkerJobDto::FieldImprovement {
            target: encode_coordinate(*target),
            improvement: encode_improvement(*improvement),
            remaining_turns: *remaining_turns,
            total_turns: *total_turns,
        },
        WorkerJob::RoadConstruction {
            target,
            remaining_turns,
            total_turns,
        } => WorkerJobDto::RoadConstruction {
            target: encode_coordinate(*target),
            remaining_turns: *remaining_turns,
            total_turns: *total_turns,
        },
    });
    UnitActivityDto {
        worker_job,
        city_founding_job: activity.city_founding_job().map(|job| CityFoundingJobDto {
            center: encode_coordinate(job.center()),
            controlled_hexes: job
                .controlled_hexes()
                .iter()
                .copied()
                .map(encode_coordinate)
                .collect(),
            remaining_turns: job.remaining_turns(),
            total_turns: job.total_turns(),
        }),
        worker_assignment: activity.worker_assignment().map(encode_coordinate),
        excavating_artifact_id: activity
            .excavating_artifact_id()
            .map(|id| id.as_str().to_owned()),
    }
}
