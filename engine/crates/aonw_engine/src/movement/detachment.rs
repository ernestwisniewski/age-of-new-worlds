use aonw_domain::{FogVisibility, GameState, TroopKind, Unit, UnitId, UnitKind};

use super::auto_explore::validate_revision;
use super::fog::{merge_discovered_contacts, recompute_after_move};
use super::logistics::{
    DetachTroopCommand, DetachmentOption, MovementLogisticsError, MovementLogisticsUpdate,
};
use super::{MovementCost, terrain_entry_cost};
use crate::{
    CommandRejectionCode, DomainEvent, EngineContext, LogisticsExecution, TroopDetachedEvent,
};

pub(crate) fn apply_detach_troop(
    state: &GameState,
    context: EngineContext<'_>,
    command: DetachTroopCommand<'_>,
) -> Result<MovementLogisticsUpdate, MovementLogisticsError> {
    validate_revision(state, command.expected_revision())?;
    let source = controlled_source(state, context, command.unit_id())?;
    if !has_troop(source, command.troop_kind()) {
        return Err(MovementLogisticsError::new(
            CommandRejectionCode::TroopNotAvailable,
        ));
    }
    if context.map().tile_at(source.position()).is_none() {
        return Err(MovementLogisticsError::new(
            CommandRejectionCode::DetachmentSourceOutOfBounds,
        ));
    }
    let destination =
        destination_for(state, context, source, command.troop_kind()).ok_or_else(|| {
            MovementLogisticsError::new(CommandRejectionCode::DetachmentDestinationUnavailable)
        })?;
    let detached_id = next_detached_id(state, source, command.troop_kind())?;
    let detached_kind = detached_unit_kind(command.troop_kind());
    let maximum = context
        .ruleset()
        .maximum_movement(detached_kind, false)
        .ok_or_else(|| MovementLogisticsError::new(CommandRejectionCode::UnitDefinitionMissing))?;
    let updated_source = source
        .after_troop_detached(command.troop_kind())
        .ok_or_else(|| MovementLogisticsError::new(CommandRejectionCode::TroopNotAvailable))?;
    let detached = Unit::builder(
        detached_id.clone(),
        source.owner_player_id().clone(),
        detached_kind,
        detached_name(command.troop_kind()),
        destination,
        maximum,
    )
    .build()
    .map_err(|_| MovementLogisticsError::new(CommandRejectionCode::InvalidUnit))?;
    let revision = state
        .revision()
        .checked_next()
        .ok_or_else(|| MovementLogisticsError::new(CommandRejectionCode::StateRevisionOverflow))?;
    let mut units = state.units().to_vec();
    let source_slot = units
        .iter_mut()
        .find(|unit| unit.id() == source.id())
        .ok_or_else(|| {
            MovementLogisticsError::new(CommandRejectionCode::MovementUnitUpdateFailed)
        })?;
    *source_slot = updated_source;
    units.push(detached);
    units.sort_unstable_by(|left, right| left.id().cmp(right.id()));
    let refs = units.iter().collect::<Vec<_>>();
    let fog = recompute_after_move(
        state.fog_of_war(),
        context.map(),
        source.owner_player_id(),
        &refs,
        state.cities(),
    );
    let diplomacy = merge_discovered_contacts(state.diplomacy(), &fog, &refs, state.cities());
    Ok(MovementLogisticsUpdate {
        revision,
        units,
        fog_of_war: fog,
        diplomacy,
        interaction: state.interaction().clone().without_unit(source.id()),
        events: vec![DomainEvent::TroopDetached(TroopDetachedEvent::new(
            source.id().clone(),
            detached_id.clone(),
            command.troop_kind(),
            destination,
        ))]
        .into_boxed_slice(),
        evidence: LogisticsExecution::TroopDetached {
            source_unit_id: source.id().clone(),
            detached_unit_id: detached_id,
            troop_kind: command.troop_kind(),
            destination,
        },
    })
}

pub(super) fn detachment_options(
    state: &GameState,
    context: EngineContext<'_>,
    source: &Unit,
) -> Vec<DetachmentOption> {
    source
        .army()
        .iter()
        .filter_map(|troop| {
            destination_for(state, context, source, troop.kind()).map(|destination| {
                DetachmentOption {
                    troop_kind: troop.kind(),
                    destination,
                }
            })
        })
        .collect()
}

pub(super) fn destination_for(
    state: &GameState,
    context: EngineContext<'_>,
    source: &Unit,
    troop_kind: TroopKind,
) -> Option<aonw_domain::HexCoord> {
    let kind = detached_unit_kind(troop_kind);
    let domain = context
        .ruleset()
        .unit(kind)?
        .capabilities()
        .movement_domain
        .domain();
    source.position().neighbors().find(|coordinate| {
        let Some(tile) = context.map().tile_at(*coordinate) else {
            return false;
        };
        context.visibility_at(*coordinate) != FogVisibility::Hidden
            && !state
                .units()
                .iter()
                .any(|unit| unit.position() == *coordinate)
            && !context.city_blocks(source, *coordinate)
            && !context.territory_blocks(source, *coordinate)
            && matches!(terrain_entry_cost(tile, domain), MovementCost::Passable(_))
    })
}

fn controlled_source<'state>(
    state: &'state GameState,
    context: EngineContext<'_>,
    unit_id: &UnitId,
) -> Result<&'state Unit, MovementLogisticsError> {
    let unit = state
        .unit(unit_id)
        .ok_or_else(|| MovementLogisticsError::new(CommandRejectionCode::UnitNotFound))?;
    if !context.can_act() || unit.owner_player_id() != context.actor_player_id() {
        return Err(MovementLogisticsError::new(
            CommandRejectionCode::UnitNotControlled,
        ));
    }
    Ok(unit)
}

fn has_troop(source: &Unit, kind: TroopKind) -> bool {
    source
        .army()
        .iter()
        .any(|troop| troop.kind() == kind && troop.count() > 0)
}

fn next_detached_id(
    state: &GameState,
    source: &Unit,
    kind: TroopKind,
) -> Result<UnitId, MovementLogisticsError> {
    let kind = detached_name(kind);
    for index in 1..=state.units().len().saturating_add(1) {
        let candidate = format!("{}_{}_{}", source.id().as_str(), kind, index);
        let Ok(candidate) = UnitId::new(candidate) else {
            return Err(MovementLogisticsError::new(
                CommandRejectionCode::DetachedUnitIdUnavailable,
            ));
        };
        if state.unit(&candidate).is_none() {
            return Ok(candidate);
        }
    }
    Err(MovementLogisticsError::new(
        CommandRejectionCode::DetachedUnitIdUnavailable,
    ))
}

const fn detached_unit_kind(kind: TroopKind) -> UnitKind {
    match kind {
        TroopKind::Warrior => UnitKind::Warrior,
        TroopKind::Archer => UnitKind::Archer,
        TroopKind::Settler => UnitKind::Settler,
    }
}

const fn detached_name(kind: TroopKind) -> &'static str {
    match kind {
        TroopKind::Warrior => "warrior",
        TroopKind::Archer => "archer",
        TroopKind::Settler => "settler",
    }
}
