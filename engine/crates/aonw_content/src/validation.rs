const MAX_CONTENT_ID_BYTES: usize = 64;

/// Domain invariant violation raised while constructing logical map content.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MapValidationError {
    pub(crate) path: Box<str>,
    pub(crate) message: Box<str>,
}

impl MapValidationError {
    pub(super) fn new(path: impl Into<Box<str>>, message: impl Into<Box<str>>) -> Self {
        Self {
            path: path.into(),
            message: message.into(),
        }
    }

    /// Returns the logical field path that violated an invariant.
    #[must_use]
    pub fn path(&self) -> &str {
        &self.path
    }

    /// Returns the validation failure description.
    #[must_use]
    pub fn message(&self) -> &str {
        &self.message
    }
}

impl core::fmt::Display for MapValidationError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        write!(formatter, "{}: {}", self.path, self.message)
    }
}

impl std::error::Error for MapValidationError {}

pub(super) fn validate_content_id(path: &str, value: &str) -> Result<(), MapValidationError> {
    let bytes = value.as_bytes();
    let is_alphanumeric = |byte: u8| byte.is_ascii_lowercase() || byte.is_ascii_digit();
    let valid = !bytes.is_empty()
        && bytes.len() <= MAX_CONTENT_ID_BYTES
        && bytes.first().copied().is_some_and(is_alphanumeric)
        && bytes.last().copied().is_some_and(is_alphanumeric)
        && bytes
            .iter()
            .copied()
            .all(|byte| is_alphanumeric(byte) || byte == b'_' || byte == b'-');
    if valid {
        return Ok(());
    }
    Err(MapValidationError::new(
        path,
        "must be 1-64 lowercase ASCII letters, digits, underscores, or hyphens and start and end alphanumerically",
    ))
}

/// Validates a logical map identifier without constructing a complete map.
///
/// This is used by authoring specifications before potentially expensive map
/// generation. [`crate::MapDefinition`] applies the same invariant again when
/// the canonical aggregate is constructed.
///
/// # Errors
///
/// Returns [`MapValidationError`] when the identifier is not canonical.
pub fn validate_map_id(value: &str) -> Result<(), MapValidationError> {
    validate_content_id("$.mapName", value)
}
