use serde::{Deserialize, Serialize};

use crate::{
    CityBuildingTypeDto, CityConquestActionDto, CityProjectTypeDto, CitySpecializationTypeDto,
    CoordinateDto, DiplomaticMessageResponseDto, DiplomaticMessageTopicDto,
    DiplomaticProposalKindDto, FieldImprovementKindDto, ResourceTypeDto, TechnologyIdDto,
    TroopKindDto, UnitKindDto, WonderTypeDto,
};

/// One revision-bound command stored in a replay.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ReplayCommandDto {
    /// Declares war on one discovered participant.
    DeclareWar {
        expected_revision: u64,
        target_player_id: String,
    },
    /// Transfers a gold gift to one discovered participant.
    SendGoldGift {
        expected_revision: u64,
        target_player_id: String,
        amount: i64,
    },
    /// Opens one resource-for-gold agreement.
    OpenResourceTrade {
        expected_revision: u64,
        target_player_id: String,
        resource: ResourceTypeDto,
        gold_per_turn: i64,
        duration_turns: i64,
        agreement_id: Option<String>,
    },
    /// Opens one atomic two-resource exchange.
    OpenResourceExchange {
        expected_revision: u64,
        target_player_id: String,
        offered_resource: ResourceTypeDto,
        requested_resource: ResourceTypeDto,
        duration_turns: i64,
        agreement_id: Option<String>,
    },
    /// Selects one currently available research target.
    SelectTechnology {
        expected_revision: u64,
        technology_id: TechnologyIdDto,
    },
    /// Sends one current bilateral friendship or truce proposal.
    SendDiplomaticProposal {
        expected_revision: u64,
        target_player_id: String,
        kind: DiplomaticProposalKindDto,
        proposal_id: Option<String>,
        gold_payment: i64,
    },
    /// Accepts or rejects one proposal addressed to the authenticated actor.
    RespondDiplomaticProposal {
        expected_revision: u64,
        proposal_id: String,
        accepted: bool,
    },
    /// Sends one private bilateral diplomatic message.
    SendDiplomaticMessage {
        expected_revision: u64,
        target_player_id: String,
        topic: DiplomaticMessageTopicDto,
        message_id: Option<String>,
    },
    /// Responds to one message addressed to the authenticated actor.
    RespondDiplomaticMessage {
        expected_revision: u64,
        message_id: String,
        response: DiplomaticMessageResponseDto,
    },
    /// Starts excavating the artifact at one controlled unit.
    StartArtifactExcavation {
        expected_revision: u64,
        unit_id: String,
    },
    /// Stores the artifact carried by one controlled unit.
    StoreArtifactInCity {
        expected_revision: u64,
        unit_id: String,
        city_id: Option<String>,
    },
    /// Transfers one stored artifact and optional offered gold to another player.
    TradeArtifact {
        expected_revision: u64,
        target_player_id: String,
        offered_artifact_id: String,
        offered_gold: i64,
    },
    /// Schedules a validated city-founding job.
    FoundCity {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Controlled founder.
        founder_unit_id: String,
        /// Complete initial non-center territory.
        controlled_hexes: Vec<CoordinateDto>,
    },
    /// Toggles one manually worked city coordinate.
    ToggleWorkedHex {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Controlled city.
        city_id: String,
        /// Non-center controlled coordinate.
        target: CoordinateDto,
    },
    /// Selects one current city-expansion candidate.
    SelectCityExpansionHex {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Controlled city.
        city_id: String,
        /// Preferred expansion coordinate.
        target: CoordinateDto,
    },
    /// Starts construction of one building.
    StartBuilding {
        expected_revision: u64,
        city_id: String,
        building: CityBuildingTypeDto,
    },
    /// Starts production of one unit and optional strategic-cost alternative.
    StartUnitProduction {
        expected_revision: u64,
        city_id: String,
        unit: UnitKindDto,
        resource_option_index: Option<u32>,
    },
    /// Starts one continuous city project.
    StartCityProject {
        expected_revision: u64,
        city_id: String,
        project: CityProjectTypeDto,
    },
    /// Starts construction of one globally unique wonder.
    StartWonder {
        expected_revision: u64,
        city_id: String,
        wonder: WonderTypeDto,
    },
    /// Selects one city specialization.
    SetCitySpecialization {
        expected_revision: u64,
        city_id: String,
        specialization: CitySpecializationTypeDto,
    },
    /// Buys one bounded production increment for a finite city queue.
    RushProduction {
        expected_revision: u64,
        city_id: String,
    },
    /// Starts one explicitly selected field improvement.
    SelectWorkerImprovement {
        expected_revision: u64,
        unit_id: String,
        improvement: FieldImprovementKindDto,
    },
    /// Confirms an explicit or matching pending field improvement.
    ConfirmWorkerImprovement {
        expected_revision: u64,
        unit_id: String,
        improvement: Option<FieldImprovementKindDto>,
    },
    /// Cancels current worker construction.
    CancelWorkerJob {
        expected_revision: u64,
        unit_id: String,
    },
    /// Assigns a worker to an improved coordinate.
    AssignWorkerToHex {
        expected_revision: u64,
        unit_id: String,
    },
    /// Cancels a worker assignment.
    CancelWorkerAssignment {
        expected_revision: u64,
        unit_id: String,
    },
    /// Starts road construction.
    BuildRoad {
        expected_revision: u64,
        unit_id: String,
    },
    /// Starts or continues worker automation.
    AutomateWorker {
        expected_revision: u64,
        unit_id: String,
    },
    /// Visible unit or city attack.
    AttackHex {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Attacking unit.
        attacker_unit_id: String,
        /// Target coordinate.
        defender: CoordinateDto,
        /// Requested city disposition.
        city_conquest_action: CityConquestActionDto,
    },
    /// Manual movement command.
    MoveUnit {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Opaque canonical unit identifier.
        unit_id: String,
        /// Requested movement target.
        target: CoordinateDto,
    },
    /// Starts or continues deterministic scout auto-exploration.
    AutoExploreUnit {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Scout identity.
        unit_id: String,
    },
    /// Assigns a cyclic merchant route.
    AssignMerchantTradeRoute {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Merchant identity.
        unit_id: String,
        /// Owned destination city.
        destination_city_id: String,
    },
    /// Queues explicit merchant travel.
    MoveMerchantToCity {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Merchant identity.
        unit_id: String,
        /// Owned destination city.
        destination_city_id: String,
    },
    /// Detaches one troop into an engine-selected tile.
    DetachTroop {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Source army unit.
        unit_id: String,
        /// Troop kind to detach.
        troop_kind: TroopKindDto,
    },
    /// Clears all cancellable orders owned by one unit.
    CancelUnitAction {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Opaque canonical unit identifier.
        unit_id: String,
    },
    /// Consumes one unit's movement for the current turn.
    SkipUnitTurn {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Opaque canonical unit identifier.
        unit_id: String,
    },
    /// Fortifies one idle unit.
    FortifyUnit {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Opaque canonical unit identifier.
        unit_id: String,
    },
    /// Completes one sequential participant turn.
    EndTurn {
        /// Expected canonical revision.
        expected_revision: u64,
    },
    /// Marks one simultaneous participant ready.
    SubmitTurn {
        /// Expected canonical revision.
        expected_revision: u64,
    },
}

/// Trusted host commands stored separately from player-authored requests.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ReplaySystemCommandDto {
    /// Finalizes one expired simultaneous turn.
    FinalizeTimedOutTurn {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Ordered participant scope selected by the host.
        player_ids: Vec<String>,
        /// Ordered participants finalized because of timeout.
        skipped_player_ids: Vec<String>,
        /// Explicit host-provided next-turn UTC time when rule-relevant.
        next_turn_started_at: Option<String>,
    },
    /// Removes one participant from the active match lifecycle.
    KickParticipant {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Participant selected by the host.
        player_id: String,
        /// Stable host-owned reason.
        reason: String,
        /// Timeout streak observed by the host.
        timeout_streak: i64,
    },
}
