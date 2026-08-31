use serde::{Deserialize, Serialize};

use super::{
    MAX_REPLAY_ENTRY_COUNT, MAX_REPLAY_LOG_JSON_BYTES, MAX_REPLAY_SEGMENT_COUNT,
    MAX_SAVE_GAME_JSON_BYTES, PERSISTENCE_FORMAT_VERSION, PersistenceCodecError, ReplayLogDto,
    SaveGameDto,
};

impl SaveGameDto {
    /// Parses a bounded strict save document.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized or structurally invalid input.
    pub fn from_json(input: &str) -> Result<Self, PersistenceCodecError> {
        let save: Self = parse_bounded(input, MAX_SAVE_GAME_JSON_BYTES)?;
        validate_format_version(save.format_version)?;
        Ok(save)
    }

    /// Serializes compact save JSON.
    ///
    /// # Errors
    ///
    /// Returns an error if serialization fails.
    pub fn to_json(&self) -> Result<String, PersistenceCodecError> {
        validate_format_version(self.format_version)?;
        serialize_bounded(self, MAX_SAVE_GAME_JSON_BYTES)
    }
}

impl ReplayLogDto {
    /// Parses a bounded strict replay document.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized, structurally invalid, or unbounded input.
    pub fn from_json(input: &str) -> Result<Self, PersistenceCodecError> {
        let replay: Self = parse_bounded(input, MAX_REPLAY_LOG_JSON_BYTES)?;
        validate_format_version(replay.format_version)?;
        replay.validate_bounds()?;
        Ok(replay)
    }

    /// Serializes compact replay JSON.
    ///
    /// # Errors
    ///
    /// Returns an error if serialization fails.
    pub fn to_json(&self) -> Result<String, PersistenceCodecError> {
        validate_format_version(self.format_version)?;
        self.validate_bounds()?;
        serialize_bounded(self, MAX_REPLAY_LOG_JSON_BYTES)
    }

    fn validate_bounds(&self) -> Result<(), PersistenceCodecError> {
        if self.segments.is_empty() {
            return Err(PersistenceCodecError::EmptyReplayArchive);
        }
        if self.segments.len() > MAX_REPLAY_SEGMENT_COUNT {
            return Err(PersistenceCodecError::TooManyReplaySegments {
                actual: self.segments.len(),
                maximum: MAX_REPLAY_SEGMENT_COUNT,
            });
        }
        for segment in &self.segments {
            if segment.entries.len() > MAX_REPLAY_ENTRY_COUNT {
                return Err(PersistenceCodecError::TooManyReplayEntries {
                    actual: segment.entries.len(),
                    maximum: MAX_REPLAY_ENTRY_COUNT,
                });
            }
        }
        Ok(())
    }
}

fn parse_bounded<T>(input: &str, maximum: usize) -> Result<T, PersistenceCodecError>
where
    T: for<'input> Deserialize<'input>,
{
    if input.len() > maximum {
        return Err(PersistenceCodecError::TooLarge {
            actual: input.len(),
            maximum,
        });
    }
    serde_json::from_str(input).map_err(PersistenceCodecError::Json)
}

fn serialize_bounded<T>(value: &T, maximum: usize) -> Result<String, PersistenceCodecError>
where
    T: Serialize,
{
    let mut output = BoundedWriter::new(maximum);
    let serialized = serde_json::to_writer(&mut output, value);
    if output.overflowed {
        return Err(PersistenceCodecError::TooLarge {
            actual: maximum.saturating_add(1),
            maximum,
        });
    }
    serialized.map_err(PersistenceCodecError::Json)?;
    String::from_utf8(output.bytes).map_err(|error| {
        PersistenceCodecError::Json(serde_json::Error::io(std::io::Error::new(
            std::io::ErrorKind::InvalidData,
            error,
        )))
    })
}

fn validate_format_version(found: u16) -> Result<(), PersistenceCodecError> {
    if found == PERSISTENCE_FORMAT_VERSION {
        Ok(())
    } else {
        Err(PersistenceCodecError::UnsupportedFormatVersion {
            found,
            supported: PERSISTENCE_FORMAT_VERSION,
        })
    }
}

struct BoundedWriter {
    bytes: Vec<u8>,
    maximum: usize,
    overflowed: bool,
}

impl BoundedWriter {
    fn new(maximum: usize) -> Self {
        Self {
            bytes: Vec::with_capacity(maximum.min(1024 * 1024)),
            maximum,
            overflowed: false,
        }
    }
}

impl std::io::Write for BoundedWriter {
    fn write(&mut self, buffer: &[u8]) -> std::io::Result<usize> {
        let Some(next_len) = self.bytes.len().checked_add(buffer.len()) else {
            self.overflowed = true;
            return Err(std::io::Error::other("persistence size overflow"));
        };
        if next_len > self.maximum {
            self.overflowed = true;
            return Err(std::io::Error::other("persistence size limit exceeded"));
        }
        self.bytes.extend_from_slice(buffer);
        Ok(buffer.len())
    }

    fn flush(&mut self) -> std::io::Result<()> {
        Ok(())
    }
}
