use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_domain::{HexCoord, PlayerId};

use crate::{CompiledMovementMap, EngineContext, movement::MovementPlanningView};

#[test]
fn engine_context_carries_actor_and_map_explicitly() {
    let actor = PlayerId::new("player-1").expect("valid player id");
    let tile = TileDefinition::try_new_for_simulation(
        HexCoord::new(0, 0),
        vec![TerrainType::Plains],
        Vec::new(),
        0,
    )
    .expect("valid tile");
    let map = MapDefinition::try_new(
        "fixture",
        GridLayout::OddQFlatTop,
        1,
        1,
        vec![tile],
        Vec::new(),
    )
    .expect("valid logical map");

    let context = EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled());

    assert_eq!(context.actor_player_id(), &actor);
    assert_eq!(context.map().map_id(), "fixture");
}

#[test]
fn compiled_context_uses_the_content_it_was_compiled_from() {
    let actor = PlayerId::new("player-1").expect("valid player id");
    let map = single_tile_map("source");
    let other_map = single_tile_map("other");
    let compiled =
        CompiledMovementMap::compile_owned(map.clone(), RulesetDefinition::standard().clone())
            .expect("compiled");

    let context = EngineContext::new(&actor, &other_map, MovementPlanningView::fog_disabled())
        .with_compiled_movement_map(&compiled);

    assert_eq!(context.map().map_id(), "source");
    assert_eq!(context.ruleset(), RulesetDefinition::standard());
}

fn single_tile_map(map_id: &str) -> MapDefinition {
    MapDefinition::try_new(
        map_id,
        GridLayout::OddQFlatTop,
        1,
        1,
        vec![
            TileDefinition::try_new_for_simulation(
                HexCoord::new(0, 0),
                vec![TerrainType::Plains],
                Vec::new(),
                0,
            )
            .expect("valid tile"),
        ],
        Vec::new(),
    )
    .expect("valid logical map")
}
