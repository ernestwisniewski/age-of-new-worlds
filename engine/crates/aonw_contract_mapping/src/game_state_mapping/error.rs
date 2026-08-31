/// Failure raised while mapping the canonical game-state contract.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct GameStateMappingError {
    path: Box<str>,
    message: Box<str>,
}

impl GameStateMappingError {
    pub(super) fn new(path: impl Into<Box<str>>, message: impl Into<Box<str>>) -> Self {
        Self {
            path: path.into(),
            message: message.into(),
        }
    }

    /// Returns the contract path that failed validation.
    #[must_use]
    pub fn path(&self) -> &str {
        &self.path
    }
}

impl core::fmt::Display for GameStateMappingError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        write!(formatter, "{}: {}", self.path, self.message)
    }
}

impl std::error::Error for GameStateMappingError {}
