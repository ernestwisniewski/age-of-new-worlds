use aonw_contracts::{ReplayCommandDto, ReplayRecordDto};
use aonw_domain::{ArtifactId, CityId, PlayerId, UnitId};
use aonw_engine::{
    PlayerCommand, StartArtifactExcavationCommand, StoreArtifactInCityCommand, TradeArtifactCommand,
};

use super::{CommandResult, dispatch_player};
use crate::RuntimeError;
use crate::session::Session;

/// Current revision-bound artifact command.
#[derive(Clone, Debug, Eq, Hash, PartialEq)]
pub enum ArtifactCommandRequest {
    /// Starts excavation at the controlled unit's coordinate.
    StartExcavation {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Controlled excavating unit.
        unit_id: UnitId,
    },
    /// Stores the artifact carried by a controlled unit.
    StoreInCity {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Controlled carrier.
        unit_id: UnitId,
        /// Explicit owned city, or the city below the carrier.
        city_id: Option<CityId>,
    },
    /// Transfers one stored artifact and optional gold to another player.
    Trade {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Recipient player.
        target_player_id: PlayerId,
        /// Offered stored artifact.
        offered_artifact_id: ArtifactId,
        /// Optional offered gold amount.
        offered_gold: i64,
    },
}

pub(crate) fn dispatch_artifact(
    session: &mut Session,
    request: &ArtifactCommandRequest,
) -> Result<CommandResult, RuntimeError> {
    match request {
        ArtifactCommandRequest::StartExcavation {
            expected_revision,
            unit_id,
        } => dispatch_player(
            session,
            PlayerCommand::StartArtifactExcavation(StartArtifactExcavationCommand::new(
                *expected_revision,
                unit_id,
            )),
            ReplayRecordDto::Player {
                command: ReplayCommandDto::StartArtifactExcavation {
                    expected_revision: *expected_revision,
                    unit_id: unit_id.as_str().to_owned(),
                },
            },
        ),
        ArtifactCommandRequest::StoreInCity {
            expected_revision,
            unit_id,
            city_id,
        } => dispatch_player(
            session,
            PlayerCommand::StoreArtifactInCity(StoreArtifactInCityCommand::new(
                *expected_revision,
                unit_id,
                city_id.as_ref(),
            )),
            ReplayRecordDto::Player {
                command: ReplayCommandDto::StoreArtifactInCity {
                    expected_revision: *expected_revision,
                    unit_id: unit_id.as_str().to_owned(),
                    city_id: city_id.as_ref().map(|city| city.as_str().to_owned()),
                },
            },
        ),
        ArtifactCommandRequest::Trade {
            expected_revision,
            target_player_id,
            offered_artifact_id,
            offered_gold,
        } => dispatch_player(
            session,
            PlayerCommand::TradeArtifact(TradeArtifactCommand::new(
                *expected_revision,
                target_player_id,
                offered_artifact_id,
                *offered_gold,
            )),
            ReplayRecordDto::Player {
                command: ReplayCommandDto::TradeArtifact {
                    expected_revision: *expected_revision,
                    target_player_id: target_player_id.as_str().to_owned(),
                    offered_artifact_id: offered_artifact_id.as_str().to_owned(),
                    offered_gold: *offered_gold,
                },
            },
        ),
    }
}
