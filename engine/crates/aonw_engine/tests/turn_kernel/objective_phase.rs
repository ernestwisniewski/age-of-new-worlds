//! Exact authored-objective, domination, and cultural turn progression.

use std::collections::BTreeMap;

use aonw_content::{
    GridLayout, MapDefinition, MapObjective, MapObjectiveType, RulesetDefinition, TerrainType,
    TileDefinition,
};
use aonw_domain::{
    ArtifactId, City, CityId, EconomyState, GameLengthConfig, GameMode, GameState, HexCoord,
    InitialResourceDistribution, MapObjectiveHoldState, MatchIdentity, MatchLifecycle, MatchRules,
    ObjectiveState, PlayerId, PlayerTurnState, RuleNumber, StateRevision, TurnLifecycle,
    UnitOccupancyPolicy, VictoryRules, WorldArtifact, WorldArtifactLocation, WorldArtifactType,
};
use aonw_engine::{DomainEvent, EngineContext, GameEngine, PlayerCommand, TurnCommand};

use super::{participant, player, unit};

#[test]
fn map_objective_crossing_is_atomic_ordered_and_paid_only_for_the_scope() {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let objective = MapObjective::try_new(
        "central-ruins",
        MapObjectiveType::Ruins,
        HexCoord::new(0, 0),
        2,
        5,
        3,
    )
    .expect("objective");
    let map = map(2, vec![objective]);
    let identity = identity(MatchRules::default(), &p1, &p2);
    let economy = EconomyState::try_new(
        &identity,
        map.bounds(),
        BTreeMap::from([(p2.clone(), 4)]),
        BTreeMap::new(),
        BTreeMap::new(),
        BTreeMap::new(),
        InitialResourceDistribution::default(),
    )
    .expect("economy");
    let objectives = ObjectiveState::try_new(
        &identity,
        BTreeMap::new(),
        BTreeMap::new(),
        [
            MapObjectiveHoldState::try_new("central-ruins".to_owned(), p2.clone(), 1)
                .expect("hold"),
        ],
    )
    .expect("objectives");
    let state = state(&map, identity, &p1, &p2, [], [], economy, objectives);

    let transition = finalize(state, &map, &p2);

    assert!(matches!(
        transition.events(),
        [
            DomainEvent::AllPlayersSubmitted(_),
            DomainEvent::MapObjectiveSecured(_),
            DomainEvent::TurnEnded(_),
            DomainEvent::TurnEnded(_)
        ]
    ));
    let hold = &transition.state().objectives().map_objective_hold_states()[0];
    assert_eq!(hold.player_id(), &p2);
    assert_eq!(hold.hold_turns(), 2);
    assert_eq!(
        transition.state().economy().player_gold().get(&p2),
        Some(&7)
    );

    let partial = GameEngine::apply_player_owned(
        transition.state().clone(),
        EngineContext::canonical(&p1, &map, RulesetDefinition::standard()),
        PlayerCommand::SubmitTurn(TurnCommand::new(8, &p1)),
    )
    .expect("partial next turn");
    let next = GameEngine::apply_player_owned(
        partial.state().clone(),
        EngineContext::canonical(&p2, &map, RulesetDefinition::standard()),
        PlayerCommand::SubmitTurn(TurnCommand::new(9, &p2)),
    )
    .expect("final next turn");
    assert!(
        !next
            .events()
            .iter()
            .any(|event| matches!(event, DomainEvent::MapObjectiveSecured(_)))
    );
    assert_eq!(next.state().economy().player_gold().get(&p2), Some(&10));
}

#[test]
fn contested_map_objective_removes_the_sparse_hold() {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let objective = MapObjective::try_new(
        "contested",
        MapObjectiveType::StrategicPass,
        HexCoord::new(0, 0),
        1,
        1,
        0,
    )
    .expect("objective");
    let map = map(2, vec![objective]);
    let identity = identity(MatchRules::default(), &p1, &p2);
    let objectives = ObjectiveState::try_new(
        &identity,
        BTreeMap::new(),
        BTreeMap::new(),
        [MapObjectiveHoldState::try_new("contested".to_owned(), p2.clone(), 3).expect("hold")],
    )
    .expect("objectives");
    let state = state_with_units(
        &map,
        identity,
        &p1,
        &p2,
        [city("city-2", &p2, 0, [])],
        [],
        EconomyState::default(),
        objectives,
        [unit("unit-1", &p1), unit_at("unit-2", &p2, 1)],
    );

    let transition = finalize(state, &map, &p2);

    assert!(
        transition
            .state()
            .objectives()
            .map_objective_hold_states()
            .is_empty()
    );
    assert!(
        !transition
            .events()
            .iter()
            .any(|event| matches!(event, DomainEvent::MapObjectiveSecured(_)))
    );
}

#[test]
fn domination_starts_once_and_advances_from_unique_passable_territory() {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let map = map(3, Vec::new());
    let identity = identity(MatchRules::default(), &p1, &p2);
    let state = state(
        &map,
        identity,
        &p1,
        &p2,
        [city("city-2", &p2, 0, [HexCoord::new(1, 0)])],
        [],
        EconomyState::default(),
        ObjectiveState::default(),
    );

    let transition = finalize(state, &map, &p2);
    let event = transition
        .events()
        .iter()
        .find_map(|event| match event {
            DomainEvent::DominationThresholdReached(value) => Some(value),
            _ => None,
        })
        .expect("threshold event");
    assert_eq!(event.player_id(), &p2);
    assert_eq!(event.controlled_tile_count(), 2);
    assert_eq!(event.valid_tile_count(), 3);
    assert_eq!(event.hold_turns(), 1);
    assert_eq!(
        transition
            .state()
            .objectives()
            .domination_hold_turns_by_player_id()
            .get(&p2),
        Some(&1)
    );

    let partial = GameEngine::apply_player_owned(
        transition.state().clone(),
        EngineContext::canonical(&p1, &map, RulesetDefinition::standard()),
        PlayerCommand::SubmitTurn(TurnCommand::new(8, &p1)),
    )
    .expect("partial");
    let next = GameEngine::apply_player_owned(
        partial.state().clone(),
        EngineContext::canonical(&p2, &map, RulesetDefinition::standard()),
        PlayerCommand::SubmitTurn(TurnCommand::new(9, &p2)),
    )
    .expect("next");
    assert!(
        !next
            .events()
            .iter()
            .any(|event| matches!(event, DomainEvent::DominationThresholdReached(_)))
    );
    assert_eq!(
        next.state()
            .objectives()
            .domination_hold_turns_by_player_id()
            .get(&p2),
        Some(&2)
    );
}

#[test]
fn cultural_progress_counts_distinct_types_and_disabled_rules_preserve_holds() {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let map = map(8, Vec::new());
    let rules = victory_rules(false, true);
    let enabled_identity = identity(rules, &p1, &p2);
    let cities = (0..6)
        .map(|col| city(&format!("city-{col}"), &p2, col, []))
        .collect::<Vec<_>>();
    let types = [
        WorldArtifactType::AncientImperialCrown,
        WorldArtifactType::AstronomersTablets,
        WorldArtifactType::ProphetMask,
        WorldArtifactType::HeroSword,
        WorldArtifactType::MerchantsSeal,
        WorldArtifactType::FirstPeoplesChronicle,
    ];
    let artifacts = types
        .into_iter()
        .enumerate()
        .map(|(index, artifact_type)| {
            WorldArtifact::new(
                ArtifactId::new(format!("artifact-{index}")).expect("artifact id"),
                artifact_type,
                WorldArtifactLocation::Stored(
                    CityId::new(format!("city-{index}")).expect("city id"),
                ),
            )
        })
        .collect::<Vec<_>>();
    let enabled_state = state(
        &map,
        enabled_identity,
        &p1,
        &p2,
        cities,
        artifacts,
        EconomyState::default(),
        ObjectiveState::default(),
    );

    let transition = finalize(enabled_state, &map, &p2);
    assert_eq!(
        transition
            .state()
            .objectives()
            .cultural_victory_hold_turns_by_player_id()
            .get(&p2),
        Some(&1)
    );

    let disabled_rules = victory_rules(false, false);
    let identity = identity(disabled_rules, &p1, &p2);
    let objectives = ObjectiveState::try_new(
        &identity,
        BTreeMap::new(),
        BTreeMap::from([(p2.clone(), 4)]),
        [],
    )
    .expect("objectives");
    let state = state(
        &map,
        identity,
        &p1,
        &p2,
        [],
        [],
        EconomyState::default(),
        objectives,
    );
    let transition = finalize(state, &map, &p2);
    assert_eq!(
        transition
            .state()
            .objectives()
            .cultural_victory_hold_turns_by_player_id()
            .get(&p2),
        Some(&4)
    );
}

fn finalize(
    state: GameState,
    map: &MapDefinition,
    actor: &PlayerId,
) -> aonw_engine::DomainTransition {
    GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(actor, map, RulesetDefinition::standard()),
        PlayerCommand::SubmitTurn(TurnCommand::new(7, actor)),
    )
    .expect("finalize turn")
}

#[allow(clippy::too_many_arguments)]
fn state(
    map: &MapDefinition,
    identity: MatchIdentity,
    p1: &PlayerId,
    p2: &PlayerId,
    cities: impl IntoIterator<Item = City>,
    artifacts: impl IntoIterator<Item = WorldArtifact>,
    economy: EconomyState,
    objectives: ObjectiveState,
) -> GameState {
    state_with_units(
        map,
        identity,
        p1,
        p2,
        cities,
        artifacts,
        economy,
        objectives,
        [
            unit_at("unit-1", p1, i32::from(map.cols()) - 1),
            unit_at("unit-2", p2, 0),
        ],
    )
}

#[allow(clippy::too_many_arguments)]
fn state_with_units(
    map: &MapDefinition,
    identity: MatchIdentity,
    p1: &PlayerId,
    p2: &PlayerId,
    cities: impl IntoIterator<Item = City>,
    artifacts: impl IntoIterator<Item = WorldArtifact>,
    economy: EconomyState,
    objectives: ObjectiveState,
    units: impl IntoIterator<Item = aonw_domain::Unit>,
) -> GameState {
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (p1.clone(), PlayerTurnState::Finished),
            (p2.clone(), PlayerTurnState::Active),
        ]),
        [p1.clone(), p2.clone()],
        [p1.clone()],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle");
    GameState::builder(
        StateRevision::new(7),
        7,
        map.bounds(),
        UnitOccupancyPolicy::Exclusive,
        units,
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .with_cities(cities)
    .with_artifacts(artifacts)
    .with_economy(economy)
    .with_objectives(objectives)
    .try_build()
    .expect("state")
}

fn identity(rules: MatchRules, p1: &PlayerId, p2: &PlayerId) -> MatchIdentity {
    MatchIdentity::try_new(
        rules,
        [
            participant(p1.clone(), "One"),
            participant(p2.clone(), "Two"),
        ],
        GameMode::Multiplayer,
    )
    .expect("identity")
}

fn victory_rules(domination: bool, cultural: bool) -> MatchRules {
    MatchRules::new(
        GameLengthConfig::default(),
        VictoryRules::try_new(
            true,
            domination,
            RuleNumber::new("60").expect("percent"),
            5,
            false,
            None,
            None,
            cultural,
            6,
            5,
        )
        .expect("victory rules"),
        BTreeMap::new(),
    )
}

fn city(
    id: &str,
    owner: &PlayerId,
    center_col: i32,
    controlled: impl IntoIterator<Item = HexCoord>,
) -> City {
    City::new(
        CityId::new(id).expect("city id"),
        owner.clone(),
        HexCoord::new(center_col, 0),
        controlled,
    )
}

fn unit_at(id: &str, owner: &PlayerId, col: i32) -> aonw_domain::Unit {
    aonw_domain::Unit::builder(
        aonw_domain::UnitId::new(id).expect("unit id"),
        owner.clone(),
        aonw_domain::UnitKind::Commander,
        id,
        HexCoord::new(col, 0),
        aonw_domain::MovementUnits::ZERO,
    )
    .build()
    .expect("unit")
}

fn map(cols: u16, objectives: Vec<MapObjective>) -> MapDefinition {
    MapDefinition::try_new(
        "objective-test",
        GridLayout::OddQFlatTop,
        cols,
        1,
        (0..i32::from(cols))
            .map(|col| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(col, 0),
                    vec![TerrainType::Plains],
                    Vec::new(),
                    0,
                )
                .expect("tile")
            })
            .collect(),
        objectives,
    )
    .expect("map")
}
