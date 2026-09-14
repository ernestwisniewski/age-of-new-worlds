use aonw_content::RulesetDefinition;
use aonw_domain::{MovementStep, Unit};

use super::maximum_movement_units;
use super::reachable::movement_available_for_query;
use super::route_turns::route_step_turns;

/// Returns calendar turns for a stored itinerary from the unit's current position.
///
/// Steps before the current position are marked zero (already traversed). The
/// current position is turn one, and remaining steps use the same exhaustion
/// rules as a fresh route query. Costs describe the stored itinerary, not a
/// prediction of future replanning when terrain, roads or occupancy change.
/// Returns `None` when the unit no longer lies on the itinerary. The caller must
/// disclose this private order only to its owner.
#[must_use]
pub fn stored_route_step_turns<'route>(
    unit: &Unit,
    ruleset: &RulesetDefinition,
    steps: &'route [MovementStep],
) -> Option<impl Iterator<Item = u32> + 'route> {
    let current = steps
        .iter()
        .position(|step| step.coordinate() == unit.position())?;
    let available = movement_available_for_query(unit, ruleset);
    let maximum =
        maximum_movement_units(ruleset, unit.kind(), unit.carried_artifact_id().is_some());
    Some(core::iter::repeat_n(0, current).chain(route_step_turns(
        &steps[current..],
        available,
        maximum,
    )))
}

#[cfg(test)]
mod tests {
    use aonw_domain::{ArtifactId, HexCoord, MovementUnits, PlayerId, UnitId, UnitKind};

    use super::*;

    #[test]
    fn queued_route_keeps_exhausting_entries_and_all_future_turns() {
        let steps = steps();
        let unit = unit(0, 3);
        let before = steps.clone();
        assert_eq!(turns(&unit, &steps), Some(vec![1, 1, 2, 2, 3, 3]));
        assert_eq!(steps, before);
        assert_eq!(unit.movement_units(), MovementUnits::new(3));
    }

    #[test]
    fn merchant_prefix_is_traversed_and_its_current_step_is_not_charged_again() {
        let steps = steps();
        assert_eq!(turns(&unit(2, 3), &steps), Some(vec![0, 0, 1, 1, 2, 2]));
        assert_eq!(turns(&unit(2, 0), &steps), Some(vec![0, 0, 1, 2, 3, 3]));
        assert_eq!(turns(&unit(5, 0), &steps), Some(vec![0, 0, 0, 0, 0, 1]));
        assert_eq!(turns(&unit(9, 3), &steps), None);
        assert_eq!(turns(&unit(0, 3), &[]), None);
    }

    #[test]
    fn stored_route_uses_the_unit_and_carried_artifact_movement_allowance() {
        let build = |artifact| {
            Unit::builder(
                UnitId::new("scout").unwrap(),
                PlayerId::new("owner").unwrap(),
                UnitKind::ReconPlane,
                "Scout",
                HexCoord::new(0, 0),
                MovementUnits::ZERO,
            )
            .with_carried_artifact(artifact)
            .build()
            .unwrap()
        };
        let steps = steps();
        assert_eq!(turns(&build(None), &steps), Some(vec![1, 2, 2, 2, 2, 2]));
        let carrier = build(Some(ArtifactId::new("artifact").unwrap()));
        assert_eq!(turns(&carrier, &steps), Some(vec![1, 2, 3, 3, 4, 4]));
    }

    fn turns(unit: &Unit, steps: &[MovementStep]) -> Option<Vec<u32>> {
        stored_route_step_turns(unit, RulesetDefinition::standard(), steps).map(Iterator::collect)
    }

    fn unit(col: i32, available: u32) -> Unit {
        Unit::builder(
            UnitId::new("unit").unwrap(),
            PlayerId::new("owner").unwrap(),
            UnitKind::FieldCannon,
            "Cannon",
            HexCoord::new(col, 0),
            MovementUnits::new(available),
        )
        .build()
        .unwrap()
    }

    fn steps() -> Vec<MovementStep> {
        [
            (0, 0, 0),
            (1, 4, 4),
            (2, 2, 6),
            (3, 4, 10),
            (4, 2, 12),
            (5, 2, 14),
        ]
        .into_iter()
        .map(|(col, cost, cumulative)| {
            MovementStep::new(
                HexCoord::new(col, 0),
                MovementUnits::new(cost),
                MovementUnits::new(cumulative),
            )
        })
        .collect()
    }
}
