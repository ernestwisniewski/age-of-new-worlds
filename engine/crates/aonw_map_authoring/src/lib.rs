//! Versioned terrain-authoring profiles for logical `AoNW` maps.
//!
//! This crate converts logical hex heights into explicit metric authoring
//! envelopes without changing game content or its canonical hash. It owns no
//! rasterization, filesystem, Godot, or gameplay behavior.

#![forbid(unsafe_code)]

mod canonical;
mod codec;
mod error;
mod model;

pub use error::TerrainAuthoringLoadError;
pub use model::{
    AuthoringProfileHash, AuthoringVector3, ReferenceTransform, TerrainAuthoringProfile,
    TerrainHeightEnvelope,
};

/// Terrain-authoring document version emitted by the canonical serializer.
pub const CURRENT_TERRAIN_AUTHORING_SCHEMA_VERSION: u64 = 1;
