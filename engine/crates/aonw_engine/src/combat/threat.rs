use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{FogVisibility, GameState, HexCoord, MovementUnits, PlayerId, Unit};

use super::stats;

/// Returns recipient-inspectable coordinates threatened by one foreign unit.
///
/// The result is computed from authoritative combat stats and excludes units
/// that cannot currently perform a manual attack. Coordinates keep canonical
/// recipient coordinate order and never disclose hidden fog cells.
#[must_use]
pub fn unit_threatened_hexes(
    state: &GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    unit: &Unit,
    recipient: &PlayerId,
) -> Box<[HexCoord]> {
    if unit.owner_player_id() == recipient
        || unit.activity().blocks_manual_movement()
        || unit.movement_units() == MovementUnits::ZERO
    {
        return Box::default();
    }
    let Some(origin_tile) = map.tile_at(unit.position()) else {
        return Box::default();
    };
    let Some(combat_stats) = stats::for_unit(
        state,
        ruleset,
        unit,
        stats::UnitCombatSituation {
            opponent: None,
            defended_city: None,
            attacker: true,
            terrain_tags: origin_tile.terrain_tags(),
            opponent_terrain_tags: &[],
        },
    ) else {
        return Box::default();
    };
    if combat_stats.attack <= 0 || combat_stats.range == 0 {
        return Box::default();
    }
    let mut coordinates: Vec<_> = map
        .tiles()
        .iter()
        .map(aonw_content::TileDefinition::coordinate)
        .filter(|coordinate| {
            unit.position().distance_to(*coordinate) <= u64::from(combat_stats.range)
                && state.fog_of_war().visibility(recipient, *coordinate) != FogVisibility::Hidden
        })
        .collect();
    coordinates.sort_unstable();
    coordinates.into_boxed_slice()
}
