use std::collections::BTreeMap;

use aonw_content::{
    GridLayout, MapDefinition, ResourceType as MapResourceType, RulesetDefinition, TerrainType,
    TileDefinition,
};
use aonw_domain::{
    City, CityId, Diplomacy, DiplomaticRelation, DiplomaticRelationStatus, EconomyState, GameMode,
    GameState, HexCoord, MatchIdentity, MatchLifecycle, MatchRules, Participant, PlayerCountry,
    PlayerId, PlayerKind, PlayerPair, PlayerTurnState, ResourceTradeAgreement, ResourceType,
    StateRevision, TurnLifecycle, UnitOccupancyPolicy,
};
use aonw_engine::{
    CommandRejectionCode, EngineContext, GameEngine, OpenResourceExchangeCommand,
    OpenResourceTradeCommand, PlayerCommand,
};

pub(super) struct Fixture {
    pub(super) map: MapDefinition,
    pub(super) state: GameState,
    pub(super) p1: PlayerId,
    pub(super) p2: PlayerId,
}

pub(super) fn fixture(
    status: Option<DiplomaticRelationStatus>,
    actor_gold: i64,
    contact: bool,
    agreements: impl IntoIterator<Item = ResourceTradeAgreement>,
) -> Fixture {
    let map = resource_map();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [participant(p1.clone(), 1), participant(p2.clone(), 2)],
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
    .expect("lifecycle");
    let pair = PlayerPair::new(p1.clone(), p2.clone()).expect("pair");
    let relation = status.map(|status| {
        DiplomaticRelation::try_new(pair.clone(), status, 0, None, Some(2), None).expect("relation")
    });
    let diplomacy = Diplomacy::try_new(
        &identity,
        contact.then_some(pair),
        relation,
        [],
        [],
        [],
        agreements,
    )
    .expect("diplomacy");
    let economy = EconomyState::try_new(
        &identity,
        map.bounds(),
        BTreeMap::from([(p1.clone(), actor_gold), (p2.clone(), 5)]),
        BTreeMap::new(),
        BTreeMap::new(),
        BTreeMap::new(),
        aonw_domain::InitialResourceDistribution::default(),
    )
    .expect("economy");
    let actor_city = City::builder(
        CityId::new("city-1").expect("city id"),
        p1.clone(),
        "Actor",
        HexCoord::new(0, 0),
    )
    .with_controlled_hexes([HexCoord::new(1, 0), HexCoord::new(2, 0)])
    .build()
    .expect("actor city");
    let target_city = City::builder(
        CityId::new("city-2").expect("city id"),
        p2.clone(),
        "Target",
        HexCoord::new(3, 0),
    )
    .with_controlled_hexes([HexCoord::new(4, 0), HexCoord::new(5, 0)])
    .build()
    .expect("target city");
    let state = GameState::builder(
        StateRevision::new(11),
        7,
        map.bounds(),
        UnitOccupancyPolicy::Exclusive,
        [],
    )
    .with_cities([actor_city, target_city])
    .with_economy(economy)
    .with_diplomacy(diplomacy)
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state");
    Fixture { map, state, p1, p2 }
}

fn resource_map() -> MapDefinition {
    let resources = [
        None,
        Some(MapResourceType::Iron),
        Some(MapResourceType::Marble),
        None,
        Some(MapResourceType::Iron),
        Some(MapResourceType::Marble),
    ];
    let tiles = resources
        .into_iter()
        .enumerate()
        .map(|(col, resource)| {
            TileDefinition::try_new_for_simulation(
                HexCoord::new(i32::try_from(col).expect("small map"), 0),
                vec![TerrainType::Plains],
                resource.into_iter().collect(),
                0,
            )
            .expect("tile")
        })
        .collect();
    MapDefinition::try_new(
        "resource-trade",
        GridLayout::OddQFlatTop,
        6,
        1,
        tiles,
        Vec::new(),
    )
    .expect("map")
}

pub(super) fn apply_trade(
    state: GameState,
    fixture: &Fixture,
    expected_revision: u64,
    resource: ResourceType,
    gold_per_turn: i64,
    duration_turns: i64,
    agreement_id: Option<&str>,
) -> aonw_engine::DomainTransition {
    GameEngine::apply_player_owned(
        state,
        context(fixture),
        PlayerCommand::OpenResourceTrade(OpenResourceTradeCommand::new(
            expected_revision,
            &fixture.p2,
            resource,
            gold_per_turn,
            duration_turns,
            agreement_id,
        )),
    )
    .expect("resource trade transition")
}

pub(super) fn apply_exchange(
    state: GameState,
    fixture: &Fixture,
    expected_revision: u64,
    offered: ResourceType,
    requested: ResourceType,
    duration_turns: i64,
    agreement_id: Option<&str>,
) -> aonw_engine::DomainTransition {
    GameEngine::apply_player_owned(
        state,
        context(fixture),
        PlayerCommand::OpenResourceExchange(OpenResourceExchangeCommand::new(
            expected_revision,
            &fixture.p2,
            offered,
            requested,
            duration_turns,
            agreement_id,
        )),
    )
    .expect("resource exchange transition")
}

pub(super) fn context(fixture: &Fixture) -> EngineContext<'_> {
    EngineContext::canonical(&fixture.p1, &fixture.map, RulesetDefinition::standard())
}

pub(super) fn assert_rejected(
    transition: &aonw_engine::DomainTransition,
    code: CommandRejectionCode,
    expected_state: &GameState,
) {
    assert_eq!(transition.rejection().expect("rejection").code(), code);
    assert_eq!(transition.state(), expected_state);
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
