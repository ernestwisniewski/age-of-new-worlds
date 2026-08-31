use std::collections::BTreeMap;

use aonw_domain::{
    Diplomacy, DiplomaticMessage, DiplomaticMessageCategory, DiplomaticMessageTopic,
    DiplomaticProposal, DiplomaticProposalKind, DiplomaticRelation, DiplomaticRelationStatus,
    GameMode, GameState, HexGridBounds, MatchIdentity, MatchLifecycle, MatchRules, Participant,
    PlayerCountry, PlayerId, PlayerKind, PlayerPair, PlayerTurnState, ResourceTradeAgreement,
    ResourceType, StateRevision, TurnLifecycle, UnitOccupancyPolicy,
};

use super::diplomacy_view;

#[test]
fn projection_exposes_only_records_involving_the_recipient() {
    let fixture = fixture();

    let p1 = diplomacy_view(&fixture.state, &fixture.p1);
    assert_eq!(counterparts(&p1), ["player-2", "player-3"]);
    assert_eq!(
        p1.relations()[1].status(),
        DiplomaticRelationStatus::Neutral
    );
    assert_eq!(proposal_ids(&p1), ["proposal-12"]);
    assert_eq!(message_ids(&p1), ["message-12"]);
    assert_eq!(agreement_ids(&p1), ["trade-12"]);

    let p2 = diplomacy_view(&fixture.state, &fixture.p2);
    assert_eq!(counterparts(&p2), ["player-1", "player-3"]);
    assert_eq!(proposal_ids(&p2), ["proposal-12", "proposal-23"]);
    assert_eq!(message_ids(&p2), ["message-12", "message-23"]);
    assert_eq!(agreement_ids(&p2), ["trade-12", "trade-23"]);

    let p3 = diplomacy_view(&fixture.state, &fixture.p3);
    assert_eq!(counterparts(&p3), ["player-1", "player-2"]);
    assert_eq!(
        p3.relations()[0].status(),
        DiplomaticRelationStatus::Neutral
    );
    assert_eq!(proposal_ids(&p3), ["proposal-23"]);
    assert_eq!(message_ids(&p3), ["message-23"]);
    assert_eq!(agreement_ids(&p3), ["trade-23"]);
}

fn counterparts(view: &super::PlayerDiplomacyView) -> Vec<&str> {
    view.relations()
        .iter()
        .map(|relation| relation.counterpart_player_id().as_str())
        .collect()
}

fn proposal_ids(view: &super::PlayerDiplomacyView) -> Vec<&str> {
    view.proposals()
        .iter()
        .map(super::PlayerDiplomaticProposalView::id)
        .collect()
}

fn message_ids(view: &super::PlayerDiplomacyView) -> Vec<&str> {
    view.messages()
        .iter()
        .map(super::PlayerDiplomaticMessageView::id)
        .collect()
}

fn agreement_ids(view: &super::PlayerDiplomacyView) -> Vec<&str> {
    view.resource_trade_agreements()
        .iter()
        .map(super::PlayerResourceTradeAgreementView::id)
        .collect()
}

struct Fixture {
    state: GameState,
    p1: PlayerId,
    p2: PlayerId,
    p3: PlayerId,
}

fn fixture() -> Fixture {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let p3 = player("player-3");
    let identity = identity(&p1, &p2, &p3);
    let lifecycle = lifecycle(&identity, &p1, &p2, &p3);
    let pair12 = PlayerPair::new(p1.clone(), p2.clone()).expect("pair");
    let pair13 = PlayerPair::new(p1.clone(), p3.clone()).expect("pair");
    let pair23 = PlayerPair::new(p2.clone(), p3.clone()).expect("pair");
    let diplomacy = Diplomacy::try_new(
        &identity,
        [pair12.clone(), pair13, pair23.clone()],
        [
            relation(pair12, DiplomaticRelationStatus::Friendly),
            relation(pair23, DiplomaticRelationStatus::Hostile),
        ],
        [
            proposal("proposal-12", p1.clone(), p2.clone()),
            proposal("proposal-23", p2.clone(), p3.clone()),
        ],
        [
            message("message-12", p1.clone(), p2.clone()),
            message("message-23", p2.clone(), p3.clone()),
        ],
        [],
        [
            agreement("trade-12", p2.clone(), p1.clone()),
            agreement("trade-23", p3.clone(), p2.clone()),
        ],
    )
    .expect("recipient diplomacy");
    let state = GameState::builder(
        StateRevision::new(11),
        7,
        HexGridBounds::new(1, 1).expect("bounds"),
        UnitOccupancyPolicy::Exclusive,
        [],
    )
    .with_diplomacy(diplomacy)
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state");
    Fixture { state, p1, p2, p3 }
}

fn identity(p1: &PlayerId, p2: &PlayerId, p3: &PlayerId) -> MatchIdentity {
    MatchIdentity::try_new(
        MatchRules::default(),
        [
            participant(p1.clone(), 1),
            participant(p2.clone(), 2),
            participant(p3.clone(), 3),
        ],
        GameMode::Multiplayer,
    )
    .expect("identity")
}

fn lifecycle(
    identity: &MatchIdentity,
    p1: &PlayerId,
    p2: &PlayerId,
    p3: &PlayerId,
) -> TurnLifecycle {
    TurnLifecycle::try_new(
        identity,
        BTreeMap::from([
            (p1.clone(), PlayerTurnState::Active),
            (p2.clone(), PlayerTurnState::Active),
            (p3.clone(), PlayerTurnState::Active),
        ]),
        [p1.clone(), p2.clone(), p3.clone()],
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle")
}

fn relation(pair: PlayerPair, status: DiplomaticRelationStatus) -> DiplomaticRelation {
    DiplomaticRelation::try_new(pair, status, 10, None, Some(7), None).expect("relation")
}

fn proposal(id: &str, from: PlayerId, to: PlayerId) -> DiplomaticProposal {
    DiplomaticProposal::try_new(
        id.to_owned(),
        from,
        to,
        DiplomaticProposalKind::Friendship,
        7,
        12,
        0,
    )
    .expect("proposal")
}

fn message(id: &str, from: PlayerId, to: PlayerId) -> DiplomaticMessage {
    DiplomaticMessage::try_new(
        id.to_owned(),
        from,
        to,
        DiplomaticMessageTopic::WithdrawScouts,
        DiplomaticMessageCategory::Request,
        7,
        12,
        None,
        None,
        0,
        None,
        None,
        false,
    )
    .expect("message")
}

fn agreement(id: &str, exporter: PlayerId, importer: PlayerId) -> ResourceTradeAgreement {
    ResourceTradeAgreement::try_new(
        id.to_owned(),
        exporter,
        importer,
        ResourceType::Iron,
        3,
        5,
        1,
        None,
    )
    .expect("agreement")
}

fn participant(id: PlayerId, color: u32) -> Participant {
    Participant::try_new(
        id,
        "Player",
        0xff00_0000 + color,
        PlayerCountry::Poland,
        PlayerKind::Human,
        None,
    )
    .expect("participant")
}

fn player(value: &str) -> PlayerId {
    PlayerId::new(value).expect("player")
}
