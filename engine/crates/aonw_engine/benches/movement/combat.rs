use std::collections::BTreeMap;
use std::hint::black_box;

use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{
    CityConquestAction, CombatState, FogOfWar, GameMode, GameState, HexCoord, IntendedAttack,
    MatchIdentity, MatchLifecycle, MatchRules, MovementUnits, Participant, PlayerCountry, PlayerId,
    PlayerKind, PlayerTurnState, StateRevision, TurnLifecycle, Unit, UnitId, UnitKind,
    UnitOccupancyPolicy,
};
use aonw_engine::{
    AttackHexCommand, CombatPreviewQuery, EngineContext, GameEngine, GameQuery,
    MovementSearchMetrics, PlayerCommand, QueryResult, TurnCommand,
};

use super::support::{mix, report, signature_bytes};

const MAX_MASS_COMBAT_PAIRS: usize = 32;

pub(super) fn benchmark(map: &MapDefinition, cols: u16, rows: u16, unit_count: usize) {
    if unit_count < 2 {
        return;
    }
    let (state, actor, defender) = combat_state(cols, rows, unit_count);
    let attacker_id = UnitId::new("combat-attacker-0").expect("attacker id");
    let target = HexCoord::new(1, 0);
    let context = EngineContext::canonical(&actor, map, RulesetDefinition::standard());
    report(
        "combat_preview",
        cols,
        rows,
        unit_count,
        MovementSearchMetrics::default(),
        0,
        || {
            GameEngine::query(
                black_box(&state),
                context,
                GameQuery::CombatPreview(CombatPreviewQuery::new(
                    state.revision().get(),
                    &attacker_id,
                    target,
                )),
            )
            .map_or_else(
                |error| signature_bytes(error.code().as_bytes()),
                |result| {
                    let QueryResult::CombatPreview(preview) = result else {
                        unreachable!("combat preview")
                    };
                    mix(
                        u64::from(preview.outgoing_damage.0),
                        u64::from(preview.outgoing_damage.1),
                    )
                },
            )
        },
    );
    report(
        "combat_apply",
        cols,
        rows,
        unit_count,
        MovementSearchMetrics::default(),
        0,
        || {
            GameEngine::apply_player_owned(
                black_box(state.clone()),
                context,
                PlayerCommand::AttackHex(AttackHexCommand::new(
                    state.revision().get(),
                    &attacker_id,
                    target,
                )),
            )
            .map_or_else(
                |error| signature_bytes(error.to_string().as_bytes()),
                |transition| {
                    mix(
                        u64::try_from(transition.events().len()).unwrap_or(u64::MAX),
                        u64::from(transition.digest().as_bytes()[0]),
                    )
                },
            )
        },
    );
    let submitted = GameEngine::apply_player_owned(
        state.clone(),
        EngineContext::canonical(&defender, map, RulesetDefinition::standard()),
        PlayerCommand::SubmitTurn(TurnCommand::new(state.revision().get(), &defender)),
    )
    .expect("prepare combat turn")
    .into_parts()
    .state;
    report(
        "combat_mass_turn",
        cols,
        rows,
        unit_count,
        MovementSearchMetrics::default(),
        0,
        || {
            GameEngine::apply_player_owned(
                black_box(submitted.clone()),
                EngineContext::canonical(&actor, map, RulesetDefinition::standard()),
                PlayerCommand::SubmitTurn(TurnCommand::new(submitted.revision().get(), &actor)),
            )
            .map_or_else(
                |error| signature_bytes(error.to_string().as_bytes()),
                |transition| {
                    mix(
                        u64::try_from(transition.events().len()).unwrap_or(u64::MAX),
                        u64::from(transition.digest().as_bytes()[0]),
                    )
                },
            )
        },
    );
}

fn combat_state(cols: u16, rows: u16, unit_count: usize) -> (GameState, PlayerId, PlayerId) {
    let actor = PlayerId::new("player-1").expect("actor");
    let defender = PlayerId::new("player-2").expect("defender");
    let pair_count = (unit_count / 2).min(MAX_MASS_COMBAT_PAIRS);
    let pairs_per_row = usize::from(cols / 2);
    assert!(pair_count <= pairs_per_row * usize::from(rows));
    let mut units = Vec::with_capacity(pair_count * 2);
    let mut intents = Vec::with_capacity(pair_count);
    for index in 0..pair_count {
        let row = index / pairs_per_row;
        let col = (index % pairs_per_row) * 2;
        let attacker_id = UnitId::new(format!("combat-attacker-{index}")).expect("attacker id");
        let defender_id = UnitId::new(format!("combat-defender-{index}")).expect("defender id");
        let attacker_position = HexCoord::new(
            i32::try_from(col).expect("column"),
            i32::try_from(row).expect("row"),
        );
        let defender_position = HexCoord::new(attacker_position.col() + 1, attacker_position.row());
        units.push(unit(
            attacker_id.clone(),
            actor.clone(),
            UnitKind::Warrior,
            attacker_position,
        ));
        units.push(unit(
            defender_id,
            defender.clone(),
            UnitKind::Settler,
            defender_position,
        ));
        intents.push(IntendedAttack::new(
            attacker_id,
            defender_position,
            StateRevision::new(u64::try_from(index).unwrap_or(u64::MAX)),
            actor.clone(),
            CityConquestAction::Capture,
        ));
    }
    for index in (pair_count * 2)..unit_count {
        let row = index / usize::from(cols);
        let col = index % usize::from(cols);
        units.push(unit(
            UnitId::new(format!("combat-padding-{index}")).expect("padding id"),
            actor.clone(),
            UnitKind::Warrior,
            HexCoord::new(
                i32::try_from(col).expect("padding column"),
                i32::try_from(row).expect("padding row"),
            ),
        ));
    }
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [participant(&actor), participant(&defender)],
        GameMode::Multiplayer,
    )
    .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (actor.clone(), PlayerTurnState::Active),
            (defender.clone(), PlayerTurnState::Active),
        ]),
        [actor.clone(), defender.clone()],
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle");
    let state = GameState::builder(
        StateRevision::new(1),
        7,
        aonw_domain::HexGridBounds::new(cols, rows).expect("bounds"),
        UnitOccupancyPolicy::Exclusive,
        units,
    )
    .with_fog_of_war(FogOfWar::default())
    .with_combat(CombatState::try_new(intents).expect("combat intents"))
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state");
    (state, actor, defender)
}

fn unit(id: UnitId, owner: PlayerId, kind: UnitKind, position: HexCoord) -> Unit {
    Unit::builder(
        id,
        owner,
        kind,
        "combat-unit",
        position,
        MovementUnits::new(10),
    )
    .build()
    .expect("unit")
}

fn participant(id: &PlayerId) -> Participant {
    Participant::try_new(
        id.clone(),
        id.as_str(),
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Human,
        None,
    )
    .expect("participant")
}
