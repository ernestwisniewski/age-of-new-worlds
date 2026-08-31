use std::fmt;
use std::io;
use std::path::{Path, PathBuf};

/// Failure raised while loading or validating a canonical fixture.
#[allow(missing_docs)]
#[derive(Debug)]
pub enum FixtureLoadError {
    /// Filesystem access failed.
    Io { path: PathBuf, source: io::Error },
    /// JSON syntax or numeric representation is invalid.
    Json {
        path: Option<PathBuf>,
        source: serde_json::Error,
    },
    /// A fixture is larger than the configured limit.
    FixtureTooLarge {
        path: Option<PathBuf>,
        actual: usize,
        limit: usize,
    },
    /// Aggregate fixture bytes exceed the corpus limit.
    CorpusTooLarge {
        path: PathBuf,
        actual: usize,
        limit: usize,
    },
    /// The corpus contains too many fixtures.
    TooManyFixtures {
        path: PathBuf,
        actual: usize,
        limit: usize,
    },
    /// Fixture structure violates the versioned contract.
    Invalid {
        path: Option<PathBuf>,
        field: Box<str>,
        message: Box<str>,
    },
    /// The fixture version is not supported by this testkit build.
    UnsupportedVersion {
        path: Option<PathBuf>,
        found: u64,
        supported: u64,
    },
    /// Fixture filename does not match its identifier.
    FilenameMismatch { path: PathBuf, fixture_id: Box<str> },
    /// The corpus contains an entry other than JSON fixtures and its README.
    UnexpectedCorpusEntry { path: PathBuf },
    /// No JSON fixture exists in the corpus.
    EmptyCorpus { path: PathBuf },
    /// Two corpus fixtures declare the same identifier.
    DuplicateFixtureId { fixture_id: Box<str> },
}

impl fmt::Display for FixtureLoadError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Io { path, source } => write!(formatter, "{}: {source}", path.display()),
            Self::Json { path, source } => write_source(formatter, path.as_deref(), source),
            Self::FixtureTooLarge {
                path,
                actual,
                limit,
            } => write!(
                formatter,
                "{}fixture has {actual} bytes; limit is {limit}",
                path_prefix(path.as_deref())
            ),
            Self::CorpusTooLarge {
                path,
                actual,
                limit,
            } => write!(
                formatter,
                "{}: corpus has {actual} bytes; limit is {limit}",
                path.display()
            ),
            Self::TooManyFixtures {
                path,
                actual,
                limit,
            } => write!(
                formatter,
                "{}: corpus has {actual} fixtures; limit is {limit}",
                path.display()
            ),
            Self::Invalid {
                path,
                field,
                message,
            } => {
                write!(
                    formatter,
                    "{}{field}: {message}",
                    path_prefix(path.as_deref())
                )
            }
            Self::UnsupportedVersion {
                path,
                found,
                supported,
            } => write!(
                formatter,
                "{}unsupported fixture version {found}; supported version is {supported}",
                path_prefix(path.as_deref())
            ),
            Self::FilenameMismatch { path, fixture_id } => write!(
                formatter,
                "{}: fixture id {fixture_id:?} must match its filename",
                path.display()
            ),
            Self::UnexpectedCorpusEntry { path } => {
                write!(formatter, "unexpected corpus entry: {}", path.display())
            }
            Self::EmptyCorpus { path } => {
                write!(formatter, "fixture corpus is empty: {}", path.display())
            }
            Self::DuplicateFixtureId { fixture_id } => {
                write!(formatter, "duplicate fixture id: {fixture_id}")
            }
        }
    }
}

impl std::error::Error for FixtureLoadError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::Io { source, .. } => Some(source),
            Self::Json { source, .. } => Some(source),
            _ => None,
        }
    }
}

fn path_prefix(path: Option<&Path>) -> String {
    path.map_or_else(String::new, |path| format!("{}: ", path.display()))
}

fn write_source(
    formatter: &mut fmt::Formatter<'_>,
    path: Option<&Path>,
    source: &dyn fmt::Display,
) -> fmt::Result {
    write!(formatter, "{}{source}", path_prefix(path))
}
