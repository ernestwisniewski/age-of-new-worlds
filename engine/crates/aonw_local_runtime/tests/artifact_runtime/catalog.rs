use aonw_domain::{ArtifactId, HexCoord, WorldArtifact, WorldArtifactLocation, WorldArtifactType};

pub(super) fn artifact_catalog() -> [WorldArtifact; 7] {
    [
        artifact("crown", WorldArtifactType::AncientImperialCrown),
        artifact("tablets", WorldArtifactType::AstronomersTablets),
        artifact("mask", WorldArtifactType::ProphetMask),
        artifact("seal", WorldArtifactType::MerchantsSeal),
        artifact("chronicle", WorldArtifactType::FirstPeoplesChronicle),
        artifact("reliquary", WorldArtifactType::TempleReliquary),
        artifact("mirror", WorldArtifactType::QueensMirror),
    ]
}

fn artifact(id: &str, artifact_type: WorldArtifactType) -> WorldArtifact {
    WorldArtifact::new(
        ArtifactId::new(id).expect("artifact id"),
        artifact_type,
        WorldArtifactLocation::Map(HexCoord::new(3, 0)),
    )
}
