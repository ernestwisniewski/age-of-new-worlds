use serde::{Deserialize, Serialize};

use super::CoordinateDto;

#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct WorldArtifactDto {
    pub id: String,
    #[serde(rename = "type")]
    pub artifact_type: WorldArtifactTypeDto,
    pub location: WorldArtifactLocationDto,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum WorldArtifactTypeDto {
    AncientImperialCrown,
    AstronomersTablets,
    ProphetMask,
    HeroSword,
    MerchantsSeal,
    FirstPeoplesChronicle,
    TempleReliquary,
    QueensMirror,
}

#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "kind",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum WorldArtifactLocationDto {
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
