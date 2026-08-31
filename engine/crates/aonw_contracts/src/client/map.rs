use serde::de::Error as _;
use serde::{Deserialize, Deserializer, Serialize};

use crate::{CoordinateDto, MapObjectiveTypeDto};

/// Framework-neutral map read model returned to presentation clients.
#[derive(Clone, Debug, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct MapViewDto {
    /// Stable authored map identifier.
    pub map_id: String,
    /// SHA-256 identity of canonical logical map content.
    pub content_hash: String,
    /// Hex-grid orientation used by geometry adapters.
    pub grid_layout: MapGridLayoutDto,
    /// Number of tile columns.
    pub cols: u16,
    /// Number of tile rows.
    pub rows: u16,
    /// Authored initial presentation zoom.
    #[serde(deserialize_with = "deserialize_f64")]
    pub default_zoom: f64,
    /// Stable row-major presentation tiles.
    pub tiles: Vec<MapTileViewDto>,
    /// Stable identifier-ordered map objectives.
    pub objectives: Vec<MapObjectiveViewDto>,
}

fn deserialize_f64<'de, D: Deserializer<'de>>(deserializer: D) -> Result<f64, D::Error> {
    let number = serde_json::Number::deserialize(deserializer)?;
    number
        .as_f64()
        .filter(|value| value.is_finite())
        .ok_or_else(|| D::Error::custom("number must be representable as a finite f64"))
}

/// Presentation-safe semantics of one logical map tile.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct MapTileViewDto {
    /// Tile coordinate in the map grid.
    pub coordinate: CoordinateDto,
    /// Terrain selected for the base visual treatment.
    pub display_terrain: MapTerrainDto,
    /// Terrain selected for base economic presentation.
    pub yield_terrain: MapTerrainDto,
    /// Ordered movement semantics derived by the content domain.
    pub movement_terrains: Vec<MapTerrainDto>,
    /// Ordered authored terrain composition.
    pub terrain_tags: Vec<MapTerrainDto>,
    /// Stable ordered resources present on the tile.
    pub resources: Vec<MapResourceDto>,
    /// Logical authored elevation in the map rules range.
    pub height: u8,
}

/// Presentation-safe map objective.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct MapObjectiveViewDto {
    /// Stable objective identifier.
    pub id: String,
    /// Objective presentation kind.
    #[serde(rename = "type")]
    pub objective_type: MapObjectiveTypeDto,
    /// Objective coordinate.
    pub coordinate: CoordinateDto,
    /// Consecutive turns required to hold the objective.
    pub required_hold_turns: u32,
    /// Victory points granted by the objective.
    pub victory_points: u32,
    /// Gold granted each held turn.
    pub gold_per_turn: u32,
}

/// Supported map grid layouts.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum MapGridLayoutDto {
    /// Odd columns are vertically offset; hexes have flat top edges.
    OddQFlatTop,
}

/// Terrain values exposed by the current map presentation contract.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum MapTerrainDto {
    Ocean,
    Coast,
    Lake,
    Plains,
    Grassland,
    Desert,
    Tundra,
    Snow,
    Mountain,
    Hills,
    Wetlands,
    Jungle,
    Forest,
    River,
}

/// Resource values exposed by the current map presentation contract.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum MapResourceDto {
    Wheat,
    Fish,
    Deer,
    Sheep,
    Rice,
    Cow,
    Apple,
    Banana,
    Citrus,
    Gold,
    Silver,
    Gems,
    Silk,
    Spices,
    Cotton,
    Grapes,
    Ivory,
    Pearls,
    Coffee,
    Cocoa,
    Tobacco,
    Sugar,
    Iron,
    Coal,
    Oil,
    Aluminium,
    Uranium,
    Horses,
    Marble,
}
