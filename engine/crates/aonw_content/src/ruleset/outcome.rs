use serde::Serialize;

/// Immutable empire-score weights used by authoritative outcome resolution.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct OutcomeBalance {
    city_score: u32,
    population_score: u32,
    territory_hex_score: u32,
    building_score: u32,
    technology_score: u32,
    improvement_score: u32,
    experience_point_divisor: u32,
    gold_divisor: u32,
    maximum_gold_score: u32,
}

impl OutcomeBalance {
    pub(super) const STANDARD: Self = Self {
        city_score: 40,
        population_score: 12,
        territory_hex_score: 3,
        building_score: 8,
        technology_score: 18,
        improvement_score: 5,
        experience_point_divisor: 5,
        gold_divisor: 50,
        maximum_gold_score: 200,
    };

    /// Returns score awarded for each owned city.
    #[must_use]
    pub const fn city_score(self) -> u32 {
        self.city_score
    }
    /// Returns score awarded for each population point.
    #[must_use]
    pub const fn population_score(self) -> u32 {
        self.population_score
    }
    /// Returns score awarded for each controlled territory hex.
    #[must_use]
    pub const fn territory_hex_score(self) -> u32 {
        self.territory_hex_score
    }
    /// Returns score awarded for each completed city building.
    #[must_use]
    pub const fn building_score(self) -> u32 {
        self.building_score
    }
    /// Returns score awarded for each unlocked technology.
    #[must_use]
    pub const fn technology_score(self) -> u32 {
        self.technology_score
    }
    /// Returns score awarded for each owned field improvement.
    #[must_use]
    pub const fn improvement_score(self) -> u32 {
        self.improvement_score
    }
    /// Returns the divisor applied to unit experience points.
    #[must_use]
    pub const fn experience_point_divisor(self) -> u32 {
        self.experience_point_divisor
    }
    /// Returns gold units represented by one score point.
    #[must_use]
    pub const fn gold_divisor(self) -> u32 {
        self.gold_divisor
    }
    /// Returns the maximum score contributed by gold.
    #[must_use]
    pub const fn maximum_gold_score(self) -> u32 {
        self.maximum_gold_score
    }
}
