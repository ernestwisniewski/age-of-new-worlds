use aonw_domain::{HexCoord, PlayerId, UnitId, UnitKind};

use crate::{
    GridLayout, MapDefinition, RulesetDefinition, ScenarioDefinition, ScenarioUnitDefinition,
    TerrainType, TileDefinition,
};

fn map() -> MapDefinition {
    let tiles = (0..2)
        .flat_map(|row| {
            (0..2).map(move |col| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(col, row),
                    vec![TerrainType::Plains],
                    Vec::new(),
                    0,
                )
                .expect("tile")
            })
        })
        .collect();
    MapDefinition::try_new(
        "scenario-map",
        GridLayout::OddQFlatTop,
        2,
        2,
        tiles,
        Vec::new(),
    )
    .expect("map")
}

fn initial(id: &str, owner: &str, position: HexCoord) -> ScenarioUnitDefinition {
    ScenarioUnitDefinition::new(
        UnitId::new(id).expect("unit id"),
        PlayerId::new(owner).expect("owner id"),
        UnitKind::Commander,
        "unit.commander",
        position,
    )
}

#[test]
fn scenario_bootstraps_full_state_from_map_and_ruleset() {
    let map = map();
    let ruleset = RulesetDefinition::standard();
    let scenario = ScenarioDefinition::try_new(
        "duel",
        &map,
        ruleset,
        [
            initial("unit-1", "player-1", HexCoord::new(0, 0)),
            initial("unit-2", "player-2", HexCoord::new(1, 1)),
        ],
    )
    .expect("scenario");

    let state = scenario.bootstrap(&map, ruleset).expect("state");
    assert_eq!(state.turn(), 1);
    assert_eq!(state.units().len(), 2);
    assert_eq!(
        state.units()[0].movement_units(),
        ruleset
            .unit(UnitKind::Commander)
            .expect("definition")
            .maximum_movement(false)
    );
    assert_ne!(
        scenario.content_hash().expect("scenario hash"),
        scenario.map_hash()
    );
    assert_ne!(scenario.ruleset_hash(), scenario.map_hash());
    assert_eq!(
        scenario.content_hash().expect("hash").to_string(),
        "3876abf123f0066791447aa303a69b00230cf29d0bcb32b84617586fcedafb79"
    );
}

#[test]
fn scenario_rejects_hostile_stacking_but_allows_friendly_stacking() {
    let map = map();
    let ruleset = RulesetDefinition::standard();
    let position = HexCoord::new(0, 0);
    assert!(
        ScenarioDefinition::try_new(
            "friendly",
            &map,
            ruleset,
            [
                initial("one", "player-1", position),
                initial("two", "player-1", position)
            ]
        )
        .is_ok()
    );
    assert!(
        ScenarioDefinition::try_new(
            "hostile",
            &map,
            ruleset,
            [
                initial("one", "player-1", position),
                initial("two", "player-2", position)
            ]
        )
        .is_err()
    );
}

#[test]
fn scenario_json_is_strict_and_bound_to_content() {
    let map = map();
    let ruleset = RulesetDefinition::standard();
    let source = br#"{
        "schemaVersion": 1,
        "scenarioId": "json-scenario",
        "mapId": "scenario-map",
        "rulesetId": "aonw-standard",
        "initialUnits": [{
            "id": "unit-1",
            "ownerPlayerId": "player-1",
            "kind": "commander",
            "name": "Commander",
            "col": 0,
            "row": 0
        }]
    }"#;
    let scenario = ScenarioDefinition::from_json(source, &map, ruleset).expect("scenario");
    assert_eq!(scenario.initial_units().len(), 1);

    let unknown = String::from_utf8(source.to_vec())
        .expect("utf8")
        .replace("\"initialUnits\"", "\"unknown\": true, \"initialUnits\"");
    assert!(ScenarioDefinition::from_json(unknown.as_bytes(), &map, ruleset).is_err());
    let other_map = MapDefinition::try_new(
        "other-map",
        map.grid_layout(),
        map.cols(),
        map.rows(),
        map.tiles().to_vec(),
        Vec::new(),
    )
    .expect("other map");
    assert!(ScenarioDefinition::from_json(source, &other_map, ruleset).is_err());
}
