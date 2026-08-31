//! Canonical worker, automation, and infrastructure acceptance tests.

use aonw_content::RulesetDefinition;
use aonw_domain::{
    FieldImprovement, FieldImprovementKind, HexCoord, InteractionState, MovementUnits,
    PendingInteraction, TechnologyId, UnitPosture, WorkerJob,
};
use aonw_engine::{
    AssignWorkerToHexCommand, AutomateWorkerCommand, BuildRoadCommand,
    CancelWorkerAssignmentCommand, CancelWorkerJobCommand, CommandRejectionCode,
    ConfirmWorkerImprovementCommand, DomainEvent, EngineContext, ExecutionEvidence, GameEngine,
    GameQuery, PlayerCommand, QueryResult, SelectWorkerImprovementCommand, TerrainMovementQuery,
    TurnCommand, WorkerAutomationAction, WorkerOptionsQuery,
};

#[path = "worker/manifest.rs"]
mod manifest;
#[path = "worker/scale.rs"]
mod scale;
#[path = "worker/support.rs"]
mod support;

use support::{city, infrastructure, map, player, state, unit_id, worker};

#[test]
fn query_select_confirm_and_cancel_share_one_technology_gated_rule_path() {
    let map = map(6, 4);
    let actor = player("player-1");
    let worker_id = unit_id("worker-1");
    let target = HexCoord::new(1, 1);
    let owned_city = city("city-1", &actor, HexCoord::new(0, 1), [target]);
    let base = state(
        &map,
        vec![worker("worker-1", &actor, target, 2)],
        vec![owned_city.clone()],
        infrastructure([]),
        InteractionState::default(),
        &[TechnologyId::Agriculture],
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    assert_options_and_technology_gate(&base, context, &worker_id);

    let selected = GameEngine::apply_player_owned(
        base.clone(),
        context,
        PlayerCommand::SelectWorkerImprovement(SelectWorkerImprovementCommand::new(
            9,
            &worker_id,
            FieldImprovementKind::Farm,
        )),
    )
    .expect("select improvement");
    let selected_worker = selected.state().unit(&worker_id).expect("worker remains");
    assert_eq!(selected_worker.movement_units(), MovementUnits::ZERO);
    assert!(matches!(
        selected_worker.activity().worker_job(),
        Some(WorkerJob::FieldImprovement {
            improvement: FieldImprovementKind::Farm,
            ..
        })
    ));

    let cancelled = GameEngine::apply_player_owned(
        selected.into_parts().state,
        context,
        PlayerCommand::CancelWorkerJob(CancelWorkerJobCommand::new(10, &worker_id)),
    )
    .expect("cancel job");
    assert!(
        cancelled
            .state()
            .unit(&worker_id)
            .expect("worker")
            .activity()
            .worker_job()
            .is_none()
    );

    let pending = InteractionState::new(
        None,
        Some(PendingInteraction::WorkerActionSelection {
            owner_player_id: actor.clone(),
            unit_id: worker_id.clone(),
            improvement: Some(FieldImprovementKind::Farm),
        }),
    );
    let foreign = player("player-2");
    let foreign_city = city("city-2", &foreign, HexCoord::new(5, 3), []);
    let confirm_state = state(
        &map,
        vec![worker("worker-1", &actor, target, 1)],
        vec![owned_city, foreign_city],
        infrastructure([]),
        pending,
        &[TechnologyId::Agriculture],
    );
    let foreign_context = EngineContext::canonical(&foreign, &map, RulesetDefinition::standard());
    let rejected = GameEngine::apply_player_owned(
        confirm_state.clone(),
        foreign_context,
        PlayerCommand::ConfirmWorkerImprovement(ConfirmWorkerImprovementCommand::new(
            9, &worker_id, None,
        )),
    )
    .expect("foreign pending rejection");
    assert_eq!(
        rejected.rejection().expect("pending owner").code(),
        CommandRejectionCode::WorkerActionNotControlled
    );
    assert_eq!(rejected.state(), &confirm_state);
    let confirmed = GameEngine::apply_player_owned(
        confirm_state,
        context,
        PlayerCommand::ConfirmWorkerImprovement(ConfirmWorkerImprovementCommand::new(
            9, &worker_id, None,
        )),
    )
    .expect("confirm pending improvement");
    assert!(confirmed.is_accepted());
    assert!(confirmed.state().interaction().pending().is_none());
}

#[test]
fn assignment_cancel_and_road_cover_the_remaining_manual_commands() {
    let map = map(6, 4);
    let actor = player("player-1");
    let worker_id = unit_id("worker-1");
    let target = HexCoord::new(1, 1);
    let owned_city = city("city-1", &actor, HexCoord::new(0, 1), [target]);
    let improved = FieldImprovement::new(target, FieldImprovementKind::Farm, None);
    let base = state(
        &map,
        vec![worker("worker-1", &actor, target, 1)],
        vec![owned_city.clone()],
        infrastructure([improved]),
        InteractionState::default(),
        &[TechnologyId::Agriculture],
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());

    let assigned = GameEngine::apply_player_owned(
        base,
        context,
        PlayerCommand::AssignWorkerToHex(AssignWorkerToHexCommand::new(9, &worker_id)),
    )
    .expect("assign worker");
    assert_eq!(
        assigned
            .state()
            .unit(&worker_id)
            .expect("worker")
            .activity()
            .worker_assignment(),
        Some(target)
    );
    let unassigned = GameEngine::apply_player_owned(
        assigned.into_parts().state,
        context,
        PlayerCommand::CancelWorkerAssignment(CancelWorkerAssignmentCommand::new(10, &worker_id)),
    )
    .expect("cancel assignment");
    assert!(
        unassigned
            .state()
            .unit(&worker_id)
            .expect("worker")
            .activity()
            .worker_assignment()
            .is_none()
    );

    let road_state = state(
        &map,
        vec![worker("worker-1", &actor, target, 1)],
        vec![owned_city],
        infrastructure([]),
        InteractionState::default(),
        &[TechnologyId::Agriculture],
    );
    let road = GameEngine::apply_player_owned(
        road_state,
        context,
        PlayerCommand::BuildRoad(BuildRoadCommand::new(9, &worker_id)),
    )
    .expect("build road");
    assert!(matches!(
        road.state()
            .unit(&worker_id)
            .expect("worker")
            .activity()
            .worker_job(),
        Some(WorkerJob::RoadConstruction { .. })
    ));

    let foreign = player("player-2");
    let foreign_state = state(
        &map,
        vec![worker("worker-1", &actor, target, 1)],
        vec![city(
            "foreign-city",
            &foreign,
            HexCoord::new(2, 1),
            [target],
        )],
        infrastructure([]),
        InteractionState::default(),
        &[TechnologyId::Agriculture],
    );
    let rejected = GameEngine::apply_player_owned(
        foreign_state,
        context,
        PlayerCommand::BuildRoad(BuildRoadCommand::new(9, &worker_id)),
    )
    .expect("foreign road rejection");
    assert_eq!(
        rejected.rejection().expect("foreign road").code(),
        CommandRejectionCode::RoadConstructionEnemyTerritory
    );
}

#[test]
fn assignment_capacity_is_enforced_across_one_city() {
    let map = map(6, 4);
    let actor = player("player-1");
    let candidate = HexCoord::new(1, 1);
    let assigned_a = HexCoord::new(2, 1);
    let assigned_b = HexCoord::new(3, 1);
    let worker_id = unit_id("candidate");
    let base = state(
        &map,
        vec![
            worker("candidate", &actor, candidate, 0),
            worker("assigned-a", &actor, assigned_a, 0).after_worker_assigned(assigned_a),
            worker("assigned-b", &actor, assigned_b, 0).after_worker_assigned(assigned_b),
        ],
        vec![city(
            "city-1",
            &actor,
            HexCoord::new(0, 1),
            [candidate, assigned_a, assigned_b],
        )],
        infrastructure([
            FieldImprovement::new(candidate, FieldImprovementKind::Farm, None),
            FieldImprovement::new(assigned_a, FieldImprovementKind::Farm, None),
            FieldImprovement::new(assigned_b, FieldImprovementKind::Farm, None),
        ]),
        InteractionState::default(),
        &[TechnologyId::Agriculture],
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let rejected = GameEngine::apply_player_owned(
        base.clone(),
        context,
        PlayerCommand::AssignWorkerToHex(AssignWorkerToHexCommand::new(9, &worker_id)),
    )
    .expect("assignment capacity rejection");
    assert_eq!(
        rejected.rejection().expect("assignment capacity").code(),
        CommandRejectionCode::WorkerAssignmentUnavailable
    );
    assert_eq!(rejected.state(), &base);
}

#[test]
fn automation_is_deterministic_bounded_and_falls_back_to_assignment() {
    let map = map(7, 4);
    let actor = player("player-1");
    let worker_id = unit_id("worker-1");
    let from = HexCoord::new(1, 1);
    let target = HexCoord::new(2, 1);
    let city = city(
        "city-1",
        &actor,
        HexCoord::new(0, 1),
        [from, target, HexCoord::new(3, 1)],
    );
    let base = state(
        &map,
        vec![worker("worker-1", &actor, from, 0)],
        vec![city],
        infrastructure([FieldImprovement::new(
            target,
            FieldImprovementKind::Farm,
            None,
        )]),
        InteractionState::default(),
        &[TechnologyId::Agriculture],
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let query = || {
        let QueryResult::WorkerOptions(options) = GameEngine::query(
            &base,
            context,
            GameQuery::WorkerOptions(WorkerOptionsQuery::new(9, &worker_id)),
        )
        .expect("worker options") else {
            panic!("worker options")
        };
        options.automation().expect("assignment target")
    };
    let first = query();
    let second = query();
    assert_eq!(first, second);
    assert_eq!(first.target(), target);
    assert_eq!(first.action(), WorkerAutomationAction::Assign);
    assert!(
        first.metrics().tiles_examined()
            <= RulesetDefinition::standard()
                .worker()
                .automation_tile_budget()
    );
    assert!(
        first.metrics().legality_evaluations()
            <= RulesetDefinition::standard()
                .worker()
                .automation_legality_budget()
    );

    let automated = GameEngine::apply_player_owned(
        base,
        context,
        PlayerCommand::AutomateWorker(AutomateWorkerCommand::new(9, &worker_id)),
    )
    .expect("automate worker");
    assert!(automated.is_accepted());
    assert_eq!(
        automated
            .state()
            .unit(&worker_id)
            .expect("worker")
            .posture(),
        UnitPosture::AutoWorking
    );
    let Some(ExecutionEvidence::WorkerAutomation(execution)) = automated.evidence() else {
        panic!("worker automation evidence")
    };
    assert_eq!(execution.option(), first);
}

#[test]
fn turn_completion_emits_typed_events_updates_infrastructure_and_changes_routing() {
    let map = map(6, 4);
    let actor = player("player-1");
    let farm_target = HexCoord::new(2, 1);
    let road_target = HexCoord::new(1, 1);
    let center = HexCoord::new(0, 1);
    let city = city("city-1", &actor, center, [road_target, farm_target]);
    let farm_worker = worker("farm-worker", &actor, farm_target, 2).with_worker_job(Some(
        WorkerJob::FieldImprovement {
            target: farm_target,
            improvement: FieldImprovementKind::Farm,
            remaining_turns: 1,
            total_turns: 3,
        },
    ));
    let road_worker = worker("road-worker", &actor, road_target, 1).with_worker_job(Some(
        WorkerJob::RoadConstruction {
            target: road_target,
            remaining_turns: 1,
            total_turns: 2,
        },
    ));
    let base = state(
        &map,
        vec![farm_worker, road_worker],
        vec![city],
        infrastructure([]),
        InteractionState::default(),
        &[TechnologyId::Agriculture],
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let transition = GameEngine::apply_player_owned(
        base,
        context,
        PlayerCommand::EndTurn(TurnCommand::new(9, &actor)),
    )
    .expect("end turn");
    assert!(transition.is_accepted());
    assert!(
        transition
            .state()
            .infrastructure()
            .field_improvement_at(farm_target)
            .is_some()
    );
    assert!(
        transition
            .state()
            .transport_network()
            .at(road_target)
            .is_some()
    );
    assert!(
        !transition
            .state()
            .transport_network()
            .routing_fingerprint()
            .is_empty()
    );
    assert!(matches!(
        transition.events(),
        [
            DomainEvent::WorkerCompletedJob(_),
            DomainEvent::WorkerCompletedJob(_),
            DomainEvent::ResearchPointsGained(_),
            DomainEvent::TurnEnded(_)
        ]
    ));
    assert_eq!(
        transition
            .state()
            .unit(&unit_id("farm-worker"))
            .expect("farm worker remains")
            .worker_build_charges(),
        1
    );
    assert_road_reduces_route_cost(&map, &actor, road_target, center, transition.state());
}

fn assert_options_and_technology_gate(
    base: &aonw_domain::GameState,
    context: EngineContext<'_>,
    worker_id: &aonw_domain::UnitId,
) {
    let QueryResult::WorkerOptions(options) = GameEngine::query(
        base,
        context,
        GameQuery::WorkerOptions(WorkerOptionsQuery::new(9, worker_id)),
    )
    .expect("worker options") else {
        panic!("worker options result")
    };
    assert_eq!(options.unit_id(), worker_id);
    assert_eq!(
        options
            .improvements()
            .iter()
            .map(|option| option.kind())
            .collect::<Vec<_>>(),
        [FieldImprovementKind::Farm]
    );
    assert!(options.can_build_road());
    let locked = GameEngine::apply_player_owned(
        base.clone(),
        context,
        PlayerCommand::SelectWorkerImprovement(SelectWorkerImprovementCommand::new(
            9,
            worker_id,
            FieldImprovementKind::Mine,
        )),
    )
    .expect("normal rejection");
    assert_eq!(
        locked.rejection().expect("technology rejection").code(),
        CommandRejectionCode::WorkerImprovementUnavailable
    );
}

fn assert_road_reduces_route_cost(
    map: &aonw_content::MapDefinition,
    actor: &aonw_domain::PlayerId,
    road_target: HexCoord,
    center: HexCoord,
    road_state: &aonw_domain::GameState,
) {
    let idle_baseline = state(
        map,
        vec![worker("road-worker", actor, road_target, 1)],
        vec![city("city-1", actor, center, [road_target])],
        infrastructure([]),
        InteractionState::default(),
        &[TechnologyId::Agriculture],
    );
    let context = EngineContext::canonical(actor, map, RulesetDefinition::standard());
    let QueryResult::Route(before) = GameEngine::query(
        &idle_baseline,
        context,
        GameQuery::PlanRoute(TerrainMovementQuery::new(
            9,
            &unit_id("road-worker"),
            center,
        )),
    )
    .expect("baseline route") else {
        panic!("route")
    };
    let QueryResult::Route(after) = GameEngine::query(
        road_state,
        context,
        GameQuery::PlanRoute(TerrainMovementQuery::new(
            10,
            &unit_id("road-worker"),
            center,
        )),
    )
    .expect("road route") else {
        panic!("route")
    };
    assert!(after.total_cost() < before.total_cost());
}
