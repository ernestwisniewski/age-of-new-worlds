use aonw_contracts::ReplayCommandDto;
use aonw_domain::{ArtifactId, CityId, GameState, PlayerId, UnitId};
use aonw_engine::{
    DomainTransition, EngineContext, GameEngine, PlayerCommand, StartArtifactExcavationCommand,
    StoreArtifactInCityCommand, TradeArtifactCommand,
};

use super::{ExecutionError, display_error};

pub(super) fn apply(
    state: GameState,
    context: EngineContext<'_>,
    command: &ReplayCommandDto,
) -> Result<DomainTransition, ExecutionError> {
    match command {
        ReplayCommandDto::StartArtifactExcavation {
            expected_revision,
            unit_id,
        } => {
            let unit_id = UnitId::new(unit_id.as_str()).map_err(display_error)?;
            GameEngine::apply_player_owned(
                state,
                context,
                PlayerCommand::StartArtifactExcavation(StartArtifactExcavationCommand::new(
                    *expected_revision,
                    &unit_id,
                )),
            )
            .map_err(display_error)
        }
        ReplayCommandDto::StoreArtifactInCity {
            expected_revision,
            unit_id,
            city_id,
        } => {
            let unit_id = UnitId::new(unit_id.as_str()).map_err(display_error)?;
            let city_id = city_id
                .as_deref()
                .map(CityId::new)
                .transpose()
                .map_err(display_error)?;
            GameEngine::apply_player_owned(
                state,
                context,
                PlayerCommand::StoreArtifactInCity(StoreArtifactInCityCommand::new(
                    *expected_revision,
                    &unit_id,
                    city_id.as_ref(),
                )),
            )
            .map_err(display_error)
        }
        ReplayCommandDto::TradeArtifact {
            expected_revision,
            target_player_id,
            offered_artifact_id,
            offered_gold,
        } => {
            let target = PlayerId::new(target_player_id.as_str()).map_err(display_error)?;
            let artifact = ArtifactId::new(offered_artifact_id.as_str()).map_err(display_error)?;
            GameEngine::apply_player_owned(
                state,
                context,
                PlayerCommand::TradeArtifact(TradeArtifactCommand::new(
                    *expected_revision,
                    &target,
                    &artifact,
                    *offered_gold,
                )),
            )
            .map_err(display_error)
        }
        _ => unreachable!("artifact executor received another command family"),
    }
}
