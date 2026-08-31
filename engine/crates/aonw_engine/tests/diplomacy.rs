//! Canonical diplomacy proposal command evidence.

#[path = "diplomacy/messages.rs"]
mod messages;
#[path = "diplomacy/resource_trade.rs"]
mod resource_trade;
#[path = "diplomacy/war_gift.rs"]
mod war_gift;

use std::collections::BTreeMap;

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    City, CityConquestAction, CityId, CombatState, Diplomacy, DiplomaticProposalKind,
    DiplomaticRelation, DiplomaticRelationStatus, EconomyState, GameMode, GameState, HexCoord,
    IntendedAttack, MatchIdentity, MatchLifecycle, MatchRules, MovementUnits, Participant,
    PlayerCountry, PlayerId, PlayerKind, PlayerPair, PlayerTurnState, StateRevision, TurnLifecycle,
    Unit, UnitId, UnitKind, UnitOccupancyPolicy,
};
use aonw_engine::{
    CommandRejectionCode, DomainEvent, EngineContext, GameEngine, PlayerCommand,
    RespondDiplomaticProposalCommand, SendDiplomaticProposalCommand,
};

#[test]
fn friendship_proposal_is_private_deterministic_and_duplicate_safe() {
    let fixture = fixture(None, true, (20, 1), false);
    let sent = apply_send(
        fixture.state.clone(),
        &fixture,
        DiplomaticProposalKind::Friendship,
        Some("friendship-1"),
        99,
    );
    assert!(sent.is_accepted());
    assert_eq!(sent.revision(), StateRevision::new(12));
    let proposal = sent
        .state()
        .diplomacy()
        .proposal("friendship-1")
        .expect("proposal");
    assert_eq!(proposal.from_player_id(), &fixture.p1);
    assert_eq!(proposal.to_player_id(), &fixture.p2);
    assert_eq!(proposal.gold_payment(), 0);
    assert_eq!(proposal.created_turn(), 7);
    assert_eq!(proposal.expires_on_turn(), 12);
    let [DomainEvent::DiplomaticProposalSent(event)] = sent.events() else {
        panic!("proposal event")
    };
    assert_eq!(event.proposal_id(), "friendship-1");
    assert_eq!(event.from_player_id(), &fixture.p1);
    assert_eq!(event.to_player_id(), &fixture.p2);

    let repeated = GameEngine::apply_player_owned(
        sent.state().clone(),
        EngineContext::canonical(&fixture.p1, &fixture.map, RulesetDefinition::standard()),
        PlayerCommand::SendDiplomaticProposal(SendDiplomaticProposalCommand::new(
            12,
            &fixture.p2,
            DiplomaticProposalKind::Friendship,
            Some("friendship-2"),
            0,
        )),
    )
    .expect("duplicate rejection");
    assert_eq!(
        repeated.rejection().expect("rejection").code(),
        CommandRejectionCode::DiplomacyDuplicateProposal
    );
    assert_eq!(repeated.state(), sent.state());
}

#[test]
fn truce_acceptance_transfers_capped_gold_clears_attacks_and_orders_events() {
    let fixture = fixture(Some(DiplomaticRelationStatus::War), true, (20, 1), true);
    let sent = apply_send(
        fixture.state.clone(),
        &fixture,
        DiplomaticProposalKind::Truce,
        None,
        12,
    );
    let proposal_id = sent.state().diplomacy().pending_proposals()[0]
        .id()
        .to_owned();
    assert_eq!(proposal_id, "proposal.7.player-1.player-2.truce.0");
    let accepted = GameEngine::apply_player_owned(
        sent.state().clone(),
        EngineContext::canonical(&fixture.p2, &fixture.map, RulesetDefinition::standard()),
        PlayerCommand::RespondDiplomaticProposal(RespondDiplomaticProposalCommand::new(
            12,
            &proposal_id,
            true,
        )),
    )
    .expect("accept truce");
    assert!(accepted.is_accepted());
    assert_eq!(accepted.revision(), StateRevision::new(13));
    assert_eq!(
        accepted.state().economy().player_gold().get(&fixture.p1),
        Some(&8)
    );
    assert_eq!(
        accepted.state().economy().player_gold().get(&fixture.p2),
        Some(&13)
    );
    assert!(accepted.state().combat().intended_attacks().is_empty());
    let relation = accepted
        .state()
        .diplomacy()
        .relation_between(&fixture.p1, &fixture.p2)
        .expect("relation");
    assert_eq!(relation.status(), DiplomaticRelationStatus::Truce);
    assert_eq!(relation.relation_score(), -10);
    assert_eq!(relation.status_expires_on_turn(), Some(17));
    assert!(matches!(
        accepted.events(),
        [
            DomainEvent::DiplomaticProposalResponded(_),
            DomainEvent::DiplomaticRelationChanged(_),
            DomainEvent::DiplomaticScoreChanged(_)
        ]
    ));
}

#[test]
fn rejection_removes_proposal_and_applies_exact_score_penalty() {
    let fixture = fixture(None, true, (20, 1), false);
    let sent = apply_send(
        fixture.state.clone(),
        &fixture,
        DiplomaticProposalKind::Friendship,
        Some("declined"),
        0,
    );
    let rejected = GameEngine::apply_player_owned(
        sent.state().clone(),
        EngineContext::canonical(&fixture.p2, &fixture.map, RulesetDefinition::standard()),
        PlayerCommand::RespondDiplomaticProposal(RespondDiplomaticProposalCommand::new(
            12, "declined", false,
        )),
    )
    .expect("reject proposal");
    assert!(rejected.is_accepted());
    assert!(rejected.state().diplomacy().proposal("declined").is_none());
    let relation = rejected
        .state()
        .diplomacy()
        .relation_between(&fixture.p1, &fixture.p2)
        .expect("score relation");
    assert_eq!(relation.status(), DiplomaticRelationStatus::Neutral);
    assert_eq!(relation.relation_score(), -6);
    assert!(matches!(
        rejected.events(),
        [
            DomainEvent::DiplomaticProposalResponded(_),
            DomainEvent::DiplomaticScoreChanged(_)
        ]
    ));
}

#[test]
fn proposal_rejections_are_precedence_ordered_and_transactional() {
    let hidden = fixture(None, false, (20, 1), false);
    let stale = GameEngine::apply_player_owned(
        hidden.state.clone(),
        EngineContext::canonical(&hidden.p1, &hidden.map, RulesetDefinition::standard()),
        PlayerCommand::SendDiplomaticProposal(SendDiplomaticProposalCommand::new(
            10,
            &hidden.p2,
            DiplomaticProposalKind::Friendship,
            None,
            0,
        )),
    )
    .expect("stale");
    assert_eq!(
        stale.rejection().expect("rejection").code(),
        CommandRejectionCode::StaleRevision
    );
    let undiscovered = apply_send(
        hidden.state.clone(),
        &hidden,
        DiplomaticProposalKind::Friendship,
        None,
        0,
    );
    assert_eq!(
        undiscovered.rejection().expect("rejection").code(),
        CommandRejectionCode::DiplomacyTargetNotDiscovered
    );
    assert_eq!(undiscovered.state(), &hidden.state);

    let neutral = fixture(None, true, (20, 1), false);
    let disallowed = apply_send(
        neutral.state.clone(),
        &neutral,
        DiplomaticProposalKind::Truce,
        None,
        0,
    );
    assert_eq!(
        disallowed.rejection().expect("rejection").code(),
        CommandRejectionCode::DiplomacyProposalNotAllowed
    );
    assert_eq!(disallowed.state(), &neutral.state);
}

fn apply_send(
    state: GameState,
    fixture: &Fixture,
    kind: DiplomaticProposalKind,
    id: Option<&str>,
    gold: i64,
) -> aonw_engine::DomainTransition {
    GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&fixture.p1, &fixture.map, RulesetDefinition::standard()),
        PlayerCommand::SendDiplomaticProposal(SendDiplomaticProposalCommand::new(
            11,
            &fixture.p2,
            kind,
            id,
            gold,
        )),
    )
    .expect("proposal transition")
}

struct Fixture {
    map: MapDefinition,
    state: GameState,
    p1: PlayerId,
    p2: PlayerId,
    p3: PlayerId,
}

fn fixture(
    status: Option<DiplomaticRelationStatus>,
    contact: bool,
    gold: (i64, i64),
    with_attack: bool,
) -> Fixture {
    fixture_with_observer(status, contact, gold, with_attack, false)
}

fn fixture_with_observer(
    status: Option<DiplomaticRelationStatus>,
    contact: bool,
    gold: (i64, i64),
    with_attack: bool,
    observer_contacts: bool,
) -> Fixture {
    let map = map();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let p3 = player("player-3");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [
            participant(p1.clone(), 1),
            participant(p2.clone(), 2),
            participant(p3.clone(), 3),
        ],
        GameMode::Multiplayer,
    )
    .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
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
    .expect("lifecycle");
    let pair = PlayerPair::new(p1.clone(), p2.clone()).expect("pair");
    let relation = status.map(|value| {
        DiplomaticRelation::try_new(
            pair.clone(),
            value,
            -20,
            (value == DiplomaticRelationStatus::Truce).then_some(8),
            Some(2),
            None,
        )
        .expect("relation")
    });
    let mut contacts = contact.then_some(pair).into_iter().collect::<Vec<_>>();
    if observer_contacts {
        contacts.push(PlayerPair::new(p1.clone(), p3.clone()).expect("observer contact"));
        contacts.push(PlayerPair::new(p2.clone(), p3.clone()).expect("victim contact"));
    }
    let diplomacy =
        Diplomacy::try_new(&identity, contacts, relation, [], [], [], []).expect("diplomacy");
    let economy = EconomyState::try_new(
        &identity,
        map.bounds(),
        BTreeMap::from([(p1.clone(), gold.0), (p2.clone(), gold.1)]),
        BTreeMap::new(),
        BTreeMap::new(),
        BTreeMap::new(),
        aonw_domain::InitialResourceDistribution::default(),
    )
    .expect("economy");
    let attacker = unit("attacker", &p1, HexCoord::new(0, 0));
    let target = city("target", &p2, HexCoord::new(1, 0));
    let combat = CombatState::try_new(with_attack.then(|| {
        IntendedAttack::new(
            attacker.id().clone(),
            target.center(),
            StateRevision::new(5),
            p1.clone(),
            CityConquestAction::Capture,
        )
    }))
    .expect("combat");
    let state = GameState::builder(
        StateRevision::new(11),
        7,
        map.bounds(),
        UnitOccupancyPolicy::Exclusive,
        [attacker],
    )
    .with_cities([target])
    .with_economy(economy)
    .with_combat(combat)
    .with_diplomacy(diplomacy)
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state");
    Fixture {
        map,
        state,
        p1,
        p2,
        p3,
    }
}

fn map() -> MapDefinition {
    let tiles = (0..3)
        .map(|col| {
            TileDefinition::try_new_for_simulation(
                HexCoord::new(col, 0),
                vec![TerrainType::Plains],
                Vec::new(),
                0,
            )
            .expect("tile")
        })
        .collect();
    MapDefinition::try_new(
        "diplomacy",
        GridLayout::OddQFlatTop,
        3,
        1,
        tiles,
        Vec::new(),
    )
    .expect("map")
}

fn unit(id: &str, owner: &PlayerId, position: HexCoord) -> Unit {
    Unit::builder(
        UnitId::new(id).expect("unit id"),
        owner.clone(),
        UnitKind::Warrior,
        id,
        position,
        MovementUnits::new(100),
    )
    .build()
    .expect("unit")
}

fn city(id: &str, owner: &PlayerId, center: HexCoord) -> City {
    City::builder(CityId::new(id).expect("city id"), owner.clone(), id, center)
        .build()
        .expect("city")
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
