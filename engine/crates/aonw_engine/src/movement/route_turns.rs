use aonw_domain::{MovementStep, MovementUnits};

pub(super) fn route_step_turns(
    steps: &[MovementStep],
    available: MovementUnits,
    maximum: MovementUnits,
) -> impl Iterator<Item = u32> + '_ {
    let mut turn = 1_u32;
    let mut remaining = available;
    steps.iter().enumerate().map(move |(index, step)| {
        if index != 0 {
            if remaining == MovementUnits::ZERO {
                turn = turn.saturating_add(1);
                remaining = maximum;
            }
            remaining = remaining
                .checked_sub(step.enter_cost())
                .unwrap_or(MovementUnits::ZERO);
        }
        turn
    })
}

#[cfg(test)]
mod tests {
    use aonw_domain::HexCoord;

    use super::*;

    fn turns(costs: &[u32], available: u32, maximum: u32) -> Vec<u32> {
        let mut cumulative = 0;
        let steps = costs
            .iter()
            .map(|cost| {
                cumulative += cost;
                MovementStep::new(
                    HexCoord::new(0, 0),
                    MovementUnits::new(*cost),
                    MovementUnits::new(cumulative),
                )
            })
            .collect::<Vec<_>>();
        route_step_turns(
            &steps,
            MovementUnits::new(available),
            MovementUnits::new(maximum),
        )
        .collect()
    }

    #[test]
    fn marks_every_future_turn_without_spreading_unused_points() {
        assert_eq!(
            turns(&[0, 2, 2, 2, 2, 2, 2, 2], 2, 4),
            [1, 1, 2, 2, 3, 3, 4, 4]
        );
    }

    #[test]
    fn rough_entry_exhausts_the_current_positive_remainder() {
        assert_eq!(turns(&[0, 4, 2, 4, 2, 2], 3, 4), [1, 1, 2, 2, 3, 3]);
    }

    #[test]
    fn spent_current_turn_and_expensive_future_entries_keep_calendar_turns() {
        assert_eq!(turns(&[0, 6, 2, 2], 0, 4), [1, 2, 3, 3]);
        assert_eq!(turns(&[0], 0, 4), [1]);
        assert!(turns(&[], 0, 4).is_empty());
    }
}
