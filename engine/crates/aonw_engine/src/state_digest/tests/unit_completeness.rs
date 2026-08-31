use aonw_contract_mapping::decode_game_state;
use aonw_contracts::{
    GameStateDto, MovementStepDto, PendingInteractionDto, TroopKindDto, UnitKindDto,
    UnitPostureDto, WorkerJobDto, WorldArtifactLocationDto,
};

use super::fixture::{complete_state_contract, coordinate};
use crate::state_digest::{hash_unit, writer::DigestWriter};

#[test]
fn digest_changes_with_unit_identity_and_movement() {
    let source = complete_state_contract();
    let baseline = first_unit_digest(&source);

    assert_unit_digest_change(&source, baseline, "id", |candidate| {
        rename_unit(candidate, "unit-2");
    });
    assert_unit_digest_change(&source, baseline, "owner", |candidate| {
        rename_owner(candidate, "player-2");
    });
    assert_unit_digest_change(&source, baseline, "kind", |candidate| {
        candidate.units[0].kind = UnitKindDto::Settler;
    });
    assert_unit_digest_change(&source, baseline, "name", |candidate| {
        candidate.units[0].name = "unit.builder".to_owned();
    });
    assert_unit_digest_change(&source, baseline, "position", |candidate| {
        candidate.units[0].col = 1;
        candidate.units[0].row = 0;
        candidate.units[0].queued_path.as_mut().expect("path").steps[0] = movement_step(1, 0, 0, 0);
        match &mut candidate.artifacts[0].location {
            WorldArtifactLocationDto::Excavation { coordinate, .. } => {
                *coordinate = super::fixture::coordinate(1, 0);
            }
            _ => panic!("artifact fixture should be under excavation"),
        }
    });
    assert_unit_digest_change(&source, baseline, "movement balance", |candidate| {
        candidate.units[0].movement_units = 5;
    });
    assert_unit_digest_change(&source, baseline, "army kind", |candidate| {
        candidate.units[0].army[0].kind = TroopKindDto::Archer;
    });
    assert_unit_digest_change(&source, baseline, "army count", |candidate| {
        candidate.units[0].army[0].count = 3;
    });
    assert_unit_digest_change(&source, baseline, "queued target", |candidate| {
        let path = candidate.units[0].queued_path.as_mut().expect("path");
        path.target_col = 1;
        path.target_row = 2;
        path.steps[1] = movement_step(1, 2, 2, 2);
    });
    assert_unit_digest_change(&source, baseline, "queued enter cost", |candidate| {
        let step = &mut candidate.units[0].queued_path.as_mut().expect("path").steps[1];
        step.enter_cost_units = 3;
        step.cumulative_cost_units = 3;
    });
}

#[test]
fn digest_changes_with_unit_orders_and_activity() {
    let source = complete_state_contract();
    let baseline = first_unit_digest(&source);

    assert_unit_digest_change(&source, baseline, "merchant origin", |candidate| {
        candidate.units[0]
            .merchant_trade_route
            .as_mut()
            .expect("merchant route")
            .origin_city_id = "city-2".to_owned();
    });
    assert_unit_digest_change(&source, baseline, "merchant destination", |candidate| {
        candidate.units[0]
            .merchant_trade_route
            .as_mut()
            .expect("merchant route")
            .destination_city_id = "city-1".to_owned();
    });
    assert_unit_digest_change(&source, baseline, "merchant steps", |candidate| {
        candidate.units[0]
            .merchant_trade_route
            .as_mut()
            .expect("merchant route")
            .steps[1] = movement_step(1, 2, 3, 3);
    });
    assert_unit_digest_change(&source, baseline, "merchant fingerprint", |candidate| {
        candidate.units[0]
            .merchant_trade_route
            .as_mut()
            .expect("merchant route")
            .transport_network_fingerprint = "network-2".to_owned();
    });
    assert_unit_digest_change(&source, baseline, "worker job", |candidate| {
        candidate.units[0].activity.worker_job = Some(WorkerJobDto::RoadConstruction {
            target: coordinate(1, 1),
            remaining_turns: 2,
            total_turns: 3,
        });
    });
    assert_unit_digest_change(&source, baseline, "city founding center", |candidate| {
        candidate.units[0]
            .activity
            .city_founding_job
            .as_mut()
            .expect("founding job")
            .center = coordinate(3, 2);
    });
    assert_unit_digest_change(
        &source,
        baseline,
        "city founding controlled hexes",
        |candidate| {
            candidate.units[0]
                .activity
                .city_founding_job
                .as_mut()
                .expect("founding job")
                .controlled_hexes = vec![coordinate(3, 3)];
        },
    );
    assert_unit_digest_change(&source, baseline, "city founding duration", |candidate| {
        candidate.units[0]
            .activity
            .city_founding_job
            .as_mut()
            .expect("founding job")
            .remaining_turns = 1;
    });
    assert_unit_digest_change(&source, baseline, "worker assignment", |candidate| {
        candidate.units[0].activity.worker_assignment = Some(coordinate(2, 1));
    });
    assert_unit_digest_change(&source, baseline, "excavated artifact", |candidate| {
        candidate.units[0].activity.excavating_artifact_id = Some("artifact-3".to_owned());
        candidate.artifacts[0].id = "artifact-3".to_owned();
    });
}

#[test]
fn digest_changes_with_unit_progression() {
    let source = complete_state_contract();
    let baseline = first_unit_digest(&source);

    assert_unit_digest_change(&source, baseline, "worker charges", |candidate| {
        candidate.units[0].worker_build_charges = 5;
    });
    assert_unit_digest_change(&source, baseline, "hit points", |candidate| {
        candidate.units[0].hit_points = Some(8);
    });
    assert_unit_digest_change(&source, baseline, "experience", |candidate| {
        candidate.units[0].experience_points = 12;
    });
    assert_unit_digest_change(&source, baseline, "posture", |candidate| {
        candidate.units[0].posture = UnitPostureDto::Active;
    });
    assert_unit_digest_change(&source, baseline, "carried artifact", |candidate| {
        candidate.units[0].carried_artifact_id = Some("artifact-4".to_owned());
        candidate.units[0].activity.excavating_artifact_id = None;
        candidate.artifacts[0].location = WorldArtifactLocationDto::Map {
            coordinate: coordinate(1, 1),
        };
        candidate.artifacts[1].id = "artifact-4".to_owned();
        candidate.artifacts[1].location = WorldArtifactLocationDto::Carried {
            unit_id: "unit-1".to_owned(),
        };
    });
}

fn assert_unit_digest_change(
    source: &GameStateDto,
    baseline: [u8; 32],
    label: &str,
    change: impl FnOnce(&mut GameStateDto),
) {
    let mut candidate = source.clone();
    change(&mut candidate);
    assert_ne!(
        baseline,
        first_unit_digest(&candidate),
        "unit digest ignored {label}"
    );
}

fn first_unit_digest(contract: &GameStateDto) -> [u8; 32] {
    let state = decode_game_state(contract.clone()).expect("valid complete state");
    let mut writer = DigestWriter::new();
    hash_unit(&mut writer, &state.units()[0]);
    writer.finish()
}

fn rename_unit(contract: &mut GameStateDto, id: &str) {
    contract.units[0].id = id.to_owned();
    contract.intended_attacks[0].attacker_unit_id = id.to_owned();
    for artifact in &mut contract.artifacts {
        match &mut artifact.location {
            WorldArtifactLocationDto::Carried { unit_id }
            | WorldArtifactLocationDto::Excavation { unit_id, .. } => *unit_id = id.to_owned(),
            WorldArtifactLocationDto::Map { .. } | WorldArtifactLocationDto::Stored { .. } => {}
        }
    }
    contract
        .interaction
        .city_founding_draft
        .as_mut()
        .expect("draft")
        .unit_id = id.to_owned();
    if let Some(PendingInteractionDto::WorkerActionSelection { unit_id, .. }) =
        &mut contract.interaction.pending
    {
        *unit_id = id.to_owned();
    }
}

fn rename_owner(contract: &mut GameStateDto, id: &str) {
    contract.units[0].owner_player_id = id.to_owned();
    contract.intended_attacks[0].declaring_player_id = id.to_owned();
    contract
        .interaction
        .city_founding_draft
        .as_mut()
        .expect("draft")
        .owner_player_id = id.to_owned();
    if let Some(PendingInteractionDto::WorkerActionSelection {
        owner_player_id, ..
    }) = &mut contract.interaction.pending
    {
        *owner_player_id = id.to_owned();
    }
}

const fn movement_step(
    col: i32,
    row: i32,
    enter_cost_units: u32,
    cumulative_cost_units: u32,
) -> MovementStepDto {
    MovementStepDto {
        col,
        row,
        enter_cost_units,
        cumulative_cost_units,
    }
}
