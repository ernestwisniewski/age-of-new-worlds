use std::collections::BTreeMap;

use aonw_content::{GridLayout, MapDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    ArtifactId, City, CityId, Diplomacy, DiplomaticRelation, DiplomaticRelationStatus,
    EconomyState, GameMode, GameState, HexCoord, InitialResourceDistribution, MatchIdentity,
    MatchLifecycle, MatchRules, MovementUnits, Participant, PlayerCountry, PlayerId, PlayerKind,
    PlayerPair, PlayerTurnState, StateRevision, TurnLifecycle, Unit, UnitActivity, UnitId,
    UnitKind, UnitOccupancyPolicy, WorldArtifact, WorldArtifactLocation, WorldArtifactType,
};

pub(super) fn game_state(
    units: Vec<Unit>,
    cities: Vec<City>,
    artifacts: Vec<WorldArtifact>,
    gold: Option<(i64, i64)>,
    war: bool,
) -> GameState {
    state_with_active(units, cities, artifacts, gold, war, &player("player-1"))
}

pub(super) fn state_with_active(
    units: Vec<Unit>,
    cities: Vec<City>,
    artifacts: Vec<WorldArtifact>,
    gold: Option<(i64, i64)>,
    war: bool,
    active: &PlayerId,
) -> GameState {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [participant(p1.clone()), participant(p2.clone())],
        GameMode::HotSeat,
    )
    .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (
                p1.clone(),
                if active == &p1 {
                    PlayerTurnState::Active
                } else {
                    PlayerTurnState::Finished
                },
            ),
            (
                p2.clone(),
                if active == &p2 {
                    PlayerTurnState::Active
                } else {
                    PlayerTurnState::Finished
                },
            ),
        ]),
        [p1.clone(), p2.clone()],
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle");
    let economy = EconomyState::try_new(
        &identity,
        map().bounds(),
        gold.map_or_else(BTreeMap::new, |(p1_gold, p2_gold)| {
            BTreeMap::from([(p1.clone(), p1_gold), (p2.clone(), p2_gold)])
        }),
        BTreeMap::new(),
        BTreeMap::new(),
        BTreeMap::new(),
        InitialResourceDistribution::default(),
    )
    .expect("economy");
    let diplomacy =
        if war {
            let pair = PlayerPair::new(p1, p2).expect("pair");
            Diplomacy::try_new(
                &identity,
                [pair.clone()],
                [DiplomaticRelation::try_new(
                    pair,
                    DiplomaticRelationStatus::War,
                    0,
                    None,
                    None,
                    None,
                )
                .expect("war")],
                [],
                [],
                [],
                [],
            )
            .expect("diplomacy")
        } else {
            Diplomacy::default()
        };
    GameState::builder(
        StateRevision::new(9),
        4,
        map().bounds(),
        UnitOccupancyPolicy::Exclusive,
        units,
    )
    .with_cities(cities)
    .with_artifacts(artifacts)
    .with_economy(economy)
    .with_diplomacy(diplomacy)
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
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

pub(super) fn unit(id: &str, owner: &PlayerId, position: HexCoord) -> Unit {
    Unit::builder(
        unit_id(id),
        owner.clone(),
        UnitKind::Scout,
        id,
        position,
        MovementUnits::new(10),
    )
    .build()
    .expect("unit")
}

pub(super) fn carried_unit(
    id: &str,
    owner: &PlayerId,
    position: HexCoord,
    artifact: ArtifactId,
) -> Unit {
    Unit::builder(
        unit_id(id),
        owner.clone(),
        UnitKind::Scout,
        id,
        position,
        MovementUnits::new(10),
    )
    .with_carried_artifact(Some(artifact))
    .build()
    .expect("carrier")
}

pub(super) fn excavating_unit(
    id: &str,
    owner: &PlayerId,
    position: HexCoord,
    artifact: ArtifactId,
) -> Unit {
    Unit::builder(
        unit_id(id),
        owner.clone(),
        UnitKind::Scout,
        id,
        position,
        MovementUnits::ZERO,
    )
    .with_activity(UnitActivity::new(None, None, None, Some(artifact)))
    .build()
    .expect("excavator")
}

pub(super) fn city(id: &str, owner: &PlayerId, center: HexCoord) -> City {
    City::builder(city_id(id), owner.clone(), id, center)
        .build()
        .expect("city")
}

pub(super) fn artifact(id: &str, location: WorldArtifactLocation) -> WorldArtifact {
    WorldArtifact::new(artifact_id(id), WorldArtifactType::HeroSword, location)
}

pub(super) fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player id")
}

pub(super) fn unit_id(id: &str) -> UnitId {
    UnitId::new(id).expect("unit id")
}

pub(super) fn city_id(id: &str) -> CityId {
    CityId::new(id).expect("city id")
}

pub(super) fn artifact_id(id: &str) -> ArtifactId {
    ArtifactId::new(id).expect("artifact id")
}

pub(super) fn map() -> MapDefinition {
    MapDefinition::try_new(
        "artifact-test",
        GridLayout::OddQFlatTop,
        4,
        1,
        (0..4)
            .map(|column| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(column, 0),
                    vec![TerrainType::Plains],
                    Vec::new(),
                    0,
                )
                .expect("tile")
            })
            .collect(),
        Vec::new(),
    )
    .expect("map")
}
