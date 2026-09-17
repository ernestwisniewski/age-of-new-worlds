use super::*;

#[test]
fn catalog_distinguishes_built_locked_and_site_blocked_targets() {
    let map = map();
    let actor = player();
    let id = CityId::new("capital").expect("city");
    let city = City::builder(id.clone(), actor.clone(), "Capital", HexCoord::new(2, 2))
        .with_buildings([CityBuildingType::Granary])
        .build()
        .expect("city");
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let state = state(
        &map,
        &actor,
        city,
        [TechnologyId::Navigation],
        BTreeMap::new(),
    );
    let options = query(&state, context, &id);
    let granary = building(&options, CityBuildingType::Granary);
    let workshop = building(&options, CityBuildingType::Workshop);
    let harbor = building(&options, CityBuildingType::Port);
    assert_eq!(granary.rejection(), workshop.rejection());
    assert_eq!(workshop.rejection(), harbor.rejection());
    assert!(granary.availability().completed_in_city());
    assert!(granary.availability().technology_unlocked());
    assert_eq!(granary.availability().required_technology(), None);
    assert!(!workshop.availability().completed_in_city());
    assert!(!workshop.availability().technology_unlocked());
    assert_eq!(
        workshop.availability().required_technology(),
        Some(TechnologyId::Craftsmanship)
    );
    assert!(!harbor.availability().completed_in_city());
    assert!(harbor.availability().technology_unlocked());
    assert_eq!(
        harbor.availability().required_technology(),
        Some(TechnologyId::Navigation)
    );
}

#[test]
fn research_unlock_changes_catalog_and_accepted_command_together() {
    let map = map();
    let actor = player();
    let id = CityId::new("capital").expect("city");
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    for unlocked in [false, true] {
        let city = City::new(id.clone(), actor.clone(), HexCoord::new(2, 2), []);
        let state = state(
            &map,
            &actor,
            city,
            unlocked.then_some(TechnologyId::Craftsmanship),
            BTreeMap::new(),
        );
        let options = query(&state, context, &id);
        let workshop = building(&options, CityBuildingType::Workshop);
        assert_eq!(workshop.availability().technology_unlocked(), unlocked);
        let result = GameEngine::apply_player_owned(
            state,
            context,
            PlayerCommand::StartBuilding(StartBuildingCommand::new(
                9,
                &id,
                CityBuildingType::Workshop,
            )),
        )
        .expect("command");
        assert_eq!(result.is_accepted(), unlocked);
    }
}

#[test]
fn unit_project_and_wonder_availability_uses_only_owner_capabilities_and_local_completion() {
    let map = map();
    let actor = player();
    let id = CityId::new("capital").expect("city");
    let city = City::builder(id.clone(), actor.clone(), "Capital", HexCoord::new(2, 2))
        .with_wonders([WonderType::GreatLibrary])
        .build()
        .expect("city");
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let state = state(&map, &actor, city, [TechnologyId::Writing], BTreeMap::new());
    let options = query(&state, context, &id);
    for option in options.units() {
        assert!(!option.option().availability().completed_in_city());
    }
    let warrior = options
        .units()
        .iter()
        .find(|option| option.option().target() == CityProductionTarget::Unit(UnitKind::Warrior))
        .expect("warrior")
        .option();
    assert!(warrior.availability().technology_unlocked());
    assert_eq!(warrior.availability().required_technology(), None);
    for option in options.projects() {
        assert!(option.availability().technology_unlocked());
        assert!(!option.availability().completed_in_city());
        assert_eq!(option.availability().required_technology(), None);
    }
    for option in options.wonders() {
        assert_eq!(
            option.availability().completed_in_city(),
            option.target() == CityProductionTarget::Wonder(WonderType::GreatLibrary)
        );
    }
}

fn query(
    state: &GameState,
    context: EngineContext<'_>,
    id: &CityId,
) -> aonw_engine::ProductionOptions {
    let QueryResult::ProductionOptions(options) = GameEngine::query(
        state,
        context,
        GameQuery::ProductionOptions(ProductionOptionsQuery::new(9, id)),
    )
    .expect("options") else {
        panic!("options")
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
