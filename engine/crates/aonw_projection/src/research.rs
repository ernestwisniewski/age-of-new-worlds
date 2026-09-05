use std::collections::BTreeMap;

use aonw_content::{MapDefinition, RulesetDefinition, TechnologyEra};
use aonw_domain::{CityId, GameState, PlayerId, PlayerResearchState, TechnologyId};
use aonw_engine::{
    CanonicalQueryError, EngineContext, GameEngine, GameQuery, QueryResult, ResearchOptionsQuery,
    ScienceYieldSourceKind,
};

/// One positive, engine-owned science contribution visible only to its owner.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerScienceYieldSourceView {
    city_id: CityId,
    amount: i64,
    kind: ScienceYieldSourceKind,
}

impl PlayerScienceYieldSourceView {
    /// Returns the recipient-owned city producing this contribution.
    #[must_use]
    pub const fn city_id(&self) -> &CityId {
        &self.city_id
    }

    /// Returns the exact positive contribution.
    #[must_use]
    pub const fn amount(&self) -> i64 {
        self.amount
    }

    /// Returns the engine-owned contribution category.
    #[must_use]
    pub const fn kind(&self) -> ScienceYieldSourceKind {
        self.kind
    }
}

/// Recipient-owned research progress and current science forecast required by the HUD.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct PlayerResearchView {
    dominant_era: TechnologyEra,
    active_technology_id: Option<TechnologyId>,
    active_progress: Option<i64>,
    active_effective_cost: Option<u32>,
    science_overflow: i64,
    science_per_turn: i64,
    science_by_city_id: BTreeMap<CityId, i64>,
    science_sources: Box<[PlayerScienceYieldSourceView]>,
}

impl PlayerResearchView {
    pub(crate) fn try_for_recipient(
        state: &GameState,
        actor: &PlayerId,
        map: &MapDefinition,
        ruleset: &RulesetDefinition,
    ) -> Result<Self, CanonicalQueryError> {
        let result = GameEngine::query(
            state,
            EngineContext::canonical(actor, map, ruleset),
            GameQuery::ResearchOptions(ResearchOptionsQuery::new(state.revision().get())),
        )?;
        let QueryResult::ResearchOptions(options) = result else {
            unreachable!("research query returned another result kind");
        };
        debug_assert_eq!(options.player_id(), actor);
        let active = options.active_technology().and_then(|technology| {
            options
                .options()
                .iter()
                .find(|option| option.technology() == technology)
                .map(|option| (technology, option.progress(), option.effective_cost()))
        });
        debug_assert_eq!(active.is_some(), options.active_technology().is_some());
        let science = options.science_yield();
        Ok(Self {
            dominant_era: state
                .research()
                .players()
                .get(actor)
                .map_or(TechnologyEra::Foundation, |research| {
                    dominant_era_for_research(research, ruleset)
                }),
            active_technology_id: active.map(|(technology, _, _)| technology),
            active_progress: active.map(|(_, progress, _)| progress),
            active_effective_cost: active.map(|(_, _, cost)| cost),
            science_overflow: options.science_overflow(),
            science_per_turn: science.total(),
            science_by_city_id: science.by_city_id().clone(),
            science_sources: science
                .sources()
                .iter()
                .map(|source| PlayerScienceYieldSourceView {
                    city_id: source.city_id().clone(),
                    amount: source.amount(),
                    kind: source.kind(),
                })
                .collect::<Vec<_>>()
                .into_boxed_slice(),
        })
    }

    #[cfg(test)]
    pub(crate) const fn with_science_per_turn(mut self, amount: i64) -> Self {
        self.science_per_turn = amount;
        self
    }

    /// Returns the highest completed research era belonging to this recipient.
    #[must_use]
    pub const fn dominant_era(&self) -> TechnologyEra {
        self.dominant_era
    }

    /// Returns the selected technology, when research is active.
    #[must_use]
    pub const fn active_technology_id(&self) -> Option<TechnologyId> {
        self.active_technology_id
    }

    /// Returns persisted progress for the active technology.
    #[must_use]
    pub const fn active_progress(&self) -> Option<i64> {
        self.active_progress
    }

    /// Returns the current pace-, city-, and boost-adjusted active cost.
    #[must_use]
    pub const fn active_effective_cost(&self) -> Option<u32> {
        self.active_effective_cost
    }

    /// Returns stored science available after choosing a technology.
    #[must_use]
    pub const fn science_overflow(&self) -> i64 {
        self.science_overflow
    }

    /// Returns the authoritative science forecast for the next research phase.
    #[must_use]
    pub const fn science_per_turn(&self) -> i64 {
        self.science_per_turn
    }

    /// Returns combined positive science contributions in stable city order.
    #[must_use]
    pub const fn science_by_city_id(&self) -> &BTreeMap<CityId, i64> {
        &self.science_by_city_id
    }

    /// Returns the exact engine-owned science sources in calculation order.
    #[must_use]
    pub const fn science_sources(&self) -> &[PlayerScienceYieldSourceView] {
        &self.science_sources
    }
}

pub(crate) fn dominant_era_for_research(
    research: &PlayerResearchState,
    ruleset: &RulesetDefinition,
) -> TechnologyEra {
    research
        .unlocked_technology_ids()
        .iter()
        .filter_map(|id| ruleset.technology(*id))
        .map(aonw_content::TechnologyDefinition::era)
        .max()
        .unwrap_or_default()
}

#[cfg(test)]
mod tests;
