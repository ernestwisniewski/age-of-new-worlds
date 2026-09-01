//! Golden and strict-boundary tests for the shared client protocol.

use std::collections::BTreeMap;

use aonw_contracts::client::{
    AutoExploreOptionDto, CLIENT_API_VERSION, ClientCommandDto, ClientCommandOutcomeDto,
    ClientCommandRejectionCodeDto, ClientCommandResultDto, ClientErrorDto, ClientEventDto,
    ClientEvidenceDto, ClientFeatureDto, ClientOutcomeDto, ClientParticipantControlDto,
    ClientQueryDto, ClientQueryResultDto, ClientReplayVerificationDto, ClientRequestBodyDto,
    ClientRequestDto, ClientResponseBodyDto, ClientResponseDto, ClientSessionStampDto,
    CulturalVictoryProgressDto, DominationVictoryProgressDto, MapObjectiveProgressDto,
    MovementSearchMetricsDto, MovementStepViewDto, PendingActionViewDto, PlayerDiplomacyViewDto,
    PlayerEconomyViewDto, PlayerFogViewDto, PlayerParticipantViewDto, PlayerResearchViewDto,
    PlayerTurnLifecycleViewDto, PlayerUnitViewDto, PlayerVictoryViewDto, PlayerViewPatchDto,
    PlayerViewSnapshotDto, ReachableTileViewDto, ScienceYieldBreakdownDto, ScienceYieldSourceDto,
    ScienceYieldSourceKindDto, StrategicResourceAmountDto, StrategicResourceSourceDto,
};
use aonw_contracts::{
    CoordinateDto, FieldImprovementKindDto, GameOutcomeConditionDto, GameOutcomeDto,
    PlayerCountryDto, PlayerKindDto, PlayerTurnStateDto, ResourceTypeDto, TechnologyIdDto,
    TurnModeDto, UnitKindDto, UnitPostureDto,
};

#[path = "client_contract/artifact.rs"]
mod artifact_contract;
#[path = "client_contract/diplomacy.rs"]
mod diplomacy_contract;
#[path = "client_contract/economy.rs"]
mod economy_contract;
#[path = "client_contract/objective.rs"]
mod objective_contract;
#[path = "client_contract/production.rs"]
mod production_contract;
#[path = "client_contract/research.rs"]
mod research_contract;
#[path = "client_contract/strictness.rs"]
mod strictness_contract;
#[path = "client_contract/worker.rs"]
mod worker_contract;

fn coordinate(col: i32, row: i32) -> CoordinateDto {
    CoordinateDto { col, row }
}

fn stamp() -> ClientSessionStampDto {
    ClientSessionStampDto {
        revision: 8,
        state_digest: "digest-8".to_owned(),
        map_hash: "map-hash".to_owned(),
        ruleset_hash: "ruleset-hash".to_owned(),
    }
}

fn unit() -> PlayerUnitViewDto {
    PlayerUnitViewDto {
        id: "unit-1".to_owned(),
        owner_player_id: "player-1".to_owned(),
        kind: UnitKindDto::Commander,
        name: "Commander".to_owned(),
        coordinate: coordinate(3, 4),
        movement_units: 8,
        posture: UnitPostureDto::Active,
        hit_points: None,
        carried_artifact_id: None,
        owned_details: None,
    }
}

fn economy() -> PlayerEconomyViewDto {
    PlayerEconomyViewDto {
        gold: 125,
        war_weariness: 3,
        stability_net: -2,
        strategic_resource_stockpile: vec![StrategicResourceAmountDto {
            resource: ResourceTypeDto::Oil,
            amount: 4,
        }],
        strategic_resource_output: vec![StrategicResourceAmountDto {
            resource: ResourceTypeDto::Oil,
            amount: 1,
        }],
        strategic_resource_sources: vec![StrategicResourceSourceDto {
            city_id: "city-1".to_owned(),
            coordinate: coordinate(3, 4),
            resource: ResourceTypeDto::Oil,
            improvement: FieldImprovementKindDto::OilWell,
            amount_per_turn: 1,
        }],
    }
}

fn research() -> PlayerResearchViewDto {
    PlayerResearchViewDto {
        active_technology_id: Some(TechnologyIdDto::Agriculture),
        active_progress: Some(9),
        active_effective_cost: Some(42),
        science_overflow: 1,
        science_yield: ScienceYieldBreakdownDto {
            total: 3,
            by_city_id: BTreeMap::from([("city-1".to_owned(), 3)]),
            sources: vec![ScienceYieldSourceDto {
                city_id: "city-1".to_owned(),
                amount: 3,
                kind: ScienceYieldSourceKindDto::CityScience,
            }],
        },
    }
}

fn victory() -> PlayerVictoryViewDto {
    PlayerVictoryViewDto {
        conquest_enabled: true,
        domination_enabled: true,
        domination_required_control_percent: 60.into(),
        domination_required_hold_turns: 5,
        cultural_enabled: true,
        cultural_required_artifacts: 6,
        cultural_required_hold_turns: 5,
        score_fallback_enabled: true,
        turn_limit: Some(20),
        remaining_turns: Some(13),
        score_by_player_id: BTreeMap::from([("player-1".to_owned(), 37)]),
        domination: vec![DominationVictoryProgressDto {
            player_id: "player-1".to_owned(),
            controlled_passable_hexes: 3,
            total_passable_hexes: 10,
            hold_turns: 0,
        }],
        own_cultural: CulturalVictoryProgressDto {
            unique_stored_artifacts: 2,
            hold_turns: 0,
        },
        map_objectives: vec![MapObjectiveProgressDto {
            objective_id: "central-ruins".to_owned(),
            controller_player_id: Some("player-1".to_owned()),
            hold_turns: 2,
        }],
    }
}

fn player_snapshot() -> PlayerViewSnapshotDto {
    PlayerViewSnapshotDto {
        stamp: stamp(),
        turn: 7,
        turn_mode: TurnModeDto::Simultaneous,
        participants: vec![PlayerParticipantViewDto {
            id: "player-1".to_owned(),
            name: "Player One".to_owned(),
            color_value: 0xff00_0000,
            country: PlayerCountryDto::Poland,
            kind: PlayerKindDto::Human,
        }],
        fog: PlayerFogViewDto {
            enabled: true,
            discovered_hexes: vec![coordinate(2, 4), coordinate(3, 4)],
            visible_hexes: vec![coordinate(3, 4)],
        },
        economy: economy(),
        research: research(),
        victory: victory(),
        outcome: GameOutcomeDto {
            condition: GameOutcomeConditionDto::Ongoing,
            winner_player_id: None,
            score_by_player_id: BTreeMap::new(),
        },
        turn_lifecycle: PlayerTurnLifecycleViewDto {
            own_state: Some(PlayerTurnStateDto::Active),
            own_submitted: false,
            required_submission_count: 2,
            submitted_count: 1,
        },
        pending_action: Some(PendingActionViewDto::WorkerActionSelection {
            unit_id: "unit-1".to_owned(),
            improvement: Some(FieldImprovementKindDto::Farm),
        }),
        city_founding_draft: None,
        diplomacy: PlayerDiplomacyViewDto::default(),
        units: vec![unit()],
        cities: Vec::new(),
        artifacts: Vec::new(),
        field_improvements: Vec::new(),
        roads: Vec::new(),
    }
}

fn command_result() -> ClientCommandResultDto {
    ClientCommandResultDto {
        stamp: stamp(),
        outcome: ClientCommandOutcomeDto::Accepted,
        events: vec![ClientEventDto::UnitMoved {
            unit_id: "unit-1".to_owned(),
            from: coordinate(1, 2),
            to: coordinate(3, 4),
        }],
        evidence: Some(ClientEvidenceDto::UnitMovement {
            unit_id: "unit-1".to_owned(),
            from: coordinate(1, 2),
            steps: vec![MovementStepViewDto {
                coordinate: coordinate(3, 4),
                enter_cost_units: 2,
                cumulative_cost_units: 2,
            }],
        }),
        view_patch: PlayerViewPatchDto {
            from_revision: 7,
            to_revision: 8,
            turn: 7,
            turn_mode: TurnModeDto::Simultaneous,
            fog: Some(PlayerFogViewDto {
                enabled: true,
                discovered_hexes: vec![coordinate(2, 4), coordinate(3, 4)],
                visible_hexes: vec![coordinate(3, 4)],
            }),
            economy: Some(economy()),
            research: Some(research()),
            victory: Some(victory()),
            turn_lifecycle: None,
            outcome: None,
            upserted_units: vec![unit()],
            removed_unit_ids: Vec::new(),
            upserted_cities: Vec::new(),
            removed_city_ids: Vec::new(),
            upserted_artifacts: Vec::new(),
            removed_artifact_ids: Vec::new(),
            upserted_field_improvements: Vec::new(),
            removed_field_improvement_coordinates: Vec::new(),
            upserted_roads: Vec::new(),
            removed_road_coordinates: Vec::new(),
            pending_action: None,
            city_founding_draft: None,
            diplomacy: None,
        },
    }
}

#[test]
fn golden_move_request_is_stable_and_strict() {
    let request = ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request: ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::MoveUnit {
                expected_revision: 7,
                unit_id: "unit-1".to_owned(),
                target: coordinate(3, 4),
            },
        },
    };
    let golden = include_str!("../../../fixtures/client_protocol/move_unit_request.json").trim();

    assert_eq!(request.to_json().expect("request JSON"), golden);
    assert_eq!(
        ClientRequestDto::from_json(golden).expect("golden request"),
        request
    );
}

#[test]
fn golden_command_response_is_stable_and_strict() {
    let response = ClientResponseDto {
        api_version: CLIENT_API_VERSION,
        outcome: ClientOutcomeDto::Success {
            response: Box::new(ClientResponseBodyDto::Command {
                result: Box::new(command_result()),
            }),
        },
    };
    let golden =
        include_str!("../../../fixtures/client_protocol/command_result_response.json").trim();

    assert_eq!(response.to_json().expect("response JSON"), golden);
    assert_eq!(
        ClientResponseDto::from_json(golden).expect("golden response"),
        response
    );
}

#[test]
fn command_rejection_codes_match_the_shared_fixture() {
    let fixture: serde_json::Value = serde_json::from_str(include_str!(
        "../../../fixtures/client_protocol/command_rejection_codes.json"
    ))
    .expect("rejection code fixture");
    let fixture_codes = fixture["codes"]
        .as_array()
        .expect("rejection code list")
        .iter()
        .map(|value| value.as_str().expect("rejection code"))
        .collect::<Vec<_>>();
    let contract_codes =
        ClientCommandRejectionCodeDto::ALL.map(ClientCommandRejectionCodeDto::as_str);

    assert_eq!(fixture_codes, contract_codes);
    for code in ClientCommandRejectionCodeDto::ALL {
        assert_eq!(
            serde_json::to_string(&code).expect("rejection code JSON"),
            format!("\"{}\"", code.as_str())
        );
    }
}

#[test]
fn every_request_variant_round_trips() {
    let mut requests = vec![
        ClientRequestBodyDto::Capabilities,
        ClientRequestBodyDto::InspectMap {
            map_document: "map".to_owned(),
        },
        ClientRequestBodyDto::OpenSession {
            map_document: "map".to_owned(),
            scenario_document: "scenario".to_owned(),
            actor_player_id: "player-1".to_owned(),
        },
        ClientRequestBodyDto::CloseSession,
        ClientRequestBodyDto::Snapshot,
        ClientRequestBodyDto::Query {
            query: ClientQueryDto::Reachable {
                expected_revision: 8,
                unit_id: "unit-1".to_owned(),
            },
        },
        ClientRequestBodyDto::Query {
            query: ClientQueryDto::RoutePlan {
                expected_revision: 8,
                unit_id: "unit-1".to_owned(),
                target: coordinate(4, 4),
            },
        },
        ClientRequestBodyDto::Query {
            query: ClientQueryDto::UnitLogisticsOptions {
                expected_revision: 8,
                unit_id: "unit-1".to_owned(),
            },
        },
        ClientRequestBodyDto::Query {
            query: ClientQueryDto::CityYield {
                expected_revision: 8,
                city_id: "city-1".to_owned(),
            },
        },
        ClientRequestBodyDto::Query {
            query: ClientQueryDto::StrategicResourceProjection {
                expected_revision: 8,
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::CancelUnitAction {
                expected_revision: 8,
                unit_id: "unit-1".to_owned(),
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::SkipUnitTurn {
                expected_revision: 8,
                unit_id: "unit-1".to_owned(),
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::FortifyUnit {
                expected_revision: 8,
                unit_id: "unit-1".to_owned(),
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::EndTurn {
                expected_revision: 8,
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::SubmitTurn {
                expected_revision: 8,
            },
        },
    ];
    requests.extend(persistence_requests());
    requests.extend(logistics_requests());
    requests.extend(artifact_contract::requests());
    requests.extend(production_contract::requests());
    requests.extend(research_contract::requests());
    requests.extend(diplomacy_contract::requests());
    requests.extend(worker_contract::requests());

    for request in requests {
        let envelope = ClientRequestDto {
            api_version: CLIENT_API_VERSION,
            request,
        };
        let encoded = envelope.to_json().expect("request JSON");
        assert_eq!(
            ClientRequestDto::from_json(&encoded).expect("request"),
            envelope
        );
    }
}

fn persistence_requests() -> [ClientRequestBodyDto; 6] {
    [
        ClientRequestBodyDto::ExportSave,
        ClientRequestBodyDto::OpenSave {
            map_document: "map".to_owned(),
            save_document: "save".to_owned(),
        },
        ClientRequestBodyDto::ExportReplay,
        ClientRequestBodyDto::VerifyReplay {
            map_document: "map".to_owned(),
            replay_document: "replay".to_owned(),
        },
        ClientRequestBodyDto::OpenReplay {
            map_document: "map".to_owned(),
            replay_document: "replay".to_owned(),
            recipient_player_id: "player-1".to_owned(),
        },
        ClientRequestBodyDto::SeekReplay { position: 3 },
    ]
}

fn logistics_requests() -> [ClientRequestBodyDto; 4] {
    [
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::AutoExploreUnit {
                expected_revision: 8,
                unit_id: "unit-1".to_owned(),
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::AssignMerchantTradeRoute {
                expected_revision: 8,
                unit_id: "merchant-1".to_owned(),
                destination_city_id: "city-2".to_owned(),
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::MoveMerchantToCity {
                expected_revision: 8,
                unit_id: "merchant-1".to_owned(),
                destination_city_id: "city-2".to_owned(),
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::DetachTroop {
                expected_revision: 8,
                unit_id: "unit-1".to_owned(),
                troop_kind: aonw_contracts::TroopKindDto::Archer,
            },
        },
    ]
}

#[test]
fn every_response_variant_round_trips() {
    let responses = core_response_variants()
        .into_iter()
        .chain(economy_contract::responses())
        .chain([research_contract::response()])
        .chain(remaining_response_variants());

    for response in responses {
        let envelope = ClientResponseDto {
            api_version: CLIENT_API_VERSION,
            outcome: ClientOutcomeDto::Success {
                response: Box::new(response),
            },
        };
        let encoded = envelope.to_json().expect("response JSON");
        assert_eq!(
            ClientResponseDto::from_json(&encoded).expect("response"),
            envelope
        );
    }

    let failure = ClientResponseDto {
        api_version: CLIENT_API_VERSION,
        outcome: ClientOutcomeDto::Failure {
            error: ClientErrorDto {
                code: "session_not_open".to_owned(),
                message: "session is not open".to_owned(),
            },
        },
    };
    let encoded = failure.to_json().expect("failure JSON");
    assert_eq!(
        ClientResponseDto::from_json(&encoded).expect("failure"),
        failure
    );
}

fn core_response_variants() -> Vec<ClientResponseBodyDto> {
    let query_stamp = stamp();
    vec![
        ClientResponseBodyDto::Capabilities {
            features: vec![ClientFeatureDto::Snapshot, ClientFeatureDto::MoveUnit],
        },
        ClientResponseBodyDto::SessionOpened { stamp: stamp() },
        ClientResponseBodyDto::SessionClosed,
        ClientResponseBodyDto::Snapshot {
            snapshot: player_snapshot(),
        },
        ClientResponseBodyDto::Query {
            result: ClientQueryResultDto::Reachable {
                stamp: query_stamp.clone(),
                unit_id: "unit-1".to_owned(),
                available_movement_units: 8,
                tiles: vec![ReachableTileViewDto {
                    coordinate: coordinate(4, 4),
                    cost_units: 2,
                    exhausts_movement: false,
                }],
            },
        },
        ClientResponseBodyDto::Query {
            result: ClientQueryResultDto::RoutePlan {
                stamp: query_stamp,
                unit_id: "unit-1".to_owned(),
                target: coordinate(4, 4),
                destination: coordinate(4, 4),
                total_cost_units: 2,
                available_movement_units: 8,
                remaining_movement_units: 6,
                steps: vec![MovementStepViewDto {
                    coordinate: coordinate(4, 4),
                    enter_cost_units: 2,
                    cumulative_cost_units: 2,
                }],
            },
        },
    ]
}

fn remaining_response_variants() -> Vec<ClientResponseBodyDto> {
    let mut rejected_command = command_result();
    rejected_command.outcome = ClientCommandOutcomeDto::Rejected {
        code: ClientCommandRejectionCodeDto::StaleRevision,
    };
    rejected_command.events.clear();
    rejected_command.evidence = None;
    vec![
        logistics_response(),
        production_contract::response(),
        worker_contract::response(),
        ClientResponseBodyDto::Command {
            result: Box::new(command_result()),
        },
        ClientResponseBodyDto::Command {
            result: Box::new(rejected_command),
        },
        ClientResponseBodyDto::SaveExported {
            document: "save".to_owned(),
        },
        ClientResponseBodyDto::SaveOpened {
            stamp: stamp(),
            actor_player_id: "player-1".to_owned(),
            participants: vec![ClientParticipantControlDto {
                id: "player-1".to_owned(),
                name: "Player".to_owned(),
                kind: PlayerKindDto::Human,
            }],
        },
        ClientResponseBodyDto::ReplayExported {
            document: "replay".to_owned(),
        },
        ClientResponseBodyDto::ReplayVerified {
            verification: ClientReplayVerificationDto {
                entry_count: 4,
                final_event_offset: 7,
                final_stamp: stamp(),
            },
        },
        ClientResponseBodyDto::ReplayFrame {
            position: 3,
            entry_count: 4,
            snapshot: player_snapshot(),
        },
    ]
}

fn logistics_response() -> ClientResponseBodyDto {
    ClientResponseBodyDto::Query {
        result: ClientQueryResultDto::UnitLogisticsOptions {
            stamp: stamp(),
            unit_id: "scout-1".to_owned(),
            auto_explore: Some(AutoExploreOptionDto {
                target: coordinate(4, 3),
                total_cost_units: 10,
                search_metrics: MovementSearchMetricsDto {
                    frontier_pops: 4,
                    expanded_tiles: 3,
                    examined_edges: 12,
                    heap_pushes: 7,
                    route_records: 7,
                },
            }),
            merchant_route_destinations: Vec::new(),
            merchant_travel_destinations: Vec::new(),
            detachments: Vec::new(),
        },
    }
}
