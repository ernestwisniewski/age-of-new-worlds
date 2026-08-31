use std::collections::BTreeMap;

use aonw_domain::{
    City, CityBuildingType, CityProductionQueue, CityProductionTarget, CityProjectType,
    EconomyAccountChange, KnowledgeState, PlayerResearchState, ProductionStateUpdate,
    ResearchState, StrategicResourceStockpile, TechnologyId, Unit, UnitId, UnitKind,
    WonderRegistry, WonderType,
};
use aonw_engine::{
    CommandRejectionCode, DomainEvent, EngineContext, GameEngine, PlayerCommand,
    RushProductionCommand,
};

use super::{map, player, state_with};

#[test]
fn rush_completes_building_and_spends_only_the_bounded_quote() {
    let map = map();
    let actor = player();
    let city_id = aonw_domain::CityId::new("capital").expect("city id");
    let cost = paced_building_cost(CityBuildingType::Housing);
    let queue = CityProductionQueue::try_new(
        CityProductionTarget::Building(CityBuildingType::Housing),
        cost - 1,
        StrategicResourceStockpile::default(),
    )
    .expect("queue");
    let city = City::builder(
        city_id.clone(),
        actor.clone(),
        "Capital",
        aonw_domain::HexCoord::new(2, 2),
    )
    .with_production(Some(queue), 0)
    .build()
    .expect("city");
    let state = state_with_accounts(&map, &actor, vec![city], Vec::new(), 10, None);
    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&actor, &map, aonw_content::RulesetDefinition::standard()),
        PlayerCommand::RushProduction(RushProductionCommand::new(9, &city_id)),
    )
    .expect("rush");

    assert!(transition.is_accepted());
    assert_eq!(
        transition.state().economy().player_gold().get(&actor),
        Some(&8)
    );
    let completed = transition.state().city(&city_id).expect("city");
    assert!(completed.production_queue().is_none());
    assert!(completed.buildings().contains(&CityBuildingType::Housing));
    assert_eq!(completed.max_hexes(), 8);
    assert!(matches!(
        transition.events(),
        [DomainEvent::CityBuiltBuilding(event)]
            if event.city_id() == &city_id && event.building() == CityBuildingType::Housing
    ));
}

#[test]
fn rush_advances_an_incomplete_queue_without_completion_events() {
    let map = map();
    let actor = player();
    let city_id = aonw_domain::CityId::new("capital").expect("city id");
    let cost = paced_building_cost(CityBuildingType::Housing);
    let city = queued_city(
        &city_id,
        &actor,
        CityProductionTarget::Building(CityBuildingType::Housing),
        0,
    );
    let transition = GameEngine::apply_player_owned(
        state_with_accounts(&map, &actor, vec![city], Vec::new(), 100, None),
        EngineContext::canonical(&actor, &map, aonw_content::RulesetDefinition::standard()),
        PlayerCommand::RushProduction(RushProductionCommand::new(9, &city_id)),
    )
    .expect("partial rush");

    let invested = transition
        .state()
        .city(&city_id)
        .and_then(City::production_queue)
        .expect("queue remains")
        .invested_production();
    assert!(invested > 0 && invested < cost);
    assert_eq!(
        transition.state().economy().player_gold().get(&actor),
        Some(&(100 - invested * 2))
    );
    assert!(transition.events().is_empty());
}

#[test]
fn rush_rejections_preserve_empty_project_complete_and_unaffordable_precedence() {
    let map = map();
    let actor = player();
    let city_id = aonw_domain::CityId::new("capital").expect("city id");
    let context =
        EngineContext::canonical(&actor, &map, aonw_content::RulesetDefinition::standard());
    let empty = City::new(
        city_id.clone(),
        actor.clone(),
        aonw_domain::HexCoord::new(2, 2),
        [],
    );
    let state = state_with_accounts(&map, &actor, vec![empty], Vec::new(), 10, None);
    assert_rejection(
        &GameEngine::apply_player_owned(
            state,
            context,
            PlayerCommand::RushProduction(RushProductionCommand::new(9, &city_id)),
        )
        .expect("empty rejection"),
        CommandRejectionCode::ProductionQueueEmpty,
    );

    let project = queued_city(
        &city_id,
        &actor,
        CityProductionTarget::Project(CityProjectType::Wealth),
        0,
    );
    let state = state_with_accounts(&map, &actor, vec![project], Vec::new(), 10, None);
    assert_rejection(
        &GameEngine::apply_player_owned(
            state,
            context,
            PlayerCommand::RushProduction(RushProductionCommand::new(9, &city_id)),
        )
        .expect("project rejection"),
        CommandRejectionCode::ProjectCannotBeRushed,
    );

    let cost = paced_building_cost(CityBuildingType::Granary);
    for (invested, gold) in [(cost, 10), (cost - 1, 1)] {
        let city = queued_city(
            &city_id,
            &actor,
            CityProductionTarget::Building(CityBuildingType::Granary),
            invested,
        );
        let state = state_with_accounts(&map, &actor, vec![city], Vec::new(), gold, None);
        assert_rejection(
            &GameEngine::apply_player_owned(
                state,
                context,
                PlayerCommand::RushProduction(RushProductionCommand::new(9, &city_id)),
            )
            .expect("unavailable rejection"),
            CommandRejectionCode::RushProductionUnavailable,
        );
    }
}

#[test]
fn completed_unit_uses_stable_candidate_order_and_next_identity() {
    let map = map();
    let actor = player();
    let city_id = aonw_domain::CityId::new("capital").expect("city id");
    let cost = paced_unit_cost(UnitKind::Warrior);
    let city = queued_city(
        &city_id,
        &actor,
        CityProductionTarget::Unit(UnitKind::Warrior),
        cost - 1,
    );
    let existing_id = UnitId::new("capital_warrior_1").expect("unit id");
    let existing = Unit::builder(
        existing_id,
        actor.clone(),
        UnitKind::Warrior,
        "warrior",
        city.center(),
        aonw_domain::MovementUnits::new(6),
    )
    .build()
    .expect("unit");
    let state = state_with_accounts(&map, &actor, vec![city], vec![existing], 10, None);
    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&actor, &map, aonw_content::RulesetDefinition::standard()),
        PlayerCommand::RushProduction(RushProductionCommand::new(9, &city_id)),
    )
    .expect("rush unit");

    let produced = transition
        .state()
        .units()
        .iter()
        .find(|unit| unit.id().as_str() == "capital_warrior_2")
        .expect("produced unit");
    assert_eq!(produced.position(), aonw_domain::HexCoord::new(3, 1));
    assert_eq!(produced.name(), "warrior");
    assert!(matches!(
        transition.events(),
        [DomainEvent::CityProducedUnit(event)]
            if event.produced_unit_id() == produced.id() && event.unit() == UnitKind::Warrior
    ));
}

#[test]
fn blocked_unit_spawn_keeps_complete_queue_after_spending_gold() {
    let map = map();
    let actor = player();
    let city_id = aonw_domain::CityId::new("capital").expect("city id");
    let cost = paced_unit_cost(UnitKind::Warrior);
    let city = queued_city(
        &city_id,
        &actor,
        CityProductionTarget::Unit(UnitKind::Warrior),
        cost - 1,
    );
    let occupied = std::iter::once(city.center())
        .chain(city.center().neighbors())
        .enumerate()
        .map(|(index, coordinate)| {
            Unit::builder(
                UnitId::new(format!("blocker_{index}")).expect("unit id"),
                actor.clone(),
                UnitKind::Warrior,
                "blocker",
                coordinate,
                aonw_domain::MovementUnits::new(6),
            )
            .build()
            .expect("blocking unit")
        })
        .collect::<Vec<_>>();
    let state = state_with_accounts(&map, &actor, vec![city], occupied, 10, None);
    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&actor, &map, aonw_content::RulesetDefinition::standard()),
        PlayerCommand::RushProduction(RushProductionCommand::new(9, &city_id)),
    )
    .expect("blocked spawn remains accepted");

    assert!(transition.is_accepted());
    assert!(transition.events().is_empty());
    assert_eq!(
        transition.state().economy().player_gold().get(&actor),
        Some(&8)
    );
    let queue = transition
        .state()
        .city(&city_id)
        .and_then(City::production_queue)
        .expect("complete queue remains pending");
    assert_eq!(queue.invested_production(), cost);
    assert_eq!(transition.state().units().len(), 7);
}

#[test]
fn wonder_claim_is_atomic_and_refunds_every_losing_queue() {
    let map = map();
    let actor = player();
    let host_id = aonw_domain::CityId::new("host").expect("city id");
    let loser_id = aonw_domain::CityId::new("loser").expect("city id");
    let wonder = WonderType::CentralBank;
    let cost = paced_wonder_cost(wonder);
    let host = queued_city_at(
        &host_id,
        &actor,
        aonw_domain::HexCoord::new(1, 1),
        CityProductionTarget::Wonder(wonder),
        cost - 1,
    );
    let loser = queued_city_at(
        &loser_id,
        &actor,
        aonw_domain::HexCoord::new(4, 4),
        CityProductionTarget::Wonder(wonder),
        7,
    );
    let state = state_with_accounts(&map, &actor, vec![host, loser], Vec::new(), 10, None);
    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&actor, &map, aonw_content::RulesetDefinition::standard()),
        PlayerCommand::RushProduction(RushProductionCommand::new(9, &host_id)),
    )
    .expect("rush wonder");

    assert_eq!(
        transition.state().economy().player_gold().get(&actor),
        Some(&128)
    );
    assert_eq!(
        transition
            .state()
            .wonder_registry()
            .completed_by()
            .get(&wonder),
        Some(&actor)
    );
    assert!(
        transition
            .state()
            .city(&host_id)
            .expect("host")
            .wonders()
            .contains(&wonder)
    );
    let loser = transition.state().city(&loser_id).expect("loser");
    assert!(loser.production_queue().is_none());
    assert_eq!(loser.production_overflow(), 7);
    assert!(matches!(
        transition.events(),
        [DomainEvent::CityBuiltWonder(_), DomainEvent::WonderProductionRefunded(event)]
            if event.city_id() == &loser_id && event.refunded_production() == 7
    ));
}

#[test]
fn great_library_completes_active_technology_with_ordered_event() {
    let map = map();
    let actor = player();
    let city_id = aonw_domain::CityId::new("library-city").expect("city id");
    let wonder = WonderType::GreatLibrary;
    let technology = TechnologyId::Writing;
    let city = queued_city(
        &city_id,
        &actor,
        CityProductionTarget::Wonder(wonder),
        paced_wonder_cost(wonder) - 1,
    );
    let state = state_with_accounts(&map, &actor, vec![city], Vec::new(), 10, Some(technology));
    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&actor, &map, aonw_content::RulesetDefinition::standard()),
        PlayerCommand::RushProduction(RushProductionCommand::new(9, &city_id)),
    )
    .expect("great library rush");

    let research = transition
        .state()
        .research()
        .players()
        .get(&actor)
        .expect("player research");
    assert!(research.unlocked_technology_ids().contains(&technology));
    assert_eq!(research.active_technology_id(), None);
    assert!(matches!(
        transition.events(),
        [DomainEvent::CityBuiltWonder(event), DomainEvent::TechnologyResearched(researched)]
            if event.wonder() == wonder
                && researched.player_id() == &actor
                && researched.technology() == technology
    ));
}

fn queued_city(
    id: &aonw_domain::CityId,
    owner: &aonw_domain::PlayerId,
    target: CityProductionTarget,
    invested: i64,
) -> City {
    queued_city_at(
        id,
        owner,
        aonw_domain::HexCoord::new(2, 2),
        target,
        invested,
    )
}

fn queued_city_at(
    id: &aonw_domain::CityId,
    owner: &aonw_domain::PlayerId,
    center: aonw_domain::HexCoord,
    target: CityProductionTarget,
    invested: i64,
) -> City {
    let queue =
        CityProductionQueue::try_new(target, invested, StrategicResourceStockpile::default())
            .expect("queue");
    City::builder(id.clone(), owner.clone(), id.as_str(), center)
        .with_production(Some(queue), 0)
        .build()
        .expect("city")
}

fn state_with_accounts(
    map: &aonw_content::MapDefinition,
    actor: &aonw_domain::PlayerId,
    cities: Vec<City>,
    units: Vec<Unit>,
    gold: i64,
    active: Option<TechnologyId>,
) -> aonw_domain::GameState {
    let base = state_with(map, actor, cities, units, [], BTreeMap::new());
    let economy = base
        .economy()
        .try_after_changes(
            base.match_lifecycle().identity(),
            base.bounds(),
            [EconomyAccountChange::Gold {
                player: actor.clone(),
                delta: gold,
            }],
        )
        .expect("gold");
    let research = active.map_or_else(ResearchState::default, |technology| {
        ResearchState::try_new([(
            actor.clone(),
            PlayerResearchState::try_new([], Some(technology), [], 0).expect("research"),
        )])
        .expect("research state")
    });
    let update = ProductionStateUpdate {
        revision: base.revision(),
        units: base.units().to_vec(),
        cities: base.cities().to_vec(),
        economy,
        knowledge: KnowledgeState::new(research, WonderRegistry::default()),
        fog_of_war: base.fog_of_war().clone(),
        diplomacy: base.diplomacy().clone(),
    };
    base.into_after_production(update).expect("account state")
}

fn paced_building_cost(building: CityBuildingType) -> i64 {
    let production = aonw_content::RulesetDefinition::standard().production();
    production
        .building(building)
        .and_then(|definition| {
            production.building_cost(definition.base_cost(), aonw_domain::PaceProfile::Unlimited)
        })
        .expect("building cost")
}

fn paced_unit_cost(unit: UnitKind) -> i64 {
    let production = aonw_content::RulesetDefinition::standard().production();
    production
        .unit(unit)
        .and_then(|definition| {
            production.unit_cost(definition.base_cost(), aonw_domain::PaceProfile::Unlimited)
        })
        .expect("unit cost")
}

fn paced_wonder_cost(wonder: WonderType) -> i64 {
    let production = aonw_content::RulesetDefinition::standard().production();
    production
        .wonder(wonder)
        .and_then(|definition| {
            production.building_cost(definition.base_cost(), aonw_domain::PaceProfile::Unlimited)
        })
        .expect("wonder cost")
}

fn assert_rejection(transition: &aonw_engine::DomainTransition, expected: CommandRejectionCode) {
    assert_eq!(transition.rejection().expect("rejection").code(), expected);
}
