use serde::{Deserialize, Serialize};

use crate::{
    CityBuildingTypeDto, CityConquestActionDto, CityProjectTypeDto, CitySpecializationTypeDto,
    CoordinateDto, FieldImprovementKindDto, MatchIdentityDto, ResourceTypeDto, TechnologyIdDto,
    TroopKindDto, UnitKindDto, WonderTypeDto,
};

/// One current client protocol request.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ClientRequestDto {
    /// Client protocol version shared by independently packaged adapters.
    pub api_version: u16,
    /// Requested lifecycle, query, or command operation.
    pub request: ClientRequestBodyDto,
}

/// Operations supported by the current local client protocol.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ClientRequestBodyDto {
    /// Returns protocol and engine capabilities.
    Capabilities,
    /// Validates authored map content and returns its presentation read model.
    InspectMap {
        /// Strict canonical map document.
        map_document: String,
    },
    /// Opens a session from strict authored content.
    OpenSession {
        /// Strict canonical map document.
        map_document: String,
        /// Strict current scenario document.
        scenario_document: String,
        /// Player receiving the local view.
        actor_player_id: String,
    },
    /// Starts a fully configured playable match from authored content.
    StartMatch {
        /// Strict canonical map document.
        map_document: String,
        /// Strict current scenario document.
        scenario_document: String,
        /// Player receiving the initial local view.
        actor_player_id: String,
        /// Immutable rules, participants, control kinds, and game mode.
        match_identity: MatchIdentityDto,
        /// Explicit global fog mode for the match.
        fog_mode: ClientFogModeDto,
    },
    /// Closes the current session.
    CloseSession,
    /// Changes the recipient in one explicitly local hot-seat match.
    HandoffActor {
        /// Participant receiving subsequent snapshots and commands.
        actor_player_id: String,
    },
    /// Executes one complete, bounded turn for an AI participant.
    AdvanceAiTurn {
        /// AI participant whose turn should be executed.
        actor_player_id: String,
        /// Maximum number of authoritative commands for this turn.
        command_budget: u32,
    },
    /// Returns a complete recipient-safe snapshot.
    Snapshot,
    /// Executes one recipient-safe query.
    Query {
        /// Query payload.
        query: ClientQueryDto,
    },
    /// Dispatches one authoritative command.
    Dispatch {
        /// Command payload.
        command: ClientCommandDto,
    },
    /// Exports the current canonical save document.
    ExportSave,
    /// Opens a current save against its canonical map.
    OpenSave {
        /// Strict canonical map document.
        map_document: String,
        /// Strict current save document.
        save_document: String,
    },
    /// Exports the current deterministic replay segment.
    ExportReplay,
    /// Verifies a replay against its canonical map.
    VerifyReplay {
        /// Strict canonical map document.
        map_document: String,
        /// Strict current replay document.
        replay_document: String,
    },
    /// Validates and opens a replay for recipient-safe visual playback.
    OpenReplay {
        /// Strict canonical map document.
        map_document: String,
        /// Strict current replay document.
        replay_document: String,
        /// Participant receiving every projected playback frame.
        recipient_player_id: String,
    },
    /// Seeks the open replay to an exact authoritative entry boundary.
    SeekReplay {
        /// Number of replay entries applied in the requested frame.
        position: u64,
    },
}

/// Explicit visibility mode selected when a new match starts.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum ClientFogModeDto {
    /// Every participant has unrestricted world visibility.
    Disabled,
    /// Every participant receives complete fail-closed fog state.
    Enabled,
}

/// Authoritative commands available to local clients.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ClientCommandDto {
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
        kind: crate::DiplomaticProposalKindDto,
        /// Optional caller-supplied deterministic identity.
        proposal_id: Option<String>,
        /// Requested truce payment; ignored for friendship proposals.
        gold_payment: i64,
    },
    /// Accepts or rejects one proposal addressed to the authenticated actor.
    RespondDiplomaticProposal {
        expected_revision: u64,
        proposal_id: String,
        accepted: bool,
    },
    /// Sends one private message to a discovered participant.
    SendDiplomaticMessage {
        expected_revision: u64,
        target_player_id: String,
        topic: crate::DiplomaticMessageTopicDto,
        message_id: Option<String>,
    },
    /// Responds to one private message addressed to the authenticated actor.
    RespondDiplomaticMessage {
        expected_revision: u64,
        message_id: String,
        response: crate::DiplomaticMessageResponseDto,
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
        /// Optional owned city; omission selects the city under the unit.
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
        /// Revision observed by the client.
        expected_revision: u64,
        /// Controlled settler or commander carrying settlers.
        founder_unit_id: String,
        /// Complete initial non-center territory selected through engine queries.
        controlled_hexes: Vec<CoordinateDto>,
    },
    /// Toggles one manually worked controlled city hex.
    ToggleWorkedHex {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Controlled city.
        city_id: String,
        /// Non-center controlled coordinate.
        target: CoordinateDto,
    },
    /// Selects the preferred next territory expansion.
    SelectCityExpansionHex {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Controlled city.
        city_id: String,
        /// Current engine-ranked expansion candidate.
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
    /// Assigns a worker to its current improved coordinate.
    AssignWorkerToHex {
        expected_revision: u64,
        unit_id: String,
    },
    /// Cancels a worker assignment.
    CancelWorkerAssignment {
        expected_revision: u64,
        unit_id: String,
    },
    /// Starts road construction at the worker coordinate.
    BuildRoad {
        expected_revision: u64,
        unit_id: String,
    },
    /// Starts or continues deterministic worker automation.
    AutomateWorker {
        expected_revision: u64,
        unit_id: String,
    },
    /// Resolves one visible unit or city attack.
    AttackHex {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Controlled attacking unit.
        attacker_unit_id: String,
        /// Target coordinate.
        defender: CoordinateDto,
        /// Requested disposition when a city is defeated.
        city_conquest_action: CityConquestActionDto,
    },
    /// Moves one controlled unit toward a map coordinate.
    MoveUnit {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Unit receiving the command.
        unit_id: String,
        /// Requested target.
        target: CoordinateDto,
    },
    /// Starts or continues deterministic scout auto-exploration.
    AutoExploreUnit {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Scout receiving the command.
        unit_id: String,
    },
    /// Assigns a cyclic route between two owned cities.
    AssignMerchantTradeRoute {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Merchant receiving the route.
        unit_id: String,
        /// Owned destination city.
        destination_city_id: String,
    },
    /// Queues explicit merchant travel to an owned city.
    MoveMerchantToCity {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Merchant receiving the order.
        unit_id: String,
        /// Owned destination city.
        destination_city_id: String,
    },
    /// Detaches one troop into an engine-selected adjacent tile.
    DetachTroop {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Army unit losing the troop.
        unit_id: String,
        /// Troop kind to detach.
        troop_kind: TroopKindDto,
    },
    /// Clears cancellable work and orders owned by one unit.
    CancelUnitAction {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Unit receiving the command.
        unit_id: String,
    },
    /// Consumes one unit's movement for the current turn.
    SkipUnitTurn {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Unit receiving the command.
        unit_id: String,
    },
    /// Fortifies one available unit.
    FortifyUnit {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Unit receiving the command.
        unit_id: String,
    },
    /// Completes the authenticated participant's sequential turn.
    EndTurn {
        /// Revision observed by the client.
        expected_revision: u64,
    },
    /// Submits the authenticated participant's simultaneous turn.
    SubmitTurn {
        /// Revision observed by the client.
        expected_revision: u64,
    },
}

/// Read-only queries available to local clients.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ClientQueryDto {
    /// Returns every technology with current availability, cost, and progress.
    ResearchOptions { expected_revision: u64 },
    /// Returns legal initial territory choices for one founder.
    CityFoundingOptions {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Controlled settler or commander carrying settlers.
        founder_unit_id: String,
    },
    /// Returns controlled, manual, and effective worked coordinates.
    CityWorkedHexOptions {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Controlled city.
        city_id: String,
    },
    /// Returns deterministically ranked territory-expansion candidates.
    CityExpansionOptions {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Controlled city.
        city_id: String,
    },
    /// Returns a complete display-ready tile yield for one city.
    CityYield {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Controlled city.
        city_id: String,
    },
    /// Returns actor-owned strategic resource output after technology gates.
    StrategicResourceProjection {
        /// Revision observed by the client.
        expected_revision: u64,
    },
    /// Returns complete production choices and blockers for one city.
    ProductionOptions {
        expected_revision: u64,
        city_id: String,
    },
    /// Returns current worker actions and an engine-selected automation target.
    WorkerOptions {
        expected_revision: u64,
        unit_id: String,
    },
    /// Returns effective combat stats and damage bounds without RNG evidence.
    CombatPreview {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Controlled attacking unit.
        attacker_unit_id: String,
        /// Visible target coordinate.
        defender: CoordinateDto,
    },
    /// Returns every current-turn reachable coordinate.
    Reachable {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Unit inspected by the query.
        unit_id: String,
    },
    /// Plans a deterministic route toward one coordinate.
    RoutePlan {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Unit inspected by the query.
        unit_id: String,
        /// Requested target.
        target: CoordinateDto,
    },
    /// Returns engine-owned logistics options for one controlled unit.
    UnitLogisticsOptions {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Unit inspected by the query.
        unit_id: String,
    },
}
