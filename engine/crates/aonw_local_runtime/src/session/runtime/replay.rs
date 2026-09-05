use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_contract_mapping::decode_game_state;
use aonw_contracts::{ReplayEntryDto, ReplayLogDto};
use aonw_domain::PlayerId;
use aonw_engine::GameEngine;

use crate::persistence::{PersistenceError, verify_entry, verify_replay};
use crate::{CommandResult, OpenSession, PlayerViewSnapshot};

use super::LocalRuntime;

/// Recipient-safe snapshot at one exact replay entry boundary.
#[derive(Clone, Debug)]
pub struct ReplayFrame {
    /// Number of authoritative entries applied to this frame.
    pub position: u64,
    /// Total number of entries in the verified archive.
    pub entry_count: u64,
    /// Complete projection for the selected participant.
    pub snapshot: PlayerViewSnapshot,
    /// Exact command for a one-entry advance; absent for open, repeat, or random seeks.
    /// Wire encoding applies its recipient disclosure to events and evidence.
    pub command: Option<CommandResult>,
}

#[derive(Clone, Debug)]
pub(super) struct ReplayPlayback {
    map: MapDefinition,
    ruleset: RulesetDefinition,
    replay: ReplayLogDto,
    recipient: PlayerId,
    position: u64,
    entry_count: u64,
}

impl LocalRuntime {
    /// Verifies a current replay in full, then opens its first recipient-safe frame.
    ///
    /// A failed open preserves the previous valid session.
    ///
    /// # Errors
    ///
    /// Returns an error for incompatible content, replay drift, or an invalid recipient.
    pub fn open_replay_json(
        &mut self,
        map: MapDefinition,
        ruleset: RulesetDefinition,
        input: &str,
        recipient: PlayerId,
    ) -> Result<ReplayFrame, PersistenceError> {
        let verification = verify_replay(map.clone(), ruleset.clone(), input)?;
        let replay = ReplayLogDto::from_json(input).map_err(PersistenceError::Codec)?;
        let entry_count = u64::try_from(verification.entry_count)
            .map_err(|_| PersistenceError::ReplayIndexOverflow)?;
        let playback = ReplayPlayback {
            map,
            ruleset,
            replay,
            recipient,
            position: 0,
            entry_count,
        };
        let (candidate, frame) = build_candidate(&playback, 0)?;
        *self = candidate;
        Ok(frame)
    }

    /// Seeks an open verified replay to an exact authoritative entry boundary.
    ///
    /// Sequential forward playback applies one command to the retained runtime;
    /// random access rebuilds only the segment containing the requested boundary.
    ///
    /// # Errors
    ///
    /// Returns an error when playback is closed or the position is outside the archive.
    pub fn seek_replay(&mut self, position: u64) -> Result<ReplayFrame, PersistenceError> {
        let playback = self
            .replay_playback
            .clone()
            .ok_or(PersistenceError::ReplayPlaybackNotOpen)?;
        if position > playback.entry_count {
            return Err(PersistenceError::ReplayPositionOutOfBounds {
                requested: position,
                entry_count: playback.entry_count,
            });
        }
        if position == playback.position {
            return self.playback_frame();
        }
        if position == playback.position.saturating_add(1) {
            let (segment_index, entry_index, entry) = playback.entry_at(playback.position).ok_or(
                PersistenceError::ReplayPositionOutOfBounds {
                    requested: position,
                    entry_count: playback.entry_count,
                },
            )?;
            self.start_observing_recipient(1)
                .map_err(PersistenceError::Runtime)?;
            let result = verify_entry(self, segment_index, entry_index, &entry);
            let mut commands = self.finish_observing_recipient().into_vec();
            if let Err(error) = result {
                self.poison();
                return Err(error);
            }
            self.handoff_hot_seat_actor(playback.recipient.clone())
                .map_err(PersistenceError::ReplayRecipient)?;
            self.replay_playback = Some(ReplayPlayback {
                position,
                ..playback
            });
            let mut frame = self.playback_frame()?;
            frame.command = commands.pop();
            return Ok(frame);
        }

        let (candidate, frame) = build_candidate(&playback, position)?;
        *self = candidate;
        Ok(frame)
    }

    /// Returns whether the current session is a read-only replay playback.
    #[must_use]
    pub const fn is_replay_playback(&self) -> bool {
        self.replay_playback.is_some()
    }

    fn playback_frame(&self) -> Result<ReplayFrame, PersistenceError> {
        let playback = self
            .replay_playback
            .as_ref()
            .ok_or(PersistenceError::ReplayPlaybackNotOpen)?;
        Ok(ReplayFrame {
            position: playback.position,
            entry_count: playback.entry_count,
            snapshot: self.snapshot().map_err(PersistenceError::Runtime)?,
            command: None,
        })
    }
}

impl ReplayPlayback {
    fn entry_at(&self, global_index: u64) -> Option<(usize, usize, ReplayEntryDto)> {
        let mut remaining = usize::try_from(global_index).ok()?;
        for (segment_index, segment) in self.replay.segments.iter().enumerate() {
            if remaining < segment.entries.len() {
                return Some((segment_index, remaining, segment.entries[remaining].clone()));
            }
            remaining = remaining.checked_sub(segment.entries.len())?;
        }
        None
    }

    fn segment_for_position(&self, position: u64) -> Result<(usize, usize), PersistenceError> {
        let target =
            usize::try_from(position).map_err(|_| PersistenceError::ReplayIndexOverflow)?;
        let mut segment_start = 0usize;
        for (segment_index, segment) in self.replay.segments.iter().enumerate() {
            let segment_end = segment_start
                .checked_add(segment.entries.len())
                .ok_or(PersistenceError::ReplayIndexOverflow)?;
            if target < segment_end
                || (target == segment_end && segment_index + 1 == self.replay.segments.len())
            {
                return Ok((segment_index, target - segment_start));
            }
            segment_start = segment_end;
        }
        Err(PersistenceError::ReplayPositionOutOfBounds {
            requested: position,
            entry_count: self.entry_count,
        })
    }
}

fn build_candidate(
    playback: &ReplayPlayback,
    position: u64,
) -> Result<(LocalRuntime, ReplayFrame), PersistenceError> {
    let (segment_index, local_position) = playback.segment_for_position(position)?;
    let segment = &playback.replay.segments[segment_index];
    let state =
        decode_game_state(segment.initial_state.clone()).map_err(PersistenceError::State)?;
    if GameEngine::state_digest(&state).to_string() != segment.initial_state_digest {
        return Err(PersistenceError::ReplayCheckpointDigestMismatch {
            segment: segment_index,
        });
    }
    let actor = PlayerId::new(playback.replay.actor_player_id.clone())
        .map_err(PersistenceError::InvalidActor)?;
    let mut candidate = LocalRuntime::default();
    candidate
        .open(
            OpenSession::from_state(playback.map.clone(), playback.ruleset.clone(), state, actor)
                .with_event_offset(segment.initial_event_offset),
        )
        .map_err(PersistenceError::Open)?;
    candidate
        .session
        .as_mut()
        .expect("candidate session is open")
        .disable_replay();
    for (entry_index, entry) in segment.entries.iter().take(local_position).enumerate() {
        verify_entry(&mut candidate, segment_index, entry_index, entry)?;
    }
    candidate
        .handoff_hot_seat_actor(playback.recipient.clone())
        .map_err(PersistenceError::ReplayRecipient)?;
    candidate.replay_playback = Some(ReplayPlayback {
        position,
        ..playback.clone()
    });
    let frame = candidate.playback_frame()?;
    Ok((candidate, frame))
}
