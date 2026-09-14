use aonw_content::{GridLayout, TerrainType, TileDefinition};
use aonw_domain::{MovementUnits, StateRevision, UnitId, UnitKind};

use super::*;
use crate::{GameEngine, MoveUnitCommand, PlayerCommand};

#[test]
fn replacing_ruleset_invalidates_compiled_data_and_preserves_command_identity() {
    let actor = PlayerId::new("player").expect("actor");
    let map = MapDefinition::try_new(
        "context",
        GridLayout::OddQFlatTop,
        2,
        1,
        (0..2)
            .map(|col| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(col, 0),
                    vec![TerrainType::Plains],
                    Vec::new(),
                    0,
                )
                .expect("tile")
            })
            .collect(),
        Vec::new(),
    )
    .expect("map");
    let compiled =
        CompiledMovementMap::compile_owned(map.clone(), RulesetDefinition::standard().clone())
            .expect("compiled map");
    // Standard is currently the only publicly constructible ruleset. A separate
    // clone still exercises invalidation when the context input is replaced.
    let replacement = RulesetDefinition::standard().clone();
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard())
        .with_compiled_movement_map(&compiled)
        .with_ruleset(&replacement);
    assert!(context.compiled_movement_map().is_none());
    assert!(core::ptr::eq(
        context.ruleset(),
        core::ptr::from_ref(&replacement)
    ));
    let unit_id = UnitId::new("unit").expect("unit id");
    let unit = Unit::builder(
        unit_id.clone(),
        actor.clone(),
        UnitKind::Warrior,
        "Warrior",
        HexCoord::new(0, 0),
        MovementUnits::new(6),
    )
    .build()
    .expect("unit");
    let state = GameState::try_new(
        StateRevision::INITIAL,
        1,
        map.bounds(),
        replacement.occupancy_policy(),
        [unit],
    )
    .expect("state");
    let result = GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::MoveUnit(MoveUnitCommand::new(0, &unit_id, HexCoord::new(1, 0))),
    )
    .expect("command");
    assert!(result.is_accepted());
    assert_eq!(
        result.ruleset_hash(),
        replacement.content_hash().expect("ruleset hash")
    );
    assert_eq!(result.map_hash(), map.content_hash().expect("map hash"));
}
