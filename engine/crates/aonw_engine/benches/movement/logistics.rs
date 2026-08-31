use std::collections::BTreeMap;
use std::hint::black_box;

use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{
    City, CityId, FogOfWar, GameMode, GameState, HexCoord, MatchIdentity, MatchLifecycle,
    MatchRules, MovementUnits, Participant, PlayerCountry, PlayerId, PlayerKind, PlayerTurnState,
    StateRevision, TurnLifecycle, Unit, UnitId, UnitKind, UnitOccupancyPolicy,
};
use aonw_engine::{
    AssignMerchantTradeRouteCommand, AutoExploreUnitCommand, EngineContext, GameEngine, GameQuery,
    MovementSearchMetrics, PlayerCommand, QueryResult, UnitLogisticsOptionsQuery,
};

use super::support::{mix, report, signature_bytes, signed};

pub(super) fn benchmark(map: &MapDefinition, cols: u16, rows: u16, unit_count: usize) {
    let actor = PlayerId::new("player-1").expect("actor");
    let context = EngineContext::canonical(&actor, map, RulesetDefinition::standard());
    let scout_id = UnitId::new("logistics-scout").expect("scout id");
    let scout_state = logistics_state(cols, rows, unit_count, &actor, UnitKind::Scout);
    let metrics = auto_metrics(&scout_state, context, &scout_id);
    report(
        "logistics_auto_options",
        cols,
        rows,
        unit_count,
        metrics,
        0,
        || auto_option_signature(black_box(&scout_state), context, &scout_id),
    );
    report(
        "logistics_auto_apply",
        cols,
        rows,
        unit_count,
        metrics,
        0,
        || {
            GameEngine::apply_player_owned(
                black_box(scout_state.clone()),
                context,
                PlayerCommand::AutoExploreUnit(AutoExploreUnitCommand::new(
                    scout_state.revision().get(),
                    &scout_id,
                )),
            )
            .map_or_else(
                |error| signature_bytes(error.to_string().as_bytes()),
                |transition| transition.digest().as_bytes()[0].into(),
            )
        },
    );

    let merchant_id = UnitId::new("logistics-merchant").expect("merchant id");
    let destination_id = CityId::new("logistics-city-b").expect("city id");
    let merchant_state = merchant_state(cols, rows, unit_count, &actor);
    report(
        "logistics_merchant_long_route",
        cols,
        rows,
        unit_count,
        MovementSearchMetrics::default(),
        0,
        || {
            GameEngine::apply_player_owned(
                black_box(merchant_state.clone()),
                context,
                PlayerCommand::AssignMerchantTradeRoute(AssignMerchantTradeRouteCommand::new(
                    merchant_state.revision().get(),
                    &merchant_id,
                    &destination_id,
                )),
            )
            .map_or_else(
                |error| signature_bytes(error.to_string().as_bytes()),
                |transition| transition.digest().as_bytes()[0].into(),
            )
        },
    );
}

fn auto_metrics(
    state: &GameState,
    context: EngineContext<'_>,
    scout_id: &UnitId,
) -> MovementSearchMetrics {
    let query = GameQuery::UnitLogisticsOptions(UnitLogisticsOptionsQuery::new(
        state.revision().get(),
        scout_id,
    ));
    let Ok(QueryResult::UnitLogisticsOptions(options)) = GameEngine::query(state, context, query)
    else {
        return MovementSearchMetrics::default();
    };
    options
        .auto_explore()
        .map_or(MovementSearchMetrics::default(), |option| {
            option.search_metrics()
        })
}

fn auto_option_signature(state: &GameState, context: EngineContext<'_>, scout_id: &UnitId) -> u64 {
    let query = GameQuery::UnitLogisticsOptions(UnitLogisticsOptionsQuery::new(
        state.revision().get(),
        scout_id,
    ));
    GameEngine::query(state, context, query).map_or_else(
        |error| signature_bytes(error.code().as_bytes()),
        |result| {
            let QueryResult::UnitLogisticsOptions(options) = result else {
                unreachable!("logistics query result")
            };
            options.auto_explore().map_or(0, |option| {
                mix(signed(option.target().col()), signed(option.target().row()))
            })
        },
    )
}

fn logistics_state(
    cols: u16,
    rows: u16,
    unit_count: usize,
    actor: &PlayerId,
    primary_kind: UnitKind,
) -> GameState {
    let mut units = Vec::with_capacity(unit_count);
    units.push(unit(
        "logistics-scout",
        actor,
        primary_kind,
        HexCoord::new(0, 0),
    ));
    append_units(&mut units, cols, rows, unit_count, actor);
    state(cols, rows, actor, units, Vec::new())
}

fn merchant_state(cols: u16, rows: u16, unit_count: usize, actor: &PlayerId) -> GameState {
    let origin = HexCoord::new(0, 0);
    let destination = HexCoord::new(i32::from(cols) - 1, 0);
    let mut units = Vec::with_capacity(unit_count);
    units.push(unit(
        "logistics-merchant",
        actor,
        UnitKind::Merchant,
        origin,
    ));
    append_units(&mut units, cols, rows, unit_count, actor);
    state(
        cols,
        rows,
        actor,
        units,
        vec![
            City::new(
                CityId::new("logistics-city-a").expect("city id"),
                actor.clone(),
                origin,
                [],
            ),
            City::new(
                CityId::new("logistics-city-b").expect("city id"),
                actor.clone(),
                destination,
                [],
            ),
        ],
    )
}

fn append_units(units: &mut Vec<Unit>, cols: u16, rows: u16, unit_count: usize, actor: &PlayerId) {
    let positions =
        (1..rows).flat_map(|row| (0..cols).map(move |col| HexCoord::new(col.into(), row.into())));
    for (index, position) in positions.take(unit_count.saturating_sub(1)).enumerate() {
        units.push(unit(
            &format!("logistics-unit-{}", index + 1),
            actor,
            UnitKind::Warrior,
            position,
        ));
    }
    assert_eq!(units.len(), unit_count, "logistics workload must fit map");
}

fn state(cols: u16, rows: u16, actor: &PlayerId, units: Vec<Unit>, cities: Vec<City>) -> GameState {
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [Participant::try_new(
            actor.clone(),
            "Player 1",
            0xff00_0000,
            PlayerCountry::Poland,
            PlayerKind::Human,
            None,
        )
        .expect("participant")],
        GameMode::Multiplayer,
    )
    .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([(actor.clone(), PlayerTurnState::Active)]),
        [actor.clone()],
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle");
    GameState::builder(
        StateRevision::new(1),
        1,
        aonw_domain::HexGridBounds::new(cols, rows).expect("bounds"),
        UnitOccupancyPolicy::Exclusive,
        units,
    )
    .with_cities(cities)
    .with_fog_of_war(FogOfWar::default())
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state")
}

fn unit(id: &str, owner: &PlayerId, kind: UnitKind, position: HexCoord) -> Unit {
    Unit::builder(
        UnitId::new(id).expect("unit id"),
        owner.clone(),
        kind,
        id,
        position,
        MovementUnits::new(10),
    )
    .build()
    .expect("unit")
}
