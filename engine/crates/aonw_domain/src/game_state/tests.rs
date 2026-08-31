use crate::{
    ArtifactId, City, CityId, Diplomacy, DiplomacyStateBuildError, EconomyState, FogOfWar,
    GameMode, GameState, GameStateBuildError, HexCoord, HexGridBounds, InteractionState,
    KnowledgeState, MatchIdentity, MatchLifecycle, MatchRules, MovementUnits, Participant,
    PendingInteraction, PlayerCountry, PlayerFog, PlayerId, PlayerKind, PlayerPair,
    ProductionStateUpdate, StateRevision, TurnLifecycle, Unit, UnitId, UnitKind,
    UnitOccupancyPolicy, WorldArtifact, WorldArtifactLocation, WorldArtifactType,
};

fn unit(id: &str, position: HexCoord) -> Unit {
    Unit::builder(
        UnitId::new(id).expect("unit id"),
        PlayerId::new("player-1").expect("player id"),
        UnitKind::Commander,
        "unit.commander",
        position,
        MovementUnits::new(10),
    )
    .build()
    .expect("unit")
}

#[test]
fn aggregate_normalizes_entity_order_and_indexes_by_id() {
    let state = GameState::try_new(
        StateRevision::new(7),
        3,
        HexGridBounds::new(5, 5).expect("bounds"),
        UnitOccupancyPolicy::Exclusive,
        [
            unit("unit-z", HexCoord::new(1, 1)),
            unit("unit-a", HexCoord::new(2, 1)),
        ],
    )
    .expect("state");

    assert_eq!(state.units()[0].id().as_str(), "unit-a");
    assert_eq!(state.units()[1].id().as_str(), "unit-z");
    assert_eq!(
        state
            .unit(&UnitId::new("unit-a").expect("id"))
            .expect("lookup")
            .position(),
        HexCoord::new(2, 1)
    );
}

#[test]
fn aggregate_rejects_out_of_bounds_and_colliding_units() {
    let bounds = HexGridBounds::new(2, 2).expect("bounds");
    let outside = unit("outside", HexCoord::new(2, 0));
    assert!(matches!(
        GameState::try_new(
            StateRevision::INITIAL,
            0,
            bounds,
            UnitOccupancyPolicy::Exclusive,
            [outside]
        ),
        Err(GameStateBuildError::UnitOutOfBounds { .. })
    ));

    let position = HexCoord::new(1, 1);
    assert_eq!(
        GameState::try_new(
            StateRevision::INITIAL,
            0,
            bounds,
            UnitOccupancyPolicy::Exclusive,
            [unit("one", position), unit("two", position)]
        ),
        Err(GameStateBuildError::OccupiedCoordinate { position })
    );
}

#[test]
fn aggregate_rejects_overlapping_city_territory() {
    let owner = PlayerId::new("player-1").expect("player id");
    let first = City::builder(
        CityId::new("city-a").expect("city id"),
        owner.clone(),
        "First",
        HexCoord::new(0, 0),
    )
    .with_controlled_hexes([HexCoord::new(1, 0)])
    .build()
    .expect("first city");
    let second = City::builder(
        CityId::new("city-b").expect("city id"),
        owner,
        "Second",
        HexCoord::new(1, 0),
    )
    .build()
    .expect("second city");

    assert_eq!(
        GameState::builder(
            StateRevision::INITIAL,
            0,
            HexGridBounds::new(2, 1).expect("bounds"),
            UnitOccupancyPolicy::Exclusive,
            [],
        )
        .with_cities([second, first])
        .try_build(),
        Err(GameStateBuildError::CityTerritoryOverlap {
            position: HexCoord::new(1, 0),
            first_city_id: CityId::new("city-a").expect("city id"),
            second_city_id: CityId::new("city-b").expect("city id"),
        })
    );
}

#[test]
fn aggregate_revalidates_city_local_invariants_after_mutation() {
    let city_id = CityId::new("city").expect("city id");
    let city = City::builder(
        city_id.clone(),
        PlayerId::new("player-1").expect("player id"),
        "City",
        HexCoord::new(0, 0),
    )
    .with_controlled_hexes([HexCoord::new(1, 0)])
    .build()
    .expect("city")
    .with_worked_hexes(vec![HexCoord::new(1, 0), HexCoord::new(1, 0)].into_boxed_slice());

    assert_eq!(
        GameState::builder(
            StateRevision::INITIAL,
            0,
            HexGridBounds::new(2, 1).expect("bounds"),
            UnitOccupancyPolicy::Exclusive,
            [],
        )
        .with_cities([city])
        .try_build(),
        Err(GameStateBuildError::InvalidCity {
            city_id,
            error: crate::CityBuildError::DuplicateWorkedHex(HexCoord::new(1, 0)),
        })
    );
}

#[test]
fn friendly_stacking_is_an_explicit_policy() {
    let position = HexCoord::new(1, 1);
    let state = GameState::try_new(
        StateRevision::INITIAL,
        0,
        HexGridBounds::new(2, 2).expect("bounds"),
        UnitOccupancyPolicy::FriendlyStacking,
        [unit("one", position), unit("two", position)],
    )
    .expect("friendly stack");
    assert_eq!(
        state
            .units_at(position)
            .map(|unit| unit.id().as_str())
            .collect::<Vec<_>>(),
        ["one", "two"]
    );
}

#[test]
fn aggregate_indexes_city_centers_and_territory_by_coordinate() {
    let city = City::builder(
        CityId::new("city-a").expect("city id"),
        PlayerId::new("player-1").expect("player id"),
        "First",
        HexCoord::new(0, 0),
    )
    .with_controlled_hexes([HexCoord::new(1, 0)])
    .build()
    .expect("city");
    let state = GameState::builder(
        StateRevision::INITIAL,
        0,
        HexGridBounds::new(2, 1).expect("bounds"),
        UnitOccupancyPolicy::Exclusive,
        [],
    )
    .with_cities([city])
    .try_build()
    .expect("state");

    assert_eq!(
        state.city_at(HexCoord::new(0, 0)).map(City::id),
        state.city_controlling(HexCoord::new(1, 0)).map(City::id)
    );
    assert!(state.city_at(HexCoord::new(1, 0)).is_none());
}

#[test]
fn builder_validates_cross_section_references_only_when_constructing_state() {
    let missing_unit_id = UnitId::new("missing").expect("unit id");
    let artifact_id = ArtifactId::new("artifact-1").expect("artifact id");
    let state = GameState::builder(
        StateRevision::INITIAL,
        1,
        HexGridBounds::new(2, 2).expect("bounds"),
        UnitOccupancyPolicy::Exclusive,
        [unit("unit-1", HexCoord::new(0, 0))],
    )
    .with_artifacts([WorldArtifact::new(
        artifact_id.clone(),
        WorldArtifactType::HeroSword,
        WorldArtifactLocation::Carried(missing_unit_id.clone()),
    )])
    .try_build();

    assert_eq!(
        state,
        Err(GameStateBuildError::ArtifactUnitNotFound {
            artifact_id,
            unit_id: missing_unit_id,
        })
    );
}

#[test]
fn bound_aggregate_rejects_every_direct_player_reference_family() {
    let known = PlayerId::new("known").expect("known player");
    let unknown = PlayerId::new("unknown").expect("unknown player");
    let lifecycle = bound_lifecycle(known.clone());
    let bounds = HexGridBounds::new(2, 2).expect("bounds");

    let unknown_unit = Unit::builder(
        UnitId::new("unknown-unit").expect("unit id"),
        unknown.clone(),
        UnitKind::Commander,
        "unknown unit",
        HexCoord::new(0, 0),
        MovementUnits::new(10),
    )
    .build()
    .expect("unit");
    assert!(matches!(
        GameState::builder(
            StateRevision::INITIAL,
            1,
            bounds,
            UnitOccupancyPolicy::Exclusive,
            [unknown_unit]
        )
        .with_match_lifecycle(lifecycle.clone())
        .try_build(),
        Err(GameStateBuildError::UnitPlayerNotFound { player_id, .. }) if player_id == unknown
    ));

    let unknown_city = City::new(
        CityId::new("unknown-city").expect("city id"),
        unknown.clone(),
        HexCoord::new(0, 0),
        [],
    );
    assert!(matches!(
        empty_bound_builder(bounds, lifecycle.clone())
            .with_cities([unknown_city])
            .try_build(),
        Err(GameStateBuildError::CityPlayerNotFound { player_id, .. }) if player_id == unknown
    ));

    let fog = FogOfWar::try_new([PlayerFog::new(unknown.clone(), [], [])]).expect("fog");
    assert_eq!(
        empty_bound_builder(bounds, lifecycle.clone())
            .with_fog_of_war(fog)
            .try_build(),
        Err(GameStateBuildError::FogPlayerNotFound(unknown.clone()))
    );

    let interaction = InteractionState::new(
        None,
        Some(PendingInteraction::ResearchSelection {
            owner_player_id: unknown.clone(),
        }),
    );
    assert_eq!(
        empty_bound_builder(bounds, lifecycle.clone())
            .with_interaction(interaction)
            .try_build(),
        Err(GameStateBuildError::InteractionPlayerNotFound(
            unknown.clone()
        ))
    );

    let pair = PlayerPair::new(known, unknown.clone()).expect("player pair");
    assert_eq!(
        empty_bound_builder(bounds, lifecycle)
            .with_diplomacy(Diplomacy::new([pair]))
            .try_build(),
        Err(GameStateBuildError::InvalidDiplomacy(
            DiplomacyStateBuildError::PlayerNotFound(unknown)
        ))
    );
}

#[test]
fn production_update_rebuilds_every_affected_section_atomically() {
    let owner = PlayerId::new("known").expect("owner");
    let lifecycle = bound_lifecycle(owner.clone());
    let bounds = HexGridBounds::new(2, 2).expect("bounds");
    let city = City::new(
        CityId::new("city").expect("city id"),
        owner,
        HexCoord::new(0, 0),
        [],
    );
    let state = empty_bound_builder(bounds, lifecycle)
        .with_cities([city.clone()])
        .try_build()
        .expect("state");
    let updated = state
        .into_after_production(ProductionStateUpdate {
            revision: StateRevision::new(1),
            units: Vec::new(),
            cities: vec![city],
            economy: EconomyState::default(),
            knowledge: KnowledgeState::default(),
            fog_of_war: FogOfWar::default(),
            diplomacy: Diplomacy::default(),
        })
        .expect("production state");
    assert_eq!(updated.revision(), StateRevision::new(1));
    assert_eq!(updated.cities().len(), 1);
    assert!(updated.economy().player_gold().is_empty());
    assert!(updated.wonder_registry().completed_by().is_empty());
}

fn bound_lifecycle(player_id: PlayerId) -> MatchLifecycle {
    let participant = Participant::try_new(
        player_id,
        "Known player",
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Human,
        None,
    )
    .expect("participant");
    let identity = MatchIdentity::try_new(MatchRules::default(), [participant], GameMode::HotSeat)
        .expect("identity");
    MatchLifecycle::new(identity, TurnLifecycle::default())
}

fn empty_bound_builder(
    bounds: HexGridBounds,
    lifecycle: MatchLifecycle,
) -> super::GameStateBuilder {
    GameState::builder(
        StateRevision::INITIAL,
        1,
        bounds,
        UnitOccupancyPolicy::Exclusive,
        [],
    )
    .with_match_lifecycle(lifecycle)
}
