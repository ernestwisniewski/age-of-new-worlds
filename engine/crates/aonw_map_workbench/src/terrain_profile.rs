use aonw_content::MapDocument;
use aonw_map_authoring::TerrainAuthoringProfile;
use serde::Serialize;

use crate::MapWorkbenchError;

/// Canonical result of changing one map's metric terrain-height scale.
#[derive(Clone, Debug, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct UpdatedTerrainProfile {
    terrain_authoring_document: String,
    authoring_profile_hash: String,
    max_terrain_height_meters: f64,
}

impl UpdatedTerrainProfile {
    /// Rebuilds height envelopes in Rust while preserving the profile's other
    /// spatial authoring settings.
    ///
    /// # Errors
    ///
    /// Returns [`MapWorkbenchError`] if either input document is invalid, does
    /// not describe the same logical map, or the requested maximum is invalid.
    pub fn reconfigure(
        map_document: &str,
        terrain_authoring_document: &str,
        max_terrain_height_meters: f64,
    ) -> Result<Self, MapWorkbenchError> {
        let map_document = MapDocument::from_json(map_document.as_bytes())?;
        let current = TerrainAuthoringProfile::from_json(
            terrain_authoring_document.as_bytes(),
            map_document.map(),
        )?;
        let updated = current
            .with_max_terrain_height_meters(map_document.map(), max_terrain_height_meters)?;
        Ok(Self {
            terrain_authoring_document: updated.to_versioned_json()?,
            authoring_profile_hash: updated.authoring_profile_hash()?.to_string(),
            max_terrain_height_meters: updated.max_terrain_height_meters(),
        })
    }

    /// Canonical replacement for `terrain_authoring.json`.
    #[must_use]
    pub fn terrain_authoring_document(&self) -> &str {
        &self.terrain_authoring_document
    }

    /// SHA-256 identity of the replacement authoring profile.
    #[must_use]
    pub fn authoring_profile_hash(&self) -> &str {
        &self.authoring_profile_hash
    }

    /// Validated map-specific metric ceiling stored by the replacement.
    #[must_use]
    pub const fn max_terrain_height_meters(&self) -> f64 {
        self.max_terrain_height_meters
    }
}
