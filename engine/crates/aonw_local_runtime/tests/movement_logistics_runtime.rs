//! Save, replay, turn, and recipient-boundary tests for movement logistics.

use std::collections::BTreeMap;

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_contracts::SaveGameDto;
use aonw_domain::{
    ArmyTroop, City, CityId, FogOfWar, GameMode, GameState, HexCoord, MatchIdentity,
    MatchLifecycle, MatchRules, MovementUnits, Participant, PlayerCountry, PlayerFog, PlayerId,
    PlayerKind, PlayerTurnState, StateRevision, TroopKind, TurnLifecycle, Unit, UnitId, UnitKind,
};
use aonw_local_runtime::{
    DetachTroopRequest, LocalRuntime, MerchantCityRequest, OpenSession, TurnCommandRequest,
};

#[test]
fn save_reopen_turn_replay_is_exact_and_foreign_snapshot_stays_fog_safe() {
    let (map, rules, state, p1, p2) = fixture();
    let merchant_id = unit_id("merchant-1");
    let army_id = unit_id("army-1");
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(
            map.clone(),
            rules.clone(),
            state,
            p1,
        ))
        .expect("open");

    let assigned = runtime
        .assign_merchant_trade_route(&MerchantCityRequest {
            expected_revision: 9,
            unit_id: merchant_id,
            destination_city_id: city_id("city-b"),
        })
        .expect("assign merchant route");
    assert!(assigned.is_accepted());
    let detached = runtime
        .detach_troop(&DetachTroopRequest {
            expected_revision: 10,
            unit_id: army_id,
            troop_kind: TroopKind::Archer,
        })
        .expect("detach troop");
    assert!(detached.is_accepted());
    assert!(
        detached
            .view_patch
            .upserted_units
            .iter()
            .any(|unit| unit.id().as_str() == "army-1_archer_1")
    );

    let save = runtime.export_save_json().expect("save");
    let expected = runtime.snapshot().expect("owner snapshot");
    let mut reopened = LocalRuntime::default();
    reopened
        .open_save_json(map.clone(), rules.clone(), &save)
        .expect("reopen owner save");
    assert_eq!(reopened.snapshot().expect("reopened snapshot"), expected);

    let mut foreign_save = SaveGameDto::from_json(&save).expect("save DTO");
    foreign_save.actor_player_id = p2.as_str().to_owned();
    let foreign_save = serde_json::to_string(&foreign_save).expect("foreign save");
    let mut foreign_runtime = LocalRuntime::default();
    foreign_runtime
        .open_save_json(map.clone(), rules.clone(), &foreign_save)
        .expect("open foreign recipient");
    let foreign_snapshot = foreign_runtime.snapshot().expect("foreign snapshot");
    assert!(
        foreign_snapshot
            .units()
            .iter()
            .all(|unit| unit.id().as_str() != "army-1_archer_1")
    );
    assert!(foreign_snapshot.fog().enabled());
    assert_eq!(
        foreign_snapshot.fog().discovered_hexes(),
        [HexCoord::new(5, 2)]
    );
    assert_eq!(
        foreign_snapshot.fog().visible_hexes(),
        [HexCoord::new(5, 2)]
    );

    let advanced = foreign_runtime
        .end_turn(TurnCommandRequest {
            expected_revision: 11,
        })
        .expect("end foreign turn");
    assert!(advanced.is_accepted());
    let replay = foreign_runtime.export_replay_json().expect("replay");
    let verification =
        LocalRuntime::verify_replay_json(map, rules, &replay).expect("verify replay");
    assert_eq!(verification.entry_count, 1);
    assert_eq!(verification.final_stamp, advanced.stamp);
}

fn fixture() -> (
    MapDefinition,
    RulesetDefinition,
    GameState,
    PlayerId,
    PlayerId,
) {
    let map = map();
    let rules = RulesetDefinition::standard().clone();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [participant(&p2), participant(&p1)],
        GameMode::HotSeat,
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
    let merchant = unit("merchant-1", &p1, UnitKind::Merchant, HexCoord::new(0, 1));
    let army = Unit::builder(
        unit_id("army-1"),
        p1.clone(),
        UnitKind::Commander,
        "army",
        HexCoord::new(1, 2),
        MovementUnits::new(10),
    )
    .with_army([ArmyTroop::new(TroopKind::Archer, 1)])
    .build()
    .expect("army");
    let foreign = unit("foreign-1", &p2, UnitKind::Warrior, HexCoord::new(5, 2));
    let fog = FogOfWar::try_new([
        PlayerFog::new(
            p1.clone(),
            [],
            [
                HexCoord::new(0, 1),
                HexCoord::new(1, 2),
                HexCoord::new(2, 2),
            ],
        ),
        PlayerFog::new(p2.clone(), [], [HexCoord::new(5, 2)]),
    ])
    .expect("fog");
    let state = GameState::builder(
        StateRevision::new(9),
        4,
        map.bounds(),
        rules.occupancy_policy(),
        [merchant, army, foreign],
    )
    .with_cities([
        City::new(city_id("city-a"), p1.clone(), HexCoord::new(0, 1), []),
        City::new(city_id("city-b"), p1.clone(), HexCoord::new(5, 1), []),
    ])
    .with_fog_of_war(fog)
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state");
    (map, rules, state, p1, p2)
}

fn map() -> MapDefinition {
    MapDefinition::try_new(
        "runtime-movement-logistics",
        GridLayout::OddQFlatTop,
        6,
        4,
        (0..4)
            .flat_map(|row| {
                (0..6).map(move |col| {
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

fn unit(id: &str, owner: &PlayerId, kind: UnitKind, position: HexCoord) -> Unit {
    Unit::builder(
        unit_id(id),
        owner.clone(),
        kind,
        id,
        position,
        MovementUnits::new(10),
    )
    .build()
    .expect("unit")
}

fn participant(id: &PlayerId) -> Participant {
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

fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player id")
}

fn unit_id(id: &str) -> UnitId {
    UnitId::new(id).expect("unit id")
}

fn city_id(id: &str) -> CityId {
    CityId::new(id).expect("city id")
}
