use serde::{Deserialize, Serialize};

use crate::{CoordinateDto, WorldArtifactTypeDto};

/// Recipient-safe artifact read model.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerArtifactViewDto {
    /// Stable artifact identity.
    pub id: String,
    /// Stable artifact category.
    #[serde(rename = "type")]
    pub artifact_type: WorldArtifactTypeDto,
    /// Visible current location.
    pub location: PlayerArtifactLocationViewDto,
}

/// Recipient-safe current artifact location.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "kind",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum PlayerArtifactLocationViewDto {
    Map {
        coordinate: CoordinateDto,
    },
    Carried {
        unit_id: String,
    },
    Stored {
        city_id: String,
    },
    Excavation {
        unit_id: String,
        coordinate: CoordinateDto,
        remaining_turns: u32,
    },
}
