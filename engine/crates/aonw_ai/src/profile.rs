use crate::PlanningBudget;

const BASIS_POINTS: u32 = 10_000;

/// Reviewed production difficulty levels with deterministic work budgets.
#[derive(Clone, Copy, Debug, Default, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub enum AiDifficulty {
    /// Forgiving policy with conservative combat and no tactical tree search.
    Easy,
    /// Default production strength and a small tactical search.
    #[default]
    Normal,
    /// Stronger evaluation and a broader tactical search.
    Hard,
    /// Largest reviewed deterministic search budget.
    VeryHard,
}

impl AiDifficulty {
    /// Returns the reviewed tactical search budget, or `None` for easy play.
    #[must_use]
    pub fn tactical_budget(self) -> Option<PlanningBudget> {
        let limits = match self {
            Self::Easy => return None,
            Self::Normal => (8, 6, 2),
            Self::Hard => (16, 10, 3),
            Self::VeryHard => (32, 16, 4),
        };
        PlanningBudget::try_new(limits.0, limits.1, limits.2).ok()
    }

    pub(crate) const fn combat_risk_basis_points(self) -> u32 {
        match self {
            Self::Easy => 8_000,
            Self::Normal => 9_000,
            Self::Hard => 9_600,
            Self::VeryHard => BASIS_POINTS,
        }
    }

    const fn weight_multiplier(self) -> UtilityWeights {
        match self {
            Self::Easy => UtilityWeights::new(6_500, 9_500, 10_500, 9_500),
            Self::Normal => UtilityWeights::new(7_800, 10_000, 10_500, 10_000),
            Self::Hard => UtilityWeights::new(9_000, 10_000, 10_000, 10_000),
            Self::VeryHard => UtilityWeights::IDENTITY,
        }
    }
}

/// Long-lived strategic preference applied to every utility decision.
#[derive(Clone, Copy, Debug, Default, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub enum AiPersona {
    /// No strategic branch receives a preference.
    #[default]
    Balanced,
    /// Prefers military pressure and accepts more combat risk.
    Aggressive,
    /// Prefers exploration, settlers, and territorial growth.
    Expansive,
    /// Prefers workers, infrastructure, trade, and wealth.
    Economic,
    /// Prefers research and science infrastructure.
    Scientific,
}

impl AiPersona {
    const fn weights(self) -> UtilityWeights {
        match self {
            Self::Balanced => UtilityWeights::IDENTITY,
            Self::Aggressive => UtilityWeights::new(13_500, 9_500, 8_500, 8_500),
            Self::Expansive => UtilityWeights::new(9_000, 13_500, 10_500, 9_500),
            Self::Economic => UtilityWeights::new(8_000, 10_500, 13_500, 10_500),
            Self::Scientific => UtilityWeights::new(8_500, 9_500, 10_500, 13_500),
        }
    }
}

/// Fixed-point strategic weights; 10,000 represents a neutral multiplier.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct UtilityWeights {
    aggression: u32,
    expansion: u32,
    economy: u32,
    science: u32,
}

impl UtilityWeights {
    /// Neutral fixed-point weights.
    pub const IDENTITY: Self = Self::new(BASIS_POINTS, BASIS_POINTS, BASIS_POINTS, BASIS_POINTS);

    const fn new(aggression: u32, expansion: u32, economy: u32, science: u32) -> Self {
        Self {
            aggression,
            expansion,
            economy,
            science,
        }
    }

    const fn multiplied(self, other: Self) -> Self {
        Self::new(
            multiply_basis_points(self.aggression, other.aggression),
            multiply_basis_points(self.expansion, other.expansion),
            multiply_basis_points(self.economy, other.economy),
            multiply_basis_points(self.science, other.science),
        )
    }

    /// Returns the military utility multiplier in basis points.
    #[must_use]
    pub const fn aggression(self) -> u32 {
        self.aggression
    }
    /// Returns the territorial utility multiplier in basis points.
    #[must_use]
    pub const fn expansion(self) -> u32 {
        self.expansion
    }
    /// Returns the economic utility multiplier in basis points.
    #[must_use]
    pub const fn economy(self) -> u32 {
        self.economy
    }
    /// Returns the science utility multiplier in basis points.
    #[must_use]
    pub const fn science(self) -> u32 {
        self.science
    }
}

/// Complete deterministic production policy profile.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct AiProfile {
    difficulty: AiDifficulty,
    persona: AiPersona,
    tactical_strategy: AiTacticalStrategy,
    base_seed: u32,
}

impl Default for AiProfile {
    fn default() -> Self {
        Self::new(AiDifficulty::default(), AiPersona::default())
    }
}

#[derive(Clone, Copy, Debug, Default, Eq, Hash, PartialEq)]
pub(crate) enum AiTacticalStrategy {
    Direct,
    Random,
    #[default]
    Mcts,
}

impl AiProfile {
    /// Creates a profile without a registry or runtime-global mutable state.
    #[must_use]
    pub const fn new(difficulty: AiDifficulty, persona: AiPersona) -> Self {
        Self {
            difficulty,
            persona,
            tactical_strategy: AiTacticalStrategy::Mcts,
            base_seed: 0xA10D_2000,
        }
    }

    pub(crate) const fn with_runtime_configuration(
        mut self,
        tactical_strategy: AiTacticalStrategy,
        seed: i64,
    ) -> Self {
        let seed_bytes = seed.to_le_bytes();
        let low = u32::from_le_bytes([seed_bytes[0], seed_bytes[1], seed_bytes[2], seed_bytes[3]]);
        let high = u32::from_le_bytes([seed_bytes[4], seed_bytes[5], seed_bytes[6], seed_bytes[7]]);
        self.tactical_strategy = tactical_strategy;
        self.base_seed = 0xA10D_2000 ^ low ^ high;
        self
    }

    pub(crate) const fn tactical_strategy(self) -> AiTacticalStrategy {
        self.tactical_strategy
    }
    /// Returns the selected difficulty.
    #[must_use]
    pub const fn difficulty(self) -> AiDifficulty {
        self.difficulty
    }
    /// Returns the selected strategic persona.
    #[must_use]
    pub const fn persona(self) -> AiPersona {
        self.persona
    }
    /// Returns combined persona and difficulty multipliers.
    #[must_use]
    pub const fn weights(self) -> UtilityWeights {
        self.persona
            .weights()
            .multiplied(self.difficulty.weight_multiplier())
    }

    pub(crate) const fn search_seed(self, turn: u32) -> u32 {
        let difficulty = self.difficulty as u32 + 1;
        let persona = self.persona as u32 + 1;
        self.base_seed ^ turn.rotate_left(7) ^ (difficulty << 12) ^ (persona << 4)
    }
}

const fn multiply_basis_points(left: u32, right: u32) -> u32 {
    left.saturating_mul(right) / BASIS_POINTS
}

#[cfg(test)]
mod tests {
    use super::{AiDifficulty, AiPersona, AiProfile, UtilityWeights};

    #[test]
    fn profile_weights_and_search_budgets_change_real_policy_inputs() {
        let balanced = AiProfile::default();
        assert_eq!(
            balanced.weights(),
            UtilityWeights::new(7_800, 10_000, 10_500, 10_000)
        );
        assert_eq!(balanced.difficulty(), AiDifficulty::Normal);
        assert_eq!(balanced.persona(), AiPersona::Balanced);
        assert_eq!(AiDifficulty::Easy.tactical_budget(), None);

        let budgets = [
            AiDifficulty::Normal,
            AiDifficulty::Hard,
            AiDifficulty::VeryHard,
        ]
        .map(|difficulty| difficulty.tactical_budget().expect("searched difficulty"));
        assert_eq!(
            budgets.map(PlanningBudgetView::from),
            [(8, 6, 2), (16, 10, 3), (32, 16, 4)]
        );

        let personas = [
            AiPersona::Aggressive,
            AiPersona::Expansive,
            AiPersona::Economic,
            AiPersona::Scientific,
        ];
        let dominant =
            personas.map(|persona| AiProfile::new(AiDifficulty::VeryHard, persona).weights());
        assert!(dominant[0].aggression() > dominant[0].economy());
        assert!(dominant[1].expansion() > dominant[1].science());
        assert!(dominant[2].economy() > dominant[2].aggression());
        assert!(dominant[3].science() > dominant[3].expansion());
        assert_ne!(balanced.search_seed(3), balanced.search_seed(4));
    }

    struct PlanningBudgetView;

    impl PlanningBudgetView {
        fn from(value: crate::PlanningBudget) -> (u32, u32, u32) {
            (value.iterations(), value.max_nodes(), value.max_depth())
        }
    }
}
