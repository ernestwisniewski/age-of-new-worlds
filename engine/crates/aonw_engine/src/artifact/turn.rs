use aonw_domain::{ArtifactStateUpdate, GameState};

use super::ArtifactError;
use crate::{ArtifactCarriedEvent, DomainEvent};

pub(crate) struct ArtifactTurnPhase {
    pub(crate) state: GameState,
    pub(crate) events: Vec<DomainEvent>,
}

pub(crate) fn advance_turn_artifacts(
    state: GameState,
    scope: &[aonw_domain::PlayerId],
) -> Result<ArtifactTurnPhase, ArtifactError> {
    let has_active_excavation = state.units().iter().any(|unit| {
        scope.contains(unit.owner_player_id()) && unit.activity().excavating_artifact_id().is_some()
    });
    if !has_active_excavation {
        return Ok(ArtifactTurnPhase {
            state,
            events: Vec::new(),
        });
    }
    let mut units = state.units().to_vec();
    let mut artifacts = state.artifacts().to_vec();
    let mut events = Vec::new();
    for player_id in scope {
        for unit_slot in &mut units {
            let unit = unit_slot.clone();
            if unit.owner_player_id() != player_id {
                continue;
            }
            let Some(artifact_id) = unit.activity().excavating_artifact_id().cloned() else {
                continue;
            };
            let artifact_index = artifacts
                .iter()
                .position(|artifact| artifact.id() == &artifact_id)
                .ok_or_else(|| invalid("excavated artifact is absent from canonical state"))?;
            let (updated_artifact, completed) = artifacts[artifact_index]
                .try_advance_excavation(unit.id(), unit.position())
                .map_err(|error| invalid(error.to_string()))?;
            artifacts[artifact_index] = updated_artifact;
            if completed {
                *unit_slot = unit
                    .after_artifact_excavation_completed(&artifact_id)
                    .ok_or_else(|| invalid("unit failed to complete artifact excavation"))?;
                events.push(DomainEvent::ArtifactCarried(ArtifactCarriedEvent::new(
                    artifact_id,
                    unit.owner_player_id().clone(),
                    unit.id().clone(),
                    unit.position(),
                )));
            }
        }
    }
    let revision = state.revision();
    let economy = state.economy().clone();
    let state = state
        .into_after_artifact(ArtifactStateUpdate {
            revision,
            units,
            artifacts,
            economy,
        })
        .map_err(|error| invalid(error.to_string()))?;
    Ok(ArtifactTurnPhase { state, events })
}

fn invalid(message: impl Into<Box<str>>) -> ArtifactError {
    ArtifactError::InvalidState(message.into())
}

#[cfg(test)]
mod tests {
    #[test]
    fn invalid_state_helper_preserves_its_message() {
        assert_eq!(super::invalid("broken").to_string(), "broken");
    }
}
