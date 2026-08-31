//! Contract checks for terrain authoring profile version 1.

use std::fs;
use std::path::{Path, PathBuf};

use aonw_content::{GridLayout, MapDocument};
use aonw_map_authoring::{TerrainAuthoringLoadError, TerrainAuthoringProfile};
use serde_json::{Value, json};

fn repository_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .find(|path| path.join("engine/Cargo.toml").is_file() && path.join("content").is_dir())
        .expect("repository root must contain engine and content")
        .to_path_buf()
}

fn starter_map() -> MapDocument {
    let source = fs::read(repository_root().join("content/maps/aonw2_starter/map.json"))
        .expect("starter map must be readable");
    MapDocument::from_json(&source).expect("starter map must validate")
}

fn starter_profile_source() -> Vec<u8> {
    fs::read(repository_root().join("content/maps/aonw2_starter/terrain_authoring.json"))
        .expect("starter terrain profile must be readable")
}

fn starter_profile_value() -> Value {
    serde_json::from_slice(&starter_profile_source()).expect("fixture JSON must decode")
}

fn decode(
    value: &Value,
    map: &MapDocument,
) -> Result<TerrainAuthoringProfile, TerrainAuthoringLoadError> {
    TerrainAuthoringProfile::from_json(
        &serde_json::to_vec(value).expect("test JSON must encode"),
        map.map(),
    )
}

#[test]
fn every_shared_map_defines_its_own_metric_height_ceiling() {
    let maps_directory = repository_root().join("content/maps");
    let mut map_directories = fs::read_dir(&maps_directory)
        .expect("shared map directory must be readable")
        .map(|entry| entry.expect("map entry must be readable").path())
        .filter(|path| path.is_dir() && path.join("map.json").is_file())
        .collect::<Vec<_>>();
    map_directories.sort();
    assert!(
        !map_directories.is_empty(),
        "shared map corpus must not be empty"
    );

    for directory in map_directories {
        let map = MapDocument::from_json(
            &fs::read(directory.join("map.json")).expect("map must be readable"),
        )
        .expect("map must validate");
        let profile = TerrainAuthoringProfile::from_json(
            &fs::read(directory.join("terrain_authoring.json"))
                .expect("every map must define terrain authoring"),
            map.map(),
        )
        .expect("terrain authoring profile must validate");

        let expected_maximum = profile.max_terrain_height_meters();
        assert!(expected_maximum.is_finite() && expected_maximum > 0.0);
        assert!(
            profile.hex_heights().iter().all(|height| {
                height.max_height_meters() <= profile.max_terrain_height_meters()
            })
        );
        for (tile, height) in map.map().tiles().iter().zip(profile.hex_heights()) {
            if tile.height() == 5 {
                assert!((height.base_height_meters() - expected_maximum).abs() <= f64::EPSILON);
            }
        }
    }
}

#[test]
fn starter_profile_is_bound_to_logical_content_but_has_its_own_identity() {
    let map = starter_map();
    let map_hash = map.map().content_hash().expect("map must hash");
    let profile = TerrainAuthoringProfile::from_json(&starter_profile_source(), map.map())
        .expect("starter profile must validate");

    assert_eq!(profile.source_map_content_hash(), map_hash);
    assert_eq!(profile.orientation(), GridLayout::OddQFlatTop);
    assert!((profile.hex_radius_meters() - 10.0).abs() <= f64::EPSILON);
    assert!((profile.max_terrain_height_meters() - 20.0).abs() <= f64::EPSILON);
    assert_eq!(profile.hex_heights().len(), 49);
    assert!(profile.hex_heights()[0].contains_final_height(1.5));
    assert!(!profile.hex_heights()[0].contains_final_height(5.0));
    assert_eq!(
        profile
            .authoring_profile_hash()
            .expect("profile must hash")
            .to_string(),
        "52d4f1631dcb506e8a05eee30f928a6d72aabb2f1f2a1d8daf1894295ded61a2",
        "approved starter authoring profile hash",
    );
    assert_eq!(
        map.map()
            .content_hash()
            .expect("map hash must remain stable"),
        map_hash,
        "loading authoring metadata cannot change logical map identity",
    );
    assert_ne!(
        profile
            .authoring_profile_hash()
            .expect("profile must hash")
            .to_string(),
        map_hash.to_string(),
        "authoring and logical content use separate identities",
    );
}

#[test]
fn profile_round_trip_and_hash_are_deterministic() {
    let map = starter_map();
    let profile = TerrainAuthoringProfile::from_json(&starter_profile_source(), map.map())
        .expect("starter profile must validate");
    let versioned = profile.to_versioned_json().expect("profile must serialize");
    let reloaded = TerrainAuthoringProfile::from_json(versioned.as_bytes(), map.map())
        .expect("serialized profile must reload");

    assert_eq!(reloaded, profile);
    assert_eq!(
        reloaded
            .to_versioned_json()
            .expect("profile must serialize"),
        versioned,
    );
    assert_eq!(
        reloaded
            .authoring_profile_hash()
            .expect("profile must hash"),
        profile.authoring_profile_hash().expect("profile must hash"),
    );

    let mut reordered = starter_profile_value();
    reordered["hexHeights"]
        .as_array_mut()
        .expect("height array")
        .reverse();
    let normalized = decode(&reordered, &map).expect("input order must normalize");
    assert_eq!(
        normalized
            .canonical_bytes()
            .expect("normalized profile must serialize"),
        profile
            .canonical_bytes()
            .expect("source profile must serialize")
    );
}

#[test]
fn metric_height_ceiling_is_rebuilt_from_logical_heights() {
    let map = starter_map();
    let profile = TerrainAuthoringProfile::from_json(&starter_profile_source(), map.map())
        .expect("starter profile must validate");
    let updated = profile
        .with_max_terrain_height_meters(map.map(), 35.0)
        .expect("metric height scale must update");

    assert!((updated.max_terrain_height_meters() - 35.0).abs() <= f64::EPSILON);
    assert!((updated.hex_radius_meters() - profile.hex_radius_meters()).abs() <= f64::EPSILON);
    assert_eq!(updated.world_origin_meters(), profile.world_origin_meters());
    assert_eq!(updated.reference_transform(), profile.reference_transform());
    for (tile, envelope) in map.map().tiles().iter().zip(updated.hex_heights()) {
        let expected_base = f64::from(tile.height()) * 7.0;
        assert!((envelope.base_height_meters() - expected_base).abs() <= f64::EPSILON);
        assert!(envelope.max_height_meters() <= 35.0);
    }
}

#[test]
fn invalid_height_envelopes_fail_closed() {
    let map = starter_map();
    let cases = [
        (
            "minimum above base",
            Box::new(|value: &mut Value| value["hexHeights"][0]["minHeightMeters"] = json!(1.0))
                as Box<dyn Fn(&mut Value)>,
        ),
        (
            "base above maximum",
            Box::new(|value: &mut Value| value["hexHeights"][0]["baseHeightMeters"] = json!(5.0)),
        ),
        (
            "missing coverage",
            Box::new(|value: &mut Value| {
                value["hexHeights"].as_array_mut().expect("array").pop();
            }),
        ),
        (
            "duplicate coverage",
            Box::new(|value: &mut Value| {
                value["hexHeights"][1] = value["hexHeights"][0].clone();
            }),
        ),
    ];

    for (name, mutate) in cases {
        let mut value = starter_profile_value();
        mutate(&mut value);
        assert!(decode(&value, &map).is_err(), "{name}");
    }
}

#[test]
fn stale_map_hash_and_profile_only_final_height_are_rejected() {
    let map = starter_map();
    let mut stale = starter_profile_value();
    stale["sourceMapContentHash"] = json!("00".repeat(32));
    let error = decode(&stale, &map).expect_err("stale map hash must fail");
    assert_eq!(error.path(), Some("$.sourceMapContentHash"));

    let mut final_height = starter_profile_value();
    final_height["hexHeights"][0]["finalHeightMeters"] = json!(0.5);
    assert!(matches!(
        decode(&final_height, &map),
        Err(TerrainAuthoringLoadError::Json(_))
    ));
}

#[test]
fn non_finite_and_invalid_metric_values_are_rejected() {
    let map = starter_map();
    let mut negative_radius = starter_profile_value();
    negative_radius["hexRadiusMeters"] = json!(-1.0);
    assert!(decode(&negative_radius, &map).is_err());

    let mut oversized_blend = starter_profile_value();
    oversized_blend["edgeBlendMeters"] = json!(11.0);
    assert!(decode(&oversized_blend, &map).is_err());

    let mut invalid_maximum = starter_profile_value();
    invalid_maximum["maxTerrainHeightMeters"] = json!(0.0);
    assert!(decode(&invalid_maximum, &map).is_err());

    let mut envelope_above_maximum = starter_profile_value();
    envelope_above_maximum["maxTerrainHeightMeters"] = json!(3.0);
    assert!(decode(&envelope_above_maximum, &map).is_err());

    for invalid_number in ["NaN", "1e400", "-1e400"] {
        let source = String::from_utf8(starter_profile_source())
            .expect("fixture must be UTF-8")
            .replacen(
                "\"hexRadiusMeters\": 10.0",
                &format!("\"hexRadiusMeters\": {invalid_number}"),
                1,
            );
        assert!(
            TerrainAuthoringProfile::from_json(source.as_bytes(), map.map()).is_err(),
            "{invalid_number} must fail",
        );
    }
}

#[test]
fn changing_authoring_scale_does_not_change_map_content_hash() {
    let map = starter_map();
    let map_hash = map.map().content_hash().expect("map must hash");
    let original = decode(&starter_profile_value(), &map).expect("profile");
    let mut changed_value = starter_profile_value();
    changed_value["hexRadiusMeters"] = json!(12.0);
    let changed = decode(&changed_value, &map).expect("changed authoring profile");

    assert_ne!(
        original.authoring_profile_hash().expect("hash"),
        changed.authoring_profile_hash().expect("hash"),
    );
    assert_eq!(map.map().content_hash().expect("map must hash"), map_hash);
}
