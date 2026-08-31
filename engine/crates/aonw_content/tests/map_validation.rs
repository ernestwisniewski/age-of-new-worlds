//! Validation and canonicalization checks for map schema version 1.

use aonw_content::{
    GridLayout, MapDefinition, MapDocument, MapLoadError, MapObjective, MapObjectiveType,
    ResourceType, TerrainProfile, TerrainType, TileDefinition,
};
use aonw_domain::{HexCoord, HexTileIndex};
use serde_json::{Value, json};

type Mutation = (&'static str, Box<dyn Fn(&mut Value)>);

fn document() -> Value {
    let tiles = (0..5)
        .flat_map(|row| {
            (0..5).map(move |col| {
                json!({
                    "col": col,
                    "row": row,
                    "terrainTags": ["plains"],
                    "resources": if col == 0 && row == 0 {
                        json!(["iron", "wheat"])
                    } else {
                        json!([])
                    },
                    "height": 0
                })
            })
        })
        .collect::<Vec<_>>();
    json!({
        "schemaVersion": 1,
        "gridLayout": "oddQFlatTop",
        "cols": 5,
        "rows": 5,
        "mapName": "test_map",
        "defaultZoom": 1.0,
        "objectives": [{
            "id": "center_ruins",
            "type": "ruins",
            "hex": {"col": 2, "row": 2},
            "requiredHoldTurns": 3,
            "victoryPoints": 2,
            "goldPerTurn": 1
        }],
        "tiles": tiles
    })
}

fn decode(value: &Value) -> Result<MapDocument, MapLoadError> {
    MapDocument::from_json(&serde_json::to_vec(value).expect("test JSON must encode"))
}

fn logical_map(cols: u16, rows: u16) -> MapDefinition {
    let tiles = (0..rows)
        .flat_map(|row| {
            (0..cols).map(move |col| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(i32::from(col), i32::from(row)),
                    vec![TerrainType::Grassland],
                    Vec::new(),
                    0,
                )
                .expect("valid fixture tile")
            })
        })
        .collect();
    MapDefinition::try_new(
        "movement_fixture",
        GridLayout::OddQFlatTop,
        cols,
        rows,
        tiles,
        Vec::new(),
    )
    .expect("valid logical map")
}

#[test]
fn canonical_logical_map_round_trips_simulation_bounds_without_presentation_fields() {
    let map = logical_map(2, 1);
    let bytes = map.canonical_bytes().expect("canonical map");
    let decoded = MapDefinition::from_canonical_json(&bytes).expect("logical map");

    assert_eq!(decoded, map);
    let mut value = serde_json::from_slice::<Value>(&bytes).expect("canonical JSON");
    value["defaultZoom"] = json!(1.0);
    assert!(
        MapDefinition::from_canonical_json(&serde_json::to_vec(&value).expect("JSON")).is_err()
    );
}

#[test]
fn versioned_map_normalizes_lookup_and_resource_order() {
    let mut source = document();
    source["tiles"][0]["terrainTags"] = json!(["ocean", "mountain"]);
    let document = decode(&source).expect("valid map");
    let tile = document.map().tile_at(HexCoord::new(0, 0)).expect("tile");

    assert_eq!(tile.resources(), &[ResourceType::Wheat, ResourceType::Iron]);
    assert_eq!(tile.movement_terrains(), &[TerrainType::Mountain]);
    assert_eq!(tile.display_terrain(), TerrainType::Ocean);
    assert_eq!(tile.yield_terrain(), TerrainType::Ocean);
    assert_eq!(
        tile.terrain_tags(),
        &[TerrainType::Ocean, TerrainType::Mountain],
    );
    assert!(document.map().tile_at(HexCoord::new(-1, 0)).is_none());
}

#[test]
fn strict_document_requires_every_schema_field() {
    for field in ["defaultZoom", "objectives"] {
        let mut value = document();
        value.as_object_mut().expect("object").remove(field);
        assert!(
            matches!(decode(&value), Err(MapLoadError::Json(_))),
            "{field}"
        );
    }

    let mut value = document();
    value["objectives"][0]
        .as_object_mut()
        .expect("objective")
        .remove("victoryPoints");
    assert!(matches!(decode(&value), Err(MapLoadError::Json(_))));

    let mut value = document();
    value["tiles"][0]
        .as_object_mut()
        .expect("tile")
        .remove("terrainTags");
    assert!(matches!(decode(&value), Err(MapLoadError::Json(_))));
}

#[test]
fn integer_valued_json_numbers_survive_godot_round_trips() {
    let mut value = document();
    value["schemaVersion"] = json!(1.0);
    value["cols"] = json!(5.0);
    value["rows"] = json!(5.0);
    value["tiles"][0]["col"] = json!(0.0);
    value["tiles"][0]["row"] = json!(0.0);
    value["tiles"][0]["height"] = json!(0.0);
    value["objectives"][0]["hex"]["col"] = json!(2.0);
    value["objectives"][0]["requiredHoldTurns"] = json!(3.0);

    decode(&value).expect("integer-valued numbers remain valid JSON integers");

    value["tiles"][0]["height"] = json!(0.5);
    assert!(matches!(decode(&value), Err(MapLoadError::Json(_))));
}

#[test]
fn duplicate_json_keys_are_rejected() {
    let source = br#"{
        "schemaVersion":1,"schemaVersion":1,"gridLayout":"oddQFlatTop",
        "cols":5,"rows":5,"mapName":"test_map","defaultZoom":1,
        "objectives":[],"tiles":[]
    }"#;

    assert!(matches!(
        MapDocument::from_json(source),
        Err(MapLoadError::Json(_))
    ));
}

#[test]
fn invalid_tiles_fail_closed() {
    let cases: [Mutation; 7] = [
        (
            "duplicate coordinate",
            Box::new(|value| value["tiles"][1]["col"] = json!(0)),
        ),
        (
            "duplicate resource",
            Box::new(|value| value["tiles"][0]["resources"] = json!(["wheat", "wheat"])),
        ),
        (
            "empty terrain tags",
            Box::new(|value| value["tiles"][0]["terrainTags"] = json!([])),
        ),
        (
            "duplicate terrain tag",
            Box::new(|value| value["tiles"][0]["terrainTags"] = json!(["plains", "plains"])),
        ),
        (
            "unknown terrain tag",
            Box::new(|value| value["tiles"][0]["terrainTags"] = json!(["volcano"])),
        ),
        (
            "terrain tags without yield terrain",
            Box::new(|value| value["tiles"][0]["terrainTags"] = json!(["river"])),
        ),
        (
            "height out of range",
            Box::new(|value| value["tiles"][0]["height"] = json!(6)),
        ),
    ];

    for (name, mutate) in cases {
        let mut value = document();
        mutate(&mut value);
        assert!(decode(&value).is_err(), "{name}");
    }
}

#[test]
fn invalid_map_and_objective_invariants_fail_closed() {
    let cases: [Mutation; 6] = [
        (
            "invalid id",
            Box::new(|value| value["mapName"] = json!("Bad Map")),
        ),
        (
            "invalid zoom",
            Box::new(|value| value["defaultZoom"] = json!(0)),
        ),
        (
            "invalid dimensions",
            Box::new(|value| value["cols"] = json!(4)),
        ),
        (
            "duplicate objective id",
            Box::new(|value| {
                let duplicate = value["objectives"][0].clone();
                value["objectives"]
                    .as_array_mut()
                    .expect("array")
                    .push(duplicate);
            }),
        ),
        (
            "objective collision",
            Box::new(|value| {
                let mut duplicate = value["objectives"][0].clone();
                duplicate["id"] = json!("other_ruins");
                value["objectives"]
                    .as_array_mut()
                    .expect("array")
                    .push(duplicate);
            }),
        ),
        (
            "objective outside map",
            Box::new(|value| value["objectives"][0]["hex"]["col"] = json!(8)),
        ),
    ];

    for (name, mutate) in cases {
        let mut value = document();
        mutate(&mut value);
        assert!(decode(&value).is_err(), "{name}");
    }
}

#[test]
fn canonical_hash_ignores_non_semantic_order_and_camera_zoom() {
    let mut original = document();
    original["tiles"][0]["terrainTags"] = json!(["river", "forest", "plains"]);
    let mut reordered = original.clone();
    reordered["tiles"].as_array_mut().expect("tiles").reverse();
    reordered["tiles"][24]["resources"] = json!(["wheat", "iron"]);
    reordered["defaultZoom"] = json!(2.5);

    let original = decode(&original).expect("original");
    let reordered = decode(&reordered).expect("reordered");

    assert_eq!(
        original.map().canonical_bytes().expect("bytes"),
        reordered.map().canonical_bytes().expect("bytes")
    );
    assert_eq!(
        original.map().content_hash().expect("hash"),
        reordered.map().content_hash().expect("hash")
    );
}

#[test]
fn canonical_hash_preserves_terrain_precedence() {
    let mut river_first = document();
    river_first["tiles"][0]["terrainTags"] = json!(["river", "forest", "plains"]);
    let mut forest_first = river_first.clone();
    forest_first["tiles"][0]["terrainTags"] = json!(["forest", "river", "plains"]);

    assert_ne!(
        decode(&river_first)
            .expect("river-first profile")
            .map()
            .content_hash()
            .expect("hash"),
        decode(&forest_first)
            .expect("forest-first profile")
            .map()
            .content_hash()
            .expect("hash"),
    );
}

#[test]
fn canonical_hash_includes_the_terrain_profile_resources_and_height() {
    let source = document();
    let original = decode(&source)
        .expect("original")
        .map()
        .content_hash()
        .expect("hash");
    let cases: [Mutation; 3] = [
        (
            "terrain profile",
            Box::new(|value| {
                value["tiles"][0]["terrainTags"] = json!(["grassland"]);
            }),
        ),
        (
            "resources",
            Box::new(|value| value["tiles"][1]["resources"] = json!(["wheat"])),
        ),
        (
            "height",
            Box::new(|value| value["tiles"][0]["height"] = json!(1)),
        ),
    ];

    for (name, mutate) in cases {
        let mut changed = source.clone();
        mutate(&mut changed);
        assert_ne!(
            decode(&changed)
                .expect("changed map")
                .map()
                .content_hash()
                .expect("hash"),
            original,
            "{name} must participate in contentHash"
        );
    }
}

#[test]
fn canonical_hash_uses_one_terrain_source_of_truth() {
    let decoded = decode(&document()).expect("valid map");
    let canonical: Value =
        serde_json::from_slice(&decoded.map().canonical_bytes().expect("canonical bytes"))
            .expect("canonical JSON");
    let tile = &canonical["tiles"][0];

    assert!(tile.get("terrainTags").is_some());
    assert!(tile.get("terrains").is_none());
    assert!(tile.get("displayTerrain").is_none());
    assert!(tile.get("yieldTerrain").is_none());
}

#[test]
fn canonical_hash_matches_golden_digest() {
    let document = decode(&document()).expect("valid map");

    assert_eq!(
        document.map().content_hash().expect("hash").to_string(),
        "7bbe6a1bf5fbe7da1ec74f9f6a24b7287302f4327ece2019bd753156f207aa45"
    );
}

#[test]
fn domain_content_can_be_constructed_without_a_json_adapter() {
    let tiles = (0..5)
        .flat_map(|row| {
            (0..5).map(move |col| {
                TileDefinition::try_new(
                    HexCoord::new(col, row),
                    TerrainProfile::try_new(vec![TerrainType::Plains])
                        .expect("valid terrain profile"),
                    Vec::new(),
                    0,
                )
                .expect("valid tile")
            })
        })
        .collect();
    let objective = MapObjective::try_new(
        "center_ruins",
        MapObjectiveType::Ruins,
        HexCoord::new(2, 2),
        3,
        2,
        1,
    )
    .expect("valid objective");
    let map = MapDefinition::try_new(
        "constructed_map",
        GridLayout::OddQFlatTop,
        5,
        5,
        tiles,
        vec![objective],
    )
    .expect("valid map");
    let document = MapDocument::try_new(map, 1.5).expect("valid document");

    assert_eq!(document.map().map_id(), "constructed_map");
    assert!((document.default_zoom() - 1.5).abs() < f64::EPSILON);
    assert!(
        TileDefinition::try_new_for_simulation(
            HexCoord::new(0, 0),
            vec![TerrainType::Plains, TerrainType::Plains],
            Vec::new(),
            0,
        )
        .is_err()
    );
}

#[test]
fn terrain_profile_derives_bounded_context_views_from_ordered_tags() {
    let terrain = TerrainProfile::try_new(vec![
        TerrainType::River,
        TerrainType::Forest,
        TerrainType::Plains,
        TerrainType::Hills,
    ])
    .expect("valid terrain profile");

    assert_eq!(terrain.display_terrain(), TerrainType::River);
    assert_eq!(terrain.yield_terrain(), TerrainType::Forest);
    assert_eq!(
        terrain.movement_terrains(),
        &[
            TerrainType::Plains,
            TerrainType::Hills,
            TerrainType::Forest,
            TerrainType::River,
        ],
    );
}

#[test]
fn versioned_serializer_emits_only_the_authored_terrain_tags() {
    let mut source = document();
    source["tiles"][0]["terrainTags"] = json!(["river", "forest", "plains"]);
    let document = decode(&source).expect("valid terrain profile");
    let encoded: Value =
        serde_json::from_str(&document.to_versioned_json().expect("versioned JSON"))
            .expect("valid JSON");
    let tile = &encoded["tiles"][0];

    assert_eq!(tile["terrainTags"], json!(["river", "forest", "plains"]));
    assert!(tile.get("terrains").is_none());
    assert!(tile.get("displayTerrain").is_none());
    assert!(tile.get("yieldTerrain").is_none());
    let model = document.map().tile_at(HexCoord::new(0, 0)).expect("tile");
    assert_eq!(model.display_terrain(), TerrainType::River);
    assert_eq!(model.yield_terrain(), TerrainType::Forest);
    assert_eq!(
        model.movement_terrains(),
        &[TerrainType::Plains, TerrainType::Forest, TerrainType::River],
    );
}

#[test]
fn simulation_maps_allow_small_fixture_grids_but_authored_documents_do_not() {
    let tiles = (0..3)
        .flat_map(|row| {
            (0..3).map(move |col| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(col, row),
                    vec![TerrainType::Plains],
                    Vec::new(),
                    0,
                )
                .expect("valid fixture tile")
            })
        })
        .collect();
    let map = MapDefinition::try_new(
        "movement_fixture",
        GridLayout::OddQFlatTop,
        3,
        3,
        tiles,
        Vec::new(),
    )
    .expect("logical simulation map");

    assert!(MapDocument::try_new(map, 1.0).is_err());
}

#[test]
fn tile_requires_one_explicit_primary_terrain() {
    let feature_first = TileDefinition::try_new_for_simulation(
        HexCoord::new(0, 0),
        vec![TerrainType::Forest, TerrainType::Plains],
        Vec::new(),
        0,
    )
    .expect_err("feature-first terrain must fail closed");
    assert_eq!(feature_first.path(), "$.terrains[0]");

    let second_primary = TileDefinition::try_new_for_simulation(
        HexCoord::new(0, 0),
        vec![TerrainType::Plains, TerrainType::Grassland],
        Vec::new(),
        0,
    )
    .expect_err("multiple primary terrains must fail closed");
    assert_eq!(second_primary.path(), "$.terrains[1]");
}

#[test]
fn logical_map_exposes_row_major_indices_and_ordered_bounded_neighbors() {
    let map = logical_map(3, 3);

    assert_eq!(
        map.tile_index(HexCoord::new(2, 1)),
        Some(HexTileIndex::new(5))
    );
    assert_eq!(
        map.coordinate_at(HexTileIndex::new(5)),
        Some(HexCoord::new(2, 1))
    );
    assert_eq!(
        map.neighbors(HexCoord::new(1, 1)).collect::<Vec<_>>(),
        [
            HexCoord::new(2, 1),
            HexCoord::new(2, 2),
            HexCoord::new(1, 2),
            HexCoord::new(0, 2),
            HexCoord::new(0, 1),
            HexCoord::new(1, 0),
        ]
    );
    assert_eq!(
        map.neighbors(HexCoord::new(0, 0)).collect::<Vec<_>>(),
        [HexCoord::new(1, 0), HexCoord::new(0, 1)]
    );
    assert!(map.tile_index(HexCoord::new(-1, 0)).is_none());
    assert!(map.coordinate_at(HexTileIndex::new(9)).is_none());
}
