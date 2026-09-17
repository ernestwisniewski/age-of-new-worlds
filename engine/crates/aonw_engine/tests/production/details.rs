use super::*;
use aonw_engine::{ProductionDetailsQuery, ProductionTargetEffects};

#[test]
fn every_catalog_target_has_identical_read_only_details() {
    let map = rich_map(TerrainType::Plains);
    let actor = player();
    let id = CityId::new("capital").expect("city");
    let city = City::builder(id.clone(), actor.clone(), "Capital", HexCoord::new(2, 2))
        .with_controlled_hexes([HexCoord::new(3, 2), HexCoord::new(2, 1)])
        .with_buildings([CityBuildingType::Granary])
        .build()
        .expect("city");
    let state = state(
        &map,
        &actor,
        city,
        [TechnologyId::Writing, TechnologyId::Urbanization],
        BTreeMap::new(),
    );
    let before = state.clone();
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let options = super::availability::query(&state, context, &id);
    for option in options
        .buildings()
        .iter()
        .chain(options.projects())
        .chain(options.wonders())
        .copied()
        .chain(
            options
                .units()
                .iter()
                .map(aonw_engine::UnitProductionOption::option),
        )
    {
        let details = GameEngine::production_details(
            &state,
            context,
            ProductionDetailsQuery::new(9, &id, option.target()),
        )
        .expect("details");
        assert_eq!(details.option, option);
        assert_eq!(details.revision, 9);
        assert_eq!(details.city_id, id);
    }
    assert_eq!(state, before);
}

#[test]
fn details_reject_stale_revisions_foreign_cities_and_missing_cities() {
    let map = map();
    let actor = player();
    let id = CityId::new("capital").expect("city");
    let target = CityProductionTarget::Building(CityBuildingType::Granary);
    let city = City::new(id.clone(), actor.clone(), HexCoord::new(2, 2), []);
    let state = state(&map, &actor, city, [], BTreeMap::new());
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    assert_eq!(
        GameEngine::production_details(
            &state,
            context,
            ProductionDetailsQuery::new(8, &id, target)
        ),
        Err(ProductionError::Rejected(
            CommandRejectionCode::StaleRevision
        ))
    );
    let foreign = PlayerId::new("foreign").expect("player");
    let foreign_context = EngineContext::canonical(&foreign, &map, RulesetDefinition::standard());
    assert_eq!(
        GameEngine::production_details(
            &state,
            foreign_context,
            ProductionDetailsQuery::new(9, &id, target)
        ),
        Err(ProductionError::Rejected(
            CommandRejectionCode::CityNotControlled
        ))
    );
    let missing = CityId::new("missing").expect("city");
    assert_eq!(
        GameEngine::production_details(
            &state,
            context,
            ProductionDetailsQuery::new(9, &missing, target)
        ),
        Err(ProductionError::Rejected(
            CommandRejectionCode::CityNotFound
        ))
    );
}

#[test]
fn building_impact_matches_completed_city_economy_research_and_production() {
    let map = rich_map(TerrainType::Plains);
    let actor = player();
    let id = CityId::new("capital").expect("city");
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    for kind in [
        CityBuildingType::WaterMill,
        CityBuildingType::Workshop,
        CityBuildingType::University,
        CityBuildingType::Housing,
    ] {
        let city = City::builder(id.clone(), actor.clone(), "Capital", HexCoord::new(2, 2))
            .with_controlled_hexes([HexCoord::new(3, 2)])
            .with_buildings([CityBuildingType::Academy])
            .build()
            .expect("city");
        let definition = RulesetDefinition::standard()
            .production()
            .building(kind)
            .expect("building");
        let completed_city = city
            .try_with_completed_building(kind, definition.max_controlled_hexes_delta())
            .expect("completed city");
        let original = state(
            &map,
            &actor,
            city,
            [TechnologyId::Writing, TechnologyId::Urbanization],
            BTreeMap::new(),
        );
        let completed = state(
            &map,
            &actor,
            completed_city,
            [TechnologyId::Writing, TechnologyId::Urbanization],
            BTreeMap::new(),
        );
        let query = ProductionDetailsQuery::new(9, &id, CityProductionTarget::Building(kind));
        let ProductionTargetEffects::Building(details) =
            GameEngine::production_details(&original, context, query)
                .expect("details")
                .effects
        else {
            panic!("building");
        };
        let ProductionTargetEffects::Building(built) =
            GameEngine::production_details(&completed, context, query)
                .expect("details")
                .effects
        else {
            panic!("building");
        };
        assert_eq!(
            details.current.max_controlled_hexes,
            original.city(&id).expect("city").max_hexes() + 1
        );
        assert_eq!(details.completed, built.current);
        assert_eq!(
            built.current, built.completed,
            "completed buildings must not be applied twice"
        );
        let options = super::availability::query(&completed, context, &id);
        assert_eq!(
            details.completed.production,
            options.projects()[0].forecast().production_per_turn()
        );
        let QueryResult::ResearchOptions(research) = GameEngine::query(
            &completed,
            context,
            GameQuery::ResearchOptions(aonw_engine::ResearchOptionsQuery::new(9)),
        )
        .expect("research") else {
            panic!("research");
        };
        assert_eq!(
            details.completed.science,
            research.science_yield().by_city_id()[&id]
        );
        let QueryResult::EconomyForecast(economy) = GameEngine::query(
            &completed,
            context,
            GameQuery::EconomyForecast(aonw_engine::EconomyForecastQuery::new(9)),
        )
        .expect("economy") else {
            panic!("economy");
        };
        assert_eq!(details.completed.gold, economy.city_income());
        if kind == CityBuildingType::WaterMill {
            assert_eq!(details.river_applications, 1);
            assert_eq!(
                details.completed.gross_yield.food - details.current.gross_yield.food,
                1
            );
        }
        if kind == CityBuildingType::University {
            assert!(details.completed.science - details.current.science < details.science_per_turn);
        }
    }
}

#[test]
fn location_requirements_share_the_command_predicates_even_when_research_is_locked() {
    let map = map();
    let actor = player();
    let id = CityId::new("capital").expect("city");
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let city = City::new(id.clone(), actor.clone(), HexCoord::new(2, 2), []);
    let state = state(&map, &actor, city, [], BTreeMap::new());
    let details = GameEngine::production_details(
        &state,
        context,
        ProductionDetailsQuery::new(
            9,
            &id,
            CityProductionTarget::Building(CityBuildingType::Port),
        ),
    )
    .expect("details");
    assert!(!details.option.availability().technology_unlocked());
    let ProductionTargetEffects::Building(details) = details.effects else {
        panic!("building");
    };
    assert_eq!(details.requirements.len(), 1);
    assert_eq!(
        details.requirements[0].requirement,
        aonw_content::ProductionRequirement::CoastalAccess
    );
    assert!(!details.requirements[0].met);
}

#[test]
fn fresh_unit_statistics_apply_only_persistent_owner_technology() {
    let map = map();
    let actor = player();
    let id = CityId::new("capital").expect("city");
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let city = City::new(id.clone(), actor.clone(), HexCoord::new(2, 2), []);
    let state = state(
        &map,
        &actor,
        city,
        [TechnologyId::Strategy],
        BTreeMap::new(),
    );
    let details = GameEngine::production_details(
        &state,
        context,
        ProductionDetailsQuery::new(9, &id, CityProductionTarget::Unit(UnitKind::Warrior)),
    )
    .expect("details");
    let ProductionTargetEffects::Unit(details) = details.effects else {
        panic!("unit");
    };
    assert_eq!(
        details.effective_combat.defense,
        details.base_combat.defense() + 1
    );
    assert_eq!(
        details.effective_combat.hit_points,
        details.base_combat.hit_points() + 2
    );
    assert!(
        details
            .effective_combat
            .modifiers
            .iter()
            .all(|modifier| modifier.kind == aonw_engine::CombatModifierKind::Technology)
    );
    let balance = RulesetDefinition::standard()
        .production()
        .unit(UnitKind::Warrior)
        .expect("unit");
    assert_eq!(details.base_upkeep, balance.upkeep());
    assert_eq!(details.supply_cost, balance.supply_cost());
    assert_eq!(details.supply_used_without_city_queue, 0);
}

#[test]
fn wonder_effects_expose_public_rules_without_foreign_completion_metadata() {
    let map = map();
    let actor = player();
    let id = CityId::new("capital").expect("city");
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let city = City::new(id.clone(), actor.clone(), HexCoord::new(2, 2), []);
    let state = state(&map, &actor, city, [], BTreeMap::new());
    let details = GameEngine::production_details(
        &state,
        context,
        ProductionDetailsQuery::new(
            9,
            &id,
            CityProductionTarget::Wonder(WonderType::GreatLibrary),
        ),
    )
    .expect("details");
    let ProductionTargetEffects::Wonder(details) = details.effects else {
        panic!("wonder");
    };
    assert!(details.grants_free_active_technology);
    assert!(details.empire_science_per_city > 0);
}
