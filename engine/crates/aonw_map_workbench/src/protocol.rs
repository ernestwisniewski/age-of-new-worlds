use serde::de::Error as _;
use serde::{Deserialize, Deserializer, Serialize};

use aonw_content::{ResourceType, TerrainType};
use aonw_domain::HexCoord;

use crate::{
    GeneratedMapPackage, LogicalMapTileEditorSnapshot, MapGenerationSpec, UpdatedLogicalMap,
    UpdatedTerrainProfile,
};

/// Current framework-neutral logical-map workbench protocol version.
pub const MAP_WORKBENCH_API_VERSION: u16 = 1;
// One edit request can carry a maximum-sized canonical map plus its complete
// per-hex terrain profile. Each nested codec still enforces its own limit.
const MAX_WORKBENCH_REQUEST_BYTES: usize = 16 * 1024 * 1024;

/// Strict dispatcher used by native authoring adapters.
pub struct MapWorkbenchProtocol;

impl MapWorkbenchProtocol {
    /// Executes one current logical-map authoring request.
    #[must_use]
    pub fn dispatch_json(input: &str) -> String {
        let response = if input.len() > MAX_WORKBENCH_REQUEST_BYTES {
            failure(
                "invalid_workbench_request",
                format!("request exceeds {MAX_WORKBENCH_REQUEST_BYTES} bytes"),
                None,
            )
        } else {
            match serde_json::from_str::<WorkbenchRequest>(input) {
                Ok(request) => dispatch(request),
                Err(error) => failure("invalid_workbench_request", error, None),
            }
        };
        serde_json::to_string(&response).unwrap_or_else(|_| {
            format!(
                r#"{{"apiVersion":{MAP_WORKBENCH_API_VERSION},"outcome":{{"status":"failure","error":{{"code":"workbench_serialization_failed","message":"workbench response serialization failed"}}}}}}"#
            )
        })
    }
}

fn dispatch(request: WorkbenchRequest) -> WorkbenchResponse {
    if request.api_version != MAP_WORKBENCH_API_VERSION {
        return failure(
            "unsupported_workbench_api_version",
            format!(
                "unsupported workbench API version {}; expected {MAP_WORKBENCH_API_VERSION}",
                request.api_version
            ),
            None,
        );
    }
    match request.request {
        WorkbenchRequestBody::GenerateMap { spec_document } => {
            match MapGenerationSpec::from_json(spec_document.as_bytes())
                .and_then(|spec| GeneratedMapPackage::generate(&spec))
            {
                Ok(package) => WorkbenchResponse {
                    api_version: MAP_WORKBENCH_API_VERSION,
                    outcome: WorkbenchOutcome::Success {
                        response: WorkbenchResponseBody::MapGenerated { package },
                    },
                },
                Err(error) => failure(error.code(), &error, error.path()),
            }
        }
        WorkbenchRequestBody::ReconfigureTerrainHeight {
            map_document,
            terrain_authoring_document,
            max_terrain_height_meters,
        } => match UpdatedTerrainProfile::reconfigure(
            &map_document,
            &terrain_authoring_document,
            max_terrain_height_meters,
        ) {
            Ok(update) => WorkbenchResponse {
                api_version: MAP_WORKBENCH_API_VERSION,
                outcome: WorkbenchOutcome::Success {
                    response: WorkbenchResponseBody::TerrainHeightReconfigured { update },
                },
            },
            Err(error) => failure(error.code(), &error, error.path()),
        },
        WorkbenchRequestBody::InspectMapTile {
            map_document,
            col,
            row,
        } => match LogicalMapTileEditorSnapshot::inspect(&map_document, HexCoord::new(col, row)) {
            Ok(snapshot) => WorkbenchResponse {
                api_version: MAP_WORKBENCH_API_VERSION,
                outcome: WorkbenchOutcome::Success {
                    response: WorkbenchResponseBody::MapTileInspected { snapshot },
                },
            },
            Err(error) => failure(error.code(), &error, error.path()),
        },
        WorkbenchRequestBody::SetTileTerrain {
            map_document,
            terrain_authoring_document,
            col,
            row,
            terrain,
        } => dispatch_edit(UpdatedLogicalMap::set_tile_terrain(
            &map_document,
            &terrain_authoring_document,
            HexCoord::new(col, row),
            terrain,
        )),
        WorkbenchRequestBody::SetTileResources {
            map_document,
            terrain_authoring_document,
            col,
            row,
            resources,
        } => dispatch_edit(UpdatedLogicalMap::set_tile_resources(
            &map_document,
            &terrain_authoring_document,
            HexCoord::new(col, row),
            resources,
        )),
        WorkbenchRequestBody::SetTileHeight {
            map_document,
            terrain_authoring_document,
            col,
            row,
            height,
        } => dispatch_edit(UpdatedLogicalMap::set_tile_height(
            &map_document,
            &terrain_authoring_document,
            HexCoord::new(col, row),
            height,
        )),
    }
}

fn dispatch_edit(result: Result<UpdatedLogicalMap, crate::MapWorkbenchError>) -> WorkbenchResponse {
    match result {
        Ok(update) => WorkbenchResponse {
            api_version: MAP_WORKBENCH_API_VERSION,
            outcome: WorkbenchOutcome::Success {
                response: WorkbenchResponseBody::MapTileEdited { update },
            },
        },
        Err(error) => failure(error.code(), &error, error.path()),
    }
}

fn failure(code: &str, message: impl core::fmt::Display, path: Option<&str>) -> WorkbenchResponse {
    WorkbenchResponse {
        api_version: MAP_WORKBENCH_API_VERSION,
        outcome: WorkbenchOutcome::Failure {
            error: WorkbenchErrorDto {
                code: code.to_owned(),
                message: message.to_string(),
                path: path.map(str::to_owned),
            },
        },
    }
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct WorkbenchRequest {
    api_version: u16,
    request: WorkbenchRequestBody,
}

#[derive(Deserialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
enum WorkbenchRequestBody {
    GenerateMap {
        spec_document: String,
    },
    ReconfigureTerrainHeight {
        map_document: String,
        terrain_authoring_document: String,
        #[serde(deserialize_with = "deserialize_f64")]
        max_terrain_height_meters: f64,
    },
    InspectMapTile {
        map_document: String,
        col: i32,
        row: i32,
    },
    SetTileTerrain {
        map_document: String,
        terrain_authoring_document: String,
        col: i32,
        row: i32,
        terrain: TerrainType,
    },
    SetTileResources {
        map_document: String,
        terrain_authoring_document: String,
        col: i32,
        row: i32,
        resources: Vec<ResourceType>,
    },
    SetTileHeight {
        map_document: String,
        terrain_authoring_document: String,
        col: i32,
        row: i32,
        height: u8,
    },
}

fn deserialize_f64<'de, D: Deserializer<'de>>(deserializer: D) -> Result<f64, D::Error> {
    let number = serde_json::Number::deserialize(deserializer)?;
    number
        .as_f64()
        .filter(|value| value.is_finite())
        .ok_or_else(|| D::Error::custom("number must be representable as a finite f64"))
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct WorkbenchResponse {
    api_version: u16,
    outcome: WorkbenchOutcome,
}

#[derive(Serialize)]
#[serde(
    tag = "status",
    rename_all = "camelCase",
    rename_all_fields = "camelCase"
)]
enum WorkbenchOutcome {
    Success { response: WorkbenchResponseBody },
    Failure { error: WorkbenchErrorDto },
}

#[derive(Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase"
)]
enum WorkbenchResponseBody {
    MapGenerated {
        package: GeneratedMapPackage,
    },
    TerrainHeightReconfigured {
        update: UpdatedTerrainProfile,
    },
    MapTileInspected {
        snapshot: LogicalMapTileEditorSnapshot,
    },
    MapTileEdited {
        update: UpdatedLogicalMap,
    },
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct WorkbenchErrorDto {
    code: String,
    message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    path: Option<String>,
}
