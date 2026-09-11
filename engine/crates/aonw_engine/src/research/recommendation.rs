use std::cmp::Reverse;
use std::num::NonZeroU32;

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
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ResearchRecommendation {
    technology: TechnologyId,
    score: i64,
    turns_remaining: Option<NonZeroU32>,
    reasons: u8,
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
    pub fn turns_remaining(&self) -> Option<i64> {
        self.turns_remaining.map(|turns| i64::from(turns.get()))
    }
    /// Returns positive score contributions in stable presentation order.
    pub fn reasons(&self) -> impl Iterator<Item = ResearchRecommendationReason> + '_ {
        use ResearchRecommendationReason as Reason;
        [
            Reason::Boost,
            Reason::WorkerYields,
            Reason::Unlocks,
            Reason::Effects,
            Reason::NearCompletion,
        ]
        .into_iter()
        .filter(|reason| self.reasons & (1 << *reason as u8) != 0)
    }
}

pub(super) fn recommend(
    options: &[ResearchOption],
    science_per_turn: i64,
    ruleset: &RulesetDefinition,
) -> ResearchRecommendations {
    let candidates = options
        .iter()
        .filter(|option| option.availability() == TechnologyAvailability::Available)
        .map(|option| {
            let effects = ruleset
                .technology(option.technology())
                .map_or(0, |definition| definition.effects().len());
            score(option, science_per_turn, effects)
        });
    rank(candidates)
}

/// Fixed-capacity result: ranking never allocates per query or candidate.
#[derive(Clone, Debug, Eq, PartialEq)]
pub(crate) struct ResearchRecommendations {
    values: [ResearchRecommendation; 3],
    len: usize,
}

impl std::ops::Deref for ResearchRecommendations {
    type Target = [ResearchRecommendation];
    fn deref(&self) -> &Self::Target {
        &self.values[..self.len]
    }
}

fn rank(candidates: impl IntoIterator<Item = ResearchRecommendation>) -> ResearchRecommendations {
    let empty = ResearchRecommendation {
        technology: TechnologyId::Agriculture,
        score: 0,
        turns_remaining: None,
        reasons: 0,
    };
    let mut result = ResearchRecommendations {
        values: [empty; 3],
        len: 0,
    };
    for candidate in candidates {
        let index = result
            .iter()
            .position(|entry| priority_key(&candidate) < priority_key(entry))
            .unwrap_or(result.len);
        if index >= 3 {
            continue;
        }
        for slot in (index..result.len.min(2)).rev() {
            result.values[slot + 1] = result.values[slot];
        }
        result.values[index] = candidate;
        result.len = (result.len + 1).min(3);
    }
    result
}

fn priority_key(entry: &ResearchRecommendation) -> (Reverse<i64>, i64, (u8, u8), TechnologyId) {
    (
        Reverse(entry.score),
        entry.turns_remaining().unwrap_or(999),
        priority::catalog_priority(entry.technology),
        entry.technology,
    )
}

fn score(option: &ResearchOption, science: i64, effects: usize) -> ResearchRecommendation {
    use ResearchRecommendationReason as Reason;
    let mut score = 0_i64;
    let mut reasons = 0;
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
            reasons |= 1 << reason as u8;
        }
    }
    score = score.saturating_sub(i64::from(priority::catalog_priority(option.technology()).0) * 2);
    ResearchRecommendation {
        technology: option.technology(),
        score,
        turns_remaining: turns
            .and_then(|value| u32::try_from(value).ok())
            .and_then(NonZeroU32::new),
        reasons,
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
