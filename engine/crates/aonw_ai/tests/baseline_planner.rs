//! Baseline planner integration through the public local runtime boundary.

use aonw_ai::{BaselinePlanner, BaselinePlanningOutcome, PlannedCommand};
use aonw_content::{
    GridLayout, MapDefinition, RulesetDefinition, ScenarioDefinition, ScenarioUnitDefinition,
    TerrainType, TileDefinition,
};
use aonw_domain::{HexCoord, PlayerId, StateRevision, UnitId, UnitKind};
use aonw_local_runtime::{LocalRuntime, OpenSession, UnitActionRequest};

#[test]
fn identical_recipient_state_produces_identical_plan_and_fingerprint() {
    let mut first_runtime = opened_runtime();
    let mut second_runtime = opened_runtime();
    let mut first_planner = BaselinePlanner::default();
    let mut second_planner = BaselinePlanner::default();

    let BaselinePlanningOutcome::Planned(first) =
        first_planner.plan(&mut first_runtime).expect("first plan")
    else {
        panic!("first command")
    };
    let BaselinePlanningOutcome::Planned(second) = second_planner
        .plan(&mut second_runtime)
        .expect("second plan")
    else {
        panic!("second command")
    };

    assert_eq!(first, second);
    assert_eq!(first.fingerprint(), second.fingerprint());
    assert_eq!(first.state_digest(), first.stamp().state_digest);
    assert_eq!(first.fingerprint().as_bytes().len(), 32);
    assert_eq!(first.fingerprint().to_string().len(), 64);
    assert_eq!(first.command().expected_revision(), 0);
}

#[test]
fn planner_uses_public_runtime_command_and_replans_only_after_revision_change() {
    let mut runtime = opened_runtime();
    let mut planner = BaselinePlanner::default();
    let snapshot = runtime.snapshot().expect("snapshot");
    assert_eq!(snapshot.recipient_player_id().as_str(), "player-1");

    let BaselinePlanningOutcome::Planned(plan) = planner.plan(&mut runtime).expect("plan") else {
        panic!("planned command")
    };
    assert!(matches!(plan.command(), PlannedCommand::MoveUnit(_)));
    assert_eq!(
        planner.plan(&mut runtime).expect("same revision"),
        BaselinePlanningOutcome::AlreadyPlanned {
            revision: StateRevision::INITIAL
        }
    );

    let result = plan.execute(&mut runtime).expect("execute through runtime");
    assert!(result.is_accepted());
    assert_eq!(result.stamp.revision, StateRevision::new(1));
    assert!(matches!(
        planner.plan(&mut runtime).expect("fresh revision"),
        BaselinePlanningOutcome::Planned(_)
    ));
}

#[test]
fn reopening_a_different_state_at_the_same_revision_requires_a_new_plan() {
    let mut runtime = opened_runtime();
    let mut planner = BaselinePlanner::default();
    assert!(matches!(
        planner.plan(&mut runtime).expect("initial plan"),
        BaselinePlanningOutcome::Planned(_)
    ));

    runtime
        .open(request_at(HexCoord::new(2, 2)))
        .expect("replace session");

    assert!(matches!(
        planner.plan(&mut runtime).expect("replacement plan"),
        BaselinePlanningOutcome::Planned(_)
    ));
}

#[test]
fn stale_plan_is_rejected_without_replacing_the_newer_state() {
    let mut runtime = opened_runtime();
    let mut planner = BaselinePlanner::default();
    let BaselinePlanningOutcome::Planned(plan) = planner.plan(&mut runtime).expect("plan") else {
        panic!("planned command")
    };

    runtime
        .skip_unit_turn(&UnitActionRequest {
            expected_revision: 0,
            unit_id: UnitId::new("unit-1").expect("unit id"),
        })
        .expect("advance revision");
    let newer = runtime.snapshot().expect("newer state").stamp().to_owned();

    let rejected = plan.execute(&mut runtime).expect("typed stale rejection");
    assert_eq!(
        rejected.rejection,
        Some(aonw_engine::CommandRejectionCode::StaleRevision)
    );
    assert_eq!(runtime.snapshot().expect("preserved").stamp(), &newer);
}

fn opened_runtime() -> LocalRuntime {
    let mut runtime = LocalRuntime::default();
    runtime.open(request()).expect("open");
    runtime
}

fn request() -> OpenSession {
    request_at(HexCoord::new(0, 0))
}

fn request_at(position: HexCoord) -> OpenSession {
    let map = map();
    let ruleset = RulesetDefinition::standard().clone();
    let scenario = ScenarioDefinition::try_new(
        "ai-baseline-scenario",
        &map,
        &ruleset,
        [ScenarioUnitDefinition::new(
            UnitId::new("unit-1").expect("unit id"),
            PlayerId::new("player-1").expect("player id"),
            UnitKind::Commander,
            "Commander",
            position,
        )],
    )
    .expect("scenario");
    OpenSession::from_scenario(
        map,
        ruleset,
        &scenario,
        PlayerId::new("player-1").expect("player id"),
    )
    .expect("open request")
}

fn map() -> MapDefinition {
    let tiles = (0..3)
        .flat_map(|row| {
            (0..3).map(move |col| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(col, row),
                    vec![TerrainType::Grassland],
                    Vec::new(),
                    0,
                )
                .expect("tile")
            })
        })
        .collect();
    MapDefinition::try_new(
        "ai-baseline-map",
        GridLayout::OddQFlatTop,
        3,
        3,
        tiles,
        Vec::new(),
    )
    .expect("map")
}
