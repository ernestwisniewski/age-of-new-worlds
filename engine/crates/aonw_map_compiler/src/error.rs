use std::fmt;

/// Failure raised before or during deterministic terrain compilation.
#[derive(Debug)]
pub enum TerrainCompileError {
    /// Raster density must be within the supported bounded range.
    InvalidSamplesPerHex {
        /// Rejected density.
        found: u16,
        /// Smallest supported density.
        minimum: u16,
        /// Largest supported density.
        maximum: u16,
    },
    /// The requested raster exceeds the compiler's bounded sample budget.
    RasterTooLarge {
        /// Computed sample width.
        width: usize,
        /// Computed sample height.
        height: usize,
        /// Maximum supported total sample count.
        limit: usize,
    },
    /// A metric authoring value cannot be represented by `Terrain3D`'s f32 data.
    MetricOutsideF32 {
        /// Logical profile path or derived output path.
        path: Box<str>,
        /// Rejected metric value.
        value: f64,
    },
    /// The validated authoring profile could not produce its canonical hash.
    AuthoringProfileHash(serde_json::Error),
}

impl fmt::Display for TerrainCompileError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::InvalidSamplesPerHex {
                found,
                minimum,
                maximum,
            } => write!(
                formatter,
                "samples per hex must be between {minimum} and {maximum}; found {found}"
            ),
            Self::RasterTooLarge {
                width,
                height,
                limit,
            } => write!(
                formatter,
                "terrain raster {width}x{height} exceeds the {limit}-sample limit"
            ),
            Self::MetricOutsideF32 { path, value } => {
                write!(
                    formatter,
                    "{path} value {value} is outside the finite f32 range"
                )
            }
            Self::AuthoringProfileHash(source) => {
                write!(
                    formatter,
                    "cannot hash the terrain-authoring profile: {source}"
                )
            }
        }
    }
}

impl std::error::Error for TerrainCompileError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::AuthoringProfileHash(source) => Some(source),
            _ => None,
        }
    }
}

/// Failure raised while clamping caller-owned final terrain.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum TerrainClampError {
    /// The final raster must match the compiled constraint dimensions.
    LengthMismatch {
        /// Required row-major sample count.
        expected: usize,
        /// Provided sample count.
        found: usize,
    },
    /// The requested region must be non-empty and contained by the raster.
    InvalidRegion,
    /// Non-finite manual input is rejected before any sample is changed.
    NonFiniteFinalHeight {
        /// Row-major index of the rejected sample.
        index: usize,
    },
}

impl fmt::Display for TerrainClampError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::LengthMismatch { expected, found } => write!(
                formatter,
                "final terrain has {found} samples; expected {expected}"
            ),
            Self::InvalidRegion => formatter.write_str("clamp region is outside the raster"),
            Self::NonFiniteFinalHeight { index } => {
                write!(formatter, "final terrain sample {index} must be finite")
            }
        }
    }
}

impl std::error::Error for TerrainClampError {}
