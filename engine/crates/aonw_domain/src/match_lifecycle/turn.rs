use std::collections::{BTreeMap, BTreeSet};

use crate::PlayerId;

use super::MatchIdentity;

/// Per-player participation state in the current turn.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum PlayerTurnState {
    /// Player may still submit turn work.
    Active,
    /// Player has finished current-turn work.
    Finished,
}

/// Host-provided UTC timestamp retained without consulting ambient time.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct UtcTimestamp(Box<str>);

impl UtcTimestamp {
    /// Validates the canonical UTC ISO-8601 shape used by the protocol.
    ///
    /// # Errors
    ///
    /// Returns an error when the timestamp is not a UTC calendar value.
    pub fn new(value: impl Into<Box<str>>) -> Result<Self, &'static str> {
        let value = value.into();
        if valid_utc_timestamp(&value) {
            Ok(Self(value))
        } else {
            Err("expected a UTC ISO-8601 timestamp")
        }
    }

    /// Returns the canonical textual value.
    #[must_use]
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

/// Structural lifecycle failure.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum TurnLifecycleBuildError {
    /// A set contained a duplicate identity.
    DuplicatePlayer(PlayerId),
    /// A lifecycle field referenced someone outside match participants.
    UnknownPlayer(PlayerId),
    /// A timeout streak cannot be negative.
    NegativeTimeoutStreak(PlayerId),
    /// A participant has no explicit current-turn state.
    MissingTurnState(PlayerId),
    /// A submitted participant is outside the explicit submission scope.
    SubmittedPlayerNotRequired(PlayerId),
    /// A submitted participant is not marked finished.
    SubmittedPlayerNotFinished(PlayerId),
    /// A kicked participant is not marked finished.
    KickedPlayerNotFinished(PlayerId),
    /// A kicked participant remains in the required submission scope.
    KickedPlayerStillRequired(PlayerId),
    /// A resigned participant is not marked finished.
    ResignedPlayerNotFinished(PlayerId),
    /// A resigned participant remains in the required submission scope.
    ResignedPlayerStillRequired(PlayerId),
    /// A participant cannot be both kicked and resigned.
    ParticipantRemovedTwice(PlayerId),
}

impl core::fmt::Display for TurnLifecycleBuildError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::DuplicatePlayer(player) => {
                write!(formatter, "duplicate lifecycle player: {player}")
            }
            Self::UnknownPlayer(player) => {
                write!(formatter, "lifecycle player is not a participant: {player}")
            }
            Self::NegativeTimeoutStreak(player) => {
                write!(
                    formatter,
                    "timeout streak is negative for participant: {player}"
                )
            }
            Self::MissingTurnState(player) => {
                write!(formatter, "participant has no turn state: {player}")
            }
            Self::SubmittedPlayerNotRequired(player) => {
                write!(formatter, "submitted participant is not required: {player}")
            }
            Self::SubmittedPlayerNotFinished(player) => {
                write!(formatter, "submitted participant is not finished: {player}")
            }
            Self::KickedPlayerNotFinished(player) => {
                write!(formatter, "kicked participant is not finished: {player}")
            }
            Self::KickedPlayerStillRequired(player) => {
                write!(formatter, "kicked participant is still required: {player}")
            }
            Self::ResignedPlayerNotFinished(player) => {
                write!(formatter, "resigned participant is not finished: {player}")
            }
            Self::ResignedPlayerStillRequired(player) => {
                write!(
                    formatter,
                    "resigned participant is still required: {player}"
                )
            }
            Self::ParticipantRemovedTwice(player) => {
                write!(
                    formatter,
                    "participant is both kicked and resigned: {player}"
                )
            }
        }
    }
}

impl std::error::Error for TurnLifecycleBuildError {}

/// Deterministically ordered state of current-turn participation.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct TurnLifecycle {
    turn_states_by_player_id: BTreeMap<PlayerId, PlayerTurnState>,
    required_submission_player_ids: BTreeSet<PlayerId>,
    submitted_player_ids: BTreeSet<PlayerId>,
    timeout_streaks_by_player_id: BTreeMap<PlayerId, i64>,
    afk_player_ids: BTreeSet<PlayerId>,
    kicked_player_ids: BTreeSet<PlayerId>,
    resigned_player_ids: BTreeSet<PlayerId>,
    turn_started_at: Option<UtcTimestamp>,
}

impl TurnLifecycle {
    /// Validates participant references and owns the current lifecycle.
    ///
    /// # Errors
    ///
    /// Returns an error for duplicate set entries or unknown participants.
    #[allow(clippy::too_many_arguments)]
    pub fn try_new(
        identity: &MatchIdentity,
        turn_states_by_player_id: BTreeMap<PlayerId, PlayerTurnState>,
        required_submission_player_ids: impl IntoIterator<Item = PlayerId>,
        submitted_player_ids: impl IntoIterator<Item = PlayerId>,
        timeout_streaks_by_player_id: BTreeMap<PlayerId, i64>,
        afk_player_ids: impl IntoIterator<Item = PlayerId>,
        kicked_player_ids: impl IntoIterator<Item = PlayerId>,
        turn_started_at: Option<UtcTimestamp>,
    ) -> Result<Self, TurnLifecycleBuildError> {
        Self::try_new_with_resigned(
            identity,
            turn_states_by_player_id,
            required_submission_player_ids,
            submitted_player_ids,
            timeout_streaks_by_player_id,
            afk_player_ids,
            kicked_player_ids,
            std::iter::empty(),
            turn_started_at,
        )
    }

    /// Validates participant references and owns lifecycle removal reasons.
    ///
    /// # Errors
    ///
    /// Returns an error for invalid references, states, or overlapping removal reasons.
    #[allow(clippy::too_many_arguments)]
    pub fn try_new_with_resigned(
        identity: &MatchIdentity,
        turn_states_by_player_id: BTreeMap<PlayerId, PlayerTurnState>,
        required_submission_player_ids: impl IntoIterator<Item = PlayerId>,
        submitted_player_ids: impl IntoIterator<Item = PlayerId>,
        timeout_streaks_by_player_id: BTreeMap<PlayerId, i64>,
        afk_player_ids: impl IntoIterator<Item = PlayerId>,
        kicked_player_ids: impl IntoIterator<Item = PlayerId>,
        resigned_player_ids: impl IntoIterator<Item = PlayerId>,
        turn_started_at: Option<UtcTimestamp>,
    ) -> Result<Self, TurnLifecycleBuildError> {
        let required_submission_player_ids = collect_set(required_submission_player_ids)?;
        let submitted_player_ids = collect_set(submitted_player_ids)?;
        let afk_player_ids = collect_set(afk_player_ids)?;
        let kicked_player_ids = collect_set(kicked_player_ids)?;
        let resigned_player_ids = collect_set(resigned_player_ids)?;
        for player in turn_states_by_player_id
            .keys()
            .chain(required_submission_player_ids.iter())
            .chain(submitted_player_ids.iter())
            .chain(timeout_streaks_by_player_id.keys())
            .chain(afk_player_ids.iter())
            .chain(kicked_player_ids.iter())
            .chain(resigned_player_ids.iter())
        {
            if !identity.contains(player) {
                return Err(TurnLifecycleBuildError::UnknownPlayer(player.clone()));
            }
        }
        if let Some((player, _)) = timeout_streaks_by_player_id
            .iter()
            .find(|(_, streak)| **streak < 0)
        {
            return Err(TurnLifecycleBuildError::NegativeTimeoutStreak(
                player.clone(),
            ));
        }
        for participant in identity.participants() {
            if !turn_states_by_player_id.contains_key(participant.id()) {
                return Err(TurnLifecycleBuildError::MissingTurnState(
                    participant.id().clone(),
                ));
            }
        }
        for player in &submitted_player_ids {
            if !required_submission_player_ids.contains(player) {
                return Err(TurnLifecycleBuildError::SubmittedPlayerNotRequired(
                    player.clone(),
                ));
            }
            if turn_states_by_player_id.get(player) != Some(&PlayerTurnState::Finished) {
                return Err(TurnLifecycleBuildError::SubmittedPlayerNotFinished(
                    player.clone(),
                ));
            }
        }
        for player in &kicked_player_ids {
            if turn_states_by_player_id.get(player) != Some(&PlayerTurnState::Finished) {
                return Err(TurnLifecycleBuildError::KickedPlayerNotFinished(
                    player.clone(),
                ));
            }
            if required_submission_player_ids.contains(player) {
                return Err(TurnLifecycleBuildError::KickedPlayerStillRequired(
                    player.clone(),
                ));
            }
        }
        for player in &resigned_player_ids {
            if kicked_player_ids.contains(player) {
                return Err(TurnLifecycleBuildError::ParticipantRemovedTwice(
                    player.clone(),
                ));
            }
            if turn_states_by_player_id.get(player) != Some(&PlayerTurnState::Finished) {
                return Err(TurnLifecycleBuildError::ResignedPlayerNotFinished(
                    player.clone(),
                ));
            }
            if required_submission_player_ids.contains(player) {
                return Err(TurnLifecycleBuildError::ResignedPlayerStillRequired(
                    player.clone(),
                ));
            }
        }
        Ok(Self {
            turn_states_by_player_id,
            required_submission_player_ids,
            submitted_player_ids,
            timeout_streaks_by_player_id,
            afk_player_ids,
            kicked_player_ids,
            resigned_player_ids,
            turn_started_at,
        })
    }

    /// Returns player turn states sorted by identifier.
    #[must_use]
    pub const fn turn_states_by_player_id(&self) -> &BTreeMap<PlayerId, PlayerTurnState> {
        &self.turn_states_by_player_id
    }
    /// Returns the explicit submission scope sorted by identifier.
    #[must_use]
    pub const fn required_submission_player_ids(&self) -> &BTreeSet<PlayerId> {
        &self.required_submission_player_ids
    }
    /// Returns submitted player identities sorted by identifier.
    #[must_use]
    pub const fn submitted_player_ids(&self) -> &BTreeSet<PlayerId> {
        &self.submitted_player_ids
    }
    /// Returns timeout streaks sorted by identifier.
    #[must_use]
    pub const fn timeout_streaks_by_player_id(&self) -> &BTreeMap<PlayerId, i64> {
        &self.timeout_streaks_by_player_id
    }
    /// Returns AFK identities sorted by identifier.
    #[must_use]
    pub const fn afk_player_ids(&self) -> &BTreeSet<PlayerId> {
        &self.afk_player_ids
    }
    /// Returns kicked identities sorted by identifier.
    #[must_use]
    pub const fn kicked_player_ids(&self) -> &BTreeSet<PlayerId> {
        &self.kicked_player_ids
    }
    /// Returns voluntarily resigned identities sorted by identifier.
    #[must_use]
    pub const fn resigned_player_ids(&self) -> &BTreeSet<PlayerId> {
        &self.resigned_player_ids
    }
    /// Returns whether a participant no longer belongs to active play.
    #[must_use]
    pub fn is_removed(&self, player_id: &PlayerId) -> bool {
        self.kicked_player_ids.contains(player_id) || self.resigned_player_ids.contains(player_id)
    }
    /// Returns the explicit host-provided turn start.
    #[must_use]
    pub const fn turn_started_at(&self) -> Option<&UtcTimestamp> {
        self.turn_started_at.as_ref()
    }
}

fn collect_set(
    values: impl IntoIterator<Item = PlayerId>,
) -> Result<BTreeSet<PlayerId>, TurnLifecycleBuildError> {
    let mut result = BTreeSet::new();
    for value in values {
        if !result.insert(value.clone()) {
            return Err(TurnLifecycleBuildError::DuplicatePlayer(value));
        }
    }
    Ok(result)
}

fn valid_utc_timestamp(value: &str) -> bool {
    let Some(body) = value.strip_suffix('Z') else {
        return false;
    };
    let Some((date, time)) = body.split_once('T') else {
        return false;
    };
    let mut date_parts = date.split('-');
    let (Some(year), Some(month), Some(day), None) = (
        date_parts.next(),
        date_parts.next(),
        date_parts.next(),
        date_parts.next(),
    ) else {
        return false;
    };
    let mut time_parts = time.split(':');
    let (Some(hour), Some(minute), Some(second), None) = (
        time_parts.next(),
        time_parts.next(),
        time_parts.next(),
        time_parts.next(),
    ) else {
        return false;
    };
    let (whole_second, fraction) = second
        .split_once('.')
        .map_or((second, None), |(whole, fraction)| (whole, Some(fraction)));
    let Some(year_number) = fixed_number(year, 4) else {
        return false;
    };
    let Some(month_number) = fixed_number(month, 2) else {
        return false;
    };
    let Some(day_number) = fixed_number(day, 2) else {
        return false;
    };
    (1..=12).contains(&month_number)
        && (1..=days_in_month(year_number, month_number)).contains(&day_number)
        && in_range(hour, 0, 23)
        && in_range(minute, 0, 59)
        && in_range(whole_second, 0, 59)
        && fraction.is_none_or(|digits| {
            !digits.is_empty()
                && digits.len() <= 6
                && digits.bytes().all(|byte| byte.is_ascii_digit())
        })
}

fn fixed_number(value: &str, digits: usize) -> Option<u16> {
    (value.len() == digits && value.bytes().all(|byte| byte.is_ascii_digit()))
        .then(|| value.parse().ok())
        .flatten()
}

const fn days_in_month(year: u16, month: u16) -> u16 {
    match month {
        4 | 6 | 9 | 11 => 30,
        2 if year.is_multiple_of(400) || (year.is_multiple_of(4) && !year.is_multiple_of(100)) => {
            29
        }
        2 => 28,
        _ => 31,
    }
}

fn in_range(value: &str, minimum: u8, maximum: u8) -> bool {
    value.len() == 2
        && value.bytes().all(|byte| byte.is_ascii_digit())
        && value
            .parse::<u8>()
            .is_ok_and(|number| number >= minimum && number <= maximum)
}

#[cfg(test)]
mod tests {
    use super::UtcTimestamp;

    #[test]
    fn timestamp_requires_explicit_utc_without_reading_a_clock() {
        assert!(UtcTimestamp::new("2026-08-23T14:15:16.123456Z").is_ok());
        assert!(UtcTimestamp::new("2026-08-23T14:15:16+02:00").is_err());
        assert!(UtcTimestamp::new("2026-08-23T25:15:16Z").is_err());
        assert!(UtcTimestamp::new("2026-02-29T14:15:16Z").is_err());
        assert!(UtcTimestamp::new("2024-02-29T14:15:16Z").is_ok());
    }
}
