use std::path::{Path, PathBuf};

use super::*;

pub(super) fn step(col: i32, row: i32, enter: u32, cumulative: u32) -> MovementStep {
    MovementStep::new(
        HexCoord::new(col, row),
        MovementUnits::new(enter),
        MovementUnits::new(cumulative),
    )
}

pub(super) fn state(
    map: &MapDefinition,
    units: Vec<Unit>,
    cities: Vec<City>,
    fog: FogOfWar,
) -> GameState {
    let mut players = units
        .iter()
        .map(|unit| unit.owner_player_id().clone())
        .chain(cities.iter().map(|city| city.owner_player_id().clone()))
        .collect::<Vec<_>>();
    players.sort_unstable();
    players.dedup();
    let participants = players
        .iter()
        .enumerate()
        .map(|(index, id)| {
            Participant::try_new(
                id.clone(),
                id.as_str(),
                0xff00_0000 | u32::try_from(index).expect("participant index"),
                PlayerCountry::Poland,
                PlayerKind::Human,
                None,
            )
            .expect("participant")
        })
        .collect::<Vec<_>>();
    let identity =
        MatchIdentity::try_new(MatchRules::default(), participants, GameMode::Multiplayer)
            .expect("match identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        players
            .iter()
            .cloned()
            .map(|id| (id, PlayerTurnState::Active))
            .collect::<BTreeMap<_, _>>(),
        players.iter().cloned(),
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("turn lifecycle");
    GameState::builder(
        StateRevision::new(9),
        4,
        map.bounds(),
        UnitOccupancyPolicy::Exclusive,
        units,
    )
    .with_cities(cities)
    .with_fog_of_war(fog)
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state")
}

pub(super) fn map(width: u32, height: u32) -> MapDefinition {
    let tiles = (0..i32::try_from(height).expect("height"))
        .flat_map(|row| {
            (0..i32::try_from(width).expect("width")).map(move |col| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(col, row),
                    vec![TerrainType::Plains],
                    Vec::new(),
                    0,
                )
                .expect("tile")
            })
        })
        .collect();
    MapDefinition::try_new(
        "movement-logistics",
        GridLayout::OddQFlatTop,
        u16::try_from(width).expect("width"),
        u16::try_from(height).expect("height"),
        tiles,
        Vec::new(),
    )
    .expect("map")
}

pub(super) fn unit(id: &str, owner: &PlayerId, kind: UnitKind, position: HexCoord) -> Unit {
    Unit::builder(
        unit_id(id),
        owner.clone(),
        kind,
        id,
        position,
        MovementUnits::new(100),
    )
    .build()
    .expect("unit")
}

pub(super) fn city(id: &str, owner: &PlayerId, center: HexCoord) -> City {
    City::new(city_id(id), owner.clone(), center, [])
}

pub(super) fn unit_id(id: &str) -> UnitId {
    UnitId::new(id).expect("unit id")
}

pub(super) fn city_id(id: &str) -> CityId {
    CityId::new(id).expect("city id")
}

pub(super) fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player id")
}

pub(super) fn repository_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .find(|path| path.join("engine/fixtures/movement_logistics").is_dir())
        .expect("repository root")
        .to_path_buf()
}
