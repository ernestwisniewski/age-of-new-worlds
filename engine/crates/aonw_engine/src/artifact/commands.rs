use aonw_domain::{
    ArtifactStateUpdate, EconomyAccountChange, EconomyStateBuildError, GameState,
    WorldArtifactLocation,
};

use super::{
    ArtifactError, StartArtifactExcavationCommand, StoreArtifactInCityCommand, TradeArtifactCommand,
};
use crate::{
    ArtifactExcavationStartedEvent, ArtifactStoredEvent, CommandRejectionCode,
    DiplomacyPolicyQuery, DomainEvent, EngineContext,
};

const EXCAVATION_TURNS: u32 = 2;

/// Atomic replacement produced by one artifact command.
pub(crate) struct ArtifactMutation {
    pub(crate) update: ArtifactStateUpdate,
    pub(crate) events: Box<[DomainEvent]>,
}

pub(crate) fn apply_start_excavation(
    state: &GameState,
    context: EngineContext<'_>,
    command: StartArtifactExcavationCommand<'_>,
) -> Result<ArtifactMutation, ArtifactError> {
    validate_revision(state, command.expected_revision())?;
    let unit = controlled_unit(state, context, command.unit_id())?;
    if unit.activity().blocks_manual_movement()
        || unit.posture() == aonw_domain::UnitPosture::Fortified
    {
        return Err(CommandRejectionCode::UnitUnavailable.into());
    }
    if unit.carried_artifact_id().is_some() {
        return Err(CommandRejectionCode::UnitAlreadyCarryingArtifact.into());
    }
    let artifact = state
        .artifacts()
        .iter()
        .find(|artifact| artifact.location() == &WorldArtifactLocation::Map(unit.position()))
        .ok_or(CommandRejectionCode::ArtifactNotFound)?;
    let updated_unit = unit.after_artifact_excavation_started(artifact.id().clone());
    let updated_artifact = artifact
        .try_start_excavation(unit.id().clone(), unit.position(), EXCAVATION_TURNS)
        .map_err(|error| invalid(error.to_string()))?;
    let revision = next_revision(state)?;
    let mut units = state.units().to_vec();
    replace_unit(&mut units, updated_unit)?;
    let mut artifacts = state.artifacts().to_vec();
    replace_artifact(&mut artifacts, updated_artifact)?;
    let event = ArtifactExcavationStartedEvent::new(
        artifact.id().clone(),
        unit.owner_player_id().clone(),
        unit.id().clone(),
        unit.position(),
    );
    Ok(mutation(
        state,
        revision,
        units,
        artifacts,
        [DomainEvent::ArtifactExcavationStarted(event)],
    ))
}

pub(crate) fn apply_store_in_city(
    state: &GameState,
    context: EngineContext<'_>,
    command: StoreArtifactInCityCommand<'_>,
) -> Result<ArtifactMutation, ArtifactError> {
    validate_revision(state, command.expected_revision())?;
    let unit = controlled_unit(state, context, command.unit_id())?;
    let artifact_id = unit
        .carried_artifact_id()
        .ok_or(CommandRejectionCode::UnitNotCarryingArtifact)?;
    let artifact = state
        .artifact(artifact_id)
        .ok_or_else(|| invalid("carried artifact is absent from canonical state"))?;
    if artifact.location() != &WorldArtifactLocation::Carried(unit.id().clone()) {
        return Err(invalid("carried artifact ownership is inconsistent"));
    }
    let city = command
        .city_id()
        .map_or_else(
            || state.city_at(unit.position()),
            |city_id| state.city(city_id),
        )
        .ok_or(CommandRejectionCode::CityNotFound)?;
    if city.owner_player_id() != context.actor_player_id() {
        return Err(CommandRejectionCode::CityNotControlled.into());
    }
    if city.center() != unit.position() {
        return Err(CommandRejectionCode::UnitNotInCity.into());
    }
    if city_stores_artifact(state, city.id()) {
        return Err(CommandRejectionCode::CityArtifactSlotFull.into());
    }
    let updated_unit = unit
        .after_artifact_stored(artifact.id())
        .ok_or_else(|| invalid("unit failed to release its carried artifact"))?;
    let updated_artifact = artifact
        .try_store(unit.id(), city.id().clone())
        .map_err(|error| invalid(error.to_string()))?;
    let revision = next_revision(state)?;
    let mut units = state.units().to_vec();
    replace_unit(&mut units, updated_unit)?;
    let mut artifacts = state.artifacts().to_vec();
    replace_artifact(&mut artifacts, updated_artifact)?;
    let event = ArtifactStoredEvent::new(
        artifact.id().clone(),
        city.owner_player_id().clone(),
        Some(unit.id().clone()),
        city.id().clone(),
        city.center(),
    );
    Ok(mutation(
        state,
        revision,
        units,
        artifacts,
        [DomainEvent::ArtifactStored(event)],
    ))
}

pub(crate) fn apply_trade(
    state: &GameState,
    context: EngineContext<'_>,
    command: TradeArtifactCommand<'_>,
) -> Result<ArtifactMutation, ArtifactError> {
    validate_revision(state, command.expected_revision())?;
    let actor = context.actor_player_id();
    let identity = state.match_lifecycle().identity();
    if !context.can_act() || !identity.contains(actor) {
        return Err(CommandRejectionCode::ArtifactTradeActorUnavailable.into());
    }
    let target = command.target_player_id();
    if target == actor || !identity.contains(target) {
        return Err(CommandRejectionCode::ArtifactTradeTargetInvalid.into());
    }
    if command.offered_gold() < 0 {
        return Err(CommandRejectionCode::ArtifactTradeGoldInvalid.into());
    }
    let policy = DiplomacyPolicyQuery::between(state, actor, target)
        .map_err(|error| invalid(error.to_string()))?;
    if !policy.trade_eligible() {
        return Err(CommandRejectionCode::ArtifactTradeBlockedByWar.into());
    }
    let artifact = state
        .artifact(command.offered_artifact_id())
        .ok_or(CommandRejectionCode::OfferedArtifactUnavailable)?;
    let WorldArtifactLocation::Stored(source_city_id) = artifact.location() else {
        return Err(CommandRejectionCode::OfferedArtifactUnavailable.into());
    };
    let source_city = state
        .city(source_city_id)
        .ok_or_else(|| invalid("stored artifact city is absent from canonical state"))?;
    if source_city.owner_player_id() != actor {
        return Err(CommandRejectionCode::OfferedArtifactUnavailable.into());
    }
    let target_city = state
        .cities()
        .iter()
        .filter(|city| city.owner_player_id() == target)
        .find(|city| !city_stores_artifact(state, city.id()))
        .ok_or(CommandRejectionCode::TargetArtifactSlotUnavailable)?;
    let economy = transfer_gold(state, actor, target, command.offered_gold())?;
    let updated_artifact = artifact
        .try_transfer_stored(source_city.id(), target_city.id().clone())
        .map_err(|error| invalid(error.to_string()))?;
    let revision = next_revision(state)?;
    let mut artifacts = state.artifacts().to_vec();
    replace_artifact(&mut artifacts, updated_artifact)?;
    let event = ArtifactStoredEvent::new(
        artifact.id().clone(),
        target.clone(),
        None,
        target_city.id().clone(),
        target_city.center(),
    );
    Ok(ArtifactMutation {
        update: ArtifactStateUpdate {
            revision,
            units: state.units().to_vec(),
            artifacts,
            economy,
        },
        events: vec![DomainEvent::ArtifactStored(event)].into_boxed_slice(),
    })
}

fn controlled_unit<'state>(
    state: &'state GameState,
    context: EngineContext<'_>,
    unit_id: &aonw_domain::UnitId,
) -> Result<&'state aonw_domain::Unit, ArtifactError> {
    let unit = state
        .unit(unit_id)
        .ok_or(CommandRejectionCode::UnitNotFound)?;
    if !context.can_act() || unit.owner_player_id() != context.actor_player_id() {
        return Err(CommandRejectionCode::UnitNotControlled.into());
    }
    Ok(unit)
}

fn city_stores_artifact(state: &GameState, city_id: &aonw_domain::CityId) -> bool {
    state
        .artifacts()
        .iter()
        .any(|artifact| artifact.location() == &WorldArtifactLocation::Stored(city_id.clone()))
}

fn transfer_gold(
    state: &GameState,
    actor: &aonw_domain::PlayerId,
    target: &aonw_domain::PlayerId,
    offered_gold: i64,
) -> Result<aonw_domain::EconomyState, ArtifactError> {
    if offered_gold == 0 {
        return Ok(state.economy().clone());
    }
    let actor_gold = state
        .economy()
        .player_gold()
        .get(actor)
        .copied()
        .unwrap_or_default();
    let target_gold = state
        .economy()
        .player_gold()
        .get(target)
        .copied()
        .unwrap_or_default();
    if actor_gold < offered_gold || target_gold.checked_add(offered_gold).is_none() {
        return Err(CommandRejectionCode::ArtifactTradeGoldUnavailable.into());
    }
    state
        .economy()
        .try_after_changes(
            state.match_lifecycle().identity(),
            state.bounds(),
            [
                EconomyAccountChange::Gold {
                    player: actor.clone(),
                    delta: -offered_gold,
                },
                EconomyAccountChange::Gold {
                    player: target.clone(),
                    delta: offered_gold,
                },
            ],
        )
        .map_err(|error| match error {
            EconomyStateBuildError::InsufficientBalance { .. }
            | EconomyStateBuildError::AccountOverflow { .. } => {
                CommandRejectionCode::ArtifactTradeGoldUnavailable.into()
            }
            other => invalid(other.to_string()),
        })
}

fn mutation(
    state: &GameState,
    revision: aonw_domain::StateRevision,
    units: Vec<aonw_domain::Unit>,
    artifacts: Vec<aonw_domain::WorldArtifact>,
    events: impl IntoIterator<Item = DomainEvent>,
) -> ArtifactMutation {
    ArtifactMutation {
        update: ArtifactStateUpdate {
            revision,
            units,
            artifacts,
            economy: state.economy().clone(),
        },
        events: events.into_iter().collect(),
    }
}

fn validate_revision(state: &GameState, expected_revision: u64) -> Result<(), ArtifactError> {
    if state.revision().get() == expected_revision {
        Ok(())
    } else {
        Err(CommandRejectionCode::StaleRevision.into())
    }
}

fn next_revision(state: &GameState) -> Result<aonw_domain::StateRevision, ArtifactError> {
    state
        .revision()
        .checked_next()
        .ok_or_else(|| CommandRejectionCode::StateRevisionOverflow.into())
}

fn replace_unit(
    units: &mut [aonw_domain::Unit],
    updated: aonw_domain::Unit,
) -> Result<(), ArtifactError> {
    let slot = units
        .iter_mut()
        .find(|unit| unit.id() == updated.id())
        .ok_or_else(|| invalid("validated artifact unit disappeared"))?;
    *slot = updated;
    Ok(())
}

fn replace_artifact(
    artifacts: &mut [aonw_domain::WorldArtifact],
    updated: aonw_domain::WorldArtifact,
) -> Result<(), ArtifactError> {
    let slot = artifacts
        .iter_mut()
        .find(|artifact| artifact.id() == updated.id())
        .ok_or_else(|| invalid("validated artifact disappeared"))?;
    *slot = updated;
    Ok(())
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
