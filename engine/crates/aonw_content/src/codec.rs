use aonw_domain::HexCoord;

use crate::error::MapLoadError;
use crate::raw::{RawCanonicalMap, RawMap, RawMapDocument, RawObjective, RawTile};
use crate::{
    GridLayout, MapDefinition, MapDocument, MapObjective, MapObjectiveType, ResourceType,
    TerrainProfile, TerrainType, TileDefinition,
};

const MAX_MAP_DOCUMENT_BYTES: usize = 8 * 1024 * 1024;

impl MapDocument {
    /// Decodes the strict, versioned shared map format.
    ///
    /// # Errors
    ///
    /// Returns [`MapLoadError`] for malformed, incomplete, unsupported, or invalid input.
    pub fn from_json(source: &[u8]) -> Result<Self, MapLoadError> {
        check_size(source)?;
        build_document(serde_json::from_slice::<RawMapDocument>(source)?.try_into()?)
    }
}

impl MapDefinition {
    /// Decodes the strict canonical logical map used for content identity.
    ///
    /// Unlike an authored [`MapDocument`], a logical map has no presentation
    /// zoom and may use simulation-sized bounds.
    ///
    /// # Errors
    ///
    /// Returns [`MapLoadError`] for malformed, incomplete, unsupported, or
    /// invalid input.
    pub fn from_canonical_json(source: &[u8]) -> Result<Self, MapLoadError> {
        check_size(source)?;
        build_map(serde_json::from_slice::<RawCanonicalMap>(source)?.try_into()?)
    }
}

const fn check_size(source: &[u8]) -> Result<(), MapLoadError> {
    if source.len() <= MAX_MAP_DOCUMENT_BYTES {
        return Ok(());
    }
    Err(MapLoadError::DocumentTooLarge {
        actual: source.len(),
        limit: MAX_MAP_DOCUMENT_BYTES,
    })
}

fn build_document(raw: RawMap) -> Result<MapDocument, MapLoadError> {
    let default_zoom = raw.default_zoom;
    MapDocument::try_new(build_map(raw)?, default_zoom).map_err(Into::into)
}

fn build_map(raw: RawMap) -> Result<MapDefinition, MapLoadError> {
    let cols = u16_value("$.cols", raw.cols)?;
    let rows = u16_value("$.rows", raw.rows)?;
    let tiles = raw
        .tiles
        .into_iter()
        .enumerate()
        .map(|(index, tile)| build_tile(tile, index))
        .collect::<Result<Vec<_>, _>>()?;
    let objectives = raw
        .objectives
        .into_iter()
        .enumerate()
        .map(|(index, objective)| build_objective(objective, index))
        .collect::<Result<Vec<_>, _>>()?;
    MapDefinition::try_new(
        raw.map_name,
        GridLayout::OddQFlatTop,
        cols,
        rows,
        tiles,
        objectives,
    )
    .map_err(Into::into)
}

fn build_tile(raw: RawTile, index: usize) -> Result<TileDefinition, MapLoadError> {
    let path = format!("$.tiles[{index}]");
    let coordinate = HexCoord::new(
        i32_value(&format!("{path}.col"), raw.col)?,
        i32_value(&format!("{path}.row"), raw.row)?,
    );
    let height = u8::try_from(raw.height).map_err(|_| {
        MapLoadError::invalid(format!("{path}.height"), "must be a non-negative u8")
    })?;
    let terrain_tags = parse_values(
        raw.terrain_tags,
        &format!("{path}.terrainTags"),
        parse_terrain,
    )?;
    let terrain = TerrainProfile::try_new_at(&path, terrain_tags)?;
    let resources = parse_values(raw.resources, &format!("{path}.resources"), parse_resource)?;
    TileDefinition::try_new_at(&path, coordinate, terrain, resources, height).map_err(Into::into)
}

fn build_objective(raw: RawObjective, index: usize) -> Result<MapObjective, MapLoadError> {
    let path = format!("$.objectives[{index}]");
    MapObjective::try_new_at(
        &path,
        raw.id,
        parse_objective_type(&raw.objective_type, &format!("{path}.type"))?,
        HexCoord::new(
            i32_value(&format!("{path}.hex.col"), raw.hex.col)?,
            i32_value(&format!("{path}.hex.row"), raw.hex.row)?,
        ),
        positive_u32(
            &format!("{path}.requiredHoldTurns"),
            raw.required_hold_turns,
        )?,
        non_negative_u32(&format!("{path}.victoryPoints"), raw.victory_points)?,
        non_negative_u32(&format!("{path}.goldPerTurn"), raw.gold_per_turn)?,
    )
    .map_err(Into::into)
}

fn parse_values<Value>(
    raw_values: Vec<Box<str>>,
    path: &str,
    parse: fn(&str, &str) -> Result<Value, MapLoadError>,
) -> Result<Vec<Value>, MapLoadError> {
    let mut values = Vec::with_capacity(raw_values.len());
    for (index, raw) in raw_values.into_iter().enumerate() {
        let item_path = format!("{path}[{index}]");
        let value = parse(&raw, &item_path)?;
        values.push(value);
    }
    Ok(values)
}

fn u16_value(path: &str, value: i64) -> Result<u16, MapLoadError> {
    u16::try_from(value).map_err(|_| MapLoadError::invalid(path, "must be a non-negative u16"))
}

fn i32_value(path: &str, value: i64) -> Result<i32, MapLoadError> {
    i32::try_from(value).map_err(|_| MapLoadError::invalid(path, "must fit i32"))
}

fn positive_u32(path: &str, value: i64) -> Result<u32, MapLoadError> {
    let value = non_negative_u32(path, value)?;
    if value == 0 {
        return Err(MapLoadError::invalid(path, "must be positive"));
    }
    Ok(value)
}

fn non_negative_u32(path: &str, value: i64) -> Result<u32, MapLoadError> {
    u32::try_from(value).map_err(|_| MapLoadError::invalid(path, "must be a non-negative u32"))
}

fn parse_terrain(value: &str, path: &str) -> Result<TerrainType, MapLoadError> {
    match value {
        "ocean" => Ok(TerrainType::Ocean),
        "coast" => Ok(TerrainType::Coast),
        "lake" => Ok(TerrainType::Lake),
        "plains" => Ok(TerrainType::Plains),
        "grassland" => Ok(TerrainType::Grassland),
        "desert" => Ok(TerrainType::Desert),
        "tundra" => Ok(TerrainType::Tundra),
        "snow" => Ok(TerrainType::Snow),
        "mountain" => Ok(TerrainType::Mountain),
        "hills" => Ok(TerrainType::Hills),
        "wetlands" => Ok(TerrainType::Wetlands),
        "jungle" => Ok(TerrainType::Jungle),
        "forest" => Ok(TerrainType::Forest),
        "river" => Ok(TerrainType::River),
        _ => Err(MapLoadError::invalid(
            path,
            format!("unknown terrain {value:?}"),
        )),
    }
}

fn parse_resource(value: &str, path: &str) -> Result<ResourceType, MapLoadError> {
    let resource = match value {
        "wheat" => ResourceType::Wheat,
        "fish" => ResourceType::Fish,
        "deer" => ResourceType::Deer,
        "sheep" => ResourceType::Sheep,
        "rice" => ResourceType::Rice,
        "cow" => ResourceType::Cow,
        "apple" => ResourceType::Apple,
        "banana" => ResourceType::Banana,
        "citrus" => ResourceType::Citrus,
        "gold" => ResourceType::Gold,
        "silver" => ResourceType::Silver,
        "gems" => ResourceType::Gems,
        "silk" => ResourceType::Silk,
        "spices" => ResourceType::Spices,
        "cotton" => ResourceType::Cotton,
        "grapes" => ResourceType::Grapes,
        "ivory" => ResourceType::Ivory,
        "pearls" => ResourceType::Pearls,
        "coffee" => ResourceType::Coffee,
        "cocoa" => ResourceType::Cocoa,
        "tobacco" => ResourceType::Tobacco,
        "sugar" => ResourceType::Sugar,
        "iron" => ResourceType::Iron,
        "coal" => ResourceType::Coal,
        "oil" => ResourceType::Oil,
        "aluminium" => ResourceType::Aluminium,
        "uranium" => ResourceType::Uranium,
        "horses" => ResourceType::Horses,
        "marble" => ResourceType::Marble,
        _ => {
            return Err(MapLoadError::invalid(
                path,
                format!("unknown resource {value:?}"),
            ));
        }
    };
    Ok(resource)
}

fn parse_objective_type(value: &str, path: &str) -> Result<MapObjectiveType, MapLoadError> {
    match value {
        "ruins" => Ok(MapObjectiveType::Ruins),
        "strategicPass" => Ok(MapObjectiveType::StrategicPass),
        "holySite" => Ok(MapObjectiveType::HolySite),
        "legendaryResource" => Ok(MapObjectiveType::LegendaryResource),
        _ => Err(MapLoadError::invalid(
            path,
            format!("unknown objective type {value:?}"),
        )),
    }
}
