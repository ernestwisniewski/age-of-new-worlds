use super::support::{city, infrastructure, map, player, state, unit_id, worker};
use aonw_content::RulesetDefinition;
use aonw_domain::{FieldImprovementKind, HexCoord, InteractionState, TechnologyId, WorkerJob};
use aonw_engine::{
    DomainEvent, EngineContext, GameEngine, GameQuery, PlayerCommand, QueryResult,
    TerrainMovementQuery, TurnCommand,
};

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
            DomainEvent::WorkerCompletedJob(farm),
            DomainEvent::WorkerCompletedJob(road),
            DomainEvent::ResearchPointsGained(_),
            DomainEvent::TurnEnded(_)
        ] if farm.yield_delta() == aonw_engine::YieldValue::new(1, 0, 0, 0)
            && road.yield_delta() == aonw_engine::YieldValue::default()
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
