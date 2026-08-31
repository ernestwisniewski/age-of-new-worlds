use std::collections::BTreeMap;

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    City, CityId, GameLengthConfig, GameMode, GameState, HexCoord, MatchIdentity, MatchLifecycle,
    MatchRules, MovementUnits, Participant, PlayerCountry, PlayerId, PlayerKind, PlayerTurnState,
    RuleNumber, StateRevision, TurnLifecycle, Unit, UnitId, UnitKind, VictoryRules,
};
use aonw_local_runtime::{LocalRuntime, MoveUnitRequest, OpenSession, UnitActionRequest};

use super::{MctsSearchStats, execute_move, iteration_score};
use crate::actions::legal_move_candidates;

#[test]
fn rejected_simulation_moves_are_counted_and_scored_as_illegal() {
    let mut runtime = opened_runtime();
    let original_snapshot = runtime.snapshot().expect("snapshot");
    runtime
        .skip_unit_turn(&UnitActionRequest {
            expected_revision: 0,
            unit_id: UnitId::new("unit-1").expect("unit"),
        })
        .expect("advance revision");
    let mut stats = MctsSearchStats::default();
    let accepted = execute_move(
        &mut runtime,
        &MoveUnitRequest {
            expected_revision: 0,
            unit_id: UnitId::new("unit-1").expect("unit"),
            target: HexCoord::new(1, 0),
        },
        &mut stats,
    )
    .expect("typed stale rejection");
    assert!(!accepted);
    assert_eq!(stats.executed_commands(), 1);
    assert_eq!(stats.rejected_commands(), 1);
    assert_eq!(
        iteration_score(
            true,
            &runtime,
            &PlayerId::new("player-1").expect("actor"),
            10,
        )
        .expect("rejection score"),
        -1_000_000
    );

    assert!(
        legal_move_candidates(&mut runtime, &original_snapshot)
            .expect("stale reachable query is skipped")
            .is_empty()
    );
    runtime.close();
    assert_eq!(
        legal_move_candidates(&mut runtime, &original_snapshot),
        Err(aonw_local_runtime::RuntimeError::SessionNotOpen)
    );
}

pub(crate) fn opened_runtime() -> LocalRuntime {
    let tiles = (0..2)
        .map(|col| {
            TileDefinition::try_new_for_simulation(
                HexCoord::new(col, 0),
                vec![TerrainType::Grassland],
                Vec::new(),
                0,
            )
            .expect("tile")
        })
        .collect();
    let map = MapDefinition::try_new(
        "mcts-rejection",
        GridLayout::OddQFlatTop,
        2,
        1,
        tiles,
        Vec::new(),
    )
    .expect("map");
    let rules = RulesetDefinition::standard().clone();
    let actor = PlayerId::new("player-1").expect("actor");
    let opponent = PlayerId::new("player-2").expect("opponent");
    let victory = VictoryRules::try_new(
        false,
        false,
        RuleNumber::new("60").expect("percent"),
        1,
        true,
        Some(6),
        None,
        false,
        1,
        1,
    )
    .expect("victory");
    let identity = MatchIdentity::try_new(
        MatchRules::new(GameLengthConfig::default(), victory, BTreeMap::new()),
        [participant(actor.clone()), participant(opponent.clone())],
        GameMode::Multiplayer,
    )
    .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (actor.clone(), PlayerTurnState::Active),
            (opponent, PlayerTurnState::Active),
        ]),
        [actor.clone()],
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle");
    let unit = Unit::builder(
        UnitId::new("unit-1").expect("unit"),
        actor.clone(),
        UnitKind::Scout,
        "Scout",
        HexCoord::new(0, 0),
        MovementUnits::new(10),
    )
    .build()
    .expect("unit");
    let city = City::builder(
        CityId::new("city-1").expect("city"),
        actor.clone(),
        "Capital",
        HexCoord::new(0, 0),
    )
    .build()
    .expect("city");
    let state = GameState::builder(
        StateRevision::INITIAL,
        0,
        map.bounds(),
        rules.occupancy_policy(),
        [unit],
    )
    .with_cities([city])
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state");
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(map, rules, state, actor))
        .expect("open");
    runtime
}

fn participant(id: PlayerId) -> Participant {
    Participant::try_new(
        id,
        "AI",
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Ai,
        None,
    )
    .expect("participant")
}
