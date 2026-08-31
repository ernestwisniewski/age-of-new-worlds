//! Movement-logistics acceptance tests.

use std::collections::BTreeMap;

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    ArmyTroop, City, CityId, FogOfWar, GameMode, GameState, HexCoord, MatchIdentity,
    MatchLifecycle, MatchRules, MerchantTradeRoute, MovementStep, MovementUnits, Participant,
    PlayerCountry, PlayerFog, PlayerId, PlayerKind, PlayerTurnState, QueuedMovePath, StateRevision,
    TroopKind, TurnLifecycle, Unit, UnitId, UnitKind, UnitOccupancyPolicy, UnitPosture,
};
use aonw_engine::{
    AssignMerchantTradeRouteCommand, AutoExploreUnitCommand, CommandRejectionCode,
    DetachTroopCommand, DomainEvent, EngineContext, ExecutionEvidence, GameEngine, GameQuery,
    LogisticsExecution, MoveMerchantToCityCommand, PlayerCommand, QueryResult, TurnCommand,
    UnitLogisticsOptionsQuery,
};
#[path = "movement_logistics/manifest.rs"]
mod manifest;
#[path = "movement_logistics/support.rs"]
mod support;

use support::*;

#[test]
fn rejection_code_surface_is_total_and_stable() {
    let mut values = std::collections::BTreeSet::new();
    for code in CommandRejectionCode::ALL {
        assert_eq!(code.to_string(), code.as_str());
        assert!(values.insert(code.as_str()));
    }
    assert_eq!(values.len(), CommandRejectionCode::ALL.len());
}

#[test]
fn auto_explore_without_fog_is_deterministic_and_bounded() {
    let map = map(7, 5);
    let actor = player("player-1");
    let scout_id = unit_id("scout-1");
    let state = state(
        &map,
        vec![unit(
            "scout-1",
            &actor,
            UnitKind::Scout,
            HexCoord::new(3, 2),
        )],
        Vec::new(),
        FogOfWar::default(),
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let query = || {
        GameEngine::query(
            &state,
            context,
            GameQuery::UnitLogisticsOptions(UnitLogisticsOptionsQuery::new(9, &scout_id)),
        )
        .expect("options")
    };
    let QueryResult::UnitLogisticsOptions(first) = query() else {
        panic!("logistics options")
    };
    let QueryResult::UnitLogisticsOptions(second) = query() else {
        panic!("logistics options")
    };
    let first = first.auto_explore().expect("auto explore option");
    let second = second.auto_explore().expect("auto explore option");
    assert_eq!(first, second);
    assert_ne!(first.target(), HexCoord::new(3, 2));
    let tile_count = u64::try_from(map.bounds().tile_count()).expect("tile count");
    assert!(first.search_metrics().expanded_tiles() <= tile_count);
    assert!(first.search_metrics().examined_edges() <= tile_count.saturating_mul(6));

    let transition = GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::AutoExploreUnit(AutoExploreUnitCommand::new(9, &scout_id)),
    )
    .expect("auto explore");
    assert!(transition.is_accepted());
    assert!(matches!(
        transition.events().first(),
        Some(DomainEvent::AutoExplorePlanned(_))
    ));
    assert_eq!(
        transition.state().unit(&scout_id).expect("scout").posture(),
        UnitPosture::AutoExploring
    );
}

#[test]
fn merchant_routes_are_engine_planned_and_allow_owned_city_stacking() {
    let map = map(6, 3);
    let actor = player("player-1");
    let merchant_id = unit_id("merchant-1");
    let destination_id = city_id("city-b");
    let origin = city("city-a", &actor, HexCoord::new(0, 1));
    let destination = city("city-b", &actor, HexCoord::new(5, 1));
    let destination_center = destination.center();
    let state = state(
        &map,
        vec![
            unit("merchant-1", &actor, UnitKind::Merchant, origin.center()),
            unit(
                "city-guard",
                &actor,
                UnitKind::Warrior,
                destination.center(),
            ),
        ],
        vec![origin, destination],
        FogOfWar::default(),
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let assigned = GameEngine::apply_player_owned(
        state.clone(),
        context,
        PlayerCommand::AssignMerchantTradeRoute(AssignMerchantTradeRouteCommand::new(
            9,
            &merchant_id,
            &destination_id,
        )),
    )
    .expect("assign route");
    assert!(
        assigned.is_accepted(),
        "merchant route rejected: {:?}",
        assigned.rejection().map(aonw_engine::DomainRejection::code)
    );
    let route = assigned
        .state()
        .unit(&merchant_id)
        .expect("merchant")
        .merchant_trade_route()
        .expect("route");
    assert_eq!(route.destination_city_id(), &destination_id);
    assert_eq!(route.transport_network_fingerprint(), "");
    assert!(matches!(
        assigned.evidence(),
        Some(ExecutionEvidence::Logistics(
            LogisticsExecution::MerchantRouteAssigned { .. }
        ))
    ));

    let queued = GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::MoveMerchantToCity(MoveMerchantToCityCommand::new(
            9,
            &merchant_id,
            &destination_id,
        )),
    )
    .expect("queue merchant travel");
    assert!(queued.is_accepted());
    let merchant = queued.state().unit(&merchant_id).expect("merchant");
    assert_eq!(
        merchant.queued_path().expect("queued path").target(),
        destination_center
    );
    assert!(merchant.merchant_trade_route().is_none());
}

#[test]
fn merchant_rejection_precedence_is_revision_then_control_then_kind() {
    let map = map(3, 2);
    let actor = player("player-1");
    let foreign = player("player-2");
    let unit_id = unit_id("foreign-warrior");
    let destination_id = city_id("missing");
    let state = state(
        &map,
        vec![unit(
            "foreign-warrior",
            &foreign,
            UnitKind::Warrior,
            HexCoord::new(0, 0),
        )],
        vec![city("actor-city", &actor, HexCoord::new(2, 1))],
        FogOfWar::default(),
    );
    let apply = |revision| {
        GameEngine::apply_player_owned(
            state.clone(),
            EngineContext::canonical(&actor, &map, RulesetDefinition::standard()),
            PlayerCommand::MoveMerchantToCity(MoveMerchantToCityCommand::new(
                revision,
                &unit_id,
                &destination_id,
            )),
        )
        .expect("rejection")
    };
    assert_eq!(
        apply(8).rejection().expect("stale").code(),
        CommandRejectionCode::StaleRevision
    );
    assert_eq!(
        apply(9).rejection().expect("control").code(),
        CommandRejectionCode::UnitNotControlled
    );
}

#[test]
fn detachment_preserves_army_count_and_chooses_next_free_identity() {
    let map = map(4, 4);
    let actor = player("player-1");
    let source_id = unit_id("army-1");
    let collision = unit(
        "army-1_archer_1",
        &actor,
        UnitKind::Archer,
        HexCoord::new(3, 3),
    );
    let source = Unit::builder(
        source_id.clone(),
        actor.clone(),
        UnitKind::Commander,
        "army",
        HexCoord::new(1, 1),
        MovementUnits::new(10),
    )
    .with_army([
        ArmyTroop::new(TroopKind::Archer, 2),
        ArmyTroop::new(TroopKind::Warrior, 1),
    ])
    .build()
    .expect("army");
    let fog = FogOfWar::try_new([PlayerFog::new(
        actor.clone(),
        [HexCoord::new(1, 0), HexCoord::new(2, 1)],
        [HexCoord::new(1, 1)],
    )])
    .expect("fog");
    let state = state(&map, vec![source, collision], Vec::new(), fog);
    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&actor, &map, RulesetDefinition::standard()),
        PlayerCommand::DetachTroop(DetachTroopCommand::new(9, &source_id, TroopKind::Archer)),
    )
    .expect("detach");
    assert!(transition.is_accepted());
    let source = transition.state().unit(&source_id).expect("source");
    assert_eq!(
        source.army(),
        [
            ArmyTroop::new(TroopKind::Archer, 1),
            ArmyTroop::new(TroopKind::Warrior, 1)
        ]
    );
    let detached_id = unit_id("army-1_archer_2");
    let detached = transition.state().unit(&detached_id).expect("detached");
    assert_eq!(detached.kind(), UnitKind::Archer);
    assert_eq!(detached.position(), HexCoord::new(2, 1));
    assert!(matches!(
        transition.evidence(),
        Some(ExecutionEvidence::Logistics(
            LogisticsExecution::TroopDetached { .. }
        ))
    ));
}

#[test]
fn merchant_options_and_rejections_cover_the_ruleset() {
    let map = map(6, 3);
    let actor = player("player-1");
    let foreign = player("player-2");
    let merchant_id = unit_id("merchant-1");
    let origin = city("city-a", &actor, HexCoord::new(0, 1));
    let destination = city("city-b", &actor, HexCoord::new(5, 1));
    let foreign_city = city("city-c", &foreign, HexCoord::new(5, 2));
    let state = state(
        &map,
        vec![
            unit("merchant-1", &actor, UnitKind::Merchant, origin.center()),
            unit("warrior-1", &actor, UnitKind::Warrior, HexCoord::new(2, 2)),
            unit(
                "foreign-1",
                &foreign,
                UnitKind::Warrior,
                HexCoord::new(4, 2),
            ),
        ],
        vec![origin.clone(), destination.clone(), foreign_city.clone()],
        FogOfWar::default(),
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let QueryResult::UnitLogisticsOptions(options) = GameEngine::query(
        &state,
        context,
        GameQuery::UnitLogisticsOptions(UnitLogisticsOptionsQuery::new(9, &merchant_id)),
    )
    .expect("merchant options") else {
        panic!("logistics options")
    };
    assert_eq!(options.merchant_route_destinations().len(), 1);
    assert_eq!(options.merchant_travel_destinations().len(), 1);

    let rejection = |command| {
        GameEngine::apply_player_owned(state.clone(), context, command)
            .expect("merchant rejection")
            .rejection()
            .expect("rejected")
            .code()
    };
    assert_eq!(
        rejection(PlayerCommand::AssignMerchantTradeRoute(
            AssignMerchantTradeRouteCommand::new(9, &merchant_id, origin.id()),
        )),
        CommandRejectionCode::DestinationCityIsOrigin
    );
    assert_eq!(
        rejection(PlayerCommand::MoveMerchantToCity(
            MoveMerchantToCityCommand::new(9, &merchant_id, origin.id()),
        )),
        CommandRejectionCode::DestinationCityIsCurrent
    );
    assert_eq!(
        rejection(PlayerCommand::AssignMerchantTradeRoute(
            AssignMerchantTradeRouteCommand::new(9, &merchant_id, foreign_city.id()),
        )),
        CommandRejectionCode::DestinationCityNotControlled
    );
    let missing_city = city_id("missing-city");
    assert_eq!(
        rejection(PlayerCommand::MoveMerchantToCity(
            MoveMerchantToCityCommand::new(9, &merchant_id, &missing_city),
        )),
        CommandRejectionCode::DestinationCityNotFound
    );
    let warrior_id = unit_id("warrior-1");
    assert_eq!(
        rejection(PlayerCommand::MoveMerchantToCity(
            MoveMerchantToCityCommand::new(9, &warrior_id, destination.id()),
        )),
        CommandRejectionCode::UnitNotMerchant
    );
    let missing_unit = unit_id("missing-unit");
    assert_eq!(
        rejection(PlayerCommand::MoveMerchantToCity(
            MoveMerchantToCityCommand::new(9, &missing_unit, destination.id()),
        )),
        CommandRejectionCode::UnitNotFound
    );
}

#[test]
fn automation_and_detachment_fail_closed_on_invalid_state() {
    let map = map(3, 3);
    let actor = player("player-1");
    let scout_id = unit_id("scout-1");
    let warrior_id = unit_id("warrior-1");
    let army_id = unit_id("army-1");
    let explored = (0..3)
        .flat_map(|row| (0..3).map(move |col| HexCoord::new(col, row)))
        .collect::<Vec<_>>();
    let fog = FogOfWar::try_new([PlayerFog::new(actor.clone(), explored.clone(), explored)])
        .expect("fog");
    let army = Unit::builder(
        army_id.clone(),
        actor.clone(),
        UnitKind::Commander,
        "army",
        HexCoord::new(1, 1),
        MovementUnits::new(10),
    )
    .with_army([ArmyTroop::new(TroopKind::Archer, 1)])
    .build()
    .expect("army");
    let state = state(
        &map,
        vec![
            unit("scout-1", &actor, UnitKind::Scout, HexCoord::new(0, 0)),
            unit("warrior-1", &actor, UnitKind::Warrior, HexCoord::new(2, 2)),
            army,
        ],
        Vec::new(),
        fog,
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let apply_auto = |unit_id| {
        GameEngine::apply_player_owned(
            state.clone(),
            context,
            PlayerCommand::AutoExploreUnit(AutoExploreUnitCommand::new(9, unit_id)),
        )
        .expect("auto rejection")
        .rejection()
        .expect("rejected")
        .code()
    };
    assert_eq!(apply_auto(&warrior_id), CommandRejectionCode::UnitNotScout);
    assert_eq!(
        apply_auto(&scout_id),
        CommandRejectionCode::AutoExploreNoTarget
    );

    let QueryResult::UnitLogisticsOptions(options) = GameEngine::query(
        &state,
        context,
        GameQuery::UnitLogisticsOptions(UnitLogisticsOptionsQuery::new(9, &army_id)),
    )
    .expect("detachment options") else {
        panic!("logistics options")
    };
    assert_eq!(options.detachments().len(), 1);
    let rejected = GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::DetachTroop(DetachTroopCommand::new(9, &army_id, TroopKind::Warrior)),
    )
    .expect("detach rejection");
    assert_eq!(
        rejected.rejection().expect("rejection").code(),
        CommandRejectionCode::TroopNotAvailable
    );
}

#[test]
fn turn_processors_advance_queued_trade_and_auto_units_together() {
    let map = map(7, 4);
    let actor = player("player-1");
    let origin = city("city-a", &actor, HexCoord::new(0, 1));
    let destination = city("city-b", &actor, HexCoord::new(6, 1));
    let queued = QueuedMovePath::try_new(
        HexCoord::new(3, 0),
        vec![step(1, 0, 0, 0), step(2, 0, 2, 2), step(3, 0, 2, 4)],
    )
    .expect("queued path");
    let warrior = Unit::builder(
        unit_id("warrior-1"),
        actor.clone(),
        UnitKind::Warrior,
        "warrior",
        HexCoord::new(1, 0),
        MovementUnits::new(1),
    )
    .with_queued_path(Some(queued))
    .build()
    .expect("queued warrior");
    let route = MerchantTradeRoute::new(
        origin.id().clone(),
        destination.id().clone(),
        Vec::<MovementStep>::new(),
        "",
    );
    let merchant = Unit::builder(
        unit_id("merchant-1"),
        actor.clone(),
        UnitKind::Merchant,
        "merchant",
        origin.center(),
        MovementUnits::new(1),
    )
    .with_merchant_trade_route(Some(route))
    .build()
    .expect("merchant");
    let scout =
        unit("scout-1", &actor, UnitKind::Scout, HexCoord::new(3, 2)).after_auto_explore_started();
    let fog = FogOfWar::try_new([PlayerFog::new(
        actor.clone(),
        [],
        [warrior.position(), merchant.position(), scout.position()],
    )])
    .expect("fog");
    let state = state(
        &map,
        vec![warrior, merchant, scout],
        vec![origin, destination],
        fog,
    );
    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&actor, &map, RulesetDefinition::standard()),
        PlayerCommand::SubmitTurn(TurnCommand::new(9, &actor)),
    )
    .expect("turn transition");
    assert!(transition.is_accepted());
    assert!(transition.events().len() >= 3);
    assert!(matches!(
        transition.events().last(),
        Some(DomainEvent::TurnEnded(_))
    ));
    assert!(
        transition.events()[..transition.events().len() - 1]
            .iter()
            .all(|event| !matches!(event, DomainEvent::TurnEnded(_)))
    );
    let Some(ExecutionEvidence::TurnKernel(evidence)) = transition.evidence() else {
        panic!("turn evidence")
    };
    assert_eq!(evidence.reset_unit_ids().len(), 3);
    assert!(!evidence.movement_executions().is_empty());
}
