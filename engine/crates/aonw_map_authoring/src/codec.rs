use aonw_content::{GridLayout, MapDefinition};
use aonw_domain::HexCoord;
use serde::de::Error as _;
use serde::{Deserialize, Deserializer};

use crate::model::ProfileComponents;
use crate::{
    AuthoringVector3, CURRENT_TERRAIN_AUTHORING_SCHEMA_VERSION, ReferenceTransform,
    TerrainAuthoringLoadError, TerrainAuthoringProfile, TerrainHeightEnvelope,
};

const MAX_TERRAIN_AUTHORING_DOCUMENT_BYTES: usize = 8 * 1024 * 1024;

#[derive(Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct RawProfile {
    #[serde(deserialize_with = "deserialize_u64")]
    schema_version: u64,
    source_map_content_hash: Box<str>,
    orientation: Box<str>,
    hex_radius_meters: f64,
    max_terrain_height_meters: f64,
    world_origin_meters: RawVector3,
    reference_transform: RawReferenceTransform,
    edge_blend_meters: f64,
    city_core_radius_meters: Option<f64>,
    max_city_slope: Option<f64>,
    hex_heights: Vec<RawHeightEnvelope>,
}

#[derive(Clone, Copy, Deserialize)]
#[serde(deny_unknown_fields)]
struct RawVector3 {
    x: f64,
    y: f64,
    z: f64,
}

impl From<RawVector3> for AuthoringVector3 {
    fn from(value: RawVector3) -> Self {
        Self::new(value.x, value.y, value.z)
    }
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct RawReferenceTransform {
    translation_meters: RawVector3,
    rotation_degrees: RawVector3,
    scale: RawVector3,
}

#[derive(Clone, Copy, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct RawHeightEnvelope {
    #[serde(deserialize_with = "deserialize_i64")]
    col: i64,
    #[serde(deserialize_with = "deserialize_i64")]
    row: i64,
    base_height_meters: f64,
    min_height_meters: f64,
    max_height_meters: f64,
}

impl TerrainAuthoringProfile {
    /// Decodes a strict profile and binds it to the exact supplied logical map.
    ///
    /// # Errors
    ///
    /// Returns [`TerrainAuthoringLoadError`] for malformed, incomplete,
    /// unsupported, stale, or invalid input.
    pub fn from_json(
        source: &[u8],
        map: &MapDefinition,
    ) -> Result<Self, TerrainAuthoringLoadError> {
        check_size(source)?;
        build_profile(serde_json::from_slice(source)?, map)
    }
}

const fn check_size(source: &[u8]) -> Result<(), TerrainAuthoringLoadError> {
    if source.len() <= MAX_TERRAIN_AUTHORING_DOCUMENT_BYTES {
        return Ok(());
    }
    Err(TerrainAuthoringLoadError::DocumentTooLarge {
        actual: source.len(),
        limit: MAX_TERRAIN_AUTHORING_DOCUMENT_BYTES,
    })
}

fn build_profile(
    raw: RawProfile,
    map: &MapDefinition,
) -> Result<TerrainAuthoringProfile, TerrainAuthoringLoadError> {
    if raw.schema_version != CURRENT_TERRAIN_AUTHORING_SCHEMA_VERSION {
        return Err(TerrainAuthoringLoadError::UnsupportedSchemaVersion {
            found: raw.schema_version,
            supported: CURRENT_TERRAIN_AUTHORING_SCHEMA_VERSION,
        });
    }
    if raw.orientation.as_ref() != GridLayout::OddQFlatTop.as_str() {
        return Err(TerrainAuthoringLoadError::invalid(
            "$.orientation",
            "must be oddQFlatTop",
        ));
    }
    let map_hash = map
        .content_hash()
        .map_err(TerrainAuthoringLoadError::MapHash)?;
    if raw.source_map_content_hash.as_ref() != map_hash.to_string() {
        return Err(TerrainAuthoringLoadError::invalid(
            "$.sourceMapContentHash",
            "does not match the current logical map content hash",
        ));
    }

    let hex_heights = raw
        .hex_heights
        .into_iter()
        .enumerate()
        .map(|(index, height)| build_height(height, index))
        .collect::<Result<Vec<_>, _>>()?;
    TerrainAuthoringProfile::try_new(
        map,
        map_hash,
        ProfileComponents {
            hex_radius_meters: raw.hex_radius_meters,
            max_terrain_height_meters: raw.max_terrain_height_meters,
            world_origin_meters: raw.world_origin_meters.into(),
            reference_transform: ReferenceTransform::new(
                raw.reference_transform.translation_meters.into(),
                raw.reference_transform.rotation_degrees.into(),
                raw.reference_transform.scale.into(),
            ),
            edge_blend_meters: raw.edge_blend_meters,
            city_core_radius_meters: raw.city_core_radius_meters,
            max_city_slope: raw.max_city_slope,
            hex_heights,
        },
    )
}

fn build_height(
    raw: RawHeightEnvelope,
    index: usize,
) -> Result<TerrainHeightEnvelope, TerrainAuthoringLoadError> {
    let path = format!("$.hexHeights[{index}]");
    TerrainHeightEnvelope::try_new(
        &path,
        HexCoord::new(
            i32_value(&format!("{path}.col"), raw.col)?,
            i32_value(&format!("{path}.row"), raw.row)?,
        ),
        raw.base_height_meters,
        raw.min_height_meters,
        raw.max_height_meters,
    )
}

fn i32_value(path: &str, value: i64) -> Result<i32, TerrainAuthoringLoadError> {
    i32::try_from(value).map_err(|_| TerrainAuthoringLoadError::invalid(path, "must fit i32"))
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
