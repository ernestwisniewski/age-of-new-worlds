use std::collections::BTreeMap;
use std::hint::black_box;

use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{
    City, CityId, FogOfWar, GameMode, GameState, HexCoord, KnowledgeState, MatchIdentity,
    MatchLifecycle, MatchRules, MovementUnits, Participant, PlayerCountry, PlayerFog, PlayerId,
    PlayerKind, PlayerResearchState, PlayerTurnState, ResearchState, StateRevision, TechnologyId,
    TurnLifecycle, Unit, UnitId, UnitKind, UnitOccupancyPolicy, WonderRegistry, WorkerJob,
};
use aonw_engine::{
    AutomateWorkerCommand, EngineContext, GameEngine, GameQuery, PlayerCommand, QueryResult,
    TurnCommand, WorkerAutomationAction, WorkerAutomationMetrics, WorkerOptionsQuery,
};

use super::support::{WorkCounters, mix, report, signature_bytes, signed};

pub(super) fn benchmark(map: &MapDefinition, cols: u16, rows: u16) {
    let actor = PlayerId::new("player-1").expect("actor");
    let worker_id = UnitId::new("worker-0000").expect("worker id");
    let (planning_state, turn_state) = worker_states(map, &actor);
    let unit_count = planning_state.units().len();
    let context = EngineContext::canonical(&actor, map, RulesetDefinition::standard());
    let metrics = automation_metrics(&planning_state, context, &worker_id);
    let counters = WorkCounters::worker(metrics);

    report(
        "worker_options",
        cols,
        rows,
        unit_count,
        counters,
        0,
        || worker_options_signature(black_box(&planning_state), context, &worker_id),
    );
    report(
        "worker_automation_apply",
        cols,
        rows,
        unit_count,
        counters,
        0,
        || {
            GameEngine::apply_player_owned(
                black_box(planning_state.clone()),
                context,
                PlayerCommand::AutomateWorker(AutomateWorkerCommand::new(
                    planning_state.revision().get(),
                    &worker_id,
                )),
            )
            .map_or_else(
                |error| signature_bytes(error.to_string().as_bytes()),
                |transition| u64::from(transition.digest().as_bytes()[0]),
            )
        },
    );
    report(
        "worker_turn_jobs",
        cols,
        rows,
        unit_count,
        WorkCounters::default(),
        0,
        || {
            GameEngine::apply_player_owned(
                black_box(turn_state.clone()),
                context,
                PlayerCommand::EndTurn(TurnCommand::new(turn_state.revision().get(), &actor)),
            )
            .map_or_else(
                |error| signature_bytes(error.to_string().as_bytes()),
                |transition| {
                    mix(
                        mix(
                            u64::try_from(
                                transition
                                    .state()
                                    .infrastructure()
                                    .field_improvements()
                                    .len(),
                            )
                            .unwrap_or(u64::MAX),
                            u64::try_from(transition.events().len()).unwrap_or(u64::MAX),
                        ),
                        u64::from(transition.digest().as_bytes()[0]),
                    )
                },
            )
        },
    );
}

fn automation_metrics(
    state: &GameState,
    context: EngineContext<'_>,
    worker_id: &UnitId,
) -> WorkerAutomationMetrics {
    let Ok(QueryResult::WorkerOptions(options)) = GameEngine::query(
        state,
        context,
        GameQuery::WorkerOptions(WorkerOptionsQuery::new(state.revision().get(), worker_id)),
    ) else {
        return WorkerAutomationMetrics::default();
    };
    options
        .automation()
        .map_or(WorkerAutomationMetrics::default(), |option| {
            option.metrics()
        })
}

fn worker_options_signature(
    state: &GameState,
    context: EngineContext<'_>,
    worker_id: &UnitId,
) -> u64 {
    GameEngine::query(
        state,
        context,
        GameQuery::WorkerOptions(WorkerOptionsQuery::new(state.revision().get(), worker_id)),
    )
    .map_or_else(
        |error| signature_bytes(error.code().as_bytes()),
        |result| {
            let QueryResult::WorkerOptions(options) = result else {
                unreachable!("worker options")
            };
            options.automation().map_or(0, |option| {
                let action = match option.action() {
                    WorkerAutomationAction::Improve(_) => 1,
                    WorkerAutomationAction::Assign => u64::MAX,
                };
                mix(
                    mix(signed(option.target().col()), signed(option.target().row())),
                    mix(
                        action,
                        mix(
                            u64::from(option.metrics().tiles_examined()),
                            u64::from(option.metrics().legality_evaluations()),
                        ),
                    ),
                )
            })
        },
    )
}

fn worker_states(map: &MapDefinition, actor: &PlayerId) -> (GameState, GameState) {
    let center = HexCoord::new(0, 0);
    let controlled = map
        .tiles()
        .iter()
        .map(aonw_content::TileDefinition::coordinate)
        .filter(|coordinate| *coordinate != center)
        .collect::<Vec<_>>();
    let units = controlled
        .iter()
        .copied()
        .enumerate()
        .map(|(index, coordinate)| worker(index, coordinate, actor, index != 0))
        .collect::<Vec<_>>();
    let turn_units = controlled
        .iter()
        .copied()
        .enumerate()
        .map(|(index, coordinate)| worker(index, coordinate, actor, true))
        .collect::<Vec<_>>();
    let city = City::builder(
        CityId::new("worker-city").expect("city id"),
        actor.clone(),
        "Worker benchmark",
        center,
    )
    .with_progression(4, 0, 2_000, 100)
    .with_controlled_hexes(controlled)
    .build()
    .expect("city");
    (
        worker_state(map, actor, units, city.clone()),
        worker_state(map, actor, turn_units, city),
    )
}

fn worker(index: usize, coordinate: HexCoord, actor: &PlayerId, with_job: bool) -> Unit {
    let id = format!("worker-{index:04}");
    let unit = Unit::builder(
        UnitId::new(id.clone()).expect("worker id"),
        actor.clone(),
        UnitKind::Worker,
        id,
        coordinate,
        MovementUnits::new(10),
    )
    .with_worker_build_charges(1)
    .build()
    .expect("worker");
    if with_job {
        unit.with_worker_job(Some(WorkerJob::FieldImprovement {
            target: coordinate,
            improvement: aonw_domain::FieldImprovementKind::Farm,
            remaining_turns: 1,
            total_turns: 3,
        }))
    } else {
        unit
    }
}

fn worker_state(map: &MapDefinition, actor: &PlayerId, units: Vec<Unit>, city: City) -> GameState {
    let participant = Participant::try_new(
        actor.clone(),
        "Player 1",
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Human,
        None,
    )
    .expect("participant");
    let identity = MatchIdentity::try_new(MatchRules::default(), [participant], GameMode::HotSeat)
        .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([(actor.clone(), PlayerTurnState::Active)]),
        [actor.clone()],
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle");
    let research = ResearchState::try_new([(
        actor.clone(),
        PlayerResearchState::try_new([TechnologyId::Agriculture], None, [], 0).expect("research"),
    )])
    .expect("research state");
    let visible = map
        .tiles()
        .iter()
        .map(aonw_content::TileDefinition::coordinate);
    let fog = FogOfWar::try_new([PlayerFog::new(actor.clone(), [], visible)]).expect("fog");
    GameState::builder(
        StateRevision::new(9),
        4,
        map.bounds(),
        UnitOccupancyPolicy::Exclusive,
        units,
    )
    .with_cities([city])
    .with_fog_of_war(fog)
    .with_knowledge(KnowledgeState::new(research, WonderRegistry::default()))
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("worker benchmark state")
}
