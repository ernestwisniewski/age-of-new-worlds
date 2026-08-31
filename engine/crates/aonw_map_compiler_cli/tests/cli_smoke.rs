//! Black-box smoke test for the thin terrain artifact writer.

use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::{SystemTime, UNIX_EPOCH};

use serde_json::Value;

fn repository_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .find(|path| path.join("engine/Cargo.toml").is_file() && path.join("content").is_dir())
        .expect("repository root must contain engine and content")
        .to_path_buf()
}

#[test]
fn cli_writes_reviewable_exr_r16_and_manifest_artifacts() {
    let root = repository_root();
    let temporary = TemporaryDirectory::new();
    let status = Command::new(env!("CARGO_BIN_EXE_aonw-map-compiler"))
        .arg(root.join("content/maps/aonw2_starter/map.json"))
        .arg(root.join("content/maps/aonw2_starter/terrain_authoring.json"))
        .arg(temporary.path())
        .arg("4")
        .status()
        .expect("compiler CLI must start");
    assert!(status.success(), "compiler CLI must succeed");

    let manifest_source =
        fs::read(temporary.path().join("terrain_compile.json")).expect("manifest must be written");
    let manifest: Value = serde_json::from_slice(&manifest_source).expect("manifest must decode");
    assert!(manifest.get("schemaVersion").is_none());
    assert_eq!(manifest["generatorVersion"], "aonw-map-compiler/1");
    assert_eq!(manifest["mapId"], "aonw2_starter");
    assert_eq!(
        manifest["mapContentHash"],
        "4d5603cc00fa8963a71c23133570f89f43c734598d86579e12e1b1059da8712d",
    );
    assert_eq!(
        manifest["authoringProfileHash"],
        "52d4f1631dcb506e8a05eee30f928a6d72aabb2f1f2a1d8daf1894295ded61a2",
    );
    let width = manifest["raster"]["width"]
        .as_u64()
        .expect("width must be an integer");
    let height = manifest["raster"]["height"]
        .as_u64()
        .expect("height must be an integer");
    for layer in ["base", "min", "max"] {
        let exr = fs::read(temporary.path().join(format!("{layer}.exr")))
            .expect("OpenEXR layer must be written");
        assert_eq!(&exr[..4], &[0x76, 0x2f, 0x31, 0x01]);
        let r16 = fs::read(temporary.path().join(format!("{layer}.r16")))
            .expect("R16 layer must be written");
        assert_eq!(
            u64::try_from(r16.len()).expect("length fits u64"),
            width * height * 2,
        );
        assert!(manifest["layers"][layer]["hash"].is_string());
        assert!(manifest["layers"][layer]["openExrSha256"].is_string());
        assert!(manifest["layers"][layer]["rawR16Sha256"].is_string());
    }
    assert_eq!(
        manifest["generatedBaseHash"],
        manifest["layers"]["base"]["hash"],
    );
    assert_eq!(manifest["authoring"]["cols"], 7);
    assert_eq!(manifest["authoring"]["rows"], 7);
    assert_eq!(manifest["authoring"]["hexRadiusMeters"], 10.0);
    assert_eq!(manifest["authoring"]["maxTerrainHeightMeters"], 20.0);
    assert_eq!(manifest["authoring"]["cityCoreRadiusMeters"], 4.0);
}

#[test]
fn profile_cli_generates_a_deterministic_standard_profile() {
    let root = repository_root();
    let temporary = TemporaryDirectory::new();
    let map_path = root.join("content/maps/aonw2_starter/map.json");
    let first_path = temporary.path().join("first.json");
    let second_path = temporary.path().join("second.json");
    for output_path in [&first_path, &second_path] {
        let status = Command::new(env!("CARGO_BIN_EXE_aonw-map-profile"))
            .arg(&map_path)
            .arg(output_path)
            .arg("10")
            .status()
            .expect("profile CLI must start");
        assert!(status.success(), "profile CLI must succeed");
    }

    let first = fs::read(&first_path).expect("first profile must be written");
    let second = fs::read(&second_path).expect("second profile must be written");
    assert_eq!(
        first, second,
        "standard profile output must be deterministic"
    );
    let profile: Value = serde_json::from_slice(&first).expect("profile must decode");
    assert_eq!(profile["schemaVersion"], 1);
    assert_eq!(profile["hexRadiusMeters"], 10.0);
    assert_eq!(profile["maxTerrainHeightMeters"], 20.0);
    assert_eq!(profile["hexHeights"].as_array().map(Vec::len), Some(49));
    assert_eq!(
        profile["sourceMapContentHash"],
        "4d5603cc00fa8963a71c23133570f89f43c734598d86579e12e1b1059da8712d",
    );
}

struct TemporaryDirectory(PathBuf);

static NEXT_TEMPORARY_DIRECTORY: AtomicU64 = AtomicU64::new(0);

impl TemporaryDirectory {
    fn new() -> Self {
        let nonce = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("system clock must follow the epoch")
            .as_nanos();
        let path = std::env::temp_dir().join(format!(
            "aonw-map-compiler-test-{}-{nonce}-{}",
            std::process::id(),
            NEXT_TEMPORARY_DIRECTORY.fetch_add(1, Ordering::Relaxed),
        ));
        fs::create_dir(&path).expect("unique temporary directory must be created");
        Self(path)
    }

    fn path(&self) -> &Path {
        &self.0
    }
}

impl Drop for TemporaryDirectory {
    fn drop(&mut self) {
        fs::remove_dir_all(&self.0).expect("temporary compiler output must be removable");
    }
}
