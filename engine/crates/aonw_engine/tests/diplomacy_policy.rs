//! Oracle-characterized read-only diplomacy-policy evidence for CP7/DP.

use std::collections::BTreeMap;
use std::path::{Path, PathBuf};

use aonw_domain::{
    Diplomacy, DiplomaticRelation, DiplomaticRelationStatus, GameMode, GameState, HexGridBounds,
    MatchIdentity, MatchLifecycle, MatchRules, Participant, PlayerCountry, PlayerId, PlayerKind,
    PlayerPair, PlayerTurnState, StateRevision, TurnLifecycle, UnitOccupancyPolicy,
};
use aonw_engine::{DiplomacyDisclosure, DiplomacyPolicyPlayerRole, DiplomacyPolicyQuery};
use serde::Deserialize;

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct PolicyManifest {
    cases: Vec<PolicyCase>,
}

#[derive(Clone, Copy, Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
enum ExpectedDecision {
    Allow,
    Deny,
}

impl ExpectedDecision {
    const fn value(self) -> bool {
        matches!(self, Self::Allow)
    }
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct PolicyCase {
    id: String,
    actor: String,
    counterparty: String,
    has_contact: bool,
    configured_status: Option<String>,
    expected_status: String,
    expected_disclosure: String,
    hostile: ExpectedDecision,
    city_entry: ExpectedDecision,
    territory_entry: ExpectedDecision,
    attack: ExpectedDecision,
    automation: ExpectedDecision,
    trade: ExpectedDecision,
}

#[test]
fn policy_manifest_covers_accepted_rejected_and_hidden_outcomes() {
    let manifest: PolicyManifest = serde_json::from_slice(
        &std::fs::read(repository_root().join("engine/fixtures/diplomacy_policy/manifest.json"))
            .expect("policy manifest"),
    )
    .expect("strict policy manifest");
    assert_eq!(manifest.cases.len(), 7);

    for case in manifest.cases {
        let state = state(case.has_contact, case.configured_status.as_deref());
        let actor = player(&case.actor);
        let counterparty = player(&case.counterparty);
        let policy = DiplomacyPolicyQuery::between(&state, &actor, &counterparty)
            .unwrap_or_else(|error| panic!("{}: {error}", case.id));

        assert_eq!(
            status_name(policy.status()),
            case.expected_status,
            "{}",
            case.id
        );
        assert_eq!(
            disclosure_name(policy.disclosure()),
            case.expected_disclosure,
            "{}",
            case.id
        );
        assert_eq!(policy.is_hostile(), case.hostile.value(), "{}", case.id);
        assert_eq!(
            policy.can_enter_city_center(),
            case.city_entry.value(),
            "{}",
            case.id
        );
        assert_eq!(
            policy.can_enter_territory(),
            case.territory_entry.value(),
            "{}",
            case.id
        );
        assert_eq!(policy.can_attack(), case.attack.value(), "{}", case.id);
        assert_eq!(
            policy.automation_eligible(),
            case.automation.value(),
            "{}",
            case.id
        );
        assert_eq!(policy.trade_eligible(), case.trade.value(), "{}", case.id);
    }
}

#[test]
fn unknown_player_validation_is_actor_first_and_fail_closed() {
    let state = state(false, None);
    let unknown_actor = player("unknown-actor");
    let unknown_counterparty = player("unknown-counterparty");
    let error = DiplomacyPolicyQuery::between(&state, &unknown_actor, &unknown_counterparty)
        .expect_err("unknown players must fail");
    assert_eq!(error.role(), DiplomacyPolicyPlayerRole::Actor);
    assert_eq!(error.player_id(), &unknown_actor);

    let actor = player("player-1");
    let error = DiplomacyPolicyQuery::between(&state, &actor, &unknown_counterparty)
        .expect_err("unknown counterparty must fail");
    assert_eq!(error.role(), DiplomacyPolicyPlayerRole::Counterparty);
    assert_eq!(error.player_id(), &unknown_counterparty);
}

#[test]
fn policy_manifest_rejects_unknown_fields() {
    let invalid = std::fs::read(
        repository_root().join("engine/fixtures/diplomacy_policy/invalid/unknown-field.json"),
    )
    .expect("invalid fixture");
    assert!(serde_json::from_slice::<PolicyManifest>(&invalid).is_err());
}

#[test]
fn changing_only_relation_status_changes_every_dependent_policy() {
    let friendly = policy_for("friendly");
    let war = policy_for("war");
    let truce = policy_for("truce");
    assert_ne!(friendly.is_hostile(), war.is_hostile());
    assert_ne!(friendly.can_enter_territory(), war.can_enter_territory());
    assert_ne!(friendly.can_attack(), war.can_attack());
    assert_ne!(friendly.automation_eligible(), war.automation_eligible());
    assert_ne!(friendly.trade_eligible(), war.trade_eligible());
    assert_ne!(friendly.disclosure(), war.disclosure());
    assert!(!friendly.can_enter_city_center());
    assert!(!war.can_enter_city_center());
    assert_eq!(friendly.status_expires_on_turn(), None);
    assert_eq!(truce.status_expires_on_turn(), Some(9));
}

fn policy_for(status: &str) -> aonw_engine::DiplomacyPolicy {
    let state = state(true, Some(status));
    DiplomacyPolicyQuery::between(&state, &player("player-1"), &player("player-2"))
        .expect("known players")
}

fn state(has_contact: bool, configured_status: Option<&str>) -> GameState {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [participant(p1.clone()), participant(p2.clone())],
        GameMode::Multiplayer,
    )
    .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (p1.clone(), PlayerTurnState::Active),
            (p2.clone(), PlayerTurnState::Active),
        ]),
        [p1.clone(), p2.clone()],
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("turn lifecycle");
    let pair = PlayerPair::new(p1, p2).expect("pair");
    let contacts = has_contact.then(|| pair.clone());
    let relations = configured_status.map(|status| {
        let status = parse_status(status);
        DiplomaticRelation::try_new(
            pair,
            status,
            0,
            (status == DiplomaticRelationStatus::Truce).then_some(9),
            None,
            None,
        )
        .expect("relation")
    });
    let diplomacy =
        Diplomacy::try_new(&identity, contacts, relations, [], [], [], []).expect("diplomacy");
    GameState::builder(
        StateRevision::new(1),
        1,
        HexGridBounds::new(1, 1).expect("bounds"),
        UnitOccupancyPolicy::Exclusive,
        [],
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .with_diplomacy(diplomacy)
    .try_build()
    .expect("state")
}

fn participant(id: PlayerId) -> Participant {
    Participant::try_new(
        id,
        "Player",
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Human,
        None,
    )
    .expect("participant")
}

fn player(value: &str) -> PlayerId {
    PlayerId::new(value).expect("player id")
}

fn parse_status(value: &str) -> DiplomaticRelationStatus {
    match value {
        "friendly" => DiplomaticRelationStatus::Friendly,
        "neutral" => DiplomaticRelationStatus::Neutral,
        "hostile" => DiplomaticRelationStatus::Hostile,
        "truce" => DiplomaticRelationStatus::Truce,
        "war" => DiplomaticRelationStatus::War,
        _ => panic!("unknown status {value}"),
    }
}

fn status_name(value: DiplomaticRelationStatus) -> &'static str {
    match value {
        DiplomaticRelationStatus::Friendly => "friendly",
        DiplomaticRelationStatus::Neutral => "neutral",
        DiplomaticRelationStatus::Hostile => "hostile",
        DiplomaticRelationStatus::Truce => "truce",
        DiplomaticRelationStatus::War => "war",
    }
}

fn disclosure_name(value: DiplomacyDisclosure) -> &'static str {
    match value {
        DiplomacyDisclosure::Own => "own",
        DiplomacyDisclosure::Known(_) => "known",
        DiplomacyDisclosure::Hidden => "hidden",
    }
}

fn repository_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .nth(3)
        .expect("repository root")
        .to_path_buf()
}
