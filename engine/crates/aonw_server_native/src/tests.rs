use aonw_contracts::server::{
    SERVER_HOST_API_VERSION, ServerHostErrorCodeDto, ServerHostOutcomeDto, ServerHostResponseDto,
};
use serde_json::json;

use super::{
    aonw_server_native_api_version, aonw_server_native_apply_player_command,
    aonw_server_native_build_identity_data, aonw_server_native_build_identity_len,
    aonw_server_native_prepare_world, aonw_server_native_response_data,
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
fn prepare_response_transfers_one_reusable_world() {
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
    let map = json!({
        "schemaVersion": 1,
        "gridLayout": "oddQFlatTop",
        "cols": 5,
        "rows": 5,
        "mapName": "native-server-test",
        "defaultZoom": 1.0,
        "objectives": [],
        "tiles": tiles
    });
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
