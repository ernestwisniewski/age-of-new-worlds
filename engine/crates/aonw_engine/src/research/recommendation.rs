use std::cmp::Reverse;

use aonw_content::RulesetDefinition;
use aonw_domain::TechnologyId;

use super::ResearchOption;
use crate::TechnologyAvailability;

#[path = "recommendation_priority.rs"]
mod priority;

/// Positive contributions to an authoritative research recommendation.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum ResearchRecommendationReason {
    Boost,
    WorkerYields,
    Unlocks,
    Effects,
    NearCompletion,
}

/// One available technology in the engine's ordered, at-most-three suggestions.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ResearchRecommendation {
    technology: TechnologyId,
    score: i64,
    turns_remaining: Option<i64>,
    reasons: [ResearchRecommendationReason; 5],
    reason_count: usize,
}

impl ResearchRecommendation {
    /// Returns the selectable technology.
    #[must_use]
    pub const fn technology(&self) -> TechnologyId {
        self.technology
    }
    /// Returns the deterministic recommendation score, not a gameplay effect.
    #[must_use]
    pub const fn score(&self) -> i64 {
        self.score
    }
    /// Returns the current science-rate estimate, absent when no estimate exists.
    #[must_use]
    pub const fn turns_remaining(&self) -> Option<i64> {
        self.turns_remaining
    }
    /// Returns positive score contributions in stable presentation order.
    #[must_use]
    pub fn reasons(&self) -> &[ResearchRecommendationReason] {
        &self.reasons[..self.reason_count]
    }
}

pub(super) fn recommend(
    options: &[ResearchOption],
    science_per_turn: i64,
    ruleset: &RulesetDefinition,
) -> Box<[ResearchRecommendation]> {
    let candidates = options
        .iter()
        .filter(|option| option.availability() == TechnologyAvailability::Available)
        .map(|option| {
            let effects = ruleset
                .technology(option.technology())
                .map_or(0, |definition| definition.effects().len());
            score(option, science_per_turn, effects)
        })
        .collect();
    rank(candidates)
}

fn rank(mut candidates: Vec<ResearchRecommendation>) -> Box<[ResearchRecommendation]> {
    candidates.sort_by_key(|entry| {
        (
            Reverse(entry.score),
            entry.turns_remaining.unwrap_or(999),
            priority::catalog_priority(entry.technology),
            entry.technology,
        )
    });
    candidates.truncate(3);
    candidates.into_boxed_slice()
}

fn score(option: &ResearchOption, science: i64, effects: usize) -> ResearchRecommendation {
    use ResearchRecommendationReason as Reason;
    let mut score = 0_i64;
    let mut reasons = [Reason::Boost; 5];
    let mut reason_count = 0;
    let turns = turns_remaining(option, science);
    let contributions = [
        (
            Reason::Boost,
            if option.boost_discount_basis_points() > 0 {
                80
            } else {
                0
            },
        ),
        (
            Reason::WorkerYields,
            if opens_worker_yields(option.technology()) {
                48
            } else {
                0
            },
        ),
        (Reason::Unlocks, weighted_count(option.unlocks().len(), 16)),
        (Reason::Effects, weighted_count(effects, 20)),
        (
            Reason::NearCompletion,
            turns.map_or(0, |value| {
                24_i64.saturating_sub(value.saturating_mul(3)).max(0)
            }),
        ),
    ];
    for (reason, contribution) in contributions {
        if contribution > 0 {
            score = score.saturating_add(contribution);
            reasons[reason_count] = reason;
            reason_count += 1;
        }
    }
    score = score.saturating_sub(i64::from(priority::catalog_priority(option.technology()).0) * 2);
    ResearchRecommendation {
        technology: option.technology(),
        score,
        turns_remaining: turns,
        reasons,
        reason_count,
    }
}

fn weighted_count(count: usize, weight: i64) -> i64 {
    i64::try_from(count)
        .unwrap_or(i64::MAX)
        .saturating_mul(weight)
}

fn turns_remaining(option: &ResearchOption, science: i64) -> Option<i64> {
    let cost = i64::from(option.effective_cost());
    let remaining = cost - option.progress().clamp(0, cost);
    if science <= 0 || remaining <= 0 {
        return None;
    }
    Some(remaining / science + i64::from(remaining % science != 0))
}

const fn opens_worker_yields(technology: TechnologyId) -> bool {
    matches!(
        technology,
        TechnologyId::Agriculture
            | TechnologyId::Mining
            | TechnologyId::Hunting
            | TechnologyId::AnimalHusbandry
            | TechnologyId::Fishing
            | TechnologyId::Woodworking
            | TechnologyId::Stoneworking
    )
}

#[cfg(test)]
#[path = "recommendation_tests.rs"]
mod tests;
