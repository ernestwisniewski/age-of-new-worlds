use core::fmt;

use aonw_content::{
    MAX_MAP_COLS, MAX_MAP_ROWS, MIN_AUTHORED_MAP_COLS, MIN_AUTHORED_MAP_ROWS, validate_map_id,
};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

use crate::MapWorkbenchError;

/// Stable identifier of the first deterministic empty-map generator.
pub const BLANK_GENERATOR_ID: &str = "blank";
/// Current behavior version of the empty-map generator.
pub const BLANK_GENERATOR_VERSION: u16 = 1;
/// Stable identifier of the first procedural landscape generator.
pub const CONTINENTAL_GENERATOR_ID: &str = "continental";
/// Current behavior version of the procedural landscape generator.
pub const CONTINENTAL_GENERATOR_VERSION: u16 = 1;
const MAX_GENERATION_SPEC_BYTES: usize = 64 * 1024;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum Generator {
    Blank,
    Continental,
}

/// SHA-256 identity of one complete generation specification.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct GenerationSpecHash([u8; 32]);

impl fmt::Display for GenerationSpecHash {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        for byte in self.0 {
            write!(formatter, "{byte:02x}")?;
        }
        Ok(())
    }
}

/// Validated deterministic input for creating a logical map package.
#[derive(Clone, Debug, PartialEq)]
pub struct MapGenerationSpec {
    generator: Generator,
    map_id: Box<str>,
    cols: u16,
    rows: u16,
    default_zoom: f64,
    hex_radius_meters: f64,
    max_terrain_height_meters: f64,
    seed: u64,
}

#[allow(missing_docs)]
impl MapGenerationSpec {
    /// Constructs a current `blank` generation specification.
    ///
    /// # Errors
    ///
    /// Returns [`MapWorkbenchError`] when the authored dimensions, identifier,
    /// zoom, or metric scale are outside the canonical limits.
    pub fn try_new(
        map_id: impl Into<Box<str>>,
        cols: u16,
        rows: u16,
        default_zoom: f64,
        hex_radius_meters: f64,
        max_terrain_height_meters: f64,
        seed: u64,
    ) -> Result<Self, MapWorkbenchError> {
        Self::try_new_for_generator(
            Generator::Blank,
            map_id,
            cols,
            rows,
            default_zoom,
            hex_radius_meters,
            max_terrain_height_meters,
            seed,
        )
    }

    /// Constructs a current `continental` generation specification.
    ///
    /// # Errors
    ///
    /// Returns [`MapWorkbenchError`] when any common map or metric input is invalid.
    pub fn try_new_continental(
        map_id: impl Into<Box<str>>,
        cols: u16,
        rows: u16,
        default_zoom: f64,
        hex_radius_meters: f64,
        max_terrain_height_meters: f64,
        seed: u64,
    ) -> Result<Self, MapWorkbenchError> {
        Self::try_new_for_generator(
            Generator::Continental,
            map_id,
            cols,
            rows,
            default_zoom,
            hex_radius_meters,
            max_terrain_height_meters,
            seed,
        )
    }

    #[allow(clippy::too_many_arguments)]
    fn try_new_for_generator(
        generator: Generator,
        map_id: impl Into<Box<str>>,
        cols: u16,
        rows: u16,
        default_zoom: f64,
        hex_radius_meters: f64,
        max_terrain_height_meters: f64,
        seed: u64,
    ) -> Result<Self, MapWorkbenchError> {
        let map_id = map_id.into();
        validate_map_id(&map_id)?;
        if !(MIN_AUTHORED_MAP_COLS..=MAX_MAP_COLS).contains(&cols) {
            return Err(MapWorkbenchError::invalid(
                "$.cols",
                format!("must be in range {MIN_AUTHORED_MAP_COLS}..={MAX_MAP_COLS}"),
            ));
        }
        if !(MIN_AUTHORED_MAP_ROWS..=MAX_MAP_ROWS).contains(&rows) {
            return Err(MapWorkbenchError::invalid(
                "$.rows",
                format!("must be in range {MIN_AUTHORED_MAP_ROWS}..={MAX_MAP_ROWS}"),
            ));
        }
        if !default_zoom.is_finite() || default_zoom <= 0.0 {
            return Err(MapWorkbenchError::invalid(
                "$.defaultZoom",
                "must be finite and positive",
            ));
        }
        if !hex_radius_meters.is_finite() || hex_radius_meters <= 0.0 {
            return Err(MapWorkbenchError::invalid(
                "$.hexRadiusMeters",
                "must be finite and positive",
            ));
        }
        if !max_terrain_height_meters.is_finite() || max_terrain_height_meters <= 0.0 {
            return Err(MapWorkbenchError::invalid(
                "$.maxTerrainHeightMeters",
                "must be finite and positive",
            ));
        }
        Ok(Self {
            generator,
            map_id,
            cols,
            rows,
            default_zoom,
            hex_radius_meters,
            max_terrain_height_meters,
            seed,
        })
    }

    /// Decodes one strict, current generation specification.
    ///
    /// # Errors
    ///
    /// Returns [`MapWorkbenchError`] for malformed, oversized, unsupported, or
    /// invalid input.
    pub fn from_json(source: &[u8]) -> Result<Self, MapWorkbenchError> {
        if source.len() > MAX_GENERATION_SPEC_BYTES {
            return Err(MapWorkbenchError::invalid(
                "$",
                format!("document exceeds {MAX_GENERATION_SPEC_BYTES} bytes"),
            ));
        }
        let raw: RawGenerationSpec = serde_json::from_slice(source)?;
        let generator = match (raw.generator_id.as_ref(), raw.generator_version) {
            (BLANK_GENERATOR_ID, BLANK_GENERATOR_VERSION) => Generator::Blank,
            (CONTINENTAL_GENERATOR_ID, CONTINENTAL_GENERATOR_VERSION) => Generator::Continental,
            _ => {
                return Err(MapWorkbenchError::UnsupportedGenerator {
                    generator_id: raw.generator_id,
                    generator_version: raw.generator_version,
                });
            }
        };
        let seed = raw
            .seed
            .parse::<u64>()
            .map_err(|_| MapWorkbenchError::invalid("$.seed", "must be a decimal u64 string"))?;
        Self::try_new_for_generator(
            generator,
            raw.map_id,
            raw.cols,
            raw.rows,
            raw.default_zoom,
            raw.hex_radius_meters,
            raw.max_terrain_height_meters,
            seed,
        )
    }

    #[must_use]
    pub fn map_id(&self) -> &str {
        &self.map_id
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
    pub const fn default_zoom(&self) -> f64 {
        self.default_zoom
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
    pub const fn seed(&self) -> u64 {
        self.seed
    }

    #[must_use]
    pub const fn generator_id(&self) -> &'static str {
        match self.generator {
            Generator::Blank => BLANK_GENERATOR_ID,
            Generator::Continental => CONTINENTAL_GENERATOR_ID,
        }
    }

    #[must_use]
    pub const fn generator_version(&self) -> u16 {
        match self.generator {
            Generator::Blank => BLANK_GENERATOR_VERSION,
            Generator::Continental => CONTINENTAL_GENERATOR_VERSION,
        }
    }

    /// Computes the identity of every generation input, including the seed.
    ///
    /// # Errors
    ///
    /// Returns an error only if canonical JSON serialization fails.
    pub fn spec_hash(&self) -> Result<GenerationSpecHash, serde_json::Error> {
        Ok(GenerationSpecHash(
            Sha256::digest(self.canonical_bytes()?).into(),
        ))
    }

    /// Returns the compact deterministic bytes used for specification identity.
    ///
    /// # Errors
    ///
    /// Returns an error only if JSON serialization fails.
    pub fn canonical_bytes(&self) -> Result<Vec<u8>, serde_json::Error> {
        serde_json::to_vec(&PersistedGenerationSpec::from(self))
    }

    /// Serializes a readable strict specification document.
    ///
    /// # Errors
    ///
    /// Returns an error only if JSON serialization fails.
    pub fn to_json(&self) -> Result<String, serde_json::Error> {
        pretty_json(&PersistedGenerationSpec::from(self))
    }
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct RawGenerationSpec {
    generator_id: Box<str>,
    generator_version: u16,
    map_id: Box<str>,
    cols: u16,
    rows: u16,
    default_zoom: f64,
    hex_radius_meters: f64,
    max_terrain_height_meters: f64,
    seed: Box<str>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub(crate) struct PersistedGenerationSpec<'a> {
    generator_id: &'a str,
    generator_version: u16,
    map_id: &'a str,
    cols: u16,
    rows: u16,
    default_zoom: f64,
    hex_radius_meters: f64,
    max_terrain_height_meters: f64,
    seed: String,
}

impl<'a> From<&'a MapGenerationSpec> for PersistedGenerationSpec<'a> {
    fn from(spec: &'a MapGenerationSpec) -> Self {
        Self {
            generator_id: spec.generator_id(),
            generator_version: spec.generator_version(),
            map_id: spec.map_id(),
            cols: spec.cols(),
            rows: spec.rows(),
            default_zoom: spec.default_zoom(),
            hex_radius_meters: spec.hex_radius_meters(),
            max_terrain_height_meters: spec.max_terrain_height_meters(),
            seed: spec.seed().to_string(),
        }
    }
}

pub(crate) fn pretty_json(value: &impl Serialize) -> Result<String, serde_json::Error> {
    let mut output = serde_json::to_string_pretty(value)?;
    output.push('\n');
    Ok(output)
}
