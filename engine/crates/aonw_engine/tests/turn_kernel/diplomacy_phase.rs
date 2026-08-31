use std::collections::BTreeMap;

use aonw_content::RulesetDefinition;
use aonw_domain::{
    City, CityId, Diplomacy, DiplomaticMessage, DiplomaticMessageCategory,
    DiplomaticMessageResponse, DiplomaticMessageTopic, DiplomaticProposal, DiplomaticProposalKind,
    DiplomaticRelation, DiplomaticRelationStatus, EconomyState, GameMode, GameState,
    InitialResourceDistribution, MatchIdentity, MatchLifecycle, MatchRules, PlayerId, PlayerPair,
    PlayerTurnState, ResourceTradeAgreement, ResourceType, StateRevision,
    StrategicResourceStockpile, TurnLifecycle, UnitOccupancyPolicy,
};
use aonw_engine::{DomainEvent, EngineContext, GameEngine, PlayerCommand, TurnCommand};

use super::{map, participant, player, unit};

#[test]
fn turn_expiry_is_ordered_and_broken_promises_are_audited_once() {
    let (state, p1, p2) = expiry_state();
    let transition = end_round(state, &p2);
    assert!(transition.is_accepted());
    assert!(
        transition
            .state()
            .diplomacy()
            .pending_proposals()
            .is_empty()
    );
    assert!(
        transition
            .state()
            .diplomacy()
            .message("message-expired")
            .is_none()
    );
    assert!(
        transition
            .state()
            .diplomacy()
            .message("promise-due")
            .expect("retained promise")
            .promise_broken()
    );
    let relation = transition
        .state()
        .diplomacy()
        .relation_between(&p1, &p2)
        .expect("relation");
    assert_eq!(relation.status(), DiplomaticRelationStatus::Neutral);
    assert_eq!(relation.relation_score(), -5);
    assert_eq!(relation.status_expires_on_turn(), None);
    assert_eq!(relation.last_changed_turn(), Some(8));
    assert!(
        matches!(
            transition.events(),
            [
                DomainEvent::ResearchPointsGained(_),
                DomainEvent::DiplomaticProposalExpired(_),
                DomainEvent::DiplomaticRelationChanged(_),
                DomainEvent::DiplomaticPromiseBroken(_),
                DomainEvent::DiplomaticScoreChanged(_),
                DomainEvent::TurnEnded(_)
            ]
        ),
        "events: {:?}",
        transition.events()
    );
}

fn expiry_state() -> (GameState, PlayerId, PlayerId) {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let (identity, lifecycle) = lifecycle(&p1, &p2);
    let pair = PlayerPair::new(p1.clone(), p2.clone()).expect("pair");
    let relation = DiplomaticRelation::try_new(
        pair.clone(),
        DiplomaticRelationStatus::Truce,
        10,
        Some(8),
        Some(7),
        None,
    )
    .expect("relation");
    let proposal = DiplomaticProposal::try_new(
        "proposal-expired".to_owned(),
        p1.clone(),
        p2.clone(),
        DiplomaticProposalKind::Friendship,
        7,
        8,
        0,
    )
    .expect("proposal");
    let messages = [
        DiplomaticMessage::try_new(
            "message-expired".to_owned(),
            p1.clone(),
            p2.clone(),
            DiplomaticMessageTopic::PeacefulPraise,
            DiplomaticMessageCategory::Praise,
            7,
            8,
            None,
            None,
            0,
            None,
            None,
            false,
        )
        .expect("message"),
        DiplomaticMessage::try_new(
            "promise-due".to_owned(),
            p1.clone(),
            p2.clone(),
            DiplomaticMessageTopic::WithdrawScouts,
            DiplomaticMessageCategory::Request,
            4,
            9,
            Some(DiplomaticMessageResponse::Conciliatory),
            Some(5),
            12,
            Some(10),
            Some(8),
            false,
        )
        .expect("promise"),
    ];
    let diplomacy = Diplomacy::try_new(&identity, [pair], [relation], [proposal], messages, [], [])
        .expect("diplomacy");
    let city = City::builder(
        CityId::new("city-1").expect("city id"),
        p1.clone(),
        "city-1",
        aonw_domain::HexCoord::new(0, 0),
    )
    .build()
    .expect("city");
    let state = GameState::builder(
        StateRevision::new(7),
        7,
        map().bounds(),
        UnitOccupancyPolicy::Exclusive,
        [unit("unit-1", &p1), unit("unit-2", &p2)],
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .with_cities([city])
    .with_diplomacy(diplomacy)
    .try_build()
    .expect("state");
    (state, p1, p2)
}

#[test]
fn exchange_group_settles_resources_gold_bonus_and_duration_atomically() {
    let fixture = trade_state(DiplomaticRelationStatus::Friendly, (10, 10), (3, 5), 2);
    let transition = end_round(fixture.state, &fixture.p2);
    assert!(transition.is_accepted());
    let economy = transition.state().economy();
    assert_eq!(economy.player_gold().get(&fixture.p1), Some(&9));
    assert_eq!(economy.player_gold().get(&fixture.p2), Some(&13));
    assert_eq!(oil(economy, &fixture.p1), 5);
    assert_eq!(oil(economy, &fixture.p2), 3);
    let agreements = transition.state().diplomacy().resource_trade_agreements();
    assert_eq!(agreements.len(), 2);
    assert!(agreements.iter().all(|value| value.remaining_turns() == 1));
}

#[test]
fn exchange_group_failure_never_applies_only_one_leg() {
    let poor = trade_state(DiplomaticRelationStatus::Friendly, (3, 10), (3, 5), 2);
    let poor_before = poor.state.economy().clone();
    let expired = end_round(poor.state, &poor.p2);
    assert_trade_accounts_unchanged(expired.state().economy(), &poor_before);
    assert!(
        expired
            .state()
            .diplomacy()
            .resource_trade_agreements()
            .is_empty()
    );

    let war = trade_state(DiplomaticRelationStatus::War, (10, 10), (3, 5), 2);
    let war_before = war.state.economy().clone();
    let aged = end_round(war.state, &war.p2);
    assert_trade_accounts_unchanged(aged.state().economy(), &war_before);
    assert!(
        aged.state()
            .diplomacy()
            .resource_trade_agreements()
            .iter()
            .all(|value| value.remaining_turns() == 1)
    );

    let short = trade_state(DiplomaticRelationStatus::Neutral, (10, 10), (3, 4), 2);
    let short_before = short.state.economy().clone();
    let stock_failed = end_round(short.state, &short.p2);
    assert_trade_accounts_unchanged(stock_failed.state().economy(), &short_before);
    assert!(
        stock_failed
            .state()
            .diplomacy()
            .resource_trade_agreements()
            .iter()
            .all(|value| value.remaining_turns() == 1)
    );
}

fn assert_trade_accounts_unchanged(actual: &EconomyState, previous: &EconomyState) {
    assert_eq!(actual.player_gold(), previous.player_gold());
    assert_eq!(actual.strategic_resources(), previous.strategic_resources());
    assert_eq!(
        actual.initial_resource_distribution(),
        previous.initial_resource_distribution()
    );
}

struct TradeFixture {
    state: GameState,
    p1: PlayerId,
    p2: PlayerId,
}

fn trade_state(
    status: DiplomaticRelationStatus,
    gold: (i64, i64),
    stock: (i64, i64),
    remaining_turns: u32,
) -> TradeFixture {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let (identity, lifecycle) = lifecycle(&p1, &p2);
    let pair = PlayerPair::new(p1.clone(), p2.clone()).expect("pair");
    let relation =
        DiplomaticRelation::try_new(pair.clone(), status, 0, None, None, None).expect("relation");
    let agreements = [
        ResourceTradeAgreement::try_new(
            "exchange-offered".to_owned(),
            p1.clone(),
            p2.clone(),
            ResourceType::Oil,
            2,
            remaining_turns,
            3,
            Some("exchange".to_owned()),
        )
        .expect("offered"),
        ResourceTradeAgreement::try_new(
            "exchange-requested".to_owned(),
            p2.clone(),
            p1.clone(),
            ResourceType::Oil,
            4,
            remaining_turns,
            5,
            Some("exchange".to_owned()),
        )
        .expect("requested"),
    ];
    let diplomacy = Diplomacy::try_new(&identity, [pair], [relation], [], [], [], agreements)
        .expect("diplomacy");
    let economy = EconomyState::try_new(
        &identity,
        map().bounds(),
        BTreeMap::from([(p1.clone(), gold.0), (p2.clone(), gold.1)]),
        BTreeMap::new(),
        BTreeMap::new(),
        BTreeMap::from([
            (p1.clone(), stockpile(stock.0)),
            (p2.clone(), stockpile(stock.1)),
        ]),
        InitialResourceDistribution::default(),
    )
    .expect("economy");
    let state = GameState::builder(
        StateRevision::new(7),
        7,
        map().bounds(),
        UnitOccupancyPolicy::Exclusive,
        [unit("unit-1", &p1), unit("unit-2", &p2)],
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .with_economy(economy)
    .with_diplomacy(diplomacy)
    .try_build()
    .expect("state");
    TradeFixture { state, p1, p2 }
}

fn stockpile(oil: i64) -> StrategicResourceStockpile {
    StrategicResourceStockpile::try_new(BTreeMap::from([(ResourceType::Oil, oil)]))
        .expect("stockpile")
}

fn oil(economy: &EconomyState, player: &PlayerId) -> i64 {
    economy
        .strategic_resources()
        .get(player)
        .and_then(|value| value.amounts().get(&ResourceType::Oil))
        .copied()
        .unwrap_or(0)
}

fn lifecycle(p1: &PlayerId, p2: &PlayerId) -> (MatchIdentity, TurnLifecycle) {
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [
            participant(p1.clone(), "One"),
            participant(p2.clone(), "Two"),
        ],
        GameMode::HotSeat,
    )
    .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (p1.clone(), PlayerTurnState::Finished),
            (p2.clone(), PlayerTurnState::Active),
        ]),
        [p1.clone(), p2.clone()],
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle");
    (identity, lifecycle)
}

fn end_round(state: GameState, actor: &PlayerId) -> aonw_engine::DomainTransition {
    GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(actor, &map(), RulesetDefinition::standard()),
        PlayerCommand::EndTurn(TurnCommand::new(7, actor)),
    )
    .expect("end round")
}
