//! Deterministic full-game coverage for multiple production AI actors.

use core::num::NonZeroU32;
use std::collections::BTreeMap;

use aonw_ai::{AiDifficulty, AiPersona, AiProfile, PlannedCommandFamily, StrategicPlanner};
use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    City, CityId, FogOfWar, GameLengthConfig, GameMode, GameOutcomeCondition, GameState, HexCoord,
    KnowledgeState, MatchIdentity, MatchLifecycle, MatchRules, MovementUnits, Participant,
    PlayerCountry, PlayerFog, PlayerId, PlayerKind, PlayerResearchState, PlayerTurnState,
    ResearchState, StateRevision, TechnologyId, TurnLifecycle, Unit, UnitId, UnitKind,
    VictoryRules, WonderRegistry,
};
use aonw_local_runtime::{LocalRuntime, OpenSession, SessionStamp};

#[derive(Debug, Eq, PartialEq)]
struct FullGameEvidence {
    final_stamp: SessionStamp,
    final_save: String,
    checkpoint_stamps: Vec<SessionStamp>,
    family_usage: BTreeMap<PlannedCommandFamily, u32>,
    executed_commands: u32,
}

#[test]
fn profiled_ai_actors_finish_an_exact_game_across_save_and_replay() {
    let first = run_full_game();
    let second = run_full_game();

    assert_eq!(first, second);
    assert!(first.checkpoint_stamps.len() >= 4);
    assert!(first.executed_commands >= 12);
    for family in [
        PlannedCommandFamily::Research,
        PlannedCommandFamily::Production,
        PlannedCommandFamily::Worker,
        PlannedCommandFamily::Movement,
        PlannedCommandFamily::Turn,
    ] {
        assert!(
            first.family_usage.get(&family).copied().unwrap_or(0) > 0,
            "full game did not exercise {family:?}"
        );
    }
}

fn run_full_game() -> FullGameEvidence {
    let map = map();
    let rules = RulesetDefinition::standard().clone();
    let players = [player("player-1"), player("player-2")];
    let profiles = [
        AiProfile::new(AiDifficulty::Hard, AiPersona::Expansive),
        AiProfile::new(AiDifficulty::VeryHard, AiPersona::Scientific),
    ];
    let state = state(&map, &rules, &players);
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(
            map.clone(),
            rules.clone(),
            state,
            players[0].clone(),
        ))
        .expect("open full AI game");

    let mut family_usage = BTreeMap::new();
    let mut executed_commands = 0;
    let mut checkpoint_stamps = Vec::new();
    let mut reopened = false;
    while !runtime
        .snapshot()
        .expect("round snapshot")
        .outcome()
        .is_terminal()
    {
        for (actor, profile) in players.iter().zip(profiles) {
            runtime
                .handoff_hot_seat_actor(actor.clone())
                .expect("handoff AI actor");
            if runtime
                .snapshot()
                .expect("actor snapshot")
                .outcome()
                .is_terminal()
            {
                break;
            }
            let report = StrategicPlanner
                .play_turn_with_profile(
                    &mut runtime,
                    NonZeroU32::new(128).expect("positive command budget"),
                    profile,
                )
                .expect("complete AI actor turn");
            assert!(report.completed_turn());
            executed_commands += report.executed_commands();
            for (family, count) in report.family_usage() {
                *family_usage.entry(*family).or_insert(0) += count;
            }
            checkpoint_stamps.push(*report.final_stamp());
        }

        let replay = runtime.export_replay_json().expect("checkpoint replay");
        let verification = LocalRuntime::verify_replay_json(map.clone(), rules.clone(), &replay)
            .expect("verify checkpoint replay");
        assert_eq!(
            verification.final_stamp,
            *runtime.snapshot().expect("verified snapshot").stamp()
        );

        if !reopened
            && !runtime
                .snapshot()
                .expect("save snapshot")
                .outcome()
                .is_terminal()
        {
            let save = runtime.export_save_json().expect("checkpoint save");
            let expected = runtime.snapshot().expect("pre-reopen snapshot");
            let mut restored = LocalRuntime::default();
            restored
                .open_save_json(map.clone(), rules.clone(), &save)
                .expect("reopen AI checkpoint");
            assert_eq!(restored.snapshot().expect("restored snapshot"), expected);
            runtime = restored;
            reopened = true;
        }
    }

    assert!(
        reopened,
        "game reached terminal state before save/reopen checkpoint"
    );
    let terminal = runtime.snapshot().expect("terminal snapshot");
    assert_eq!(terminal.outcome().condition(), GameOutcomeCondition::Score);
    let final_stamp = *terminal.stamp();
    let final_replay = runtime.export_replay_json().expect("final replay");
    assert_eq!(
        LocalRuntime::verify_replay_json(map, rules, &final_replay)
            .expect("verify final replay")
            .final_stamp,
        final_stamp
    );
    FullGameEvidence {
        final_stamp,
        final_save: runtime.export_save_json().expect("final save"),
        checkpoint_stamps,
        family_usage,
        executed_commands,
    }
}

fn state(map: &MapDefinition, rules: &RulesetDefinition, players: &[PlayerId; 2]) -> GameState {
    let identity = MatchIdentity::try_new(
        match_rules(),
        [
            participant(&players[0], PlayerCountry::Poland),
            participant(&players[1], PlayerCountry::Germany),
        ],
        GameMode::HotSeat,
    )
    .expect("AI match identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (players[0].clone(), PlayerTurnState::Active),
            (players[1].clone(), PlayerTurnState::Active),
        ]),
        players.iter().cloned(),
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("AI turn lifecycle");
    let research = ResearchState::try_new(players.iter().map(|player| {
        (
            player.clone(),
            PlayerResearchState::try_new([TechnologyId::Agriculture], None, [], 0)
                .expect("AI research"),
        )
    }))
    .expect("research state");
    let visible = map
        .tiles()
        .iter()
        .map(TileDefinition::coordinate)
        .collect::<Vec<_>>();
    let fog = FogOfWar::try_new(
        players
            .iter()
            .map(|player| PlayerFog::new(player.clone(), [], visible.iter().copied())),
    )
    .expect("full AI visibility");
    GameState::builder(
        StateRevision::INITIAL,
        0,
        map.bounds(),
        rules.occupancy_policy(),
        [
            unit("commander-1", &players[0], UnitKind::Commander, 1, 1),
            unit("worker-1", &players[0], UnitKind::Worker, 1, 0),
            unit("commander-2", &players[1], UnitKind::Commander, 6, 1),
            unit("worker-2", &players[1], UnitKind::Worker, 6, 2),
        ],
    )
    .with_cities([
        city("city-1", &players[0], "Warsaw", 0, 1, 1, 0),
        city("city-2", &players[1], "Berlin", 7, 1, 6, 2),
    ])
    .with_fog_of_war(fog)
    .with_knowledge(KnowledgeState::new(research, WonderRegistry::default()))
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("full AI game state")
}

fn match_rules() -> MatchRules {
    MatchRules::new(
        GameLengthConfig::default(),
        VictoryRules::try_new(
            false,
            false,
            aonw_domain::RuleNumber::new("60").expect("percent"),
            1,
            true,
            Some(4),
            None,
            false,
            1,
            1,
        )
        .expect("victory rules"),
        BTreeMap::new(),
    )
}

fn participant(id: &PlayerId, country: PlayerCountry) -> Participant {
    Participant::try_new(
        id.clone(),
        id.as_str(),
        0xff00_0000,
        country,
        PlayerKind::Ai,
        None,
    )
    .expect("AI participant")
}

fn unit(id: &str, owner: &PlayerId, kind: UnitKind, col: i32, row: i32) -> Unit {
    let mut builder = Unit::builder(
        UnitId::new(id).expect("unit id"),
        owner.clone(),
        kind,
        id,
        HexCoord::new(col, row),
        MovementUnits::new(10),
    );
    if kind == UnitKind::Worker {
        builder = builder.with_worker_build_charges(1);
    }
    builder.build().expect("AI unit")
}

fn city(
    id: &str,
    owner: &PlayerId,
    name: &str,
    col: i32,
    row: i32,
    controlled_col: i32,
    controlled_row: i32,
) -> City {
    City::builder(
        CityId::new(id).expect("city id"),
        owner.clone(),
        name,
        HexCoord::new(col, row),
    )
    .with_progression(2, 0, 6, 3)
    .with_controlled_hexes([HexCoord::new(controlled_col, controlled_row)])
    .build()
    .expect("AI city")
}

fn map() -> MapDefinition {
    MapDefinition::try_new(
        "ai-full-game",
        GridLayout::OddQFlatTop,
        8,
        3,
        (0..3)
            .flat_map(|row| {
                (0..8).map(move |col| {
                    TileDefinition::try_new_for_simulation(
                        HexCoord::new(col, row),
                        vec![TerrainType::Grassland],
                        Vec::new(),
                        0,
                    )
                    .expect("tile")
                })
            })
            .collect(),
        Vec::new(),
    )
    .expect("AI full-game map")
}

fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player")
}
