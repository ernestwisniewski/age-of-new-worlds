use aonw_map_workbench::MAP_WORKBENCH_API_VERSION;
use serde_json::{Value, json};

use super::dispatch_json;

#[test]
fn native_workbench_bridge_returns_rust_generated_documents() {
    let spec = json!({
        "generatorId": "blank",
        "generatorVersion": 1,
        "mapId": "native_generated",
        "cols": 5,
        "rows": 5,
        "defaultZoom": 1.0,
        "hexRadiusMeters": 100.0,
        "maxTerrainHeightMeters": 240.0,
        "seed": "42",
    });
    let request = json!({
        "apiVersion": MAP_WORKBENCH_API_VERSION,
        "request": {
            "type": "generateMap",
            "specDocument": serde_json::to_string_pretty(&spec).expect("spec"),
        },
    });
    let response: Value =
        serde_json::from_str(&dispatch_json(&request.to_string())).expect("response");
    let package = &response["outcome"]["response"]["package"];
    assert_eq!(response["outcome"]["status"], "success");
    assert!(package["mapDocument"].as_str().is_some());
    assert!(package["terrainAuthoringDocument"].as_str().is_some());
    assert!(package["generationDocument"].as_str().is_some());
    assert!(
        package["generatedDecorationPlanDocument"]
            .as_str()
            .is_some()
    );
}

#[test]
fn native_workbench_bridge_reconfigures_metric_height() {
    let spec = json!({
        "generatorId": "blank",
        "generatorVersion": 1,
        "mapId": "native_generated",
        "cols": 5,
        "rows": 5,
        "defaultZoom": 1.0,
        "hexRadiusMeters": 100.0,
        "maxTerrainHeightMeters": 240.0,
        "seed": "42",
    });
    let generated_request = json!({
        "apiVersion": MAP_WORKBENCH_API_VERSION,
        "request": {
            "type": "generateMap",
            "specDocument": serde_json::to_string_pretty(&spec).expect("spec"),
        },
    });
    let generated: Value = serde_json::from_str(&dispatch_json(&generated_request.to_string()))
        .expect("generated response");
    let package = &generated["outcome"]["response"]["package"];
    let update_request = json!({
        "apiVersion": MAP_WORKBENCH_API_VERSION,
        "request": {
            "type": "reconfigureTerrainHeight",
            "mapDocument": package["mapDocument"],
            "terrainAuthoringDocument": package["terrainAuthoringDocument"],
            "maxTerrainHeightMeters": 180.0,
        },
    });
    let response: Value =
        serde_json::from_str(&dispatch_json(&update_request.to_string())).expect("update response");

    assert_eq!(response["outcome"]["status"], "success");
    assert_eq!(
        response["outcome"]["response"]["update"]["maxTerrainHeightMeters"],
        180.0
    );
}

#[test]
fn native_workbench_bridge_edits_logical_tiles_through_rust() {
    let spec = json!({
        "generatorId": "blank",
        "generatorVersion": 1,
        "mapId": "native_edited",
        "cols": 5,
        "rows": 5,
        "defaultZoom": 1.0,
        "hexRadiusMeters": 100.0,
        "maxTerrainHeightMeters": 240.0,
        "seed": "42",
    });
    let generated_request = json!({
        "apiVersion": MAP_WORKBENCH_API_VERSION,
        "request": {
            "type": "generateMap",
            "specDocument": serde_json::to_string_pretty(&spec).expect("spec"),
        },
    });
    let generated: Value = serde_json::from_str(&dispatch_json(&generated_request.to_string()))
        .expect("generated response");
    let package = &generated["outcome"]["response"]["package"];
    let edit_request = json!({
        "apiVersion": MAP_WORKBENCH_API_VERSION,
        "request": {
            "type": "setTileHeight",
            "mapDocument": package["mapDocument"],
            "terrainAuthoringDocument": package["terrainAuthoringDocument"],
            "col": 2,
            "row": 3,
            "height": 5,
        },
    });
    let response: Value =
        serde_json::from_str(&dispatch_json(&edit_request.to_string())).expect("edit response");

    assert_eq!(response["outcome"]["status"], "success");
    assert_eq!(response["outcome"]["response"]["type"], "mapTileEdited");
    assert_eq!(
        response["outcome"]["response"]["update"]["snapshot"]["tile"]["height"],
        5
    );
    assert_ne!(
        response["outcome"]["response"]["update"]["mapContentHash"],
        package["mapContentHash"]
    );
}
