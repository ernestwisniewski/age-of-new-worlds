use aonw_content::{GridLayout, MapDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    GameState, HexCoord, MovementUnits, PlayerId, StateRevision, Unit, UnitActivity, UnitId,
    UnitKind, UnitOccupancyPolicy, UnitPosture,
};

use super::{MoveUnitCommand, TerrainMovementQueryError, apply_move_unit};
use crate::{EngineContext, MoveUnitError, movement::MovementPlanningView};

fn map(cols: u16, rows: u16, rough: &[HexCoord]) -> MapDefinition {
    let mut tiles = Vec::new();
    for row in 0..rows {
        for col in 0..cols {
            let coordinate = HexCoord::new(i32::from(col), i32::from(row));
            let terrains = if rough.contains(&coordinate) {
                vec![TerrainType::Plains, TerrainType::Hills]
            } else {
                vec![TerrainType::Plains]
            };
            tiles.push(
                TileDefinition::try_new_for_simulation(coordinate, terrains, Vec::new(), 0)
                    .expect("valid tile"),
            );
        }
    }
    MapDefinition::try_new(
        "movement-transition",
        GridLayout::OddQFlatTop,
        cols,
        rows,
        tiles,
        Vec::new(),
    )
    .expect("valid map")
}

fn unit(id: &str, owner: &PlayerId, kind: UnitKind, position: HexCoord, movement: u32) -> Unit {
    Unit::builder(
        UnitId::new(id).expect("valid unit id"),
        owner.clone(),
        kind,
        format!("unit.{id}"),
        position,
        MovementUnits::new(movement),
    )
    .build()
    .expect("valid unit")
}

fn state(revision: u64, map: &MapDefinition, units: impl IntoIterator<Item = Unit>) -> GameState {
    GameState::try_new(
        StateRevision::new(revision),
        1,
        map.bounds(),
        UnitOccupancyPolicy::Exclusive,
        units,
    )
    .expect("valid state")
}

#[test]
fn adjacent_move_returns_state_event_and_exact_execution() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let map = map(3, 1, &[]);
    let state = state(
        5,
        &map,
        [unit(
            "unit-1",
            &actor,
            UnitKind::Commander,
            HexCoord::new(0, 0),
            4,
        )],
    );
    let unit_id = UnitId::new("unit-1").expect("valid unit id");

    let transition = apply_move_unit(
        &state,
        EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
        MoveUnitCommand::new(5, &unit_id, HexCoord::new(1, 0)),
    )
    .expect("move accepted");

    let moved = transition.unit();
    assert_eq!(transition.revision(), StateRevision::new(6));
    assert_eq!(moved.position(), HexCoord::new(1, 0));
    assert_eq!(moved.movement_units(), MovementUnits::new(2));
    assert_eq!(
        transition.event().map(|event| (event.from(), event.to())),
        Some((HexCoord::new(0, 0), HexCoord::new(1, 0)))
    );
    let execution = transition.execution().expect("movement execution");
    assert_eq!(execution.from(), HexCoord::new(0, 0));
    assert_eq!(execution.steps().len(), 1);
    assert_eq!(
        execution.steps()[0].cumulative_cost(),
        MovementUnits::new(2)
    );
}

#[test]
fn partial_move_rebases_the_queued_path_at_the_destination() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let map = map(4, 1, &[HexCoord::new(1, 0)]);
    let state = state(
        2,
        &map,
        [unit(
            "unit-1",
            &actor,
            UnitKind::Warrior,
            HexCoord::new(0, 0),
            3,
        )],
    );
    let unit_id = UnitId::new("unit-1").expect("valid unit id");

    let transition = apply_move_unit(
        &state,
        EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
        MoveUnitCommand::new(2, &unit_id, HexCoord::new(3, 0)),
    )
    .expect("partial move accepted");
    let moved = transition.unit();
    let queued = moved.queued_path().expect("remaining path queued");

    assert_eq!(moved.position(), HexCoord::new(1, 0));
    assert_eq!(moved.movement_units(), MovementUnits::ZERO);
    assert_eq!(queued.steps()[0].coordinate(), moved.position());
    assert_eq!(queued.steps()[0].cumulative_cost(), MovementUnits::ZERO);
    assert_eq!(queued.target(), HexCoord::new(3, 0));
}

#[test]
fn hidden_blocker_produces_an_accepted_no_op_without_disclosure() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let other = PlayerId::new("player-2").expect("valid player");
    let map = map(3, 1, &[]);
    let state = state(
        7,
        &map,
        [
            unit("unit-1", &actor, UnitKind::Warrior, HexCoord::new(0, 0), 6),
            unit(
                "unit-hidden",
                &other,
                UnitKind::Warrior,
                HexCoord::new(1, 0),
                6,
            ),
        ],
    );
    let unit_id = UnitId::new("unit-1").expect("valid unit id");
    let known: Vec<UnitId> = Vec::new();

    let transition = apply_move_unit(
        &state,
        EngineContext::new(&actor, &map, MovementPlanningView::known_units(&known)),
        MoveUnitCommand::new(7, &unit_id, HexCoord::new(2, 0)),
    )
    .expect("hidden collision is accepted without disclosure");

    assert!(transition.is_no_op());
    assert_eq!(transition.revision(), StateRevision::new(8));
    assert_eq!(transition.unit().position(), HexCoord::new(0, 0));
}

#[test]
fn rejection_preserves_state() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let map = map(2, 1, &[]);
    let blocked = Unit::builder(
        UnitId::new("unit-1").expect("valid unit id"),
        actor.clone(),
        UnitKind::Warrior,
        "unit.warrior",
        HexCoord::new(0, 0),
        MovementUnits::new(6),
    )
    .with_posture(UnitPosture::AutoWorking)
    .with_activity(UnitActivity::new(
        None,
        None,
        Some(HexCoord::new(0, 0)),
        None,
    ))
    .build()
    .expect("valid blocked unit");
    let state = state(9, &map, [blocked]);
    let before = state.clone();
    let unit_id = UnitId::new("unit-1").expect("valid unit id");

    assert_eq!(
        apply_move_unit(
            &state,
            EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
            MoveUnitCommand::new(9, &unit_id, HexCoord::new(1, 0)),
        ),
        Err(MoveUnitError::Query(
            TerrainMovementQueryError::UnitUnavailable
        ))
    );
    assert_eq!(state, before);
}
