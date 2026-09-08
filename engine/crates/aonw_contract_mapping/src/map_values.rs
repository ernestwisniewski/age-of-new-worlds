use aonw_content::{ResourceType, TerrainType};
use aonw_contracts::client::{MapResourceDto, MapTerrainDto};

/// Converts an authored map terrain to its closed wire value.
#[must_use]
pub const fn encode_map_terrain(value: TerrainType) -> MapTerrainDto {
    match value {
        TerrainType::Ocean => MapTerrainDto::Ocean,
        TerrainType::Coast => MapTerrainDto::Coast,
        TerrainType::Lake => MapTerrainDto::Lake,
        TerrainType::Plains => MapTerrainDto::Plains,
        TerrainType::Grassland => MapTerrainDto::Grassland,
        TerrainType::Desert => MapTerrainDto::Desert,
        TerrainType::Tundra => MapTerrainDto::Tundra,
        TerrainType::Snow => MapTerrainDto::Snow,
        TerrainType::Mountain => MapTerrainDto::Mountain,
        TerrainType::Hills => MapTerrainDto::Hills,
        TerrainType::Wetlands => MapTerrainDto::Wetlands,
        TerrainType::Jungle => MapTerrainDto::Jungle,
        TerrainType::Forest => MapTerrainDto::Forest,
        TerrainType::River => MapTerrainDto::River,
    }
}

/// Converts an authored map resource to its closed wire value.
#[must_use]
pub const fn encode_map_resource(value: ResourceType) -> MapResourceDto {
    match value {
        ResourceType::Wheat => MapResourceDto::Wheat,
        ResourceType::Fish => MapResourceDto::Fish,
        ResourceType::Deer => MapResourceDto::Deer,
        ResourceType::Sheep => MapResourceDto::Sheep,
        ResourceType::Rice => MapResourceDto::Rice,
        ResourceType::Cow => MapResourceDto::Cow,
        ResourceType::Apple => MapResourceDto::Apple,
        ResourceType::Banana => MapResourceDto::Banana,
        ResourceType::Citrus => MapResourceDto::Citrus,
        ResourceType::Gold => MapResourceDto::Gold,
        ResourceType::Silver => MapResourceDto::Silver,
        ResourceType::Gems => MapResourceDto::Gems,
        ResourceType::Silk => MapResourceDto::Silk,
        ResourceType::Spices => MapResourceDto::Spices,
        ResourceType::Cotton => MapResourceDto::Cotton,
        ResourceType::Grapes => MapResourceDto::Grapes,
        ResourceType::Ivory => MapResourceDto::Ivory,
        ResourceType::Pearls => MapResourceDto::Pearls,
        ResourceType::Coffee => MapResourceDto::Coffee,
        ResourceType::Cocoa => MapResourceDto::Cocoa,
        ResourceType::Tobacco => MapResourceDto::Tobacco,
        ResourceType::Sugar => MapResourceDto::Sugar,
        ResourceType::Iron => MapResourceDto::Iron,
        ResourceType::Coal => MapResourceDto::Coal,
        ResourceType::Oil => MapResourceDto::Oil,
        ResourceType::Aluminium => MapResourceDto::Aluminium,
        ResourceType::Uranium => MapResourceDto::Uranium,
        ResourceType::Horses => MapResourceDto::Horses,
        ResourceType::Marble => MapResourceDto::Marble,
    }
}
