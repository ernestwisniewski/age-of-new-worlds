//! Pure deterministic compilation of terrain-authoring profiles.
//!
//! The library owns geometry, blending, constraint rasters, hashes, and
//! explicit clamping of caller-owned final terrain. It performs no filesystem,
//! image-format, Godot, or gameplay work.

#![forbid(unsafe_code)]

mod clamp;
mod compiler;
mod error;
mod model;

pub use compiler::compile_terrain;
pub use error::{TerrainClampError, TerrainCompileError};
pub use model::{
    ClampReport, CompiledTerrain, CompiledTerrainMetadata, HeightRaster, RasterConfig, RasterHash,
    RasterRegion,
};

/// Version of the deterministic raster generator and hash contract.
pub const TERRAIN_GENERATOR_VERSION: &str = "aonw-map-compiler/1";
