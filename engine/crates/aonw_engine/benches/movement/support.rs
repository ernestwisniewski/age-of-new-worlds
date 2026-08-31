use std::hint::black_box;
use std::time::Instant;

use aonw_content::{GridLayout, MapDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    FogOfWar, GameState, HexCoord, HexGridBounds, MovementUnits, PlayerFog, PlayerId,
    StateRevision, Unit, UnitId, UnitKind, UnitOccupancyPolicy,
};
use aonw_engine::{MovementSearchMetrics, WorkerAutomationMetrics};
use stats_alloc::{Region, Stats};

use crate::GLOBAL;

const ITERATIONS: usize = 20;

#[derive(Clone, Copy, Default)]
pub(crate) struct WorkCounters {
    frontier_pops: u64,
    expanded_tiles: u64,
    examined_edges: u64,
    heap_pushes: u64,
    route_records: u64,
}

impl WorkCounters {
    pub(crate) const fn worker(metrics: WorkerAutomationMetrics) -> Self {
        Self {
            frontier_pops: 0,
            expanded_tiles: metrics.tiles_examined() as u64,
            examined_edges: metrics.legality_evaluations() as u64,
            heap_pushes: 0,
            route_records: metrics.routes_planned() as u64,
        }
    }
}

impl From<MovementSearchMetrics> for WorkCounters {
    fn from(metrics: MovementSearchMetrics) -> Self {
        Self {
            frontier_pops: metrics.frontier_pops(),
            expanded_tiles: metrics.expanded_tiles(),
            examined_edges: metrics.examined_edges(),
            heap_pushes: metrics.heap_pushes(),
            route_records: metrics.route_records(),
        }
    }
}

pub(crate) fn report(
    workload: &str,
    cols: u16,
    rows: u16,
    units: usize,
    metrics: impl Into<WorkCounters>,
    payload_bytes: usize,
    mut operation: impl FnMut() -> u64,
) {
    let metrics = metrics.into();
    for _ in 0..3 {
        black_box(operation());
    }
    let mut samples = Vec::with_capacity(ITERATIONS);
    let mut signature = 0;
    let mut allocation_stats: Option<Stats> = None;
    for _ in 0..ITERATIONS {
        let region = Region::new(GLOBAL);
        let started = Instant::now();
        signature = black_box(operation());
        samples.push(started.elapsed().as_nanos());
        let observed = region.change();
        if let Some(expected) = allocation_stats {
            assert_eq!(
                observed, expected,
                "allocation sample drifted for {workload}"
            );
        } else {
            allocation_stats = Some(observed);
        }
    }
    let allocations = allocation_stats.expect("at least one allocation sample");
    samples.sort_unstable();
    let median = samples[samples.len() / 2];
    let p95 = samples[(samples.len() * 95 / 100).min(samples.len() - 1)];
    println!(
        "{workload},{},{units},{ITERATIONS},{},{},{},{payload_bytes},{},{},{},{},{},{signature:016x},{median},{p95}",
        usize::from(cols) * usize::from(rows),
        allocations.allocations,
        allocations.reallocations,
        allocations.bytes_allocated,
        metrics.frontier_pops,
        metrics.expanded_tiles,
        metrics.examined_edges,
        metrics.heap_pushes,
        metrics.route_records,
    );
}

pub(crate) fn map(cols: u16, rows: u16) -> MapDefinition {
    let tiles = (0..rows)
        .flat_map(|row| {
            (0..cols).map(move |col| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(i32::from(col), i32::from(row)),
                    vec![TerrainType::Grassland],
                    Vec::new(),
                    0,
                )
                .expect("benchmark tile")
            })
        })
        .collect();
    MapDefinition::try_new(
        format!("benchmark_{cols}x{rows}"),
        GridLayout::OddQFlatTop,
        cols,
        rows,
        tiles,
        Vec::new(),
    )
    .expect("benchmark map")
}

pub(crate) fn movement_state(
    cols: u16,
    rows: u16,
    unit_count: usize,
    actor: &PlayerId,
) -> GameState {
    let mut units = Vec::with_capacity(unit_count);
    units.push(unit(
        "unit-0",
        actor,
        UnitKind::Commander,
        HexCoord::new(0, 0),
        10,
    ));
    let positions = (1..rows).flat_map(|row| {
        (0..cols.saturating_sub(1)).map(move |col| HexCoord::new(i32::from(col), i32::from(row)))
    });
    for (index, position) in positions.take(unit_count.saturating_sub(1)).enumerate() {
        units.push(unit(
            &format!("unit-{}", index + 1),
            actor,
            UnitKind::Warrior,
            position,
            6,
        ));
    }
    assert_eq!(units.len(), unit_count, "benchmark unit count must fit map");
    GameState::try_new(
        StateRevision::new(1),
        1,
        HexGridBounds::new(cols, rows).expect("benchmark bounds"),
        UnitOccupancyPolicy::Exclusive,
        units,
    )
    .expect("benchmark state")
}

pub(crate) fn occupied_target_state(state: &GameState, target: HexCoord) -> GameState {
    let mut units = state.units().to_vec();
    units.push(unit(
        "occupied-target",
        &PlayerId::new("player-2").expect("blocker owner"),
        UnitKind::Warrior,
        target,
        6,
    ));
    GameState::try_new(
        state.revision(),
        state.turn(),
        state.bounds(),
        state.occupancy_policy(),
        units,
    )
    .expect("occupied target state")
}

pub(crate) fn hidden_blocker_state(cols: u16, rows: u16, actor: &PlayerId) -> GameState {
    let units = [
        unit(
            "unit-0",
            actor,
            UnitKind::Commander,
            HexCoord::new(0, 0),
            10,
        ),
        unit(
            "hidden-blocker",
            &PlayerId::new("player-2").expect("blocker owner"),
            UnitKind::Warrior,
            HexCoord::new(1, 0),
            6,
        ),
    ];
    let fog = FogOfWar::try_new([PlayerFog::new(actor.clone(), [], [])]).expect("benchmark fog");
    GameState::builder(
        StateRevision::new(1),
        1,
        HexGridBounds::new(cols, rows).expect("benchmark bounds"),
        UnitOccupancyPolicy::Exclusive,
        units,
    )
    .with_fog_of_war(fog)
    .try_build()
    .expect("hidden blocker state")
}

fn unit(id: &str, owner: &PlayerId, kind: UnitKind, position: HexCoord, movement: u32) -> Unit {
    Unit::builder(
        UnitId::new(id).expect("unit id"),
        owner.clone(),
        kind,
        format!("unit.{id}"),
        position,
        MovementUnits::new(movement),
    )
    .build()
    .expect("unit")
}

pub(crate) fn signed(value: i32) -> u64 {
    i64::from(value).cast_unsigned()
}

pub(crate) fn signature_bytes(bytes: &[u8]) -> u64 {
    bytes.iter().fold(0xcbf2_9ce4_8422_2325, |digest, byte| {
        mix(digest, u64::from(*byte))
    })
}

pub(crate) const fn mix(digest: u64, value: u64) -> u64 {
    (digest ^ value).wrapping_mul(0x0000_0100_0000_01b3)
}
