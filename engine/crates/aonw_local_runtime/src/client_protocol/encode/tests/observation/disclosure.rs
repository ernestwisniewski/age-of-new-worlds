use aonw_contract_mapping::encode_recipient_evidence;
use aonw_domain::{CityId, TroopKind};
use aonw_engine::{ExecutionEvidence, LogisticsExecution};
use aonw_projection::RecipientDisclosure;

use super::{HexCoord, ScriptedDriver, budget, command_result, opened, player, unit_id};

#[test]
fn observation_admits_new_visible_entities_and_keeps_city_memories_private() {
    use aonw_domain::{City, FogOfWar, GameState, PlayerFog};
    use aonw_projection::ProjectedView;
    use std::sync::Arc;

    let (map, rules, runtime) = opened();
    let session = runtime.session_ref().expect("session");
    let state = session.state();
    let city_id = |name| CityId::new(name).expect("city");
    let mut units = state.units().to_vec();
    units.push(super::unit("arriving-ai", &player("ai"), 1));
    let next = GameState::builder(
        state.revision(),
        state.turn(),
        map.bounds(),
        rules.occupancy_policy(),
        units,
    )
    .with_match_lifecycle(state.match_lifecycle().clone())
    .with_fog_of_war(
        FogOfWar::try_new([
            PlayerFog::new(
                player("human"),
                [HexCoord::new(5, 0)],
                (0..3).map(|col| HexCoord::new(col, 0)),
            ),
            PlayerFog::new(player("ai"), [], (0..12).map(|col| HexCoord::new(col, 0))),
        ])
        .expect("fog"),
    )
    .with_cities([
        City::new(city_id("new-city"), player("ai"), HexCoord::new(1, 0), []),
        City::new(
            city_id("remembered-city"),
            player("ai"),
            HexCoord::new(5, 0),
            [],
        ),
        City::new(
            city_id("hidden-city"),
            player("ai"),
            HexCoord::new(8, 0),
            [],
        ),
    ])
    .try_build()
    .expect("new entities");
    let after = ProjectedView::try_for_recipient(&next, Arc::new(player("human")), &map, &rules)
        .expect("projection");
    assert!(
        after
            .cities()
            .iter()
            .any(|city| city.id() == &city_id("remembered-city"))
    );
    let disclosure = RecipientDisclosure::observed_transition(
        player("human"),
        session.projection(),
        &after,
        None,
    );
    assert!(disclosure.allows_unit(&unit_id("arriving-ai")));
    assert!(disclosure.allows_city(&city_id("new-city")));
    assert!(!disclosure.allows_city(&city_id("remembered-city")));
    assert!(!disclosure.allows_city(&city_id("hidden-city")));
}

#[test]
fn visible_endpoints_do_not_disclose_an_unseen_intermediate_path() {
    let (_, _, mut runtime) = super::opened_with_visibility(&[0, 1, 2, 5]);
    let mut driver = ScriptedDriver::new(1);
    driver.target = Some(5);
    let observed = runtime
        .advance_ai_turn_observed(player("ai"), budget(1), &mut driver)
        .expect("AI movement");
    let command = command_result(&observed.commands[0]);
    assert_eq!(command.events.len(), 1);
    assert!(command.evidence.is_none());
    assert_eq!(command.view_patch.upserted_units.len(), 1);
}

#[test]
fn observed_movement_into_fog_hides_the_path_and_destination_event() {
    let (_, _, mut runtime) = opened();
    let mut driver = ScriptedDriver::new(1);
    driver.target = Some(5);
    let observed = runtime
        .advance_ai_turn_observed(player("ai"), budget(1), &mut driver)
        .expect("AI movement");
    let command = command_result(&observed.commands[0]);
    assert!(command.events.is_empty());
    assert!(command.evidence.is_none());
    assert_eq!(command.view_patch.removed_unit_ids, ["visible-ai"]);
    runtime
        .handoff_hot_seat_actor(player("human"))
        .expect("human");
    assert!(
        !runtime
            .snapshot()
            .expect("view")
            .fog()
            .visible_hexes()
            .contains(&HexCoord::new(5, 0))
    );
}

#[test]
fn visible_foreign_units_do_not_disclose_private_logistics() {
    let (_, _, mut runtime) = opened();
    let observed = runtime
        .advance_ai_turn_observed(player("ai"), budget(1), &mut ScriptedDriver::new(1))
        .expect("AI");
    let viewer = &observed.commands[0].recipient_disclosure;
    assert!(viewer.allows_unit(&unit_id("visible-ai")));
    let snapshot = runtime.snapshot().expect("AI view");
    let owner = RecipientDisclosure::new(player("ai"), snapshot.units(), snapshot.cities(), None);
    let unit_id = unit_id("visible-ai");
    let origin = CityId::new("private-origin").expect("city");
    let destination = CityId::new("private-destination").expect("city");
    let cases = [
        LogisticsExecution::AutoExplore {
            unit_id: unit_id.clone(),
            target: HexCoord::new(11, 0),
            movement: None,
        },
        LogisticsExecution::MerchantRouteAssigned {
            unit_id: unit_id.clone(),
            origin_city_id: origin,
            destination_city_id: destination.clone(),
            steps: Box::new([]),
            transport_network_fingerprint: "private-network".into(),
        },
        LogisticsExecution::MerchantTravelQueued {
            unit_id: unit_id.clone(),
            destination_city_id: destination,
            steps: Box::new([]),
        },
        LogisticsExecution::TroopDetached {
            source_unit_id: unit_id,
            detached_unit_id: super::unit_id("new-troop"),
            troop_kind: TroopKind::Settler,
            destination: HexCoord::new(11, 0),
        },
    ];
    for execution in cases {
        let evidence = ExecutionEvidence::Logistics(execution);
        assert!(encode_recipient_evidence(&evidence, viewer).is_none());
        assert!(encode_recipient_evidence(&evidence, &owner).is_some());
    }
}

#[test]
fn foreign_exploration_keeps_visible_motion_without_its_private_destination() {
    let (_, _, mut runtime) = opened();
    let observed = runtime
        .advance_ai_turn_observed(player("ai"), budget(1), &mut ScriptedDriver::new(1))
        .expect("AI");
    let frame = &observed.commands[0];
    let Some(ExecutionEvidence::UnitMovement(movement)) = &frame.evidence else {
        panic!("scripted movement");
    };
    let evidence = ExecutionEvidence::Logistics(LogisticsExecution::AutoExplore {
        unit_id: movement.unit_id().clone(),
        target: HexCoord::new(11, 0),
        movement: Some(movement.clone()),
    });
    assert_eq!(
        encode_recipient_evidence(&evidence, &frame.recipient_disclosure),
        command_result(frame).evidence
    );
}
