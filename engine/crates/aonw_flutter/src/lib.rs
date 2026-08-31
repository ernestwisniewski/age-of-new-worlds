//! Stable C ABI for the Flutter Native Assets adapter.

#![deny(unsafe_op_in_unsafe_fn)]

use std::panic::{AssertUnwindSafe, catch_unwind};

use aonw_ai::StrategicPlanner;
use aonw_contracts::client::CLIENT_API_VERSION;
use aonw_local_runtime::{ClientProtocol, LocalRuntime};

static BUILD_IDENTITY: &[u8] = concat!("aonw_flutter/", env!("CARGO_PKG_VERSION")).as_bytes();

struct FlutterSession {
    runtime: LocalRuntime,
    ai_driver: StrategicPlanner,
}

struct FlutterResponse(Box<[u8]>);

/// Returns whether this library contains the Rust runtime.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn aonw_flutter_is_available() -> u8 {
    1
}

/// Returns the supported shared client protocol version.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn aonw_flutter_client_api_version() -> u16 {
    CLIENT_API_VERSION
}

/// Returns the byte length of the immutable adapter build identity.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn aonw_flutter_build_identity_len() -> usize {
    BUILD_IDENTITY.len()
}

/// Returns immutable UTF-8 build identity bytes for the lifetime of the library.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn aonw_flutter_build_identity_data() -> *const u8 {
    BUILD_IDENTITY.as_ptr()
}

/// Allocates an independent local session.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub extern "C" fn aonw_flutter_session_new() -> *mut core::ffi::c_void {
    Box::into_raw(Box::new(FlutterSession {
        runtime: LocalRuntime::default(),
        ai_driver: StrategicPlanner,
    }))
    .cast()
}

/// Releases a session previously returned by [`aonw_flutter_session_new`].
///
/// # Safety
///
/// `session` must be null or a live handle returned by this library and not
/// released previously.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub unsafe extern "C" fn aonw_flutter_session_free(session: *mut core::ffi::c_void) {
    if !session.is_null() {
        // SAFETY: The caller transfers a live handle returned by session_new exactly once.
        drop(unsafe { Box::from_raw(session.cast::<FlutterSession>()) });
    }
}

/// Dispatches one UTF-8 client request and returns an owned response handle.
///
/// # Safety
///
/// `session` must be a live uniquely accessed session handle. `request` must
/// reference `request_len` readable bytes for the duration of the call.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub unsafe extern "C" fn aonw_flutter_session_request(
    session: *mut core::ffi::c_void,
    request: *const u8,
    request_len: usize,
) -> *mut core::ffi::c_void {
    let output = catch_unwind(AssertUnwindSafe(|| {
        if session.is_null() || (request.is_null() && request_len != 0) {
            return adapter_failure("invalid_ffi_argument", "invalid FFI pointer");
        }
        let bytes = if request_len == 0 {
            &[]
        } else {
            // SAFETY: The caller guarantees request points to request_len readable bytes.
            unsafe { core::slice::from_raw_parts(request, request_len) }
        };
        let Ok(input) = core::str::from_utf8(bytes) else {
            return adapter_failure("invalid_client_request", "request must be UTF-8");
        };
        // SAFETY: The caller keeps the unique session handle live for this call.
        let session = unsafe { &mut *session.cast::<FlutterSession>() };
        ClientProtocol::dispatch_json_with_ai(&mut session.runtime, input, &mut session.ai_driver)
    }));
    let output = if let Ok(output) = output {
        output
    } else {
        if !session.is_null() {
            // SAFETY: The caller supplied the same live unique handle used by the failed call.
            unsafe { &mut *session.cast::<FlutterSession>() }
                .runtime
                .poison();
        }
        adapter_failure("native_panic", "native request failed; session invalidated")
    };
    Box::into_raw(Box::new(FlutterResponse(
        output.into_bytes().into_boxed_slice(),
    )))
    .cast()
}

/// Returns the byte length of a response handle.
///
/// # Safety
///
/// `response` must be null or a live response handle returned by this library.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub unsafe extern "C" fn aonw_flutter_response_len(response: *const core::ffi::c_void) -> usize {
    if response.is_null() {
        return 0;
    }
    // SAFETY: The caller passes a live response handle returned by session_request.
    unsafe { (&*response.cast::<FlutterResponse>()).0.len() }
}

/// Returns borrowed response bytes valid until [`aonw_flutter_response_free`].
///
/// # Safety
///
/// `response` must be null or a live response handle returned by this library.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub unsafe extern "C" fn aonw_flutter_response_data(
    response: *const core::ffi::c_void,
) -> *const u8 {
    if response.is_null() {
        return core::ptr::null();
    }
    // SAFETY: The caller passes a live response handle returned by session_request.
    unsafe { (&*response.cast::<FlutterResponse>()).0.as_ptr() }
}

/// Releases a response previously returned by [`aonw_flutter_session_request`].
///
/// # Safety
///
/// `response` must be null or a live handle returned by this library and not
/// released previously.
#[allow(unsafe_code)]
#[unsafe(no_mangle)]
pub unsafe extern "C" fn aonw_flutter_response_free(response: *mut core::ffi::c_void) {
    if !response.is_null() {
        // SAFETY: The caller transfers a live response handle exactly once.
        drop(unsafe { Box::from_raw(response.cast::<FlutterResponse>()) });
    }
}

fn adapter_failure(code: &str, message: &str) -> String {
    format!(
        r#"{{"apiVersion":{CLIENT_API_VERSION},"outcome":{{"status":"failure","error":{{"code":"{code}","message":"{message}"}}}}}}"#
    )
}

#[cfg(test)]
mod tests {
    use aonw_contracts::client::{
        CLIENT_API_VERSION, ClientOutcomeDto, ClientResponseBodyDto, ClientResponseDto,
    };

    use super::{
        aonw_flutter_build_identity_data, aonw_flutter_build_identity_len,
        aonw_flutter_response_data, aonw_flutter_response_free, aonw_flutter_response_len,
        aonw_flutter_session_free, aonw_flutter_session_new, aonw_flutter_session_request,
    };

    #[test]
    #[allow(unsafe_code)]
    fn c_abi_exposes_the_adapter_build_identity() {
        // SAFETY: The adapter returns immutable bytes with static lifetime.
        let identity = unsafe {
            core::slice::from_raw_parts(
                aonw_flutter_build_identity_data(),
                aonw_flutter_build_identity_len(),
            )
        };
        assert_eq!(identity, b"aonw_flutter/0.1.0");
    }

    #[test]
    #[allow(unsafe_code)]
    fn c_abi_dispatches_the_shared_client_protocol() {
        let request =
            format!(r#"{{"apiVersion":{CLIENT_API_VERSION},"request":{{"type":"capabilities"}}}}"#);
        let session = aonw_flutter_session_new();
        // SAFETY: This test owns every handle and preserves the request buffer for the call.
        let response =
            unsafe { aonw_flutter_session_request(session, request.as_ptr(), request.len()) };
        // SAFETY: The response is live until it is released below.
        let bytes = unsafe {
            core::slice::from_raw_parts(
                aonw_flutter_response_data(response),
                aonw_flutter_response_len(response),
            )
        };
        let decoded = ClientResponseDto::from_json(core::str::from_utf8(bytes).expect("UTF-8"))
            .expect("response");
        assert!(matches!(
            decoded.outcome,
            ClientOutcomeDto::Success {
                response
            } if matches!(*response, ClientResponseBodyDto::Capabilities { .. })
        ));
        // SAFETY: Both handles are released exactly once after their final use.
        unsafe {
            aonw_flutter_response_free(response);
            aonw_flutter_session_free(session);
        }
    }

    #[test]
    #[allow(unsafe_code)]
    fn c_abi_accepts_a_null_pointer_only_for_empty_input() {
        let session = aonw_flutter_session_new();
        // SAFETY: A null request is valid when its declared length is zero.
        let response = unsafe { aonw_flutter_session_request(session, core::ptr::null(), 0) };
        // SAFETY: The response is live until both handles are released below.
        let bytes = unsafe {
            core::slice::from_raw_parts(
                aonw_flutter_response_data(response),
                aonw_flutter_response_len(response),
            )
        };
        let decoded = ClientResponseDto::from_json(core::str::from_utf8(bytes).expect("UTF-8"))
            .expect("response");
        assert!(matches!(decoded.outcome, ClientOutcomeDto::Failure { .. }));
        // SAFETY: Both handles are released exactly once after their final use.
        unsafe {
            aonw_flutter_response_free(response);
            aonw_flutter_session_free(session);
        }
    }
}
