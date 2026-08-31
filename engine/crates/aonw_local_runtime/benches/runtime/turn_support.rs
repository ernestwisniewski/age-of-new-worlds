use std::collections::{BTreeMap, BTreeSet};

use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{
    GameMode, GameState, HexCoord, MatchIdentity, MatchLifecycle, MatchRules, Participant,
    PlayerCountry, PlayerId, PlayerKind, PlayerTurnState, StateRevision, TurnLifecycle, Unit,
    UnitId, UnitKind,
};
use aonw_local_runtime::{LocalRuntime, OpenSession};

pub(super) fn opened_turn_runtime(
    map: MapDefinition,
    ruleset: RulesetDefinition,
    unit_count: usize,
) -> (LocalRuntime, PlayerId, PlayerId) {
    let first = PlayerId::new("player-1").expect("first player");
    let second = PlayerId::new("player-2").expect("second player");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [
            participant(first.clone(), "One"),
            participant(second.clone(), "Two"),
        ],
        GameMode::Multiplayer,
    )
    .expect("match identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (first.clone(), PlayerTurnState::Active),
            (second.clone(), PlayerTurnState::Active),
        ]),
        BTreeSet::from([first.clone(), second.clone()]),
        BTreeSet::new(),
        BTreeMap::new(),
        BTreeSet::new(),
        BTreeSet::new(),
        None,
    )
    .expect("turn lifecycle");
    let definition = ruleset
        .unit(UnitKind::Commander)
        .expect("commander definition");
    let units = positions(unit_count).enumerate().map(|(index, position)| {
        Unit::builder(
            UnitId::new(format!("turn-unit-{index}")).expect("unit id"),
            first.clone(),
            UnitKind::Commander,
            "Commander",
            position,
            definition.maximum_movement(false),
        )
        .build()
        .expect("unit")
    });
    let state = GameState::builder(
        StateRevision::INITIAL,
        1,
        map.bounds(),
        ruleset.occupancy_policy(),
        units,
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("turn state");
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(map, ruleset, state, first.clone()))
        .expect("open turn runtime");
    (runtime, first, second)
}

fn participant(id: PlayerId, name: &str) -> Participant {
    Participant::try_new(
        id,
        name,
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Human,
        None,
    )
    .expect("participant")
}

fn positions(unit_count: usize) -> impl Iterator<Item = HexCoord> {
    (0..30)
        .flat_map(|row| (0..40).map(move |col| HexCoord::new(col, row)))
        .take(unit_count)
}
