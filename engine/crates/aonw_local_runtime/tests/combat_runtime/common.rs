use std::collections::BTreeMap;

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_contracts::CityConquestActionDto;
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientCommandDto, ClientQueryDto, ClientRequestBodyDto, ClientRequestDto,
};
use aonw_domain::{
    City, CityId, Diplomacy, FogOfWar, GameMode, GameState, HexCoord, MatchIdentity,
    MatchLifecycle, MatchRules, MovementUnits, Participant, PlayerCountry, PlayerId, PlayerKind,
    PlayerPair, PlayerTurnState, StateRevision, TurnLifecycle, Unit, UnitId, UnitKind,
};
use aonw_local_runtime::{ClientProtocol, LocalRuntime};

pub(super) fn assert_hidden_replay(
    runtime: &LocalRuntime,
    map: MapDefinition,
    rules: RulesetDefinition,
    attacker_id: &UnitId,
    defender_id: &UnitId,
) {
    let replay = runtime.export_replay_json().expect("replay");
    assert!(replay.contains(attacker_id.as_str()));
    assert!(replay.contains(defender_id.as_str()));
    assert!(replay.contains("\"seed\""));
    LocalRuntime::verify_replay_json(map, rules, &replay).expect("canonical replay");
}

pub(super) fn submit_turn_json(runtime: &mut LocalRuntime) -> String {
    let request = ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request: ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::SubmitTurn {
                expected_revision: 11,
            },
        },
    }
    .to_json()
    .expect("request JSON");
    ClientProtocol::dispatch_json(runtime, &request)
}

pub(super) fn dispatch_attack_json(
    runtime: &mut LocalRuntime,
    attacker_unit_id: &str,
    defender: HexCoord,
    city_conquest_action: CityConquestActionDto,
) -> String {
    let request = ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request: ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::AttackHex {
                expected_revision: 11,
                attacker_unit_id: attacker_unit_id.to_owned(),
                defender: aonw_contracts::CoordinateDto {
                    col: defender.col(),
                    row: defender.row(),
                },
                city_conquest_action,
            },
        },
    }
    .to_json()
    .expect("request JSON");
    ClientProtocol::dispatch_json(runtime, &request)
}

pub(super) fn dispatch_preview_json(
    runtime: &mut LocalRuntime,
    attacker_unit_id: &str,
    defender: HexCoord,
) -> String {
    let request = ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request: ClientRequestBodyDto::Query {
            query: ClientQueryDto::CombatPreview {
                expected_revision: 11,
                attacker_unit_id: attacker_unit_id.to_owned(),
                defender: aonw_contracts::CoordinateDto {
                    col: defender.col(),
                    row: defender.row(),
                },
            },
        },
    }
    .to_json()
    .expect("request JSON");
    ClientProtocol::dispatch_json(runtime, &request)
}

pub(super) fn fixture() -> (MapDefinition, RulesetDefinition, GameState, PlayerId) {
    let map = map();
    let rules = RulesetDefinition::standard().clone();
    let actor = player("player_1");
    let defender = player("player_2");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [participant(&actor), participant(&defender)],
        GameMode::Multiplayer,
    )
    .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (actor.clone(), PlayerTurnState::Active),
            (defender.clone(), PlayerTurnState::Active),
        ]),
        [actor.clone(), defender.clone()],
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle");
    let state = GameState::builder(
        StateRevision::new(11),
        7,
        map.bounds(),
        rules.occupancy_policy(),
        [
            unit("attacker", &actor, UnitKind::Warrior, HexCoord::new(0, 0)),
            unit(
                "defender",
                &defender,
                UnitKind::Settler,
                HexCoord::new(1, 0),
            ),
        ],
    )
    .with_fog_of_war(FogOfWar::default())
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state");
    (map, rules, state, actor)
}

pub(super) fn city_fixture() -> (MapDefinition, RulesetDefinition, GameState, PlayerId) {
    let map = map();
    let rules = RulesetDefinition::standard().clone();
    let actor = player("player_1");
    let defender = player("player_2");
    let observer = player("player_3");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [
            participant(&actor),
            participant(&defender),
            participant(&observer),
        ],
        GameMode::Multiplayer,
    )
    .expect("identity");
    let lifecycle = lifecycle(&identity, [&actor, &defender, &observer]);
    let diplomacy = Diplomacy::try_new(
        &identity,
        [
            PlayerPair::new(actor.clone(), defender.clone()).expect("pair"),
            PlayerPair::new(actor.clone(), observer.clone()).expect("pair"),
            PlayerPair::new(defender.clone(), observer).expect("pair"),
        ],
        [],
        [],
        [],
        [],
        [],
    )
    .expect("diplomacy");
    let city = City::builder(
        CityId::new("city").expect("city id"),
        defender,
        "City",
        HexCoord::new(1, 0),
    )
    .with_hit_points(Some(1))
    .build()
    .expect("city");
    let state = GameState::builder(
        StateRevision::new(11),
        7,
        map.bounds(),
        rules.occupancy_policy(),
        [unit("tank", &actor, UnitKind::Tank, HexCoord::new(0, 0))],
    )
    .with_cities([city])
    .with_diplomacy(diplomacy)
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state");
    (map, rules, state, actor)
}

pub(super) fn retreat_fixture() -> (MapDefinition, RulesetDefinition, GameState, PlayerId) {
    let map = map();
    let rules = RulesetDefinition::standard().clone();
    let actor = player("player_1");
    let defender = player("player_2");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [participant(&actor), participant(&defender)],
        GameMode::Multiplayer,
    )
    .expect("identity");
    let lifecycle = lifecycle(&identity, [&actor, &defender]);
    let defender_unit = Unit::builder(
        unit_id("defender"),
        defender,
        UnitKind::Warrior,
        "defender",
        HexCoord::new(1, 0),
        MovementUnits::new(10),
    )
    .with_hit_points(Some(2))
    .build()
    .expect("defender");
    let state = GameState::builder(
        StateRevision::new(11),
        7,
        map.bounds(),
        rules.occupancy_policy(),
        [
            unit("archer", &actor, UnitKind::Archer, HexCoord::new(0, 0)),
            defender_unit,
        ],
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state");
    (map, rules, state, actor)
}

fn lifecycle<const N: usize>(identity: &MatchIdentity, players: [&PlayerId; N]) -> TurnLifecycle {
    TurnLifecycle::try_new(
        identity,
        players
            .iter()
            .map(|player| ((*player).clone(), PlayerTurnState::Active))
            .collect::<BTreeMap<_, _>>(),
        players.into_iter().cloned(),
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle")
}

fn map() -> MapDefinition {
    map_with_size("runtime-combat", 3)
}

pub(super) fn hidden_combat_map() -> MapDefinition {
    map_with_size("runtime-hidden-combat", 8)
}

fn map_with_size(id: &str, columns: u16) -> MapDefinition {
    MapDefinition::try_new(
        id,
        GridLayout::OddQFlatTop,
        columns,
        2,
        (0..2)
            .flat_map(|row| {
                (0..i32::from(columns)).map(move |col| {
                    TileDefinition::try_new_for_simulation(
                        HexCoord::new(col, row),
                        vec![TerrainType::Plains],
                        Vec::new(),
                        0,
                    )
                    .expect("tile")
                })
            })
            .collect(),
        Vec::new(),
    )
    .expect("map")
}

pub(super) fn unit(id: &str, owner: &PlayerId, kind: UnitKind, coordinate: HexCoord) -> Unit {
    Unit::builder(
        unit_id(id),
        owner.clone(),
        kind,
        id,
        coordinate,
        MovementUnits::new(10),
    )
    .build()
    .expect("unit")
}

pub(super) fn participant(id: &PlayerId) -> Participant {
    Participant::try_new(
        id.clone(),
        id.as_str(),
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Human,
        None,
    )
    .expect("participant")
}

pub(super) fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player id")
}

pub(super) fn unit_id(id: &str) -> UnitId {
    UnitId::new(id).expect("unit id")
}
