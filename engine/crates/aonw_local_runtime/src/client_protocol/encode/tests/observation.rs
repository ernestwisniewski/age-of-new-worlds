mod disclosure;
mod protocol;
mod replay;

use std::collections::BTreeMap;
use std::num::NonZeroU32;

use crate::{
    AiTurnDriver, AiTurnExecution, LocalRuntime, MoveUnitRequest, OpenSession,
    SelectTechnologyRequest,
};
use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_contracts::client::ClientEventDto;
use aonw_domain::{
    AiDifficulty, AiPersona, AiPlayer, AiStrategyId, FogOfWar, GameMode, GameState, HexCoord,
    MatchIdentity, MatchLifecycle, MatchRules, MovementUnits, Participant, PlayerCountry,
    PlayerFog, PlayerId, PlayerKind, PlayerTurnState, StateRevision, TechnologyId, TurnLifecycle,
    Unit, UnitId, UnitKind,
};

use super::super::command_result;

#[test]
fn observed_ai_commands_keep_the_human_projection_and_disclosure() {
    let (map, rules, mut runtime) = opened();
    let mut ordinary = runtime.clone();
    let result = runtime
        .advance_ai_turn_observed(player("ai"), budget(3), &mut ScriptedDriver::new(3))
        .expect("observed AI");
    let plain = ordinary
        .advance_ai_turn(player("ai"), budget(3), &mut ScriptedDriver::new(3))
        .expect("ordinary AI");
    assert_eq!(result.execution, plain);
    assert_eq!(result.recipient_player_id, player("human"));
    assert_eq!(result.commands.len(), 3);
    let commands: Vec<_> = result.commands.iter().map(command_result).collect();
    for (index, command) in commands.iter().enumerate() {
        assert_eq!(
            command.view_patch.from_revision,
            u64::try_from(index).expect("index")
        );
        assert_eq!(command.view_patch.to_revision, command.stamp.revision);
        assert_eq!(
            command.stamp.revision,
            u64::try_from(index + 1).expect("index")
        );
    }
    assert!(
        matches!(&commands[0].events[..], [ClientEventDto::UnitMoved { unit_id, .. }] if unit_id == "visible-ai")
    );
    assert!(commands[0].evidence.is_some());
    assert!(commands[1].events.is_empty());
    assert!(commands[1].evidence.is_none());
    assert!(commands[1].view_patch.upserted_units.is_empty());
    assert!(commands[2].view_patch.research.is_none());
    assert!(commands[2].view_patch.pending_action.is_none());
    assert!(
        runtime
            .snapshot()
            .expect("AI view")
            .research()
            .active_technology_id()
            .is_some()
    );
    let replay = runtime.export_replay_json().expect("replay");
    assert_eq!(
        replay,
        ordinary.export_replay_json().expect("ordinary replay")
    );
    let save = runtime.export_save_json().expect("save");
    assert_eq!(save, ordinary.export_save_json().expect("ordinary save"));
    assert_eq!(
        LocalRuntime::verify_replay_json(map, rules, &replay)
            .expect("verify")
            .entry_count,
        3
    );
}

#[test]
fn replay_forward_frames_match_live_observation_and_random_seeks_are_silent() {
    let (map, rules, mut runtime) = opened();
    let observed = runtime
        .advance_ai_turn_observed(player("ai"), budget(3), &mut ScriptedDriver::new(3))
        .expect("AI");
    let replay = runtime.export_replay_json().expect("replay");
    let first = runtime
        .open_replay_json(map, rules, &replay, player("human"))
        .expect("open playback");
    assert!(first.command.is_none());
    for (index, expected) in observed.commands.iter().enumerate() {
        let position = u64::try_from(index + 1).expect("position");
        let frame = runtime.seek_replay(position).expect("forward");
        assert_eq!(
            command_result(frame.command.as_ref().expect("command")),
            command_result(expected)
        );
        assert_eq!(frame.snapshot.recipient_player_id(), &player("human"));
        assert_eq!(frame.snapshot.stamp(), &expected.stamp);
        assert!(
            runtime
                .seek_replay(position)
                .expect("same position")
                .command
                .is_none()
        );
    }
    assert!(runtime.seek_replay(0).expect("backward").command.is_none());
    assert!(runtime.seek_replay(3).expect("jump").command.is_none());
    assert!(
        runtime
            .seek_replay(1)
            .expect("backward segment")
            .command
            .is_none()
    );
    assert_eq!(
        command_result(
            runtime
                .seek_replay(2)
                .expect("resume")
                .command
                .as_ref()
                .expect("command")
        ),
        command_result(&observed.commands[1])
    );
}

#[test]
fn simulation_work_and_failed_batches_do_not_enter_later_observations() {
    let (_, _, mut runtime) = opened();
    let mut driver = ScriptedDriver::new(1);
    driver.simulate = true;
    let result = runtime
        .advance_ai_turn_observed(player("ai"), budget(1), &mut driver)
        .expect("AI with simulation");
    assert_eq!(result.commands.len(), 1);
    assert_eq!(result.commands[0].stamp.revision.get(), 1);
    runtime
        .handoff_hot_seat_actor(player("human"))
        .expect("human");
    let mut failure = ScriptedDriver::new(2);
    failure.target = Some(2);
    failure.fail = true;
    assert!(
        runtime
            .advance_ai_turn_observed(player("ai"), budget(1), &mut failure)
            .is_err()
    );
    runtime
        .handoff_hot_seat_actor(player("human"))
        .expect("restore");
    assert!(
        runtime
            .advance_ai_turn_observed(player("ai"), budget(1), &mut ScriptedDriver::new(0))
            .expect("next batch")
            .commands
            .is_empty()
    );
    let (_, _, mut excessive) = opened();
    let error = excessive
        .advance_ai_turn_observed(player("ai"), budget(1), &mut ScriptedDriver::new(2))
        .expect_err("bounded observation");
    assert!(
        error
            .to_string()
            .contains("observed command budget exceeded")
    );
}

struct ScriptedDriver {
    count: u32,
    simulate: bool,
    fail: bool,
    target: Option<i32>,
}

impl ScriptedDriver {
    fn new(count: u32) -> Self {
        Self {
            count,
            simulate: false,
            fail: false,
            target: None,
        }
    }
}

impl AiTurnDriver for ScriptedDriver {
    fn play_turn(
        &mut self,
        runtime: &mut LocalRuntime,
        _: AiPlayer,
        _: NonZeroU32,
    ) -> Result<AiTurnExecution, Box<str>> {
        if self.simulate {
            let mut simulation = runtime.simulation_clone();
            for index in 0..3 {
                execute(&mut simulation, index, None)?;
            }
        }
        for index in 0..self.count {
            execute(runtime, index, self.target)?;
        }
        if self.fail {
            return Err("script failed".into());
        }
        Ok(AiTurnExecution {
            stamp: *runtime.snapshot().expect("snapshot").stamp(),
            executed_commands: self.count,
            completed_turn: false,
        })
    }
}

fn execute(runtime: &mut LocalRuntime, index: u32, target: Option<i32>) -> Result<(), Box<str>> {
    let revision = runtime.snapshot().expect("snapshot").stamp().revision.get();
    let result = if index == 2 {
        runtime.select_technology(SelectTechnologyRequest {
            expected_revision: revision,
            technology: TechnologyId::Agriculture,
        })
    } else {
        runtime.dispatch(&MoveUnitRequest {
            expected_revision: revision,
            unit_id: unit_id(if index == 0 {
                "visible-ai"
            } else {
                "hidden-ai"
            }),
            target: HexCoord::new(if index == 0 { target.unwrap_or(1) } else { 9 }, 0),
        })
    }
    .map_err(|error| error.to_string().into_boxed_str())?;
    assert!(
        result.is_accepted(),
        "scripted command {index}: {:?}",
        result.rejection
    );
    Ok(())
}

fn opened() -> (MapDefinition, RulesetDefinition, LocalRuntime) {
    opened_with_visibility(&[0, 1, 2])
}

fn opened_with_visibility(visible: &[i32]) -> (MapDefinition, RulesetDefinition, LocalRuntime) {
    let map = MapDefinition::try_new(
        "recipient-observation",
        GridLayout::OddQFlatTop,
        12,
        5,
        (0..5)
            .flat_map(|row| (0..12).map(move |col| (col, row)))
            .map(|(col, row)| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(col, row),
                    vec![TerrainType::Grassland],
                    Vec::new(),
                    0,
                )
                .expect("tile")
            })
            .collect(),
        Vec::new(),
    )
    .expect("map");
    let rules = RulesetDefinition::standard().clone();
    let human = player("human");
    let ai = player("ai");
    let identity = match_identity(&human, &ai);
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (human.clone(), PlayerTurnState::Active),
            (ai.clone(), PlayerTurnState::Active),
        ]),
        [human.clone(), ai.clone()],
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("turn");
    let fog = FogOfWar::try_new([
        PlayerFog::new(
            human.clone(),
            [],
            visible.iter().map(|&col| HexCoord::new(col, 0)),
        ),
        PlayerFog::new(ai.clone(), [], (0..12).map(|col| HexCoord::new(col, 0))),
    ])
    .expect("fog");
    let state = GameState::builder(
        StateRevision::INITIAL,
        1,
        map.bounds(),
        rules.occupancy_policy(),
        [
            unit("human-unit", &human, 0),
            unit("visible-ai", &ai, 2),
            unit("hidden-ai", &ai, 10),
        ],
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .with_fog_of_war(fog)
    .try_build()
    .expect("state");
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(
            map.clone(),
            rules.clone(),
            state,
            human,
        ))
        .expect("open");
    (map, rules, runtime)
}

fn match_identity(human: &PlayerId, ai: &PlayerId) -> MatchIdentity {
    let config = AiPlayer::new(
        AiStrategyId::Scripted,
        AiDifficulty::Normal,
        AiPersona::Balanced,
        1,
    );
    MatchIdentity::try_new(
        MatchRules::default(),
        [
            Participant::try_new(
                human.clone(),
                "Human",
                0xff68_a7e8,
                PlayerCountry::Poland,
                PlayerKind::Human,
                None,
            )
            .expect("human"),
            Participant::try_new(
                ai.clone(),
                "AI",
                0xffc4_5e63,
                PlayerCountry::Germany,
                PlayerKind::Ai,
                Some(config),
            )
            .expect("AI"),
        ],
        GameMode::HotSeat,
    )
    .expect("identity")
}

fn unit(id: &str, owner: &PlayerId, col: i32) -> Unit {
    Unit::builder(
        unit_id(id),
        owner.clone(),
        UnitKind::Commander,
        id,
        HexCoord::new(col, 0),
        MovementUnits::new(10),
    )
    .build()
    .expect("unit")
}
fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player")
}
fn unit_id(id: &str) -> UnitId {
    UnitId::new(id).expect("unit")
}
fn budget(count: u32) -> NonZeroU32 {
    NonZeroU32::new(count).expect("budget")
}
