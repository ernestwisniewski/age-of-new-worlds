use super::*;

#[test]
fn policy_confirms_and_selects_pending_worker_improvements() {
    for improvement in [Some(FieldImprovementKind::Farm), None] {
        let world = World::new("ai-policy-worker-pending", 3, 3);
        let worker = Unit::builder(
            UnitId::new("worker").expect("worker id"),
            world.actor.clone(),
            UnitKind::Worker,
            "worker",
            HexCoord::new(1, 1),
            MovementUnits::new(10),
        )
        .with_worker_build_charges(1)
        .build()
        .expect("worker");
        let interaction = InteractionState::new(
            None,
            Some(PendingInteraction::WorkerActionSelection {
                owner_player_id: world.actor.clone(),
                unit_id: worker.id().clone(),
                improvement,
            }),
        );
        let capital = City::builder(
            CityId::new("capital").expect("city id"),
            world.actor.clone(),
            "capital",
            HexCoord::new(0, 1),
        )
        .with_controlled_hexes([HexCoord::new(1, 1)])
        .build()
        .expect("capital");
        let research = ResearchState::try_new([
            (
                world.actor.clone(),
                PlayerResearchState::try_new(
                    [TechnologyId::Agriculture],
                    Some(TechnologyId::Craftsmanship),
                    [],
                    0,
                )
                .expect("research"),
            ),
            (world.foreign.clone(), PlayerResearchState::default()),
        ])
        .expect("research state");
        let state = world
            .state([worker], [capital])
            .with_knowledge(KnowledgeState::new(research, WonderRegistry::default()))
            .with_interaction(interaction)
            .try_build()
            .expect("state");
        assert_family_executes(world, state, PlannedCommandFamily::Worker);
    }
}

#[test]
fn policy_cancels_a_pending_unit_targeting_context() {
    for kind in 0..3 {
        let world = World::new("ai-policy-unit-pending", 3, 1);
        let scout = unit("scout", &world.actor, UnitKind::Scout, HexCoord::new(1, 0));
        let scout = if kind == 0 {
            scout.after_skip_turn()
        } else {
            scout
        };
        let pending = match kind {
            0 => PendingInteraction::UnitTurnSkip {
                owner_player_id: world.actor.clone(),
                unit_id: scout.id().clone(),
                restore_movement: MovementUnits::new(10),
            },
            1 => PendingInteraction::AttackTargeting {
                owner_player_id: world.actor.clone(),
                unit_id: scout.id().clone(),
                defender: None,
            },
            _ => PendingInteraction::CommanderMergeSelection {
                owner_player_id: world.actor.clone(),
                unit_id: scout.id().clone(),
            },
        };
        let state = world
            .state([scout], [])
            .with_interaction(InteractionState::new(None, Some(pending)))
            .try_build()
            .expect("state");
        assert_family_executes(world, state, PlannedCommandFamily::Movement);
    }
}

#[test]
fn policy_routes_both_pending_merchant_workflows() {
    for route in [true, false] {
        let world = World::new("ai-policy-merchant-pending", 5, 1);
        let origin = if route {
            HexCoord::new(0, 0)
        } else {
            HexCoord::new(2, 0)
        };
        let merchant = unit("merchant", &world.actor, UnitKind::Merchant, origin);
        let pending = if route {
            PendingInteraction::MerchantTradeRouteSelection {
                owner_player_id: world.actor.clone(),
                unit_id: merchant.id().clone(),
            }
        } else {
            PendingInteraction::MerchantMoveToCitySelection {
                owner_player_id: world.actor.clone(),
                unit_id: merchant.id().clone(),
            }
        };
        let state = world
            .state(
                [merchant],
                [
                    producing_city("west", &world.actor, HexCoord::new(0, 0)),
                    producing_city("east", &world.actor, HexCoord::new(4, 0)),
                ],
            )
            .with_interaction(InteractionState::new(None, Some(pending)))
            .try_build()
            .expect("state");
        assert_family_executes(world, state, PlannedCommandFamily::Logistics);
    }
}

#[test]
fn policy_uses_non_pending_merchant_routes_and_cancels_an_empty_pending_choice() {
    for origin in [HexCoord::new(0, 0), HexCoord::new(2, 0)] {
        let world = World::new("ai-policy-merchant", 5, 1);
        let merchant = unit("merchant", &world.actor, UnitKind::Merchant, origin);
        let state = world
            .state(
                [merchant],
                [
                    producing_city("west", &world.actor, HexCoord::new(0, 0)),
                    producing_city("east", &world.actor, HexCoord::new(4, 0)),
                ],
            )
            .try_build()
            .expect("state");
        assert_family_executes(world, state, PlannedCommandFamily::Logistics);
    }

    let world = World::new("ai-policy-merchant-empty", 2, 1);
    let merchant = unit(
        "merchant",
        &world.actor,
        UnitKind::Merchant,
        HexCoord::new(0, 0),
    );
    let pending = PendingInteraction::MerchantTradeRouteSelection {
        owner_player_id: world.actor.clone(),
        unit_id: merchant.id().clone(),
    };
    let state = world
        .state(
            [merchant],
            [city("only", &world.actor, HexCoord::new(0, 0))],
        )
        .with_interaction(InteractionState::new(None, Some(pending)))
        .try_build()
        .expect("state");
    assert_family_executes(world, state, PlannedCommandFamily::Movement);
}

#[test]
fn policy_resolves_a_pending_research_choice() {
    let world = World::new("ai-policy-research-pending", 2, 1);
    let research = ResearchState::try_new([
        (
            world.actor.clone(),
            PlayerResearchState::try_new([], None, [], 0).expect("research"),
        ),
        (world.foreign.clone(), PlayerResearchState::default()),
    ])
    .expect("research state");
    let pending = PendingInteraction::ResearchSelection {
        owner_player_id: world.actor.clone(),
    };
    let state = world
        .state([], [])
        .with_knowledge(KnowledgeState::new(research, WonderRegistry::default()))
        .with_interaction(InteractionState::new(None, Some(pending)))
        .try_build()
        .expect("state");
    assert_family_executes(world, state, PlannedCommandFamily::Research);
}

#[test]
fn persistent_city_selection_context_does_not_block_turn_completion() {
    for expansion in [false, true] {
        let world = World::new("ai-policy-city-pending", 3, 3);
        let capital = city("capital", &world.actor, HexCoord::new(1, 1));
        let pending = if expansion {
            PendingInteraction::CityExpansionSelection {
                owner_player_id: world.actor.clone(),
                city_id: capital.id().clone(),
            }
        } else {
            PendingInteraction::CityWorkedHexSelection {
                owner_player_id: world.actor.clone(),
                city_id: capital.id().clone(),
            }
        };
        let state = world
            .state([], [capital])
            .with_interaction(InteractionState::new(None, Some(pending)))
            .try_build()
            .expect("state");
        let mut runtime = LocalRuntime::default();
        runtime
            .open(OpenSession::from_state(
                world.map,
                world.rules,
                state,
                world.actor,
            ))
            .expect("open");
        let StrategicPlanningOutcome::Planned(plan) =
            StrategicPlanner.plan(&mut runtime).expect("plan")
        else {
            panic!("expected plan")
        };
        assert_ne!(plan.command().family(), PlannedCommandFamily::City);
    }
}

#[test]
fn multiplayer_policy_submits_then_waits_without_replanning() {
    let world = World::new("ai-policy-awaiting", 2, 1);
    let state = world.state([], []).try_build().expect("state");
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(
            world.map,
            world.rules,
            state,
            world.actor,
        ))
        .expect("open");
    let StrategicPlanningOutcome::Planned(plan) =
        StrategicPlanner.plan(&mut runtime).expect("end plan")
    else {
        panic!("expected end plan")
    };
    assert_eq!(plan.command().family(), PlannedCommandFamily::Turn);
    assert!(plan.execute(&mut runtime).expect("submit").is_accepted());
    assert!(matches!(
        StrategicPlanner.plan(&mut runtime).expect("awaiting"),
        StrategicPlanningOutcome::AwaitingTurn { .. }
    ));
    let report = StrategicPlanner
        .play_turn(&mut runtime, core::num::NonZeroU32::new(2).expect("budget"))
        .expect("awaiting report");
    assert!(!report.completed_turn());
    assert_eq!(report.executed_commands(), 0);
    assert!(report.family_usage().is_empty());
    assert_eq!(report.initial_stamp(), report.final_stamp());
}
