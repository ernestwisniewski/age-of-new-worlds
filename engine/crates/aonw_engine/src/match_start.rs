use std::collections::BTreeMap;

use aonw_content::MapDefinition;
use aonw_domain::{
    FogOfWar, GameState, GameStateBuildError, MatchIdentity, MatchLifecycle, PlayerFog, PlayerId,
    PlayerTurnState, TurnLifecycle, TurnLifecycleBuildError, TurnMode,
};

use crate::movement::{merge_discovered_contacts, recompute_after_move};

/// Failure raised while binding an authored scenario seed to a playable match.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum MatchStartError {
    /// A playable match requires at least one participant.
    EmptyParticipants,
    /// Initial lifecycle construction failed.
    InvalidLifecycle(TurnLifecycleBuildError),
    /// Initial fog construction found a duplicated participant.
    InvalidFog(PlayerId),
    /// The bound aggregate violates a canonical invariant.
    InvalidState(GameStateBuildError),
}

impl core::fmt::Display for MatchStartError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::EmptyParticipants => {
                formatter.write_str("match requires at least one participant")
            }
            Self::InvalidLifecycle(source) => {
                write!(formatter, "invalid initial lifecycle: {source}")
            }
            Self::InvalidFog(player) => write!(formatter, "duplicate initial fog player: {player}"),
            Self::InvalidState(source) => write!(formatter, "invalid started match: {source}"),
        }
    }
}

impl std::error::Error for MatchStartError {}

/// Atomically binds participants, initial turn lifecycle, visibility, and
/// discovered contacts to one validated scenario seed.
///
/// Empty fog storage means that fog is globally disabled. When enabled, every
/// participant receives a complete fog entry before canonical validation.
///
/// # Errors
///
/// Returns [`MatchStartError`] when identity is empty or the resulting
/// aggregate violates lifecycle, ownership, fog, or content invariants.
pub fn start_match(
    seed: GameState,
    map: &MapDefinition,
    identity: MatchIdentity,
    fog_enabled: bool,
) -> Result<GameState, MatchStartError> {
    if identity.participants().is_empty() {
        return Err(MatchStartError::EmptyParticipants);
    }

    let turn_states_by_player_id = identity
        .participants()
        .iter()
        .map(|participant| (participant.id().clone(), PlayerTurnState::Active))
        .collect::<BTreeMap<_, _>>();
    let required_submission_player_ids = if identity.turn_mode() == TurnMode::Simultaneous {
        identity
            .participants()
            .iter()
            .map(|participant| participant.id().clone())
            .collect::<Vec<_>>()
    } else {
        Vec::new()
    };
    let turn = TurnLifecycle::try_new(
        &identity,
        turn_states_by_player_id,
        required_submission_player_ids,
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .map_err(MatchStartError::InvalidLifecycle)?;

    let mut fog = if fog_enabled {
        FogOfWar::try_new(
            identity
                .participants()
                .iter()
                .map(|participant| PlayerFog::new(participant.id().clone(), [], [])),
        )
        .map_err(MatchStartError::InvalidFog)?
    } else {
        FogOfWar::default()
    };
    let unit_references = seed.units().iter().collect::<Vec<_>>();
    if fog_enabled {
        for participant in identity.participants() {
            fog =
                recompute_after_move(&fog, map, participant.id(), &unit_references, seed.cities());
        }
    }
    let diplomacy =
        merge_discovered_contacts(seed.diplomacy(), &fog, &unit_references, seed.cities());
    seed.into_started_match(MatchLifecycle::new(identity, turn), fog, diplomacy)
        .map_err(MatchStartError::InvalidState)
}
