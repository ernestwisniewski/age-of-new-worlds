use aonw_content::RulesetDefinition;
use aonw_domain::{
    Diplomacy, DiplomaticMessage, DiplomaticMessageTopic, DiplomaticRelation,
    DiplomaticRelationChangeReason, DiplomaticRelationStatus, DiplomaticScoreChangeReason,
    GameState, PlayerPair, Unit,
};

use crate::diplomacy::support::adjust_score;
use crate::{
    DiplomacyError, DiplomaticPromiseBrokenEvent, DiplomaticProposalExpiredEvent,
    DiplomaticRelationChangedEvent, DiplomaticScoreChangedEvent, DomainEvent,
};

pub(super) struct TurnDiplomacyPhase {
    pub(super) diplomacy: Diplomacy,
    pub(super) events: Vec<DomainEvent>,
}

pub(super) fn advance_turn_diplomacy(
    state: &GameState,
    ruleset: &RulesetDefinition,
    units: &[Unit],
    mut diplomacy: Diplomacy,
    turn: u32,
) -> Result<TurnDiplomacyPhase, DiplomacyError> {
    let identity = state.match_lifecycle().identity();
    let mut events = Vec::new();
    let expired_proposals = diplomacy
        .pending_proposals()
        .iter()
        .filter(|proposal| proposal.expires_on_turn() <= turn)
        .cloned()
        .collect::<Vec<_>>();
    for proposal in expired_proposals {
        diplomacy = diplomacy.try_without_proposal(identity, proposal.id())?;
        events.push(DomainEvent::DiplomaticProposalExpired(
            DiplomaticProposalExpiredEvent::from_proposal(&proposal),
        ));
    }

    let expired_message_ids = diplomacy
        .messages()
        .iter()
        .filter(|message| message.response().is_none() && message.expires_on_turn() <= turn)
        .map(|message| message.id().to_owned())
        .collect::<Vec<_>>();
    for message_id in expired_message_ids {
        diplomacy = diplomacy.try_without_message(identity, &message_id)?;
    }

    let expired_truces = diplomacy
        .relations()
        .iter()
        .filter(|relation| {
            relation.status() == DiplomaticRelationStatus::Truce
                && relation
                    .status_expires_on_turn()
                    .is_some_and(|expiry| expiry <= turn)
        })
        .cloned()
        .collect::<Vec<_>>();
    for relation in expired_truces {
        let neutral = DiplomaticRelation::try_new(
            relation.pair().clone(),
            DiplomaticRelationStatus::Neutral,
            relation.relation_score(),
            None,
            Some(turn),
            Some(DiplomaticRelationChangeReason::TruceExpired),
        )?;
        diplomacy = diplomacy.try_with_relation(identity, neutral)?;
        events.push(DomainEvent::DiplomaticRelationChanged(
            DiplomaticRelationChangedEvent::new(
                relation.pair().clone(),
                DiplomaticRelationStatus::Truce,
                DiplomaticRelationStatus::Neutral,
                DiplomaticRelationChangeReason::TruceExpired,
                None,
            ),
        ));
    }

    let promises_due = diplomacy
        .messages()
        .iter()
        .filter(|message| {
            message.response().is_some()
                && !message.promise_broken()
                && message
                    .promise_due_turn()
                    .is_some_and(|due_turn| due_turn <= turn)
        })
        .cloned()
        .collect::<Vec<_>>();
    for promise in promises_due {
        if !promise_is_broken(state, units, &promise) {
            continue;
        }
        let marked = message_with_broken_promise(&promise)?;
        diplomacy = diplomacy.try_replacing_message(identity, marked)?;
        let pair = PlayerPair::new(
            promise.from_player_id().clone(),
            promise.to_player_id().clone(),
        )
        .ok_or_else(|| DiplomacyError::InvalidState("promise self relation".into()))?;
        let (next, score) = adjust_score(
            &diplomacy,
            identity,
            &pair,
            turn,
            ruleset.diplomacy().promise_broken_score_delta(),
            DiplomaticScoreChangeReason::PromiseBroken,
            Some(promise.id()),
        )?;
        diplomacy = next;
        events.push(DomainEvent::DiplomaticPromiseBroken(
            DiplomaticPromiseBrokenEvent::new(
                promise.id().to_owned(),
                pair,
                score.delta(),
                score.score_after(),
            ),
        ));
        events.push(DomainEvent::DiplomaticScoreChanged(
            DiplomaticScoreChangedEvent::from_entry(&score),
        ));
    }
    Ok(TurnDiplomacyPhase { diplomacy, events })
}

fn promise_is_broken(state: &GameState, units: &[Unit], promise: &DiplomaticMessage) -> bool {
    if !can_create_withdrawal_promise(promise.topic()) {
        return false;
    }
    let protected_cities = state
        .cities()
        .iter()
        .filter(|city| city.owner_player_id() == promise.from_player_id())
        .collect::<Vec<_>>();
    !protected_cities.is_empty()
        && units.iter().any(|unit| {
            unit.owner_player_id() == promise.to_player_id()
                && protected_cities
                    .iter()
                    .any(|city| unit.position().distance_to(city.center()) <= 2)
        })
}

fn message_with_broken_promise(
    message: &DiplomaticMessage,
) -> Result<DiplomaticMessage, DiplomacyError> {
    Ok(DiplomaticMessage::try_new(
        message.id().to_owned(),
        message.from_player_id().clone(),
        message.to_player_id().clone(),
        message.topic(),
        message.category(),
        message.created_turn(),
        message.expires_on_turn(),
        message.response(),
        message.responded_turn(),
        message.relation_score_delta(),
        message.relation_score_after(),
        message.promise_due_turn(),
        true,
    )?)
}

const fn can_create_withdrawal_promise(topic: DiplomaticMessageTopic) -> bool {
    matches!(
        topic,
        DiplomaticMessageTopic::TroopsNearCities
            | DiplomaticMessageTopic::BlockedRoutes
            | DiplomaticMessageTopic::WithdrawScouts
    )
}
