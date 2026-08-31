use serde::ser::{SerializeSeq, SerializeStruct};
use serde::{Serialize, Serializer};
use sha2::{Digest, Sha256};

use crate::{
    AuthoringProfileHash, AuthoringVector3, CURRENT_TERRAIN_AUTHORING_SCHEMA_VERSION,
    ReferenceTransform, TerrainAuthoringProfile, TerrainHeightEnvelope,
};

struct CanonicalProfile<'a>(&'a TerrainAuthoringProfile);
struct CanonicalVector3(AuthoringVector3);
struct CanonicalReferenceTransform(ReferenceTransform);
struct CanonicalHeights<'a>(&'a [TerrainHeightEnvelope]);
struct CanonicalHeight(TerrainHeightEnvelope);

impl TerrainAuthoringProfile {
    /// Returns the exact compact bytes used for authoring-profile identity.
    ///
    /// # Errors
    ///
    /// Returns an error if canonical JSON serialization cannot complete.
    pub fn canonical_bytes(&self) -> Result<Vec<u8>, serde_json::Error> {
        serde_json::to_vec(&CanonicalProfile(self))
    }

    /// Computes a SHA-256 identity independent from the logical map hash.
    ///
    /// # Errors
    ///
    /// Returns an error if canonical JSON serialization cannot complete.
    pub fn authoring_profile_hash(&self) -> Result<AuthoringProfileHash, serde_json::Error> {
        let digest = Sha256::digest(self.canonical_bytes()?);
        Ok(AuthoringProfileHash(digest.into()))
    }

    /// Serializes the complete deterministic profile for editing or persistence.
    ///
    /// # Errors
    ///
    /// Returns an error if JSON serialization cannot complete.
    pub fn to_versioned_json(&self) -> Result<String, serde_json::Error> {
        let mut output = serde_json::to_string_pretty(&CanonicalProfile(self))?;
        output.push('\n');
        Ok(output)
    }
}

impl Serialize for CanonicalProfile<'_> {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        let profile = self.0;
        let mut value = serializer.serialize_struct("TerrainAuthoringProfile", 11)?;
        value.serialize_field("schemaVersion", &CURRENT_TERRAIN_AUTHORING_SCHEMA_VERSION)?;
        value.serialize_field(
            "sourceMapContentHash",
            &profile.source_map_content_hash().to_string(),
        )?;
        value.serialize_field("orientation", &profile.orientation())?;
        value.serialize_field("hexRadiusMeters", &profile.hex_radius_meters())?;
        value.serialize_field(
            "maxTerrainHeightMeters",
            &profile.max_terrain_height_meters(),
        )?;
        value.serialize_field(
            "worldOriginMeters",
            &CanonicalVector3(profile.world_origin_meters()),
        )?;
        value.serialize_field(
            "referenceTransform",
            &CanonicalReferenceTransform(profile.reference_transform()),
        )?;
        value.serialize_field("edgeBlendMeters", &profile.edge_blend_meters())?;
        if let Some(city_core_radius_meters) = profile.city_core_radius_meters() {
            value.serialize_field("cityCoreRadiusMeters", &city_core_radius_meters)?;
        }
        if let Some(max_city_slope) = profile.max_city_slope() {
            value.serialize_field("maxCitySlope", &max_city_slope)?;
        }
        value.serialize_field("hexHeights", &CanonicalHeights(profile.hex_heights()))?;
        value.end()
    }
}

impl Serialize for CanonicalVector3 {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        let mut value = serializer.serialize_struct("AuthoringVector3", 3)?;
        value.serialize_field("x", &self.0.x())?;
        value.serialize_field("y", &self.0.y())?;
        value.serialize_field("z", &self.0.z())?;
        value.end()
    }
}

impl Serialize for CanonicalReferenceTransform {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        let mut value = serializer.serialize_struct("ReferenceTransform", 3)?;
        value.serialize_field(
            "translationMeters",
            &CanonicalVector3(self.0.translation_meters()),
        )?;
        value.serialize_field(
            "rotationDegrees",
            &CanonicalVector3(self.0.rotation_degrees()),
        )?;
        value.serialize_field("scale", &CanonicalVector3(self.0.scale()))?;
        value.end()
    }
}

impl Serialize for CanonicalHeights<'_> {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        let mut sequence = serializer.serialize_seq(Some(self.0.len()))?;
        for height in self.0 {
            sequence.serialize_element(&CanonicalHeight(*height))?;
        }
        sequence.end()
    }
}

impl Serialize for CanonicalHeight {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        let height = self.0;
        let mut value = serializer.serialize_struct("TerrainHeightEnvelope", 5)?;
        value.serialize_field("col", &height.coordinate().col())?;
        value.serialize_field("row", &height.coordinate().row())?;
        value.serialize_field("baseHeightMeters", &height.base_height_meters())?;
        value.serialize_field("minHeightMeters", &height.min_height_meters())?;
        value.serialize_field("maxHeightMeters", &height.max_height_meters())?;
        value.end()
    }
}
