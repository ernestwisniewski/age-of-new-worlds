use crate::MapDefinition;
use crate::validation::MapValidationError;

/// Minimum width of a persistable authored map document.
pub const MIN_AUTHORED_MAP_COLS: u16 = 5;
/// Minimum height of a persistable authored map document.
pub const MIN_AUTHORED_MAP_ROWS: u16 = 5;

#[allow(missing_docs)]
#[derive(Clone, Debug, PartialEq)]
pub struct MapDocument {
    map: MapDefinition,
    default_zoom: f64,
}

#[allow(missing_docs)]
impl MapDocument {
    /// Constructs an editable document around a validated logical map.
    ///
    /// # Errors
    ///
    /// Returns [`MapValidationError`] when the camera zoom is not finite and positive.
    pub fn try_new(map: MapDefinition, default_zoom: f64) -> Result<Self, MapValidationError> {
        if map.cols() < MIN_AUTHORED_MAP_COLS {
            return Err(MapValidationError::new(
                "$.cols",
                format!("must be at least {MIN_AUTHORED_MAP_COLS} for an authored map document"),
            ));
        }
        if map.rows() < MIN_AUTHORED_MAP_ROWS {
            return Err(MapValidationError::new(
                "$.rows",
                format!("must be at least {MIN_AUTHORED_MAP_ROWS} for an authored map document"),
            ));
        }
        if !default_zoom.is_finite() || default_zoom <= 0.0 {
            return Err(MapValidationError::new(
                "$.defaultZoom",
                "must be finite and positive",
            ));
        }
        Ok(Self { map, default_zoom })
    }

    #[must_use]
    pub const fn map(&self) -> &MapDefinition {
        &self.map
    }

    #[must_use]
    pub const fn default_zoom(&self) -> f64 {
        self.default_zoom
    }
}
