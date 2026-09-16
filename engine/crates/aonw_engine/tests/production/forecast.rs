use super::*;

#[test]
fn forecast_preserves_queued_investment_and_caps_idle_overflow_like_start_commands() {
    let map = map();
    let actor = player();
    let id = CityId::new("capital").expect("city id");
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    for active in [false, true] {
        let queue = active.then(|| {
            CityProductionQueue::try_new(
                CityProductionTarget::Project(CityProjectType::Research),
                7,
                StrategicResourceStockpile::default(),
            )
            .expect("queue")
        });
        let city = City::builder(id.clone(), actor.clone(), "Capital", HexCoord::new(2, 2))
            .with_production(queue, 100)
            .build()
            .expect("city");
        let state = state(&map, &actor, city, [], BTreeMap::new());
        let options = options(&state, context, &id);
        let option = building(&options, CityBuildingType::Granary);
        let predicted = option.forecast();
        assert_eq!(predicted.invested_production(), if active { 7 } else { 4 });
        assert_eq!(
            predicted.estimated_turns(),
            Some(if active { 2 } else { 5 })
        );
        let started = GameEngine::apply_player_owned(
            state,
            context,
            PlayerCommand::StartBuilding(StartBuildingCommand::new(
                9,
                &id,
                CityBuildingType::Granary,
            )),
        )
        .expect("start");
        assert!(started.is_accepted());
        assert_eq!(
            started
                .state()
                .city(&id)
                .expect("city")
                .production_queue()
                .expect("queue")
                .invested_production(),
            predicted.invested_production()
        );
    }
}

#[test]
fn rates_apply_unit_technology_and_only_matching_specializations() {
    let map = map();
    let actor = player();
    let id = CityId::new("capital").expect("city id");
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    for (specialization, building_rate, worker_rate, warrior_rate) in [
        (None, 1, 2, 2),
        (Some(CitySpecializationType::Growth), 1, 3, 2),
        (Some(CitySpecializationType::Industry), 4, 4, 4),
        (Some(CitySpecializationType::Military), 2, 4, 4),
    ] {
        let city = City::new(id.clone(), actor.clone(), HexCoord::new(2, 2), [])
            .with_specialization(specialization);
        let state = state(
            &map,
            &actor,
            city,
            [TechnologyId::Logistics],
            BTreeMap::new(),
        );
        let options = options(&state, context, &id);
        assert_eq!(
            building(&options, CityBuildingType::Granary)
                .forecast()
                .production_per_turn(),
            building_rate
        );
        assert_eq!(
            unit(&options, UnitKind::Worker)
                .forecast()
                .production_per_turn(),
            worker_rate
        );
        assert_eq!(
            unit(&options, UnitKind::Warrior)
                .forecast()
                .production_per_turn(),
            warrior_rate
        );
    }
}

#[test]
fn continuous_projects_expose_output_without_a_completion_estimate() {
    let map = map();
    let actor = player();
    let id = CityId::new("capital").expect("city id");
    let city = City::new(id.clone(), actor.clone(), HexCoord::new(2, 2), [])
        .with_specialization(Some(CitySpecializationType::Science));
    let state = state(&map, &actor, city, [], BTreeMap::new());
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let options = options(&state, context, &id);
    for project in options.projects() {
        let forecast = project.forecast();
        assert_eq!(forecast.estimated_turns(), None);
        assert_eq!(forecast.project_output(), Some(1));
        assert!(!forecast.spawn_blocked());
        let expected =
            if project.target() == CityProductionTarget::Project(CityProjectType::Research) {
                2
            } else {
                1
            };
        assert_eq!(forecast.production_per_turn(), expected);
    }
}

#[test]
fn completed_unit_forecast_reports_blocked_spawn_without_disclosing_positions() {
    let map = map();
    let actor = player();
    let id = CityId::new("capital").expect("city id");
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let production = context.ruleset().production();
    let cost = production
        .unit_cost(
            production
                .unit(UnitKind::Warrior)
                .expect("unit")
                .base_cost(),
            aonw_domain::PaceProfile::Unlimited,
        )
        .expect("cost");
    for blocked in [false, true] {
        let queue = CityProductionQueue::try_new(
            CityProductionTarget::Unit(UnitKind::Warrior),
            cost,
            StrategicResourceStockpile::default(),
        )
        .expect("queue");
        let city = City::builder(id.clone(), actor.clone(), "Capital", HexCoord::new(2, 2))
            .with_production(Some(queue), 0)
            .build()
            .expect("city");
        let units = if blocked {
            std::iter::once(city.center())
                .chain(city.center().neighbors())
                .enumerate()
                .map(|(index, position)| {
                    Unit::builder(
                        UnitId::new(format!("blocker-{index}")).expect("id"),
                        actor.clone(),
                        UnitKind::Warrior,
                        "Guard",
                        position,
                        MovementUnits::new(6),
                    )
                    .build()
                    .expect("unit")
                })
                .collect()
        } else {
            Vec::new()
        };
        let state = state_with(&map, &actor, vec![city], units, [], BTreeMap::new());
        let options = options(&state, context, &id);
        let forecast = unit(&options, UnitKind::Warrior).forecast();
        assert_eq!(forecast.spawn_blocked(), blocked);
        assert_eq!(
            forecast.estimated_turns(),
            if blocked { None } else { Some(0) }
        );
        assert!(!unit(&options, UnitKind::Worker).forecast().spawn_blocked());
        assert_eq!(
            options.rush_quote().rejection(),
            Some(CommandRejectionCode::RushProductionUnavailable)
        );
    }
}

#[test]
fn forecasts_reject_foreign_cities_and_stale_revisions_before_reading_output() {
    let map = map();
    let actor = player();
    let id = CityId::new("capital").expect("city id");
    let city = City::new(id.clone(), actor.clone(), HexCoord::new(2, 2), []);
    let state = state(&map, &actor, city, [], BTreeMap::new());
    let outsider = PlayerId::new("outsider").expect("outsider");
    for (recipient, revision, rejection) in [
        (&actor, 8, CommandRejectionCode::StaleRevision),
        (&outsider, 9, CommandRejectionCode::CityNotControlled),
    ] {
        let context = EngineContext::canonical(recipient, &map, RulesetDefinition::standard());
        let result = GameEngine::query(
            &state,
            context,
            GameQuery::ProductionOptions(ProductionOptionsQuery::new(revision, &id)),
        );
        assert!(
            matches!(result, Err(aonw_engine::CanonicalQueryError::Production(ProductionError::Rejected(code))) if code == rejection)
        );
    }
}

fn options(
    state: &GameState,
    context: EngineContext<'_>,
    id: &CityId,
) -> aonw_engine::ProductionOptions {
    let QueryResult::ProductionOptions(options) = GameEngine::query(
        state,
        context,
        GameQuery::ProductionOptions(ProductionOptionsQuery::new(state.revision().get(), id)),
    )
    .expect("production options") else {
        panic!("production options");
    };
    options
}

fn building(
    options: &aonw_engine::ProductionOptions,
    kind: CityBuildingType,
) -> aonw_engine::ProductionOption {
    *options
        .buildings()
        .iter()
        .find(|option| option.target() == CityProductionTarget::Building(kind))
        .expect("building")
}

fn unit(options: &aonw_engine::ProductionOptions, kind: UnitKind) -> aonw_engine::ProductionOption {
    options
        .units()
        .iter()
        .find(|option| option.option().target() == CityProductionTarget::Unit(kind))
        .expect("unit")
        .option()
}
