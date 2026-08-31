//! Integrated simultaneous-turn fixture spanning supported processors.

use aonw_domain::{
    CityFoundingJob, CombatState, Diplomacy, FogOfWar, HexCoord, MovementStep, MovementUnits,
    PlayerId, QueuedMovePath, Unit, UnitKind, WorkerJob,
};

use super::{identity, state_with_identity, unit, unit_id};

pub(super) fn state(
    actor: &PlayerId,
    defender_owner: &PlayerId,
    third: &PlayerId,
    intended: CombatState,
) -> aonw_domain::GameState {
    let founder = unit(
        "founder",
        third,
        UnitKind::Settler,
        HexCoord::new(3, 2),
        None,
    )
    .with_city_founding_job(Some(CityFoundingJob::new(
        HexCoord::new(3, 2),
        [HexCoord::new(3, 1), HexCoord::new(2, 2)],
        1,
        1,
    )));
    let worker = unit("worker", actor, UnitKind::Worker, HexCoord::new(0, 2), None)
        .with_worker_job(Some(WorkerJob::RoadConstruction {
            target: HexCoord::new(0, 2),
            remaining_turns: 1,
            total_turns: 1,
        }));
    state_with_identity(
        identity(),
        vec![
            unit(
                "attacker",
                actor,
                UnitKind::Warrior,
                HexCoord::new(0, 0),
                None,
            ),
            unit(
                "defender",
                defender_owner,
                UnitKind::Settler,
                HexCoord::new(1, 0),
                None,
            ),
            founder,
            worker,
            mover(third),
        ],
        Vec::new(),
        FogOfWar::default(),
        Diplomacy::default(),
        intended,
    )
}

fn mover(owner: &PlayerId) -> Unit {
    let queued = QueuedMovePath::try_new(
        HexCoord::new(2, 0),
        vec![
            MovementStep::new(
                HexCoord::new(3, 0),
                MovementUnits::ZERO,
                MovementUnits::ZERO,
            ),
            MovementStep::new(
                HexCoord::new(2, 0),
                MovementUnits::new(2),
                MovementUnits::new(2),
            ),
        ],
    )
    .expect("queued path");
    Unit::builder(
        unit_id("mover"),
        owner.clone(),
        UnitKind::Scout,
        "mover",
        HexCoord::new(3, 0),
        MovementUnits::new(100),
    )
    .with_queued_path(Some(queued))
    .build()
    .expect("mover")
}
