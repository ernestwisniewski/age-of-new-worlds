use aonw_domain::{
    Diplomacy, DiplomaticRelation, DiplomaticRelationChangeReason, DiplomaticRelationStatus,
    DiplomaticScoreChangeReason, EconomyAccountChange, GameState, PlayerId, PlayerPair,
};

use super::{
    DeclareWarCommand, DiplomacyError, DiplomacyMutation, SendGoldGiftCommand,
    support::{adjust_score, effective_relation, mutation, validate_actor, validate_revision},
};
use crate::{
    CommandRejectionCode, DiplomacyDisclosure, DiplomacyPolicyQuery,
    DiplomaticRelationChangedEvent, DiplomaticScoreChangedEvent, DomainEvent, EngineContext,
};

pub(crate) fn apply_declare_war(
    state: &GameState,
    context: EngineContext<'_>,
    command: DeclareWarCommand<'_>,
) -> Result<DiplomacyMutation, DiplomacyError> {
    validate_revision(state, command.expected_revision())?;
    let actor = context.actor_player_id();
    validate_actor(state, context, actor)?;
    let target = command.target_player_id();
    let policy = DiplomacyPolicyQuery::between(state, actor, target)
        .map_err(|_| CommandRejectionCode::DiplomacyTargetNotDiscovered)?;
    if !matches!(policy.disclosure(), DiplomacyDisclosure::Known(_)) {
        return Err(CommandRejectionCode::DiplomacyTargetNotDiscovered.into());
    }
    if policy.status() == DiplomaticRelationStatus::Truce
        && policy
            .status_expires_on_turn()
            .is_some_and(|expiry| state.turn() < expiry)
    {
        return Err(CommandRejectionCode::DiplomacyTruceActive.into());
    }
    if policy.status() == DiplomaticRelationStatus::War {
        return Err(CommandRejectionCode::DiplomacyWarAlreadyActive.into());
    }

    let identity = state.match_lifecycle().identity();
    let pair = PlayerPair::new(actor.clone(), target.clone())
        .ok_or_else(|| DiplomacyError::InvalidState("war self relation".into()))?;
    let (old_status, old_score) = effective_relation(state.diplomacy(), &pair);
    let relation = DiplomaticRelation::try_new(
        pair.clone(),
        DiplomaticRelationStatus::War,
        old_score,
        None,
        Some(state.turn()),
        Some(DiplomaticRelationChangeReason::DeclarationOfWar),
    )?;
    let diplomacy = state.diplomacy().try_with_relation(identity, relation)?;
    let diplomacy = diplomacy.try_without_pair_pending_actions(identity, &pair)?;
    let (mut diplomacy, declaration_score) = adjust_score(
        &diplomacy,
        identity,
        &pair,
        state.turn(),
        context.ruleset().diplomacy().war_declaration_score_delta(),
        DiplomaticScoreChangeReason::DeclarationOfWar,
        None,
    )?;

    let mut observer_scores = Vec::new();
    let source_id = format!(
        "warmonger.{}.declarationOfWar.{}.{}",
        state.turn(),
        actor.as_str(),
        target.as_str()
    );
    for observer in known_observers(&diplomacy, actor, target) {
        let observer_pair = PlayerPair::new(observer, actor.clone())
            .ok_or_else(|| DiplomacyError::InvalidState("observer self relation".into()))?;
        let (next, score) = adjust_score(
            &diplomacy,
            identity,
            &observer_pair,
            state.turn(),
            context
                .ruleset()
                .diplomacy()
                .war_declaration_observer_score_delta(),
            DiplomaticScoreChangeReason::WarmongerPenalty,
            Some(&source_id),
        )?;
        diplomacy = next;
        observer_scores.push(score);
    }

    let mut events = Vec::with_capacity(observer_scores.len().saturating_add(2));
    events.push(DomainEvent::DiplomaticRelationChanged(
        DiplomaticRelationChangedEvent::new(
            pair,
            old_status,
            DiplomaticRelationStatus::War,
            DiplomaticRelationChangeReason::DeclarationOfWar,
            None,
        ),
    ));
    events.push(DomainEvent::DiplomaticScoreChanged(
        DiplomaticScoreChangedEvent::from_entry(&declaration_score),
    ));
    events.extend(observer_scores.iter().map(|score| {
        DomainEvent::DiplomaticScoreChanged(DiplomaticScoreChangedEvent::from_entry(score))
    }));
    mutation(
        state,
        diplomacy,
        state.economy().clone(),
        state.combat().clone(),
        events,
    )
}

pub(crate) fn apply_send_gold_gift(
    state: &GameState,
    context: EngineContext<'_>,
    command: SendGoldGiftCommand<'_>,
) -> Result<DiplomacyMutation, DiplomacyError> {
    validate_revision(state, command.expected_revision())?;
    let actor = context.actor_player_id();
    validate_actor(state, context, actor)?;
    let target = command.target_player_id();
    let policy = DiplomacyPolicyQuery::between(state, actor, target)
        .map_err(|_| CommandRejectionCode::DiplomacyTargetNotDiscovered)?;
    if !matches!(policy.disclosure(), DiplomacyDisclosure::Known(_)) {
        return Err(CommandRejectionCode::DiplomacyTargetNotDiscovered.into());
    }
    if command.amount() < 0 {
        return Err(CommandRejectionCode::DiplomacyInvalidGoldAmount.into());
    }
    if matches!(
        policy.status(),
        DiplomaticRelationStatus::War | DiplomaticRelationStatus::Truce
    ) {
        return Err(CommandRejectionCode::DiplomacyGoldGiftBlockedByRelation.into());
    }
    let available = state
        .economy()
        .player_gold()
        .get(actor)
        .copied()
        .unwrap_or(0);
    if available < command.amount() {
        return Err(CommandRejectionCode::DiplomacyGoldUnavailable.into());
    }
    let balance = context.ruleset().diplomacy();
    let delta = balance.gold_gift_score_delta(command.amount());
    if delta <= 0
        || gift_on_cooldown(
            state.diplomacy(),
            actor,
            target,
            state.turn(),
            balance.gold_gift_cooldown_turns(),
        )
    {
        return Err(CommandRejectionCode::DiplomacyGoldGiftUnavailable.into());
    }

    let pair = PlayerPair::new(actor.clone(), target.clone())
        .ok_or_else(|| DiplomacyError::InvalidState("gift self relation".into()))?;
    let source_id = format!(
        "gold_gift.{}.{}.{}",
        state.turn(),
        actor.as_str(),
        target.as_str()
    );
    let (diplomacy, score) = adjust_score(
        state.diplomacy(),
        state.match_lifecycle().identity(),
        &pair,
        state.turn(),
        delta,
        DiplomaticScoreChangeReason::GoldGift,
        Some(&source_id),
    )?;
    let economy = state
        .economy()
        .try_after_changes(
            state.match_lifecycle().identity(),
            state.bounds(),
            [
                EconomyAccountChange::Gold {
                    player: actor.clone(),
                    delta: -command.amount(),
                },
                EconomyAccountChange::Gold {
                    player: target.clone(),
                    delta: command.amount(),
                },
            ],
        )
        .map_err(|_| CommandRejectionCode::DiplomacyGoldUnavailable)?;
    mutation(
        state,
        diplomacy,
        economy,
        state.combat().clone(),
        [DomainEvent::DiplomaticScoreChanged(
            DiplomaticScoreChangedEvent::from_entry(&score),
        )],
    )
}

fn known_observers(
    diplomacy: &Diplomacy,
    aggressor: &PlayerId,
    victim: &PlayerId,
) -> Vec<PlayerId> {
    let mut observers = diplomacy
        .contacts()
        .iter()
        .filter_map(|pair| {
            if pair.first() == aggressor {
                Some(pair.second())
            } else if pair.second() == aggressor {
                Some(pair.first())
            } else {
                None
            }
        })
        .filter(|observer| *observer != victim && diplomacy.has_contact(observer, victim))
        .cloned()
        .collect::<Vec<_>>();
    observers.sort_unstable();
    observers.dedup();
    observers
}

fn gift_on_cooldown(
    diplomacy: &Diplomacy,
    actor: &PlayerId,
    target: &PlayerId,
    turn: u32,
    cooldown_turns: u32,
) -> bool {
    let pair = PlayerPair::new(actor.clone(), target.clone());
    diplomacy.score_history().iter().any(|entry| {
        pair.as_ref() == Some(entry.pair())
            && entry.reason() == DiplomaticScoreChangeReason::GoldGift
            && turn >= entry.turn()
            && turn - entry.turn() < cooldown_turns
    })
}
