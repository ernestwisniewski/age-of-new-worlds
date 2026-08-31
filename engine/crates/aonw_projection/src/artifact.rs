use aonw_domain::{
    ArtifactId, CityId, FogVisibility, GameState, HexCoord, PlayerId, UnitId, WorldArtifact,
    WorldArtifactLocation, WorldArtifactType,
};

/// Recipient-safe current artifact read model.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerArtifactView {
    id: ArtifactId,
    artifact_type: WorldArtifactType,
    location: PlayerArtifactLocationView,
}

impl PlayerArtifactView {
    fn from_artifact(artifact: &WorldArtifact) -> Self {
        let location = match artifact.location() {
            WorldArtifactLocation::Map(coordinate) => PlayerArtifactLocationView::Map(*coordinate),
            WorldArtifactLocation::Carried(unit_id) => {
                PlayerArtifactLocationView::Carried(unit_id.clone())
            }
            WorldArtifactLocation::Stored(city_id) => {
                PlayerArtifactLocationView::Stored(city_id.clone())
            }
            WorldArtifactLocation::Excavation {
                unit_id,
                coordinate,
                remaining_turns,
            } => PlayerArtifactLocationView::Excavation {
                unit_id: unit_id.clone(),
                coordinate: *coordinate,
                remaining_turns: *remaining_turns,
            },
        };
        Self {
            id: artifact.id().clone(),
            artifact_type: artifact.artifact_type(),
            location,
        }
    }

    /// Returns the artifact identity.
    #[must_use]
    pub const fn id(&self) -> &ArtifactId {
        &self.id
    }

    /// Returns the stable artifact category.
    #[must_use]
    pub const fn artifact_type(&self) -> WorldArtifactType {
        self.artifact_type
    }

    /// Returns the visible current location.
    #[must_use]
    pub const fn location(&self) -> &PlayerArtifactLocationView {
        &self.location
    }
}

/// Recipient-safe current artifact location.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum PlayerArtifactLocationView {
    /// Visible map coordinate.
    Map(HexCoord),
    /// Owned or visible carrier.
    Carried(UnitId),
    /// Owned or visible storage city.
    Stored(CityId),
    /// Owned or visible active excavation.
    Excavation {
        /// Excavating unit.
        unit_id: UnitId,
        /// Excavation coordinate.
        coordinate: HexCoord,
        /// Turns remaining.
        remaining_turns: u32,
    },
}

pub(crate) fn visible_artifacts(state: &GameState, actor: &PlayerId) -> Vec<PlayerArtifactView> {
    state
        .artifacts()
        .iter()
        .filter(|artifact| can_see(state, actor, artifact.location()))
        .map(PlayerArtifactView::from_artifact)
        .collect()
}

fn can_see(state: &GameState, actor: &PlayerId, location: &WorldArtifactLocation) -> bool {
    match location {
        WorldArtifactLocation::Map(coordinate)
        | WorldArtifactLocation::Excavation { coordinate, .. } => {
            state.fog_of_war().visibility(actor, *coordinate) == FogVisibility::Visible
        }
        WorldArtifactLocation::Carried(unit_id) => state.unit(unit_id).is_some_and(|unit| {
            unit.owner_player_id() == actor
                || state.fog_of_war().visibility(actor, unit.position()) == FogVisibility::Visible
        }),
        WorldArtifactLocation::Stored(city_id) => state.city(city_id).is_some_and(|city| {
            city.owner_player_id() == actor
                || state.fog_of_war().visibility(actor, city.center()) == FogVisibility::Visible
        }),
    }
}
