//! Crash-safe save storage for native hosts.

use std::ffi::OsString;
use std::fs::{self, File, OpenOptions};
use std::io::{Read, Write};
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicU64, Ordering};

use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_contracts::{MAX_SAVE_GAME_JSON_BYTES, SaveGameDto};

use crate::{LocalRuntime, PersistenceError, SessionStamp};

static TEMP_SEQUENCE: AtomicU64 = AtomicU64::new(0);

/// Identifies which current-format document restored a session.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum PersistenceRestoreSource {
    /// The primary document passed strict validation.
    Primary,
    /// The primary failed and the last known-good backup was promoted.
    Backup,
}

/// Failure while storing or restoring a native current-format save.
#[derive(Debug)]
pub struct PersistenceFileError {
    message: Box<str>,
}

impl PersistenceFileError {
    fn new(message: impl Into<Box<str>>) -> Self {
        Self {
            message: message.into(),
        }
    }
}

impl core::fmt::Display for PersistenceFileError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        formatter.write_str(&self.message)
    }
}

impl std::error::Error for PersistenceFileError {}

/// Native host storage for one canonical save and one last known-good backup.
///
/// Updates are written and synced in the destination directory before an
/// atomic rename. The store contains only the current canonical save contract;
/// backup is a recovery copy that uses the same save format.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PersistenceFileStore {
    primary: PathBuf,
}

impl PersistenceFileStore {
    /// Creates a store for a concrete save file path.
    #[must_use]
    pub fn new(primary: impl Into<PathBuf>) -> Self {
        Self {
            primary: primary.into(),
        }
    }

    /// Returns the canonical primary save path.
    #[must_use]
    pub fn primary_path(&self) -> &Path {
        &self.primary
    }

    /// Returns the last known-good backup path.
    #[must_use]
    pub fn backup_path(&self) -> PathBuf {
        sibling_path(&self.primary, ".backup")
    }

    /// Atomically stores the open runtime's canonical save.
    ///
    /// A valid prior primary becomes the backup. An invalid prior primary is
    /// discarded only after the replacement is installed, without displacing
    /// an existing known-good backup.
    ///
    /// # Errors
    ///
    /// Returns an error when export, validation, filesystem I/O, installation,
    /// or rollback fails.
    pub fn write_save(&self, runtime: &LocalRuntime) -> Result<(), PersistenceFileError> {
        ensure_file_path(&self.primary)?;
        let payload = runtime
            .export_save_json()
            .map_err(|error| export_error(&error))?;
        SaveGameDto::from_json(&payload)
            .map_err(|error| PersistenceFileError::new(format!("export is invalid: {error}")))?;
        let temp = self.write_synced_temp(payload.as_bytes())?;
        let prior = self.prior_disposition(runtime);
        self.install_temp(&temp, prior)
    }

    /// Restores the save transactionally, falling back to the backup.
    ///
    /// A valid backup is promoted to the primary path before this method
    /// returns. A rejected document never replaces the caller's open session.
    ///
    /// # Errors
    ///
    /// Returns an error when neither save document can be read and
    /// validated, or when backup promotion fails.
    pub fn restore_save(
        &self,
        runtime: &mut LocalRuntime,
        map: MapDefinition,
        ruleset: RulesetDefinition,
    ) -> Result<(SessionStamp, PersistenceRestoreSource), PersistenceFileError> {
        ensure_file_path(&self.primary)?;
        let primary_error = match restore_path(runtime, map.clone(), ruleset.clone(), &self.primary)
        {
            Ok(stamp) => return Ok((stamp, PersistenceRestoreSource::Primary)),
            Err(error) => error,
        };
        let backup = self.backup_path();
        let payload = read_bounded(&backup).map_err(|backup_error| {
            PersistenceFileError::new(format!(
                "primary restore failed ({primary_error}); backup restore failed ({backup_error})"
            ))
        })?;
        let mut probe = LocalRuntime::default();
        probe
            .open_save_json(map.clone(), ruleset.clone(), &payload)
            .map_err(|backup_error| {
                PersistenceFileError::new(format!(
                    "primary restore failed ({primary_error}); backup restore failed ({backup_error})"
                ))
            })?;
        self.promote_backup(payload.as_bytes())?;
        let stamp = runtime
            .open_save_json(map, ruleset, &payload)
            .map_err(|error| {
                PersistenceFileError::new(format!("validated backup reopen failed: {error}"))
            })?;
        Ok((stamp, PersistenceRestoreSource::Backup))
    }

    fn prior_disposition(&self, runtime: &LocalRuntime) -> PriorDisposition {
        if !self.primary.exists() {
            return PriorDisposition::None;
        }
        let Ok(payload) = read_bounded(&self.primary) else {
            return PriorDisposition::Reject;
        };
        let Ok(session) = runtime.session_ref() else {
            return PriorDisposition::Reject;
        };
        let mut probe = LocalRuntime::default();
        if probe
            .open_save_json(session.map().clone(), session.ruleset().clone(), &payload)
            .is_ok()
        {
            PriorDisposition::Backup
        } else {
            PriorDisposition::Reject
        }
    }

    fn write_synced_temp(&self, bytes: &[u8]) -> Result<PathBuf, PersistenceFileError> {
        let temp = sibling_path(
            &self.primary,
            &format!(
                ".tmp.{}.{}",
                std::process::id(),
                TEMP_SEQUENCE.fetch_add(1, Ordering::Relaxed)
            ),
        );
        let mut file = OpenOptions::new()
            .write(true)
            .create_new(true)
            .open(&temp)
            .map_err(|error| io_error("create temporary save", &temp, &error))?;
        if let Err(error) = file.write_all(bytes).and_then(|()| file.sync_all()) {
            let _ = fs::remove_file(&temp);
            return Err(io_error("write temporary save", &temp, &error));
        }
        Ok(temp)
    }

    fn install_temp(
        &self,
        temp: &Path,
        prior: PriorDisposition,
    ) -> Result<(), PersistenceFileError> {
        self.install_temp_using(temp, prior, |source, destination| {
            fs::rename(source, destination)
        })
    }

    fn install_temp_using(
        &self,
        temp: &Path,
        prior: PriorDisposition,
        install: impl FnOnce(&Path, &Path) -> std::io::Result<()>,
    ) -> Result<(), PersistenceFileError> {
        let displaced = match prior {
            PriorDisposition::None => None,
            PriorDisposition::Backup => {
                let backup = self.backup_path();
                remove_if_present(&backup)?;
                displace(&self.primary, &backup)?;
                Some(backup)
            }
            PriorDisposition::Reject => {
                let rejected = sibling_path(&self.primary, ".rejected");
                remove_if_present(&rejected)?;
                displace(&self.primary, &rejected)?;
                Some(rejected)
            }
        };
        if displaced.is_some()
            && let Err(sync_error) = sync_parent(&self.primary)
        {
            let rollback = displaced
                .as_deref()
                .map(|path| fs::rename(path, &self.primary))
                .transpose();
            let _ = fs::remove_file(temp);
            return match rollback {
                Ok(_) => Err(sync_error),
                Err(rollback_error) => Err(PersistenceFileError::new(format!(
                    "sync displaced save failed ({sync_error}); rollback failed ({rollback_error})"
                ))),
            };
        }
        if let Err(install_error) = install(temp, &self.primary) {
            let rollback = displaced
                .as_deref()
                .map(|path| fs::rename(path, &self.primary))
                .transpose();
            let _ = fs::remove_file(temp);
            return match rollback {
                Ok(_) => Err(io_error(
                    "install current save",
                    &self.primary,
                    &install_error,
                )),
                Err(rollback_error) => Err(PersistenceFileError::new(format!(
                    "install current save failed ({install_error}); rollback failed ({rollback_error})"
                ))),
            };
        }
        if prior == PriorDisposition::Reject {
            let _ = remove_if_present(&sibling_path(&self.primary, ".rejected"));
        }
        sync_parent(&self.primary)
    }

    fn promote_backup(&self, bytes: &[u8]) -> Result<(), PersistenceFileError> {
        let temp = self.write_synced_temp(bytes)?;
        let prior = if self.primary.exists() {
            PriorDisposition::Reject
        } else {
            PriorDisposition::None
        };
        self.install_temp(&temp, prior)
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum PriorDisposition {
    None,
    Backup,
    Reject,
}

fn restore_path(
    runtime: &mut LocalRuntime,
    map: MapDefinition,
    ruleset: RulesetDefinition,
    path: &Path,
) -> Result<SessionStamp, PersistenceFileError> {
    let payload = read_bounded(path)?;
    runtime
        .open_save_json(map, ruleset, &payload)
        .map_err(|error| PersistenceFileError::new(format!("{}: {error}", path.display())))
}

fn read_bounded(path: &Path) -> Result<String, PersistenceFileError> {
    let file = File::open(path).map_err(|error| io_error("open save", path, &error))?;
    let limit = u64::try_from(MAX_SAVE_GAME_JSON_BYTES).expect("save limit fits u64");
    let mut bytes = Vec::new();
    file.take(limit + 1)
        .read_to_end(&mut bytes)
        .map_err(|error| io_error("read save", path, &error))?;
    if bytes.len() > MAX_SAVE_GAME_JSON_BYTES {
        return Err(PersistenceFileError::new(format!(
            "{} exceeds the current save byte limit",
            path.display()
        )));
    }
    String::from_utf8(bytes).map_err(|error| {
        PersistenceFileError::new(format!("{} is not UTF-8: {error}", path.display()))
    })
}

fn ensure_file_path(path: &Path) -> Result<(), PersistenceFileError> {
    if path.file_name().is_none() {
        return Err(PersistenceFileError::new("save path must identify a file"));
    }
    let parent = path.parent().unwrap_or_else(|| Path::new("."));
    if !parent.is_dir() {
        return Err(PersistenceFileError::new(format!(
            "save directory does not exist: {}",
            parent.display()
        )));
    }
    Ok(())
}

fn sibling_path(path: &Path, suffix: &str) -> PathBuf {
    let mut name = path
        .file_name()
        .map_or_else(OsString::new, std::ffi::OsStr::to_os_string);
    name.push(suffix);
    path.with_file_name(name)
}

fn remove_if_present(path: &Path) -> Result<(), PersistenceFileError> {
    match fs::remove_file(path) {
        Ok(()) => Ok(()),
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(()),
        Err(error) => Err(io_error("remove replaced save", path, &error)),
    }
}

fn displace(source: &Path, destination: &Path) -> Result<(), PersistenceFileError> {
    fs::rename(source, destination).map_err(|error| io_error("rotate current save", source, &error))
}

#[cfg(unix)]
fn sync_parent(path: &Path) -> Result<(), PersistenceFileError> {
    let parent = path.parent().unwrap_or_else(|| Path::new("."));
    File::open(parent)
        .and_then(|directory| directory.sync_all())
        .map_err(|error| io_error("sync save directory", parent, &error))
}

#[cfg(not(unix))]
fn sync_parent(_path: &Path) -> Result<(), PersistenceFileError> {
    Ok(())
}

fn export_error(error: &PersistenceError) -> PersistenceFileError {
    PersistenceFileError::new(format!("export current save: {error}"))
}

fn io_error(operation: &str, path: &Path, error: &std::io::Error) -> PersistenceFileError {
    PersistenceFileError::new(format!("{operation} {}: {error}", path.display()))
}

#[cfg(test)]
mod tests {
    use std::fs;
    use std::sync::atomic::{AtomicU64, Ordering};

    use super::{PersistenceFileStore, PriorDisposition};

    static TEST_SEQUENCE: AtomicU64 = AtomicU64::new(0);

    #[test]
    fn failed_atomic_install_rolls_the_displaced_primary_back() {
        let directory = std::env::temp_dir().join(format!(
            "aonw-persistence-install-{}-{}",
            std::process::id(),
            TEST_SEQUENCE.fetch_add(1, Ordering::Relaxed)
        ));
        fs::create_dir(&directory).expect("create scratch directory");
        let store = PersistenceFileStore::new(directory.join("session.aonw-save"));
        fs::write(store.primary_path(), "current").expect("write primary");
        let temp = store
            .write_synced_temp(b"replacement")
            .expect("write temporary replacement");

        let error = store
            .install_temp_using(&temp, PriorDisposition::Backup, |_, _| {
                Err(std::io::Error::new(
                    std::io::ErrorKind::PermissionDenied,
                    "injected install failure",
                ))
            })
            .expect_err("install must fail");

        assert!(error.to_string().contains("install current save"));
        assert_eq!(
            fs::read_to_string(store.primary_path()).expect("rolled back primary"),
            "current"
        );
        assert!(!store.backup_path().exists());
        assert!(!temp.exists());
        fs::remove_dir_all(directory).expect("remove scratch directory");
    }
}
