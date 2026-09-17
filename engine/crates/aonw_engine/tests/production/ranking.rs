use super::*;
use aonw_engine::{ProductionBuildingRank, ProductionBuildingSort};

#[test]
fn priorities_use_owned_territory_and_all_buildings_in_content_order() {
    let map = rich_map(TerrainType::Plains);
    let actor = player();
    let id = CityId::new("capital").expect("city");
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let plain = City::new(id.clone(), actor.clone(), HexCoord::new(2, 2), []);
    let rivers = City::new(
        id.clone(),
        actor.clone(),
        HexCoord::new(2, 2),
        [HexCoord::new(3, 2)],
    );
    let plain_state = state(&map, &actor, plain, [], BTreeMap::new());
    let river_state = state(&map, &actor, rivers, [], BTreeMap::new());
    let query = ProductionOptionsQuery::new(9, &id);
    let ranks = GameEngine::production_building_ranks(&plain_state, context, query).expect("ranks");
    let river_ranks =
        GameEngine::production_building_ranks(&river_state, context, query).expect("ranks");
    assert_eq!(ranks.revision, 9);
    assert_eq!(ranks.city_id, id);
    assert_eq!(ranks.buildings.len(), 59);
    assert!(
        ranks
            .buildings
            .iter()
            .map(|rank| rank.building)
            .eq(RulesetDefinition::standard()
                .production()
                .buildings()
                .iter()
                .map(|building| building.building()))
    );
    let plain_mill = rank(&ranks.buildings, CityBuildingType::WaterMill);
    let river_mill = rank(&river_ranks.buildings, CityBuildingType::WaterMill);
    assert_eq!(plain_mill.growth, 0);
    assert_eq!(river_mill.growth, 120);
    assert_eq!(river_mill.industry, 10);
    let workshop = rank(&ranks.buildings, CityBuildingType::Workshop);
    let granary = rank(&ranks.buildings, CityBuildingType::Granary);
    assert!(
        workshop.priority(ProductionBuildingSort::Industry)
            > granary.priority(ProductionBuildingSort::Industry)
    );
    assert!(
        granary.priority(ProductionBuildingSort::Growth)
            > workshop.priority(ProductionBuildingSort::Growth)
    );
    assert_eq!(
        workshop.priority(ProductionBuildingSort::FastestImpact),
        -workshop.turns_for_score
    );
    assert_eq!(
        GameEngine::production_building_ranks(&plain_state, context, query).expect("repeat"),
        ranks
    );
}

#[test]
fn ranking_enforces_revision_and_city_ownership() {
    let map = map();
    let actor = player();
    let id = CityId::new("capital").expect("city");
    let city = City::new(id.clone(), actor.clone(), HexCoord::new(2, 2), []);
    let state = state(&map, &actor, city, [], BTreeMap::new());
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    assert_eq!(
        GameEngine::production_building_ranks(&state, context, ProductionOptionsQuery::new(8, &id)),
        Err(ProductionError::Rejected(
            CommandRejectionCode::StaleRevision
        ))
    );
    let foreign = PlayerId::new("foreign").expect("player");
    let context = EngineContext::canonical(&foreign, &map, RulesetDefinition::standard());
    assert_eq!(
        GameEngine::production_building_ranks(&state, context, ProductionOptionsQuery::new(9, &id)),
        Err(ProductionError::Rejected(
            CommandRejectionCode::CityNotControlled
        ))
    );
}

fn rank(ranks: &[ProductionBuildingRank], building: CityBuildingType) -> ProductionBuildingRank {
    *ranks
        .iter()
        .find(|rank| rank.building == building)
        .expect("building")
}
