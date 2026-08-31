use std::hint::black_box;

use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{
    City, CityId, GameState, HexCoord, HexGridBounds, MovementUnits, PlayerId, StateRevision, Unit,
    UnitId, UnitKind, UnitOccupancyPolicy,
};
use aonw_engine::{
    CityExpansionOptionsQuery, CityFoundingOptionsQuery, CityWorkedHexOptionsQuery, EngineContext,
    FoundCityCommand, GameEngine, GameQuery, MovementSearchMetrics, PlayerCommand, QueryResult,
};

use super::support::{mix, report, signature_bytes, signed};

pub(super) fn benchmark(map: &MapDefinition, cols: u16, rows: u16, entity_count: usize) {
    let actor = PlayerId::new("player-1").expect("actor");
    let founder_id = UnitId::new("city-founder").expect("founder id");
    let founding_state = city_state(cols, rows, entity_count, &actor, Some(&founder_id));
    let city_state = city_state(cols, rows, entity_count, &actor, None);
    let city_id = CityId::new("city-0").expect("city id");
    let context = EngineContext::canonical(&actor, map, RulesetDefinition::standard());
    let controlled = [HexCoord::new(3, 2), HexCoord::new(2, 3)];

    benchmark_founding(
        cols,
        rows,
        entity_count,
        &founding_state,
        context,
        &founder_id,
        &controlled,
    );
    benchmark_worked(cols, rows, entity_count, &city_state, context, &city_id);
    benchmark_expansion(cols, rows, entity_count, &city_state, context, &city_id);
}

fn benchmark_founding(
    cols: u16,
    rows: u16,
    entity_count: usize,
    state: &GameState,
    context: EngineContext<'_>,
    founder_id: &UnitId,
    controlled: &[HexCoord],
) {
    report(
        "city_founding_options",
        cols,
        rows,
        entity_count,
        MovementSearchMetrics::default(),
        0,
        || {
            GameEngine::query(
                black_box(state),
                context,
                GameQuery::CityFoundingOptions(CityFoundingOptionsQuery::new(
                    state.revision().get(),
                    founder_id,
                )),
            )
            .map_or_else(
                |error| signature_bytes(error.code().as_bytes()),
                |result| {
                    let QueryResult::CityFoundingOptions(options) = result else {
                        unreachable!("founding options")
                    };
                    mix(
                        u64::try_from(options.available_controlled_hexes().len())
                            .unwrap_or(u64::MAX),
                        u64::from(options.required_controlled_hexes()),
                    )
                },
            )
        },
    );
    report(
        "city_found_apply",
        cols,
        rows,
        entity_count,
        MovementSearchMetrics::default(),
        0,
        || {
            GameEngine::apply_player_owned(
                black_box(state.clone()),
                context,
                PlayerCommand::FoundCity(FoundCityCommand::new(
                    state.revision().get(),
                    founder_id,
                    controlled,
                )),
            )
            .map_or_else(
                |error| signature_bytes(error.to_string().as_bytes()),
                |transition| {
                    mix(
                        transition.state().revision().get(),
                        u64::from(transition.digest().as_bytes()[0]),
                    )
                },
            )
        },
    );
}

fn benchmark_worked(
    cols: u16,
    rows: u16,
    entity_count: usize,
    state: &GameState,
    context: EngineContext<'_>,
    city_id: &CityId,
) {
    report(
        "city_worked_options",
        cols,
        rows,
        entity_count,
        MovementSearchMetrics::default(),
        0,
        || {
            GameEngine::query(
                black_box(state),
                context,
                GameQuery::CityWorkedHexOptions(CityWorkedHexOptionsQuery::new(
                    state.revision().get(),
                    city_id,
                )),
            )
            .map_or_else(
                |error| signature_bytes(error.code().as_bytes()),
                |result| {
                    let QueryResult::CityWorkedHexOptions(options) = result else {
                        unreachable!("worked options")
                    };
                    options.effective_hexes().iter().fold(
                        u64::from(options.limit()),
                        |digest, coordinate| {
                            mix(
                                mix(digest, signed(coordinate.col())),
                                signed(coordinate.row()),
                            )
                        },
                    )
                },
            )
        },
    );
}

fn benchmark_expansion(
    cols: u16,
    rows: u16,
    entity_count: usize,
    state: &GameState,
    context: EngineContext<'_>,
    city_id: &CityId,
) {
    report(
        "city_expansion_options",
        cols,
        rows,
        entity_count,
        MovementSearchMetrics::default(),
        0,
        || {
            GameEngine::query(
                black_box(state),
                context,
                GameQuery::CityExpansionOptions(CityExpansionOptionsQuery::new(
                    state.revision().get(),
                    city_id,
                )),
            )
            .map_or_else(
                |error| signature_bytes(error.code().as_bytes()),
                |result| {
                    let QueryResult::CityExpansionOptions(options) = result else {
                        unreachable!("expansion options")
                    };
                    options.candidates().iter().fold(0, |digest, candidate| {
                        mix(
                            mix(digest, signed(candidate.coordinate().col())),
                            signed(candidate.coordinate().row()),
                        )
                    })
                },
            )
        },
    );
}

fn city_state(
    cols: u16,
    rows: u16,
    entity_count: usize,
    actor: &PlayerId,
    founder_id: Option<&UnitId>,
) -> GameState {
    let center = HexCoord::new(3, 3);
    let units = founder_id.into_iter().map(|id| {
        Unit::builder(
            id.clone(),
            actor.clone(),
            UnitKind::Settler,
            "founder",
            center,
            MovementUnits::new(10),
        )
        .build()
        .expect("founder")
    });
    let mut cities = vec![
        City::builder(
            CityId::new("city-0").expect("city id"),
            actor.clone(),
            "Benchmark",
            center,
        )
        .with_controlled_hexes([
            HexCoord::new(3, 2),
            HexCoord::new(2, 3),
            HexCoord::new(3, 4),
        ])
        .build()
        .expect("city"),
    ];
    let positions = (6..i32::from(rows))
        .flat_map(|row| (0..i32::from(cols)).map(move |col| HexCoord::new(col, row)))
        .chain(
            (0..i32::from(rows))
                .flat_map(|row| (7..i32::from(cols)).map(move |col| HexCoord::new(col, row))),
        );
    cities.extend(
        positions
            .take(entity_count.saturating_sub(1))
            .enumerate()
            .map(|(index, position)| {
                City::new(
                    CityId::new(format!("city-{}", index + 1)).expect("city id"),
                    actor.clone(),
                    position,
                    [],
                )
            }),
    );
    assert_eq!(cities.len(), entity_count, "city benchmark must fit map");
    let cities = if founder_id.is_some() {
        cities.into_iter().skip(1).collect()
    } else {
        cities
    };
    GameState::builder(
        StateRevision::new(1),
        1,
        HexGridBounds::new(cols, rows).expect("bounds"),
        UnitOccupancyPolicy::Exclusive,
        units,
    )
    .with_cities(cities)
    .try_build()
    .expect("city benchmark state")
}
