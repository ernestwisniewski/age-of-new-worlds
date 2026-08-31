//! Golden and strict-boundary tests for the stateless map client contract.

use aonw_contracts::CoordinateDto;
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientOutcomeDto, ClientRequestBodyDto, ClientRequestDto,
    ClientResponseBodyDto, ClientResponseDto, MapGridLayoutDto, MapObjectiveTypeDto,
    MapObjectiveViewDto, MapResourceDto, MapTerrainDto, MapTileViewDto, MapViewDto,
};

fn map_view() -> MapViewDto {
    MapViewDto {
        map_id: "map-1".to_owned(),
        content_hash: "a".repeat(64),
        grid_layout: MapGridLayoutDto::OddQFlatTop,
        cols: 1,
        rows: 1,
        default_zoom: 1.25,
        tiles: vec![MapTileViewDto {
            coordinate: CoordinateDto { col: 0, row: 0 },
            display_terrain: MapTerrainDto::Forest,
            yield_terrain: MapTerrainDto::Grassland,
            movement_terrains: vec![MapTerrainDto::Grassland, MapTerrainDto::Forest],
            terrain_tags: vec![MapTerrainDto::Forest, MapTerrainDto::Grassland],
            resources: vec![MapResourceDto::Deer],
            height: 2,
        }],
        objectives: vec![MapObjectiveViewDto {
            id: "ruins-1".to_owned(),
            objective_type: MapObjectiveTypeDto::Ruins,
            coordinate: CoordinateDto { col: 0, row: 0 },
            required_hold_turns: 2,
            victory_points: 3,
            gold_per_turn: 1,
        }],
    }
}

#[test]
fn inspect_map_request_golden_is_stable() {
    let request = ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request: ClientRequestBodyDto::InspectMap {
            map_document: "map-document".to_owned(),
        },
    };
    let golden = include_str!("../../../fixtures/client_protocol/inspect_map_request.json").trim();

    assert_eq!(request.to_json().expect("request JSON"), golden);
    assert_eq!(
        ClientRequestDto::from_json(golden).expect("request"),
        request
    );
}

#[test]
fn map_inspected_response_golden_is_stable_and_strict() {
    let response = ClientResponseDto {
        api_version: CLIENT_API_VERSION,
        outcome: ClientOutcomeDto::Success {
            response: Box::new(ClientResponseBodyDto::MapInspected { map: map_view() }),
        },
    };
    let golden =
        include_str!("../../../fixtures/client_protocol/map_inspected_response.json").trim();

    assert_eq!(response.to_json().expect("response JSON"), golden);
    assert_eq!(
        ClientResponseDto::from_json(golden).expect("response"),
        response
    );

    let mut foreign_field: serde_json::Value = serde_json::from_str(golden).expect("golden JSON");
    foreign_field["outcome"]["response"]["map"]["tiles"][0]["unknown"] = serde_json::json!(true);
    assert!(ClientResponseDto::from_json(&foreign_field.to_string()).is_err());
}
