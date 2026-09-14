use super::visible_units;
use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    CityId, FogOfWarState, GameState, HexCoord, HexGridBounds, MerchantTradeRoute, MovementStep,
    MovementUnits, PlayerFogState, PlayerId, QueuedMovePath, StateRevision, Unit, UnitId, UnitKind,
    UnitOccupancyPolicy,
};

#[test]
fn queued_timing_is_owned_and_refreshes_without_changing_the_persisted_path() {
    let steps = steps();
    let path = QueuedMovePath::try_new(HexCoord::new(5, 0), steps).unwrap();
    for (balance, expected) in [(3, vec![1, 1, 2, 2, 3, 3]), (0, vec![1, 2, 3, 3, 4, 4])] {
        let unit = builder(UnitKind::FieldCannon, 0, balance)
            .with_queued_path(Some(path.clone()))
            .build()
            .unwrap();
        let (state, map, actor) = fixture(unit);
        let view = visible_units(&state, &actor, &map, RulesetDefinition::standard());
        let route = view[0].owned_details().unwrap().queued_path().unwrap();
        assert_eq!(route.route(), &path);
        assert_eq!(route.step_turns(), expected);
        assert!(route.road_step_indices().is_empty());
        let foreign = visible_units(
            &state,
            &PlayerId::new("observer").unwrap(),
            &map,
            RulesetDefinition::standard(),
        );
        assert_eq!(foreign.len(), 1);
        assert!(foreign[0].owned_details().is_none());
        assert_eq!(state.units()[0].queued_path(), Some(&path));
    }
}

#[test]
fn merchant_projection_marks_the_traversed_prefix_and_retains_itinerary_identity() {
    let path = MerchantTradeRoute::new(
        CityId::new("a").unwrap(),
        CityId::new("b").unwrap(),
        steps(),
        "network",
    );
    let unit = builder(UnitKind::Merchant, 2, 0)
        .with_merchant_trade_route(Some(path.clone()))
        .build()
        .unwrap();
    let (state, map, actor) = fixture(unit);
    let view = visible_units(&state, &actor, &map, RulesetDefinition::standard());
    let route = view[0]
        .owned_details()
        .unwrap()
        .merchant_trade_route()
        .unwrap();
    assert_eq!(route.route(), &path);
    assert_eq!(&route.step_turns()[..4], &[0, 0, 1, 2]);
    assert!(
        route
            .step_turns()
            .windows(2)
            .skip(2)
            .all(|p| p[1] >= p[0] && p[1] <= p[0] + 1)
    );
}

fn builder(kind: UnitKind, col: i32, balance: u32) -> aonw_domain::UnitBuilder {
    Unit::builder(
        UnitId::new("unit").unwrap(),
        PlayerId::new("owner").unwrap(),
        kind,
        "Unit",
        HexCoord::new(col, 0),
        MovementUnits::new(balance),
    )
}

fn steps() -> Vec<MovementStep> {
    [
        (0, 0, 0),
        (1, 4, 4),
        (2, 2, 6),
        (3, 4, 10),
        (4, 2, 12),
        (5, 2, 14),
    ]
    .into_iter()
    .map(|(col, cost, total)| {
        MovementStep::new(
            HexCoord::new(col, 0),
            MovementUnits::new(cost),
            MovementUnits::new(total),
        )
    })
    .collect()
}

fn fixture(unit: Unit) -> (GameState, MapDefinition, PlayerId) {
    let actor = unit.owner_player_id().clone();
    let positions: Vec<_> = (0..6).map(|col| HexCoord::new(col, 0)).collect();
    let fog = FogOfWarState::try_new([
        PlayerFogState::new(actor.clone(), positions.clone(), positions.clone()),
        PlayerFogState::new(
            PlayerId::new("observer").unwrap(),
            positions.clone(),
            positions.clone(),
        ),
    ])
    .unwrap();
    let state = GameState::builder(
        StateRevision::INITIAL,
        0,
        HexGridBounds::new(6, 1).unwrap(),
        UnitOccupancyPolicy::Exclusive,
        [unit],
    )
    .with_fog_of_war(fog)
    .try_build()
    .unwrap();
    let tiles = positions
        .into_iter()
        .map(|position| {
            TileDefinition::try_new_for_simulation(position, vec![TerrainType::Plains], vec![], 0)
                .unwrap()
        })
        .collect();
    let map =
        MapDefinition::try_new("route-map", GridLayout::OddQFlatTop, 6, 1, tiles, vec![]).unwrap();
    (state, map, actor)
}
