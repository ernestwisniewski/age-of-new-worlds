use aonw_contracts::client::{ClientQueryDto, ClientQueryResultDto};
use aonw_contracts::server::{
    PlayerQueryServerRequestDto, SERVER_HOST_API_VERSION, ServerHostErrorCodeDto,
    ServerHostOutcomeDto, ServerHostResponseBodyDto, ServerHostResponseDto,
    ServerPlayerQueryOutcomeDto,
};
use serde_json::json;

use super::{
    aonw_server_native_api_version, aonw_server_native_apply_player_command,
    aonw_server_native_build_identity_data, aonw_server_native_build_identity_len,
    aonw_server_native_create_match, aonw_server_native_prepare_world,
    aonw_server_native_query_player, aonw_server_native_response_data,
    aonw_server_native_response_free, aonw_server_native_response_len,
    aonw_server_native_response_take_world, aonw_server_native_world_free,
};

#[test]
#[allow(unsafe_code)]
fn identity_and_protocol_are_exact() {
    assert_eq!(aonw_server_native_api_version(), SERVER_HOST_API_VERSION);
    // SAFETY: Identity bytes have static lifetime.
    let identity = unsafe {
        core::slice::from_raw_parts(
            aonw_server_native_build_identity_data(),
            aonw_server_native_build_identity_len(),
        )
    };
    assert_eq!(identity, b"aonw_server_native/0.1.0");
}

#[test]
#[allow(unsafe_code)]
fn invalid_request_returns_owned_contained_failure() {
    // SAFETY: The request bytes remain alive for the duration of the call.
    let response = unsafe { aonw_server_native_prepare_world(b"{}".as_ptr(), 2) };
    assert!(!response.is_null());
    // SAFETY: This test owns the live response until it is freed below.
    let decoded = unsafe { decode_response(response) };
    assert!(matches!(
        decoded.outcome,
        ServerHostOutcomeDto::Failure { error }
            if error.code == ServerHostErrorCodeDto::InvalidRequest
    ));
    // SAFETY: The test transfers its only live response handle.
    unsafe { aonw_server_native_response_free(response) };
}

#[test]
#[allow(unsafe_code)]
fn player_command_requires_a_live_prepared_world() {
    // SAFETY: Null is deliberately tested and the request buffer stays alive.
    let response =
        unsafe { aonw_server_native_apply_player_command(core::ptr::null(), b"{}".as_ptr(), 2) };
    // SAFETY: This test owns the live response until it is freed below.
    let decoded = unsafe { decode_response(response) };
    assert!(matches!(
        decoded.outcome,
        ServerHostOutcomeDto::Failure { error }
            if error.code == ServerHostErrorCodeDto::InvalidFfiArgument
    ));
    // SAFETY: The test transfers its only live response handle.
    unsafe { aonw_server_native_response_free(response) };
}

#[test]
#[allow(unsafe_code)]
fn player_query_returns_one_owned_recipient_safe_response() {
    let map = map_document();
    let prepare_request = serde_json::to_vec(&json!({
        "apiVersion": SERVER_HOST_API_VERSION,
        "mapDocument": serde_json::to_string(&map).expect("map JSON"),
        "rulesetId": "aonw-standard"
    }))
    .expect("prepare request");
    // SAFETY: The request buffer stays alive for this call.
    let prepare_response = unsafe {
        aonw_server_native_prepare_world(prepare_request.as_ptr(), prepare_request.len())
    };
    // SAFETY: The response remains live while its bytes are decoded.
    let prepared = unsafe { decode_response(prepare_response) };
    let ServerHostOutcomeDto::Success { response } = prepared.outcome else {
        panic!("world preparation failed")
    };
    let ServerHostResponseBodyDto::WorldPrepared {
        map_hash,
        ruleset_hash,
    } = *response
    else {
        panic!("world response expected")
    };
    // SAFETY: The response is live and uniquely accessed.
    let world = unsafe { aonw_server_native_response_take_world(prepare_response) };
    // SAFETY: Ownership of the response is released once after the transfer.
    unsafe { aonw_server_native_response_free(prepare_response) };

    let create_request = serde_json::to_vec(&json!({
        "apiVersion": SERVER_HOST_API_VERSION,
        "mapHash": map_hash,
        "rulesetHash": ruleset_hash,
        "scenarioDocument": serde_json::to_string(&scenario_document()).expect("scenario JSON"),
        "matchIdentity": match_identity(),
        "fogEnabled": true
    }))
    .expect("create request");
    // SAFETY: The world and request buffer remain live for this call.
    let create_response = unsafe {
        aonw_server_native_create_match(world, create_request.as_ptr(), create_request.len())
    };
    // SAFETY: The response remains live while its bytes are decoded.
    let created = unsafe { decode_response(create_response) };
    let ServerHostOutcomeDto::Success { response } = created.outcome else {
        panic!("match creation failed")
    };
    let ServerHostResponseBodyDto::MatchCreated { result } = *response else {
        panic!("match response expected")
    };
    // SAFETY: Ownership of the response is released once after decoding.
    unsafe { aonw_server_native_response_free(create_response) };

    let query = PlayerQueryServerRequestDto {
        api_version: SERVER_HOST_API_VERSION,
        authenticated_actor_player_id: "player-1".to_owned(),
        query: ClientQueryDto::Reachable {
            expected_revision: result.state.revision,
            unit_id: "unit-1".to_owned(),
        },
        map_hash,
        ruleset_hash,
        state: result.state,
    };
    let query_request = serde_json::to_vec(&query).expect("query request");
    // SAFETY: The world and request buffer remain live for this call.
    let query_response = unsafe {
        aonw_server_native_query_player(world, query_request.as_ptr(), query_request.len())
    };
    // SAFETY: The response remains live while its bytes are decoded.
    let queried = unsafe { decode_response(query_response) };
    let ServerHostOutcomeDto::Success { response } = queried.outcome else {
        panic!("query host failed")
    };
    let ServerHostResponseBodyDto::PlayerQueryExecuted { result } = *response else {
        panic!("player query response expected")
    };
    let ServerPlayerQueryOutcomeDto::Success { result } = *result else {
        panic!("player query was rejected")
    };
    assert!(matches!(*result, ClientQueryResultDto::Reachable { .. }));
    // SAFETY: The test transfers each owned handle exactly once.
    unsafe {
        aonw_server_native_response_free(query_response);
        aonw_server_native_world_free(world);
    }
}

#[test]
#[allow(unsafe_code)]
fn prepare_response_transfers_one_reusable_world() {
    let map = map_document();
    let request = serde_json::to_vec(&json!({
        "apiVersion": SERVER_HOST_API_VERSION,
        "mapDocument": serde_json::to_string(&map).expect("map JSON"),
        "rulesetId": "aonw-standard"
    }))
    .expect("request JSON");

    // SAFETY: The request buffer is alive and readable during the call.
    let response = unsafe { aonw_server_native_prepare_world(request.as_ptr(), request.len()) };
    // SAFETY: The live response owns readable bytes until it is freed.
    let decoded = unsafe { decode_response(response) };
    assert!(
        matches!(decoded.outcome, ServerHostOutcomeDto::Success { .. }),
        "unexpected prepare response: {decoded:?}"
    );
    // SAFETY: The response is live and uniquely accessed.
    let world = unsafe { aonw_server_native_response_take_world(response) };
    assert!(!world.is_null());
    // SAFETY: A second transfer from the same live response is defined to return null.
    assert!(unsafe { aonw_server_native_response_take_world(response) }.is_null());
    // SAFETY: This test transfers each owned handle exactly once.
    unsafe {
        aonw_server_native_response_free(response);
        aonw_server_native_world_free(world);
    }
}

fn map_document() -> serde_json::Value {
    let tiles = (0..5)
        .flat_map(|row| {
            (0..5).map(move |col| {
                json!({
                    "col": col,
                    "row": row,
                    "terrainTags": ["plains"],
                    "resources": [],
                    "height": 0
                })
            })
        })
        .collect::<Vec<_>>();
    json!({
        "schemaVersion": 1,
        "gridLayout": "oddQFlatTop",
        "cols": 5,
        "rows": 5,
        "mapName": "native-server-test",
        "defaultZoom": 1.0,
        "objectives": [],
        "tiles": tiles
    })
}

fn scenario_document() -> serde_json::Value {
    json!({
        "schemaVersion": 1,
        "scenarioId": "native-server-scenario",
        "mapId": "native-server-test",
        "rulesetId": "aonw-standard",
        "initialUnits": [
            {
                "id": "unit-1",
                "ownerPlayerId": "player-1",
                "kind": "commander",
                "name": "One",
                "col": 0,
                "row": 0
            },
            {
                "id": "unit-2",
                "ownerPlayerId": "player-2",
                "kind": "commander",
                "name": "Two",
                "col": 4,
                "row": 4
            }
        ]
    })
}

fn match_identity() -> serde_json::Value {
    json!({
        "matchRules": {
            "gameLength": {
                "kind": "unlimited",
                "targetMinutes": null,
                "turnLimit": null,
                "paceProfile": "unlimited",
                "scoreFallbackEnabled": false
            },
            "victory": {
                "conquestEnabled": true,
                "dominationEnabled": true,
                "dominationControlPercent": 60,
                "dominationHoldTurns": 5,
                "scoreFallbackEnabled": false,
                "turnLimit": null,
                "hardTimeLimitMinutes": null,
                "culturalEnabled": true,
                "culturalRequiredArtifacts": 6,
                "culturalHoldTurns": 5
            },
            "balance": {}
        },
        "participants": [
            {
                "id": "player-1",
                "name": "One",
                "colorValue": 4_278_190_335_u32,
                "country": "poland",
                "kind": "human",
                "ai": null
            },
            {
                "id": "player-2",
                "name": "Two",
                "colorValue": 16_711_935_u32,
                "country": "germany",
                "kind": "human",
                "ai": null
            }
        ],
        "gameMode": "multiplayer"
    })
}

#[allow(unsafe_code)]
unsafe fn decode_response(response: *const core::ffi::c_void) -> ServerHostResponseDto {
    // SAFETY: The caller keeps one live response handle for this read.
    let bytes = unsafe {
        core::slice::from_raw_parts(
            aonw_server_native_response_data(response),
            aonw_server_native_response_len(response),
        )
    };
    serde_json::from_slice(bytes).expect("strict native response")
}
