use aonw_domain::{Unit, UnitId};

/// Actor-visible unit occupancy used by movement planning.
///
/// A fog-aware adapter supplies the identifiers visible to the actor. The
/// explicit fog-disabled constructor is intended for local games and tests
/// where every unit is legitimately known.
#[derive(Clone, Copy, Debug)]
pub(crate) struct MovementPlanningView<'view> {
    known_unit_ids: Option<&'view [UnitId]>,
}

impl MovementPlanningView<'_> {
    /// Builds a fog-aware view from unit identifiers known to the actor.
    #[must_use]
    #[cfg(test)]
    pub(crate) const fn known_units(known_unit_ids: &[UnitId]) -> MovementPlanningView<'_> {
        MovementPlanningView {
            known_unit_ids: Some(known_unit_ids),
        }
    }

    /// Builds an explicit fog-disabled view in which every unit is known.
    #[must_use]
    pub(crate) const fn fog_disabled() -> Self {
        Self {
            known_unit_ids: None,
        }
    }

    pub(super) fn knows(self, unit_id: &UnitId) -> bool {
        self.known_unit_ids
            .is_none_or(|known| known.iter().any(|candidate| candidate == unit_id))
    }

    pub(crate) fn observes_occupancy(self, moving_unit: &Unit, candidate: &Unit) -> bool {
        candidate.owner_player_id() == moving_unit.owner_player_id() || self.knows(candidate.id())
    }
}

#[cfg(test)]
mod tests {
    use aonw_domain::{HexCoord, MovementUnits, PlayerId, Unit, UnitId, UnitKind};

    use super::MovementPlanningView;

    #[test]
    fn planning_view_always_observes_friendly_and_only_known_enemy_occupancy() {
        let actor = PlayerId::new("actor").expect("actor");
        let enemy = PlayerId::new("enemy").expect("enemy");
        let moving = unit("moving", actor.clone());
        let friendly = unit("friendly", actor);
        let hidden_enemy = unit("enemy", enemy);
        let no_known_units = [];
        let hidden = MovementPlanningView::known_units(&no_known_units);

        assert!(hidden.observes_occupancy(&moving, &friendly));
        assert!(!hidden.observes_occupancy(&moving, &hidden_enemy));
        assert!(
            MovementPlanningView::known_units(&[hidden_enemy.id().clone()])
                .observes_occupancy(&moving, &hidden_enemy)
        );
    }

    fn unit(id: &str, owner: PlayerId) -> Unit {
        Unit::builder(
            UnitId::new(id).expect("unit id"),
            owner,
            UnitKind::Warrior,
            id,
            HexCoord::new(0, 0),
            MovementUnits::ZERO,
        )
        .build()
        .expect("unit")
    }
}
