use aonw_content::{MapLoadError, MapValidationError};
use aonw_map_authoring::TerrainAuthoringLoadError;

/// Failure produced while validating or generating workbench documents.
#[derive(Debug)]
pub enum MapWorkbenchError {
    /// A strict JSON document could not be decoded or encoded.
    Json(serde_json::Error),
    /// The requested generator identity is not implemented.
    UnsupportedGenerator {
        /// Stable requested generator identifier.
        generator_id: Box<str>,
        /// Requested behavior version.
        generator_version: u16,
    },
    /// The generation specification violates an authoring invariant.
    InvalidSpec {
        /// Logical document path that failed validation.
        path: Box<str>,
        /// Stable diagnostic description.
        message: Box<str>,
    },
    /// A logical tile edit targets an invalid coordinate or value.
    InvalidEdit {
        /// Logical request path that failed validation.
        path: Box<str>,
        /// Stable diagnostic description.
        message: Box<str>,
    },
    /// An existing logical map document could not be loaded for editing.
    SourceMap(MapLoadError),
    /// Generated logical content failed its canonical domain validation.
    Map(MapValidationError),
    /// Edited logical content failed canonical domain validation.
    EditedMap(MapValidationError),
    /// The generated metric authoring profile is invalid.
    TerrainAuthoring(TerrainAuthoringLoadError),
}

impl MapWorkbenchError {
    pub(crate) fn invalid(path: impl Into<Box<str>>, message: impl Into<Box<str>>) -> Self {
        Self::InvalidSpec {
            path: path.into(),
            message: message.into(),
        }
    }

    pub(crate) fn invalid_edit(path: impl Into<Box<str>>, message: impl Into<Box<str>>) -> Self {
        Self::InvalidEdit {
            path: path.into(),
            message: message.into(),
        }
    }

    /// Stable machine code exposed by the workbench protocol.
    #[must_use]
    pub const fn code(&self) -> &'static str {
        match self {
            Self::Json(_) | Self::InvalidSpec { .. } => "invalid_generation_spec",
            Self::InvalidEdit { .. } | Self::EditedMap(_) => "invalid_map_edit",
            Self::UnsupportedGenerator { .. } => "unsupported_map_generator",
            Self::SourceMap(_) => "source_map_invalid",
            Self::Map(_) => "generated_map_invalid",
            Self::TerrainAuthoring(_) => "generated_terrain_profile_invalid",
        }
    }

    /// Logical path associated with a validation failure when available.
    #[must_use]
    pub fn path(&self) -> Option<&str> {
        match self {
            Self::InvalidSpec { path, .. } | Self::InvalidEdit { path, .. } => Some(path),
            Self::SourceMap(error) => error.path(),
            Self::Map(error) | Self::EditedMap(error) => Some(error.path()),
            Self::TerrainAuthoring(error) => error.path(),
            _ => None,
        }
    }
}

impl core::fmt::Display for MapWorkbenchError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::Json(source) => write!(formatter, "invalid generation JSON: {source}"),
            Self::UnsupportedGenerator {
                generator_id,
                generator_version,
            } => write!(
                formatter,
                "unsupported map generator {generator_id} version {generator_version}"
            ),
            Self::InvalidSpec { path, message } | Self::InvalidEdit { path, message } => {
                write!(formatter, "{path}: {message}")
            }
            Self::SourceMap(source) => write!(formatter, "source map is invalid: {source}"),
            Self::Map(source) => write!(formatter, "generated map is invalid: {source}"),
            Self::EditedMap(source) => write!(formatter, "edited map is invalid: {source}"),
            Self::TerrainAuthoring(source) => {
                write!(formatter, "generated terrain profile is invalid: {source}")
            }
        }
    }
}

impl std::error::Error for MapWorkbenchError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::Json(source) => Some(source),
            Self::SourceMap(source) => Some(source),
            Self::Map(source) | Self::EditedMap(source) => Some(source),
            Self::TerrainAuthoring(source) => Some(source),
            _ => None,
        }
    }
}

impl From<serde_json::Error> for MapWorkbenchError {
    fn from(source: serde_json::Error) -> Self {
        Self::Json(source)
    }
}

impl From<MapValidationError> for MapWorkbenchError {
    fn from(source: MapValidationError) -> Self {
        Self::Map(source)
    }
}

impl From<MapLoadError> for MapWorkbenchError {
    fn from(source: MapLoadError) -> Self {
        Self::SourceMap(source)
    }
}

impl From<TerrainAuthoringLoadError> for MapWorkbenchError {
    fn from(source: TerrainAuthoringLoadError) -> Self {
        Self::TerrainAuthoring(source)
    }
}
