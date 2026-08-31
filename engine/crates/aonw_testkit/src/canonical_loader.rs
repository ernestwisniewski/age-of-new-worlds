use std::collections::BTreeSet;
use std::fs::{self, File};
use std::io::Read;
use std::path::Path;

use crate::FixtureLoadError;
use crate::canonical_fixture::CanonicalFixture;
use crate::canonical_fixture_parser::parse_canonical_fixture;
use crate::unique_json::UniqueJson;

/// Default maximum size of one fixture: one MiB.
const DEFAULT_MAX_FIXTURE_BYTES: usize = 1024 * 1024;
/// Default maximum corpus size: 64 MiB.
const DEFAULT_MAX_CORPUS_BYTES: usize = 64 * 1024 * 1024;
/// Default maximum number of fixture files.
const DEFAULT_MAX_CORPUS_FIXTURES: usize = 2048;

/// Resource limits applied before and during canonical fixture loading.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct FixtureLimits {
    /// Maximum bytes accepted for one JSON fixture.
    pub max_fixture_bytes: usize,
    /// Maximum aggregate bytes accepted for one corpus.
    pub max_corpus_bytes: usize,
    /// Maximum JSON fixture count accepted for one corpus.
    pub max_corpus_fixtures: usize,
}

impl Default for FixtureLimits {
    fn default() -> Self {
        Self {
            max_fixture_bytes: DEFAULT_MAX_FIXTURE_BYTES,
            max_corpus_bytes: DEFAULT_MAX_CORPUS_BYTES,
            max_corpus_fixtures: DEFAULT_MAX_CORPUS_FIXTURES,
        }
    }
}

/// Bounded loader for canonical fixtures and corpora.
#[derive(Clone, Copy, Debug, Default)]
pub struct CanonicalFixtureLoader {
    limits: FixtureLimits,
}

impl CanonicalFixtureLoader {
    /// Constructs a loader with explicit shared resource limits.
    #[must_use]
    pub const fn new(limits: FixtureLimits) -> Self {
        Self { limits }
    }

    /// Parses one in-memory canonical fixture.
    ///
    /// # Errors
    ///
    /// Returns [`FixtureLoadError`] for size, syntax, version, map, DTO, or
    /// structural contract violations.
    pub fn parse(self, source: &[u8]) -> Result<CanonicalFixture, FixtureLoadError> {
        self.parse_with_path(source, None)
    }

    /// Loads one fixture and verifies that its id matches the filename.
    ///
    /// # Errors
    ///
    /// Returns [`FixtureLoadError`] for I/O, limits, structure, or filename mismatch.
    pub fn load_file(self, path: impl AsRef<Path>) -> Result<CanonicalFixture, FixtureLoadError> {
        let path = path.as_ref();
        let source = read_bounded(path, self.limits.max_fixture_bytes)?;
        self.parse_file_source(path, &source)
    }

    /// Loads a sorted non-empty corpus of uniquely identified fixtures.
    ///
    /// `README.md` is the only permitted non-JSON entry.
    ///
    /// # Errors
    ///
    /// Returns [`FixtureLoadError`] for I/O, limits, unexpected entries,
    /// duplicate ids, or an invalid fixture.
    pub fn load_corpus(
        self,
        directory: impl AsRef<Path>,
    ) -> Result<Vec<CanonicalFixture>, FixtureLoadError> {
        let directory = directory.as_ref();
        let mut files = Vec::new();
        let entries = fs::read_dir(directory).map_err(|source| FixtureLoadError::Io {
            path: directory.to_path_buf(),
            source,
        })?;
        for entry in entries {
            let entry = entry.map_err(|source| FixtureLoadError::Io {
                path: directory.to_path_buf(),
                source,
            })?;
            let path = entry.path();
            let file_type = entry.file_type().map_err(|source| FixtureLoadError::Io {
                path: path.clone(),
                source,
            })?;
            if file_type.is_file() && path.extension().is_some_and(|value| value == "json") {
                files.push(path);
            } else if !(file_type.is_file() && entry.file_name() == "README.md") {
                return Err(FixtureLoadError::UnexpectedCorpusEntry { path });
            }
        }
        files.sort_unstable();
        if files.is_empty() {
            return Err(FixtureLoadError::EmptyCorpus {
                path: directory.to_path_buf(),
            });
        }
        if files.len() > self.limits.max_corpus_fixtures {
            return Err(FixtureLoadError::TooManyFixtures {
                path: directory.to_path_buf(),
                actual: files.len(),
                limit: self.limits.max_corpus_fixtures,
            });
        }

        let mut total_bytes = 0_usize;
        let mut fixtures = Vec::with_capacity(files.len());
        let mut ids = BTreeSet::new();
        for path in files {
            let remaining = self.limits.max_corpus_bytes.saturating_sub(total_bytes);
            let read_limit = self.limits.max_fixture_bytes.min(remaining);
            let source = match read_bounded(&path, read_limit) {
                Ok(source) => source,
                Err(FixtureLoadError::FixtureTooLarge { actual, .. })
                    if read_limit == remaining && remaining < self.limits.max_fixture_bytes =>
                {
                    return Err(FixtureLoadError::CorpusTooLarge {
                        path: directory.to_path_buf(),
                        actual: total_bytes.saturating_add(actual),
                        limit: self.limits.max_corpus_bytes,
                    });
                }
                Err(error) => return Err(error),
            };
            total_bytes += source.len();
            let fixture = self.parse_file_source(&path, &source)?;
            if !ids.insert(fixture.id().to_owned()) {
                return Err(FixtureLoadError::DuplicateFixtureId {
                    fixture_id: fixture.id,
                });
            }
            fixtures.push(fixture);
        }
        Ok(fixtures)
    }

    fn parse_with_path(
        self,
        source: &[u8],
        path: Option<&Path>,
    ) -> Result<CanonicalFixture, FixtureLoadError> {
        if source.len() > self.limits.max_fixture_bytes {
            return Err(FixtureLoadError::FixtureTooLarge {
                path: path.map(Path::to_path_buf),
                actual: source.len(),
                limit: self.limits.max_fixture_bytes,
            });
        }
        let UniqueJson(value) =
            serde_json::from_slice(source).map_err(|source| FixtureLoadError::Json {
                path: path.map(Path::to_path_buf),
                source,
            })?;
        parse_canonical_fixture(value, path)
    }

    fn parse_file_source(
        self,
        path: &Path,
        source: &[u8],
    ) -> Result<CanonicalFixture, FixtureLoadError> {
        let fixture = self.parse_with_path(source, Some(path))?;
        if path.file_stem().and_then(|value| value.to_str()) != Some(fixture.id()) {
            return Err(FixtureLoadError::FilenameMismatch {
                path: path.to_path_buf(),
                fixture_id: fixture.id,
            });
        }
        Ok(fixture)
    }
}

fn read_bounded(path: &Path, limit: usize) -> Result<Vec<u8>, FixtureLoadError> {
    let file = File::open(path).map_err(|source| FixtureLoadError::Io {
        path: path.to_path_buf(),
        source,
    })?;
    let read_limit = u64::try_from(limit).unwrap_or(u64::MAX).saturating_add(1);
    let mut reader = file.take(read_limit);
    let mut source = Vec::with_capacity(limit.min(64 * 1024));
    reader
        .read_to_end(&mut source)
        .map_err(|source| FixtureLoadError::Io {
            path: path.to_path_buf(),
            source,
        })?;
    if source.len() > limit {
        return Err(FixtureLoadError::FixtureTooLarge {
            path: Some(path.to_path_buf()),
            actual: source.len(),
            limit,
        });
    }
    Ok(source)
}
