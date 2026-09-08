use aonw_contracts::client::ClientCommandDto;
use aonw_contracts::{
    CityBuildingTypeDto, CityConquestActionDto, CityProjectTypeDto, CitySpecializationTypeDto,
    CoordinateDto, DiplomaticMessageResponseDto, DiplomaticMessageTopicDto,
    DiplomaticProposalKindDto, FieldImprovementKindDto, ResourceTypeDto, TechnologyIdDto,
    TroopKindDto, UnitKindDto, WonderTypeDto,
};

#[allow(clippy::too_many_lines)]
pub(super) fn command_shapes() -> Vec<(&'static str, ClientCommandDto)> {
    let revision = 7;
    let unit_id = || "unit-1".to_owned();
    let city_id = || "city-1".to_owned();
    let target_player_id = || "player-2".to_owned();
    let target = || CoordinateDto { col: 1, row: 0 };
    vec![
        (
            "cancelResearchSelection",
            ClientCommandDto::CancelResearchSelection {
                expected_revision: revision,
            },
        ),
        (
            "declareWar",
            ClientCommandDto::DeclareWar {
                expected_revision: revision,
                target_player_id: target_player_id(),
            },
        ),
        (
            "sendGoldGift",
            ClientCommandDto::SendGoldGift {
                expected_revision: revision,
                target_player_id: target_player_id(),
                amount: 1,
            },
        ),
        (
            "openResourceTrade",
            ClientCommandDto::OpenResourceTrade {
                expected_revision: revision,
                target_player_id: target_player_id(),
                resource: ResourceTypeDto::Oil,
                gold_per_turn: 1,
                duration_turns: 2,
                agreement_id: Some("agreement-1".to_owned()),
            },
        ),
        (
            "openResourceExchange",
            ClientCommandDto::OpenResourceExchange {
                expected_revision: revision,
                target_player_id: target_player_id(),
                offered_resource: ResourceTypeDto::Oil,
                requested_resource: ResourceTypeDto::Aluminium,
                duration_turns: 2,
                agreement_id: Some("exchange-1".to_owned()),
            },
        ),
        (
            "selectTechnology",
            ClientCommandDto::SelectTechnology {
                expected_revision: revision,
                technology_id: TechnologyIdDto::Mining,
            },
        ),
        (
            "sendDiplomaticProposal",
            ClientCommandDto::SendDiplomaticProposal {
                expected_revision: revision,
                target_player_id: target_player_id(),
                kind: DiplomaticProposalKindDto::Friendship,
                proposal_id: Some("proposal-1".to_owned()),
                gold_payment: 0,
            },
        ),
        (
            "respondDiplomaticProposal",
            ClientCommandDto::RespondDiplomaticProposal {
                expected_revision: revision,
                proposal_id: "proposal-1".to_owned(),
                accepted: true,
            },
        ),
        (
            "sendDiplomaticMessage",
            ClientCommandDto::SendDiplomaticMessage {
                expected_revision: revision,
                target_player_id: target_player_id(),
                topic: DiplomaticMessageTopicDto::AvoidEscalation,
                message_id: Some("message-1".to_owned()),
            },
        ),
        (
            "respondDiplomaticMessage",
            ClientCommandDto::RespondDiplomaticMessage {
                expected_revision: revision,
                message_id: "message-1".to_owned(),
                response: DiplomaticMessageResponseDto::Neutral,
            },
        ),
        (
            "startArtifactExcavation",
            ClientCommandDto::StartArtifactExcavation {
                expected_revision: revision,
                unit_id: unit_id(),
            },
        ),
        (
            "storeArtifactInCity",
            ClientCommandDto::StoreArtifactInCity {
                expected_revision: revision,
                unit_id: unit_id(),
                city_id: Some(city_id()),
            },
        ),
        (
            "tradeArtifact",
            ClientCommandDto::TradeArtifact {
                expected_revision: revision,
                target_player_id: target_player_id(),
                offered_artifact_id: "artifact-1".to_owned(),
                offered_gold: 0,
            },
        ),
        (
            "foundCity",
            ClientCommandDto::FoundCity {
                expected_revision: revision,
                founder_unit_id: unit_id(),
                controlled_hexes: vec![target()],
            },
        ),
        (
            "toggleWorkedHex",
            ClientCommandDto::ToggleWorkedHex {
                expected_revision: revision,
                city_id: city_id(),
                target: target(),
            },
        ),
        (
            "selectCityExpansionHex",
            ClientCommandDto::SelectCityExpansionHex {
                expected_revision: revision,
                city_id: city_id(),
                target: target(),
            },
        ),
        (
            "startBuilding",
            ClientCommandDto::StartBuilding {
                expected_revision: revision,
                city_id: city_id(),
                building: CityBuildingTypeDto::Granary,
            },
        ),
        (
            "startUnitProduction",
            ClientCommandDto::StartUnitProduction {
                expected_revision: revision,
                city_id: city_id(),
                unit: UnitKindDto::Warrior,
                resource_option_index: None,
            },
        ),
        (
            "startCityProject",
            ClientCommandDto::StartCityProject {
                expected_revision: revision,
                city_id: city_id(),
                project: CityProjectTypeDto::Wealth,
            },
        ),
        (
            "startWonder",
            ClientCommandDto::StartWonder {
                expected_revision: revision,
                city_id: city_id(),
                wonder: WonderTypeDto::GreatLibrary,
            },
        ),
        (
            "setCitySpecialization",
            ClientCommandDto::SetCitySpecialization {
                expected_revision: revision,
                city_id: city_id(),
                specialization: CitySpecializationTypeDto::Growth,
            },
        ),
        (
            "rushProduction",
            ClientCommandDto::RushProduction {
                expected_revision: revision,
                city_id: city_id(),
            },
        ),
        (
            "selectWorkerImprovement",
            ClientCommandDto::SelectWorkerImprovement {
                expected_revision: revision,
                unit_id: unit_id(),
                improvement: FieldImprovementKindDto::Farm,
            },
        ),
        (
            "confirmWorkerImprovement",
            ClientCommandDto::ConfirmWorkerImprovement {
                expected_revision: revision,
                unit_id: unit_id(),
                improvement: Some(FieldImprovementKindDto::Farm),
            },
        ),
        (
            "cancelWorkerJob",
            ClientCommandDto::CancelWorkerJob {
                expected_revision: revision,
                unit_id: unit_id(),
            },
        ),
        (
            "assignWorkerToHex",
            ClientCommandDto::AssignWorkerToHex {
                expected_revision: revision,
                unit_id: unit_id(),
            },
        ),
        (
            "cancelWorkerAssignment",
            ClientCommandDto::CancelWorkerAssignment {
                expected_revision: revision,
                unit_id: unit_id(),
            },
        ),
        (
            "buildRoad",
            ClientCommandDto::BuildRoad {
                expected_revision: revision,
                unit_id: unit_id(),
            },
        ),
        (
            "automateWorker",
            ClientCommandDto::AutomateWorker {
                expected_revision: revision,
                unit_id: unit_id(),
            },
        ),
        (
            "attackHex",
            ClientCommandDto::AttackHex {
                expected_revision: revision,
                attacker_unit_id: unit_id(),
                defender: target(),
                city_conquest_action: CityConquestActionDto::Capture,
            },
        ),
        (
            "moveUnit",
            ClientCommandDto::MoveUnit {
                expected_revision: revision,
                unit_id: unit_id(),
                target: target(),
            },
        ),
        (
            "autoExploreUnit",
            ClientCommandDto::AutoExploreUnit {
                expected_revision: revision,
                unit_id: unit_id(),
            },
        ),
        (
            "assignMerchantTradeRoute",
            ClientCommandDto::AssignMerchantTradeRoute {
                expected_revision: revision,
                unit_id: unit_id(),
                destination_city_id: city_id(),
            },
        ),
        (
            "moveMerchantToCity",
            ClientCommandDto::MoveMerchantToCity {
                expected_revision: revision,
                unit_id: unit_id(),
                destination_city_id: city_id(),
            },
        ),
        (
            "detachTroop",
            ClientCommandDto::DetachTroop {
                expected_revision: revision,
                unit_id: unit_id(),
                troop_kind: TroopKindDto::Warrior,
            },
        ),
        (
            "cancelUnitAction",
            ClientCommandDto::CancelUnitAction {
                expected_revision: revision,
                unit_id: unit_id(),
            },
        ),
        (
            "skipUnitTurn",
            ClientCommandDto::SkipUnitTurn {
                expected_revision: revision,
                unit_id: unit_id(),
            },
        ),
        (
            "fortifyUnit",
            ClientCommandDto::FortifyUnit {
                expected_revision: revision,
                unit_id: unit_id(),
            },
        ),
        (
            "endTurn",
            ClientCommandDto::EndTurn {
                expected_revision: revision,
            },
        ),
        (
            "submitTurn",
            ClientCommandDto::SubmitTurn {
                expected_revision: revision,
            },
        ),
    ]
}
