use aonw_content::{
    GridLayout, MapDefinition, MapDocument, MapObjectiveType, ResourceType, RulesetDefinition,
    TerrainType, TileDefinition,
};
use aonw_contract_mapping::{
    encode_client_evidence, encode_command_rejection, encode_pending_action,
};
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientCommandDto, ClientOutcomeDto, ClientQueryDto, ClientRequestBodyDto,
    ClientRequestDto, ClientResponseBodyDto,
};
use aonw_contracts::{
    CoordinateDto, DiplomaticMessageResponseDto, DiplomaticMessageTopicDto,
    DiplomaticProposalKindDto, TroopKindDto,
};
use aonw_domain::{
    CityId, FieldImprovementKind, HexCoord, MovementStep, MovementUnits, TroopKind, UnitId,
};
use aonw_engine::{
    CombatExecution, CombatModifier, CombatModifierKind, CombatOutcome, CombatPreview, CombatRoll,
    CombatStatTarget, CombatTarget, CommandRejectionCode, EffectiveCombatStats, ExecutionEvidence,
    LogisticsExecution,
};

use crate::{ClientProtocol, LocalRuntime, PendingActionView};

use super::*;

mod session;

#[test]
fn protocol_exercises_every_request_family() {
    let map = authored_map();
    let ruleset = RulesetDefinition::standard().clone();
    let map_document = MapDocument::try_new(map.clone(), 1.0)
        .expect("map document")
        .to_versioned_json()
        .expect("map JSON");
    let scenario_document = scenario_json(&map, &ruleset);
    let mut runtime = LocalRuntime::default();

    assert!(
        ClientProtocol::dispatch_json(&mut runtime, "not-json").contains("invalid_client_request")
    );
    let future = request(ClientRequestBodyDto::Capabilities);
    let mut future = serde_json::to_value(future).expect("request value");
    future["apiVersion"] = serde_json::json!(CLIENT_API_VERSION + 1);
    assert!(
        ClientProtocol::dispatch_json(&mut runtime, &future.to_string())
            .contains("unsupported_client_api_version")
    );

    success(&mut runtime, ClientRequestBodyDto::Capabilities);
    success(
        &mut runtime,
        ClientRequestBodyDto::InspectMap {
            map_document: map_document.clone(),
        },
    );
    success(
        &mut runtime,
        ClientRequestBodyDto::OpenSession {
            map_document: map_document.clone(),
            scenario_document,
            actor_player_id: "player-1".to_owned(),
        },
    );
    success(&mut runtime, ClientRequestBodyDto::Snapshot);

    dispatch_queries(&mut runtime);
    dispatch_commands(&mut runtime);
    round_trip_persistence(&mut runtime, map_document);
    success(&mut runtime, ClientRequestBodyDto::CloseSession);
}

fn dispatch_queries(runtime: &mut LocalRuntime) {
    for query in [
        ClientQueryDto::Reachable {
            expected_revision: 0,
            unit_id: "unit-1".to_owned(),
        },
        ClientQueryDto::RoutePlan {
            expected_revision: 0,
            unit_id: "unit-1".to_owned(),
            target: CoordinateDto { col: 1, row: 0 },
        },
        ClientQueryDto::UnitLogisticsOptions {
            expected_revision: 0,
            unit_id: "unit-1".to_owned(),
        },
    ] {
        success(runtime, ClientRequestBodyDto::Query { query });
    }
}

fn dispatch_commands(runtime: &mut LocalRuntime) {
    let commands = [
        ClientCommandDto::MoveUnit {
            expected_revision: 0,
            unit_id: "unit-1".to_owned(),
            target: CoordinateDto { col: 1, row: 0 },
        },
        ClientCommandDto::AutoExploreUnit {
            expected_revision: 1,
            unit_id: "unit-1".to_owned(),
        },
        ClientCommandDto::AssignMerchantTradeRoute {
            expected_revision: 1,
            unit_id: "unit-1".to_owned(),
            destination_city_id: "city-1".to_owned(),
        },
        ClientCommandDto::MoveMerchantToCity {
            expected_revision: 1,
            unit_id: "unit-1".to_owned(),
            destination_city_id: "city-1".to_owned(),
        },
        ClientCommandDto::DetachTroop {
            expected_revision: 1,
            unit_id: "unit-1".to_owned(),
            troop_kind: TroopKindDto::Archer,
        },
        ClientCommandDto::CancelUnitAction {
            expected_revision: 1,
            unit_id: "unit-1".to_owned(),
        },
        ClientCommandDto::SkipUnitTurn {
            expected_revision: 2,
            unit_id: "unit-1".to_owned(),
        },
        ClientCommandDto::FortifyUnit {
            expected_revision: 3,
            unit_id: "unit-1".to_owned(),
        },
        ClientCommandDto::EndTurn {
            expected_revision: 4,
        },
        ClientCommandDto::SubmitTurn {
            expected_revision: 5,
        },
        ClientCommandDto::SendDiplomaticProposal {
            expected_revision: 5,
            target_player_id: "player-2".to_owned(),
            kind: DiplomaticProposalKindDto::Friendship,
            proposal_id: None,
            gold_payment: 0,
        },
        ClientCommandDto::RespondDiplomaticProposal {
            expected_revision: 5,
            proposal_id: "proposal-1".to_owned(),
            accepted: false,
        },
        ClientCommandDto::SendDiplomaticMessage {
            expected_revision: 5,
            target_player_id: "player-2".to_owned(),
            topic: DiplomaticMessageTopicDto::WithdrawScouts,
            message_id: None,
        },
        ClientCommandDto::RespondDiplomaticMessage {
            expected_revision: 5,
            message_id: "message-1".to_owned(),
            response: DiplomaticMessageResponseDto::Neutral,
        },
    ];
    for command in commands {
        success(runtime, ClientRequestBodyDto::Dispatch { command });
    }
}

fn round_trip_persistence(runtime: &mut LocalRuntime, map_document: String) {
    let save = success(runtime, ClientRequestBodyDto::ExportSave);
    let ClientResponseBodyDto::SaveExported { document: save } = save else {
        panic!("save response")
    };
    let replay = success(runtime, ClientRequestBodyDto::ExportReplay);
    let ClientResponseBodyDto::ReplayExported { document: replay } = replay else {
        panic!("replay response")
    };
    success(
        runtime,
        ClientRequestBodyDto::OpenSave {
            map_document: map_document.clone(),
            save_document: save,
        },
    );
    let verified = success(
        runtime,
        ClientRequestBodyDto::VerifyReplay {
            map_document: map_document.clone(),
            replay_document: replay.clone(),
        },
    );
    let ClientResponseBodyDto::ReplayVerified { verification } = verified else {
        panic!("replay verification response")
    };
    let opened = success(
        runtime,
        ClientRequestBodyDto::OpenReplay {
            map_document,
            replay_document: replay,
            recipient_player_id: "player-1".to_owned(),
        },
    );
    let ClientResponseBodyDto::ReplayFrame {
        position,
        entry_count,
        ..
    } = opened
    else {
        panic!("initial replay frame")
    };
    assert_eq!(position, 0);
    assert_eq!(entry_count, verification.entry_count);
    assert!(entry_count > 0);
    let sequential = success(runtime, ClientRequestBodyDto::SeekReplay { position: 1 });
    let ClientResponseBodyDto::ReplayFrame { position, .. } = sequential else {
        panic!("sequential replay frame")
    };
    assert_eq!(position, 1);
    success(runtime, ClientRequestBodyDto::SeekReplay { position: 0 });
    let final_frame = success(
        runtime,
        ClientRequestBodyDto::SeekReplay {
            position: entry_count,
        },
    );
    let ClientResponseBodyDto::ReplayFrame {
        position, snapshot, ..
    } = final_frame
    else {
        panic!("final replay frame")
    };
    assert_eq!(position, entry_count);
    assert_eq!(snapshot.stamp, verification.final_stamp);
}

#[test]
fn encoder_maps_every_closed_enum_and_logistics_evidence_variant() {
    for value in TerrainType::ALL {
        let _ = terrain(value);
    }
    for value in ResourceType::ALL {
        let _ = resource(value);
    }
    for value in [
        MapObjectiveType::Ruins,
        MapObjectiveType::StrategicPass,
        MapObjectiveType::HolySite,
        MapObjectiveType::LegendaryResource,
    ] {
        let _ = objective_type(value);
    }
    for value in CommandRejectionCode::ALL {
        let _ = encode_command_rejection(value);
    }
    for value in pending_actions() {
        let _ = encode_pending_action(&value);
    }

    let unit_id = UnitId::new("unit-1").expect("unit id");
    let detached_id = UnitId::new("unit-2").expect("unit id");
    let origin_city_id = CityId::new("city-1").expect("city id");
    let destination_city_id = CityId::new("city-2").expect("city id");
    let step = MovementStep::new(
        HexCoord::new(1, 0),
        MovementUnits::new(2),
        MovementUnits::new(2),
    );
    let executions = [
        LogisticsExecution::AutoExplore {
            unit_id: unit_id.clone(),
            target: HexCoord::new(1, 0),
            movement: None,
        },
        LogisticsExecution::MerchantRouteAssigned {
            unit_id: unit_id.clone(),
            origin_city_id,
            destination_city_id: destination_city_id.clone(),
            steps: vec![step].into_boxed_slice(),
            transport_network_fingerprint: "network".into(),
        },
        LogisticsExecution::MerchantTravelQueued {
            unit_id: unit_id.clone(),
            destination_city_id,
            steps: vec![step].into_boxed_slice(),
        },
        LogisticsExecution::TroopDetached {
            source_unit_id: unit_id,
            detached_unit_id: detached_id,
            troop_kind: TroopKind::Archer,
            destination: HexCoord::new(0, 1),
        },
    ];
    for execution in executions {
        let _ = encode_client_evidence(&ExecutionEvidence::Logistics(execution));
    }
}

#[test]
fn encoder_maps_complete_combat_evidence_surface() {
    let mut execution = combat_execution(CombatTarget::Unit(
        UnitId::new("defender").expect("unit id"),
    ));
    let _ = encode_client_evidence(&ExecutionEvidence::Combat(execution.clone()));

    execution.preview.target = CombatTarget::City(CityId::new("defended-city").expect("city id"));
    let _ = encode_client_evidence(&ExecutionEvidence::Combat(execution));
}

#[test]
fn encoder_maps_logistics_metrics_and_destination_values() {
    let metrics = movement_metrics(aonw_engine::MovementSearchMetrics::default());
    assert_eq!(metrics.frontier_pops, 0);
    let destination = merchant_destination(&crate::MerchantDestinationView {
        city_id: CityId::new("destination").expect("city id"),
        total_cost: MovementUnits::new(7),
    });
    assert_eq!(destination.city_id, "destination");
    assert_eq!(destination.total_cost_units, 7);
}

fn combat_execution(target: CombatTarget) -> CombatExecution {
    let modifiers = [
        (CombatModifierKind::Terrain, CombatStatTarget::Attack),
        (CombatModifierKind::Fortification, CombatStatTarget::Defense),
        (CombatModifierKind::Technology, CombatStatTarget::HitPoints),
        (CombatModifierKind::Counter, CombatStatTarget::Attack),
        (
            CombatModifierKind::TroopComposition,
            CombatStatTarget::Defense,
        ),
        (CombatModifierKind::Veterancy, CombatStatTarget::HitPoints),
    ]
    .into_iter()
    .enumerate()
    .map(|(index, (kind, target))| CombatModifier {
        kind,
        label: format!("modifier-{index}").into(),
        target,
        delta: i32::try_from(index + 1).expect("modifier delta"),
    })
    .collect::<Vec<_>>()
    .into_boxed_slice();
    let attacker = EffectiveCombatStats {
        attack: 7,
        defense: 6,
        hit_points: 9,
        range: 2,
        mobility: 3,
        modifiers,
    };
    CombatExecution {
        seed: 17,
        rolls: vec![CombatRoll { value: -1 }, CombatRoll { value: 2 }].into_boxed_slice(),
        preview: CombatPreview {
            attacker_unit_id: UnitId::new("attacker").expect("unit id"),
            target,
            distance: 2,
            attacker: attacker.clone(),
            defender: attacker,
            outgoing_damage: (2, 6),
            retaliation_damage: Some((1, 3)),
        },
        outcome: CombatOutcome {
            attacker_hit_points: 4,
            defender_hit_points: 1,
            attacker_killed: false,
            defender_killed: false,
            defender_retreat: Some(HexCoord::new(2, 1)),
            outgoing_damage: 5,
            retaliation_damage: 2,
        },
    }
}

fn request(request: ClientRequestBodyDto) -> ClientRequestDto {
    ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request,
    }
}

fn success(runtime: &mut LocalRuntime, body: ClientRequestBodyDto) -> ClientResponseBodyDto {
    let response = ClientProtocol::dispatch(runtime, request(body));
    let ClientOutcomeDto::Success { response } = response.outcome else {
        panic!("protocol response failed: {:?}", response.outcome)
    };
    *response
}

fn authored_map() -> MapDefinition {
    MapDefinition::try_new(
        "client-protocol-map",
        GridLayout::OddQFlatTop,
        5,
        5,
        (0..5)
            .flat_map(|row| {
                (0..5).map(move |col| {
                    TileDefinition::try_new_for_simulation(
                        HexCoord::new(col, row),
                        vec![TerrainType::Grassland],
                        Vec::new(),
                        0,
                    )
                    .expect("tile")
                })
            })
            .collect(),
        Vec::new(),
    )
    .expect("map")
}

fn scenario_json(map: &MapDefinition, ruleset: &RulesetDefinition) -> String {
    serde_json::json!({
        "schemaVersion": 1,
        "scenarioId": "client-protocol-scenario",
        "mapId": map.map_id(),
        "rulesetId": ruleset.ruleset_id(),
        "initialUnits": [{
            "id": "unit-1",
            "ownerPlayerId": "player-1",
            "kind": "commander",
            "name": "Commander",
            "col": 0,
            "row": 0
        }]
    })
    .to_string()
}

fn pending_actions() -> [PendingActionView; 9] {
    let unit = UnitId::new("unit-1").expect("unit id");
    let city = CityId::new("city-1").expect("city id");
    [
        PendingActionView::ResearchSelection,
        PendingActionView::CityWorkedHexSelection {
            city_id: city.clone(),
        },
        PendingActionView::CityExpansionSelection { city_id: city },
        PendingActionView::WorkerActionSelection {
            unit_id: unit.clone(),
            improvement: Some(FieldImprovementKind::Farm),
        },
        PendingActionView::MerchantTradeRouteSelection {
            unit_id: unit.clone(),
        },
        PendingActionView::MerchantMoveToCitySelection {
            unit_id: unit.clone(),
        },
        PendingActionView::UnitTurnSkip {
            unit_id: unit.clone(),
            restore_movement_units: 10,
        },
        PendingActionView::AttackTargeting {
            unit_id: unit.clone(),
            defender: Some(HexCoord::new(1, 0)),
        },
        PendingActionView::CommanderMergeSelection { unit_id: unit },
    ]
}
