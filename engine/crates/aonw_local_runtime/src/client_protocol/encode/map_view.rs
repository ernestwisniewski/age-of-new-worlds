use aonw_content::{
    GridLayout, MapDocument, MapObjective, MapObjectiveType, ResourceType, TerrainType,
    TileDefinition,
};
use aonw_contracts::CoordinateDto;
use aonw_contracts::client::{
    MapGridLayoutDto, MapObjectiveTypeDto, MapObjectiveViewDto, MapResourceDto, MapTerrainDto,
    MapTileViewDto, MapViewDto,
};
use aonw_domain::HexCoord;

pub(crate) fn map(document: &MapDocument) -> Result<MapViewDto, serde_json::Error> {
    let map = document.map();
    Ok(MapViewDto {
        map_id: map.map_id().to_owned(),
        content_hash: map.content_hash()?.to_string(),
        grid_layout: grid_layout(map.grid_layout()),
        cols: map.cols(),
        rows: map.rows(),
        default_zoom: document.default_zoom(),
        tiles: map.tiles().iter().map(tile).collect(),
        objectives: map.objectives().iter().map(objective).collect(),
    })
}

const fn grid_layout(value: GridLayout) -> MapGridLayoutDto {
    match value {
        GridLayout::OddQFlatTop => MapGridLayoutDto::OddQFlatTop,
    }
}

fn tile(value: &TileDefinition) -> MapTileViewDto {
    MapTileViewDto {
        coordinate: coordinate(value.coordinate()),
        display_terrain: terrain(value.display_terrain()),
        yield_terrain: terrain(value.yield_terrain()),
        movement_terrains: value
            .movement_terrains()
            .iter()
            .copied()
            .map(terrain)
            .collect(),
        terrain_tags: value.terrain_tags().iter().copied().map(terrain).collect(),
        resources: value.resources().iter().copied().map(resource).collect(),
        height: value.height(),
    }
}

fn objective(value: &MapObjective) -> MapObjectiveViewDto {
    MapObjectiveViewDto {
        id: value.id().to_owned(),
        objective_type: objective_type(value.objective_type()),
        coordinate: coordinate(value.coordinate()),
        required_hold_turns: value.required_hold_turns(),
        victory_points: value.victory_points(),
        gold_per_turn: value.gold_per_turn(),
    }
}

pub(super) const fn terrain(value: TerrainType) -> MapTerrainDto {
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

pub(super) const fn resource(value: ResourceType) -> MapResourceDto {
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

pub(super) const fn objective_type(value: MapObjectiveType) -> MapObjectiveTypeDto {
    match value {
        MapObjectiveType::Ruins => MapObjectiveTypeDto::Ruins,
        MapObjectiveType::StrategicPass => MapObjectiveTypeDto::StrategicPass,
        MapObjectiveType::HolySite => MapObjectiveTypeDto::HolySite,
        MapObjectiveType::LegendaryResource => MapObjectiveTypeDto::LegendaryResource,
    }
}

pub(super) const fn coordinate(value: HexCoord) -> CoordinateDto {
    CoordinateDto {
        col: value.col(),
        row: value.row(),
    }
}
