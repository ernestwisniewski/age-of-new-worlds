use std::path::{Path, PathBuf};

pub(super) fn repository_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .find(|path| path.join("engine/fixtures/canonical_commands").is_dir())
        .expect("repository root must contain canonical engine fixtures")
        .to_path_buf()
}
