use aonw_domain::PlayerId;

use super::{DominationVictoryProgress, VictoryProgress};

/// The authoritative victory condition emphasized by the compact HUD.
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub enum VictoryStatusKind {
    /// No applicable victory condition is configured.
    #[default]
    None,
    /// Eliminate the remaining opponents.
    Conquest,
    /// Territorial control and its consecutive hold duration.
    Domination,
    /// The recipient's private artifact collection.
    Culture,
    /// The public turn limit and score resolution.
    Score,
}

/// Recipient-safe priority and warning state; numbers remain in the progress view.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct VictoryStatus<'a> {
    kind: VictoryStatusKind,
    critical: bool,
    leader_player_id: Option<&'a PlayerId>,
}

impl<'a> VictoryStatus<'a> {
    /// Returns the condition to emphasize.
    #[must_use]
    pub const fn kind(self) -> VictoryStatusKind {
        self.kind
    }
    /// Returns whether the HUD should show a warning.
    #[must_use]
    pub const fn critical(self) -> bool {
        self.critical
    }
    /// Returns the disclosed leader, or no identity for a score tie or no leader.
    #[must_use]
    pub const fn leader_player_id(self) -> Option<&'a PlayerId> {
        self.leader_player_id
    }
}

impl VictoryProgress {
    /// Selects the compact HUD condition from already disclosed progress.
    /// Rival cultural collections are deliberately unavailable to this policy.
    #[must_use]
    pub fn status<'a>(&'a self, actor: &'a PlayerId) -> VictoryStatus<'a> {
        if self.remaining_turns.is_some_and(|turns| turns <= 5) {
            return self.score_status();
        }
        let domination = self.domination_leader(None);
        let culture = self.cultural_enabled && self.own_cultural.unique_stored_artifacts > 0;
        if culture && self.culture_before(domination) {
            return VictoryStatus {
                kind: VictoryStatusKind::Culture,
                critical: self.own_cultural.hold_turns > 0,
                leader_player_id: Some(actor),
            };
        }
        if let Some(leader) = domination {
            return VictoryStatus {
                kind: VictoryStatusKind::Domination,
                critical: self
                    .domination_leader(Some(actor))
                    .is_some_and(|opponent| self.opponent_threat(opponent)),
                leader_player_id: Some(&leader.player_id),
            };
        }
        if self.remaining_turns.is_some() {
            return self.score_status();
        }
        VictoryStatus {
            kind: if self.conquest_enabled {
                VictoryStatusKind::Conquest
            } else {
                VictoryStatusKind::None
            },
            critical: false,
            leader_player_id: None,
        }
    }

    fn domination_leader(&self, excluded: Option<&PlayerId>) -> Option<&DominationVictoryProgress> {
        if !self.domination_enabled {
            return None;
        }
        self.domination
            .iter()
            .filter(|entry| entry.total_passable_hexes > 0 && excluded != Some(&entry.player_id))
            .max_by(|left, right| {
                left.controlled_passable_hexes
                    .cmp(&right.controlled_passable_hexes)
                    .then_with(|| left.hold_turns.cmp(&right.hold_turns))
                    .then_with(|| right.player_id.cmp(&left.player_id))
            })
    }

    fn culture_before(&self, domination: Option<&DominationVictoryProgress>) -> bool {
        let Some(leader) = domination.filter(|entry| self.at_domination_threshold(entry)) else {
            return true;
        };
        self.own_cultural.unique_stored_artifacts >= self.cultural_required_artifacts
            && self
                .cultural_required_hold_turns
                .saturating_sub(self.own_cultural.hold_turns)
                < self
                    .domination_required_hold_turns
                    .saturating_sub(leader.hold_turns)
    }

    fn at_domination_threshold(&self, entry: &DominationVictoryProgress) -> bool {
        self.domination_required_control_percent
            .percent_requirement_met(entry.controlled_passable_hexes, entry.total_passable_hexes)
    }

    fn opponent_threat(&self, entry: &DominationVictoryProgress) -> bool {
        if self.at_domination_threshold(entry) {
            return self.domination_required_hold_turns <= 3
                || self
                    .domination_required_hold_turns
                    .saturating_sub(entry.hold_turns)
                    <= 1;
        }
        let near = match self.domination_required_hold_turns {
            0..=2 => 90,
            3 => 95,
            _ => return false,
        };
        self.domination_required_control_percent
            .percent_requirement_fraction_met(
                entry.controlled_passable_hexes,
                entry.total_passable_hexes,
                near,
            )
    }

    fn score_status(&self) -> VictoryStatus<'_> {
        let best = self.score_by_player_id.values().max();
        let mut leaders = self
            .score_by_player_id
            .iter()
            .filter(|(_, score)| Some(*score) == best);
        let first = leaders.next().map(|(player, _)| player);
        VictoryStatus {
            kind: VictoryStatusKind::Score,
            critical: self.remaining_turns.is_some_and(|turns| turns <= 5),
            leader_player_id: if leaders.next().is_none() {
                first
            } else {
                None
            },
        }
    }
}

#[cfg(test)]
mod tests;
