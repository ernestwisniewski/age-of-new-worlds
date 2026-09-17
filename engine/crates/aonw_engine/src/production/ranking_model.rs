use aonw_domain::{CityBuildingType, CityId};

/// Recipient-owned building scores in canonical content order.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ProductionBuildingRanks {
    /// Canonical revision used for both output and completion estimates.
    pub revision: u64,
    /// Controlled city whose territory and production determine the scores.
    pub city_id: CityId,
    /// One score set per building, independent of current command availability.
    pub buildings: Box<[ProductionBuildingRank]>,
}

/// Reference catalog sorting policies, separate from production command legality.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum ProductionBuildingSort {
    /// Strategic output combined with return and time to completion.
    Recommended,
    /// Fewest estimated turns to complete.
    FastestImpact,
    /// Strategic output per turn spent producing.
    BestReturn,
    /// Food, territory and food-deposit improvements.
    Growth,
    /// Production improvements.
    Industry,
    /// Science improvements.
    Science,
    /// Defense and supporting production.
    DefenseMilitary,
    /// Gold and supporting production/science.
    Economy,
}

/// Authoritative priorities; larger scores precede smaller scores.
/// Equal priorities use fewer turns, then the client's localized display name.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ProductionBuildingRank {
    /// Stable content identity.
    pub building: CityBuildingType,
    /// Completion-time tie breaker; unavailable output uses the reference sentinel.
    pub turns_for_score: i64,
    /// Combined strategic output, return and speed.
    pub recommended: i64,
    /// Strategic output per production turn.
    pub best_return: i64,
    /// Growth-focused priority.
    pub growth: i64,
    /// Industry-focused priority.
    pub industry: i64,
    /// Science-focused priority.
    pub science: i64,
    /// Defense-focused priority.
    pub defense_military: i64,
    /// Economy-focused priority.
    pub economy: i64,
}

impl ProductionBuildingRank {
    /// Returns the selected policy's priority. Higher values come first.
    #[must_use]
    pub const fn priority(self, mode: ProductionBuildingSort) -> i64 {
        match mode {
            ProductionBuildingSort::Recommended => self.recommended,
            ProductionBuildingSort::FastestImpact => -self.turns_for_score,
            ProductionBuildingSort::BestReturn => self.best_return,
            ProductionBuildingSort::Growth => self.growth,
            ProductionBuildingSort::Industry => self.industry,
            ProductionBuildingSort::Science => self.science,
            ProductionBuildingSort::DefenseMilitary => self.defense_military,
            ProductionBuildingSort::Economy => self.economy,
        }
    }
}
