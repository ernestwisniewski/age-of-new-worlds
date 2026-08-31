//! Current combat query, dispatch, save, replay, and tamper-evidence tests.

use std::collections::BTreeMap;

use aonw_content::RulesetDefinition;
use aonw_contracts::{CityConquestActionDto, ReplayEvidenceDto, ReplayLogDto};
use aonw_domain::{
    CityConquestAction, CombatState, FogOfWar, GameMode, GameState, HexCoord, IntendedAttack,
    MatchIdentity, MatchLifecycle, MatchRules, PlayerFog, PlayerTurnState, StateRevision,
    TurnLifecycle, UnitKind,
};
use aonw_engine::ExecutionEvidence;
use aonw_local_runtime::{
    AttackHexRequest, CombatPreviewRequest, LocalRuntime, OpenSession, RuntimeQuery,
    RuntimeQueryResult,
};

#[path = "combat_runtime/common.rs"]
mod common;

use common::*;

#[test]
fn combat_preview_dispatch_save_and_replay_use_one_exact_execution() {
    let (map, rules, state, actor) = fixture();
    let attacker_id = unit_id("attacker");
    let defender_id = unit_id("defender");
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(
            map.clone(),
            rules.clone(),
            state,
            actor,
        ))
        .expect("open");

    let query = runtime
        .query(&RuntimeQuery::CombatPreview(CombatPreviewRequest {
            expected_revision: 11,
            attacker_unit_id: attacker_id.clone(),
            defender: HexCoord::new(1, 0),
        }))
        .expect("preview");
    let RuntimeQueryResult::CombatPreview { preview, .. } = query else {
        panic!("combat preview")
    };
    assert_eq!(preview.outgoing_damage, (1, 5));

    let result = runtime
        .attack_hex(&AttackHexRequest {
            expected_revision: 11,
            attacker_unit_id: attacker_id,
            defender: HexCoord::new(1, 0),
            city_conquest_action: CityConquestAction::Capture,
        })
        .expect("attack");
    assert!(result.is_accepted());
    assert!(result.view_patch.removed_unit_ids.contains(&defender_id));
    let Some(ExecutionEvidence::Combat(execution)) = result.evidence.as_ref() else {
        panic!("combat execution")
    };
    assert_eq!(execution.preview, preview);
    assert_eq!(execution.seed, 2_280_806_018);

    let save = runtime.export_save_json().expect("save");
    let expected = runtime.snapshot().expect("snapshot");
    let mut reopened = LocalRuntime::default();
    reopened
        .open_save_json(map.clone(), rules.clone(), &save)
        .expect("reopen");
    assert_eq!(reopened.snapshot().expect("reopened"), expected);

    let replay_json = runtime.export_replay_json().expect("replay");
    let verification = LocalRuntime::verify_replay_json(map.clone(), rules.clone(), &replay_json)
        .expect("verify replay");
    assert_eq!(verification.entry_count, 1);
    assert_eq!(verification.final_stamp, result.stamp);

    let replay = ReplayLogDto::from_json(&replay_json).expect("replay DTO");

    let mut tampered = replay.clone();
    let Some(ReplayEvidenceDto::Combat { execution }) =
        tampered.segments[0].entries[0].result.evidence.as_mut()
    else {
        panic!("persisted combat evidence")
    };
    execution.rolls[0].value = execution.rolls[0].value.saturating_add(1);
    let tampered = tampered.to_json().expect("tampered replay");
    assert!(LocalRuntime::verify_replay_json(map.clone(), rules.clone(), &tampered).is_err());

    let mut tampered = replay.clone();
    tampered.segments[0].entries[0].result.events.pop();
    let tampered = tampered.to_json().expect("event-tampered replay");
    assert!(LocalRuntime::verify_replay_json(map.clone(), rules.clone(), &tampered).is_err());

    let mut tampered = replay;
    let Some(ReplayEvidenceDto::Combat { execution }) =
        tampered.segments[0].entries[0].result.evidence.as_mut()
    else {
        panic!("persisted combat evidence")
    };
    execution.outcome.outgoing_damage = execution.outcome.outgoing_damage.saturating_add(1);
    let tampered = tampered.to_json().expect("evidence-tampered replay");
    assert!(LocalRuntime::verify_replay_json(map, rules, &tampered).is_err());
}

#[test]
fn client_turn_result_redacts_hidden_combat_but_replay_keeps_canonical_evidence() {
    let rules = RulesetDefinition::standard().clone();
    let map = hidden_combat_map();
    let observer = player("observer");
    let attacker_owner = player("attacker-owner");
    let defender_owner = player("defender-owner");
    let attacker_id = unit_id("hidden-attacker");
    let defender_id = unit_id("hidden-defender");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [
            participant(&observer),
            participant(&attacker_owner),
            participant(&defender_owner),
        ],
        GameMode::Multiplayer,
    )
    .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (observer.clone(), PlayerTurnState::Active),
            (attacker_owner.clone(), PlayerTurnState::Finished),
            (defender_owner.clone(), PlayerTurnState::Finished),
        ]),
        [
            observer.clone(),
            attacker_owner.clone(),
            defender_owner.clone(),
        ],
        [attacker_owner.clone(), defender_owner.clone()],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle");
    let observer_position = HexCoord::new(7, 1);
    let fog = FogOfWar::try_new([
        PlayerFog::new(observer.clone(), [observer_position], [observer_position]),
        PlayerFog::new(attacker_owner.clone(), [], []),
        PlayerFog::new(defender_owner.clone(), [], []),
    ])
    .expect("fog");
    let combat = CombatState::try_new([IntendedAttack::new(
        attacker_id.clone(),
        HexCoord::new(1, 0),
        StateRevision::new(1),
        attacker_owner.clone(),
        CityConquestAction::Capture,
    )])
    .expect("combat");
    let state = GameState::builder(
        StateRevision::new(11),
        7,
        map.bounds(),
        rules.occupancy_policy(),
        [
            unit(
                attacker_id.as_str(),
                &attacker_owner,
                UnitKind::Warrior,
                HexCoord::new(0, 0),
            ),
            unit(
                defender_id.as_str(),
                &defender_owner,
                UnitKind::Settler,
                HexCoord::new(1, 0),
            ),
            unit(
                "observer-unit",
                &observer,
                UnitKind::Scout,
                observer_position,
            ),
        ],
    )
    .with_fog_of_war(fog)
    .with_combat(combat)
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state");
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(
            map.clone(),
            rules.clone(),
            state,
            observer,
        ))
        .expect("open");

    let response = submit_turn_json(&mut runtime);
    assert!(!response.contains(attacker_id.as_str()));
    assert!(!response.contains(defender_id.as_str()));
    assert!(!response.contains("\"seed\""));
    assert!(response.contains("\"combatExecutions\":[]"));

    assert_hidden_replay(&runtime, map, rules, &attacker_id, &defender_id);
}

#[test]
fn visible_client_and_replay_encode_unit_city_retreat_and_conquest_events() {
    let (map, rules, state, actor) = fixture();
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(
            map.clone(),
            rules.clone(),
            state,
            actor,
        ))
        .expect("open unit combat");
    let preview_response = dispatch_preview_json(&mut runtime, "attacker", HexCoord::new(1, 0));
    assert!(preview_response.contains("combatPreview"));
    let response = dispatch_attack_json(
        &mut runtime,
        "attacker",
        HexCoord::new(1, 0),
        CityConquestActionDto::Capture,
    );
    assert!(response.contains("unitAttacked"));
    assert!(response.contains("combatResolved"));
    assert!(response.contains("unitGainedExperience"));
    assert!(response.contains("unitKilled"));
    runtime.export_replay_json().expect("unit replay");

    for (action, event) in [
        (CityConquestActionDto::Capture, "cityCaptured"),
        (CityConquestActionDto::Destroy, "cityDestroyed"),
    ] {
        let (map, rules, state, actor) = city_fixture();
        let mut runtime = LocalRuntime::default();
        runtime
            .open(OpenSession::from_state(
                map.clone(),
                rules.clone(),
                state,
                actor,
            ))
            .expect("open city combat");
        let response = dispatch_attack_json(&mut runtime, "tank", HexCoord::new(1, 0), action);
        assert!(response.contains("cityAttacked"));
        assert!(response.contains("diplomaticScoreChanged"));
        assert!(response.contains(event));
        runtime.export_replay_json().expect("city replay");
    }

    let (map, rules, state, actor) = retreat_fixture();
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(map, rules, state, actor))
        .expect("open retreat combat");
    let response = dispatch_attack_json(
        &mut runtime,
        "archer",
        HexCoord::new(1, 0),
        CityConquestActionDto::Capture,
    );
    assert!(response.contains("unitRetreated"));
    runtime.export_replay_json().expect("retreat replay");
}
