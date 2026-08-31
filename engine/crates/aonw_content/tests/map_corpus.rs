//! Contract checks for canonical shared map content.

use std::fs;
use std::path::{Path, PathBuf};

use aonw_content::{GridLayout, MapDocument, RulesetDefinition, ScenarioDefinition};

fn repository_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .find(|path| path.join("engine/Cargo.toml").is_file() && path.join("content").is_dir())
        .expect("repository root must contain engine and content")
        .to_path_buf()
}

#[test]
fn starter_scenario_bootstraps_against_canonical_content() {
    let root = repository_root();
    let map_source = fs::read(root.join("content/maps/aonw2_starter/map.json"))
        .expect("starter map must be readable");
    let document = MapDocument::from_json(&map_source).expect("starter map must validate");
    let scenario_source = fs::read(root.join("content/scenarios/aonw2_starter/scenario.json"))
        .expect("starter scenario must be readable");
    let ruleset = RulesetDefinition::standard();
    let scenario = ScenarioDefinition::from_json(&scenario_source, document.map(), ruleset)
        .expect("starter scenario must validate");
    let state = scenario
        .bootstrap(document.map(), ruleset)
        .expect("starter scenario must bootstrap");

    assert_eq!(scenario.map_id(), document.map().map_id());
    assert_eq!(scenario.ruleset_id(), ruleset.ruleset_id());
    assert_eq!(state.units().len(), 1);
}

#[test]
fn every_shared_map_loads_and_round_trips_canonically() {
    let expected_hashes = [
        (
            "aonw2_starter",
            "4d5603cc00fa8963a71c23133570f89f43c734598d86579e12e1b1059da8712d",
        ),
        (
            "dravonia",
            "64d8d98659a05cf6ba19fe7e0ae0d5e83b70f8b9da753cde9bf1459199519c82",
        ),
        (
            "myranth",
            "1743616d03d54d04f53fc699c2a6ec2e1ba30f59665ddaa8776419fe06626571",
        ),
        (
            "terenos",
            "c580c081e39a677e0d6f5e51f1654fe12b0274bfe9672c03994b9c61d1c88fec",
        ),
        (
            "verdantia",
            "8765fc5eb23e7d715a97a743a533c6381988b7afbad57f208868223c6d46fbb5",
        ),
    ];
    let mut actual_hashes = Vec::new();
    for (map_name, _) in expected_hashes {
        let path = repository_root()
            .join("content/maps")
            .join(map_name)
            .join("map.json");
        let source = fs::read(path).expect("canonical map must be readable");
        let document = MapDocument::from_json(&source).expect("canonical map must validate");
        let map = document.map();
        let versioned = document.to_versioned_json().expect("map must serialize");
        let reloaded =
            MapDocument::from_json(versioned.as_bytes()).expect("canonical map must reload");
        let content_hash = map.content_hash().expect("canonical map must hash");

        assert_eq!(map.map_id(), map_name);
        assert_eq!(map.grid_layout(), GridLayout::OddQFlatTop);
        assert_eq!(
            map.tiles().len(),
            usize::from(map.cols()) * usize::from(map.rows())
        );
        assert_eq!(
            reloaded, document,
            "{map_name} must round-trip without losing map fields"
        );
        assert_eq!(
            reloaded
                .map()
                .content_hash()
                .expect("reloaded map must hash"),
            content_hash
        );
        actual_hashes.push((map_name, content_hash.to_string()));
    }
    assert_eq!(
        actual_hashes,
        expected_hashes
            .map(|(map_name, hash)| (map_name, hash.to_owned()))
            .to_vec(),
        "approved map content hashes",
    );
}
