use super::NativeResponse;
use aonw_contracts::server::{
    SERVER_HOST_API_VERSION, ServerHostCodecError, ServerHostErrorCodeDto, ServerHostErrorDto,
    ServerHostOutcomeDto, ServerHostResponseBodyDto, ServerHostResponseDto,
};
use aonw_server_runtime::ServerBoundaryError;
use std::panic::{AssertUnwindSafe, catch_unwind};

pub(super) fn contain(
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

pub(super) fn codec_error(error: &ServerHostCodecError) -> ServerHostResponseDto {
    let code = match error {
        ServerHostCodecError::TooLarge { .. } => ServerHostErrorCodeDto::PayloadTooLarge,
        ServerHostCodecError::Json(_) => ServerHostErrorCodeDto::InvalidRequest,
    };
    failure(code, error.to_string())
}

pub(super) fn boundary_error(error: &ServerBoundaryError) -> ServerHostResponseDto {
    failure(error.code(), error.to_string())
}

pub(super) fn success(body: ServerHostResponseBodyDto) -> Result<String, ServerHostResponseDto> {
    ServerHostResponseDto {
        api_version: SERVER_HOST_API_VERSION,
        outcome: ServerHostOutcomeDto::Success {
            response: Box::new(body),
        },
    }
    .to_json()
    .map_err(|error| failure(ServerHostErrorCodeDto::ResponseTooLarge, error.to_string()))
}

pub(super) fn failure(
    code: ServerHostErrorCodeDto,
    message: impl Into<String>,
) -> ServerHostResponseDto {
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

pub(super) fn serialize_failure(response: &ServerHostResponseDto) -> Box<[u8]> {
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
