use crate::{
    ArmyTroop, ArtifactId, CityFoundingJob, HexCoord, MovementUnits, PlayerId, TroopKind, Unit,
    UnitActivity, UnitBuildError, UnitId, UnitKind, WorkerJob,
};

fn builder() -> super::UnitBuilder {
    Unit::builder(
        UnitId::new("unit-1").expect("unit id"),
        PlayerId::new("player-1").expect("player id"),
        UnitKind::Worker,
        "unit.worker",
        HexCoord::new(1, 2),
        MovementUnits::new(6),
    )
}

#[test]
fn full_unit_preserves_non_movement_fields_and_derives_availability() {
    let activity = UnitActivity::new(
        Some(WorkerJob::RoadConstruction {
            target: HexCoord::new(2, 2),
            remaining_turns: 1,
            total_turns: 3,
        }),
        Some(CityFoundingJob::new(
            HexCoord::new(1, 2),
            [HexCoord::new(1, 1), HexCoord::new(2, 2)],
            2,
            4,
        )),
        Some(HexCoord::new(1, 2)),
        Some(ArtifactId::new("ruins-1").expect("artifact id")),
    );
    let unit = builder()
        .with_army([ArmyTroop::new(TroopKind::Settler, 2)])
        .with_activity(activity.clone())
        .with_worker_build_charges(4)
        .with_hit_points(Some(7))
        .with_experience_points(12)
        .build()
        .expect("unit");

    assert_eq!(unit.activity(), &activity);
    assert_eq!(unit.worker_build_charges(), 4);
    assert_eq!(unit.hit_points(), Some(7));
    assert_eq!(unit.experience_points(), 12);
    assert!(unit.activity().blocks_manual_movement());

    let cancelled = unit.after_cancel_action(MovementUnits::new(10), None);
    assert_eq!(cancelled.activity(), &UnitActivity::default());
}

#[test]
fn unit_rejects_invalid_army_and_job_duration() {
    assert_eq!(
        builder()
            .with_army([ArmyTroop::new(TroopKind::Warrior, 0)])
            .build(),
        Err(UnitBuildError::EmptyTroop(TroopKind::Warrior))
    );
    let invalid = UnitActivity::new(
        Some(WorkerJob::RoadConstruction {
            target: HexCoord::new(0, 0),
            remaining_turns: 4,
            total_turns: 3,
        }),
        None,
        None,
        None,
    );
    assert_eq!(
        builder().with_activity(invalid).build(),
        Err(UnitBuildError::InvalidJobDuration)
    );
}

#[test]
fn unit_actions_preserve_reversible_skip_and_clear_owned_orders() {
    let skipped = builder().build().expect("unit").after_skip_turn();
    assert_eq!(skipped.movement_units(), MovementUnits::ZERO);
    let cancelled =
        skipped.after_cancel_action(MovementUnits::new(20), Some(MovementUnits::new(6)));
    assert_eq!(cancelled.movement_units(), MovementUnits::new(6));

    let fortified = cancelled.after_fortify();
    assert_eq!(fortified.posture(), crate::UnitPosture::Fortified);
    assert_eq!(fortified.movement_units(), MovementUnits::ZERO);
    assert_eq!(
        fortified
            .after_cancel_action(MovementUnits::new(10), None)
            .movement_units(),
        MovementUnits::new(10)
    );
}
