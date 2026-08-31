use aonw_domain::{
    Diplomacy, DiplomaticMessage, DiplomaticMessageResponse, DiplomaticMessageTopic,
    DiplomaticRelationStatus, DiplomaticScoreChangeReason, GameState, PlayerId, PlayerPair,
};

use super::{
    DiplomacyError, DiplomacyMutation, RespondDiplomaticMessageCommand,
    SendDiplomaticMessageCommand,
    support::{adjust_score, mutation, validate_actor, validate_revision},
};
use crate::{
    CommandRejectionCode, DiplomacyDisclosure, DiplomacyPolicyQuery,
    DiplomaticMessageRespondedEvent, DiplomaticMessageSentEvent, DiplomaticScoreChangedEvent,
    DomainEvent, EngineContext,
};

pub(crate) fn apply_send_message(
    state: &GameState,
    context: EngineContext<'_>,
    command: SendDiplomaticMessageCommand<'_>,
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
    if message_on_cooldown(
        state.diplomacy(),
        actor,
        target,
        command.topic(),
        state.turn(),
        context.ruleset().diplomacy().message_cooldown_turns(),
    ) {
        return Err(CommandRejectionCode::DiplomacyMessageCooldown.into());
    }

    let expires_on_turn = state
        .turn()
        .checked_add(context.ruleset().diplomacy().message_duration_turns())
        .ok_or_else(|| DiplomacyError::InvalidState("message expiry overflow".into()))?;
    let message_id = command.message_id().map_or_else(
        || generated_message_id(state, actor, target, command.topic()),
        str::to_owned,
    );
    let message = DiplomaticMessage::try_new(
        message_id,
        actor.clone(),
        target.clone(),
        command.topic(),
        command.topic().category(),
        state.turn(),
        expires_on_turn,
        None,
        None,
        0,
        None,
        None,
        false,
    )?;
    let diplomacy = state
        .diplomacy()
        .try_with_message(state.match_lifecycle().identity(), message.clone())
        .map_err(|error| match error {
            aonw_domain::DiplomacyStateBuildError::DuplicateId(_) => {
                DiplomacyError::Rejected(CommandRejectionCode::DiplomacyDuplicateMessage)
            }
            other => DiplomacyError::State(other),
        })?;
    mutation(
        state,
        diplomacy,
        state.economy().clone(),
        state.combat().clone(),
        [DomainEvent::DiplomaticMessageSent(
            DiplomaticMessageSentEvent::from_message(&message),
        )],
    )
}

pub(crate) fn apply_respond_message(
    state: &GameState,
    context: EngineContext<'_>,
    command: RespondDiplomaticMessageCommand<'_>,
) -> Result<DiplomacyMutation, DiplomacyError> {
    validate_revision(state, command.expected_revision())?;
    let actor = context.actor_player_id();
    validate_actor(state, context, actor)?;
    let message = state
        .diplomacy()
        .message(command.message_id())
        .filter(|message| message.to_player_id() == actor)
        .ok_or(CommandRejectionCode::DiplomacyMessageNotFound)?;
    if message.response().is_some() || state.turn() >= message.expires_on_turn() {
        return Err(CommandRejectionCode::DiplomacyMessageUnavailable.into());
    }

    let pair = PlayerPair::new(
        message.from_player_id().clone(),
        message.to_player_id().clone(),
    )
    .ok_or_else(|| DiplomacyError::InvalidState("message self relation".into()))?;
    let shared_enemy = has_shared_war_enemy(
        state.diplomacy(),
        message.from_player_id(),
        message.to_player_id(),
    );
    let cooperation_bonus =
        if message.topic() == DiplomaticMessageTopic::CommonEnemy && shared_enemy {
            context
                .ruleset()
                .diplomacy()
                .common_enemy_cooperation_bonus(command.response())
        } else {
            0
        };
    let delta = context
        .ruleset()
        .diplomacy()
        .message_response_score_delta(command.response())
        .saturating_add(cooperation_bonus);
    let reason = if cooperation_bonus == 0 {
        DiplomaticScoreChangeReason::MessageResponse
    } else {
        DiplomaticScoreChangeReason::CommonEnemyCooperation
    };
    let (diplomacy, score) = adjust_score(
        state.diplomacy(),
        state.match_lifecycle().identity(),
        &pair,
        state.turn(),
        delta,
        reason,
        Some(message.id()),
    )?;
    let promise_due_turn = if command.response() == DiplomaticMessageResponse::Conciliatory
        && can_create_withdrawal_promise(message.topic())
    {
        Some(
            state
                .turn()
                .checked_add(context.ruleset().diplomacy().promise_duration_turns())
                .ok_or_else(|| DiplomacyError::InvalidState("promise expiry overflow".into()))?,
        )
    } else {
        None
    };
    let updated = DiplomaticMessage::try_new(
        message.id().to_owned(),
        message.from_player_id().clone(),
        message.to_player_id().clone(),
        message.topic(),
        message.category(),
        message.created_turn(),
        message.expires_on_turn(),
        Some(command.response()),
        Some(state.turn()),
        score.delta(),
        Some(score.score_after()),
        promise_due_turn,
        false,
    )?;
    let diplomacy =
        diplomacy.try_replacing_message(state.match_lifecycle().identity(), updated.clone())?;
    mutation(
        state,
        diplomacy,
        state.economy().clone(),
        state.combat().clone(),
        [
            DomainEvent::DiplomaticMessageResponded(DiplomaticMessageRespondedEvent::from_message(
                &updated,
            )),
            DomainEvent::DiplomaticScoreChanged(DiplomaticScoreChangedEvent::from_entry(&score)),
        ],
    )
}

fn message_on_cooldown(
    diplomacy: &Diplomacy,
    actor: &PlayerId,
    target: &PlayerId,
    topic: DiplomaticMessageTopic,
    turn: u32,
    cooldown_turns: u32,
) -> bool {
    diplomacy.messages().iter().any(|message| {
        message.from_player_id() == actor
            && message.to_player_id() == target
            && message.category() == topic.category()
            && turn >= message.created_turn()
            && turn - message.created_turn() < cooldown_turns
    })
}

fn has_shared_war_enemy(diplomacy: &Diplomacy, first: &PlayerId, second: &PlayerId) -> bool {
    diplomacy.relations().iter().any(|relation| {
        if relation.status() != DiplomaticRelationStatus::War {
            return false;
        }
        let enemy = if relation.pair().first() == first {
            Some(relation.pair().second())
        } else if relation.pair().second() == first {
            Some(relation.pair().first())
        } else {
            None
        };
        enemy.is_some_and(|enemy| {
            enemy != second
                && diplomacy
                    .relation_between(second, enemy)
                    .is_some_and(|relation| relation.status() == DiplomaticRelationStatus::War)
        })
    })
}

fn generated_message_id(
    state: &GameState,
    actor: &PlayerId,
    target: &PlayerId,
    topic: DiplomaticMessageTopic,
) -> String {
    format!(
        "message.{}.{}.{}.{}.{}",
        state.turn(),
        actor.as_str(),
        target.as_str(),
        topic_name(topic),
        state.diplomacy().messages().len()
    )
}

const fn can_create_withdrawal_promise(topic: DiplomaticMessageTopic) -> bool {
    matches!(
        topic,
        DiplomaticMessageTopic::TroopsNearCities
            | DiplomaticMessageTopic::BlockedRoutes
            | DiplomaticMessageTopic::WithdrawScouts
    )
}

const fn topic_name(topic: DiplomaticMessageTopic) -> &'static str {
    match topic {
        DiplomaticMessageTopic::TroopsNearCities => "troopsNearCities",
        DiplomaticMessageTopic::CitiesTooClose => "citiesTooClose",
        DiplomaticMessageTopic::BlockedRoutes => "blockedRoutes",
        DiplomaticMessageTopic::WithdrawScouts => "withdrawScouts",
        DiplomaticMessageTopic::AvoidEscalation => "avoidEscalation",
        DiplomaticMessageTopic::CommonEnemy => "commonEnemy",
        DiplomaticMessageTopic::ExpansionProvocation => "expansionProvocation",
        DiplomaticMessageTopic::PeacefulPraise => "peacefulPraise",
    }
}

#[cfg(test)]
mod tests {
    use aonw_domain::{
        Diplomacy, DiplomaticRelation, DiplomaticRelationStatus, GameMode, MatchIdentity,
        MatchRules, Participant, PlayerCountry, PlayerId, PlayerKind, PlayerPair,
    };

    use super::has_shared_war_enemy;

    #[test]
    fn shared_enemy_requires_two_distinct_war_relations() {
        let first = player("first");
        let second = player("second");
        let enemy = player("enemy");
        let identity = MatchIdentity::try_new(
            MatchRules::default(),
            [
                participant(first.clone(), 1),
                participant(second.clone(), 2),
                participant(enemy.clone(), 3),
            ],
            GameMode::Multiplayer,
        )
        .expect("identity");
        let first_second = PlayerPair::new(first.clone(), second.clone()).expect("contact");
        let first_enemy = PlayerPair::new(first.clone(), enemy.clone()).expect("war");
        let second_enemy = PlayerPair::new(second.clone(), enemy.clone()).expect("war");
        let diplomacy = Diplomacy::try_new(
            &identity,
            [first_second, first_enemy.clone(), second_enemy.clone()],
            [
                DiplomaticRelation::try_new(
                    first_enemy,
                    DiplomaticRelationStatus::War,
                    0,
                    None,
                    None,
                    None,
                )
                .expect("first war"),
                DiplomaticRelation::try_new(
                    second_enemy,
                    DiplomaticRelationStatus::War,
                    0,
                    None,
                    None,
                    None,
                )
                .expect("second war"),
            ],
            [],
            [],
            [],
            [],
        )
        .expect("diplomacy");
        assert!(has_shared_war_enemy(&diplomacy, &first, &second));
        assert!(!has_shared_war_enemy(&diplomacy, &first, &enemy));
    }

    fn participant(id: PlayerId, color: u32) -> Participant {
        Participant::try_new(
            id,
            "Player",
            0xff00_0000 + color,
            PlayerCountry::Poland,
            PlayerKind::Human,
            None,
        )
        .expect("participant")
    }

    fn player(value: &str) -> PlayerId {
        PlayerId::new(value).expect("player")
    }
}
