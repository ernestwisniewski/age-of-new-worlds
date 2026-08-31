use serde::{Deserialize, Serialize};

use crate::{MovementStepDto, QueuedMovePathDto, UnitKindDto, UnitPostureDto};

mod artifact;
mod city;
mod combat;
mod diplomacy;
mod economy;
mod infrastructure;
mod interaction;
mod match_lifecycle;
mod objective;
mod outcome;
mod research;

pub use artifact::{WorldArtifactDto, WorldArtifactLocationDto, WorldArtifactTypeDto};
pub use city::{
    CityBuildingTypeDto, CityDto, CityProductionQueueDto, CityProductionTargetDto,
    CityProjectTypeDto, CitySpecializationTypeDto, WonderTypeDto,
};
pub use combat::{CityConquestActionDto, IntendedAttackDto};
pub use diplomacy::{
    DiplomacyStateDto, DiplomaticMessageCategoryDto, DiplomaticMessageDto,
    DiplomaticMessageResponseDto, DiplomaticMessageTopicDto, DiplomaticProposalDto,
    DiplomaticProposalKindDto, DiplomaticRelationChangeReasonDto, DiplomaticRelationDto,
    DiplomaticRelationStatusDto, DiplomaticScoreChangeReasonDto, DiplomaticScoreEntryDto,
    ResourceTradeAgreementDto,
};
pub use economy::{
    EconomyStateDto, InitialResourceDistributionDto, InitialResourcePlacementDto, ResourceTypeDto,
    StrategicResourceStockpileDto,
};
pub use infrastructure::{
    FieldImprovementDto, TransportConditionDto, TransportSegmentDto, TransportSegmentKindDto,
};
pub use interaction::{CityFoundingDraftDto, InteractionStateDto, PendingInteractionDto};
pub use match_lifecycle::{
    AiDifficultyDto, AiPersonaDto, AiPlayerDto, AiStrategyIdDto, GameLengthConfigDto,
    GameLengthKindDto, GameModeDto, MatchIdentityDto, MatchRulesDto, PaceProfileDto,
    ParticipantDto, PlayerCountryDto, PlayerKindDto, PlayerTurnStateDto, RuleValueDto,
    TurnLifecycleDto, TurnModeDto, VictoryRulesDto,
};
pub use objective::{
    CulturalVictoryHoldTurnsDto, DominationHoldTurnsDto, MapObjectiveHoldStateDto,
};
pub use outcome::{GameOutcomeConditionDto, GameOutcomeDto};
pub use research::{PlayerResearchStateDto, ResearchStateDto, TechnologyIdDto, WonderRegistryDto};

#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct GameStateDto {
    pub revision: u64,
    pub turn: u32,
    pub match_identity: MatchIdentityDto,
    pub turn_lifecycle: TurnLifecycleDto,
    pub economy: EconomyStateDto,
    pub research: ResearchStateDto,
    pub wonder_registry: WonderRegistryDto,
    pub intended_attacks: Vec<IntendedAttackDto>,
    pub cols: u16,
    pub rows: u16,
    pub occupancy_policy: UnitOccupancyPolicyDto,
    pub units: Vec<UnitDto>,
    pub cities: Vec<CityDto>,
    pub artifacts: Vec<WorldArtifactDto>,
    pub field_improvements: Vec<FieldImprovementDto>,
    pub interaction: InteractionStateDto,
    pub fog_of_war: Vec<PlayerFogDto>,
    pub diplomacy: DiplomacyStateDto,
    pub resource_trade_agreements: Vec<ResourceTradeAgreementDto>,
    pub domination_hold_turns_by_player_id: DominationHoldTurnsDto,
    pub cultural_victory_hold_turns_by_player_id: CulturalVictoryHoldTurnsDto,
    pub map_objective_hold_states: Vec<MapObjectiveHoldStateDto>,
    pub outcome: GameOutcomeDto,
    pub transport_network: Vec<TransportSegmentDto>,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum UnitOccupancyPolicyDto {
    Exclusive,
    FriendlyStacking,
}

#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct UnitDto {
    pub id: String,
    pub owner_player_id: String,
    pub kind: UnitKindDto,
    pub name: String,
    pub col: i32,
    pub row: i32,
    pub movement_units: u32,
    pub army: Vec<ArmyTroopDto>,
    pub queued_path: Option<QueuedMovePathDto>,
    pub merchant_trade_route: Option<MerchantTradeRouteDto>,
    pub activity: UnitActivityDto,
    pub worker_build_charges: u32,
    pub hit_points: Option<u32>,
    pub experience_points: u32,
    pub posture: UnitPostureDto,
    pub carried_artifact_id: Option<String>,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ArmyTroopDto {
    pub kind: TroopKindDto,
    pub count: u32,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum TroopKindDto {
    Warrior,
    Archer,
    Settler,
}

#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct MerchantTradeRouteDto {
    pub origin_city_id: String,
    pub destination_city_id: String,
    pub steps: Vec<MovementStepDto>,
    pub transport_network_fingerprint: String,
}

#[allow(missing_docs)]
#[derive(Clone, Debug, Default, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct UnitActivityDto {
    pub worker_job: Option<WorkerJobDto>,
    pub city_founding_job: Option<CityFoundingJobDto>,
    pub worker_assignment: Option<CoordinateDto>,
    pub excavating_artifact_id: Option<String>,
}

#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "kind",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum WorkerJobDto {
    FieldImprovement {
        target: CoordinateDto,
        improvement: FieldImprovementKindDto,
        remaining_turns: u32,
        total_turns: u32,
    },
    RoadConstruction {
        target: CoordinateDto,
        remaining_turns: u32,
        total_turns: u32,
    },
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum FieldImprovementKindDto {
    Farm,
    RiverFarm,
    Mine,
    LumberMill,
    Pasture,
    Camp,
    Quarry,
    FishingBoats,
    Orchard,
    Plantation,
    Vineyard,
    TradingPost,
    ProspectorCamp,
    HorseRanch,
    PearlDivers,
    CoalShaft,
    OilWell,
    BauxiteMine,
    UraniumMine,
}

#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct CityFoundingJobDto {
    pub center: CoordinateDto,
    pub controlled_hexes: Vec<CoordinateDto>,
    pub remaining_turns: u32,
    pub total_turns: u32,
}

#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerFogDto {
    pub player_id: String,
    pub discovered_hexes: Vec<CoordinateDto>,
    pub visible_hexes: Vec<CoordinateDto>,
}

#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerPairDto {
    pub first_player_id: String,
    pub second_player_id: String,
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct CoordinateDto {
    pub col: i32,
    pub row: i32,
}

/// Strict canonical state codec error.
#[derive(Debug)]
pub enum GameStateCodecError {
    /// Input exceeds the byte boundary.
    TooLarge {
        /// Actual input bytes.
        actual: usize,
        /// Maximum accepted bytes.
        maximum: usize,
    },
    /// JSON violates the strict DTO contract.
    Json(serde_json::Error),
}

impl core::fmt::Display for GameStateCodecError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::TooLarge { actual, maximum } => write!(
                formatter,
                "game state is {actual} bytes; maximum is {maximum}"
            ),
            Self::Json(source) => source.fmt(formatter),
        }
    }
}

impl std::error::Error for GameStateCodecError {}

impl GameStateDto {
    /// Parses strict JSON after enforcing the byte limit.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized or structurally invalid input.
    pub fn from_json(input: &str, maximum_bytes: usize) -> Result<Self, GameStateCodecError> {
        if input.len() > maximum_bytes {
            return Err(GameStateCodecError::TooLarge {
                actual: input.len(),
                maximum: maximum_bytes,
            });
        }
        serde_json::from_str(input).map_err(GameStateCodecError::Json)
    }

    /// Serializes compact contract JSON.
    ///
    /// # Errors
    ///
    /// Returns an error if serialization fails.
    pub fn to_json(&self) -> Result<String, serde_json::Error> {
        serde_json::to_string(self)
    }
}

#[cfg(test)]
mod tests {
    use super::GameStateDto;

    #[test]
    fn strict_codec_rejects_missing_unknown_and_duplicate_fields() {
        let unknown = r#"{"revision":0,"turn":0,"matchIdentity":{"matchRules":{"gameLength":{"kind":"unlimited","targetMinutes":null,"turnLimit":null,"paceProfile":"unlimited","scoreFallbackEnabled":false},"victory":{"conquestEnabled":true,"dominationEnabled":true,"dominationControlPercent":60,"dominationHoldTurns":5,"scoreFallbackEnabled":false,"turnLimit":null,"hardTimeLimitMinutes":null,"culturalEnabled":true,"culturalRequiredArtifacts":6,"culturalHoldTurns":5},"balance":{}},"participants":[],"gameMode":"hotSeat"},"turnLifecycle":{"turnStatesByPlayerId":{},"requiredSubmissionPlayerIds":[],"submittedPlayerIds":[],"timeoutStreaksByPlayerId":{},"afkPlayerIds":[],"kickedPlayerIds":[],"turnStartedAt":null},"economy":{"playerGold":{},"playerWarWeariness":{},"playerStabilityNet":{},"strategicResources":{},"initialResourceDistribution":{"seed":0,"placements":[]}},"research":{"players":{}},"wonderRegistry":{},"intendedAttacks":[],"cols":1,"rows":1,"occupancyPolicy":"exclusive","units":[],"cities":[],"artifacts":[],"fieldImprovements":[],"interaction":{"cityFoundingDraft":null,"pending":null},"fogOfWar":[],"diplomacy":{"contacts":[],"relations":[],"pendingProposals":[],"messages":[],"scoreHistory":[]},"resourceTradeAgreements":[],"dominationHoldTurnsByPlayerId":{},"culturalVictoryHoldTurnsByPlayerId":{},"mapObjectiveHoldStates":[],"outcome":{"condition":"ongoing","winnerPlayerId":null,"scoreByPlayerId":{}},"transportNetwork":[],"extra":true}"#;
        assert!(GameStateDto::from_json(unknown, 4096).is_err());
        let duplicate = unknown.replace(",\"extra\":true", "").replacen(
            "\"revision\":0",
            "\"revision\":0,\"revision\":0",
            1,
        );
        assert!(GameStateDto::from_json(&duplicate, 4096).is_err());
        let missing = unknown
            .replace(",\"extra\":true", "")
            .replace("\"submittedPlayerIds\":[],", "");
        assert!(GameStateDto::from_json(&missing, 4096).is_err());
    }
}
