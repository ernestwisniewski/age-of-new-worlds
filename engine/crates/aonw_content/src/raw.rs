use serde::de::Error as _;
use serde::{Deserialize, Deserializer};

use crate::CURRENT_MAP_SCHEMA_VERSION;

#[derive(Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub(super) struct RawMapDocument {
    #[serde(deserialize_with = "deserialize_u64")]
    pub(super) schema_version: u64,
    pub(super) grid_layout: Box<str>,
    #[serde(deserialize_with = "deserialize_i64")]
    pub(super) cols: i64,
    #[serde(deserialize_with = "deserialize_i64")]
    pub(super) rows: i64,
    pub(super) map_name: Box<str>,
    pub(super) default_zoom: f64,
    pub(super) objectives: Vec<RawObjective>,
    pub(super) tiles: Vec<RawTile>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub(super) struct RawCanonicalMap {
    #[serde(deserialize_with = "deserialize_u64")]
    pub(super) schema_version: u64,
    pub(super) grid_layout: Box<str>,
    #[serde(deserialize_with = "deserialize_i64")]
    pub(super) cols: i64,
    #[serde(deserialize_with = "deserialize_i64")]
    pub(super) rows: i64,
    pub(super) map_name: Box<str>,
    pub(super) objectives: Vec<RawObjective>,
    pub(super) tiles: Vec<RawTile>,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub(super) struct RawTile {
    #[serde(deserialize_with = "deserialize_i64")]
    pub(super) col: i64,
    #[serde(deserialize_with = "deserialize_i64")]
    pub(super) row: i64,
    #[serde(rename = "terrainTags")]
    pub(super) terrain_tags: Vec<Box<str>>,
    pub(super) resources: Vec<Box<str>>,
    #[serde(deserialize_with = "deserialize_i64")]
    pub(super) height: i64,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub(super) struct RawObjective {
    pub(super) id: Box<str>,
    #[serde(rename = "type")]
    pub(super) objective_type: Box<str>,
    pub(super) hex: RawCoordinate,
    #[serde(deserialize_with = "deserialize_i64")]
    pub(super) required_hold_turns: i64,
    #[serde(deserialize_with = "deserialize_i64")]
    pub(super) victory_points: i64,
    #[serde(deserialize_with = "deserialize_i64")]
    pub(super) gold_per_turn: i64,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub(super) struct RawCoordinate {
    #[serde(deserialize_with = "deserialize_i64")]
    pub(super) col: i64,
    #[serde(deserialize_with = "deserialize_i64")]
    pub(super) row: i64,
}

fn deserialize_i64<'de, D: Deserializer<'de>>(deserializer: D) -> Result<i64, D::Error> {
    const MAX_EXACT_INTEGER: f64 = 9_007_199_254_740_991.0;
    let number = serde_json::Number::deserialize(deserializer)?;
    if let Some(value) = number.as_i64() {
        return Ok(value);
    }
    if let Some(value) = number.as_u64() {
        return i64::try_from(value).map_err(D::Error::custom);
    }
    let value = number
        .as_f64()
        .ok_or_else(|| D::Error::custom("number must be representable as f64"))?;
    if !value.is_finite() || value.fract() != 0.0 || value.abs() > MAX_EXACT_INTEGER {
        return Err(D::Error::custom(
            "number must be a finite, exactly represented integer",
        ));
    }
    #[expect(
        clippy::cast_possible_truncation,
        reason = "the finite integral value is bounded to the exact f64 integer range"
    )]
    Ok(value as i64)
}

fn deserialize_u64<'de, D: Deserializer<'de>>(deserializer: D) -> Result<u64, D::Error> {
    let value = deserialize_i64(deserializer)?;
    u64::try_from(value).map_err(D::Error::custom)
}

pub(super) struct RawMap {
    pub(super) cols: i64,
    pub(super) rows: i64,
    pub(super) map_name: Box<str>,
    pub(super) default_zoom: f64,
    pub(super) objectives: Vec<RawObjective>,
    pub(super) tiles: Vec<RawTile>,
}

impl TryFrom<RawMapDocument> for RawMap {
    type Error = crate::MapLoadError;

    fn try_from(raw: RawMapDocument) -> Result<Self, Self::Error> {
        validate_header(raw.schema_version, &raw.grid_layout)?;
        Ok(Self {
            cols: raw.cols,
            rows: raw.rows,
            map_name: raw.map_name,
            default_zoom: raw.default_zoom,
            objectives: raw.objectives,
            tiles: raw.tiles,
        })
    }
}

impl TryFrom<RawCanonicalMap> for RawMap {
    type Error = crate::MapLoadError;

    fn try_from(raw: RawCanonicalMap) -> Result<Self, Self::Error> {
        validate_header(raw.schema_version, &raw.grid_layout)?;
        Ok(Self {
            cols: raw.cols,
            rows: raw.rows,
            map_name: raw.map_name,
            default_zoom: 1.0,
            objectives: raw.objectives,
            tiles: raw.tiles,
        })
    }
}

fn validate_header(schema_version: u64, grid_layout: &str) -> Result<(), crate::MapLoadError> {
    if schema_version != CURRENT_MAP_SCHEMA_VERSION {
        return Err(crate::MapLoadError::UnsupportedSchemaVersion {
            found: schema_version,
            supported: CURRENT_MAP_SCHEMA_VERSION,
        });
    }
    if grid_layout != "oddQFlatTop" {
        return Err(crate::MapLoadError::invalid(
            "$.gridLayout",
            "must be oddQFlatTop",
        ));
    }
    Ok(())
}
