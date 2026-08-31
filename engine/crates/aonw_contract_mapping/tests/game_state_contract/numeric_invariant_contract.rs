use std::collections::BTreeMap;

use aonw_contract_mapping::decode_game_state;
use aonw_contracts::{InitialResourcePlacementDto, ResourceTypeDto, StrategicResourceStockpileDto};

use super::contract;

#[test]
fn economy_rejects_unknown_players_invalid_stockpiles_and_invalid_placements_with_paths() {
    let mut unknown = contract();
    unknown.economy.player_gold.insert("player-3".to_owned(), 1);
    assert_eq!(
        decode_game_state(unknown)
            .expect_err("unknown player")
            .path(),
        "$.economy.playerGold.player-3"
    );

    let mut negative_gold = contract();
    negative_gold
        .economy
        .player_gold
        .insert("player-1".to_owned(), -1);
    assert_eq!(
        decode_game_state(negative_gold)
            .expect_err("negative gold")
            .path(),
        "$.economy.playerGold.player-1"
    );

    let mut negative_weariness = contract();
    negative_weariness
        .economy
        .player_war_weariness
        .insert("player-1".to_owned(), -1);
    assert_eq!(
        decode_game_state(negative_weariness)
            .expect_err("negative war weariness")
            .path(),
        "$.economy.playerWarWeariness.player-1"
    );

    let mut invalid_stockpile = contract();
    invalid_stockpile.economy.strategic_resources.insert(
        "player-1".to_owned(),
        StrategicResourceStockpileDto(BTreeMap::from([(ResourceTypeDto::Iron, 2)])),
    );
    assert_eq!(
        decode_game_state(invalid_stockpile)
            .expect_err("non-stockpiled resource")
            .path(),
        "$.economy.strategicResources.player-1"
    );

    let mut zero_stockpile = contract();
    zero_stockpile.economy.strategic_resources.insert(
        "player-1".to_owned(),
        StrategicResourceStockpileDto(BTreeMap::from([(ResourceTypeDto::Oil, 0)])),
    );
    assert_eq!(
        decode_game_state(zero_stockpile)
            .expect_err("zero canonical entry")
            .path(),
        "$.economy.strategicResources.player-1"
    );

    let mut duplicate = contract();
    duplicate
        .economy
        .initial_resource_distribution
        .placements
        .push(InitialResourcePlacementDto {
            col: 4,
            row: 3,
            resource: ResourceTypeDto::Fish,
        });
    assert_eq!(
        decode_game_state(duplicate)
            .expect_err("duplicate placement")
            .path(),
        "$.economy.initialResourceDistribution.placements"
    );

    let mut outside = contract();
    outside.economy.initial_resource_distribution.placements[0].col = 5;
    assert_eq!(
        decode_game_state(outside)
            .expect_err("out-of-bounds placement")
            .path(),
        "$.economy.initialResourceDistribution.placements[0]"
    );
}

#[test]
fn city_rejects_invalid_numeric_values_with_paths() {
    let numeric_cases = [
        ("population", "$.cities[0].population"),
        ("stored_food", "$.cities[0].storedFood"),
        ("max_hexes", "$.cities[0].maxHexes"),
        ("territory_radius", "$.cities[0].territoryRadius"),
        ("production_overflow", "$.cities[0].productionOverflow"),
        ("hit_points", "$.cities[0].hitPoints"),
        (
            "invested_production",
            "$.cities[0].productionQueue.investedProduction",
        ),
    ];
    for (field, expected_path) in numeric_cases {
        let mut invalid = contract();
        match field {
            "population" => invalid.cities[0].population = 0,
            "stored_food" => invalid.cities[0].stored_food = -1,
            "max_hexes" => invalid.cities[0].max_hexes = 0,
            "territory_radius" => invalid.cities[0].territory_radius = -1,
            "production_overflow" => invalid.cities[0].production_overflow = -1,
            "hit_points" => invalid.cities[0].hit_points = Some(0),
            "invested_production" => {
                invalid.cities[0]
                    .production_queue
                    .as_mut()
                    .expect("queue")
                    .invested_production = -1;
            }
            _ => unreachable!("covered numeric field"),
        }
        assert_eq!(
            decode_game_state(invalid)
                .expect_err("invalid city numeric value")
                .path(),
            expected_path
        );
    }
}
