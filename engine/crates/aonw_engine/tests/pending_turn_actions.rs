//! Manual turn-work ordering and recipient disclosure from the reference turn reducer.
use aonw_content::RulesetDefinition;
use aonw_domain::{
    City, CityProductionQueue, CityProductionTarget, FogOfWar, GameState, HexCoord,
    InteractionState, KnowledgeState, MovementStep, MovementUnits, PlayerFog, PlayerResearchState,
    QueuedMovePath, ResearchState, UnitKind, WonderRegistry,
};
use aonw_engine::{
    EngineContext, GameEngine, PendingTurnAction, PendingTurnActions, PendingTurnActionsError,
    PendingTurnActionsQuery,
};

#[path = "city/support.rs"]
#[allow(dead_code)]
mod support;
use support::{city_id, map, player, state, unit};

#[test]
fn orders_combat_then_workers_then_other_units_cities_and_research() {
    let map = map(20, 4);
    let actor = player("player-1");
    let world = state(
        &map,
        vec![
            unit("merchant", &actor, UnitKind::Merchant, HexCoord::new(2, 0)),
            unit("far", &actor, UnitKind::Warrior, HexCoord::new(0, 0)),
            unit("worker", &actor, UnitKind::Worker, HexCoord::new(3, 0)),
            unit("near", &actor, UnitKind::Warrior, HexCoord::new(12, 0)),
            unit(
                "foreign",
                &player("player-2"),
                UnitKind::Warrior,
                HexCoord::new(13, 0),
            ),
        ],
        vec![city("idle", "player-1", HexCoord::new(19, 3), false)],
        InteractionState::default(),
    );
    let before = world.clone();
    let result = inspect(&world, &map);
    assert!(result.can_activate);
    assert_eq!(
        targets(&result),
        [
            "unit:near",
            "unit:far",
            "unit:worker",
            "unit:merchant",
            "city:idle",
            "research"
        ]
    );
    assert_eq!(world, before);
}

#[test]
fn hidden_foreign_units_cannot_reorder_manual_work() {
    let map = map(20, 3);
    let actor = player("player-1");
    let world = state(
        &map,
        vec![
            unit("first", &actor, UnitKind::Warrior, HexCoord::new(0, 0)),
            unit("second", &actor, UnitKind::Warrior, HexCoord::new(12, 0)),
            unit(
                "foreign",
                &player("player-2"),
                UnitKind::Warrior,
                HexCoord::new(13, 0),
            ),
        ],
        vec![],
        InteractionState::default(),
    );
    let hidden = rebuild(
        &world,
        FogOfWar::try_new([
            PlayerFog::new(
                actor.clone(),
                [],
                [HexCoord::new(0, 0), HexCoord::new(12, 0)],
            ),
            PlayerFog::new(player("player-2"), [], []),
        ])
        .expect("fog"),
        ResearchState::default(),
    );
    assert_eq!(
        targets(&inspect(&hidden, &map)),
        ["unit:first", "unit:second", "research"]
    );
    let visible = rebuild(
        &world,
        FogOfWar::try_new([
            PlayerFog::new(actor, [], [HexCoord::new(13, 0)]),
            PlayerFog::new(player("player-2"), [], []),
        ])
        .expect("fog"),
        ResearchState::default(),
    );
    assert_eq!(
        targets(&inspect(&visible, &map)),
        ["unit:second", "unit:first", "research"]
    );
    let other = GameEngine::pending_turn_actions(
        &world,
        EngineContext::canonical(&player("player-2"), &map, RulesetDefinition::standard()),
        PendingTurnActionsQuery::new(9),
    )
    .expect("other actor");
    assert_eq!(targets(&other), ["unit:foreign", "research"]);
}

#[test]
fn excludes_exhausted_automated_and_queued_units() {
    let map = map(8, 3);
    let actor = player("player-1");
    let start = HexCoord::new(3, 0);
    let target = HexCoord::new(4, 0);
    let queued = QueuedMovePath::try_new(
        target,
        vec![
            MovementStep::new(start, MovementUnits::ZERO, MovementUnits::ZERO),
            MovementStep::new(target, MovementUnits::new(1), MovementUnits::new(1)),
        ],
    )
    .expect("path");
    let world = state(
        &map,
        vec![
            unit("skipped", &actor, UnitKind::Warrior, HexCoord::new(0, 0)).after_skip_turn(),
            unit("exploring", &actor, UnitKind::Warrior, HexCoord::new(1, 0))
                .after_auto_explore_started(),
            unit("automated", &actor, UnitKind::Worker, HexCoord::new(2, 0))
                .after_worker_automation_started(),
            aonw_domain::Unit::builder(
                support::unit_id("queued"),
                actor.clone(),
                UnitKind::Warrior,
                "queued",
                start,
                MovementUnits::new(10),
            )
            .with_queued_path(Some(queued))
            .build()
            .expect("queued unit"),
            unit("ready", &actor, UnitKind::Worker, HexCoord::new(5, 0)),
        ],
        vec![],
        InteractionState::default(),
    );
    assert_eq!(targets(&inspect(&world, &map)), ["unit:ready", "research"]);
}

#[test]
fn city_work_keeps_canonical_order_and_excludes_foreign_and_active_production() {
    let map = map(10, 3);
    let world = state(
        &map,
        vec![],
        vec![
            city("z", "player-1", HexCoord::new(0, 0), false),
            city("foreign", "player-2", HexCoord::new(3, 0), false),
            city("busy", "player-1", HexCoord::new(5, 0), true),
            city("a", "player-1", HexCoord::new(8, 0), false),
        ],
        InteractionState::default(),
    );
    assert_eq!(
        targets(&inspect(&world, &map)),
        ["city:a", "city:z", "research"]
    );
}

#[test]
fn research_is_absent_when_active_or_no_technology_remains_available() {
    let map = map(3, 3);
    let actor = player("player-1");
    let world = state(
        &map,
        vec![unit("done", &actor, UnitKind::Warrior, HexCoord::new(0, 0)).after_skip_turn()],
        vec![],
        InteractionState::default(),
    );
    let all = RulesetDefinition::standard()
        .technologies()
        .iter()
        .map(|value| value.id())
        .collect::<Vec<_>>();
    for research in [
        PlayerResearchState::try_new([], Some(all[0]), [], 0).expect("active"),
        PlayerResearchState::try_new(all, None, [], 0).expect("completed"),
    ] {
        let changed = rebuild(
            &world,
            FogOfWar::default(),
            ResearchState::try_new([(actor.clone(), research)]).expect("research"),
        );
        let result = inspect(&changed, &map);
        assert!(result.actions.is_empty());
        assert!(result.can_activate);
    }
}

#[test]
fn rejects_stale_revisions_and_nonparticipants() {
    let map = map(2, 2);
    let actor = player("player-1");
    let world = state(
        &map,
        vec![unit("unit", &actor, UnitKind::Warrior, HexCoord::new(0, 0))],
        vec![],
        InteractionState::default(),
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    assert_eq!(
        GameEngine::pending_turn_actions(&world, context, PendingTurnActionsQuery::new(8)),
        Err(PendingTurnActionsError::StaleRevision)
    );
    assert_eq!(
        GameEngine::pending_turn_actions(
            &world,
            EngineContext::canonical(&player("outsider"), &map, RulesetDefinition::standard()),
            PendingTurnActionsQuery::new(9)
        ),
        Err(PendingTurnActionsError::PlayerNotInMatch)
    );
}

#[test]
fn inactive_submitted_removed_and_terminal_players_cannot_activate_work() {
    use aonw_domain::{
        GameOutcome, GameOutcomeCondition, MatchLifecycle, PlayerTurnState, TurnLifecycle,
    };
    let map = map(2, 2);
    let actor = player("player-1");
    let world = state(
        &map,
        vec![unit("unit", &actor, UnitKind::Warrior, HexCoord::new(0, 0))],
        vec![],
        InteractionState::default(),
    );
    for (status, submitted, removed) in [
        (PlayerTurnState::Finished, false, false),
        (PlayerTurnState::Finished, true, false),
        (PlayerTurnState::Finished, false, true),
    ] {
        let identity = world.match_lifecycle().identity().clone();
        let turn = TurnLifecycle::try_new(
            &identity,
            [(actor.clone(), status)].into_iter().collect(),
            if removed { vec![] } else { vec![actor.clone()] },
            if submitted {
                vec![actor.clone()]
            } else {
                vec![]
            },
            std::collections::BTreeMap::default(),
            [],
            if removed { vec![actor.clone()] } else { vec![] },
            None,
        )
        .expect("turn");
        let changed = builder(&world)
            .with_match_lifecycle(MatchLifecycle::new(identity, turn))
            .try_build()
            .expect("inactive state");
        let result = inspect(&changed, &map);
        assert!(!result.can_activate);
        assert!(!result.actions.is_empty());
    }
    let outcome = GameOutcome::try_new(
        world.match_lifecycle().identity(),
        GameOutcomeCondition::Draw,
        None,
        std::collections::BTreeMap::default(),
    )
    .expect("outcome");
    let finished = builder(&world)
        .with_outcome(outcome)
        .try_build()
        .expect("finished state");
    assert!(!inspect(&finished, &map).can_activate);
}

fn inspect(world: &GameState, map: &aonw_content::MapDefinition) -> PendingTurnActions {
    GameEngine::pending_turn_actions(
        world,
        EngineContext::canonical(&player("player-1"), map, RulesetDefinition::standard()),
        PendingTurnActionsQuery::new(9),
    )
    .expect("pending work")
}
fn targets(result: &PendingTurnActions) -> Vec<String> {
    result
        .actions
        .iter()
        .map(|value| match value {
            PendingTurnAction::Unit { unit_id, .. } => format!("unit:{}", unit_id.as_str()),
            PendingTurnAction::CityProduction { city_id, .. } => {
                format!("city:{}", city_id.as_str())
            }
            PendingTurnAction::Research => "research".to_owned(),
        })
        .collect()
}
fn city(id: &str, owner: &str, position: HexCoord, busy: bool) -> City {
    City::builder(city_id(id), player(owner), id, position)
        .with_production(
            busy.then(|| {
                CityProductionQueue::try_new(
                    CityProductionTarget::Unit(UnitKind::Warrior),
                    0,
                    aonw_domain::StrategicResourceStockpile::default(),
                )
                .expect("production")
            }),
            0,
        )
        .build()
        .expect("city")
}
fn rebuild(world: &GameState, fog: FogOfWar, research: ResearchState) -> GameState {
    builder(world)
        .with_knowledge(KnowledgeState::new(research, WonderRegistry::default()))
        .with_fog_of_war(fog)
        .try_build()
        .expect("changed state")
}

fn builder(world: &GameState) -> aonw_domain::GameStateBuilder {
    GameState::builder(
        world.revision(),
        world.turn(),
        world.bounds(),
        world.occupancy_policy(),
        world.units().to_vec(),
    )
    .with_match_lifecycle(world.match_lifecycle().clone())
    .with_cities(world.cities().to_vec())
}
