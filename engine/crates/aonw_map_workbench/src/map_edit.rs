use aonw_content::{MapDocument, ResourceType, TerrainProfile, TerrainType, TileDefinition};
use aonw_domain::HexCoord;
use aonw_map_authoring::TerrainAuthoringProfile;
use serde::Serialize;

use crate::MapWorkbenchError;

/// Validated tile state and Rust-owned palettes used by the Godot workbench.
#[derive(Clone, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct LogicalMapTileEditorSnapshot {
    map_content_hash: String,
    cols: u16,
    rows: u16,
    tile: LogicalMapTileSnapshot,
    terrain_options: Box<[TerrainType]>,
    resource_options: Box<[ResourceType]>,
}

impl LogicalMapTileEditorSnapshot {
    /// Inspects one tile through the authoritative content model.
    ///
    /// # Errors
    ///
    /// Returns [`MapWorkbenchError`] when the document or coordinate is invalid.
    pub fn inspect(map_document: &str, coordinate: HexCoord) -> Result<Self, MapWorkbenchError> {
        let document = MapDocument::from_json(map_document.as_bytes())?;
        Self::from_document(&document, coordinate)
    }

    fn from_document(
        document: &MapDocument,
        coordinate: HexCoord,
    ) -> Result<Self, MapWorkbenchError> {
        let map = document.map();
        let tile = map.tile_at(coordinate).ok_or_else(|| {
            MapWorkbenchError::invalid_edit(
                "$.request.coordinate",
                format!(
                    "coordinate ({}, {}) is outside map bounds",
                    coordinate.col(),
                    coordinate.row()
                ),
            )
        })?;
        Ok(Self {
            map_content_hash: map.content_hash()?.to_string(),
            cols: map.cols(),
            rows: map.rows(),
            tile: LogicalMapTileSnapshot::from(tile),
            terrain_options: TerrainType::ALL.into(),
            resource_options: ResourceType::ALL.into(),
        })
    }
}

/// Canonical map and terrain-profile replacements produced by one logical edit.
#[derive(Clone, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct UpdatedLogicalMap {
    map_document: String,
    terrain_authoring_document: String,
    map_content_hash: String,
    authoring_profile_hash: String,
    snapshot: LogicalMapTileEditorSnapshot,
}

impl UpdatedLogicalMap {
    /// Replaces the selected tile's authored terrain with one Rust terrain value.
    ///
    /// # Errors
    ///
    /// Returns [`MapWorkbenchError`] when either source document, the
    /// coordinate, or the requested terrain violates an invariant.
    pub fn set_tile_terrain(
        map_document: &str,
        terrain_authoring_document: &str,
        coordinate: HexCoord,
        terrain: TerrainType,
    ) -> Result<Self, MapWorkbenchError> {
        Self::edit(
            map_document,
            terrain_authoring_document,
            coordinate,
            |tile| {
                TileDefinition::try_new(
                    coordinate,
                    TerrainProfile::try_new(vec![terrain])?,
                    tile.resources().to_vec(),
                    tile.height(),
                )
            },
        )
    }

    /// Replaces the selected tile's complete resource collection.
    ///
    /// # Errors
    ///
    /// Returns [`MapWorkbenchError`] when either source document, the
    /// coordinate, or the requested resources violate an invariant.
    pub fn set_tile_resources(
        map_document: &str,
        terrain_authoring_document: &str,
        coordinate: HexCoord,
        resources: Vec<ResourceType>,
    ) -> Result<Self, MapWorkbenchError> {
        Self::edit(
            map_document,
            terrain_authoring_document,
            coordinate,
            |tile| {
                TileDefinition::try_new(
                    coordinate,
                    tile.terrain().clone(),
                    resources,
                    tile.height(),
                )
            },
        )
    }

    /// Replaces the selected tile's logical gameplay height.
    ///
    /// # Errors
    ///
    /// Returns [`MapWorkbenchError`] when either source document, the
    /// coordinate, or the requested height violates an invariant.
    pub fn set_tile_height(
        map_document: &str,
        terrain_authoring_document: &str,
        coordinate: HexCoord,
        height: u8,
    ) -> Result<Self, MapWorkbenchError> {
        Self::edit(
            map_document,
            terrain_authoring_document,
            coordinate,
            |tile| {
                TileDefinition::try_new(
                    coordinate,
                    tile.terrain().clone(),
                    tile.resources().to_vec(),
                    height,
                )
            },
        )
    }

    fn edit(
        map_document: &str,
        terrain_authoring_document: &str,
        coordinate: HexCoord,
        replacement: impl FnOnce(
            &TileDefinition,
        ) -> Result<TileDefinition, aonw_content::MapValidationError>,
    ) -> Result<Self, MapWorkbenchError> {
        let current_document = MapDocument::from_json(map_document.as_bytes())?;
        let current_profile = TerrainAuthoringProfile::from_json(
            terrain_authoring_document.as_bytes(),
            current_document.map(),
        )?;
        let current_tile = current_document.map().tile_at(coordinate).ok_or_else(|| {
            MapWorkbenchError::invalid_edit(
                "$.request.coordinate",
                format!(
                    "coordinate ({}, {}) is outside map bounds",
                    coordinate.col(),
                    coordinate.row()
                ),
            )
        })?;
        let replacement = replacement(current_tile).map_err(MapWorkbenchError::EditedMap)?;
        let updated_map = current_document
            .map()
            .replacing_tile(replacement)
            .map_err(MapWorkbenchError::EditedMap)?;
        let updated_document = MapDocument::try_new(updated_map, current_document.default_zoom())
            .map_err(MapWorkbenchError::EditedMap)?;
        let updated_profile = current_profile.with_max_terrain_height_meters(
            updated_document.map(),
            current_profile.max_terrain_height_meters(),
        )?;
        let snapshot = LogicalMapTileEditorSnapshot::from_document(&updated_document, coordinate)?;
        Ok(Self {
            map_document: updated_document.to_versioned_json()?,
            terrain_authoring_document: updated_profile.to_versioned_json()?,
            map_content_hash: snapshot.map_content_hash.clone(),
            authoring_profile_hash: updated_profile.authoring_profile_hash()?.to_string(),
            snapshot,
        })
    }
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
struct LogicalMapTileSnapshot {
    col: i32,
    row: i32,
    display_terrain: TerrainType,
    terrain_tags: Box<[TerrainType]>,
    resources: Box<[ResourceType]>,
    height: u8,
}

impl From<&TileDefinition> for LogicalMapTileSnapshot {
    fn from(tile: &TileDefinition) -> Self {
        Self {
            col: tile.coordinate().col(),
            row: tile.coordinate().row(),
            display_terrain: tile.display_terrain(),
            terrain_tags: tile.terrain_tags().into(),
            resources: tile.resources().into(),
            height: tile.height(),
        }
    }
}
