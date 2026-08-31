use core::fmt;

const MAX_IDENTIFIER_BYTES: usize = 128;

/// Failure raised while constructing an opaque domain identifier.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum IdentifierError {
    /// The identifier was empty or contained only whitespace.
    Empty,
    /// The UTF-8 representation exceeded the supported boundary limit.
    TooLong {
        /// Actual byte length.
        actual: usize,
        /// Maximum accepted byte length.
        maximum: usize,
    },
}

impl fmt::Display for IdentifierError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Empty => formatter.write_str("identifier must not be empty"),
            Self::TooLong { actual, maximum } => write!(
                formatter,
                "identifier is {actual} bytes; maximum is {maximum} bytes"
            ),
        }
    }
}

impl std::error::Error for IdentifierError {}

/// Opaque player identifier.
///
/// A boxed string keeps the value immutable and one allocation wide.
#[derive(Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub struct PlayerId(Box<str>);

impl PlayerId {
    /// Validates and constructs a player identifier.
    ///
    /// # Errors
    ///
    /// Returns [`IdentifierError`] when the value is empty or exceeds the
    /// boundary length limit.
    pub fn new(value: impl Into<Box<str>>) -> Result<Self, IdentifierError> {
        validate(value.into()).map(Self)
    }

    /// Returns the stable textual representation.
    #[must_use]
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for PlayerId {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(self.as_str())
    }
}

/// Opaque unit identifier.
#[derive(Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub struct UnitId(Box<str>);

impl UnitId {
    /// Validates and constructs a unit identifier.
    ///
    /// # Errors
    ///
    /// Returns [`IdentifierError`] when the value is empty or exceeds the
    /// boundary length limit.
    pub fn new(value: impl Into<Box<str>>) -> Result<Self, IdentifierError> {
        validate(value.into()).map(Self)
    }

    /// Returns the stable textual representation.
    #[must_use]
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for UnitId {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(self.as_str())
    }
}

/// Opaque artifact identifier.
#[derive(Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub struct ArtifactId(Box<str>);

impl ArtifactId {
    /// Validates and constructs an artifact identifier.
    ///
    /// # Errors
    ///
    /// Returns [`IdentifierError`] when the value is empty or exceeds the
    /// boundary length limit.
    pub fn new(value: impl Into<Box<str>>) -> Result<Self, IdentifierError> {
        validate(value.into()).map(Self)
    }

    /// Returns the stable textual representation.
    #[must_use]
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for ArtifactId {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(self.as_str())
    }
}

/// Opaque city identifier.
#[derive(Clone, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub struct CityId(Box<str>);

impl CityId {
    /// Validates and constructs a city identifier.
    ///
    /// # Errors
    ///
    /// Returns [`IdentifierError`] when the value is empty or exceeds the
    /// boundary length limit.
    pub fn new(value: impl Into<Box<str>>) -> Result<Self, IdentifierError> {
        validate(value.into()).map(Self)
    }

    /// Returns the stable textual representation.
    #[must_use]
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for CityId {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(self.as_str())
    }
}

fn validate(value: Box<str>) -> Result<Box<str>, IdentifierError> {
    if value.trim().is_empty() {
        return Err(IdentifierError::Empty);
    }
    if value.len() > MAX_IDENTIFIER_BYTES {
        return Err(IdentifierError::TooLong {
            actual: value.len(),
            maximum: MAX_IDENTIFIER_BYTES,
        });
    }
    Ok(value)
}

#[cfg(test)]
mod tests {
    use super::{ArtifactId, IdentifierError, PlayerId, UnitId};

    #[test]
    fn identifiers_preserve_their_opaque_value() {
        let player = PlayerId::new("player-one").expect("valid player id");
        let unit = UnitId::new("unit/scout/7").expect("valid unit id");
        let artifact = ArtifactId::new("artifact-3").expect("valid artifact id");

        assert_eq!(player.as_str(), "player-one");
        assert_eq!(unit.as_str(), "unit/scout/7");
        assert_eq!(artifact.as_str(), "artifact-3");
    }

    #[test]
    fn identifiers_reject_whitespace_only_values() {
        assert_eq!(PlayerId::new(" \t "), Err(IdentifierError::Empty));
    }
}
