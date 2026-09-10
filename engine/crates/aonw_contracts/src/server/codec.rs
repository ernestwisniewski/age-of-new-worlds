use serde::Deserialize;

use super::{
    CreateServerMatchRequestDto, MAX_SERVER_HOST_REQUEST_JSON_BYTES,
    MAX_SERVER_HOST_RESPONSE_JSON_BYTES, PlayerCommandServerRequestDto,
    PlayerQueryServerRequestDto, PrepareServerWorldRequestDto, ProjectServerStateRequestDto,
    ServerHostResponseDto, SubmitTurnServerRequestDto, SystemCommandServerRequestDto,
};

impl PrepareServerWorldRequestDto {
    /// Parses one bounded strict request.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized or structurally invalid JSON.
    pub fn from_json(input: &str) -> Result<Self, ServerHostCodecError> {
        parse_bounded(input)
    }
}

impl SubmitTurnServerRequestDto {
    /// Parses one bounded strict request.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized or structurally invalid JSON.
    pub fn from_json(input: &str) -> Result<Self, ServerHostCodecError> {
        parse_bounded(input)
    }
}

impl PlayerCommandServerRequestDto {
    /// Parses one bounded strict request.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized or structurally invalid JSON.
    pub fn from_json(input: &str) -> Result<Self, ServerHostCodecError> {
        parse_bounded(input)
    }
}

impl SystemCommandServerRequestDto {
    /// Parses one bounded strict request.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized or structurally invalid JSON.
    pub fn from_json(input: &str) -> Result<Self, ServerHostCodecError> {
        parse_bounded(input)
    }
}

impl PlayerQueryServerRequestDto {
    /// Parses one bounded strict request.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized or structurally invalid JSON.
    pub fn from_json(input: &str) -> Result<Self, ServerHostCodecError> {
        parse_bounded(input)
    }
}

impl ProjectServerStateRequestDto {
    /// Parses one bounded strict request.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized or structurally invalid JSON.
    pub fn from_json(input: &str) -> Result<Self, ServerHostCodecError> {
        parse_bounded(input)
    }
}

impl CreateServerMatchRequestDto {
    /// Parses one bounded strict request.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized or structurally invalid JSON.
    pub fn from_json(input: &str) -> Result<Self, ServerHostCodecError> {
        parse_bounded(input)
    }
}

impl ServerHostResponseDto {
    /// Serializes one bounded compact response.
    ///
    /// # Errors
    ///
    /// Returns an error if serialization fails or exceeds the response bound.
    pub fn to_json(&self) -> Result<String, ServerHostCodecError> {
        let json = serde_json::to_string(self).map_err(ServerHostCodecError::Json)?;
        if json.len() > MAX_SERVER_HOST_RESPONSE_JSON_BYTES {
            return Err(ServerHostCodecError::TooLarge {
                actual: json.len(),
                maximum: MAX_SERVER_HOST_RESPONSE_JSON_BYTES,
            });
        }
        Ok(json)
    }
}

pub(super) fn parse_bounded<T: for<'de> Deserialize<'de>>(
    input: &str,
) -> Result<T, ServerHostCodecError> {
    if input.len() > MAX_SERVER_HOST_REQUEST_JSON_BYTES {
        return Err(ServerHostCodecError::TooLarge {
            actual: input.len(),
            maximum: MAX_SERVER_HOST_REQUEST_JSON_BYTES,
        });
    }
    serde_json::from_str(input).map_err(ServerHostCodecError::Json)
}

/// Strict native host JSON codec failure.
#[derive(Debug)]
pub enum ServerHostCodecError {
    /// Encoded value exceeded its reviewed byte boundary.
    TooLarge {
        /// Actual byte count.
        actual: usize,
        /// Maximum accepted byte count.
        maximum: usize,
    },
    /// JSON serialization or deserialization failed.
    Json(serde_json::Error),
}

impl core::fmt::Display for ServerHostCodecError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::TooLarge { actual, maximum } => {
                write!(formatter, "payload is {actual} bytes; maximum is {maximum}")
            }
            Self::Json(source) => source.fmt(formatter),
        }
    }
}

impl std::error::Error for ServerHostCodecError {}
