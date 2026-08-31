use std::collections::BTreeMap;

use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{
    FogOfWar, GameMode, GameState, HexCoord, MatchIdentity, MatchLifecycle, MatchRules,
    Participant, PlayerCountry, PlayerFog, PlayerId, PlayerKind, PlayerTurnState, StateRevision,
    TurnLifecycle, Unit, UnitId, UnitKind,
};
use aonw_local_runtime::OpenSession;

pub(super) fn open(map: MapDefinition, ruleset: RulesetDefinition, actor: PlayerId) -> OpenSession {
    let opponent = PlayerId::new("player-2").expect("opponent");
    let definition = ruleset
        .unit(UnitKind::Commander)
        .expect("commander definition");
    let unit = |id: &str, owner: PlayerId, position: HexCoord| {
        Unit::builder(
            UnitId::new(id).expect("unit id"),
            owner,
            UnitKind::Commander,
            "Commander",
            position,
            definition.maximum_movement(false),
        )
        .build()
        .expect("unit")
    };
    let fog = FogOfWar::try_new([
        PlayerFog::new(actor.clone(), [], []),
        PlayerFog::new(opponent.clone(), [], []),
    ])
    .expect("fog");
    let state = GameState::builder(
        StateRevision::INITIAL,
        0,
        map.bounds(),
        ruleset.occupancy_policy(),
        [
            unit("unit-0", actor.clone(), HexCoord::new(0, 0)),
            unit("hidden-blocker", opponent.clone(), HexCoord::new(1, 0)),
        ],
    )
    .with_fog_of_war(fog)
    .with_match_lifecycle(started_match(&actor, &opponent))
    .try_build()
    .expect("state");
    OpenSession::from_state(map, ruleset, state, actor)
}

fn started_match(actor: &PlayerId, opponent: &PlayerId) -> MatchLifecycle {
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [participant(actor), participant(opponent)],
        GameMode::HotSeat,
    )
    .expect("match identity");
    let turn = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (actor.clone(), PlayerTurnState::Active),
            (opponent.clone(), PlayerTurnState::Active),
        ]),
        [actor.clone(), opponent.clone()],
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("turn lifecycle");
    MatchLifecycle::new(identity, turn)
}

fn participant(player_id: &PlayerId) -> Participant {
    Participant::try_new(
        player_id.clone(),
        player_id.as_str(),
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Human,
        None,
    )
    .expect("participant")
}
