/// Authoritative treasury warning for the resource strip and breakdown.
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub enum TreasuryWarning {
    /// Treasury is nonnegative and does not become negative within three turns.
    #[default]
    None,
    /// The current treasury is negative.
    NegativeBalance,
    /// Keeping the current negative income makes the treasury negative in three turns.
    DeficitWithinThreeTurns,
}

impl TreasuryWarning {
    pub(super) fn from_forecast(treasury: i64, net_per_turn: i64) -> Self {
        if treasury < 0 {
            Self::NegativeBalance
        } else if net_per_turn < 0 && i128::from(treasury) + i128::from(net_per_turn) * 3 < 0 {
            Self::DeficitWithinThreeTurns
        } else {
            Self::None
        }
    }
}

#[cfg(test)]
mod tests {
    use super::TreasuryWarning::{self, DeficitWithinThreeTurns, NegativeBalance, None};

    #[test]
    fn treasury_warning_uses_exact_three_turn_boundary() {
        for (treasury, income, expected) in [
            (-1, 20, NegativeBalance),
            (0, 0, None),
            (0, 1, None),
            (0, -1, DeficitWithinThreeTurns),
            (30, -10, None),
            (29, -10, DeficitWithinThreeTurns),
            (i64::MIN, i64::MAX, NegativeBalance),
            (i64::MAX, i64::MIN, DeficitWithinThreeTurns),
            (i64::MAX, i64::MAX, None),
        ] {
            assert_eq!(TreasuryWarning::from_forecast(treasury, income), expected);
        }
    }
}
