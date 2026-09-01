#![no_main]

use aonw_contracts::client::ClientResponseDto;
use aonw_flutter::{
    aonw_flutter_response_data, aonw_flutter_response_free, aonw_flutter_response_len,
    aonw_flutter_session_free, aonw_flutter_session_new, aonw_flutter_session_request,
};
use libfuzzer_sys::fuzz_target;

const CAPABILITIES: &[u8] = br#"{"apiVersion":9,"request":{"type":"capabilities"}}"#;

fuzz_target!(|data: &[u8]| {
    let request = if data.is_empty() { CAPABILITIES } else { data };
    let session = aonw_flutter_session_new();
    assert!(!session.is_null());
    let request_pointer = if request.is_empty() {
        core::ptr::null()
    } else {
        request.as_ptr()
    };
    // SAFETY: The session is live and uniquely owned; request points to its exact readable slice.
    let response = unsafe { aonw_flutter_session_request(session, request_pointer, request.len()) };
    assert!(!response.is_null());
    // SAFETY: The response handle remains live for both borrowed accessors.
    let response_len = unsafe { aonw_flutter_response_len(response) };
    // SAFETY: The adapter owns response_len readable bytes until response_free below.
    let response_bytes =
        unsafe { core::slice::from_raw_parts(aonw_flutter_response_data(response), response_len) };
    let response_json = core::str::from_utf8(response_bytes).expect("adapter response UTF-8");
    ClientResponseDto::from_json(response_json).expect("strict current adapter response");
    // SAFETY: Both live handles are released exactly once after their final access.
    unsafe {
        aonw_flutter_response_free(response);
        aonw_flutter_session_free(session);
    }
});
