//! Acceptance contract for deterministic terrain compilation.

use std::fs;
use std::path::{Path, PathBuf};

use aonw_content::MapDocument;
use aonw_map_authoring::TerrainAuthoringProfile;
use aonw_map_compiler::{
    RasterConfig, RasterRegion, TERRAIN_GENERATOR_VERSION, TerrainClampError, compile_terrain,
};

fn repository_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .find(|path| path.join("engine/Cargo.toml").is_file() && path.join("content").is_dir())
        .expect("repository root must contain engine and content")
        .to_path_buf()
}

fn starter_profile() -> TerrainAuthoringProfile {
    let root = repository_root();
    let map_source = fs::read(root.join("content/maps/aonw2_starter/map.json"))
        .expect("starter map must be readable");
    let map = MapDocument::from_json(&map_source).expect("starter map must validate");
    let profile_source = fs::read(root.join("content/maps/aonw2_starter/terrain_authoring.json"))
        .expect("starter profile must be readable");
    TerrainAuthoringProfile::from_json(&profile_source, map.map())
        .expect("starter profile must validate")
}

#[test]
fn starter_compilation_is_deterministic_bounded_and_traceable() {
    let profile = starter_profile();
    let config = RasterConfig::try_new(10).expect("valid density");
    let first = compile_terrain(&profile, config).expect("starter must compile");
    let second = compile_terrain(&profile, config).expect("starter must compile twice");

    assert_eq!(first, second);
    assert_eq!(first.metadata(), second.metadata());
    assert_eq!(
        first.metadata().generator_version(),
        TERRAIN_GENERATOR_VERSION
    );
    assert_eq!(
        first.metadata().map_content_hash(),
        profile.source_map_content_hash(),
    );
    assert_eq!(
        first.metadata().authoring_profile_hash(),
        profile.authoring_profile_hash().expect("profile must hash"),
    );
    assert_eq!(first.base().width(), first.min().width());
    assert_eq!(first.base().height(), first.max().height());
    assert_eq!((first.base().width(), first.base().height()), (111, 131));
    assert_eq!(first.base().values().len(), first.min().values().len());
    assert_eq!(first.base().values().len(), first.max().values().len());
    for ((minimum, base), maximum) in first
        .min()
        .values()
        .iter()
        .zip(first.base().values())
        .zip(first.max().values())
    {
        assert!(minimum <= base, "compiled minimum must not exceed base");
        assert!(base <= maximum, "compiled base must not exceed maximum");
    }

    assert_eq!(
        first.metadata().base_raster_hash().to_string(),
        "220d23c5d9cc33e4aebfab58ede108114816a132f194ffe7aba22199a62825e1",
        "generator changes require an explicit version and golden update",
    );
    assert_eq!(
        first.metadata().min_raster_hash().to_string(),
        "16c2062b962ea9569940ff47064546e4e63191c2229d3ed71b90dd902b0f638c",
    );
    assert_eq!(
        first.metadata().max_raster_hash().to_string(),
        "e7e0e54311665721703ddab6cf1931a64dbf160f13d0fe7339ac570d7784b67a",
    );
}

#[test]
fn edge_blending_removes_full_height_steps_between_adjacent_samples() {
    let compiled = compile_terrain(
        &starter_profile(),
        RasterConfig::try_new(10).expect("valid density"),
    )
    .expect("starter must compile");
    let width = usize::try_from(compiled.base().width()).expect("width fits usize");
    let mut maximum_delta = 0.0_f32;
    for (index, value) in compiled.base().values().iter().copied().enumerate() {
        if index % width + 1 < width {
            maximum_delta = maximum_delta.max((value - compiled.base().values()[index + 1]).abs());
        }
        if index + width < compiled.base().values().len() {
            maximum_delta =
                maximum_delta.max((value - compiled.base().values()[index + width]).abs());
        }
    }

    assert!(
        maximum_delta < 4.0,
        "blended neighboring samples must not retain a full logical height step; found {maximum_delta}"
    );
}

#[test]
fn clamp_is_bounded_transactional_and_changes_only_the_requested_region() {
    let compiled = compile_terrain(
        &starter_profile(),
        RasterConfig::try_new(4).expect("valid density"),
    )
    .expect("starter must compile");
    let width = compiled.base().width();
    let height = compiled.base().height();
    let region = RasterRegion::new(1, 1, width - 2, height - 2);
    let mut final_heights = compiled
        .min()
        .values()
        .iter()
        .zip(compiled.max().values())
        .enumerate()
        .map(|(index, (minimum, maximum))| match index % 3 {
            0 => minimum - 100.0,
            1 => maximum + 100.0,
            _ => (minimum + maximum) / 2.0,
        })
        .collect::<Vec<_>>();
    let before = final_heights.clone();
    let report = compiled
        .clamp_final_region(&mut final_heights, region)
        .expect("finite region must clamp");

    assert!(report.changed_samples() > 0);
    for y in 0..height {
        for x in 0..width {
            let index = usize::try_from(y).expect("y fits usize")
                * usize::try_from(width).expect("width fits usize")
                + usize::try_from(x).expect("x fits usize");
            let inside = x >= region.x()
                && x < region.x() + region.width()
                && y >= region.y()
                && y < region.y() + region.height();
            if inside {
                assert!(final_heights[index] >= compiled.min().values()[index]);
                assert!(final_heights[index] <= compiled.max().values()[index]);
            } else {
                assert_eq!(final_heights[index].to_bits(), before[index].to_bits());
            }
        }
    }

    let mut non_finite = before;
    let invalid_index = usize::try_from(width).expect("width fits usize") + 1;
    non_finite[invalid_index] = f32::NAN;
    let snapshot = non_finite
        .iter()
        .map(|value| value.to_bits())
        .collect::<Vec<_>>();
    assert_eq!(
        compiled.clamp_final_region(&mut non_finite, region),
        Err(TerrainClampError::NonFiniteFinalHeight {
            index: invalid_index
        }),
    );
    assert_eq!(
        non_finite
            .iter()
            .map(|value| value.to_bits())
            .collect::<Vec<_>>(),
        snapshot,
        "validation must finish before any manual sample changes",
    );
}

#[test]
fn compiling_a_new_base_does_not_own_or_overwrite_manual_final_terrain() {
    let profile = starter_profile();
    let config = RasterConfig::try_new(4).expect("valid density");
    let compiled = compile_terrain(&profile, config).expect("starter must compile");
    let manual_final = compiled
        .base()
        .values()
        .iter()
        .map(|value| value + 0.25)
        .collect::<Vec<_>>();
    let before = manual_final.clone();

    let regenerated = compile_terrain(&profile, config).expect("base must regenerate");

    assert_eq!(manual_final, before);
    assert_eq!(regenerated.metadata(), compiled.metadata());
}

#[test]
fn raster_density_is_explicit_and_bounded() {
    assert!(RasterConfig::try_new(0).is_err());
    assert!(RasterConfig::try_new(65).is_err());
    assert_eq!(
        RasterConfig::try_new(8)
            .expect("density must validate")
            .samples_per_hex(),
        8,
    );
}
