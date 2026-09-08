use std::collections::BTreeSet;

use aonw_domain::{
    FogVisibility, GameState, HexCoord, PlayerResearchState, Unit, UnitKind, UnitPosture,
};

use super::{PendingTurnAction, PendingTurnActions, PendingTurnActionsQuery};
use crate::{EngineContext, TechnologyAvailability, TechnologyUnlockQuery};

/// Stable rejection of an authoritative manual-work query.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum PendingTurnActionsError {
    StaleRevision,
    PlayerNotInMatch,
    InvalidUnitStatistics,
    InvalidTechnology,
}
impl PendingTurnActionsError {
    /// Returns a language-independent query error code.
    #[must_use]
    pub const fn code(self) -> &'static str {
        match self {
            Self::StaleRevision => "stale_revision",
            Self::PlayerNotInMatch => "pending_turn_actions_player_not_in_match",
            Self::InvalidUnitStatistics => "pending_turn_actions_invalid_unit_statistics",
            Self::InvalidTechnology => "pending_turn_actions_invalid_technology",
        }
    }
}
impl core::fmt::Display for PendingTurnActionsError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        formatter.write_str(self.code())
    }
}
impl std::error::Error for PendingTurnActionsError {}

pub(super) fn pending(
    state: &GameState,
    context: EngineContext<'_>,
    query: PendingTurnActionsQuery,
) -> Result<PendingTurnActions, PendingTurnActionsError> {
    if state.revision().get() != query.expected_revision {
        return Err(PendingTurnActionsError::StaleRevision);
    }
    let actor = context.actor_player_id();
    if !state.match_lifecycle().identity().contains(actor) {
        return Err(PendingTurnActionsError::PlayerNotInMatch);
    }
    let disclosed_foreign = state
        .units()
        .iter()
        .filter(|unit| {
            unit.owner_player_id() != actor
                && state.fog_of_war().visibility(actor, unit.position()) == FogVisibility::Visible
        })
        .map(Unit::position)
        .collect::<BTreeSet<_>>();
    let mut candidates = Vec::new();
    for (index, unit) in state.units().iter().enumerate() {
        if unit.owner_player_id() != actor || !needs_manual_order(unit) {
            continue;
        }
        candidates.push((
            category(context, unit)?,
            !sees_foreign_unit(context, unit, &disclosed_foreign),
            index,
            unit,
        ));
    }
    candidates.sort_by_key(|(category, no_enemy, index, _)| (*category, *no_enemy, *index));
    let mut actions = candidates
        .into_iter()
        .map(|(_, _, _, unit)| PendingTurnAction::Unit {
            unit_id: unit.id().clone(),
            coordinate: unit.position(),
        })
        .collect::<Vec<_>>();
    actions.extend(
        state
            .cities()
            .iter()
            .filter(|city| city.owner_player_id() == actor && city.production_queue().is_none())
            .map(|city| PendingTurnAction::CityProduction {
                city_id: city.id().clone(),
                coordinate: city.center(),
            }),
    );
    if needs_research(state, context)? {
        actions.push(PendingTurnAction::Research);
    }
    Ok(PendingTurnActions {
        can_activate: !state.outcome().is_terminal()
            && crate::application::player_action_lifecycle_rejection(
                state,
                actor,
                context.can_act(),
            )
            .is_none(),
        actions,
    })
}

fn needs_manual_order(unit: &Unit) -> bool {
    !unit.activity().blocks_manual_movement()
        && !matches!(
            unit.posture(),
            UnitPosture::AutoExploring | UnitPosture::AutoWorking
        )
        && unit.movement_units().get() > 0
        && unit.queued_path().is_none()
        && unit.merchant_trade_route().is_none()
}

fn category(context: EngineContext<'_>, unit: &Unit) -> Result<u8, PendingTurnActionsError> {
    let attack = crate::combat::unit_base_attack(context.ruleset(), unit)
        .ok_or(PendingTurnActionsError::InvalidUnitStatistics)?;
    Ok(if attack > 0 {
        0
    } else if matches!(unit.kind(), UnitKind::Worker | UnitKind::Settler) {
        1
    } else {
        2
    })
}

fn sees_foreign_unit(
    context: EngineContext<'_>,
    unit: &Unit,
    foreign: &BTreeSet<HexCoord>,
) -> bool {
    !foreign.is_empty()
        && crate::movement::visible_from_unit(context.map(), unit)
            .iter()
            .any(|coordinate| foreign.contains(coordinate))
}

fn needs_research(
    state: &GameState,
    context: EngineContext<'_>,
) -> Result<bool, PendingTurnActionsError> {
    let empty = PlayerResearchState::default();
    let research = state
        .research()
        .players()
        .get(context.actor_player_id())
        .unwrap_or(&empty);
    if research.active_technology_id().is_some() {
        return Ok(false);
    }
    let unlocks = TechnologyUnlockQuery::new(context.ruleset(), research);
    for definition in context.ruleset().technologies() {
        if unlocks
            .availability(definition.id())
            .map_err(|_| PendingTurnActionsError::InvalidTechnology)?
            == TechnologyAvailability::Available
        {
            return Ok(true);
        }
    }
    Ok(false)
}

#[cfg(test)]
#[path = "unit_tests.rs"]
mod tests;
