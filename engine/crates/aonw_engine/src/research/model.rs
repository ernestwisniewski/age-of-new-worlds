use aonw_content::TechnologyUnlock;
use aonw_domain::{PlayerId, TechnologyId};

use crate::{ScienceYieldBreakdown, TechnologyAvailability};

/// Revision-bound selection of one active research target.
#[derive(Clone, Copy, Debug)]
pub struct SelectTechnologyCommand {
    expected_revision: u64,
    technology: TechnologyId,
}

impl SelectTechnologyCommand {
    /// Creates a current authenticated research command.
    #[must_use]
    pub const fn new(expected_revision: u64, technology: TechnologyId) -> Self {
        Self {
            expected_revision,
            technology,
        }
    }

    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }

    pub(crate) const fn technology(self) -> TechnologyId {
        self.technology
    }
}

/// Revision-bound query for all engine-owned technology choices of the actor.
#[derive(Clone, Copy, Debug)]
pub struct ResearchOptionsQuery {
    expected_revision: u64,
}

impl ResearchOptionsQuery {
    /// Creates the query.
    #[must_use]
    pub const fn new(expected_revision: u64) -> Self {
        Self { expected_revision }
    }

    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
}

/// One technology's complete current selection view.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ResearchOption {
    technology: TechnologyId,
    availability: TechnologyAvailability,
    effective_cost: u32,
    progress: i64,
    boost_discount_basis_points: u32,
    prerequisites: Box<[TechnologyId]>,
    blocked_by: Box<[TechnologyId]>,
    unlocks: Box<[TechnologyUnlock]>,
}

impl ResearchOption {
    #[allow(clippy::too_many_arguments)]
    pub(crate) fn new(
        technology: TechnologyId,
        availability: TechnologyAvailability,
        effective_cost: u32,
        progress: i64,
        boost_discount_basis_points: u32,
        prerequisites: impl Into<Box<[TechnologyId]>>,
        blocked_by: impl Into<Box<[TechnologyId]>>,
        unlocks: impl Into<Box<[TechnologyUnlock]>>,
    ) -> Self {
        Self {
            technology,
            availability,
            effective_cost,
            progress,
            boost_discount_basis_points,
            prerequisites: prerequisites.into(),
            blocked_by: blocked_by.into(),
            unlocks: unlocks.into(),
        }
    }

    /// Returns the canonical technology identity.
    #[must_use]
    pub const fn technology(&self) -> TechnologyId {
        self.technology
    }
    /// Returns exact current availability.
    #[must_use]
    pub const fn availability(&self) -> TechnologyAvailability {
        self.availability
    }
    /// Returns the exact pace-, city-, and boost-adjusted cost.
    #[must_use]
    pub const fn effective_cost(&self) -> u32 {
        self.effective_cost
    }
    /// Returns persisted progress for this technology.
    #[must_use]
    pub const fn progress(&self) -> i64 {
        self.progress
    }
    /// Returns the best currently fulfilled boost discount.
    #[must_use]
    pub const fn boost_discount_basis_points(&self) -> u32 {
        self.boost_discount_basis_points
    }
    /// Returns prerequisite identities in catalog order.
    #[must_use]
    pub const fn prerequisites(&self) -> &[TechnologyId] {
        &self.prerequisites
    }
    /// Returns mutually exclusive completed identities in catalog order.
    #[must_use]
    pub const fn blocked_by(&self) -> &[TechnologyId] {
        &self.blocked_by
    }
    /// Returns the ruleset-owned capability breakdown.
    #[must_use]
    pub const fn unlocks(&self) -> &[TechnologyUnlock] {
        &self.unlocks
    }
}

/// Complete actor-owned research selection view.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ResearchOptions {
    player_id: PlayerId,
    active_technology: Option<TechnologyId>,
    science_overflow: i64,
    science_yield: ScienceYieldBreakdown,
    options: Box<[ResearchOption]>,
}

impl ResearchOptions {
    pub(crate) fn new(
        player_id: PlayerId,
        active_technology: Option<TechnologyId>,
        science_overflow: i64,
        science_yield: ScienceYieldBreakdown,
        options: impl Into<Box<[ResearchOption]>>,
    ) -> Self {
        Self {
            player_id,
            active_technology,
            science_overflow,
            science_yield,
            options: options.into(),
        }
    }

    /// Returns the authenticated owner.
    #[must_use]
    pub const fn player_id(&self) -> &PlayerId {
        &self.player_id
    }
    /// Returns the current selected technology.
    #[must_use]
    pub const fn active_technology(&self) -> Option<TechnologyId> {
        self.active_technology
    }
    /// Returns stored science available for the next selection.
    #[must_use]
    pub const fn science_overflow(&self) -> i64 {
        self.science_overflow
    }
    /// Returns the engine-owned current per-turn science preview.
    #[must_use]
    pub const fn science_yield(&self) -> &ScienceYieldBreakdown {
        &self.science_yield
    }
    /// Returns every technology in immutable catalog order.
    #[must_use]
    pub const fn options(&self) -> &[ResearchOption] {
        &self.options
    }
}
