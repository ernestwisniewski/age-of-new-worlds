//! Logical map authoring and deterministic generation for the Godot workbench.
//!
//! The crate owns framework-neutral authoring use cases. It produces exact
//! canonical documents but performs no filesystem or Godot operations.

#![forbid(unsafe_code)]

mod error;
mod generation;
mod map_edit;
mod protocol;
mod spec;
mod terrain_profile;

pub use error::MapWorkbenchError;
pub use generation::GeneratedMapPackage;
pub use map_edit::{LogicalMapTileEditorSnapshot, UpdatedLogicalMap};
pub use protocol::{MAP_WORKBENCH_API_VERSION, MapWorkbenchProtocol};
pub use spec::{
    BLANK_GENERATOR_ID, BLANK_GENERATOR_VERSION, CONTINENTAL_GENERATOR_ID,
    CONTINENTAL_GENERATOR_VERSION, GenerationSpecHash, MapGenerationSpec,
};
pub use terrain_profile::UpdatedTerrainProfile;
