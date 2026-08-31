use std::fmt;

/// Failure raised while decoding or validating a terrain-authoring profile.
#[allow(missing_docs)]
#[derive(Debug)]
pub enum TerrainAuthoringLoadError {
    DocumentTooLarge { actual: usize, limit: usize },
    Json(serde_json::Error),
    MapHash(serde_json::Error),
    UnsupportedSchemaVersion { found: u64, supported: u64 },
    Invalid { path: Box<str>, message: Box<str> },
}

impl TerrainAuthoringLoadError {
    pub(crate) fn invalid(path: impl Into<Box<str>>, message: impl Into<Box<str>>) -> Self {
        Self::Invalid {
            path: path.into(),
            message: message.into(),
        }
    }

    /// Returns the failing logical path for validation errors.
    #[must_use]
    pub fn path(&self) -> Option<&str> {
        match self {
            Self::Invalid { path, .. } => Some(path),
            _ => None,
        }
    }
}

impl fmt::Display for TerrainAuthoringLoadError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::DocumentTooLarge { actual, limit } => write!(
                formatter,
                "terrain-authoring document has {actual} bytes; limit is {limit}"
            ),
            Self::Json(source) => write!(formatter, "invalid terrain-authoring JSON: {source}"),
            Self::MapHash(source) => write!(formatter, "cannot hash the logical map: {source}"),
            Self::UnsupportedSchemaVersion { found, supported } => write!(
                formatter,
                "unsupported terrain-authoring schema version {found}; supported version is {supported}"
            ),
            Self::Invalid { path, message } => write!(formatter, "{path}: {message}"),
        }
    }
}

impl std::error::Error for TerrainAuthoringLoadError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::Json(source) | Self::MapHash(source) => Some(source),
            _ => None,
        }
    }
}

impl From<serde_json::Error> for TerrainAuthoringLoadError {
    fn from(source: serde_json::Error) -> Self {
        Self::Json(source)
    }
}
