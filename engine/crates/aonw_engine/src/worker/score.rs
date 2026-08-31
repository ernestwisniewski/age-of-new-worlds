use aonw_content::{ResourceType, TerrainType, TileDefinition, WorkerImprovementDefinition};
use aonw_domain::{City, HexCoord};

#[derive(Clone, Copy, Default)]
struct Yield {
    food: i64,
    production: i64,
    gold: i64,
    defense: i64,
}

impl Yield {
    const fn plus(self, other: Self) -> Self {
        Self {
            food: self.food + other.food,
            production: self.production + other.production,
            gold: self.gold + other.gold,
            defense: self.defense + other.defense,
        }
    }

    const fn assignment_bonus(self) -> Self {
        Self {
            food: half_rounded_up(self.food),
            production: half_rounded_up(self.production),
            gold: half_rounded_up(self.gold),
            defense: 0,
        }
    }

    const fn weighted(self) -> i64 {
        self.food * 1_000 + self.production * 300 + self.gold * 180 + self.defense * 80
    }
}

pub(super) fn improvement_score(
    definition: WorkerImprovementDefinition,
    tile: &TileDefinition,
) -> i64 {
    let delta = improvement_yield(definition);
    delta.weighted()
        + if definition.specialist() { 700 } else { 0 }
        + base_yield(tile).food * 20
        + base_yield(tile).production * 5
}

pub(super) fn assignment_score(
    city: &City,
    target: HexCoord,
    definition: WorkerImprovementDefinition,
    tile: &TileDefinition,
) -> i64 {
    let tile_yield = base_yield(tile).plus(improvement_yield(definition));
    let full_yield = if city.worked_hexes().contains(&target) {
        Yield::default()
    } else {
        tile_yield
    };
    full_yield.plus(tile_yield.assignment_bonus()).weighted()
}

const fn improvement_yield(definition: WorkerImprovementDefinition) -> Yield {
    let delta = definition.yield_delta();
    Yield {
        food: delta.food() as i64,
        production: delta.production() as i64,
        gold: delta.gold() as i64,
        defense: delta.defense() as i64,
    }
}

fn base_yield(tile: &TileDefinition) -> Yield {
    let mut value = match tile.yield_terrain() {
        TerrainType::Grassland | TerrainType::Wetlands => Yield {
            food: 2,
            ..Yield::default()
        },
        TerrainType::Plains | TerrainType::Forest => Yield {
            food: 1,
            production: 1,
            ..Yield::default()
        },
        TerrainType::Hills => Yield {
            production: 2,
            ..Yield::default()
        },
        TerrainType::Tundra | TerrainType::Jungle | TerrainType::Coast | TerrainType::Lake => {
            Yield {
                food: 1,
                ..Yield::default()
            }
        }
        _ => Yield::default(),
    };
    if tile.terrain_tags().contains(&TerrainType::River) {
        value.food += 1;
    }
    for resource in tile.resources() {
        match resource {
            ResourceType::Wheat
            | ResourceType::Fish
            | ResourceType::Rice
            | ResourceType::Apple
            | ResourceType::Banana
            | ResourceType::Citrus => value.food += 2,
            ResourceType::Deer | ResourceType::Cow | ResourceType::Sheep => {
                value.food += 1;
                value.production += 1;
            }
            ResourceType::Iron | ResourceType::Marble => value.production += 2,
            _ => {}
        }
    }
    value
}

const fn half_rounded_up(value: i64) -> i64 {
    if value <= 0 { 0 } else { (value + 1) / 2 }
}
