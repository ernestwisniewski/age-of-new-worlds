//! Aggregate invariants and atomic transitions for current artifact state.

use aonw_domain::{
    ArtifactId, ArtifactStateUpdate, City, CityId, EconomyState, GameState, GameStateBuildError,
    HexCoord, HexGridBounds, MovementUnits, PlayerId, StateRevision, Unit, UnitActivity, UnitId,
    UnitKind, UnitOccupancyPolicy, WorldArtifact, WorldArtifactLocation, WorldArtifactType,
};

#[test]
fn artifact_update_rebuilds_unit_location_and_economy_atomically() {
    let player = player();
    let unit = unit(&player);
    let artifact_id = ArtifactId::new("artifact").expect("artifact id");
    let artifact = WorldArtifact::new(
        artifact_id.clone(),
        WorldArtifactType::HeroSword,
        WorldArtifactLocation::Map(unit.position()),
    );
    let state = state(unit.clone(), [artifact]);
    let excavating_unit = unit.after_artifact_excavation_started(artifact_id.clone());
    let excavating_artifact = state.artifacts()[0]
        .try_start_excavation(excavating_unit.id().clone(), unit.position(), 2)
        .expect("start excavation");
    let updated = state
        .into_after_artifact(ArtifactStateUpdate {
            revision: StateRevision::new(2),
            units: vec![excavating_unit],
            artifacts: vec![excavating_artifact],
            economy: EconomyState::default(),
        })
        .expect("artifact update");
    assert_eq!(updated.revision(), StateRevision::new(2));
    assert_eq!(
        updated.units()[0].activity().excavating_artifact_id(),
        Some(&artifact_id)
    );
}

#[test]
fn city_storage_is_single_slot_and_excavation_is_positive_and_stationary() {
    let player = player();
    let city_id = CityId::new("city").expect("city id");
    let city = City::builder(city_id.clone(), player.clone(), "City", HexCoord::new(1, 1))
        .build()
        .expect("city");
    let stored = [
        artifact("a", WorldArtifactLocation::Stored(city_id.clone())),
        artifact("b", WorldArtifactLocation::Stored(city_id.clone())),
    ];
    let duplicate = GameState::builder(
        StateRevision::INITIAL,
        1,
        bounds(),
        UnitOccupancyPolicy::Exclusive,
        [],
    )
    .with_cities([city])
    .with_artifacts(stored)
    .try_build()
    .expect_err("single city slot");
    assert!(matches!(
        &duplicate,
        GameStateBuildError::CityArtifactSlotOccupied { .. }
    ));
    assert_eq!(
        duplicate.to_string(),
        "city city stores both artifacts a and b"
    );

    let artifact_id = ArtifactId::new("excavation").expect("artifact id");
    let unit_id = UnitId::new("unit").expect("unit id");
    let excavator = Unit::builder(
        unit_id.clone(),
        player,
        UnitKind::Scout,
        "Scout",
        HexCoord::new(0, 0),
        MovementUnits::ZERO,
    )
    .with_activity(UnitActivity::new(
        None,
        None,
        None,
        Some(artifact_id.clone()),
    ))
    .build()
    .expect("excavator");
    for (coordinate, remaining_turns) in [(HexCoord::new(1, 0), 1), (HexCoord::new(0, 0), 0)] {
        let invalid = artifact(
            artifact_id.as_str(),
            WorldArtifactLocation::Excavation {
                unit_id: unit_id.clone(),
                coordinate,
                remaining_turns,
            },
        );
        let failure = GameState::builder(
            StateRevision::INITIAL,
            1,
            bounds(),
            UnitOccupancyPolicy::Exclusive,
            [excavator.clone()],
        )
        .with_artifacts([invalid])
        .try_build()
        .expect_err("invalid excavation");
        assert!(matches!(
            &failure,
            GameStateBuildError::InvalidArtifactExcavation { .. }
        ));
        assert_eq!(
            failure.to_string(),
            "artifact excavation has invalid excavation state for unit unit"
        );
    }
}

fn state(unit: Unit, artifacts: impl IntoIterator<Item = WorldArtifact>) -> GameState {
    GameState::builder(
        StateRevision::new(1),
        1,
        bounds(),
        UnitOccupancyPolicy::Exclusive,
        [unit],
    )
    .with_artifacts(artifacts)
    .try_build()
    .expect("state")
}

fn unit(player: &PlayerId) -> Unit {
    Unit::builder(
        UnitId::new("unit").expect("unit id"),
        player.clone(),
        UnitKind::Scout,
        "Scout",
        HexCoord::new(0, 0),
        MovementUnits::new(10),
    )
    .build()
    .expect("unit")
}

fn artifact(id: &str, location: WorldArtifactLocation) -> WorldArtifact {
    WorldArtifact::new(
        ArtifactId::new(id).expect("artifact id"),
        WorldArtifactType::HeroSword,
        location,
    )
}

fn player() -> PlayerId {
    PlayerId::new("player").expect("player id")
}

fn bounds() -> HexGridBounds {
    HexGridBounds::new(3, 3).expect("bounds")
}
