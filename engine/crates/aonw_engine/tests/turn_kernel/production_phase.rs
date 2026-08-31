use std::collections::{BTreeMap, BTreeSet};

use aonw_content::RulesetDefinition;
use aonw_domain::{
    City, CityBuildingType, CityId, CityProductionQueue, CityProductionTarget, CityProjectType,
    GameMode, GameState, HexCoord, KnowledgeState, MatchIdentity, MatchLifecycle, MatchRules,
    MovementUnits, PaceProfile, PlayerId, PlayerResearchState, PlayerTurnState, ResearchState,
    StateRevision, StrategicResourceStockpile, TurnLifecycle, Unit, UnitId, UnitKind,
    UnitOccupancyPolicy, WonderRegistry, WonderType,
};
use aonw_engine::{
    DomainEvent, EngineContext, ExecutionEvidence, GameEngine, PlayerCommand, TurnCommand,
    TurnProcessor,
};

use super::{map, participant, player};

#[test]
fn sequential_turn_completes_building_and_wealth_project_in_phase_order() {
    let ruleset = RulesetDefinition::standard();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let building_cost = building_cost(ruleset, CityBuildingType::Granary);
    let building_state = production_state(
        GameMode::HotSeat,
        [],
        [city(
            "city-2",
            &p2,
            1,
            CityProductionTarget::Building(CityBuildingType::Granary),
            building_cost,
        )],
        UnitOccupancyPolicy::Exclusive,
    );
    let completed = GameEngine::apply_player_owned(
        building_state,
        EngineContext::canonical(&p1, &map(), ruleset),
        PlayerCommand::EndTurn(TurnCommand::new(7, &p1)),
    )
    .expect("building turn");
    assert!(completed.is_accepted());
    assert!(matches!(
        completed.events(),
        [
            DomainEvent::CityBuiltBuilding(_),
            DomainEvent::ResearchPointsGained(_),
            DomainEvent::TurnEnded(_)
        ]
    ));
    let completed_city = completed
        .state()
        .city(&CityId::new("city-2").expect("city id"))
        .expect("completed city");
    assert!(
        completed_city
            .buildings()
            .contains(&CityBuildingType::Granary)
    );
    assert!(completed_city.production_queue().is_none());
    assert_production_evidence(&completed);

    let project_state = production_state(
        GameMode::HotSeat,
        [],
        [city(
            "city-2",
            &p2,
            1,
            CityProductionTarget::Project(CityProjectType::Wealth),
            0,
        )],
        UnitOccupancyPolicy::Exclusive,
    );
    let project = GameEngine::apply_player_owned(
        project_state,
        EngineContext::canonical(&p1, &map(), ruleset),
        PlayerCommand::EndTurn(TurnCommand::new(7, &p1)),
    )
    .expect("wealth turn");
    assert!(project.is_accepted());
    assert_eq!(project.state().economy().player_gold().get(&p2), Some(&1));
    assert!(matches!(
        project.events(),
        [
            DomainEvent::ResearchPointsGained(_),
            DomainEvent::TurnEnded(_)
        ]
    ));
}

#[test]
fn unit_completion_uses_stable_identity_and_occupancy() {
    let ruleset = RulesetDefinition::standard();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let cost = unit_cost(ruleset, UnitKind::Merchant);
    let state = production_state(
        GameMode::HotSeat,
        [],
        [city(
            "city-2",
            &p2,
            1,
            CityProductionTarget::Unit(UnitKind::Merchant),
            cost,
        )],
        UnitOccupancyPolicy::FriendlyStacking,
    );
    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&p1, &map(), ruleset),
        PlayerCommand::EndTurn(TurnCommand::new(7, &p1)),
    )
    .expect("unit turn");
    assert!(transition.is_accepted());
    let DomainEvent::CityProducedUnit(event) = &transition.events()[0] else {
        panic!("unit completion event must precede lifecycle event")
    };
    assert_eq!(event.unit(), UnitKind::Merchant);
    assert_eq!(event.produced_unit_id().as_str(), "city-2_merchant_1");
    let produced = transition
        .state()
        .unit(event.produced_unit_id())
        .expect("produced unit");
    assert_eq!(produced.position(), HexCoord::new(1, 0));
    assert!(
        transition
            .state()
            .city(&CityId::new("city-2").expect("city id"))
            .expect("city")
            .production_queue()
            .is_none()
    );
}

#[test]
fn finite_production_keeps_partial_progress_and_skips_idle_cities() {
    let ruleset = RulesetDefinition::standard();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let state = production_state(
        GameMode::HotSeat,
        [],
        [
            idle_city("city-idle", &p2, 0),
            city(
                "city-2",
                &p2,
                1,
                CityProductionTarget::Building(CityBuildingType::Granary),
                0,
            ),
        ],
        UnitOccupancyPolicy::Exclusive,
    );
    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&p1, &map(), ruleset),
        PlayerCommand::EndTurn(TurnCommand::new(7, &p1)),
    )
    .expect("partial production turn");
    assert!(transition.is_accepted());
    assert!(matches!(
        transition.events(),
        [
            DomainEvent::ResearchPointsGained(_),
            DomainEvent::DominationThresholdReached(_),
            DomainEvent::TurnEnded(_)
        ]
    ));
    let queue = transition
        .state()
        .city(&CityId::new("city-2").expect("city id"))
        .expect("producing city")
        .production_queue()
        .expect("partial queue");
    assert_eq!(queue.invested_production(), 1);
    assert_eq!(
        queue.target(),
        CityProductionTarget::Building(CityBuildingType::Granary)
    );
}

#[test]
fn blocked_unit_spawn_preserves_the_completed_queue() {
    let ruleset = RulesetDefinition::standard();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let cost = unit_cost(ruleset, UnitKind::Merchant);
    let state = production_state(
        GameMode::HotSeat,
        [],
        [city(
            "city-2",
            &p2,
            1,
            CityProductionTarget::Unit(UnitKind::Merchant),
            cost,
        )],
        UnitOccupancyPolicy::Exclusive,
    );
    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&p1, &map(), ruleset),
        PlayerCommand::EndTurn(TurnCommand::new(7, &p1)),
    )
    .expect("blocked unit turn");
    assert!(transition.is_accepted());
    assert!(matches!(
        transition.events(),
        [
            DomainEvent::ResearchPointsGained(_),
            DomainEvent::TurnEnded(_)
        ]
    ));
    assert_eq!(transition.state().units().len(), 2);
    let queue = transition
        .state()
        .city(&CityId::new("city-2").expect("city id"))
        .expect("blocked city")
        .production_queue()
        .expect("completed queue remains pending");
    assert_eq!(queue.invested_production(), cost);
}

#[test]
fn simultaneous_wonder_race_uses_scope_order_and_refunds_loser() {
    let ruleset = RulesetDefinition::standard();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let cost = wonder_cost(ruleset, WonderType::GreatWall);
    let state = production_state(
        GameMode::Multiplayer,
        [p1.clone()],
        [
            city(
                "city-1",
                &p1,
                0,
                CityProductionTarget::Wonder(WonderType::GreatWall),
                cost,
            ),
            city(
                "city-2",
                &p2,
                1,
                CityProductionTarget::Wonder(WonderType::GreatWall),
                cost,
            ),
        ],
        UnitOccupancyPolicy::Exclusive,
    );
    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&p2, &map(), ruleset),
        PlayerCommand::SubmitTurn(TurnCommand::new(7, &p2)),
    )
    .expect("wonder turn");
    assert!(transition.is_accepted());
    assert!(matches!(
        transition.events(),
        [
            DomainEvent::AllPlayersSubmitted(_),
            DomainEvent::CityBuiltWonder(_),
            DomainEvent::WonderProductionRefunded(_),
            DomainEvent::ResearchPointsGained(_),
            DomainEvent::ResearchPointsGained(_),
            DomainEvent::TurnEnded(_),
            DomainEvent::TurnEnded(_)
        ]
    ));
    assert_eq!(
        transition
            .state()
            .wonder_registry()
            .completed_by()
            .get(&WonderType::GreatWall),
        Some(&p1)
    );
    let loser = transition
        .state()
        .city(&CityId::new("city-2").expect("city id"))
        .expect("losing city");
    assert!(loser.production_queue().is_none());
    assert_eq!(loser.production_overflow(), cost);
}

pub(super) fn production_state(
    mode: GameMode,
    submitted: impl IntoIterator<Item = PlayerId>,
    cities: impl IntoIterator<Item = City>,
    occupancy: UnitOccupancyPolicy,
) -> GameState {
    production_state_with_knowledge(mode, submitted, cities, occupancy, None)
}

#[allow(clippy::too_many_arguments)]
pub(super) fn production_state_with_research(
    mode: GameMode,
    submitted: impl IntoIterator<Item = PlayerId>,
    cities: impl IntoIterator<Item = City>,
    occupancy: UnitOccupancyPolicy,
    player: &PlayerId,
    research: PlayerResearchState,
) -> GameState {
    let state = ResearchState::try_new([(player.clone(), research)]).expect("research state");
    production_state_with_knowledge(
        mode,
        submitted,
        cities,
        occupancy,
        Some(KnowledgeState::new(state, WonderRegistry::default())),
    )
}

fn production_state_with_knowledge(
    mode: GameMode,
    submitted: impl IntoIterator<Item = PlayerId>,
    cities: impl IntoIterator<Item = City>,
    occupancy: UnitOccupancyPolicy,
    knowledge: Option<KnowledgeState>,
) -> GameState {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [
            participant(p1.clone(), "One"),
            participant(p2.clone(), "Two"),
        ],
        mode,
    )
    .expect("identity");
    let submitted = submitted.into_iter().collect::<BTreeSet<_>>();
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (
                p1.clone(),
                if submitted.contains(&p1) {
                    PlayerTurnState::Finished
                } else {
                    PlayerTurnState::Active
                },
            ),
            (
                p2.clone(),
                if submitted.contains(&p2) {
                    PlayerTurnState::Finished
                } else {
                    PlayerTurnState::Active
                },
            ),
        ]),
        [p1.clone(), p2.clone()],
        submitted,
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle");
    let builder = GameState::builder(
        StateRevision::new(7),
        7,
        map().bounds(),
        occupancy,
        [unit("unit-1", p1, 0), unit("unit-2", p2, 1)],
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .with_cities(cities);
    let builder = if let Some(knowledge) = knowledge {
        builder.with_knowledge(knowledge)
    } else {
        builder
    };
    builder.try_build().expect("state")
}

pub(super) fn city(
    id: &str,
    owner: &PlayerId,
    column: i32,
    target: CityProductionTarget,
    invested: i64,
) -> City {
    City::builder(
        CityId::new(id).expect("city id"),
        owner.clone(),
        id,
        HexCoord::new(column, 0),
    )
    .with_production(
        Some(
            CityProductionQueue::try_new(target, invested, StrategicResourceStockpile::default())
                .expect("queue"),
        ),
        0,
    )
    .build()
    .expect("city")
}

fn idle_city(id: &str, owner: &PlayerId, column: i32) -> City {
    City::builder(
        CityId::new(id).expect("city id"),
        owner.clone(),
        id,
        HexCoord::new(column, 0),
    )
    .build()
    .expect("city")
}

fn unit(id: &str, owner: PlayerId, column: i32) -> Unit {
    Unit::builder(
        UnitId::new(id).expect("unit id"),
        owner,
        UnitKind::Commander,
        id,
        HexCoord::new(column, 0),
        MovementUnits::ZERO,
    )
    .build()
    .expect("unit")
}

fn building_cost(ruleset: &RulesetDefinition, building: CityBuildingType) -> i64 {
    let definition = ruleset
        .production()
        .building(building)
        .expect("building definition");
    ruleset
        .production()
        .building_cost(definition.base_cost(), PaceProfile::Unlimited)
        .expect("building cost")
}

fn unit_cost(ruleset: &RulesetDefinition, kind: UnitKind) -> i64 {
    let definition = ruleset.production().unit(kind).expect("unit definition");
    ruleset
        .production()
        .unit_cost(definition.base_cost(), PaceProfile::Unlimited)
        .expect("unit cost")
}

pub(super) fn wonder_cost(ruleset: &RulesetDefinition, wonder: WonderType) -> i64 {
    let definition = ruleset
        .production()
        .wonder(wonder)
        .expect("wonder definition");
    ruleset
        .production()
        .building_cost(definition.base_cost(), PaceProfile::Unlimited)
        .expect("wonder cost")
}

fn assert_production_evidence(transition: &aonw_engine::DomainTransition) {
    let Some(ExecutionEvidence::TurnKernel(evidence)) = transition.evidence() else {
        panic!("turn evidence")
    };
    assert!(evidence.processors().contains(&TurnProcessor::Production));
}
