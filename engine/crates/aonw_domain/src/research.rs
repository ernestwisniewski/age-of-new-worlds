use std::collections::{BTreeMap, BTreeSet};

use crate::{MatchIdentity, PlayerId, WonderType};

mod errors;

pub use errors::{
    KnowledgeStateValidationError, PlayerResearchStateBuildError, ResearchTransitionError,
    WonderCompletionError,
};

/// Stable identity of one technology in the current ruleset.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub enum TechnologyId {
    Agriculture,
    Woodworking,
    Mining,
    AnimalHusbandry,
    Hunting,
    Fishing,
    Craftsmanship,
    Trade,
    Storage,
    WaterEngineering,
    Stoneworking,
    MilitaryOrganization,
    AdvancedTrade,
    Construction,
    Navigation,
    Irrigation,
    Banking,
    Engineering,
    Metallurgy,
    HorsebackRiding,
    IronWorking,
    CoalMining,
    Machinery,
    Administration,
    Logistics,
    Shipbuilding,
    Tactics,
    Economy,
    Urbanization,
    Fortifications,
    Strategy,
    Specialization,
    Writing,
    Mathematics,
    Medicine,
    CivilService,
    Siegecraft,
    Cartography,
    Guilds,
    Law,
    Education,
    UrbanPlanning,
    NavalDoctrine,
    Steel,
    Bureaucracy,
    Nationalism,
    ScientificMethod,
    SteamPower,
    Electricity,
    Combustion,
    Flight,
    MassProduction,
    Radio,
    NuclearPhysics,
}

/// One player's canonical research selection and progress.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct PlayerResearchState {
    unlocked_technology_ids: BTreeSet<TechnologyId>,
    active_technology_id: Option<TechnologyId>,
    progress_by_technology_id: BTreeMap<TechnologyId, i64>,
    science_overflow: i64,
}

impl PlayerResearchState {
    /// Validates canonical research collections and counters.
    ///
    /// # Errors
    ///
    /// Returns an error for duplicates, non-positive progress, inconsistent
    /// unlocked state, or negative overflow.
    pub fn try_new(
        unlocked_technology_ids: impl IntoIterator<Item = TechnologyId>,
        active_technology_id: Option<TechnologyId>,
        progress_by_technology_id: impl IntoIterator<Item = (TechnologyId, i64)>,
        science_overflow: i64,
    ) -> Result<Self, PlayerResearchStateBuildError> {
        let mut unlocked = BTreeSet::new();
        for technology in unlocked_technology_ids {
            if !unlocked.insert(technology) {
                return Err(PlayerResearchStateBuildError::DuplicateUnlocked(technology));
            }
        }
        if let Some(active) = active_technology_id
            && unlocked.contains(&active)
        {
            return Err(PlayerResearchStateBuildError::ActiveAlreadyUnlocked(active));
        }
        let mut progress = BTreeMap::new();
        for (technology, amount) in progress_by_technology_id {
            if amount <= 0 {
                return Err(PlayerResearchStateBuildError::NonPositiveProgress {
                    technology,
                    amount,
                });
            }
            if unlocked.contains(&technology) {
                return Err(PlayerResearchStateBuildError::ProgressForUnlocked(
                    technology,
                ));
            }
            if progress.insert(technology, amount).is_some() {
                return Err(PlayerResearchStateBuildError::DuplicateProgress(technology));
            }
        }
        if science_overflow < 0 {
            return Err(PlayerResearchStateBuildError::NegativeScienceOverflow(
                science_overflow,
            ));
        }
        Ok(Self {
            unlocked_technology_ids: unlocked,
            active_technology_id,
            progress_by_technology_id: progress,
            science_overflow,
        })
    }

    /// Returns unlocked technologies in stable identity order.
    #[must_use]
    pub const fn unlocked_technology_ids(&self) -> &BTreeSet<TechnologyId> {
        &self.unlocked_technology_ids
    }

    /// Returns the currently selected technology.
    #[must_use]
    pub const fn active_technology_id(&self) -> Option<TechnologyId> {
        self.active_technology_id
    }

    /// Returns positive progress entries in stable identity order.
    #[must_use]
    pub const fn progress_by_technology_id(&self) -> &BTreeMap<TechnologyId, i64> {
        &self.progress_by_technology_id
    }

    /// Returns stored non-negative science overflow.
    #[must_use]
    pub const fn science_overflow(&self) -> i64 {
        self.science_overflow
    }

    /// Selects one incomplete technology and applies at most the supplied
    /// amount of stored overflow to its existing progress.
    ///
    /// Applied overflow is consumed even when the cap is zero. Availability,
    /// prerequisites, and the exact cap remain ruleset-owned engine decisions.
    ///
    /// # Errors
    ///
    /// Returns an error when the technology is already unlocked or progress
    /// addition exceeds the canonical integer range.
    pub fn try_after_selecting(
        &self,
        technology: TechnologyId,
        overflow_cap: i64,
    ) -> Result<Self, ResearchTransitionError> {
        if self.unlocked_technology_ids.contains(&technology) {
            return Err(ResearchTransitionError::TechnologyAlreadyUnlocked(
                technology,
            ));
        }
        let applied_overflow = self.science_overflow.min(overflow_cap.max(0));
        let current_progress = self
            .progress_by_technology_id
            .get(&technology)
            .copied()
            .unwrap_or(0);
        let selected_progress = current_progress
            .checked_add(applied_overflow)
            .ok_or(ResearchTransitionError::ProgressOverflow(technology))?;
        let mut updated = self.clone();
        updated.active_technology_id = Some(technology);
        updated.science_overflow = 0;
        if selected_progress > 0 {
            updated
                .progress_by_technology_id
                .insert(technology, selected_progress);
        }
        Ok(updated)
    }

    /// Clears an invalidated active selection while preserving its progress.
    #[must_use]
    pub fn without_active_technology(&self) -> Self {
        let mut updated = self.clone();
        updated.active_technology_id = None;
        updated
    }

    /// Applies checked per-turn science to the current selection.
    ///
    /// Completion unlocks exactly one technology, clears its progress and
    /// stores only the newly produced excess as overflow. With no active
    /// selection or zero science the state is unchanged.
    ///
    /// # Errors
    ///
    /// Returns an error for negative science, a zero effective cost, or
    /// progress arithmetic overflow.
    pub fn try_after_science(
        &self,
        science: i64,
        effective_cost: u32,
    ) -> Result<(Self, Option<TechnologyId>), ResearchTransitionError> {
        if science < 0 {
            return Err(ResearchTransitionError::NegativeScience(science));
        }
        let Some(active) = self.active_technology_id else {
            return Ok((self.clone(), None));
        };
        if effective_cost == 0 {
            return Err(ResearchTransitionError::ZeroEffectiveCost(active));
        }
        if science == 0 {
            return Ok((self.clone(), None));
        }
        let progress = self
            .progress_by_technology_id
            .get(&active)
            .copied()
            .unwrap_or(0)
            .checked_add(science)
            .ok_or(ResearchTransitionError::ProgressOverflow(active))?;
        let cost = i64::from(effective_cost);
        let mut updated = self.clone();
        if progress < cost {
            updated.progress_by_technology_id.insert(active, progress);
            return Ok((updated, None));
        }
        updated.unlocked_technology_ids.insert(active);
        updated.active_technology_id = None;
        updated.progress_by_technology_id.remove(&active);
        updated.science_overflow = progress - cost;
        Ok((updated, Some(active)))
    }

    /// Completes the selected technology while preserving unrelated progress.
    ///
    /// Returns the unchanged state and `None` when no technology is selected.
    #[must_use]
    pub fn after_unlocking_active(&self) -> (Self, Option<TechnologyId>) {
        let Some(active) = self.active_technology_id else {
            return (self.clone(), None);
        };
        let mut updated = self.clone();
        updated.unlocked_technology_ids.insert(active);
        updated.active_technology_id = None;
        updated.progress_by_technology_id.remove(&active);
        (updated, Some(active))
    }
}

/// Canonical research state keyed by player identity.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct ResearchState {
    players: BTreeMap<PlayerId, PlayerResearchState>,
}

impl ResearchState {
    /// Constructs deterministic per-player research state.
    ///
    /// # Errors
    ///
    /// Returns a duplicated player identity.
    pub fn try_new(
        players: impl IntoIterator<Item = (PlayerId, PlayerResearchState)>,
    ) -> Result<Self, PlayerId> {
        let mut values = BTreeMap::new();
        for (player, state) in players {
            if values.insert(player.clone(), state).is_some() {
                return Err(player);
            }
        }
        Ok(Self { players: values })
    }

    /// Returns player research in stable player-id order.
    #[must_use]
    pub const fn players(&self) -> &BTreeMap<PlayerId, PlayerResearchState> {
        &self.players
    }

    /// Replaces one participant's canonical research state.
    #[must_use]
    pub fn updating_player(&self, player: PlayerId, research: PlayerResearchState) -> Self {
        let mut players = self.players.clone();
        players.insert(player, research);
        Self { players }
    }
}

/// Globally completed wonders keyed by wonder identity.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct WonderRegistry {
    completed_by: BTreeMap<WonderType, PlayerId>,
}

impl WonderRegistry {
    /// Constructs a deterministic completed-wonder registry.
    ///
    /// # Errors
    ///
    /// Returns a duplicated wonder identity.
    pub fn try_new(
        completed_by: impl IntoIterator<Item = (WonderType, PlayerId)>,
    ) -> Result<Self, WonderType> {
        let mut values = BTreeMap::new();
        for (wonder, player) in completed_by {
            if values.insert(wonder, player).is_some() {
                return Err(wonder);
            }
        }
        Ok(Self {
            completed_by: values,
        })
    }

    /// Returns completed wonders in stable wonder order.
    #[must_use]
    pub const fn completed_by(&self) -> &BTreeMap<WonderType, PlayerId> {
        &self.completed_by
    }

    /// Records one globally unique wonder completion atomically.
    ///
    /// # Errors
    ///
    /// Returns the existing owner when the wonder was already completed.
    pub fn try_with_completed(
        &self,
        wonder: WonderType,
        player: PlayerId,
    ) -> Result<Self, WonderCompletionError> {
        if let Some(existing_owner) = self.completed_by.get(&wonder) {
            return Err(WonderCompletionError {
                wonder,
                existing_owner: existing_owner.clone(),
            });
        }
        let mut updated = self.clone();
        updated.completed_by.insert(wonder, player);
        Ok(updated)
    }
}

/// Research and global wonder state validated as one canonical component.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct KnowledgeState {
    research: ResearchState,
    wonder_registry: WonderRegistry,
}

impl KnowledgeState {
    /// Constructs a complete knowledge-state component.
    #[must_use]
    pub const fn new(research: ResearchState, wonder_registry: WonderRegistry) -> Self {
        Self {
            research,
            wonder_registry,
        }
    }

    /// Returns per-player research state.
    #[must_use]
    pub const fn research(&self) -> &ResearchState {
        &self.research
    }

    /// Returns globally completed wonders.
    #[must_use]
    pub const fn wonder_registry(&self) -> &WonderRegistry {
        &self.wonder_registry
    }

    /// Replaces the globally completed-wonder registry.
    #[must_use]
    pub fn with_wonder_registry(&self, wonder_registry: WonderRegistry) -> Self {
        Self {
            research: self.research.clone(),
            wonder_registry,
        }
    }

    /// Replaces per-player research while preserving global wonder ownership.
    #[must_use]
    pub fn with_research(&self, research: ResearchState) -> Self {
        Self {
            research,
            wonder_registry: self.wonder_registry.clone(),
        }
    }

    /// Validates all player references against match identity.
    ///
    /// # Errors
    ///
    /// Returns the first player reference absent from match participants.
    pub fn validate_for(
        &self,
        identity: &MatchIdentity,
    ) -> Result<(), KnowledgeStateValidationError> {
        for player in self.research.players().keys() {
            if !identity.contains(player) {
                return Err(KnowledgeStateValidationError::ResearchPlayerNotFound(
                    player.clone(),
                ));
            }
        }
        for (wonder, player) in self.wonder_registry.completed_by() {
            if !identity.contains(player) {
                return Err(KnowledgeStateValidationError::WonderOwnerNotFound {
                    wonder: *wonder,
                    player_id: player.clone(),
                });
            }
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests;
