mod artifact;
mod diplomacy;
mod evidence;
mod presentation;
mod snapshot;
mod worker;

use aonw_contracts::client::{
    CityFoundingDraftViewDto, CityFoundingJobViewDto, FieldImprovementViewDto,
    OwnedCityDetailsViewDto, OwnedUnitDetailsViewDto, PlayerCityViewDto, PlayerUnitViewDto,
    PlayerViewPatchDto, RoadViewDto, WorkerJobViewDto,
};
use aonw_contracts::{ArmyTroopDto, CoordinateDto, TransportConditionDto};
use aonw_domain::{HexCoord, TransportCondition};
use aonw_projection::{
    CityFoundingDraftView, PlayerCityView, PlayerFieldImprovementView, PlayerRoadView,
    PlayerUnitView, PlayerViewPatch,
};

use crate::{
    encode_city_building, encode_city_production_queue, encode_city_specialization,
    encode_city_wonder, encode_improvement, encode_merchant_trade_route, encode_queued_path,
    encode_troop, encode_unit_kind, encode_unit_posture,
};

pub use evidence::{
    encode_client_event, encode_client_evidence, encode_combat_preview, encode_recipient_evidence,
};
pub use presentation::{encode_pending_action, encode_turn_lifecycle};
pub use snapshot::{encode_client_stamp, encode_player_view_snapshot};
pub use worker::encode_worker_automation_option;

use artifact::artifact;
use diplomacy::diplomacy;
use snapshot::{economy, fog, research, victory};

/// Maps one recipient-safe projection delta to the strict current client DTO.
#[must_use]
pub fn encode_player_view_patch(value: &PlayerViewPatch) -> PlayerViewPatchDto {
    PlayerViewPatchDto {
        from_revision: value.from_revision,
        to_revision: value.to_revision,
        turn: value.turn,
        turn_mode: crate::game_state_mapping::encode_turn_mode(value.turn_mode),
        fog: value.fog.as_ref().map(fog),
        economy: value.economy.as_ref().map(economy),
        research: value.research.as_ref().map(research),
        victory: value.victory.as_ref().map(victory),
        turn_lifecycle: value.turn_lifecycle.map(encode_turn_lifecycle),
        outcome: value.outcome.as_ref().map(crate::encode_game_outcome),
        upserted_units: value.upserted_units.iter().map(unit).collect(),
        removed_unit_ids: value
            .removed_unit_ids
            .iter()
            .map(|id| id.as_str().to_owned())
            .collect(),
        upserted_cities: value.upserted_cities.iter().map(city).collect(),
        removed_city_ids: value
            .removed_city_ids
            .iter()
            .map(|id| id.as_str().to_owned())
            .collect(),
        upserted_artifacts: value.upserted_artifacts.iter().map(artifact).collect(),
        removed_artifact_ids: value
            .removed_artifact_ids
            .iter()
            .map(|id| id.as_str().to_owned())
            .collect(),
        upserted_field_improvements: value
            .upserted_field_improvements
            .iter()
            .copied()
            .map(field_improvement)
            .collect(),
        removed_field_improvement_coordinates: value
            .removed_field_improvement_coordinates
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
        upserted_roads: value.upserted_roads.iter().copied().map(road).collect(),
        removed_road_coordinates: value
            .removed_road_coordinates
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
        pending_action: value.pending_action.as_ref().map(encode_pending_action),
        city_founding_draft: value.city_founding_draft.as_ref().map(founding_draft),
        diplomacy: value.diplomacy.as_ref().map(diplomacy),
    }
}

fn unit(value: &PlayerUnitView) -> PlayerUnitViewDto {
    PlayerUnitViewDto {
        id: value.id().as_str().to_owned(),
        owner_player_id: value.owner_player_id().as_str().to_owned(),
        kind: encode_unit_kind(value.kind()),
        name: value.name().to_owned(),
        coordinate: CoordinateDto {
            col: value.col(),
            row: value.row(),
        },
        movement_units: value.movement_units(),
        posture: encode_unit_posture(value.posture()),
        hit_points: value.hit_points(),
        carried_artifact_id: value.carried_artifact_id().map(|id| id.as_str().to_owned()),
        owned_details: value.owned_details().map(|details| {
            let activity = details.activity();
            OwnedUnitDetailsViewDto {
                army: details
                    .army()
                    .iter()
                    .map(|troop| ArmyTroopDto {
                        kind: encode_troop(troop.kind()),
                        count: troop.count(),
                    })
                    .collect(),
                queued_path: details.queued_path().map(encode_queued_path),
                merchant_trade_route: details
                    .merchant_trade_route()
                    .map(encode_merchant_trade_route),
                worker_job: activity.worker_job().map(worker_job),
                city_founding_job: activity
                    .city_founding_job()
                    .map(|job| CityFoundingJobViewDto {
                        center: coordinate(job.center()),
                        controlled_hexes: job
                            .controlled_hexes()
                            .iter()
                            .copied()
                            .map(coordinate)
                            .collect(),
                        remaining_turns: job.remaining_turns(),
                        total_turns: job.total_turns(),
                    }),
                worker_assignment: activity.worker_assignment().map(coordinate),
                excavating_artifact_id: activity
                    .excavating_artifact_id()
                    .map(|id| id.as_str().to_owned()),
                worker_build_charges: details.worker_build_charges(),
                experience_points: details.experience_points(),
            }
        }),
    }
}

fn worker_job(job: &aonw_domain::WorkerJob) -> WorkerJobViewDto {
    match job {
        aonw_domain::WorkerJob::FieldImprovement {
            target,
            improvement,
            remaining_turns,
            total_turns,
        } => WorkerJobViewDto::FieldImprovement {
            target: coordinate(*target),
            improvement: encode_improvement(*improvement),
            remaining_turns: *remaining_turns,
            total_turns: *total_turns,
        },
        aonw_domain::WorkerJob::RoadConstruction {
            target,
            remaining_turns,
            total_turns,
        } => WorkerJobViewDto::RoadConstruction {
            target: coordinate(*target),
            remaining_turns: *remaining_turns,
            total_turns: *total_turns,
        },
    }
}

fn city(value: &PlayerCityView) -> PlayerCityViewDto {
    PlayerCityViewDto {
        id: value.id().as_str().to_owned(),
        owner_player_id: value.owner_player_id().as_str().to_owned(),
        name: value.name().to_owned(),
        center: coordinate(value.center()),
        visible_controlled_hexes: value
            .visible_controlled_hexes()
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
        hit_points: value.hit_points(),
        owned_details: value
            .owned_details()
            .map(|details| OwnedCityDetailsViewDto {
                population: details.population(),
                stored_food: details.stored_food(),
                max_hexes: details.max_hexes(),
                territory_radius: details.territory_radius(),
                worked_hexes: details
                    .worked_hexes()
                    .iter()
                    .copied()
                    .map(coordinate)
                    .collect(),
                buildings: details
                    .buildings()
                    .iter()
                    .copied()
                    .map(encode_city_building)
                    .collect(),
                wonders: details
                    .wonders()
                    .iter()
                    .copied()
                    .map(encode_city_wonder)
                    .collect(),
                production_queue: details.production_queue().map(encode_city_production_queue),
                production_overflow: details.production_overflow(),
                specialization: details.specialization().map(encode_city_specialization),
                preferred_expansion_hex: details.preferred_expansion_hex().map(coordinate),
            }),
    }
}

fn field_improvement(value: PlayerFieldImprovementView) -> FieldImprovementViewDto {
    FieldImprovementViewDto {
        coordinate: coordinate(value.coordinate()),
        improvement: encode_improvement(value.improvement()),
        era_column: value.era_column(),
    }
}

fn road(value: PlayerRoadView) -> RoadViewDto {
    RoadViewDto {
        coordinate: coordinate(value.coordinate()),
        condition: match value.condition() {
            TransportCondition::Operational => TransportConditionDto::Operational,
            TransportCondition::Pillaged => TransportConditionDto::Pillaged,
        },
    }
}

fn founding_draft(value: &CityFoundingDraftView) -> CityFoundingDraftViewDto {
    CityFoundingDraftViewDto {
        founder_unit_id: value.founder_unit_id().as_str().to_owned(),
        center: coordinate(value.center()),
        controlled_hexes: value
            .controlled_hexes()
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
    }
}

const fn coordinate(value: HexCoord) -> CoordinateDto {
    CoordinateDto {
        col: value.col(),
        row: value.row(),
    }
}
