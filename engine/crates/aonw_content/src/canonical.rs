use std::io::{self, Write};

use serde::ser::{SerializeSeq, SerializeStruct};
use serde::{Serialize, Serializer};
use sha2::{Digest, Sha256};

use crate::{
    CURRENT_MAP_SCHEMA_VERSION, ContentHash, MapDefinition, MapDocument, MapObjective,
    TileDefinition,
};

struct CanonicalMap<'a>(&'a MapDefinition);

struct VersionedDocument<'a>(&'a MapDocument);

struct Tiles<'a>(&'a [TileDefinition]);
struct Objectives<'a>(&'a [MapObjective]);
struct Tile<'a>(&'a TileDefinition);
struct CanonicalObjective<'a>(&'a MapObjective);

impl MapDefinition {
    /// Returns the exact compact canonical bytes used for content identity.
    ///
    /// Presentation hints such as the initial camera zoom are excluded.
    ///
    /// # Errors
    ///
    /// Returns an error if JSON serialization cannot complete.
    pub fn canonical_bytes(&self) -> Result<Vec<u8>, serde_json::Error> {
        serde_json::to_vec(&CanonicalMap(self))
    }

    /// Computes SHA-256 over [`Self::canonical_bytes`].
    ///
    /// # Errors
    ///
    /// Returns an error if canonical JSON serialization cannot complete.
    pub fn content_hash(&self) -> Result<ContentHash, serde_json::Error> {
        let mut writer = HashWriter(Sha256::new());
        serde_json::to_writer(&mut writer, &CanonicalMap(self))?;
        Ok(ContentHash(writer.0.finalize().into()))
    }
}

struct HashWriter(Sha256);

impl Write for HashWriter {
    fn write(&mut self, buffer: &[u8]) -> io::Result<usize> {
        self.0.update(buffer);
        Ok(buffer.len())
    }

    fn flush(&mut self) -> io::Result<()> {
        Ok(())
    }
}

impl MapDocument {
    /// Serializes the complete versioned document for persistence or editing.
    ///
    /// # Errors
    ///
    /// Returns an error if JSON serialization cannot complete.
    pub fn to_versioned_json(&self) -> Result<String, serde_json::Error> {
        let mut output = serde_json::to_string_pretty(&VersionedDocument(self))?;
        output.push('\n');
        Ok(output)
    }
}

impl Serialize for CanonicalMap<'_> {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        let map = self.0;
        let mut value = serializer.serialize_struct("CanonicalMap", 7)?;
        value.serialize_field("schemaVersion", &CURRENT_MAP_SCHEMA_VERSION)?;
        value.serialize_field("gridLayout", &map.grid_layout())?;
        value.serialize_field("cols", &map.cols())?;
        value.serialize_field("rows", &map.rows())?;
        value.serialize_field("mapName", map.map_id())?;
        value.serialize_field("objectives", &Objectives(map.objectives()))?;
        value.serialize_field("tiles", &Tiles(map.tiles()))?;
        value.end()
    }
}

impl Serialize for VersionedDocument<'_> {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        let document = self.0;
        let map = document.map();
        let mut value = serializer.serialize_struct("VersionedMapDocument", 8)?;
        value.serialize_field("schemaVersion", &CURRENT_MAP_SCHEMA_VERSION)?;
        value.serialize_field("gridLayout", &map.grid_layout())?;
        value.serialize_field("cols", &map.cols())?;
        value.serialize_field("rows", &map.rows())?;
        value.serialize_field("mapName", map.map_id())?;
        value.serialize_field("defaultZoom", &document.default_zoom())?;
        value.serialize_field("objectives", &Objectives(map.objectives()))?;
        value.serialize_field("tiles", &Tiles(map.tiles()))?;
        value.end()
    }
}

impl Serialize for Tiles<'_> {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        let mut sequence = serializer.serialize_seq(Some(self.0.len()))?;
        for tile in self.0 {
            sequence.serialize_element(&Tile(tile))?;
        }
        sequence.end()
    }
}

impl Serialize for Objectives<'_> {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        let mut sequence = serializer.serialize_seq(Some(self.0.len()))?;
        for objective in self.0 {
            sequence.serialize_element(&CanonicalObjective(objective))?;
        }
        sequence.end()
    }
}

impl Serialize for Tile<'_> {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        let tile = self.0;
        let mut value = serializer.serialize_struct("Tile", 5)?;
        value.serialize_field("col", &tile.coordinate().col())?;
        value.serialize_field("row", &tile.coordinate().row())?;
        value.serialize_field("terrainTags", tile.terrain_tags())?;
        value.serialize_field("resources", tile.resources())?;
        value.serialize_field("height", &tile.height())?;
        value.end()
    }
}

impl Serialize for CanonicalObjective<'_> {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        let objective = self.0;
        let mut value = serializer.serialize_struct("CanonicalObjective", 6)?;
        value.serialize_field("id", objective.id())?;
        value.serialize_field("type", &objective.objective_type())?;
        value.serialize_field(
            "hex",
            &CanonicalCoordinate {
                col: objective.coordinate().col(),
                row: objective.coordinate().row(),
            },
        )?;
        value.serialize_field("requiredHoldTurns", &objective.required_hold_turns())?;
        value.serialize_field("victoryPoints", &objective.victory_points())?;
        value.serialize_field("goldPerTurn", &objective.gold_per_turn())?;
        value.end()
    }
}

#[derive(Serialize)]
struct CanonicalCoordinate {
    col: i32,
    row: i32,
}
