use std::collections::BTreeMap;

use aonw_content::{GridLayout, MapDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    City, FogOfWar, GameMode, GameState, InfrastructureState, InteractionState, KnowledgeState,
    MatchIdentity, MatchLifecycle, MatchRules, MovementUnits, Participant, PlayerCountry,
    PlayerFog, PlayerId, PlayerKind, PlayerResearchState, PlayerTurnState, ResearchState,
    StateRevision, TechnologyId, TransportNetwork, TurnLifecycle, Unit, UnitId, UnitKind,
    UnitOccupancyPolicy, WonderRegistry,
};

pub(super) fn map(width: u16, height: u16) -> MapDefinition {
    MapDefinition::try_new(
        "worker-test",
        GridLayout::OddQFlatTop,
        width,
        height,
        coordinates(width, height)
            .map(|coordinate| {
                TileDefinition::try_new_for_simulation(
                    coordinate,
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

pub(super) fn coordinates(width: u16, height: u16) -> impl Iterator<Item = aonw_domain::HexCoord> {
    (0..i32::from(height)).flat_map(move |row| {
        (0..i32::from(width)).map(move |col| aonw_domain::HexCoord::new(col, row))
    })
}

pub(super) fn state(
    map: &MapDefinition,
    units: Vec<Unit>,
    cities: Vec<City>,
    infrastructure: InfrastructureState,
    interaction: InteractionState,
    unlocked: &[TechnologyId],
) -> GameState {
    let mut players = units
        .iter()
        .map(|unit| unit.owner_player_id().clone())
        .chain(cities.iter().map(|city| city.owner_player_id().clone()))
        .chain(
            interaction
                .pending()
                .map(|pending| pending.owner_player_id().clone()),
        )
        .collect::<Vec<_>>();
    players.sort_unstable();
    players.dedup();
    let participants = players.iter().map(participant).collect::<Vec<_>>();
    let identity = MatchIdentity::try_new(MatchRules::default(), participants, GameMode::HotSeat)
        .expect("identity");
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
    let research = ResearchState::try_new(players.iter().cloned().map(|player| {
        (
            player,
            PlayerResearchState::try_new(unlocked.iter().copied(), None, [], 0).expect("research"),
        )
    }))
    .expect("research state");
    let visible = coordinates(map.bounds().cols(), map.bounds().rows()).collect::<Vec<_>>();
    let fog = FogOfWar::try_new(
        players
            .iter()
            .cloned()
            .map(|player| PlayerFog::new(player, [], visible.iter().copied())),
    )
    .expect("fog");
    GameState::builder(
        StateRevision::new(9),
        4,
        map.bounds(),
        UnitOccupancyPolicy::Exclusive,
        units,
    )
    .with_cities(cities)
    .with_infrastructure(infrastructure)
    .with_interaction(interaction)
    .with_fog_of_war(fog)
    .with_knowledge(KnowledgeState::new(research, WonderRegistry::default()))
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state")
}

pub(super) fn city(
    id: &str,
    owner: &PlayerId,
    center: aonw_domain::HexCoord,
    controlled: impl IntoIterator<Item = aonw_domain::HexCoord>,
) -> City {
    City::builder(
        aonw_domain::CityId::new(id).expect("city id"),
        owner.clone(),
        id,
        center,
    )
    .with_progression(4, 0, 2_000, 100)
    .with_controlled_hexes(controlled)
    .build()
    .expect("city")
}

pub(super) fn worker(
    id: &str,
    owner: &PlayerId,
    position: aonw_domain::HexCoord,
    charges: u32,
) -> Unit {
    Unit::builder(
        unit_id(id),
        owner.clone(),
        UnitKind::Worker,
        id,
        position,
        MovementUnits::new(10),
    )
    .with_worker_build_charges(charges)
    .build()
    .expect("worker")
}

pub(super) fn infrastructure(
    improvements: impl IntoIterator<Item = aonw_domain::FieldImprovement>,
) -> InfrastructureState {
    InfrastructureState::try_new(improvements, TransportNetwork::default()).expect("infrastructure")
}

pub(super) fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player")
}

pub(super) fn unit_id(id: &str) -> UnitId {
    UnitId::new(id).expect("unit id")
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
