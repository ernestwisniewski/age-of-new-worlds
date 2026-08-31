use std::collections::BTreeSet;

use aonw_contracts::{
    DiplomacyStateDto, DiplomaticMessageCategoryDto, DiplomaticMessageDto,
    DiplomaticMessageResponseDto, DiplomaticMessageTopicDto, DiplomaticProposalDto,
    DiplomaticProposalKindDto, DiplomaticRelationChangeReasonDto, DiplomaticRelationDto,
    DiplomaticRelationStatusDto, DiplomaticScoreChangeReasonDto, DiplomaticScoreEntryDto,
    PlayerPairDto, ResourceTradeAgreementDto,
};
use aonw_domain::{
    Diplomacy, DiplomacyStateBuildError, DiplomaticMessage, DiplomaticMessageCategory,
    DiplomaticMessageResponse, DiplomaticMessageTopic, DiplomaticProposal, DiplomaticProposalKind,
    DiplomaticRelation, DiplomaticRelationChangeReason, DiplomaticRelationStatus,
    DiplomaticScoreChangeReason, DiplomaticScoreEntry, MatchIdentity, PlayerId, PlayerPair,
    ResourceTradeAgreement,
};

use super::economy::{decode_resource, encode_resource};
use super::error::GameStateMappingError;

pub(super) fn decode_diplomacy(
    identity: &MatchIdentity,
    dto: DiplomacyStateDto,
    trades: Vec<ResourceTradeAgreementDto>,
) -> Result<Diplomacy, GameStateMappingError> {
    reject_duplicate_ids(
        &dto.pending_proposals,
        "$.diplomacy.pendingProposals",
        |value| &value.id,
    )?;
    reject_duplicate_ids(&dto.messages, "$.diplomacy.messages", |value| &value.id)?;
    reject_duplicate_ids(&trades, "$.resourceTradeAgreements", |value| &value.id)?;
    let contacts = dto
        .contacts
        .into_iter()
        .enumerate()
        .map(|(index, value)| {
            decode_pair(identity, value, &format!("$.diplomacy.contacts[{index}]"))
        })
        .collect::<Result<Vec<_>, _>>()?;
    let relations = dto
        .relations
        .into_iter()
        .enumerate()
        .map(|(index, value)| {
            decode_relation(identity, value, &format!("$.diplomacy.relations[{index}]"))
        })
        .collect::<Result<Vec<_>, _>>()?;
    let proposals = dto
        .pending_proposals
        .into_iter()
        .enumerate()
        .map(|(index, value)| {
            decode_proposal(
                identity,
                value,
                &format!("$.diplomacy.pendingProposals[{index}]"),
            )
        })
        .collect::<Result<Vec<_>, _>>()?;
    let messages = dto
        .messages
        .into_iter()
        .enumerate()
        .map(|(index, value)| {
            decode_message(identity, value, &format!("$.diplomacy.messages[{index}]"))
        })
        .collect::<Result<Vec<_>, _>>()?;
    let score_history = dto
        .score_history
        .into_iter()
        .enumerate()
        .map(|(index, value)| {
            decode_score_entry(
                identity,
                value,
                &format!("$.diplomacy.scoreHistory[{index}]"),
            )
        })
        .collect::<Result<Vec<_>, _>>()?;
    let trades = trades
        .into_iter()
        .enumerate()
        .map(|(index, value)| {
            decode_trade(
                identity,
                value,
                &format!("$.resourceTradeAgreements[{index}]"),
            )
        })
        .collect::<Result<Vec<_>, _>>()?;
    Diplomacy::try_new(
        identity,
        contacts,
        relations,
        proposals,
        messages,
        score_history,
        trades,
    )
    .map_err(|error| map_aggregate_error(&error))
}

#[must_use]
pub(super) fn encode_diplomacy(
    value: &Diplomacy,
) -> (DiplomacyStateDto, Vec<ResourceTradeAgreementDto>) {
    let dto = DiplomacyStateDto {
        contacts: value.contacts().iter().map(encode_pair).collect(),
        relations: value.relations().iter().map(encode_relation).collect(),
        pending_proposals: value
            .pending_proposals()
            .iter()
            .map(encode_proposal)
            .collect(),
        messages: value.messages().iter().map(encode_message).collect(),
        score_history: value
            .score_history()
            .iter()
            .map(encode_score_entry)
            .collect(),
    };
    let trades = value
        .resource_trade_agreements()
        .iter()
        .map(encode_trade)
        .collect();
    (dto, trades)
}

fn decode_pair(
    identity: &MatchIdentity,
    value: PlayerPairDto,
    path: &str,
) -> Result<PlayerPair, GameStateMappingError> {
    let first = decode_player(
        identity,
        value.first_player_id,
        &format!("{path}.firstPlayerId"),
    )?;
    let second = decode_player(
        identity,
        value.second_player_id,
        &format!("{path}.secondPlayerId"),
    )?;
    PlayerPair::new(first, second)
        .ok_or_else(|| GameStateMappingError::new(path, "diplomatic pair must contain two players"))
}

fn decode_relation(
    identity: &MatchIdentity,
    value: DiplomaticRelationDto,
    path: &str,
) -> Result<DiplomaticRelation, GameStateMappingError> {
    let pair = decode_pair(
        identity,
        PlayerPairDto {
            first_player_id: value.player_a_id,
            second_player_id: value.player_b_id,
        },
        path,
    )?;
    DiplomaticRelation::try_new(
        pair,
        decode_relation_status(value.status),
        value.relation_score,
        value.status_expires_on_turn,
        value.last_changed_turn,
        value.last_change_reason.map(decode_relation_reason),
    )
    .map_err(|error| local_error(path, &error))
}

fn decode_proposal(
    identity: &MatchIdentity,
    value: DiplomaticProposalDto,
    path: &str,
) -> Result<DiplomaticProposal, GameStateMappingError> {
    let from = decode_player(
        identity,
        value.from_player_id,
        &format!("{path}.fromPlayerId"),
    )?;
    let to = decode_player(identity, value.to_player_id, &format!("{path}.toPlayerId"))?;
    DiplomaticProposal::try_new(
        value.id,
        from,
        to,
        decode_proposal_kind(value.kind),
        value.created_turn,
        value.expires_on_turn,
        value.gold_payment,
    )
    .map_err(|error| local_error(path, &error))
}

fn decode_message(
    identity: &MatchIdentity,
    value: DiplomaticMessageDto,
    path: &str,
) -> Result<DiplomaticMessage, GameStateMappingError> {
    let from = decode_player(
        identity,
        value.from_player_id,
        &format!("{path}.fromPlayerId"),
    )?;
    let to = decode_player(identity, value.to_player_id, &format!("{path}.toPlayerId"))?;
    DiplomaticMessage::try_new(
        value.id,
        from,
        to,
        decode_message_topic(value.topic),
        decode_message_category(value.category),
        value.created_turn,
        value.expires_on_turn,
        value.response.map(decode_message_response),
        value.responded_turn,
        value.relation_score_delta,
        value.relation_score_after,
        value.promise_due_turn,
        value.promise_broken,
    )
    .map_err(|error| local_error(path, &error))
}

fn decode_score_entry(
    identity: &MatchIdentity,
    value: DiplomaticScoreEntryDto,
    path: &str,
) -> Result<DiplomaticScoreEntry, GameStateMappingError> {
    let pair = decode_pair(
        identity,
        PlayerPairDto {
            first_player_id: value.player_a_id,
            second_player_id: value.player_b_id,
        },
        path,
    )?;
    DiplomaticScoreEntry::try_new(
        pair,
        value.turn,
        value.delta,
        value.score_after,
        decode_score_reason(value.reason),
        value.source_id,
    )
    .map_err(|error| local_error(path, &error))
}

fn decode_trade(
    identity: &MatchIdentity,
    value: ResourceTradeAgreementDto,
    path: &str,
) -> Result<ResourceTradeAgreement, GameStateMappingError> {
    if value.gold_per_turn < 0 {
        return Err(GameStateMappingError::new(
            format!("{path}.goldPerTurn"),
            "gold value must be non-negative",
        ));
    }
    if value.remaining_turns == 0 {
        return Err(GameStateMappingError::new(
            format!("{path}.remainingTurns"),
            "trade duration must be positive",
        ));
    }
    if value.amount_per_turn == 0 {
        return Err(GameStateMappingError::new(
            format!("{path}.amountPerTurn"),
            "trade resource amount must be positive",
        ));
    }
    if value
        .exchange_group_id
        .as_deref()
        .is_some_and(str::is_empty)
    {
        return Err(GameStateMappingError::new(
            format!("{path}.exchangeGroupId"),
            "identifier must be non-empty",
        ));
    }
    let exporter = decode_player(
        identity,
        value.exporter_player_id,
        &format!("{path}.exporterPlayerId"),
    )?;
    let importer = decode_player(
        identity,
        value.importer_player_id,
        &format!("{path}.importerPlayerId"),
    )?;
    ResourceTradeAgreement::try_new(
        value.id,
        exporter,
        importer,
        decode_resource(value.resource),
        value.gold_per_turn,
        value.remaining_turns,
        value.amount_per_turn,
        value.exchange_group_id,
    )
    .map_err(|error| local_error(path, &error))
}

fn decode_player(
    identity: &MatchIdentity,
    value: String,
    path: &str,
) -> Result<PlayerId, GameStateMappingError> {
    let player = PlayerId::new(value)
        .map_err(|error| GameStateMappingError::new(path, error.to_string()))?;
    if identity.contains(&player) {
        Ok(player)
    } else {
        Err(GameStateMappingError::new(
            path,
            format!("diplomacy references non-participant: {player}"),
        ))
    }
}

fn reject_duplicate_ids<T>(
    values: &[T],
    path: &str,
    id: impl Fn(&T) -> &str,
) -> Result<(), GameStateMappingError> {
    let mut ids = BTreeSet::new();
    for (index, value) in values.iter().enumerate() {
        if !ids.insert(id(value)) {
            return Err(GameStateMappingError::new(
                format!("{path}[{index}].id"),
                "duplicate identifier",
            ));
        }
    }
    Ok(())
}

fn local_error(path: &str, error: &DiplomacyStateBuildError) -> GameStateMappingError {
    let field = match error {
        DiplomacyStateBuildError::EmptyId | DiplomacyStateBuildError::IdNotFound(_) => "id",
        DiplomacyStateBuildError::RelationScoreOutOfRange(_) => "relationScore",
        DiplomacyStateBuildError::InvalidTurnRange => "expiresOnTurn",
        DiplomacyStateBuildError::NegativeGold(_) => "goldPayment",
        DiplomacyStateBuildError::MessageCategoryMismatch => "category",
        DiplomacyStateBuildError::MessageResponseMismatch => "respondedTurn",
        DiplomacyStateBuildError::PromiseWithoutResponse => "promiseDueTurn",
        DiplomacyStateBuildError::BrokenPromiseWithoutDueTurn => "promiseBroken",
        DiplomacyStateBuildError::NonPositiveTrade => "remainingTurns",
        _ => return GameStateMappingError::new(path, error.to_string()),
    };
    GameStateMappingError::new(format!("{path}.{field}"), error.to_string())
}

fn map_aggregate_error(error: &DiplomacyStateBuildError) -> GameStateMappingError {
    let path = match error {
        DiplomacyStateBuildError::DuplicateContact(_) => "$.diplomacy.contacts",
        DiplomacyStateBuildError::DuplicateRelation(_) => "$.diplomacy.relations",
        DiplomacyStateBuildError::DuplicateScoreEntry { .. } => "$.diplomacy.scoreHistory",
        _ => "$.diplomacy",
    };
    GameStateMappingError::new(path, error.to_string())
}

fn encode_pair(value: &PlayerPair) -> PlayerPairDto {
    PlayerPairDto {
        first_player_id: value.first().as_str().to_owned(),
        second_player_id: value.second().as_str().to_owned(),
    }
}

fn encode_relation(value: &DiplomaticRelation) -> DiplomaticRelationDto {
    DiplomaticRelationDto {
        player_a_id: value.pair().first().as_str().to_owned(),
        player_b_id: value.pair().second().as_str().to_owned(),
        status: encode_relation_status(value.status()),
        relation_score: value.relation_score(),
        status_expires_on_turn: value.status_expires_on_turn(),
        last_changed_turn: value.last_changed_turn(),
        last_change_reason: value.last_change_reason().map(encode_relation_reason),
    }
}

fn encode_proposal(value: &DiplomaticProposal) -> DiplomaticProposalDto {
    DiplomaticProposalDto {
        id: value.id().to_owned(),
        from_player_id: value.from_player_id().as_str().to_owned(),
        to_player_id: value.to_player_id().as_str().to_owned(),
        kind: encode_proposal_kind(value.kind()),
        created_turn: value.created_turn(),
        expires_on_turn: value.expires_on_turn(),
        gold_payment: value.gold_payment(),
    }
}

fn encode_message(value: &DiplomaticMessage) -> DiplomaticMessageDto {
    DiplomaticMessageDto {
        id: value.id().to_owned(),
        from_player_id: value.from_player_id().as_str().to_owned(),
        to_player_id: value.to_player_id().as_str().to_owned(),
        topic: encode_message_topic(value.topic()),
        category: encode_message_category(value.category()),
        created_turn: value.created_turn(),
        expires_on_turn: value.expires_on_turn(),
        response: value.response().map(encode_message_response),
        responded_turn: value.responded_turn(),
        relation_score_delta: value.relation_score_delta(),
        relation_score_after: value.relation_score_after(),
        promise_due_turn: value.promise_due_turn(),
        promise_broken: value.promise_broken(),
    }
}

fn encode_score_entry(value: &DiplomaticScoreEntry) -> DiplomaticScoreEntryDto {
    DiplomaticScoreEntryDto {
        player_a_id: value.pair().first().as_str().to_owned(),
        player_b_id: value.pair().second().as_str().to_owned(),
        turn: value.turn(),
        delta: value.delta(),
        score_after: value.score_after(),
        reason: encode_score_reason(value.reason()),
        source_id: value.source_id().map(str::to_owned),
    }
}

fn encode_trade(value: &ResourceTradeAgreement) -> ResourceTradeAgreementDto {
    ResourceTradeAgreementDto {
        id: value.id().to_owned(),
        exporter_player_id: value.exporter_player_id().as_str().to_owned(),
        importer_player_id: value.importer_player_id().as_str().to_owned(),
        resource: encode_resource(value.resource()),
        gold_per_turn: value.gold_per_turn(),
        remaining_turns: value.remaining_turns(),
        amount_per_turn: value.amount_per_turn(),
        exchange_group_id: value.exchange_group_id().map(str::to_owned),
    }
}

macro_rules! enum_mapping {
    ($decode:ident, $encode:ident, $dto:ident, $domain:ident; $($variant:ident),+ $(,)?) => {
        const fn $decode(value: $dto) -> $domain { match value { $($dto::$variant => $domain::$variant),+ } }
        const fn $encode(value: $domain) -> $dto { match value { $($domain::$variant => $dto::$variant),+ } }
    };
}

enum_mapping!(decode_relation_status, encode_relation_status, DiplomaticRelationStatusDto, DiplomaticRelationStatus; Friendly, Neutral, Hostile, Truce, War);
enum_mapping!(decode_relation_reason, encode_relation_reason, DiplomaticRelationChangeReasonDto, DiplomaticRelationChangeReason; Manual, UnitAttack, CityAttack, DeclarationOfWar, ProposalAccepted, TruceExpired, MessageResponse, PromiseBroken);
enum_mapping!(decode_proposal_kind, encode_proposal_kind, DiplomaticProposalKindDto, DiplomaticProposalKind; Friendship, Truce);
enum_mapping!(decode_message_category, encode_message_category, DiplomaticMessageCategoryDto, DiplomaticMessageCategory; Warning, Complaint, Request, Praise, Threat, Cooperation);
enum_mapping!(decode_message_topic, encode_message_topic, DiplomaticMessageTopicDto, DiplomaticMessageTopic; TroopsNearCities, CitiesTooClose, BlockedRoutes, WithdrawScouts, AvoidEscalation, CommonEnemy, ExpansionProvocation, PeacefulPraise);
enum_mapping!(decode_message_response, encode_message_response, DiplomaticMessageResponseDto, DiplomaticMessageResponse; Conciliatory, Neutral, Evasive, Aggressive);
enum_mapping!(decode_score_reason, encode_score_reason, DiplomaticScoreChangeReasonDto, DiplomaticScoreChangeReason; Manual, UnitAttack, CityAttack, DeclarationOfWar, WarmongerPenalty, ProposalAccepted, ProposalRejected, MessageResponse, CommonEnemyCooperation, GoldGift, PromiseBroken);
