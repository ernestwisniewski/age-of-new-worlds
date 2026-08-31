use std::collections::BTreeMap;

use aonw_content::{
    GridLayout, MapDefinition, ResourceType as MapResourceType, RulesetDefinition, TerrainType,
    TileDefinition,
};
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientCommandDto, ClientOutcomeDto, ClientRequestBodyDto, ClientRequestDto,
    ClientResponseBodyDto, ClientResponseDto,
};
use aonw_domain::{
    City, CityId, Diplomacy, DiplomaticMessage, DiplomaticProposal, EconomyState, GameMode,
    GameState, HexCoord, MatchIdentity, MatchLifecycle, MatchRules, Participant, PlayerCountry,
    PlayerId, PlayerKind, PlayerPair, PlayerTurnState, StateRevision, TurnLifecycle,
};
use aonw_local_runtime::{ClientProtocol, LocalRuntime, OpenSession};

pub(super) fn dispatch(
    runtime: &mut LocalRuntime,
    command: ClientCommandDto,
) -> aonw_contracts::client::ClientCommandResultDto {
    let response = dispatch_body(runtime, ClientRequestBodyDto::Dispatch { command });
    let ClientResponseBodyDto::Command { result } = response else {
        panic!("command response")
    };
    *result
}

pub(super) fn dispatch_body(
    runtime: &mut LocalRuntime,
    request: ClientRequestBodyDto,
) -> ClientResponseBodyDto {
    let request = ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request,
    }
    .to_json()
    .expect("request JSON");
    let response = ClientResponseDto::from_json(&ClientProtocol::dispatch_json(runtime, &request))
        .expect("response JSON");
    let ClientOutcomeDto::Success { response } = response.outcome else {
        panic!("protocol failure")
    };
    *response
}

pub(super) fn verify_one_entry(
    runtime: &LocalRuntime,
    map: MapDefinition,
    ruleset: RulesetDefinition,
) {
    let replay = runtime.export_replay_json().expect("replay");
    assert!(
        replay.contains("Diplomatic")
            || replay.contains("diplomatic")
            || replay.contains("Resource")
            || replay.contains("resource")
    );
    let verification = LocalRuntime::verify_replay_json(map, ruleset, &replay).expect("verify");
    assert_eq!(verification.entry_count, 1);
}

pub(super) fn open_runtime(
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    state: GameState,
    actor: PlayerId,
) -> LocalRuntime {
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(
            map.clone(),
            ruleset.clone(),
            state,
            actor,
        ))
        .expect("open");
    runtime
}

pub(super) fn state(proposal: Option<DiplomaticProposal>) -> GameState {
    state_with_records(proposal, None)
}

pub(super) fn state_with_message(message: DiplomaticMessage) -> GameState {
    state_with_records(None, Some(message))
}

fn state_with_records(
    proposal: Option<DiplomaticProposal>,
    message: Option<DiplomaticMessage>,
) -> GameState {
    let map = map();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let identity = identity(&p1, &p2);
    let lifecycle = lifecycle(&identity, &p1, &p2);
    let pair = PlayerPair::new(p1.clone(), p2.clone()).expect("pair");
    let diplomacy =
        Diplomacy::try_new(&identity, [pair], [], proposal, message, [], []).expect("diplomacy");
    let economy = economy(&identity, map.bounds(), &p1, &p2);
    GameState::builder(
        StateRevision::new(11),
        7,
        map.bounds(),
        RulesetDefinition::standard().occupancy_policy(),
        [],
    )
    .with_economy(economy)
    .with_diplomacy(diplomacy)
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state")
}

pub(super) fn resource_trade_state() -> GameState {
    let map = map();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let identity = identity(&p1, &p2);
    let lifecycle = lifecycle(&identity, &p1, &p2);
    let pair = PlayerPair::new(p1.clone(), p2.clone()).expect("pair");
    let diplomacy = Diplomacy::try_new(&identity, [pair], [], [], [], [], []).expect("diplomacy");
    let economy = economy(&identity, map.bounds(), &p1, &p2);
    let actor_city = City::builder(
        CityId::new("city-1").expect("city"),
        p1,
        "Actor",
        HexCoord::new(0, 0),
    )
    .with_controlled_hexes([HexCoord::new(1, 0)])
    .build()
    .expect("actor city");
    let target_city = City::builder(
        CityId::new("city-2").expect("city"),
        p2,
        "Target",
        HexCoord::new(2, 0),
    )
    .with_controlled_hexes([HexCoord::new(3, 0)])
    .build()
    .expect("target city");
    GameState::builder(
        StateRevision::new(11),
        7,
        map.bounds(),
        RulesetDefinition::standard().occupancy_policy(),
        [],
    )
    .with_cities([actor_city, target_city])
    .with_economy(economy)
    .with_diplomacy(diplomacy)
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state")
}

pub(super) fn map() -> MapDefinition {
    MapDefinition::try_new(
        "diplomacy-runtime",
        GridLayout::OddQFlatTop,
        4,
        1,
        [
            None,
            Some(MapResourceType::Iron),
            None,
            Some(MapResourceType::Marble),
        ]
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
        .collect(),
        Vec::new(),
    )
    .expect("map")
}

fn identity(p1: &PlayerId, p2: &PlayerId) -> MatchIdentity {
    MatchIdentity::try_new(
        MatchRules::default(),
        [participant(p1.clone(), 1), participant(p2.clone(), 2)],
        GameMode::Multiplayer,
    )
    .expect("identity")
}

fn lifecycle(identity: &MatchIdentity, p1: &PlayerId, p2: &PlayerId) -> TurnLifecycle {
    TurnLifecycle::try_new(
        identity,
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
    .expect("lifecycle")
}

fn economy(
    identity: &MatchIdentity,
    bounds: aonw_domain::HexGridBounds,
    p1: &PlayerId,
    p2: &PlayerId,
) -> EconomyState {
    EconomyState::try_new(
        identity,
        bounds,
        BTreeMap::from([(p1.clone(), 20), (p2.clone(), 1)]),
        BTreeMap::new(),
        BTreeMap::new(),
        BTreeMap::new(),
        aonw_domain::InitialResourceDistribution::default(),
    )
    .expect("economy")
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

pub(super) fn player(value: &str) -> PlayerId {
    PlayerId::new(value).expect("player id")
}
