use std::collections::BTreeMap;

use aonw_contracts::client::{
    CitySpecializationOptionDto, ClientCommandDto, ClientCommandRejectionCodeDto, ClientEventDto,
    ClientQueryDto, ClientQueryResultDto, ClientRequestBodyDto, ClientResponseBodyDto,
    ProductionForecastDto, ProductionOptionDto, ProductionRushQuoteDto, UnitProductionOptionDto,
};
use aonw_contracts::{
    CityBuildingTypeDto, CityProductionTargetDto, CityProjectTypeDto, CitySpecializationTypeDto,
    ResourceTypeDto, StrategicResourceStockpileDto, UnitKindDto, WonderTypeDto,
};

use super::stamp;

#[test]
fn production_metadata_matches_the_shared_dart_fixture() {
    let document: serde_json::Value = serde_json::from_str(include_str!(
        "../../../../fixtures/client_protocol/production_options_response.json"
    ))
    .expect("fixture");
    assert_eq!(
        document["apiVersion"],
        aonw_contracts::client::CLIENT_API_VERSION
    );
    assert_eq!(
        serde_json::to_value(response()).expect("production response"),
        document["outcome"]["response"]
    );
}

#[test]
fn production_forecast_and_rush_fields_are_required_and_strict() {
    let original = serde_json::to_value(response()).expect("production JSON");
    for field in [
        "investedProduction",
        "productionPerTurn",
        "estimatedTurns",
        "projectOutput",
        "spawnBlocked",
    ] {
        let mut missing = original.clone();
        missing["result"]["buildings"][0]["forecast"]
            .as_object_mut()
            .expect("forecast")
            .remove(field);
        assert!(
            serde_json::from_value::<ClientResponseBodyDto>(missing).is_err(),
            "missing {field}"
        );
    }
    for field in ["production", "goldCost", "rejection"] {
        let mut missing = original.clone();
        missing["result"]["rushQuote"]
            .as_object_mut()
            .expect("quote")
            .remove(field);
        assert!(
            serde_json::from_value::<ClientResponseBodyDto>(missing).is_err(),
            "missing {field}"
        );
    }
    for pointer in ["/result/buildings/0/forecast", "/result/rushQuote"] {
        let mut unknown = original.clone();
        unknown
            .pointer_mut(pointer)
            .expect("metadata")
            .as_object_mut()
            .expect("object")
            .insert("hiddenPlayerGold".to_owned(), serde_json::json!(100));
        assert!(serde_json::from_value::<ClientResponseBodyDto>(unknown).is_err());
    }
    let mut missing = original;
    missing["result"]
        .as_object_mut()
        .expect("result")
        .remove("rushQuote");
    assert!(serde_json::from_value::<ClientResponseBodyDto>(missing).is_err());
}

pub(super) fn requests() -> Vec<ClientRequestBodyDto> {
    vec![
        ClientRequestBodyDto::Query {
            query: ClientQueryDto::ProductionOptions {
                expected_revision: 8,
                city_id: "city-1".to_owned(),
            },
        },
        dispatch(ClientCommandDto::StartBuilding {
            expected_revision: 8,
            city_id: "city-1".to_owned(),
            building: CityBuildingTypeDto::Workshop,
        }),
        dispatch(ClientCommandDto::StartUnitProduction {
            expected_revision: 8,
            city_id: "city-1".to_owned(),
            unit: UnitKindDto::Tank,
            resource_option_index: Some(0),
        }),
        dispatch(ClientCommandDto::StartCityProject {
            expected_revision: 8,
            city_id: "city-1".to_owned(),
            project: CityProjectTypeDto::Research,
        }),
        dispatch(ClientCommandDto::StartWonder {
            expected_revision: 8,
            city_id: "city-1".to_owned(),
            wonder: WonderTypeDto::GreatLibrary,
        }),
        dispatch(ClientCommandDto::SetCitySpecialization {
            expected_revision: 8,
            city_id: "city-1".to_owned(),
            specialization: CitySpecializationTypeDto::Industry,
        }),
        dispatch(ClientCommandDto::RushProduction {
            expected_revision: 8,
            city_id: "city-1".to_owned(),
        }),
    ]
}

#[test]
fn production_completion_events_have_strict_wire_shapes() {
    let events = vec![
        ClientEventDto::CityBuiltBuilding {
            city_id: "city-1".to_owned(),
            building_type: CityBuildingTypeDto::Workshop,
        },
        ClientEventDto::CityProducedUnit {
            city_id: "city-1".to_owned(),
            unit_type: UnitKindDto::Warrior,
            produced_unit_id: "city-1_warrior_1".to_owned(),
        },
        ClientEventDto::CityBuiltWonder {
            city_id: "city-1".to_owned(),
            owner_player_id: "player-1".to_owned(),
            wonder_type: WonderTypeDto::GreatLibrary,
        },
        ClientEventDto::WonderProductionRefunded {
            city_id: "city-2".to_owned(),
            owner_player_id: "player-2".to_owned(),
            wonder_type: WonderTypeDto::GreatLibrary,
            refunded_production: 17,
        },
        ClientEventDto::TechnologyResearched {
            player_id: "player-1".to_owned(),
            technology_id: aonw_contracts::TechnologyIdDto::Writing,
        },
        ClientEventDto::ResearchPointsGained {
            player_id: "player-1".to_owned(),
            points: 7,
        },
    ];

    let encoded = serde_json::to_string(&events).expect("event JSON");
    assert_eq!(
        serde_json::from_str::<Vec<ClientEventDto>>(&encoded).expect("events"),
        events
    );
    let unknown = encoded.replacen("\"cityId\":", "\"unexpectedField\":true,\"cityId\":", 1);
    assert!(serde_json::from_str::<Vec<ClientEventDto>>(&unknown).is_err());
}

pub(super) fn response() -> ClientResponseBodyDto {
    ClientResponseBodyDto::Query {
        result: ClientQueryResultDto::ProductionOptions {
            stamp: stamp(),
            city_id: "city-1".to_owned(),
            current_target: Some(CityProductionTargetDto::Project {
                project_type: CityProjectTypeDto::Research,
            }),
            invested_production: 4,
            production_overflow: 1,
            rush_quote: ProductionRushQuoteDto {
                production: 0,
                gold_cost: 0,
                rejection: Some(ClientCommandRejectionCodeDto::ProjectCannotBeRushed),
            },
            buildings: vec![ProductionOptionDto {
                target: CityProductionTargetDto::Building {
                    building_type: CityBuildingTypeDto::Workshop,
                },
                cost: 15,
                forecast: ProductionForecastDto {
                    invested_production: 4,
                    production_per_turn: 3,
                    estimated_turns: Some(4),
                    project_output: None,
                    spawn_blocked: false,
                },
                rejection: None,
            }],
            units: vec![UnitProductionOptionDto {
                option: ProductionOptionDto {
                    target: CityProductionTargetDto::Unit {
                        unit_type: UnitKindDto::Tank,
                    },
                    cost: 32,
                    forecast: ProductionForecastDto {
                        invested_production: 4,
                        production_per_turn: 3,
                        estimated_turns: Some(10),
                        project_output: None,
                        spawn_blocked: false,
                    },
                    rejection: None,
                },
                resource_options: vec![StrategicResourceStockpileDto(BTreeMap::from([(
                    ResourceTypeDto::Oil,
                    2,
                )]))],
                affordable_resource_option_indices: vec![0],
            }],
            projects: vec![ProductionOptionDto {
                target: CityProductionTargetDto::Project {
                    project_type: CityProjectTypeDto::Research,
                },
                cost: 0,
                forecast: ProductionForecastDto {
                    invested_production: 4,
                    production_per_turn: 3,
                    estimated_turns: None,
                    project_output: Some(1),
                    spawn_blocked: false,
                },
                rejection: None,
            }],
            wonders: vec![ProductionOptionDto {
                target: CityProductionTargetDto::Wonder {
                    wonder_type: WonderTypeDto::GreatLibrary,
                },
                cost: 25,
                forecast: ProductionForecastDto {
                    invested_production: 4,
                    production_per_turn: 3,
                    estimated_turns: Some(7),
                    project_output: None,
                    spawn_blocked: false,
                },
                rejection: None,
            }],
            specializations: vec![CitySpecializationOptionDto {
                specialization: CitySpecializationTypeDto::Industry,
                required_building: CityBuildingTypeDto::Workshop,
                rejection: None,
            }],
        },
    }
}

fn dispatch(command: ClientCommandDto) -> ClientRequestBodyDto {
    ClientRequestBodyDto::Dispatch { command }
}
