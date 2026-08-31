//! Panic-safe, bounded C ABI for the stateless Serverpod host.

#![deny(unsafe_op_in_unsafe_fn)]

use std::panic::{AssertUnwindSafe, catch_unwind};

use aonw_contracts::server::{
    CreateServerMatchRequestDto, MAX_SERVER_HOST_REQUEST_JSON_BYTES, PrepareServerWorldRequestDto,
    ProjectServerStateRequestDto, SERVER_HOST_API_VERSION, ServerHostCodecError,
    ServerHostErrorCodeDto, ServerHostErrorDto, ServerHostOutcomeDto, ServerHostResponseBodyDto,
    ServerHostResponseDto, SubmitTurnServerRequestDto,
};
use aonw_server_runtime::{
    PreparedServerWorld, ServerBoundaryError, apply_submit_turn_dto, create_server_match_dto,
    prepare_server_world, project_server_state_dto,
};

static BUILD_IDENTITY: &[u8] = concat!("aonw_server_native/", env!("CARGO_PKG_VERSION")).as_bytes();

struct NativeResponse {
    bytes: Box<[u8]>,
    world: Option<Box<PreparedServerWorld>>,
}

/// Returns whether this library contains the real stateless Rust host.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn aonw_server_native_is_available() -> u8 {
    1
}

/// Returns the only current server-host protocol version.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn aonw_server_native_api_version() -> u16 {
    SERVER_HOST_API_VERSION
}

/// Returns the immutable native build-identity byte length.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn aonw_server_native_build_identity_len() -> usize {
    BUILD_IDENTITY.len()
}

/// Returns immutable UTF-8 build-identity bytes for the library lifetime.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn aonw_server_native_build_identity_data() -> *const u8 {
    BUILD_IDENTITY.as_ptr()
}

/// Validates strict immutable content and returns a response owning its world handle.
///
/// # Safety
///
/// `request` must be null only when `request_len` is zero, otherwise it must
/// reference `request_len` readable bytes for the duration of this call.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub unsafe extern "C" fn aonw_server_native_prepare_world(
    request: *const u8,
    request_len: usize,
) -> *mut core::ffi::c_void {
    contain(|| {
        let input = unsafe { read_request(request, request_len) }?;
        let request =
            PrepareServerWorldRequestDto::from_json(input).map_err(|error| codec_error(&error))?;
        let world = prepare_server_world(request).map_err(|error| boundary_error(&error))?;
        let response = success(ServerHostResponseBodyDto::WorldPrepared {
            map_hash: world.map_hash().to_string(),
            ruleset_hash: world.ruleset_hash().to_string(),
        })?;
        Ok(NativeResponse {
            bytes: response.into_bytes().into_boxed_slice(),
            world: Some(Box::new(world)),
        })
    })
}

/// Transfers the prepared world out of a successful prepare response.
///
/// Returns null for a failure response, invalid handle, or a repeated call.
///
/// # Safety
///
/// `response` must be null or a live uniquely accessed response returned by
/// [`aonw_server_native_prepare_world`].
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub unsafe extern "C" fn aonw_server_native_response_take_world(
    response: *mut core::ffi::c_void,
) -> *mut core::ffi::c_void {
    if response.is_null() {
        return core::ptr::null_mut();
    }
    let transfer = catch_unwind(AssertUnwindSafe(|| {
        // SAFETY: The caller guarantees a unique live response handle.
        match unsafe { &mut *response.cast::<NativeResponse>() }
            .world
            .take()
        {
            Some(world) => Box::into_raw(world).cast(),
            None => core::ptr::null_mut(),
        }
    }));
    transfer.unwrap_or(core::ptr::null_mut())
}

/// Releases a world returned by [`aonw_server_native_response_take_world`].
///
/// # Safety
///
/// `world` must be null or a live handle returned by this library and not
/// released previously. No submit call may still be using it.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub unsafe extern "C" fn aonw_server_native_world_free(world: *mut core::ffi::c_void) {
    if !world.is_null() {
        // SAFETY: The caller transfers ownership of one live world exactly once.
        drop(unsafe { Box::from_raw(world.cast::<PreparedServerWorld>()) });
    }
}

/// Executes one stateless authenticated `SubmitTurn` against a prepared world.
///
/// # Safety
///
/// `world` must be a live prepared handle for the duration of the call.
/// `request` follows the same rules as [`aonw_server_native_prepare_world`].
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub unsafe extern "C" fn aonw_server_native_submit_turn(
    world: *const core::ffi::c_void,
    request: *const u8,
    request_len: usize,
) -> *mut core::ffi::c_void {
    contain(|| {
        if world.is_null() {
            return Err(failure(
                ServerHostErrorCodeDto::InvalidFfiArgument,
                "prepared world pointer is null",
            ));
        }
        let input = unsafe { read_request(request, request_len) }?;
        let request =
            SubmitTurnServerRequestDto::from_json(input).map_err(|error| codec_error(&error))?;
        // SAFETY: The caller keeps the immutable world alive for this call.
        let world = unsafe { &*world.cast::<PreparedServerWorld>() }.clone();
        let result =
            apply_submit_turn_dto(world, request).map_err(|error| boundary_error(&error))?;
        let response = success(ServerHostResponseBodyDto::CommandApplied {
            result: Box::new(result),
        })?;
        Ok(NativeResponse {
            bytes: response.into_bytes().into_boxed_slice(),
            world: None,
        })
    })
}

/// Validates and projects one canonical state against a prepared world.
///
/// # Safety
///
/// `world` must be a live prepared handle for the duration of the call.
/// `request` follows the same rules as [`aonw_server_native_prepare_world`].
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub unsafe extern "C" fn aonw_server_native_project_state(
    world: *const core::ffi::c_void,
    request: *const u8,
    request_len: usize,
) -> *mut core::ffi::c_void {
    contain(|| {
        if world.is_null() {
            return Err(failure(
                ServerHostErrorCodeDto::InvalidFfiArgument,
                "prepared world pointer is null",
            ));
        }
        let input = unsafe { read_request(request, request_len) }?;
        let request =
            ProjectServerStateRequestDto::from_json(input).map_err(|error| codec_error(&error))?;
        // SAFETY: The caller keeps the immutable world alive for this call.
        let world = unsafe { &*world.cast::<PreparedServerWorld>() };
        let result =
            project_server_state_dto(world, request).map_err(|error| boundary_error(&error))?;
        let response = success(ServerHostResponseBodyDto::StateProjected {
            result: Box::new(result),
        })?;
        Ok(NativeResponse {
            bytes: response.into_bytes().into_boxed_slice(),
            world: None,
        })
    })
}

/// Constructs one authoritative multiplayer match against a prepared world.
///
/// # Safety
///
/// `world` must be a live prepared handle for the duration of the call.
/// `request` follows the same rules as [`aonw_server_native_prepare_world`].
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub unsafe extern "C" fn aonw_server_native_create_match(
    world: *const core::ffi::c_void,
    request: *const u8,
    request_len: usize,
) -> *mut core::ffi::c_void {
    contain(|| {
        if world.is_null() {
            return Err(failure(
                ServerHostErrorCodeDto::InvalidFfiArgument,
                "prepared world pointer is null",
            ));
        }
        let input = unsafe { read_request(request, request_len) }?;
        let request =
            CreateServerMatchRequestDto::from_json(input).map_err(|error| codec_error(&error))?;
        // SAFETY: The caller keeps the immutable world alive for this call.
        let world = unsafe { &*world.cast::<PreparedServerWorld>() };
        let result =
            create_server_match_dto(world, request).map_err(|error| boundary_error(&error))?;
        let response = success(ServerHostResponseBodyDto::MatchCreated {
            result: Box::new(result),
        })?;
        Ok(NativeResponse {
            bytes: response.into_bytes().into_boxed_slice(),
            world: None,
        })
    })
}

/// Returns the response byte length.
///
/// # Safety
///
/// `response` must be null or a live response handle returned by this library.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub unsafe extern "C" fn aonw_server_native_response_len(
    response: *const core::ffi::c_void,
) -> usize {
    if response.is_null() {
        return 0;
    }
    // SAFETY: The caller guarantees a live response handle.
    unsafe { (&*response.cast::<NativeResponse>()).bytes.len() }
}

/// Returns borrowed response bytes valid until response release.
///
/// # Safety
///
/// `response` must be null or a live response handle returned by this library.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub unsafe extern "C" fn aonw_server_native_response_data(
    response: *const core::ffi::c_void,
) -> *const u8 {
    if response.is_null() {
        return core::ptr::null();
    }
    // SAFETY: The caller guarantees a live response handle.
    unsafe { (&*response.cast::<NativeResponse>()).bytes.as_ptr() }
}

/// Releases one response handle and any unclaimed prepared world it owns.
///
/// # Safety
///
/// `response` must be null or a live handle returned by this library and not
/// released previously.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub unsafe extern "C" fn aonw_server_native_response_free(response: *mut core::ffi::c_void) {
    if !response.is_null() {
        // SAFETY: The caller transfers ownership of one live response exactly once.
        drop(unsafe { Box::from_raw(response.cast::<NativeResponse>()) });
    }
}

fn contain(
    operation: impl FnOnce() -> Result<NativeResponse, ServerHostResponseDto>,
) -> *mut core::ffi::c_void {
    let response = catch_unwind(AssertUnwindSafe(operation));
    let native = match response {
        Ok(Ok(response)) => response,
        Ok(Err(error)) => NativeResponse {
            bytes: serialize_failure(&error),
            world: None,
        },
        Err(_) => NativeResponse {
            bytes: serialize_failure(&failure(
                ServerHostErrorCodeDto::NativePanic,
                "native server host panicked; nothing may be persisted",
            )),
            world: None,
        },
    };
    Box::into_raw(Box::new(native)).cast()
}

#[allow(unsafe_code)]
unsafe fn read_request<'a>(
    request: *const u8,
    request_len: usize,
) -> Result<&'a str, ServerHostResponseDto> {
    if request_len > MAX_SERVER_HOST_REQUEST_JSON_BYTES {
        return Err(failure(
            ServerHostErrorCodeDto::PayloadTooLarge,
            format!(
                "request is {request_len} bytes; maximum is {MAX_SERVER_HOST_REQUEST_JSON_BYTES}"
            ),
        ));
    }
    if request.is_null() && request_len != 0 {
        return Err(failure(
            ServerHostErrorCodeDto::InvalidFfiArgument,
            "request pointer is null for a non-empty request",
        ));
    }
    let bytes = if request_len == 0 {
        &[]
    } else {
        // SAFETY: The caller guarantees request_len readable bytes.
        unsafe { core::slice::from_raw_parts(request, request_len) }
    };
    core::str::from_utf8(bytes).map_err(|_| {
        failure(
            ServerHostErrorCodeDto::InvalidRequest,
            "request must be UTF-8",
        )
    })
}

fn codec_error(error: &ServerHostCodecError) -> ServerHostResponseDto {
    let code = match error {
        ServerHostCodecError::TooLarge { .. } => ServerHostErrorCodeDto::PayloadTooLarge,
        ServerHostCodecError::Json(_) => ServerHostErrorCodeDto::InvalidRequest,
    };
    failure(code, error.to_string())
}

fn boundary_error(error: &ServerBoundaryError) -> ServerHostResponseDto {
    failure(error.code(), error.to_string())
}

fn success(body: ServerHostResponseBodyDto) -> Result<String, ServerHostResponseDto> {
    ServerHostResponseDto {
        api_version: SERVER_HOST_API_VERSION,
        outcome: ServerHostOutcomeDto::Success {
            response: Box::new(body),
        },
    }
    .to_json()
    .map_err(|error| failure(ServerHostErrorCodeDto::ResponseTooLarge, error.to_string()))
}

fn failure(code: ServerHostErrorCodeDto, message: impl Into<String>) -> ServerHostResponseDto {
    ServerHostResponseDto {
        api_version: SERVER_HOST_API_VERSION,
        outcome: ServerHostOutcomeDto::Failure {
            error: ServerHostErrorDto {
                code,
                message: message.into(),
            },
        },
    }
}

fn serialize_failure(response: &ServerHostResponseDto) -> Box<[u8]> {
    response
        .to_json()
        .unwrap_or_else(|_| {
            format!(
                r#"{{"apiVersion":{SERVER_HOST_API_VERSION},"outcome":{{"status":"failure","error":{{"code":"response_too_large","message":"native response serialization failed"}}}}}}"#
            )
        })
        .into_bytes()
        .into_boxed_slice()
}

#[cfg(test)]
mod tests {
    use aonw_contracts::server::{
        SERVER_HOST_API_VERSION, ServerHostErrorCodeDto, ServerHostOutcomeDto,
        ServerHostResponseDto,
    };
    use serde_json::json;

    use super::{
        aonw_server_native_api_version, aonw_server_native_build_identity_data,
        aonw_server_native_build_identity_len, aonw_server_native_prepare_world,
        aonw_server_native_response_data, aonw_server_native_response_free,
        aonw_server_native_response_len, aonw_server_native_response_take_world,
        aonw_server_native_world_free,
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
        let bytes = unsafe {
            core::slice::from_raw_parts(
                aonw_server_native_response_data(response),
                aonw_server_native_response_len(response),
            )
        };
        let decoded: ServerHostResponseDto =
            serde_json::from_slice(bytes).expect("strict failure response");
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
        let decoded: ServerHostResponseDto = unsafe {
            serde_json::from_slice(core::slice::from_raw_parts(
                aonw_server_native_response_data(response),
                aonw_server_native_response_len(response),
            ))
        }
        .expect("prepare response");
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
}
