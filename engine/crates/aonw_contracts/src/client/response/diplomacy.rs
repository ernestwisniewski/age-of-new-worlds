use serde::{Deserialize, Serialize};

use crate::{
    DiplomaticMessageCategoryDto, DiplomaticMessageResponseDto, DiplomaticMessageTopicDto,
    DiplomaticProposalKindDto, DiplomaticRelationChangeReasonDto, DiplomaticRelationStatusDto,
    ResourceTypeDto,
};

/// Complete diplomacy state visible to one recipient.
#[derive(Clone, Debug, Default, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerDiplomacyViewDto {
    /// Effective bilateral relations for every discovered counterparty.
    pub relations: Vec<PlayerDiplomaticRelationViewDto>,
    /// Pending proposals sent or received by this recipient.
    pub proposals: Vec<PlayerDiplomaticProposalViewDto>,
    /// Messages sent or received by this recipient.
    pub messages: Vec<PlayerDiplomaticMessageViewDto>,
    /// Active resource agreements involving this recipient.
    pub resource_trade_agreements: Vec<PlayerResourceTradeAgreementViewDto>,
}

/// One effective bilateral relation visible to a participant.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerDiplomaticRelationViewDto {
    /// The other participant in this bilateral relation.
    pub counterpart_player_id: String,
    /// Current effective relation status.
    pub status: DiplomaticRelationStatusDto,
    /// Current bounded bilateral score.
    pub relation_score: i64,
    /// Turn on which a temporary status expires.
    pub status_expires_on_turn: Option<u32>,
    /// Turn of the last explicit relation transition.
    pub last_changed_turn: Option<u32>,
    /// Reason for the last explicit relation transition.
    pub last_change_reason: Option<DiplomaticRelationChangeReasonDto>,
}

/// One pending proposal visible to its sender and recipient.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerDiplomaticProposalViewDto {
    /// Stable proposal identifier.
    pub id: String,
    /// Sending participant.
    pub from_player_id: String,
    /// Receiving participant.
    pub to_player_id: String,
    /// Friendship or truce proposal.
    pub kind: DiplomaticProposalKindDto,
    /// Turn on which the proposal was created.
    pub created_turn: u32,
    /// Last turn on which the proposal may be answered.
    pub expires_on_turn: u32,
    /// Requested truce payment.
    pub gold_payment: i64,
}

/// One message visible to its sender and recipient.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerDiplomaticMessageViewDto {
    /// Stable message identifier.
    pub id: String,
    /// Sending participant.
    pub from_player_id: String,
    /// Receiving participant.
    pub to_player_id: String,
    /// Exact current message topic.
    pub topic: DiplomaticMessageTopicDto,
    /// Category derived by current rules.
    pub category: DiplomaticMessageCategoryDto,
    /// Turn on which the message was created.
    pub created_turn: u32,
    /// Last turn on which the message may be answered.
    pub expires_on_turn: u32,
    /// Selected response, when already answered.
    pub response: Option<DiplomaticMessageResponseDto>,
    /// Turn on which the response was recorded.
    pub responded_turn: Option<u32>,
    /// Relation score delta produced by the response.
    pub relation_score_delta: i64,
    /// Relation score after the response.
    pub relation_score_after: Option<i64>,
    /// Turn on which a response promise becomes due.
    pub promise_due_turn: Option<u32>,
    /// Whether the persisted promise was broken.
    pub promise_broken: bool,
}

/// One active resource agreement visible to its importer and exporter.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerResourceTradeAgreementViewDto {
    /// Stable agreement identifier.
    pub id: String,
    /// Resource-exporting participant.
    pub exporter_player_id: String,
    /// Resource-importing participant.
    pub importer_player_id: String,
    /// Strategic resource delivered each successful settlement.
    pub resource: ResourceTypeDto,
    /// Gold transferred from importer to exporter each settlement.
    pub gold_per_turn: i64,
    /// Remaining settlement attempts including the next turn.
    pub remaining_turns: u32,
    /// Resource units delivered per successful settlement.
    pub amount_per_turn: u32,
    /// Shared atomic group for reciprocal exchange legs.
    pub exchange_group_id: Option<String>,
}
