use aonw_domain::{DiplomaticRelationStatus, UnitKind};
use aonw_local_runtime::PlayerViewSnapshot;

use crate::{AiProfile, UtilityWeights};

const MAX_UTILITY: i64 = 1_000_000;

/// Bounded fixed-point utility used for deterministic comparisons.
#[derive(Clone, Copy, Debug, Default, Eq, Ord, PartialEq, PartialOrd)]
pub struct UtilityScore(i64);

impl UtilityScore {
    /// Creates a score clamped to the reviewed arithmetic envelope.
    #[must_use]
    pub const fn new(value: i64) -> Self {
        if value < -MAX_UTILITY {
            Self(-MAX_UTILITY)
        } else if value > MAX_UTILITY {
            Self(MAX_UTILITY)
        } else {
            Self(value)
        }
    }
    /// Returns the bounded raw comparison value.
    #[must_use]
    pub const fn get(self) -> i64 {
        self.0
    }
}

/// Coarse strategic posture selected from recipient-safe information.
#[derive(Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub enum StrategicMode {
    /// Acquire the first cities and additional territory.
    Expand,
    /// Repair worker or military deficits around owned cities.
    Consolidate,
    /// Respond to visible or diplomatic military pressure.
    Military,
    /// Prefer research when the empire is otherwise stable.
    TechRush,
}

/// Stable goal vocabulary shared by strategic and tactical scoring.
#[derive(Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub enum StrategicGoal {
    /// Preserve cities and counter hostile pressure.
    Defend,
    /// Found cities and reveal useful territory.
    Expand,
    /// Close worker and infrastructure deficits.
    DevelopEconomy,
    /// Improve the technology position.
    AdvanceScience,
}

/// One goal and its comparable bounded utility.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct GoalPriority {
    goal: StrategicGoal,
    utility: UtilityScore,
}

impl GoalPriority {
    /// Returns the goal identity.
    #[must_use]
    pub const fn goal(self) -> StrategicGoal {
        self.goal
    }
    /// Returns its bounded utility.
    #[must_use]
    pub const fn utility(self) -> UtilityScore {
        self.utility
    }
}

/// Compact recipient-safe facts used by every policy family.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct EmpireAssessment {
    city_count: u32,
    population: i64,
    worker_count: u32,
    settler_count: u32,
    military_count: u32,
    visible_enemy_military_count: u32,
    hostile_relation_count: u32,
    desired_city_count: u32,
    desired_worker_count: u32,
    desired_military_count: u32,
}

impl EmpireAssessment {
    /// Returns the number of controlled cities.
    #[must_use]
    pub const fn city_count(self) -> u32 {
        self.city_count
    }
    /// Returns the known total controlled population.
    #[must_use]
    pub const fn population(self) -> i64 {
        self.population
    }
    /// Returns controlled or queued worker demand evidence.
    #[must_use]
    pub const fn worker_count(self) -> u32 {
        self.worker_count
    }
    /// Returns controlled city founders.
    #[must_use]
    pub const fn settler_count(self) -> u32 {
        self.settler_count
    }
    /// Returns controlled military units.
    #[must_use]
    pub const fn military_count(self) -> u32 {
        self.military_count
    }
    /// Returns currently visible foreign military units.
    #[must_use]
    pub const fn visible_enemy_military_count(self) -> u32 {
        self.visible_enemy_military_count
    }
    /// Returns hostile or war relations visible to the recipient.
    #[must_use]
    pub const fn hostile_relation_count(self) -> u32 {
        self.hostile_relation_count
    }
    /// Returns whether another founder improves the current expansion target.
    #[must_use]
    pub const fn needs_settler(self) -> bool {
        self.city_count.saturating_add(self.settler_count) < self.desired_city_count
    }
    /// Returns whether controlled workers are below the city-scaled target.
    #[must_use]
    pub const fn needs_worker(self) -> bool {
        self.worker_count < self.desired_worker_count
    }
    /// Returns whether military strength is below the threat-adjusted target.
    #[must_use]
    pub const fn needs_military(self) -> bool {
        self.military_count < self.desired_military_count
    }
}

/// Hierarchical strategic result: empire facts, selected mode, and ordered goals.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct StrategicAssessment {
    empire: EmpireAssessment,
    mode: StrategicMode,
    goals: [GoalPriority; 4],
}

impl StrategicAssessment {
    /// Assesses one revision-bound recipient view with an explicit profile.
    #[must_use]
    pub fn from_snapshot(snapshot: &PlayerViewSnapshot, profile: AiProfile) -> Self {
        let actor = snapshot.recipient_player_id();
        let weights = profile.weights();
        let city_count = count(
            snapshot
                .cities()
                .iter()
                .filter(|city| city.owner_player_id() == actor),
        );
        let population = snapshot
            .cities()
            .iter()
            .filter(|city| city.owner_player_id() == actor)
            .filter_map(aonw_local_runtime::PlayerCityView::owned_details)
            .map(aonw_local_runtime::OwnedCityDetailsView::population)
            .sum();
        let worker_count = count(
            snapshot
                .units()
                .iter()
                .filter(|unit| unit.owner_player_id() == actor && unit.kind() == UnitKind::Worker),
        );
        let settler_count =
            count(snapshot.units().iter().filter(|unit| {
                unit.owner_player_id() == actor && unit.kind() == UnitKind::Settler
            }));
        let military_count = count(
            snapshot
                .units()
                .iter()
                .filter(|unit| unit.owner_player_id() == actor && is_military(unit.kind())),
        );
        let visible_enemy_military_count = count(
            snapshot
                .units()
                .iter()
                .filter(|unit| unit.owner_player_id() != actor && is_military(unit.kind())),
        );
        let hostile_relation_count =
            count(snapshot.diplomacy().relations().iter().filter(|relation| {
                matches!(
                    relation.status(),
                    DiplomaticRelationStatus::Hostile | DiplomaticRelationStatus::War
                )
            }));
        let desired_city_count = desired_city_count(snapshot.turn(), weights);
        let desired_worker_count = city_count;
        let desired_military_count = city_count
            .max(1)
            .saturating_add(visible_enemy_military_count);
        let empire = EmpireAssessment {
            city_count,
            population,
            worker_count,
            settler_count,
            military_count,
            visible_enemy_military_count,
            hostile_relation_count,
            desired_city_count,
            desired_worker_count,
            desired_military_count,
        };
        let mut goals = score_goals(empire, weights);
        goals.sort_unstable_by(|left, right| {
            right
                .utility
                .cmp(&left.utility)
                .then_with(|| left.goal.cmp(&right.goal))
        });
        let mode = mode_for(goals[0].goal, weights);
        Self {
            empire,
            mode,
            goals,
        }
    }

    /// Returns the assessed empire facts.
    #[must_use]
    pub const fn empire(&self) -> EmpireAssessment {
        self.empire
    }
    /// Returns the selected strategic posture.
    #[must_use]
    pub const fn mode(&self) -> StrategicMode {
        self.mode
    }
    /// Returns all goals in descending utility order.
    #[must_use]
    pub const fn goals(&self) -> &[GoalPriority; 4] {
        &self.goals
    }
    /// Returns the highest-utility goal.
    #[must_use]
    pub const fn primary_goal(&self) -> GoalPriority {
        self.goals[0]
    }
}

pub(crate) const fn is_military(kind: UnitKind) -> bool {
    !matches!(
        kind,
        UnitKind::Settler | UnitKind::Worker | UnitKind::Merchant | UnitKind::Scout
    )
}

fn score_goals(empire: EmpireAssessment, weights: UtilityWeights) -> [GoalPriority; 4] {
    let defense_gap = empire
        .desired_military_count
        .saturating_sub(empire.military_count);
    let expansion_gap = empire
        .desired_city_count
        .saturating_sub(empire.city_count.saturating_add(empire.settler_count));
    let worker_gap = empire
        .desired_worker_count
        .saturating_sub(empire.worker_count);
    [
        priority(
            StrategicGoal::Defend,
            weights.aggression(),
            defense_gap.saturating_add(empire.hostile_relation_count),
        ),
        priority(StrategicGoal::Expand, weights.expansion(), expansion_gap),
        priority(StrategicGoal::DevelopEconomy, weights.economy(), worker_gap),
        priority(StrategicGoal::AdvanceScience, weights.science(), 0),
    ]
}

fn priority(goal: StrategicGoal, weight: u32, deficit: u32) -> GoalPriority {
    GoalPriority {
        goal,
        utility: UtilityScore::new(i64::from(weight) + i64::from(deficit) * 20_000),
    }
}

fn mode_for(goal: StrategicGoal, weights: UtilityWeights) -> StrategicMode {
    match goal {
        StrategicGoal::Defend => StrategicMode::Military,
        StrategicGoal::Expand => StrategicMode::Expand,
        StrategicGoal::AdvanceScience if weights.science() >= 12_000 => StrategicMode::TechRush,
        StrategicGoal::DevelopEconomy | StrategicGoal::AdvanceScience => StrategicMode::Consolidate,
    }
}

fn desired_city_count(turn: u32, weights: UtilityWeights) -> u32 {
    let persona = u32::from(weights.expansion() >= 12_000);
    2_u32
        .saturating_add(turn / 25)
        .saturating_add(persona)
        .min(6)
}

fn count<'a, T: 'a>(values: impl Iterator<Item = &'a T>) -> u32 {
    u32::try_from(values.count()).unwrap_or(u32::MAX)
}

#[cfg(test)]
mod tests {
    use super::{StrategicGoal, UtilityScore, desired_city_count, mode_for, priority};
    use crate::{AiDifficulty, AiPersona, AiProfile, StrategicMode};

    #[test]
    fn utility_is_bounded_and_goal_modes_are_explicit() {
        assert_eq!(UtilityScore::new(i64::MAX).get(), 1_000_000);
        assert_eq!(UtilityScore::new(i64::MIN).get(), -1_000_000);
        let weights = AiProfile::new(AiDifficulty::VeryHard, AiPersona::Scientific).weights();
        assert_eq!(
            mode_for(StrategicGoal::AdvanceScience, weights),
            StrategicMode::TechRush
        );
        assert_eq!(
            mode_for(StrategicGoal::Defend, weights),
            StrategicMode::Military
        );
        assert_eq!(
            mode_for(StrategicGoal::Expand, weights),
            StrategicMode::Expand
        );
        assert_eq!(
            mode_for(StrategicGoal::DevelopEconomy, weights),
            StrategicMode::Consolidate
        );
        assert_eq!(
            priority(StrategicGoal::Defend, 10_000, 2).utility().get(),
            50_000
        );
        assert_eq!(desired_city_count(50, weights), 4);
    }
}
