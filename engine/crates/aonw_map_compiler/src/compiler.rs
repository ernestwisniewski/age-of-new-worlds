use aonw_map_authoring::{TerrainAuthoringProfile, TerrainHeightEnvelope};
use sha2::{Digest, Sha256};

use crate::model::{CompiledTerrainMetadata, HeightRaster, RasterHash};
use crate::{CompiledTerrain, RasterConfig, TERRAIN_GENERATOR_VERSION, TerrainCompileError};

const SQRT_3: f64 = 1.732_050_807_568_877_2;
const MAX_RASTER_SAMPLES: usize = 16 * 1024 * 1024;
const CANDIDATE_RADIUS: i32 = 2;

/// Compiles one validated authoring profile into deterministic base/min/max rasters.
///
/// # Errors
///
/// Returns [`TerrainCompileError`] when the requested raster exceeds the
/// bounded sample budget, profile metrics cannot be represented as finite f32
/// terrain data, or the authoring-profile hash cannot be computed.
pub fn compile_terrain(
    profile: &TerrainAuthoringProfile,
    config: RasterConfig,
) -> Result<CompiledTerrain, TerrainCompileError> {
    let dimensions = ProfileDimensions::from_profile(profile);
    validate_metrics(profile)?;
    let geometry = RasterGeometry::new(profile, config, dimensions)?;
    let sample_count = geometry
        .width
        .checked_mul(geometry.height)
        .filter(|count| *count <= MAX_RASTER_SAMPLES)
        .ok_or(TerrainCompileError::RasterTooLarge {
            width: geometry.width,
            height: geometry.height,
            limit: MAX_RASTER_SAMPLES,
        })?;

    let mut base_values = Vec::with_capacity(sample_count);
    let mut min_values = Vec::with_capacity(sample_count);
    let mut max_values = Vec::with_capacity(sample_count);
    for y in 0..geometry.height {
        let local_z = geometry.local_min_z + usize_as_f64(y) * geometry.sample_spacing;
        for x in 0..geometry.width {
            let local_x = geometry.local_min_x + usize_as_f64(x) * geometry.sample_spacing;
            let sample = blend_sample(profile, dimensions, local_x, local_z);
            let world_min = f64_to_f32(sample.min + geometry.world_origin_y);
            let world_max = f64_to_f32(sample.max + geometry.world_origin_y);
            let world_base =
                f64_to_f32(sample.base + geometry.world_origin_y).clamp(world_min, world_max);
            min_values.push(world_min);
            base_values.push(world_base);
            max_values.push(world_max);
        }
    }

    let base = HeightRaster::new(
        geometry.width,
        geometry.height,
        geometry.world_min_x,
        geometry.world_min_z,
        geometry.sample_spacing,
        base_values,
    );
    let min = HeightRaster::new(
        geometry.width,
        geometry.height,
        geometry.world_min_x,
        geometry.world_min_z,
        geometry.sample_spacing,
        min_values,
    );
    let max = HeightRaster::new(
        geometry.width,
        geometry.height,
        geometry.world_min_x,
        geometry.world_min_z,
        geometry.sample_spacing,
        max_values,
    );
    let metadata = CompiledTerrainMetadata::new(
        profile.source_map_content_hash(),
        profile
            .authoring_profile_hash()
            .map_err(TerrainCompileError::AuthoringProfileHash)?,
        hash_raster(b"base", &base),
        hash_raster(b"min", &min),
        hash_raster(b"max", &max),
    );
    Ok(CompiledTerrain::new(metadata, base, min, max))
}

#[derive(Clone, Copy)]
struct ProfileDimensions {
    cols: usize,
    rows: usize,
}

impl ProfileDimensions {
    fn from_profile(profile: &TerrainAuthoringProfile) -> Self {
        Self {
            cols: usize::from(profile.cols()),
            rows: usize::from(profile.rows()),
        }
    }
}

struct RasterGeometry {
    width: usize,
    height: usize,
    local_min_x: f64,
    local_min_z: f64,
    world_min_x: f64,
    world_min_z: f64,
    world_origin_y: f64,
    sample_spacing: f64,
}

impl RasterGeometry {
    fn new(
        profile: &TerrainAuthoringProfile,
        config: RasterConfig,
        dimensions: ProfileDimensions,
    ) -> Result<Self, TerrainCompileError> {
        let radius = profile.hex_radius_meters();
        let half_hex_height = SQRT_3 * radius / 2.0;
        let last_col = usize_as_f64(dimensions.cols - 1);
        let last_row = usize_as_f64(dimensions.rows - 1);
        let odd_column_offset = if dimensions.cols > 1 { 0.5 } else { 0.0 };
        let local_min_x = -radius;
        let local_max_x = 1.5 * radius * last_col + radius;
        let local_min_z = -half_hex_height;
        let local_max_z = SQRT_3 * radius * (last_row + odd_column_offset) + half_hex_height;
        let sample_spacing = radius / f64::from(config.samples_per_hex());
        let width = raster_dimension(local_max_x - local_min_x, sample_spacing);
        let height = raster_dimension(local_max_z - local_min_z, sample_spacing);
        if width
            .checked_mul(height)
            .is_none_or(|count| count > MAX_RASTER_SAMPLES)
        {
            return Err(TerrainCompileError::RasterTooLarge {
                width,
                height,
                limit: MAX_RASTER_SAMPLES,
            });
        }
        let origin = profile.world_origin_meters();
        let world_min_x = origin.x() + local_min_x;
        let world_min_z = origin.z() + local_min_z;
        let world_max_x = origin.x() + local_max_x;
        let world_max_z = origin.z() + local_max_z;
        validate_f32("$.worldOriginMeters.x + rasterMinX", world_min_x)?;
        validate_f32("$.worldOriginMeters.z + rasterMinZ", world_min_z)?;
        validate_f32("$.worldOriginMeters.x + rasterMaxX", world_max_x)?;
        validate_f32("$.worldOriginMeters.z + rasterMaxZ", world_max_z)?;
        validate_f32("$.sampleSpacingMeters", sample_spacing)?;
        Ok(Self {
            width,
            height,
            local_min_x,
            local_min_z,
            world_min_x,
            world_min_z,
            world_origin_y: origin.y(),
            sample_spacing,
        })
    }
}

#[derive(Clone, Copy)]
struct HeightSample {
    base: f64,
    min: f64,
    max: f64,
}

fn blend_sample(
    profile: &TerrainAuthoringProfile,
    dimensions: ProfileDimensions,
    local_x: f64,
    local_z: f64,
) -> HeightSample {
    // The closest-center Voronoi boundary is the logical hex edge. Candidates
    // whose distance advantage is within edgeBlendMeters receive the same
    // smoothstep weight for base, min, and max, preserving their ordering.
    let radius = profile.hex_radius_meters();
    let approximate_col = rounded_i32(local_x / (1.5 * radius));
    let approximate_row =
        rounded_i32(local_z / (SQRT_3 * radius) - f64::from(approximate_col & 1) / 2.0);
    let center_col = approximate_col.clamp(0, usize_as_i32(dimensions.cols - 1));
    let center_row = approximate_row.clamp(0, usize_as_i32(dimensions.rows - 1));
    let min_col = (center_col - CANDIDATE_RADIUS).max(0);
    let max_col = (center_col + CANDIDATE_RADIUS).min(usize_as_i32(dimensions.cols - 1));
    let min_row = (center_row - CANDIDATE_RADIUS).max(0);
    let max_row = (center_row + CANDIDATE_RADIUS).min(usize_as_i32(dimensions.rows - 1));

    let mut candidates = [(0_usize, 0.0_f64); 25];
    let mut candidate_count = 0;
    let mut nearest_index = 0;
    let mut nearest_distance_squared = f64::INFINITY;
    for row in min_row..=max_row {
        for col in min_col..=max_col {
            let index = usize::try_from(row).expect("bounded row fits usize") * dimensions.cols
                + usize::try_from(col).expect("bounded column fits usize");
            let (center_x, center_z) = hex_center(col, row, radius);
            let distance_squared = (local_x - center_x).mul_add(
                local_x - center_x,
                (local_z - center_z) * (local_z - center_z),
            );
            candidates[candidate_count] = (index, distance_squared.sqrt());
            candidate_count += 1;
            if distance_squared < nearest_distance_squared {
                nearest_distance_squared = distance_squared;
                nearest_index = index;
            }
        }
    }

    if profile.edge_blend_meters() == 0.0 {
        return height_sample(profile.hex_heights()[nearest_index]);
    }

    let nearest_distance = nearest_distance_squared.sqrt();
    let mut total_weight = 0.0;
    let mut blended = HeightSample {
        base: 0.0,
        min: 0.0,
        max: 0.0,
    };
    for (index, distance) in candidates.into_iter().take(candidate_count) {
        let normalized =
            (1.0 - (distance - nearest_distance) / profile.edge_blend_meters()).clamp(0.0, 1.0);
        let weight = normalized * normalized * (3.0 - 2.0 * normalized);
        if weight == 0.0 {
            continue;
        }
        let source = height_sample(profile.hex_heights()[index]);
        blended.base = source.base.mul_add(weight, blended.base);
        blended.min = source.min.mul_add(weight, blended.min);
        blended.max = source.max.mul_add(weight, blended.max);
        total_weight += weight;
    }
    HeightSample {
        base: blended.base / total_weight,
        min: blended.min / total_weight,
        max: blended.max / total_weight,
    }
}

fn height_sample(height: TerrainHeightEnvelope) -> HeightSample {
    HeightSample {
        base: height.base_height_meters(),
        min: height.min_height_meters(),
        max: height.max_height_meters(),
    }
}

fn hex_center(col: i32, row: i32, radius: f64) -> (f64, f64) {
    (
        1.5 * radius * f64::from(col),
        SQRT_3 * radius * (f64::from(row) + f64::from(col & 1) / 2.0),
    )
}

fn validate_metrics(profile: &TerrainAuthoringProfile) -> Result<(), TerrainCompileError> {
    let origin = profile.world_origin_meters();
    for (path, value) in [
        ("$.hexRadiusMeters", profile.hex_radius_meters()),
        ("$.edgeBlendMeters", profile.edge_blend_meters()),
        ("$.worldOriginMeters.x", origin.x()),
        ("$.worldOriginMeters.y", origin.y()),
        ("$.worldOriginMeters.z", origin.z()),
    ] {
        validate_f32(path, value)?;
    }
    for (index, height) in profile.hex_heights().iter().enumerate() {
        for (field, value) in [
            ("baseHeightMeters", height.base_height_meters()),
            ("minHeightMeters", height.min_height_meters()),
            ("maxHeightMeters", height.max_height_meters()),
        ] {
            validate_f32(
                &format!("$.hexHeights[{index}].{field} + $.worldOriginMeters.y"),
                value + origin.y(),
            )?;
        }
    }
    Ok(())
}

fn validate_f32(path: &str, value: f64) -> Result<(), TerrainCompileError> {
    if value.is_finite() && (f64::from(f32::MIN)..=f64::from(f32::MAX)).contains(&value) {
        return Ok(());
    }
    Err(TerrainCompileError::MetricOutsideF32 {
        path: path.into(),
        value,
    })
}

fn raster_dimension(span: f64, spacing: f64) -> usize {
    let intervals = (span / spacing).ceil();
    #[expect(
        clippy::cast_possible_truncation,
        clippy::cast_sign_loss,
        reason = "validated positive map dimensions and density are far below usize bounds"
    )]
    let intervals = intervals as usize;
    intervals + 1
}

#[expect(
    clippy::cast_possible_truncation,
    reason = "raster samples stay within the validated map's small coordinate neighborhood"
)]
fn rounded_i32(value: f64) -> i32 {
    value.round() as i32
}

fn usize_as_i32(value: usize) -> i32 {
    i32::try_from(value).expect("validated map dimensions fit i32")
}

#[expect(
    clippy::cast_precision_loss,
    reason = "bounded raster dimensions are exactly representable as f64"
)]
fn usize_as_f64(value: usize) -> f64 {
    value as f64
}

#[expect(
    clippy::cast_possible_truncation,
    reason = "all source metrics are validated against the finite f32 range"
)]
fn f64_to_f32(value: f64) -> f32 {
    value as f32
}

fn hash_raster(layer: &[u8], raster: &HeightRaster) -> RasterHash {
    let mut digest = Sha256::new();
    digest.update(TERRAIN_GENERATOR_VERSION.as_bytes());
    digest.update([0]);
    digest.update(layer);
    digest.update(raster.width().to_le_bytes());
    digest.update(raster.height().to_le_bytes());
    digest.update(raster.world_min_x_meters().to_bits().to_le_bytes());
    digest.update(raster.world_min_z_meters().to_bits().to_le_bytes());
    digest.update(raster.sample_spacing_meters().to_bits().to_le_bytes());
    for value in raster.values() {
        digest.update(value.to_bits().to_le_bytes());
    }
    RasterHash(digest.finalize().into())
}
