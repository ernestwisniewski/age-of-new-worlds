use std::collections::{BTreeSet, hash_map::DefaultHasher};
use std::hash::{Hash, Hasher};

use aonw_domain::{
    ArtifactId, CityBuildingType, CityConquestAction, CityId, CityProjectType,
    CitySpecializationType, DiplomaticMessageResponse, DiplomaticMessageTopic,
    DiplomaticProposalKind, FieldImprovementKind, HexCoord, PlayerId, ResourceType, TechnologyId,
    TroopKind, UnitId, UnitKind, WonderType,
};
use aonw_local_runtime::{
    ArtifactCommandRequest, AttackHexRequest, AutoExploreUnitRequest, DetachTroopRequest,
    DiplomacyRequest, FoundCityRequest, MerchantCityRequest, MoveUnitRequest,
    ProductionCommandRequest, SelectCityExpansionHexRequest, SelectTechnologyRequest,
    ToggleWorkedHexRequest, TurnCommandRequest, UnitActionRequest, WorkerImprovementRequest,
    WorkerUnitRequest,
};

use super::{PlannedCommand, PlannedCommandFamily};

#[test]
fn every_public_player_command_has_one_stable_planned_shape() {
    let commands = commands();
    for command in &commands {
        assert_eq!(command.expected_revision(), 7);
    }
    assert_eq!(commands.len(), 39);
    assert_eq!(
        commands
            .iter()
            .map(PlannedCommand::family)
            .collect::<BTreeSet<_>>(),
        BTreeSet::from([
            PlannedCommandFamily::Research,
            PlannedCommandFamily::City,
            PlannedCommandFamily::Production,
            PlannedCommandFamily::Worker,
            PlannedCommandFamily::Artifact,
            PlannedCommandFamily::Combat,
            PlannedCommandFamily::Logistics,
            PlannedCommandFamily::Diplomacy,
            PlannedCommandFamily::Movement,
            PlannedCommandFamily::Turn,
        ])
    );
}

#[test]
fn every_planned_command_uses_a_normal_public_runtime_method() {
    let mut closed = aonw_local_runtime::LocalRuntime::default();
    for command in commands() {
        assert_eq!(
            command.execute(&mut closed),
            Err(aonw_local_runtime::RuntimeError::SessionNotOpen)
        );
    }
}

#[test]
fn destructive_city_conquest_has_a_distinct_command_hash() {
    let capture = PlannedCommand::AttackHex(AttackHexRequest {
        expected_revision: 7,
        attacker_unit_id: unit("unit-1"),
        defender: HexCoord::new(2, 0),
        city_conquest_action: CityConquestAction::Capture,
    });
    let destroy = PlannedCommand::AttackHex(AttackHexRequest {
        expected_revision: 7,
        attacker_unit_id: unit("unit-1"),
        defender: HexCoord::new(2, 0),
        city_conquest_action: CityConquestAction::Destroy,
    });
    let mut capture_hash = DefaultHasher::new();
    capture.hash(&mut capture_hash);
    let mut destroy_hash = DefaultHasher::new();
    destroy.hash(&mut destroy_hash);
    assert_ne!(capture_hash.finish(), destroy_hash.finish());
}

#[allow(clippy::too_many_lines)]
fn commands() -> Vec<PlannedCommand> {
    let player = player("player-2");
    let unit = unit("unit-1");
    let city = city("city-1");
    let artifact = ArtifactId::new("artifact-1").expect("artifact");
    vec![
        PlannedCommand::Diplomacy(DiplomacyRequest::DeclareWar {
            expected_revision: 7,
            target_player_id: player.clone(),
        }),
        PlannedCommand::Diplomacy(DiplomacyRequest::SendGoldGift {
            expected_revision: 7,
            target_player_id: player.clone(),
            amount: 1,
        }),
        PlannedCommand::Diplomacy(DiplomacyRequest::OpenResourceTrade {
            expected_revision: 7,
            target_player_id: player.clone(),
            resource: ResourceType::Oil,
            gold_per_turn: 1,
            duration_turns: 2,
            agreement_id: Some("trade-1".to_owned()),
        }),
        PlannedCommand::Diplomacy(DiplomacyRequest::OpenResourceExchange {
            expected_revision: 7,
            target_player_id: player.clone(),
            offered_resource: ResourceType::Oil,
            requested_resource: ResourceType::Aluminium,
            duration_turns: 2,
            agreement_id: Some("exchange-1".to_owned()),
        }),
        PlannedCommand::Diplomacy(DiplomacyRequest::Send {
            expected_revision: 7,
            target_player_id: player.clone(),
            kind: DiplomaticProposalKind::Friendship,
            proposal_id: Some("proposal-1".to_owned()),
            gold_payment: 0,
        }),
        PlannedCommand::Diplomacy(DiplomacyRequest::Respond {
            expected_revision: 7,
            proposal_id: "proposal-1".to_owned(),
            accepted: true,
        }),
        PlannedCommand::Diplomacy(DiplomacyRequest::SendMessage {
            expected_revision: 7,
            target_player_id: player.clone(),
            topic: DiplomaticMessageTopic::CommonEnemy,
            message_id: Some("message-1".to_owned()),
        }),
        PlannedCommand::Diplomacy(DiplomacyRequest::RespondMessage {
            expected_revision: 7,
            message_id: "message-1".to_owned(),
            response: DiplomaticMessageResponse::Conciliatory,
        }),
        PlannedCommand::SelectTechnology(SelectTechnologyRequest {
            expected_revision: 7,
            technology: TechnologyId::Agriculture,
        }),
        PlannedCommand::Artifact(ArtifactCommandRequest::StartExcavation {
            expected_revision: 7,
            unit_id: unit.clone(),
        }),
        PlannedCommand::Artifact(ArtifactCommandRequest::StoreInCity {
            expected_revision: 7,
            unit_id: unit.clone(),
            city_id: Some(city.clone()),
        }),
        PlannedCommand::Artifact(ArtifactCommandRequest::Trade {
            expected_revision: 7,
            target_player_id: player,
            offered_artifact_id: artifact,
            offered_gold: 0,
        }),
        PlannedCommand::FoundCity(FoundCityRequest {
            expected_revision: 7,
            founder_unit_id: unit.clone(),
            controlled_hexes: vec![HexCoord::new(1, 0)].into_boxed_slice(),
        }),
        PlannedCommand::ToggleWorkedHex(ToggleWorkedHexRequest {
            expected_revision: 7,
            city_id: city.clone(),
            target: HexCoord::new(1, 0),
        }),
        PlannedCommand::SelectCityExpansionHex(SelectCityExpansionHexRequest {
            expected_revision: 7,
            city_id: city.clone(),
            target: HexCoord::new(2, 0),
        }),
        PlannedCommand::Production(ProductionCommandRequest::StartBuilding {
            expected_revision: 7,
            city_id: city.clone(),
            building: CityBuildingType::Granary,
        }),
        PlannedCommand::Production(ProductionCommandRequest::StartUnitProduction {
            expected_revision: 7,
            city_id: city.clone(),
            unit: UnitKind::Worker,
            resource_option_index: None,
        }),
        PlannedCommand::Production(ProductionCommandRequest::StartCityProject {
            expected_revision: 7,
            city_id: city.clone(),
            project: CityProjectType::Research,
        }),
        PlannedCommand::Production(ProductionCommandRequest::StartWonder {
            expected_revision: 7,
            city_id: city.clone(),
            wonder: WonderType::GreatLibrary,
        }),
        PlannedCommand::Production(ProductionCommandRequest::SetCitySpecialization {
            expected_revision: 7,
            city_id: city.clone(),
            specialization: CitySpecializationType::Science,
        }),
        PlannedCommand::Production(ProductionCommandRequest::RushProduction {
            expected_revision: 7,
            city_id: city.clone(),
        }),
        PlannedCommand::SelectWorkerImprovement(WorkerImprovementRequest {
            expected_revision: 7,
            unit_id: unit.clone(),
            improvement: Some(FieldImprovementKind::Farm),
        }),
        PlannedCommand::ConfirmWorkerImprovement(WorkerImprovementRequest {
            expected_revision: 7,
            unit_id: unit.clone(),
            improvement: None,
        }),
        PlannedCommand::CancelWorkerJob(worker_request(&unit)),
        PlannedCommand::AssignWorkerToHex(worker_request(&unit)),
        PlannedCommand::CancelWorkerAssignment(worker_request(&unit)),
        PlannedCommand::BuildRoad(worker_request(&unit)),
        PlannedCommand::AutomateWorker(worker_request(&unit)),
        PlannedCommand::AttackHex(AttackHexRequest {
            expected_revision: 7,
            attacker_unit_id: unit.clone(),
            defender: HexCoord::new(2, 0),
            city_conquest_action: CityConquestAction::Capture,
        }),
        PlannedCommand::MoveUnit(MoveUnitRequest {
            expected_revision: 7,
            unit_id: unit.clone(),
            target: HexCoord::new(1, 0),
        }),
        PlannedCommand::AutoExploreUnit(AutoExploreUnitRequest {
            expected_revision: 7,
            unit_id: unit.clone(),
        }),
        PlannedCommand::AssignMerchantTradeRoute(merchant_request(&unit, &city)),
        PlannedCommand::MoveMerchantToCity(merchant_request(&unit, &city)),
        PlannedCommand::DetachTroop(DetachTroopRequest {
            expected_revision: 7,
            unit_id: unit.clone(),
            troop_kind: TroopKind::Archer,
        }),
        PlannedCommand::CancelUnitAction(unit_request(&unit)),
        PlannedCommand::SkipUnitTurn(unit_request(&unit)),
        PlannedCommand::FortifyUnit(unit_request(&unit)),
        PlannedCommand::EndTurn(TurnCommandRequest {
            expected_revision: 7,
        }),
        PlannedCommand::SubmitTurn(TurnCommandRequest {
            expected_revision: 7,
        }),
    ]
}

fn player(value: &str) -> PlayerId {
    PlayerId::new(value).expect("player")
}

fn unit(value: &str) -> UnitId {
    UnitId::new(value).expect("unit")
}

fn city(value: &str) -> CityId {
    CityId::new(value).expect("city")
}

fn worker_request(unit_id: &UnitId) -> WorkerUnitRequest {
    WorkerUnitRequest {
        expected_revision: 7,
        unit_id: unit_id.clone(),
    }
}

fn unit_request(unit_id: &UnitId) -> UnitActionRequest {
    UnitActionRequest {
        expected_revision: 7,
        unit_id: unit_id.clone(),
    }
}

fn merchant_request(unit_id: &UnitId, city_id: &CityId) -> MerchantCityRequest {
    MerchantCityRequest {
        expected_revision: 7,
        unit_id: unit_id.clone(),
        destination_city_id: city_id.clone(),
    }
}
