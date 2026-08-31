use super::{
    Diplomacy, DiplomacyStateBuildError, DiplomaticMessage, DiplomaticMessageCategory,
    DiplomaticMessageTopic, DiplomaticProposal, DiplomaticProposalKind, DiplomaticRelation,
    DiplomaticRelationChangeReason, DiplomaticRelationStatus, DiplomaticScoreChangeReason,
    DiplomaticScoreEntry, PlayerPair, ResourceTradeAgreement, attack_status_severity,
};
use crate::{
    GameMode, MatchIdentity, MatchRules, Participant, PlayerCountry, PlayerId, PlayerKind,
    ResourceType, WorldArtifactType,
};

#[test]
fn repeated_unit_attack_preserves_stronger_status_and_uses_unique_source() {
    let fixture = fixture();
    let updated = fixture
        .diplomacy
        .after_unit_attack(
            &fixture.identity,
            &fixture.attacker,
            &fixture.defender,
            8,
            "unit-7",
        )
        .expect("unit attack");

    let relation = relation(&updated, &fixture.attacker, &fixture.defender);
    assert_eq!(relation.status(), DiplomaticRelationStatus::War);
    assert_eq!(relation.relation_score(), -100);
    assert_eq!(relation.status_expires_on_turn(), Some(99));
    assert_eq!(relation.last_changed_turn(), Some(3));
    assert_eq!(
        relation.last_change_reason(),
        Some(DiplomaticRelationChangeReason::Manual)
    );
    assert_eq!(
        updated.score_history().last().expect("entry").source_id(),
        Some("unit_attack.8.unit-7")
    );
    assert_eq!(updated.resource_trade_agreements().len(), 2);
}

#[test]
fn city_attack_escalates_expires_penalizes_both_observer_orderings_and_ends_trade() {
    let fixture = fixture();
    let updated = fixture
        .diplomacy
        .after_city_attack(
            &fixture.identity,
            &fixture.attacker,
            &fixture.defender,
            9,
            "unit-9",
        )
        .expect("city attack");

    let primary = relation(&updated, &fixture.attacker, &fixture.defender);
    assert_eq!(primary.status(), DiplomaticRelationStatus::War);
    assert_eq!(primary.relation_score(), -100);
    assert_eq!(primary.status_expires_on_turn(), None);
    assert_eq!(primary.last_changed_turn(), Some(9));
    assert_eq!(
        primary.last_change_reason(),
        Some(DiplomaticRelationChangeReason::CityAttack)
    );

    let lower = relation(&updated, &fixture.lower_observer, &fixture.attacker);
    assert_eq!(lower.status(), DiplomaticRelationStatus::Friendly);
    assert_eq!(lower.relation_score(), 8);
    assert_eq!(lower.status_expires_on_turn(), Some(12));
    let upper = relation(&updated, &fixture.upper_observer, &fixture.attacker);
    assert_eq!(upper.status(), DiplomaticRelationStatus::Neutral);
    assert_eq!(upper.relation_score(), -12);
    assert!(updated.score_history().iter().any(|entry| {
        entry.reason() == DiplomaticScoreChangeReason::WarmongerPenalty
            && entry.source_id() == Some("city_attack.9.unit-9")
    }));
    assert_eq!(updated.resource_trade_agreements().len(), 1);
    assert_eq!(
        updated.resource_trade_agreements()[0].id(),
        "unrelated-trade"
    );
}

#[test]
fn attack_status_severity_covers_every_status() {
    assert_eq!(
        attack_status_severity(DiplomaticRelationStatus::Friendly),
        0
    );
    assert_eq!(attack_status_severity(DiplomaticRelationStatus::Neutral), 0);
    assert_eq!(attack_status_severity(DiplomaticRelationStatus::Truce), 0);
    assert_eq!(attack_status_severity(DiplomaticRelationStatus::Hostile), 1);
    assert_eq!(attack_status_severity(DiplomaticRelationStatus::War), 2);
    for artifact_type in [
        WorldArtifactType::AstronomersTablets,
        WorldArtifactType::ProphetMask,
        WorldArtifactType::HeroSword,
        WorldArtifactType::MerchantsSeal,
        WorldArtifactType::FirstPeoplesChronicle,
        WorldArtifactType::QueensMirror,
    ] {
        assert_eq!(artifact_type.stored_city_defense_bonus(), 0);
    }
}

#[test]
fn proposal_transitions_are_ordered_and_duplicate_safe() {
    let fixture = fixture();
    let second = proposal("proposal-z", &fixture.attacker, &fixture.defender);
    let first = proposal("proposal-a", &fixture.defender, &fixture.attacker);
    let updated = fixture
        .diplomacy
        .try_with_proposal(&fixture.identity, second)
        .and_then(|state| state.try_with_proposal(&fixture.identity, first.clone()))
        .expect("proposals");
    assert_eq!(updated.pending_proposals()[0].id(), "proposal-a");
    assert_eq!(updated.proposal("proposal-a"), Some(&first));
    assert_eq!(
        updated.try_with_proposal(&fixture.identity, first),
        Err(DiplomacyStateBuildError::DuplicateId(
            "proposal-a".to_owned()
        ))
    );
    let removed = updated
        .try_without_proposal(&fixture.identity, "proposal-a")
        .expect("remove proposal");
    assert!(removed.proposal("proposal-a").is_none());
    assert_eq!(
        removed
            .try_without_proposal(&fixture.identity, "absent")
            .expect("absent proposal"),
        removed
    );
}

#[test]
fn message_and_relation_transitions_replace_exact_canonical_records() {
    let fixture = fixture();
    let initial_message = message("message-1", &fixture.attacker, &fixture.defender, None);
    let state = fixture
        .diplomacy
        .try_with_message(&fixture.identity, initial_message)
        .expect("message");
    let responded = message("message-1", &fixture.attacker, &fixture.defender, Some(7));
    let state = state
        .try_replacing_message(&fixture.identity, responded.clone())
        .expect("replace message");
    assert_eq!(state.message("message-1"), Some(&responded));
    assert!(matches!(
        state.try_replacing_message(
            &fixture.identity,
            message("missing", &fixture.attacker, &fixture.defender, None)
        ),
        Err(DiplomacyStateBuildError::IdNotFound(id)) if id == "missing"
    ));

    let pair = pair(&fixture.attacker, &fixture.defender);
    let relation = DiplomaticRelation::try_new(
        pair,
        DiplomaticRelationStatus::Friendly,
        42,
        None,
        Some(7),
        Some(DiplomaticRelationChangeReason::ProposalAccepted),
    )
    .expect("relation");
    let state = state
        .try_with_relation(&fixture.identity, relation)
        .expect("replace relation");
    assert_eq!(
        state
            .relation_between(&fixture.attacker, &fixture.defender)
            .expect("relation")
            .relation_score(),
        42
    );
}

#[test]
fn pair_cleanup_removes_only_bilateral_pending_actions_and_trades() {
    let fixture = fixture();
    let state = fixture
        .diplomacy
        .try_with_proposal(
            &fixture.identity,
            proposal("proposal-1", &fixture.attacker, &fixture.defender),
        )
        .and_then(|state| {
            state.try_with_message(
                &fixture.identity,
                message("message-1", &fixture.defender, &fixture.attacker, None),
            )
        })
        .expect("pending actions");
    let cleaned = state
        .try_without_pair_pending_actions(
            &fixture.identity,
            &pair(&fixture.attacker, &fixture.defender),
        )
        .expect("pair cleanup");
    assert!(cleaned.pending_proposals().is_empty());
    assert!(cleaned.messages().is_empty());
    assert_eq!(cleaned.resource_trade_agreements().len(), 1);
    assert_eq!(
        cleaned.resource_trade_agreements()[0].id(),
        "unrelated-trade"
    );
}

struct Fixture {
    identity: MatchIdentity,
    diplomacy: Diplomacy,
    attacker: PlayerId,
    defender: PlayerId,
    lower_observer: PlayerId,
    upper_observer: PlayerId,
}

fn fixture() -> Fixture {
    let lower_observer = player("alpha");
    let defender = player("defender");
    let attacker = player("middle");
    let upper_observer = player("zulu");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [
            participant(lower_observer.clone()),
            participant(defender.clone()),
            participant(attacker.clone()),
            participant(upper_observer.clone()),
        ],
        GameMode::Multiplayer,
    )
    .expect("identity");
    let primary_pair = pair(&attacker, &defender);
    let lower_pair = pair(&lower_observer, &attacker);
    let contacts = [
        primary_pair.clone(),
        lower_pair.clone(),
        pair(&lower_observer, &defender),
        pair(&attacker, &upper_observer),
        pair(&defender, &upper_observer),
    ];
    let primary = DiplomaticRelation::try_new(
        primary_pair.clone(),
        DiplomaticRelationStatus::War,
        -95,
        Some(99),
        Some(3),
        Some(DiplomaticRelationChangeReason::Manual),
    )
    .expect("primary relation");
    let lower = DiplomaticRelation::try_new(
        lower_pair,
        DiplomaticRelationStatus::Friendly,
        20,
        Some(12),
        Some(2),
        Some(DiplomaticRelationChangeReason::ProposalAccepted),
    )
    .expect("observer relation");
    let prior = DiplomaticScoreEntry::try_new(
        primary_pair,
        8,
        -5,
        -95,
        DiplomaticScoreChangeReason::Manual,
        None,
    )
    .expect("prior score");
    let bilateral = trade("bilateral-trade", &attacker, &defender);
    let unrelated = trade("unrelated-trade", &lower_observer, &upper_observer);
    let diplomacy = Diplomacy::try_new(
        &identity,
        contacts,
        [primary, lower],
        [],
        [],
        [prior],
        [bilateral, unrelated],
    )
    .expect("diplomacy");
    Fixture {
        identity,
        diplomacy,
        attacker,
        defender,
        lower_observer,
        upper_observer,
    }
}

fn relation<'a>(
    diplomacy: &'a Diplomacy,
    left: &PlayerId,
    right: &PlayerId,
) -> &'a DiplomaticRelation {
    let pair = pair(left, right);
    diplomacy
        .relations()
        .iter()
        .find(|value| value.pair() == &pair)
        .expect("relation")
}

fn trade(id: &str, exporter: &PlayerId, importer: &PlayerId) -> ResourceTradeAgreement {
    ResourceTradeAgreement::try_new(
        id.to_owned(),
        exporter.clone(),
        importer.clone(),
        ResourceType::Iron,
        2,
        3,
        1,
        None,
    )
    .expect("trade")
}

fn proposal(id: &str, from: &PlayerId, to: &PlayerId) -> DiplomaticProposal {
    DiplomaticProposal::try_new(
        id.to_owned(),
        from.clone(),
        to.clone(),
        DiplomaticProposalKind::Friendship,
        2,
        7,
        0,
    )
    .expect("proposal")
}

fn message(
    id: &str,
    from: &PlayerId,
    to: &PlayerId,
    responded_turn: Option<u32>,
) -> DiplomaticMessage {
    DiplomaticMessage::try_new(
        id.to_owned(),
        from.clone(),
        to.clone(),
        DiplomaticMessageTopic::PeacefulPraise,
        DiplomaticMessageCategory::Praise,
        2,
        7,
        responded_turn.map(|_| super::DiplomaticMessageResponse::Neutral),
        responded_turn,
        0,
        responded_turn.map(|_| 0),
        None,
        false,
    )
    .expect("message")
}

fn pair(left: &PlayerId, right: &PlayerId) -> PlayerPair {
    PlayerPair::new(left.clone(), right.clone()).expect("pair")
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
    PlayerId::new(value).expect("player")
}
