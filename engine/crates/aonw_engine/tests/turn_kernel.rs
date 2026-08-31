//! Capability, transition ordering, and rejection tests for the current turn kernel.

#[path = "turn_kernel/diplomacy_phase.rs"]
mod diplomacy_phase;
#[path = "turn_kernel/economy_phase.rs"]
mod economy_phase;
#[path = "turn_kernel/economy_requirement.rs"]
mod economy_requirement;
#[path = "turn_kernel/objective_phase.rs"]
mod objective_phase;
#[path = "turn_kernel/production_phase.rs"]
mod production_phase;
#[path = "turn_kernel/research_phase.rs"]
mod research_phase;
#[path = "turn_kernel/system_commands.rs"]
mod system_commands;

use std::collections::{BTreeMap, BTreeSet};
use std::path::{Path, PathBuf};

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    GameMode, GameState, HexCoord, MatchIdentity, MatchLifecycle, MatchRules, MovementUnits,
    Participant, PlayerCountry, PlayerId, PlayerKind, PlayerTurnState, StateRevision,
    TurnLifecycle, Unit, UnitId, UnitKind, UnitOccupancyPolicy, UnitPosture, UtcTimestamp,
};
use aonw_engine::{
    CommandRejectionCode, DomainEvent, EngineContext, ExecutionEvidence, GameEngine, PlayerCommand,
    TurnCommand, TurnKernelCapabilities, TurnProcessor,
};

#[test]
fn submit_records_readiness_then_finalizes_in_canonical_order() {
    let map = map();
    let rules = RulesetDefinition::standard();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let initial = state(GameMode::Multiplayer, [], None);

    let partial = GameEngine::apply_player_owned(
        initial,
        EngineContext::canonical(&p1, &map, rules),
        PlayerCommand::SubmitTurn(TurnCommand::new(7, &p1)),
    )
    .expect("partial submit");
    assert!(partial.is_accepted());
    assert_eq!(partial.revision(), StateRevision::new(8));
    assert!(partial.events().is_empty());
    assert_eq!(
        partial
            .state()
            .match_lifecycle()
            .turn()
            .submitted_player_ids(),
        &BTreeSet::from([p1.clone()])
    );

    let repeated = GameEngine::apply_player_owned(
        partial.state().clone(),
        EngineContext::canonical(&p1, &map, rules),
        PlayerCommand::SubmitTurn(TurnCommand::new(8, &p1)),
    )
    .expect("repeated submit");
    assert!(repeated.is_accepted());
    assert_eq!(repeated.revision(), StateRevision::new(8));
    assert!(repeated.events().is_empty());
    assert_eq!(
        repeated
            .state()
            .match_lifecycle()
            .turn()
            .submitted_player_ids(),
        &BTreeSet::from([p1.clone()])
    );

    let final_submit = GameEngine::apply_player_owned(
        repeated.state().clone(),
        EngineContext::canonical(&p2, &map, rules),
        PlayerCommand::SubmitTurn(TurnCommand::new(8, &p2)),
    )
    .expect("final submit");
    assert!(final_submit.is_accepted());
    assert_eq!(final_submit.state().turn(), 8);
    assert_eq!(final_submit.revision(), StateRevision::new(9));
    assert!(matches!(
        final_submit.events(),
        [
            DomainEvent::AllPlayersSubmitted(_),
            DomainEvent::TurnEnded(_),
            DomainEvent::TurnEnded(_)
        ]
    ));
    assert_eq!(
        final_submit.state().units()[0].movement_units(),
        MovementUnits::new(10)
    );
    assert_eq!(
        final_submit.state().units()[1].movement_units(),
        MovementUnits::new(10)
    );
    assert!(final_submit.state().interaction().pending().is_none());
    assert_turn_evidence(&final_submit, 2);
}

#[test]
fn player_rejection_precedence_and_sequential_handoff_are_stable() {
    let map = map();
    let rules = RulesetDefinition::standard();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let initial = state(GameMode::HotSeat, [], None);

    let wrong_actor = GameEngine::apply_player_owned(
        initial.clone(),
        EngineContext::canonical(&p1, &map, rules),
        PlayerCommand::EndTurn(TurnCommand::new(7, &p2)),
    )
    .expect("wrong actor");
    assert_eq!(
        wrong_actor.rejection().expect("rejection").code(),
        CommandRejectionCode::TurnPlayerNotControlled
    );
    let stale = GameEngine::apply_player_owned(
        initial.clone(),
        EngineContext::canonical(&p1, &map, rules),
        PlayerCommand::EndTurn(TurnCommand::new(6, &p2)),
    )
    .expect("stale");
    assert_eq!(
        stale.rejection().expect("rejection").code(),
        CommandRejectionCode::StaleRevision
    );

    let accepted = GameEngine::apply_player_owned(
        initial,
        EngineContext::canonical(&p1, &map, rules),
        PlayerCommand::EndTurn(TurnCommand::new(7, &p1)),
    )
    .expect("end turn");
    assert!(accepted.is_accepted());
    assert_eq!(accepted.state().turn(), 7);
    assert!(matches!(accepted.events(), [DomainEvent::TurnEnded(_)]));
    assert_eq!(
        accepted.state().units()[0].movement_units(),
        MovementUnits::ZERO
    );
    assert_eq!(
        accepted.state().units()[1].movement_units(),
        MovementUnits::new(10)
    );
    assert_turn_evidence(&accepted, 1);
}

#[test]
fn fixture_manifest_covers_all_supported_processors() {
    let root = engine_root();
    let manifest: serde_json::Value = serde_json::from_slice(
        &std::fs::read(root.join("fixtures/turn_kernel/manifest.json")).expect("manifest"),
    )
    .expect("strict JSON");
    assert_eq!(manifest["capability"], TurnKernelCapabilities::LABEL);
    let enabled = manifest["enabledProcessors"]
        .as_array()
        .expect("enabled processors")
        .iter()
        .map(|value| value.as_str().expect("processor"))
        .collect::<Vec<_>>();
    assert_eq!(
        enabled,
        TurnKernelCapabilities::ENABLED.map(TurnProcessor::as_str)
    );
    for fixture in manifest["fixtures"].as_array().expect("fixtures") {
        for required in fixture["requiredProcessors"]
            .as_array()
            .expect("requirements")
        {
            assert!(enabled.contains(&required.as_str().expect("processor")));
        }
    }

    assert_eq!(
        TurnKernelCapabilities::ENABLED,
        TurnKernelCapabilities::ORDERED
    );
    assert!(TurnKernelCapabilities::DISABLED.is_empty());
}

#[test]
fn finalization_executes_required_economy() {
    let map = map();
    let rules = RulesetDefinition::standard();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let initial = state_with_posture(GameMode::Multiplayer, [p1], None, None, true);
    let transition = GameEngine::apply_player_owned(
        initial,
        EngineContext::canonical(&p2, &map, rules),
        PlayerCommand::SubmitTurn(TurnCommand::new(7, &p2)),
    )
    .expect("economy finalization");

    assert!(transition.is_accepted());
    assert!(
        transition
            .state()
            .economy()
            .player_war_weariness()
            .is_empty()
    );
    assert_eq!(transition.state().economy().player_stability_net().len(), 2);
}

fn state(
    mode: GameMode,
    submitted: impl IntoIterator<Item = PlayerId>,
    started: Option<UtcTimestamp>,
) -> GameState {
    state_with_posture(mode, submitted, started, None, false)
}

fn state_with_posture(
    mode: GameMode,
    submitted: impl IntoIterator<Item = PlayerId>,
    started: Option<UtcTimestamp>,
    second_unit_posture: Option<UnitPosture>,
    with_economy: bool,
) -> GameState {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let participants = [
        participant(p1.clone(), "One"),
        participant(p2.clone(), "Two"),
    ];
    let identity =
        MatchIdentity::try_new(MatchRules::default(), participants, mode).expect("identity");
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
        started,
    )
    .expect("turn lifecycle");
    let mut second_unit = Unit::builder(
        UnitId::new("unit-2").expect("unit id"),
        p2.clone(),
        UnitKind::Commander,
        "unit-2",
        HexCoord::new(1, 0),
        MovementUnits::ZERO,
    );
    if let Some(posture) = second_unit_posture {
        second_unit = second_unit.with_posture(posture);
    }
    let units = [unit("unit-1", &p1), second_unit.build().expect("unit")];
    let interaction = if second_unit_posture.is_none() {
        aonw_domain::InteractionState::default().after_skip(&units[1])
    } else {
        aonw_domain::InteractionState::default()
    };
    let economy = with_economy.then(|| {
        aonw_domain::EconomyState::try_new(
            &identity,
            map().bounds(),
            BTreeMap::new(),
            BTreeMap::from([(p2.clone(), 1)]),
            BTreeMap::new(),
            BTreeMap::new(),
            aonw_domain::InitialResourceDistribution::default(),
        )
        .expect("economy")
    });
    let mut builder = GameState::builder(
        StateRevision::new(7),
        7,
        map().bounds(),
        UnitOccupancyPolicy::Exclusive,
        units,
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .with_interaction(interaction);
    if let Some(economy) = economy {
        builder = builder.with_economy(economy);
    }
    builder.try_build().expect("state")
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

fn unit(id: &str, owner: &PlayerId) -> Unit {
    Unit::builder(
        UnitId::new(id).expect("unit id"),
        owner.clone(),
        UnitKind::Commander,
        id,
        HexCoord::new(i32::from(id != "unit-1"), 0),
        MovementUnits::ZERO,
    )
    .build()
    .expect("unit")
}

fn map() -> MapDefinition {
    MapDefinition::try_new(
        "turn-kernel",
        GridLayout::OddQFlatTop,
        2,
        1,
        (0..2)
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
        Vec::new(),
    )
    .expect("map")
}

fn assert_turn_evidence(transition: &aonw_engine::DomainTransition, reset_count: usize) {
    let Some(ExecutionEvidence::TurnKernel(evidence)) = transition.evidence() else {
        panic!("expected turn kernel evidence")
    };
    assert_eq!(evidence.reset_unit_ids().len(), reset_count);
    assert!(
        evidence
            .processors()
            .iter()
            .all(|processor| TurnKernelCapabilities::supports(*processor))
    );
}

fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player id")
}

fn engine_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .find(|path| path.join("fixtures/turn_kernel").is_dir())
        .expect("engine root")
        .to_path_buf()
}
