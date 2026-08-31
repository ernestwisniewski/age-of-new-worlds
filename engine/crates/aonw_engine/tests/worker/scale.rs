use aonw_content::RulesetDefinition;
use aonw_domain::{FieldImprovementKind, HexCoord, InteractionState, TechnologyId, WorkerJob};
use aonw_engine::{
    AssignWorkerToHexCommand, AutomateWorkerCommand, BuildRoadCommand,
    CancelWorkerAssignmentCommand, CancelWorkerJobCommand, CommandRejectionCode,
    ConfirmWorkerImprovementCommand, EngineContext, GameEngine, GameQuery, PlayerCommand,
    QueryResult, SelectWorkerImprovementCommand, WorkerOptionsQuery,
};

use super::support::{city, infrastructure, map, player, state, unit_id, worker};

#[test]
fn all_seven_commands_have_stale_revision_precedence() {
    let map = map(5, 4);
    let actor = player("player-1");
    let worker_id = unit_id("worker-1");
    let target = HexCoord::new(1, 1);
    let base = state(
        &map,
        vec![worker("worker-1", &actor, target, 1)],
        vec![city("city-1", &actor, HexCoord::new(0, 1), [target])],
        infrastructure([]),
        InteractionState::default(),
        &[TechnologyId::Agriculture],
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let commands = [
        PlayerCommand::SelectWorkerImprovement(SelectWorkerImprovementCommand::new(
            8,
            &worker_id,
            FieldImprovementKind::Farm,
        )),
        PlayerCommand::ConfirmWorkerImprovement(ConfirmWorkerImprovementCommand::new(
            8,
            &worker_id,
            Some(FieldImprovementKind::Farm),
        )),
        PlayerCommand::CancelWorkerJob(CancelWorkerJobCommand::new(8, &worker_id)),
        PlayerCommand::AssignWorkerToHex(AssignWorkerToHexCommand::new(8, &worker_id)),
        PlayerCommand::CancelWorkerAssignment(CancelWorkerAssignmentCommand::new(8, &worker_id)),
        PlayerCommand::BuildRoad(BuildRoadCommand::new(8, &worker_id)),
        PlayerCommand::AutomateWorker(AutomateWorkerCommand::new(8, &worker_id)),
    ];
    for command in commands {
        let transition = GameEngine::apply_player_owned(base.clone(), context, command)
            .expect("normal rejection");
        assert_eq!(
            transition.rejection().expect("stale").code(),
            CommandRejectionCode::StaleRevision
        );
        assert_eq!(transition.state(), &base);
    }
}

#[test]
fn large_map_many_worker_planning_stops_at_a_stable_tile_budget() {
    let map = map(40, 30);
    let actor = player("player-1");
    let center = HexCoord::new(0, 0);
    let controlled = super::support::coordinates(40, 30)
        .filter(|coordinate| *coordinate != center)
        .collect::<Vec<_>>();
    let mut units = Vec::with_capacity(controlled.len());
    for (index, coordinate) in controlled.iter().copied().enumerate() {
        let unit = worker(&format!("worker-{index:04}"), &actor, coordinate, 1);
        units.push(if index == 0 {
            unit
        } else {
            unit.with_worker_job(Some(WorkerJob::FieldImprovement {
                target: coordinate,
                improvement: FieldImprovementKind::Farm,
                remaining_turns: 2,
                total_turns: 3,
            }))
        });
    }
    let worker_id = unit_id("worker-0000");
    let base = state(
        &map,
        units,
        vec![city("large-city", &actor, center, controlled)],
        infrastructure([]),
        InteractionState::default(),
        &[TechnologyId::Agriculture],
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let plan = || {
        let QueryResult::WorkerOptions(options) = GameEngine::query(
            &base,
            context,
            GameQuery::WorkerOptions(WorkerOptionsQuery::new(9, &worker_id)),
        )
        .expect("large worker options") else {
            panic!("worker options")
        };
        options.automation().expect("current tile target")
    };
    let first = plan();
    let second = plan();
    assert_eq!(first, second);
    assert_eq!(
        first.metrics().tiles_examined(),
        u32::try_from(40 * 30 - 1).expect("tile count")
    );
    assert!(
        first.metrics().tiles_examined()
            <= RulesetDefinition::standard()
                .worker()
                .automation_tile_budget()
    );
    assert_eq!(first.metrics().routes_planned(), 0);
}
