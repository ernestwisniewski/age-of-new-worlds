use aonw_content::{EconomyBalance, TileDefinition};

pub(super) fn worked_score(tile: &TileDefinition, balance: &EconomyBalance) -> i32 {
    clamp_score(base_score(tile, balance))
}

pub(super) fn expansion_score(tile: &TileDefinition, balance: &EconomyBalance) -> i32 {
    let score = base_score(tile, balance)
        .saturating_add(
            if tile
                .terrain_tags()
                .contains(&aonw_content::TerrainType::River)
            {
                10
            } else {
                0
            },
        )
        .saturating_add(if tile.resources().is_empty() { 0 } else { 5 });
    clamp_score(score)
}

fn base_score(tile: &TileDefinition, balance: &EconomyBalance) -> i64 {
    let Ok(value) = crate::economy::rules::tile_base_yield(tile, balance) else {
        return i64::MIN;
    };
    value
        .food
        .saturating_mul(100)
        .saturating_add(value.production.saturating_mul(30))
        .saturating_add(value.gold.saturating_mul(10))
        .saturating_add(value.defense)
}

fn clamp_score(score: i64) -> i32 {
    i32::try_from(score.clamp(i64::from(i32::MIN), i64::from(i32::MAX)))
        .expect("clamped city score fits i32")
}
