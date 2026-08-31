use std::fmt;

use aonw_content::ContentHash;
use aonw_map_authoring::AuthoringProfileHash;

use crate::TerrainCompileError;

pub(crate) const MIN_SAMPLES_PER_HEX: u16 = 1;
pub(crate) const MAX_SAMPLES_PER_HEX: u16 = 64;

/// Bounded raster density expressed relative to the profile's hex radius.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct RasterConfig {
    samples_per_hex: u16,
}

impl RasterConfig {
    /// Creates a bounded deterministic raster configuration.
    ///
    /// # Errors
    ///
    /// Returns [`TerrainCompileError`] when the density is outside 1..=64.
    pub const fn try_new(samples_per_hex: u16) -> Result<Self, TerrainCompileError> {
        if samples_per_hex < MIN_SAMPLES_PER_HEX || samples_per_hex > MAX_SAMPLES_PER_HEX {
            return Err(TerrainCompileError::InvalidSamplesPerHex {
                found: samples_per_hex,
                minimum: MIN_SAMPLES_PER_HEX,
                maximum: MAX_SAMPLES_PER_HEX,
            });
        }
        Ok(Self { samples_per_hex })
    }

    /// Returns the number of samples per authoring hex radius.
    #[must_use]
    pub const fn samples_per_hex(self) -> u16 {
        self.samples_per_hex
    }
}

/// SHA-256 identity of one typed height raster and its metric transform.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct RasterHash(pub(crate) [u8; 32]);

impl RasterHash {
    /// Returns the raw SHA-256 bytes.
    #[must_use]
    pub const fn as_bytes(&self) -> &[u8; 32] {
        &self.0
    }
}

impl fmt::Display for RasterHash {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        for byte in self.0 {
            write!(formatter, "{byte:02x}")?;
        }
        Ok(())
    }
}

/// One row-major f32 height raster in world meters.
#[derive(Clone, Debug, PartialEq)]
pub struct HeightRaster {
    width: u32,
    height: u32,
    world_min_x_meters: f64,
    world_min_z_meters: f64,
    sample_spacing_meters: f64,
    values: Box<[f32]>,
}

#[allow(missing_docs)]
impl HeightRaster {
    #[must_use]
    pub const fn width(&self) -> u32 {
        self.width
    }

    #[must_use]
    pub const fn height(&self) -> u32 {
        self.height
    }

    #[must_use]
    pub const fn world_min_x_meters(&self) -> f64 {
        self.world_min_x_meters
    }

    #[must_use]
    pub const fn world_min_z_meters(&self) -> f64 {
        self.world_min_z_meters
    }

    #[must_use]
    pub const fn sample_spacing_meters(&self) -> f64 {
        self.sample_spacing_meters
    }

    #[must_use]
    pub fn values(&self) -> &[f32] {
        &self.values
    }

    #[must_use]
    pub fn value_at(&self, x: u32, y: u32) -> Option<f32> {
        let index = self.index_of(x, y)?;
        self.values.get(index).copied()
    }

    pub(crate) fn new(
        width: usize,
        height: usize,
        min_world_x: f64,
        min_world_z: f64,
        sample_spacing_meters: f64,
        values: Vec<f32>,
    ) -> Self {
        Self {
            width: u32::try_from(width).expect("bounded raster width fits u32"),
            height: u32::try_from(height).expect("bounded raster height fits u32"),
            world_min_x_meters: min_world_x,
            world_min_z_meters: min_world_z,
            sample_spacing_meters,
            values: values.into_boxed_slice(),
        }
    }

    pub(crate) fn index_of(&self, x: u32, y: u32) -> Option<usize> {
        if x >= self.width || y >= self.height {
            return None;
        }
        Some(
            usize::try_from(y).expect("u32 fits usize")
                * usize::try_from(self.width).expect("u32 fits usize")
                + usize::try_from(x).expect("u32 fits usize"),
        )
    }
}

/// Stable identities carried by one compiled base and its constraints.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct CompiledTerrainMetadata {
    map_content: ContentHash,
    authoring_profile: AuthoringProfileHash,
    rasters: RasterHashes,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
struct RasterHashes {
    base: RasterHash,
    min: RasterHash,
    max: RasterHash,
}

#[allow(missing_docs)]
impl CompiledTerrainMetadata {
    #[must_use]
    pub const fn generator_version(&self) -> &'static str {
        crate::TERRAIN_GENERATOR_VERSION
    }

    #[must_use]
    pub const fn map_content_hash(self) -> ContentHash {
        self.map_content
    }

    #[must_use]
    pub const fn authoring_profile_hash(self) -> AuthoringProfileHash {
        self.authoring_profile
    }

    #[must_use]
    pub const fn base_raster_hash(self) -> RasterHash {
        self.rasters.base
    }

    #[must_use]
    pub const fn min_raster_hash(self) -> RasterHash {
        self.rasters.min
    }

    #[must_use]
    pub const fn max_raster_hash(self) -> RasterHash {
        self.rasters.max
    }

    pub(crate) const fn new(
        map_content_hash: ContentHash,
        authoring_profile_hash: AuthoringProfileHash,
        base_raster_hash: RasterHash,
        min_raster_hash: RasterHash,
        max_raster_hash: RasterHash,
    ) -> Self {
        Self {
            map_content: map_content_hash,
            authoring_profile: authoring_profile_hash,
            rasters: RasterHashes {
                base: base_raster_hash,
                min: min_raster_hash,
                max: max_raster_hash,
            },
        }
    }
}

/// Deterministic generated base plus independent lower and upper constraints.
#[derive(Clone, Debug, PartialEq)]
pub struct CompiledTerrain {
    metadata: CompiledTerrainMetadata,
    base: HeightRaster,
    min: HeightRaster,
    max: HeightRaster,
}

#[allow(missing_docs)]
impl CompiledTerrain {
    #[must_use]
    pub const fn metadata(&self) -> CompiledTerrainMetadata {
        self.metadata
    }

    #[must_use]
    pub const fn base(&self) -> &HeightRaster {
        &self.base
    }

    #[must_use]
    pub const fn min(&self) -> &HeightRaster {
        &self.min
    }

    #[must_use]
    pub const fn max(&self) -> &HeightRaster {
        &self.max
    }

    pub(crate) const fn new(
        metadata: CompiledTerrainMetadata,
        base: HeightRaster,
        min: HeightRaster,
        max: HeightRaster,
    ) -> Self {
        Self {
            metadata,
            base,
            min,
            max,
        }
    }
}

/// Rectangular row-major section of caller-owned final terrain.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct RasterRegion {
    x: u32,
    y: u32,
    width: u32,
    height: u32,
}

#[allow(missing_docs)]
impl RasterRegion {
    #[must_use]
    pub const fn new(x: u32, y: u32, width: u32, height: u32) -> Self {
        Self {
            x,
            y,
            width,
            height,
        }
    }

    #[must_use]
    pub const fn x(self) -> u32 {
        self.x
    }

    #[must_use]
    pub const fn y(self) -> u32 {
        self.y
    }

    #[must_use]
    pub const fn width(self) -> u32 {
        self.width
    }

    #[must_use]
    pub const fn height(self) -> u32 {
        self.height
    }
}

/// Result of explicitly clamping a caller-provided final terrain region.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ClampReport {
    changed_samples: usize,
}

impl ClampReport {
    /// Returns how many manual samples were constrained.
    #[must_use]
    pub const fn changed_samples(self) -> usize {
        self.changed_samples
    }

    pub(crate) const fn new(changed_samples: usize) -> Self {
        Self { changed_samples }
    }
}
