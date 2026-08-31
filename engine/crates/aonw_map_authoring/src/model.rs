use std::fmt;

use aonw_content::{ContentHash, GridLayout, MapDefinition};
use aonw_domain::HexCoord;

use crate::TerrainAuthoringLoadError;

/// SHA-256 identity of a canonical terrain-authoring profile.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct AuthoringProfileHash(pub(crate) [u8; 32]);

impl AuthoringProfileHash {
    /// Returns the raw SHA-256 bytes.
    #[must_use]
    pub const fn as_bytes(&self) -> &[u8; 32] {
        &self.0
    }
}

impl fmt::Display for AuthoringProfileHash {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        for byte in self.0 {
            write!(formatter, "{byte:02x}")?;
        }
        Ok(())
    }
}

/// Three explicit authoring axes. Units are defined by the containing field.
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct AuthoringVector3 {
    x: f64,
    y: f64,
    z: f64,
}

#[allow(missing_docs)]
impl AuthoringVector3 {
    #[must_use]
    pub const fn x(self) -> f64 {
        self.x
    }

    #[must_use]
    pub const fn y(self) -> f64 {
        self.y
    }

    #[must_use]
    pub const fn z(self) -> f64 {
        self.z
    }

    pub(crate) const fn new(x: f64, y: f64, z: f64) -> Self {
        Self { x, y, z }
    }

    fn validate_finite(self, path: &str) -> Result<(), TerrainAuthoringLoadError> {
        for (axis, value) in [("x", self.x), ("y", self.y), ("z", self.z)] {
            validate_finite(&format!("{path}.{axis}"), value)?;
        }
        Ok(())
    }
}

/// Transform aligning source reference artwork with the authored world.
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct ReferenceTransform {
    translation_meters: AuthoringVector3,
    rotation_degrees: AuthoringVector3,
    scale: AuthoringVector3,
}

#[allow(missing_docs)]
impl ReferenceTransform {
    #[must_use]
    pub const fn translation_meters(self) -> AuthoringVector3 {
        self.translation_meters
    }

    #[must_use]
    pub const fn rotation_degrees(self) -> AuthoringVector3 {
        self.rotation_degrees
    }

    #[must_use]
    pub const fn scale(self) -> AuthoringVector3 {
        self.scale
    }

    pub(crate) const fn new(
        translation_meters: AuthoringVector3,
        rotation_degrees: AuthoringVector3,
        scale: AuthoringVector3,
    ) -> Self {
        Self {
            translation_meters,
            rotation_degrees,
            scale,
        }
    }

    fn validate(self) -> Result<(), TerrainAuthoringLoadError> {
        self.translation_meters
            .validate_finite("$.referenceTransform.translationMeters")?;
        self.rotation_degrees
            .validate_finite("$.referenceTransform.rotationDegrees")?;
        self.scale.validate_finite("$.referenceTransform.scale")?;
        for (axis, value) in [
            ("x", self.scale.x),
            ("y", self.scale.y),
            ("z", self.scale.z),
        ] {
            if value <= 0.0 {
                return Err(TerrainAuthoringLoadError::invalid(
                    format!("$.referenceTransform.scale.{axis}"),
                    "must be positive",
                ));
            }
        }
        Ok(())
    }
}

/// Base and allowed metric height envelope for one logical hex.
///
/// A manually sculpted final height is intentionally not stored here. It is a
/// separate derived artifact that must remain within this envelope.
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct TerrainHeightEnvelope {
    coordinate: HexCoord,
    base_height_meters: f64,
    min_height_meters: f64,
    max_height_meters: f64,
}

#[allow(missing_docs)]
impl TerrainHeightEnvelope {
    #[must_use]
    pub const fn coordinate(self) -> HexCoord {
        self.coordinate
    }

    #[must_use]
    pub const fn base_height_meters(self) -> f64 {
        self.base_height_meters
    }

    #[must_use]
    pub const fn min_height_meters(self) -> f64 {
        self.min_height_meters
    }

    #[must_use]
    pub const fn max_height_meters(self) -> f64 {
        self.max_height_meters
    }

    /// Tests a final sculpted height against this independent envelope.
    #[must_use]
    pub fn contains_final_height(self, final_height_meters: f64) -> bool {
        final_height_meters.is_finite()
            && (self.min_height_meters..=self.max_height_meters).contains(&final_height_meters)
    }

    pub(crate) fn try_new(
        path: &str,
        coordinate: HexCoord,
        base_height_meters: f64,
        min_height_meters: f64,
        max_height_meters: f64,
    ) -> Result<Self, TerrainAuthoringLoadError> {
        validate_finite(&format!("{path}.baseHeightMeters"), base_height_meters)?;
        validate_finite(&format!("{path}.minHeightMeters"), min_height_meters)?;
        validate_finite(&format!("{path}.maxHeightMeters"), max_height_meters)?;
        if min_height_meters > base_height_meters {
            return Err(TerrainAuthoringLoadError::invalid(
                path,
                "must satisfy minHeightMeters <= baseHeightMeters",
            ));
        }
        if base_height_meters > max_height_meters {
            return Err(TerrainAuthoringLoadError::invalid(
                path,
                "must satisfy baseHeightMeters <= maxHeightMeters",
            ));
        }
        Ok(Self {
            coordinate,
            base_height_meters,
            min_height_meters,
            max_height_meters,
        })
    }
}

/// Validated metric authoring profile bound to one exact logical map.
#[derive(Clone, Debug, PartialEq)]
pub struct TerrainAuthoringProfile {
    source_map_content_hash: ContentHash,
    orientation: GridLayout,
    cols: u16,
    rows: u16,
    hex_radius_meters: f64,
    max_terrain_height_meters: f64,
    world_origin_meters: AuthoringVector3,
    reference_transform: ReferenceTransform,
    edge_blend_meters: f64,
    city_core_radius_meters: Option<f64>,
    max_city_slope: Option<f64>,
    hex_heights: Box<[TerrainHeightEnvelope]>,
}

#[allow(missing_docs)]
impl TerrainAuthoringProfile {
    /// Builds the standard metric profile used for a newly authored logical map.
    ///
    /// Logical height remains in the gameplay range `0..=5`. The metric base
    /// maps that range to the map-specific maximum terrain height, while the
    /// sculpting envelope remains separate presentation-authoring data.
    ///
    /// # Errors
    ///
    /// Returns [`TerrainAuthoringLoadError`] when the map cannot be hashed or
    /// the metric scale is invalid.
    pub fn standard(
        map: &MapDefinition,
        hex_radius_meters: f64,
        max_terrain_height_meters: f64,
    ) -> Result<Self, TerrainAuthoringLoadError> {
        validate_positive("$.maxTerrainHeightMeters", max_terrain_height_meters)?;
        let source_map_content_hash = map
            .content_hash()
            .map_err(TerrainAuthoringLoadError::MapHash)?;
        let hex_heights = standard_height_envelopes(map, max_terrain_height_meters)?;
        Self::try_new(
            map,
            source_map_content_hash,
            ProfileComponents {
                hex_radius_meters,
                max_terrain_height_meters,
                world_origin_meters: AuthoringVector3::new(0.0, 0.0, 0.0),
                reference_transform: ReferenceTransform::new(
                    AuthoringVector3::new(0.0, hex_radius_meters * 0.005, 0.0),
                    AuthoringVector3::new(0.0, 0.0, 0.0),
                    AuthoringVector3::new(1.0, 1.0, 1.0),
                ),
                edge_blend_meters: hex_radius_meters * 0.2,
                city_core_radius_meters: Some(hex_radius_meters * 0.4),
                max_city_slope: Some(0.35),
                hex_heights,
            },
        )
    }

    /// Returns the same spatial authoring profile with its logical `0..=5`
    /// height scale rebuilt for a new map-specific metric maximum.
    ///
    /// Reference alignment, world origin, sampling scale, edge blending, and
    /// city metadata are preserved. Height envelopes remain derived from the
    /// authoritative logical map instead of being rescaled by a client.
    ///
    /// # Errors
    ///
    /// Returns [`TerrainAuthoringLoadError`] when the maximum is invalid or
    /// this profile does not belong to the supplied logical map.
    pub fn with_max_terrain_height_meters(
        &self,
        map: &MapDefinition,
        max_terrain_height_meters: f64,
    ) -> Result<Self, TerrainAuthoringLoadError> {
        validate_positive("$.maxTerrainHeightMeters", max_terrain_height_meters)?;
        let source_map_content_hash = map
            .content_hash()
            .map_err(TerrainAuthoringLoadError::MapHash)?;
        Self::try_new(
            map,
            source_map_content_hash,
            ProfileComponents {
                hex_radius_meters: self.hex_radius_meters,
                max_terrain_height_meters,
                world_origin_meters: self.world_origin_meters,
                reference_transform: self.reference_transform,
                edge_blend_meters: self.edge_blend_meters,
                city_core_radius_meters: self.city_core_radius_meters,
                max_city_slope: self.max_city_slope,
                hex_heights: standard_height_envelopes(map, max_terrain_height_meters)?,
            },
        )
    }

    #[must_use]
    pub const fn source_map_content_hash(&self) -> ContentHash {
        self.source_map_content_hash
    }

    #[must_use]
    pub const fn orientation(&self) -> GridLayout {
        self.orientation
    }

    #[must_use]
    pub const fn cols(&self) -> u16 {
        self.cols
    }

    #[must_use]
    pub const fn rows(&self) -> u16 {
        self.rows
    }

    #[must_use]
    pub const fn hex_radius_meters(&self) -> f64 {
        self.hex_radius_meters
    }

    #[must_use]
    pub const fn max_terrain_height_meters(&self) -> f64 {
        self.max_terrain_height_meters
    }

    #[must_use]
    pub const fn world_origin_meters(&self) -> AuthoringVector3 {
        self.world_origin_meters
    }

    #[must_use]
    pub const fn reference_transform(&self) -> ReferenceTransform {
        self.reference_transform
    }

    #[must_use]
    pub const fn edge_blend_meters(&self) -> f64 {
        self.edge_blend_meters
    }

    #[must_use]
    pub const fn city_core_radius_meters(&self) -> Option<f64> {
        self.city_core_radius_meters
    }

    #[must_use]
    pub const fn max_city_slope(&self) -> Option<f64> {
        self.max_city_slope
    }

    #[must_use]
    pub fn hex_heights(&self) -> &[TerrainHeightEnvelope] {
        &self.hex_heights
    }

    pub(crate) fn try_new(
        map: &MapDefinition,
        source_map_content_hash: ContentHash,
        raw: ProfileComponents,
    ) -> Result<Self, TerrainAuthoringLoadError> {
        validate_positive("$.hexRadiusMeters", raw.hex_radius_meters)?;
        validate_positive("$.maxTerrainHeightMeters", raw.max_terrain_height_meters)?;
        raw.world_origin_meters
            .validate_finite("$.worldOriginMeters")?;
        raw.reference_transform.validate()?;
        validate_non_negative("$.edgeBlendMeters", raw.edge_blend_meters)?;
        if raw.edge_blend_meters > raw.hex_radius_meters {
            return Err(TerrainAuthoringLoadError::invalid(
                "$.edgeBlendMeters",
                "must not exceed hexRadiusMeters",
            ));
        }
        if let Some(value) = raw.city_core_radius_meters {
            validate_positive("$.cityCoreRadiusMeters", value)?;
            if value > raw.hex_radius_meters {
                return Err(TerrainAuthoringLoadError::invalid(
                    "$.cityCoreRadiusMeters",
                    "must not exceed hexRadiusMeters",
                ));
            }
        }
        if let Some(value) = raw.max_city_slope {
            validate_non_negative("$.maxCitySlope", value)?;
        }

        let mut hex_heights = raw.hex_heights;
        hex_heights
            .sort_unstable_by_key(|height| (height.coordinate.row(), height.coordinate.col()));
        if hex_heights.len() != map.tiles().len() {
            return Err(TerrainAuthoringLoadError::invalid(
                "$.hexHeights",
                format!(
                    "must contain exactly one entry for every map hex; expected {}, found {}",
                    map.tiles().len(),
                    hex_heights.len()
                ),
            ));
        }
        for (height, tile) in hex_heights.iter().zip(map.tiles()) {
            if height.coordinate != tile.coordinate() {
                return Err(TerrainAuthoringLoadError::invalid(
                    "$.hexHeights",
                    format!(
                        "coverage is incomplete or duplicated; expected ({}, {})",
                        tile.coordinate().col(),
                        tile.coordinate().row()
                    ),
                ));
            }
        }
        for (index, height) in hex_heights.iter().enumerate() {
            if height.max_height_meters > raw.max_terrain_height_meters {
                return Err(TerrainAuthoringLoadError::invalid(
                    format!("$.hexHeights[{index}].maxHeightMeters"),
                    "must not exceed maxTerrainHeightMeters",
                ));
            }
        }

        Ok(Self {
            source_map_content_hash,
            orientation: map.grid_layout(),
            cols: map.cols(),
            rows: map.rows(),
            hex_radius_meters: raw.hex_radius_meters,
            max_terrain_height_meters: raw.max_terrain_height_meters,
            world_origin_meters: raw.world_origin_meters,
            reference_transform: raw.reference_transform,
            edge_blend_meters: raw.edge_blend_meters,
            city_core_radius_meters: raw.city_core_radius_meters,
            max_city_slope: raw.max_city_slope,
            hex_heights: hex_heights.into_boxed_slice(),
        })
    }
}

fn standard_height_envelopes(
    map: &MapDefinition,
    max_terrain_height_meters: f64,
) -> Result<Vec<TerrainHeightEnvelope>, TerrainAuthoringLoadError> {
    let height_step = max_terrain_height_meters / 5.0;
    let lower_margin = height_step * 0.5;
    let upper_margin = height_step;
    map.tiles()
        .iter()
        .enumerate()
        .map(|(index, tile)| {
            let base = f64::from(tile.height()) * height_step;
            TerrainHeightEnvelope::try_new(
                &format!("$.hexHeights[{index}]"),
                tile.coordinate(),
                base,
                base - lower_margin,
                (base + upper_margin).min(max_terrain_height_meters),
            )
        })
        .collect()
}

pub(crate) struct ProfileComponents {
    pub(crate) hex_radius_meters: f64,
    pub(crate) max_terrain_height_meters: f64,
    pub(crate) world_origin_meters: AuthoringVector3,
    pub(crate) reference_transform: ReferenceTransform,
    pub(crate) edge_blend_meters: f64,
    pub(crate) city_core_radius_meters: Option<f64>,
    pub(crate) max_city_slope: Option<f64>,
    pub(crate) hex_heights: Vec<TerrainHeightEnvelope>,
}

fn validate_finite(path: &str, value: f64) -> Result<(), TerrainAuthoringLoadError> {
    if value.is_finite() {
        return Ok(());
    }
    Err(TerrainAuthoringLoadError::invalid(path, "must be finite"))
}

fn validate_positive(path: &str, value: f64) -> Result<(), TerrainAuthoringLoadError> {
    validate_finite(path, value)?;
    if value > 0.0 {
        return Ok(());
    }
    Err(TerrainAuthoringLoadError::invalid(path, "must be positive"))
}

fn validate_non_negative(path: &str, value: f64) -> Result<(), TerrainAuthoringLoadError> {
    validate_finite(path, value)?;
    if value >= 0.0 {
        return Ok(());
    }
    Err(TerrainAuthoringLoadError::invalid(
        path,
        "must be non-negative",
    ))
}
