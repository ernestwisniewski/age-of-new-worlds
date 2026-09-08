use aonw_content::{GridLayout, MapDocument, MapObjective, MapObjectiveType, TileDefinition};
pub(super) use aonw_contract_mapping::{
    encode_map_resource as resource, encode_map_terrain as terrain,
};
use aonw_contracts::CoordinateDto;
use aonw_contracts::client::{
    MapGridLayoutDto, MapObjectiveTypeDto, MapObjectiveViewDto, MapTileViewDto, MapViewDto,
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
