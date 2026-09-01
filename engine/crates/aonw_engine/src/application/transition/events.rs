use aonw_domain::{CityId, PlayerId, UnitId};

use crate::CombatTarget;

impl core::fmt::Display for super::CommandRejectionCode {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        formatter.write_str(self.as_str())
    }
}

/// Kind of completed worker construction.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum WorkerJobCompletion {
    /// A field improvement was completed.
    FieldImprovement(aonw_domain::FieldImprovementKind),
    /// A road segment was completed.
    Road,
}

/// Accepted fact that one worker job completed successfully.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct WorkerCompletedJobEvent {
    unit_id: UnitId,
    target: aonw_domain::HexCoord,
    completion: WorkerJobCompletion,
}

impl WorkerCompletedJobEvent {
    pub(crate) const fn new(
        unit_id: UnitId,
        target: aonw_domain::HexCoord,
        completion: WorkerJobCompletion,
    ) -> Self {
        Self {
            unit_id,
            target,
            completion,
        }
    }
    /// Returns the worker identity before charge consumption.
    #[must_use]
    pub const fn unit_id(&self) -> &UnitId {
        &self.unit_id
    }
    /// Returns the completed coordinate.
    #[must_use]
    pub const fn target(&self) -> aonw_domain::HexCoord {
        self.target
    }
    /// Returns the completed construction kind.
    #[must_use]
    pub const fn completion(&self) -> WorkerJobCompletion {
        self.completion
    }
}

/// Accepted fact that a city-founding job completed.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CityFoundedEvent {
    city_id: CityId,
    owner_player_id: PlayerId,
}

impl CityFoundedEvent {
    pub(crate) const fn new(city_id: CityId, owner_player_id: PlayerId) -> Self {
        Self {
            city_id,
            owner_player_id,
        }
    }
    /// Returns the new city identity.
    #[must_use]
    pub const fn city_id(&self) -> &CityId {
        &self.city_id
    }
    /// Returns the founding player.
    #[must_use]
    pub const fn owner_player_id(&self) -> &PlayerId {
        &self.owner_player_id
    }
}

/// Recipient-safe score change emitted by combat diplomacy.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DiplomaticScoreChangedEvent {
    player_a_id: PlayerId,
    player_b_id: PlayerId,
    delta: i64,
    score_after: i64,
    reason: aonw_domain::DiplomaticScoreChangeReason,
    source_id: Option<String>,
}

impl DiplomaticScoreChangedEvent {
    pub(crate) fn from_entry(entry: &aonw_domain::DiplomaticScoreEntry) -> Self {
        Self {
            player_a_id: entry.pair().first().clone(),
            player_b_id: entry.pair().second().clone(),
            delta: entry.delta(),
            score_after: entry.score_after(),
            reason: entry.reason(),
            source_id: entry.source_id().map(str::to_owned),
        }
    }
    /// Returns the canonical first participant.
    #[must_use]
    pub const fn player_a_id(&self) -> &PlayerId {
        &self.player_a_id
    }
    /// Returns the canonical second participant.
    #[must_use]
    pub const fn player_b_id(&self) -> &PlayerId {
        &self.player_b_id
    }
    /// Returns the applied score delta.
    #[must_use]
    pub const fn delta(&self) -> i64 {
        self.delta
    }
    /// Returns the score after applying the delta.
    #[must_use]
    pub const fn score_after(&self) -> i64 {
        self.score_after
    }
    /// Returns the canonical score-change reason.
    #[must_use]
    pub const fn reason(&self) -> aonw_domain::DiplomaticScoreChangeReason {
        self.reason
    }
    /// Returns the deterministic source identity when present.
    #[must_use]
    pub fn source_id(&self) -> Option<&str> {
        self.source_id.as_deref()
    }
}

/// Compact typed reference shared by ordered combat events.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CombatEvent {
    attacker_unit_id: UnitId,
    target: CombatTarget,
    subject_unit_id: Option<UnitId>,
}

impl CombatEvent {
    pub(crate) fn new(attacker_unit_id: UnitId, target: CombatTarget) -> Self {
        Self {
            attacker_unit_id,
            target,
            subject_unit_id: None,
        }
    }
    pub(crate) fn for_unit(
        attacker_unit_id: UnitId,
        target: CombatTarget,
        subject_unit_id: UnitId,
    ) -> Self {
        Self {
            attacker_unit_id,
            target,
            subject_unit_id: Some(subject_unit_id),
        }
    }
    /// Returns the attacking unit.
    #[must_use]
    pub const fn attacker_unit_id(&self) -> &UnitId {
        &self.attacker_unit_id
    }
    /// Returns the visible target identity.
    #[must_use]
    pub const fn target(&self) -> &CombatTarget {
        &self.target
    }
    /// Returns the affected unit for retreat, experience, and casualty events.
    #[must_use]
    pub const fn subject_unit_id(&self) -> Option<&UnitId> {
        self.subject_unit_id.as_ref()
    }
}

/// Accepted fact that one participant completed its sequential turn.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct TurnEndedEvent {
    player_id: PlayerId,
}

impl TurnEndedEvent {
    pub(crate) const fn new(player_id: PlayerId) -> Self {
        Self { player_id }
    }

    /// Returns the participant ending its turn.
    #[must_use]
    pub const fn player_id(&self) -> &PlayerId {
        &self.player_id
    }
}

/// Accepted fact that a simultaneous submission scope completed.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct AllPlayersSubmittedEvent {
    turn: u32,
    player_ids: Box<[PlayerId]>,
}

impl AllPlayersSubmittedEvent {
    pub(crate) fn new(turn: u32, player_ids: impl Into<Box<[PlayerId]>>) -> Self {
        Self {
            turn,
            player_ids: player_ids.into(),
        }
    }

    /// Returns the finalized turn.
    #[must_use]
    pub const fn turn(&self) -> u32 {
        self.turn
    }

    /// Returns participants in canonical turn order.
    #[must_use]
    pub const fn player_ids(&self) -> &[PlayerId] {
        &self.player_ids
    }
}

/// Accepted timeout fact emitted before finalization events.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerTimedOutEvent {
    turn: u32,
    player_id: PlayerId,
}

impl PlayerTimedOutEvent {
    pub(crate) const fn new(turn: u32, player_id: PlayerId) -> Self {
        Self { turn, player_id }
    }

    /// Returns the timed-out turn.
    #[must_use]
    pub const fn turn(&self) -> u32 {
        self.turn
    }

    /// Returns the timed-out participant.
    #[must_use]
    pub const fn player_id(&self) -> &PlayerId {
        &self.player_id
    }
}

/// Accepted participant-removal fact.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerKickedEvent {
    turn: u32,
    player_id: PlayerId,
    reason: Box<str>,
    timeout_streak: i64,
}

/// Accepted voluntary participant resignation fact.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerResignedEvent {
    turn: u32,
    player_id: PlayerId,
}

impl PlayerResignedEvent {
    pub(crate) const fn new(turn: u32, player_id: PlayerId) -> Self {
        Self { turn, player_id }
    }

    /// Returns the turn during which the participant resigned.
    #[must_use]
    pub const fn turn(&self) -> u32 {
        self.turn
    }

    /// Returns the participant who resigned.
    #[must_use]
    pub const fn player_id(&self) -> &PlayerId {
        &self.player_id
    }
}

impl PlayerKickedEvent {
    pub(crate) fn new(
        turn: u32,
        player_id: PlayerId,
        reason: impl Into<Box<str>>,
        timeout_streak: i64,
    ) -> Self {
        Self {
            turn,
            player_id,
            reason: reason.into(),
            timeout_streak,
        }
    }

    /// Returns the turn during which removal occurred.
    #[must_use]
    pub const fn turn(&self) -> u32 {
        self.turn
    }

    /// Returns the removed participant.
    #[must_use]
    pub const fn player_id(&self) -> &PlayerId {
        &self.player_id
    }

    /// Returns the stable host-owned reason.
    #[must_use]
    pub const fn reason(&self) -> &str {
        &self.reason
    }

    /// Returns the host-observed timeout streak.
    #[must_use]
    pub const fn timeout_streak(&self) -> i64 {
        self.timeout_streak
    }
}
