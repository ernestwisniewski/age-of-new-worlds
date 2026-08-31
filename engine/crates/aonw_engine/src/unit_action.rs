use aonw_domain::{ArtifactId, GameState, InteractionState, StateRevision, Unit, UnitId};

use crate::{CommandRejectionCode, EngineContext};

/// Revision-bound map-independent unit action.
#[derive(Clone, Copy, Debug)]
pub struct UnitActionCommand<'command> {
    expected_revision: u64,
    unit_id: &'command UnitId,
}

impl<'command> UnitActionCommand<'command> {
    /// Creates a unit action command.
    #[must_use]
    pub const fn new(expected_revision: u64, unit_id: &'command UnitId) -> Self {
        Self {
            expected_revision,
            unit_id,
        }
    }

    /// Returns the expected canonical revision.
    #[must_use]
    pub const fn expected_revision(self) -> u64 {
        self.expected_revision
    }

    /// Returns the commanded unit.
    #[must_use]
    pub const fn unit_id(self) -> &'command UnitId {
        self.unit_id
    }
}

#[derive(Clone, Copy, Debug)]
pub(crate) enum UnitActionKind {
    Cancel,
    Skip,
    Fortify,
}

/// Stable rejection for a map-independent unit action.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum UnitActionError {
    /// Command was planned against a different state revision.
    StaleRevision,
    /// The requested unit does not exist.
    UnitNotFound,
    /// The actor cannot command the requested unit.
    UnitNotControlled,
    /// The unit has an activity that prevents fortification.
    UnitBusy,
    /// The ruleset has no definition for the unit kind.
    UnitDefinitionMissing,
    /// The next state revision cannot be represented.
    RevisionOverflow,
}

impl UnitActionError {
    /// Returns a stable language-neutral rejection code.
    #[must_use]
    pub const fn code(self) -> CommandRejectionCode {
        match self {
            Self::StaleRevision => CommandRejectionCode::StaleRevision,
            Self::UnitNotFound => CommandRejectionCode::UnitNotFound,
            Self::UnitNotControlled => CommandRejectionCode::UnitNotControlled,
            Self::UnitBusy => CommandRejectionCode::UnitBusy,
            Self::UnitDefinitionMissing => CommandRejectionCode::UnitDefinitionMissing,
            Self::RevisionOverflow => CommandRejectionCode::StateRevisionOverflow,
        }
    }
}

impl core::fmt::Display for UnitActionError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        self.code().fmt(formatter)
    }
}

impl std::error::Error for UnitActionError {}

pub(crate) struct UnitActionUpdate {
    pub(crate) revision: StateRevision,
    pub(crate) unit: Unit,
    pub(crate) interaction: InteractionState,
    pub(crate) cancelled_excavation: Option<ArtifactId>,
}

pub(crate) fn apply_unit_action(
    state: &GameState,
    context: EngineContext<'_>,
    command: UnitActionCommand<'_>,
    kind: UnitActionKind,
) -> Result<UnitActionUpdate, UnitActionError> {
    if command.expected_revision() != state.revision().get() {
        return Err(UnitActionError::StaleRevision);
    }
    let unit = state
        .unit(command.unit_id())
        .ok_or(UnitActionError::UnitNotFound)?;
    if !context.can_act() || unit.owner_player_id() != context.actor_player_id() {
        return Err(UnitActionError::UnitNotControlled);
    }
    if matches!(kind, UnitActionKind::Fortify) && unit.activity().blocks_manual_movement() {
        return Err(UnitActionError::UnitBusy);
    }
    let (updated, interaction, cancelled_excavation) = match kind {
        UnitActionKind::Cancel => {
            let maximum = context
                .ruleset()
                .maximum_movement(unit.kind(), unit.carried_artifact_id().is_some())
                .ok_or(UnitActionError::UnitDefinitionMissing)?;
            let restore = state.interaction().turn_skip_restore(unit.id());
            let excavation = unit.activity().excavating_artifact_id().cloned();
            (
                unit.after_cancel_action(maximum, restore),
                state.interaction().clone().without_unit(unit.id()),
                excavation,
            )
        }
        UnitActionKind::Skip => (
            unit.after_skip_turn(),
            state.interaction().clone().after_skip(unit),
            None,
        ),
        UnitActionKind::Fortify => (
            unit.after_fortify(),
            state.interaction().clone().without_unit(unit.id()),
            None,
        ),
    };
    let revision = state
        .revision()
        .checked_next()
        .ok_or(UnitActionError::RevisionOverflow)?;
    Ok(UnitActionUpdate {
        revision,
        unit: updated,
        interaction,
        cancelled_excavation,
    })
}

#[cfg(test)]
mod tests {
    use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
    use aonw_domain::{
        GameState, HexCoord, HexGridBounds, MovementUnits, PlayerId, StateRevision, Unit, UnitId,
        UnitKind, UnitOccupancyPolicy, UnitPosture,
    };

    use super::{UnitActionCommand, UnitActionError, UnitActionKind, apply_unit_action};
    use crate::EngineContext;

    fn world() -> (GameState, MapDefinition, PlayerId, UnitId) {
        let player = PlayerId::new("player-1").expect("player");
        let unit_id = UnitId::new("unit-1").expect("unit");
        let unit = Unit::builder(
            unit_id.clone(),
            player.clone(),
            UnitKind::Commander,
            "Commander",
            HexCoord::new(0, 0),
            MovementUnits::new(6),
        )
        .build()
        .expect("unit");
        let state = GameState::try_new(
            StateRevision::new(3),
            1,
            HexGridBounds::new(1, 1).expect("bounds"),
            UnitOccupancyPolicy::Exclusive,
            [unit],
        )
        .expect("state");
        let map = MapDefinition::try_new(
            "unit-actions",
            GridLayout::OddQFlatTop,
            1,
            1,
            vec![
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(0, 0),
                    vec![TerrainType::Grassland],
                    Vec::new(),
                    0,
                )
                .expect("tile"),
            ],
            Vec::new(),
        )
        .expect("map");
        (state, map, player, unit_id)
    }

    #[test]
    fn validation_order_is_revision_identity_control_then_activity() {
        let (state, map, player, unit_id) = world();
        let context = EngineContext::canonical(&player, &map, RulesetDefinition::standard());
        assert_eq!(
            apply_unit_action(
                &state,
                context,
                UnitActionCommand::new(2, &unit_id),
                UnitActionKind::Fortify,
            )
            .map(|_| ()),
            Err(UnitActionError::StaleRevision)
        );
        let missing = UnitId::new("missing").expect("unit");
        assert_eq!(
            apply_unit_action(
                &state,
                context,
                UnitActionCommand::new(3, &missing),
                UnitActionKind::Fortify,
            )
            .map(|_| ()),
            Err(UnitActionError::UnitNotFound)
        );
    }

    #[test]
    fn skip_cancel_and_fortify_are_deterministic() {
        let (state, map, player, unit_id) = world();
        let context = EngineContext::canonical(&player, &map, RulesetDefinition::standard());
        let skipped = apply_unit_action(
            &state,
            context,
            UnitActionCommand::new(3, &unit_id),
            UnitActionKind::Skip,
        )
        .expect("skip");
        assert_eq!(skipped.unit.movement_units(), MovementUnits::ZERO);
        assert_eq!(skipped.revision, StateRevision::new(4));

        let fortified = apply_unit_action(
            &state,
            context,
            UnitActionCommand::new(3, &unit_id),
            UnitActionKind::Fortify,
        )
        .expect("fortify");
        assert_eq!(fortified.unit.posture(), UnitPosture::Fortified);
    }
}
