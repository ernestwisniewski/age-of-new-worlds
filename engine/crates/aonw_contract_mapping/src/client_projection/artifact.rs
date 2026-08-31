use aonw_contracts::WorldArtifactTypeDto;
use aonw_contracts::client::{PlayerArtifactLocationViewDto, PlayerArtifactViewDto};
use aonw_domain::WorldArtifactType;

use aonw_projection::{PlayerArtifactLocationView, PlayerArtifactView};

use super::coordinate;

pub(super) fn artifact(value: &PlayerArtifactView) -> PlayerArtifactViewDto {
    PlayerArtifactViewDto {
        id: value.id().as_str().to_owned(),
        artifact_type: artifact_type(value.artifact_type()),
        location: match value.location() {
            PlayerArtifactLocationView::Map(value) => PlayerArtifactLocationViewDto::Map {
                coordinate: coordinate(*value),
            },
            PlayerArtifactLocationView::Carried(value) => PlayerArtifactLocationViewDto::Carried {
                unit_id: value.as_str().to_owned(),
            },
            PlayerArtifactLocationView::Stored(value) => PlayerArtifactLocationViewDto::Stored {
                city_id: value.as_str().to_owned(),
            },
            PlayerArtifactLocationView::Excavation {
                unit_id,
                coordinate: value,
                remaining_turns,
            } => PlayerArtifactLocationViewDto::Excavation {
                unit_id: unit_id.as_str().to_owned(),
                coordinate: coordinate(*value),
                remaining_turns: *remaining_turns,
            },
        },
    }
}

const fn artifact_type(value: WorldArtifactType) -> WorldArtifactTypeDto {
    match value {
        WorldArtifactType::AncientImperialCrown => WorldArtifactTypeDto::AncientImperialCrown,
        WorldArtifactType::AstronomersTablets => WorldArtifactTypeDto::AstronomersTablets,
        WorldArtifactType::ProphetMask => WorldArtifactTypeDto::ProphetMask,
        WorldArtifactType::HeroSword => WorldArtifactTypeDto::HeroSword,
        WorldArtifactType::MerchantsSeal => WorldArtifactTypeDto::MerchantsSeal,
        WorldArtifactType::FirstPeoplesChronicle => WorldArtifactTypeDto::FirstPeoplesChronicle,
        WorldArtifactType::TempleReliquary => WorldArtifactTypeDto::TempleReliquary,
        WorldArtifactType::QueensMirror => WorldArtifactTypeDto::QueensMirror,
    }
}
