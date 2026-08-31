use aonw_domain::{
    CombatState, DiplomaticProposal, DiplomaticProposalKind, DiplomaticRelation,
    DiplomaticRelationChangeReason, DiplomaticRelationStatus, DiplomaticScoreChangeReason,
    EconomyAccountChange, GameState, PlayerId, PlayerPair,
};

use super::{
    DiplomacyError, DiplomacyMutation, RespondDiplomaticProposalCommand,
    SendDiplomaticProposalCommand,
    support::{adjust_score, effective_relation, mutation, validate_actor, validate_revision},
};
use crate::{
    CommandRejectionCode, DiplomacyDisclosure, DiplomacyPolicyQuery,
    DiplomaticProposalRespondedEvent, DiplomaticProposalSentEvent, DiplomaticRelationChangedEvent,
    DiplomaticScoreChangedEvent, DomainEvent, EngineContext,
};

pub(crate) fn apply_send_proposal(
    state: &GameState,
    context: EngineContext<'_>,
    command: SendDiplomaticProposalCommand<'_>,
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
    if !proposal_allowed(command.kind(), policy.status()) {
        return Err(CommandRejectionCode::DiplomacyProposalNotAllowed.into());
    }
    if state
        .diplomacy()
        .pending_proposals()
        .iter()
        .any(|proposal| {
            proposal.from_player_id() == actor
                && proposal.to_player_id() == target
                && proposal.kind() == command.kind()
        })
    {
        return Err(CommandRejectionCode::DiplomacyDuplicateProposal.into());
    }

    let expires_on_turn = state
        .turn()
        .checked_add(context.ruleset().diplomacy().proposal_duration_turns())
        .ok_or_else(|| DiplomacyError::InvalidState("proposal expiry overflow".into()))?;
    let proposal_id = command.proposal_id().map_or_else(
        || generated_proposal_id(state, actor, target, command.kind()),
        str::to_owned,
    );
    let gold_payment = proposal_gold(state, actor, command.kind(), command.gold_payment());
    let proposal = DiplomaticProposal::try_new(
        proposal_id,
        actor.clone(),
        target.clone(),
        command.kind(),
        state.turn(),
        expires_on_turn,
        gold_payment,
    )?;
    let diplomacy = state
        .diplomacy()
        .try_with_proposal(state.match_lifecycle().identity(), proposal.clone())
        .map_err(|error| match error {
            aonw_domain::DiplomacyStateBuildError::DuplicateId(_) => {
                DiplomacyError::Rejected(CommandRejectionCode::DiplomacyDuplicateProposal)
            }
            other => DiplomacyError::State(other),
        })?;
    mutation(
        state,
        diplomacy,
        state.economy().clone(),
        state.combat().clone(),
        [DomainEvent::DiplomaticProposalSent(
            DiplomaticProposalSentEvent::from_proposal(&proposal),
        )],
    )
}

pub(crate) fn apply_respond_proposal(
    state: &GameState,
    context: EngineContext<'_>,
    command: RespondDiplomaticProposalCommand<'_>,
) -> Result<DiplomacyMutation, DiplomacyError> {
    validate_revision(state, command.expected_revision())?;
    let actor = context.actor_player_id();
    validate_actor(state, context, actor)?;
    let proposal = state
        .diplomacy()
        .proposal(command.proposal_id())
        .filter(|proposal| proposal.to_player_id() == actor)
        .ok_or(CommandRejectionCode::DiplomacyProposalNotFound)?;
    if command.accepted() && !proposal_payment_available(state, proposal) {
        return Err(CommandRejectionCode::DiplomacyProposalPaymentUnavailable.into());
    }
    if command.accepted() {
        accept_proposal(state, context, proposal)
    } else {
        reject_proposal(state, context, proposal)
    }
}

fn accept_proposal(
    state: &GameState,
    context: EngineContext<'_>,
    proposal: &DiplomaticProposal,
) -> Result<DiplomacyMutation, DiplomacyError> {
    let identity = state.match_lifecycle().identity();
    let pair = PlayerPair::new(
        proposal.from_player_id().clone(),
        proposal.to_player_id().clone(),
    )
    .ok_or_else(|| DiplomacyError::InvalidState("proposal self relation".into()))?;
    let old_status = effective_relation(state.diplomacy(), &pair).0;
    let (new_status, expires_on_turn, score_delta) = match proposal.kind() {
        DiplomaticProposalKind::Friendship => (
            DiplomaticRelationStatus::Friendly,
            None,
            context
                .ruleset()
                .diplomacy()
                .friendship_accept_score_delta(),
        ),
        DiplomaticProposalKind::Truce => (
            DiplomaticRelationStatus::Truce,
            Some(
                state
                    .turn()
                    .checked_add(context.ruleset().diplomacy().truce_duration_turns())
                    .ok_or_else(|| DiplomacyError::InvalidState("truce expiry overflow".into()))?,
            ),
            context.ruleset().diplomacy().truce_accept_score_delta(),
        ),
    };
    let diplomacy = state
        .diplomacy()
        .try_without_proposal(identity, proposal.id())?;
    let (_, old_score) = effective_relation(&diplomacy, &pair);
    let relation = DiplomaticRelation::try_new(
        pair.clone(),
        new_status,
        old_score,
        expires_on_turn,
        Some(state.turn()),
        Some(DiplomaticRelationChangeReason::ProposalAccepted),
    )?;
    let diplomacy = diplomacy.try_with_relation(identity, relation)?;
    let (diplomacy, score) = adjust_score(
        &diplomacy,
        identity,
        &pair,
        state.turn(),
        score_delta,
        DiplomaticScoreChangeReason::ProposalAccepted,
        Some(proposal.id()),
    )?;
    let economy = apply_proposal_payment(state, proposal)?;
    let combat = clear_pair_attacks(state, &pair)?;
    mutation(
        state,
        diplomacy,
        economy,
        combat,
        [
            DomainEvent::DiplomaticProposalResponded(
                DiplomaticProposalRespondedEvent::from_proposal(proposal, true),
            ),
            DomainEvent::DiplomaticRelationChanged(DiplomaticRelationChangedEvent::new(
                pair,
                old_status,
                new_status,
                DiplomaticRelationChangeReason::ProposalAccepted,
                expires_on_turn,
            )),
            DomainEvent::DiplomaticScoreChanged(DiplomaticScoreChangedEvent::from_entry(&score)),
        ],
    )
}

fn reject_proposal(
    state: &GameState,
    context: EngineContext<'_>,
    proposal: &DiplomaticProposal,
) -> Result<DiplomacyMutation, DiplomacyError> {
    let identity = state.match_lifecycle().identity();
    let pair = PlayerPair::new(
        proposal.from_player_id().clone(),
        proposal.to_player_id().clone(),
    )
    .ok_or_else(|| DiplomacyError::InvalidState("proposal self relation".into()))?;
    let diplomacy = state
        .diplomacy()
        .try_without_proposal(identity, proposal.id())?;
    let (diplomacy, score) = adjust_score(
        &diplomacy,
        identity,
        &pair,
        state.turn(),
        context.ruleset().diplomacy().proposal_reject_score_delta(),
        DiplomaticScoreChangeReason::ProposalRejected,
        Some(proposal.id()),
    )?;
    mutation(
        state,
        diplomacy,
        state.economy().clone(),
        state.combat().clone(),
        [
            DomainEvent::DiplomaticProposalResponded(
                DiplomaticProposalRespondedEvent::from_proposal(proposal, false),
            ),
            DomainEvent::DiplomaticScoreChanged(DiplomaticScoreChangedEvent::from_entry(&score)),
        ],
    )
}

fn apply_proposal_payment(
    state: &GameState,
    proposal: &DiplomaticProposal,
) -> Result<aonw_domain::EconomyState, DiplomacyError> {
    if proposal.gold_payment() == 0 {
        return Ok(state.economy().clone());
    }
    Ok(state.economy().try_after_changes(
        state.match_lifecycle().identity(),
        state.bounds(),
        [
            EconomyAccountChange::Gold {
                player: proposal.from_player_id().clone(),
                delta: -proposal.gold_payment(),
            },
            EconomyAccountChange::Gold {
                player: proposal.to_player_id().clone(),
                delta: proposal.gold_payment(),
            },
        ],
    )?)
}

fn clear_pair_attacks(state: &GameState, pair: &PlayerPair) -> Result<CombatState, DiplomacyError> {
    CombatState::try_new(
        state
            .combat()
            .intended_attacks()
            .iter()
            .filter(|attack| {
                target_owner(state, attack.defender()).is_none_or(|defender| {
                    PlayerPair::new(attack.declaring_player_id().clone(), defender.clone()).as_ref()
                        != Some(pair)
                })
            })
            .cloned(),
    )
    .map_err(|unit| DiplomacyError::Combat(format!("duplicate intended attack: {unit}").into()))
}

fn target_owner(state: &GameState, coordinate: aonw_domain::HexCoord) -> Option<&PlayerId> {
    state
        .units_at(coordinate)
        .next()
        .map(aonw_domain::Unit::owner_player_id)
        .or_else(|| {
            state
                .city_at(coordinate)
                .map(aonw_domain::City::owner_player_id)
        })
}

fn proposal_payment_available(state: &GameState, proposal: &DiplomaticProposal) -> bool {
    state
        .economy()
        .player_gold()
        .get(proposal.from_player_id())
        .copied()
        .unwrap_or(0)
        >= proposal.gold_payment()
}

fn proposal_gold(
    state: &GameState,
    actor: &PlayerId,
    kind: DiplomaticProposalKind,
    requested: i64,
) -> i64 {
    if kind != DiplomaticProposalKind::Truce || requested <= 0 {
        return 0;
    }
    requested.min(
        state
            .economy()
            .player_gold()
            .get(actor)
            .copied()
            .unwrap_or(0),
    )
}

fn generated_proposal_id(
    state: &GameState,
    actor: &PlayerId,
    target: &PlayerId,
    kind: DiplomaticProposalKind,
) -> String {
    let kind = match kind {
        DiplomaticProposalKind::Friendship => "friendship",
        DiplomaticProposalKind::Truce => "truce",
    };
    format!(
        "proposal.{}.{}.{}.{}.{}",
        state.turn(),
        actor.as_str(),
        target.as_str(),
        kind,
        state.diplomacy().pending_proposals().len()
    )
}

const fn proposal_allowed(kind: DiplomaticProposalKind, status: DiplomaticRelationStatus) -> bool {
    match kind {
        DiplomaticProposalKind::Friendship => matches!(
            status,
            DiplomaticRelationStatus::Neutral
                | DiplomaticRelationStatus::Hostile
                | DiplomaticRelationStatus::Truce
        ),
        DiplomaticProposalKind::Truce => matches!(
            status,
            DiplomaticRelationStatus::Hostile | DiplomaticRelationStatus::War
        ),
    }
}
