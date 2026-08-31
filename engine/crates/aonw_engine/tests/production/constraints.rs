use super::*;

#[test]
fn fully_unlocked_options_evaluate_every_location_resource_and_naval_requirement() {
    for center_terrain in [TerrainType::Desert, TerrainType::Snow] {
        let map = rich_map(center_terrain);
        let actor = player();
        let city_id = CityId::new("capital").expect("city id");
        let city = City::builder(
            city_id.clone(),
            actor.clone(),
            "Capital",
            HexCoord::new(2, 2),
        )
        .with_controlled_hexes([
            HexCoord::new(2, 1),
            HexCoord::new(1, 2),
            HexCoord::new(3, 2),
        ])
        .build()
        .expect("city");
        let stockpile = StrategicResourceStockpile::try_new(BTreeMap::from([
            (ResourceType::Oil, 2),
            (ResourceType::Aluminium, 1),
        ]))
        .expect("strategic resources");
        let state = state(
            &map,
            &actor,
            city,
            TechnologyKey::ALL.map(TechnologyKey::domain),
            BTreeMap::from([(actor.clone(), stockpile)]),
        );
        let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());

        let QueryResult::ProductionOptions(options) = GameEngine::query(
            &state,
            context,
            GameQuery::ProductionOptions(ProductionOptionsQuery::new(9, &city_id)),
        )
        .expect("fully unlocked production options") else {
            panic!("production options result")
        };
        assert!(
            options
                .buildings()
                .iter()
                .all(|option| option.is_available())
        );
        assert!(
            options
                .units()
                .iter()
                .all(|option| option.option().is_available())
        );
        assert!(options.units().iter().any(|option| {
            !option.resource_options().is_empty()
                && !option.affordable_resource_option_indices().is_empty()
        }));
        let terrain_wonder = if center_terrain == TerrainType::Desert {
            WonderType::Petra
        } else {
            WonderType::SvalbardSeedVault
        };
        assert!(
            options
                .wonders()
                .iter()
                .find(|option| option.target() == CityProductionTarget::Wonder(terrain_wonder))
                .expect("terrain wonder")
                .is_available()
        );
        for option in options.specializations() {
            let required = match option.specialization() {
                CitySpecializationType::Growth => CityBuildingType::Granary,
                CitySpecializationType::Industry => CityBuildingType::Workshop,
                CitySpecializationType::Commerce => CityBuildingType::MerchantHall,
                CitySpecializationType::Science => CityBuildingType::Archive,
                CitySpecializationType::Military => CityBuildingType::Barracks,
            };
            assert_eq!(option.required_building(), required);
            assert_eq!(
                option.rejection(),
                Some(CommandRejectionCode::CitySpecializationMissingBuilding)
            );
        }
    }
}

#[test]
fn production_rejections_cover_revision_control_presence_stockpile_and_coast() {
    let map = map();
    let actor = player();
    let city_id = CityId::new("capital").expect("city id");
    let city = City::new(city_id.clone(), actor.clone(), HexCoord::new(2, 2), []);
    let state = state(
        &map,
        &actor,
        city,
        TechnologyKey::ALL.map(TechnologyKey::domain),
        BTreeMap::new(),
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let stale_error = GameEngine::query(
        &state,
        context,
        GameQuery::ProductionOptions(ProductionOptionsQuery::new(8, &city_id)),
    )
    .expect_err("stale query");
    assert_eq!(
        stale_error.code(),
        CommandRejectionCode::StaleRevision.as_str()
    );
    let missing_id = CityId::new("missing").expect("city id");
    let missing = GameEngine::query(
        &state,
        context,
        GameQuery::ProductionOptions(ProductionOptionsQuery::new(9, &missing_id)),
    )
    .expect_err("missing city");
    assert_eq!(missing.code(), CommandRejectionCode::CityNotFound.as_str());
    let foreign = PlayerId::new("foreign").expect("player");
    let foreign_context = EngineContext::canonical(&foreign, &map, RulesetDefinition::standard());
    let uncontrolled = GameEngine::query(
        &state,
        foreign_context,
        GameQuery::ProductionOptions(ProductionOptionsQuery::new(9, &city_id)),
    )
    .expect_err("uncontrolled city");
    assert_eq!(
        uncontrolled.code(),
        CommandRejectionCode::CityNotControlled.as_str()
    );

    let QueryResult::ProductionOptions(options) = GameEngine::query(
        &state,
        context,
        GameQuery::ProductionOptions(ProductionOptionsQuery::new(9, &city_id)),
    )
    .expect("production options") else {
        panic!("production options result")
    };
    for (unit, rejection) in [
        (
            UnitKind::Cavalry,
            CommandRejectionCode::UnitProductionRequiresResource,
        ),
        (
            UnitKind::Tank,
            CommandRejectionCode::UnitProductionMissingStrategicResource,
        ),
        (
            UnitKind::ScoutShip,
            CommandRejectionCode::UnitProductionRequiresCoast,
        ),
    ] {
        assert_eq!(
            options
                .units()
                .iter()
                .find(|option| option.option().target() == CityProductionTarget::Unit(unit))
                .expect("unit option")
                .option()
                .rejection(),
            Some(rejection)
        );
        let rejected = GameEngine::apply_player_owned(
            state.clone(),
            context,
            PlayerCommand::StartUnitProduction(StartUnitProductionCommand::new(
                9, &city_id, unit, None,
            )),
        )
        .expect("unit production rejection");
        assert_eq!(rejected.rejection().expect("rejection").code(), rejection);
    }

    let rejected = ProductionError::from(CommandRejectionCode::CityNotControlled);
    assert_eq!(
        rejected.code(),
        CommandRejectionCode::CityNotControlled.as_str()
    );
    assert_eq!(rejected.to_string(), "city_not_controlled");
    let invalid = ProductionError::InvalidState("invalid production fixture".into());
    assert_eq!(invalid.code(), "production_state_invalid");
    assert_eq!(invalid.to_string(), "invalid production fixture");
}

#[test]
fn starting_from_stored_overflow_applies_the_reviewed_rollover_cap() {
    let map = map();
    let actor = player();
    for (overflow, expected_investment) in [(2, 2), (20, 4)] {
        let city_id = CityId::new(format!("capital-{overflow}")).expect("city id");
        let city = City::new(city_id.clone(), actor.clone(), HexCoord::new(2, 2), [])
            .try_with_production(None, overflow)
            .expect("overflow");
        let state = state(&map, &actor, city, [], BTreeMap::new());
        let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
        let started = GameEngine::apply_player_owned(
            state,
            context,
            PlayerCommand::StartBuilding(StartBuildingCommand::new(
                9,
                &city_id,
                CityBuildingType::Granary,
            )),
        )
        .expect("start building");
        let updated = started.state().city(&city_id).expect("city");
        assert_eq!(
            updated
                .production_queue()
                .expect("queue")
                .invested_production(),
            expected_investment
        );
        assert_eq!(updated.production_overflow(), 0);
    }
}

#[test]
fn existing_and_queued_units_enforce_supply_before_accepting_another_unit() {
    let map = map();
    let actor = player();
    let city_id = CityId::new("capital").expect("city id");
    let capital = City::new(city_id.clone(), actor.clone(), HexCoord::new(2, 2), []);
    let queued = CityProductionQueue::try_new(
        CityProductionTarget::Unit(UnitKind::Warrior),
        0,
        StrategicResourceStockpile::default(),
    )
    .expect("unit queue");
    let second = City::new(
        CityId::new("second").expect("city id"),
        actor.clone(),
        HexCoord::new(4, 4),
        [],
    )
    .try_with_production(Some(queued), 0)
    .expect("queued city");
    let project = CityProductionQueue::try_new(
        CityProductionTarget::Project(CityProjectType::Wealth),
        0,
        StrategicResourceStockpile::default(),
    )
    .expect("project queue");
    let third = City::new(
        CityId::new("third").expect("city id"),
        actor.clone(),
        HexCoord::new(0, 4),
        [],
    )
    .try_with_production(Some(project), 0)
    .expect("project city");
    let units = (0..11)
        .map(|index| {
            Unit::builder(
                UnitId::new(format!("unit-{index}")).expect("unit id"),
                actor.clone(),
                UnitKind::Warrior,
                format!("Unit {index}"),
                HexCoord::new(index % 5, index / 5),
                MovementUnits::ZERO,
            )
            .build()
            .expect("unit")
        })
        .collect();
    let state = state_with(
        &map,
        &actor,
        vec![capital, second, third],
        units,
        TechnologyKey::ALL.map(TechnologyKey::domain),
        BTreeMap::new(),
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());

    let QueryResult::ProductionOptions(options) = GameEngine::query(
        &state,
        context,
        GameQuery::ProductionOptions(ProductionOptionsQuery::new(9, &city_id)),
    )
    .expect("production options") else {
        panic!("production options result")
    };
    assert_eq!(
        options
            .units()
            .iter()
            .find(|option| {
                option.option().target() == CityProductionTarget::Unit(UnitKind::Warrior)
            })
            .expect("warrior option")
            .option()
            .rejection(),
        Some(CommandRejectionCode::UnitSupplyLimitReached)
    );
}

#[test]
fn another_city_wonder_queue_blocks_the_player_wide_wonder_slot() {
    let map = map();
    let actor = player();
    let city_id = CityId::new("capital").expect("city id");
    let capital = City::new(city_id.clone(), actor.clone(), HexCoord::new(2, 2), []);
    let queued = CityProductionQueue::try_new(
        CityProductionTarget::Wonder(WonderType::GreatLibrary),
        0,
        StrategicResourceStockpile::default(),
    )
    .expect("wonder queue");
    let second = City::new(
        CityId::new("second").expect("city id"),
        actor.clone(),
        HexCoord::new(4, 4),
        [],
    )
    .try_with_production(Some(queued), 0)
    .expect("queued city");
    let state = state_with(
        &map,
        &actor,
        vec![capital, second],
        Vec::new(),
        TechnologyKey::ALL.map(TechnologyKey::domain),
        BTreeMap::new(),
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());

    let rejected = GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::StartWonder(StartWonderCommand::new(
            9,
            &city_id,
            WonderType::GreatLibrary,
        )),
    )
    .expect("wonder rejection");
    assert_eq!(
        rejected.rejection().expect("rejection").code(),
        CommandRejectionCode::WonderNotAvailable
    );
}

#[test]
fn invalid_supply_arithmetic_fails_closed_as_an_engine_error() {
    let map = map();
    let actor = player();
    let city_id = CityId::new("overflow-city").expect("city id");
    let city = City::builder(
        city_id.clone(),
        actor.clone(),
        "Overflow City",
        HexCoord::new(2, 2),
    )
    .with_progression(i64::MAX, 0, 6, 2)
    .build()
    .expect("large city");
    let state = state(&map, &actor, city, [], BTreeMap::new());
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());

    let error = GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::StartUnitProduction(StartUnitProductionCommand::new(
            9,
            &city_id,
            UnitKind::Warrior,
            None,
        )),
    )
    .expect_err("overflow must fail closed");
    assert!(matches!(
        error,
        CanonicalEngineError::Production(ProductionError::InvalidState(_))
    ));
}
