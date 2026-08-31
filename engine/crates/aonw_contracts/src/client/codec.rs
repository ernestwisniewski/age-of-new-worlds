use serde::{Serialize, de::DeserializeOwned};

use super::{CLIENT_API_VERSION, ClientRequestDto, ClientResponseDto};

/// Maximum encoded request accepted by a native adapter.
pub const MAX_CLIENT_REQUEST_JSON_BYTES: usize = 128 * 1024 * 1024;
/// Maximum encoded response produced by a native adapter.
pub const MAX_CLIENT_RESPONSE_JSON_BYTES: usize = 128 * 1024 * 1024;

/// Strict client protocol codec failure.
#[derive(Debug)]
pub enum ClientCodecError {
    /// Input or output exceeds its byte boundary.
    TooLarge {
        /// Actual encoded bytes.
        actual: usize,
        /// Maximum accepted bytes.
        maximum: usize,
    },
    /// Protocol version is not implemented by this build.
    UnsupportedVersion {
        /// Version found at the boundary.
        found: u16,
        /// Only accepted version.
        supported: u16,
    },
    /// JSON violates the strict protocol contract.
    Json(serde_json::Error),
}

impl core::fmt::Display for ClientCodecError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::TooLarge { actual, maximum } => {
                write!(
                    formatter,
                    "client document is {actual} bytes; maximum is {maximum}"
                )
            }
            Self::UnsupportedVersion { found, supported } => write!(
                formatter,
                "unsupported client API version {found}; expected {supported}"
            ),
            Self::Json(source) => source.fmt(formatter),
        }
    }
}

impl std::error::Error for ClientCodecError {}

impl ClientRequestDto {
    /// Parses a bounded, strict client request.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized, malformed, or foreign-version input.
    pub fn from_json(input: &str) -> Result<Self, ClientCodecError> {
        let request: Self = parse_bounded(input, MAX_CLIENT_REQUEST_JSON_BYTES)?;
        require_supported_version(request.api_version)?;
        Ok(request)
    }

    /// Serializes a bounded client request.
    ///
    /// # Errors
    ///
    /// Returns an error for a foreign version or oversized output.
    pub fn to_json(&self) -> Result<String, ClientCodecError> {
        require_supported_version(self.api_version)?;
        serialize_bounded(self, MAX_CLIENT_REQUEST_JSON_BYTES)
    }
}

impl ClientResponseDto {
    /// Parses a bounded, strict client response.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized, malformed, or foreign-version input.
    pub fn from_json(input: &str) -> Result<Self, ClientCodecError> {
        let response: Self = parse_bounded(input, MAX_CLIENT_RESPONSE_JSON_BYTES)?;
        require_supported_version(response.api_version)?;
        Ok(response)
    }

    /// Serializes a bounded client response.
    ///
    /// # Errors
    ///
    /// Returns an error for a foreign version or oversized output.
    pub fn to_json(&self) -> Result<String, ClientCodecError> {
        require_supported_version(self.api_version)?;
        serialize_bounded(self, MAX_CLIENT_RESPONSE_JSON_BYTES)
    }
}

fn require_supported_version(version: u16) -> Result<(), ClientCodecError> {
    if version == CLIENT_API_VERSION {
        Ok(())
    } else {
        Err(ClientCodecError::UnsupportedVersion {
            found: version,
            supported: CLIENT_API_VERSION,
        })
    }
}

fn parse_bounded<T>(input: &str, maximum: usize) -> Result<T, ClientCodecError>
where
    T: DeserializeOwned,
{
    if input.len() > maximum {
        return Err(ClientCodecError::TooLarge {
            actual: input.len(),
            maximum,
        });
    }
    serde_json::from_str(input).map_err(ClientCodecError::Json)
}

fn serialize_bounded<T>(value: &T, maximum: usize) -> Result<String, ClientCodecError>
where
    T: Serialize,
{
    let output = serde_json::to_string(value).map_err(ClientCodecError::Json)?;
    if output.len() > maximum {
        return Err(ClientCodecError::TooLarge {
            actual: output.len(),
            maximum,
        });
    }
    Ok(output)
}

#[cfg(test)]
mod tests {
    use super::{ClientCodecError, parse_bounded, serialize_bounded};

    #[test]
    fn byte_limits_apply_before_and_after_json_work() {
        assert!(matches!(
            parse_bounded::<serde_json::Value>("{}", 1),
            Err(ClientCodecError::TooLarge {
                actual: 2,
                maximum: 1
            })
        ));
        assert!(matches!(
            serialize_bounded(&"long", 3),
            Err(ClientCodecError::TooLarge { maximum: 3, .. })
        ));
    }
}
