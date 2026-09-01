use std::collections::BTreeMap;

use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{GameState, PlayerId};
use aonw_engine::{CanonicalQueryError, EngineContext, calculate_victory_progress};

/// Public territorial victory pressure for one active participant.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerDominationVictoryProgressView {
    player_id: PlayerId,
    controlled_passable_hexes: u32,
    total_passable_hexes: u32,
    hold_turns: u32,
}

impl PlayerDominationVictoryProgressView {
    /// Returns the represented participant.
    #[must_use]
    pub const fn player_id(&self) -> &PlayerId {
        &self.player_id
    }
    /// Returns the exact controlled-territory numerator.
    #[must_use]
    pub const fn controlled_passable_hexes(&self) -> u32 {
        self.controlled_passable_hexes
    }
    /// Returns the exact passable-map denominator.
    #[must_use]
    pub const fn total_passable_hexes(&self) -> u32 {
        self.total_passable_hexes
    }
    /// Returns consecutive turns above the domination threshold.
    #[must_use]
    pub const fn hold_turns(&self) -> u32 {
        self.hold_turns
    }
}

/// Recipient-owned cultural victory pressure.
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub struct PlayerCulturalVictoryProgressView {
    unique_stored_artifacts: u32,
    hold_turns: u32,
}

impl PlayerCulturalVictoryProgressView {
    /// Returns distinct artifact types stored by the recipient.
    #[must_use]
    pub const fn unique_stored_artifacts(self) -> u32 {
        self.unique_stored_artifacts
    }
    /// Returns consecutive turns above the cultural threshold.
    #[must_use]
    pub const fn hold_turns(self) -> u32 {
        self.hold_turns
    }
}

/// Disclosure-filtered hold state for one authored map objective.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerMapObjectiveProgressView {
    objective_id: Box<str>,
    controller_player_id: Option<PlayerId>,
    hold_turns: u32,
}

impl PlayerMapObjectiveProgressView {
    /// Returns the authored objective identifier.
    #[must_use]
    pub const fn objective_id(&self) -> &str {
        &self.objective_id
    }
    /// Returns the controller when recipient disclosure permits it.
    #[must_use]
    pub const fn controller_player_id(&self) -> Option<&PlayerId> {
        self.controller_player_id.as_ref()
    }
    /// Returns the disclosed controller's hold duration.
    #[must_use]
    pub const fn hold_turns(&self) -> u32 {
        self.hold_turns
    }
}

/// Recipient-safe victory rules, live public scores, and current pressure.
#[allow(clippy::struct_excessive_bools)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerVictoryView {
    conquest_enabled: bool,
    domination_enabled: bool,
    domination_required_control_percent: Box<str>,
    domination_required_hold_turns: u32,
    cultural_enabled: bool,
    cultural_required_artifacts: u32,
    cultural_required_hold_turns: u32,
    score_fallback_enabled: bool,
    turn_limit: Option<u32>,
    remaining_turns: Option<u32>,
    score_by_player_id: BTreeMap<PlayerId, i64>,
    domination: Box<[PlayerDominationVictoryProgressView]>,
    own_cultural: PlayerCulturalVictoryProgressView,
    map_objectives: Box<[PlayerMapObjectiveProgressView]>,
}

impl Default for PlayerVictoryView {
    fn default() -> Self {
        Self {
            conquest_enabled: false,
            domination_enabled: false,
            domination_required_control_percent: "60".into(),
            domination_required_hold_turns: 5,
            cultural_enabled: false,
            cultural_required_artifacts: 6,
            cultural_required_hold_turns: 5,
            score_fallback_enabled: false,
            turn_limit: None,
            remaining_turns: None,
            score_by_player_id: BTreeMap::new(),
            domination: Box::new([]),
            own_cultural: PlayerCulturalVictoryProgressView::default(),
            map_objectives: Box::new([]),
        }
    }
}

impl PlayerVictoryView {
    pub(crate) fn try_for_recipient(
        state: &GameState,
        actor: &PlayerId,
        map: &MapDefinition,
        ruleset: &RulesetDefinition,
    ) -> Result<Self, CanonicalQueryError> {
        let progress =
            calculate_victory_progress(state, EngineContext::canonical(actor, map, ruleset))
                .map_err(CanonicalQueryError::Outcome)?;
        Ok(Self {
            conquest_enabled: progress.conquest_enabled(),
            domination_enabled: progress.domination_enabled(),
            domination_required_control_percent: progress
                .domination_required_control_percent()
                .into(),
            domination_required_hold_turns: progress.domination_required_hold_turns(),
            cultural_enabled: progress.cultural_enabled(),
            cultural_required_artifacts: progress.cultural_required_artifacts(),
            cultural_required_hold_turns: progress.cultural_required_hold_turns(),
            score_fallback_enabled: progress.score_fallback_enabled(),
            turn_limit: progress.turn_limit(),
            remaining_turns: progress.remaining_turns(),
            score_by_player_id: progress.score_by_player_id().clone(),
            domination: progress
                .domination()
                .iter()
                .map(|value| PlayerDominationVictoryProgressView {
                    player_id: value.player_id().clone(),
                    controlled_passable_hexes: value.controlled_passable_hexes(),
                    total_passable_hexes: value.total_passable_hexes(),
                    hold_turns: value.hold_turns(),
                })
                .collect::<Vec<_>>()
                .into_boxed_slice(),
            own_cultural: PlayerCulturalVictoryProgressView {
                unique_stored_artifacts: progress.own_cultural().unique_stored_artifacts(),
                hold_turns: progress.own_cultural().hold_turns(),
            },
            map_objectives: progress
                .map_objectives()
                .iter()
                .map(|value| PlayerMapObjectiveProgressView {
                    objective_id: value.objective_id().into(),
                    controller_player_id: value.controller_player_id().cloned(),
                    hold_turns: value.hold_turns(),
                })
                .collect::<Vec<_>>()
                .into_boxed_slice(),
        })
    }

    #[cfg(test)]
    pub(crate) fn with_live_score(mut self, amount: i64) -> Self {
        self.score_by_player_id
            .insert(PlayerId::new("test-player").expect("player id"), amount);
        self
    }

    /// Returns whether conquest victory is enabled.
    #[must_use]
    pub const fn conquest_enabled(&self) -> bool {
        self.conquest_enabled
    }
    /// Returns whether domination victory is enabled.
    #[must_use]
    pub const fn domination_enabled(&self) -> bool {
        self.domination_enabled
    }
    /// Returns the exact configured domination percentage.
    #[must_use]
    pub const fn domination_required_control_percent(&self) -> &str {
        &self.domination_required_control_percent
    }
    /// Returns required consecutive domination turns.
    #[must_use]
    pub const fn domination_required_hold_turns(&self) -> u32 {
        self.domination_required_hold_turns
    }
    /// Returns whether cultural victory is enabled.
    #[must_use]
    pub const fn cultural_enabled(&self) -> bool {
        self.cultural_enabled
    }
    /// Returns required distinct stored artifacts.
    #[must_use]
    pub const fn cultural_required_artifacts(&self) -> u32 {
        self.cultural_required_artifacts
    }
    /// Returns required consecutive cultural turns.
    #[must_use]
    pub const fn cultural_required_hold_turns(&self) -> u32 {
        self.cultural_required_hold_turns
    }
    /// Returns whether score fallback is enabled.
    #[must_use]
    pub const fn score_fallback_enabled(&self) -> bool {
        self.score_fallback_enabled
    }
    /// Returns the optional score turn limit.
    #[must_use]
    pub const fn turn_limit(&self) -> Option<u32> {
        self.turn_limit
    }
    /// Returns remaining turns before score resolution.
    #[must_use]
    pub const fn remaining_turns(&self) -> Option<u32> {
        self.remaining_turns
    }
    /// Returns live public scores in player-ID order.
    #[must_use]
    pub const fn score_by_player_id(&self) -> &BTreeMap<PlayerId, i64> {
        &self.score_by_player_id
    }
    /// Returns public domination pressure in player-ID order.
    #[must_use]
    pub const fn domination(&self) -> &[PlayerDominationVictoryProgressView] {
        &self.domination
    }
    /// Returns recipient-private cultural pressure.
    #[must_use]
    pub const fn own_cultural(&self) -> PlayerCulturalVictoryProgressView {
        self.own_cultural
    }
    /// Returns objective progress in authored objective-ID order.
    #[must_use]
    pub const fn map_objectives(&self) -> &[PlayerMapObjectiveProgressView] {
        &self.map_objectives
    }
}
