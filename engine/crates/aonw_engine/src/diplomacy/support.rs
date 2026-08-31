use aonw_domain::{
    CombatState, Diplomacy, DiplomacyStateUpdate, DiplomaticRelation, DiplomaticRelationStatus,
    DiplomaticScoreChangeReason, DiplomaticScoreEntry, EconomyState, GameState, MatchIdentity,
    PlayerId, PlayerPair,
};

use super::{DiplomacyError, DiplomacyMutation};
use crate::{CommandRejectionCode, DomainEvent, EngineContext};

#[allow(clippy::too_many_arguments)]
pub(crate) fn adjust_score(
    diplomacy: &Diplomacy,
    identity: &MatchIdentity,
    pair: &PlayerPair,
    turn: u32,
    delta: i64,
    reason: DiplomaticScoreChangeReason,
    source_id: Option<&str>,
) -> Result<(Diplomacy, DiplomaticScoreEntry), DiplomacyError> {
    let (status, current) = effective_relation(diplomacy, pair);
    let current_relation = diplomacy.relation_between(pair.first(), pair.second());
    let score_after = current.saturating_add(delta).clamp(-100, 100);
    let relation = DiplomaticRelation::try_new(
        pair.clone(),
        status,
        score_after,
        current_relation.and_then(DiplomaticRelation::status_expires_on_turn),
        current_relation.and_then(DiplomaticRelation::last_changed_turn),
        current_relation.and_then(DiplomaticRelation::last_change_reason),
    )?;
    let diplomacy = diplomacy.try_with_relation(identity, relation)?;
    let entry = DiplomaticScoreEntry::try_new(
        pair.clone(),
        turn,
        score_after - current,
        score_after,
        reason,
        source_id.map(str::to_owned),
    )?;
    let diplomacy = diplomacy.try_with_score_entry(identity, entry.clone())?;
    Ok((diplomacy, entry))
}

pub(crate) fn effective_relation(
    diplomacy: &Diplomacy,
    pair: &PlayerPair,
) -> (DiplomaticRelationStatus, i64) {
    diplomacy
        .relation_between(pair.first(), pair.second())
        .map_or((DiplomaticRelationStatus::Neutral, 0), |relation| {
            (relation.status(), relation.relation_score())
        })
}

pub(super) fn mutation(
    state: &GameState,
    diplomacy: Diplomacy,
    economy: EconomyState,
    combat: CombatState,
    events: impl IntoIterator<Item = DomainEvent>,
) -> Result<DiplomacyMutation, DiplomacyError> {
    let revision = state
        .revision()
        .checked_next()
        .ok_or(CommandRejectionCode::StateRevisionOverflow)?;
    Ok(DiplomacyMutation {
        update: DiplomacyStateUpdate {
            revision,
            economy,
            combat,
            diplomacy,
        },
        events: events.into_iter().collect::<Vec<_>>().into_boxed_slice(),
    })
}

pub(super) fn validate_actor(
    state: &GameState,
    context: EngineContext<'_>,
    actor: &PlayerId,
) -> Result<(), DiplomacyError> {
    if context.can_act() && state.match_lifecycle().identity().contains(actor) {
        Ok(())
    } else {
        Err(CommandRejectionCode::DiplomacyPlayerNotControlled.into())
    }
}

pub(super) fn validate_revision(state: &GameState, expected: u64) -> Result<(), DiplomacyError> {
    if state.revision().get() == expected {
        Ok(())
    } else {
        Err(CommandRejectionCode::StaleRevision.into())
    }
}
