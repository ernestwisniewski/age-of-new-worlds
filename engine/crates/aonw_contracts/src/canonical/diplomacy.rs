use serde::{Deserialize, Serialize};

use super::{PlayerPairDto, ResourceTypeDto};

/// Complete persisted diplomacy state.
#[allow(missing_docs)]
#[derive(Clone, Debug, Default, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct DiplomacyStateDto {
    pub contacts: Vec<PlayerPairDto>,
    pub relations: Vec<DiplomaticRelationDto>,
    pub pending_proposals: Vec<DiplomaticProposalDto>,
    pub messages: Vec<DiplomaticMessageDto>,
    pub score_history: Vec<DiplomaticScoreEntryDto>,
}

/// Persisted relationship between a normalized player pair.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct DiplomaticRelationDto {
    pub player_a_id: String,
    pub player_b_id: String,
    pub status: DiplomaticRelationStatusDto,
    pub relation_score: i64,
    pub status_expires_on_turn: Option<u32>,
    pub last_changed_turn: Option<u32>,
    pub last_change_reason: Option<DiplomaticRelationChangeReasonDto>,
}

/// Pending bilateral proposal.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct DiplomaticProposalDto {
    pub id: String,
    pub from_player_id: String,
    pub to_player_id: String,
    pub kind: DiplomaticProposalKindDto,
    pub created_turn: u32,
    pub expires_on_turn: u32,
    pub gold_payment: i64,
}

/// Persisted diplomatic message and optional response outcome.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct DiplomaticMessageDto {
    pub id: String,
    pub from_player_id: String,
    pub to_player_id: String,
    pub topic: DiplomaticMessageTopicDto,
    pub category: DiplomaticMessageCategoryDto,
    pub created_turn: u32,
    pub expires_on_turn: u32,
    pub response: Option<DiplomaticMessageResponseDto>,
    pub responded_turn: Option<u32>,
    pub relation_score_delta: i64,
    pub relation_score_after: Option<i64>,
    pub promise_due_turn: Option<u32>,
    pub promise_broken: bool,
}

/// One persisted relation-score audit entry.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct DiplomaticScoreEntryDto {
    pub player_a_id: String,
    pub player_b_id: String,
    pub turn: u32,
    pub delta: i64,
    pub score_after: i64,
    pub reason: DiplomaticScoreChangeReasonDto,
    pub source_id: Option<String>,
}

/// Active resource-for-gold transfer agreement.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ResourceTradeAgreementDto {
    pub id: String,
    pub exporter_player_id: String,
    pub importer_player_id: String,
    pub resource: ResourceTypeDto,
    pub gold_per_turn: i64,
    pub remaining_turns: u32,
    pub amount_per_turn: u32,
    pub exchange_group_id: Option<String>,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum DiplomaticRelationStatusDto {
    Friendly,
    Neutral,
    Hostile,
    Truce,
    War,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum DiplomaticRelationChangeReasonDto {
    Manual,
    UnitAttack,
    CityAttack,
    DeclarationOfWar,
    ProposalAccepted,
    TruceExpired,
    MessageResponse,
    PromiseBroken,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum DiplomaticProposalKindDto {
    Friendship,
    Truce,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum DiplomaticMessageCategoryDto {
    Warning,
    Complaint,
    Request,
    Praise,
    Threat,
    Cooperation,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum DiplomaticMessageTopicDto {
    TroopsNearCities,
    CitiesTooClose,
    BlockedRoutes,
    WithdrawScouts,
    AvoidEscalation,
    CommonEnemy,
    ExpansionProvocation,
    PeacefulPraise,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum DiplomaticMessageResponseDto {
    Conciliatory,
    Neutral,
    Evasive,
    Aggressive,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum DiplomaticScoreChangeReasonDto {
    Manual,
    UnitAttack,
    CityAttack,
    DeclarationOfWar,
    WarmongerPenalty,
    ProposalAccepted,
    ProposalRejected,
    MessageResponse,
    CommonEnemyCooperation,
    GoldGift,
    PromiseBroken,
}
