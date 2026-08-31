//! Artifact command and turn-processing acceptance tests.

use aonw_content::RulesetDefinition;
use aonw_domain::{HexCoord, MovementUnits, StateRevision, WorldArtifactLocation};
use aonw_engine::{
    ArtifactError, CanonicalEngineError, CommandRejectionCode, DomainEvent, EngineContext,
    GameEngine, PlayerCommand, StartArtifactExcavationCommand, StoreArtifactInCityCommand,
    TradeArtifactCommand,
};

#[path = "artifact/support.rs"]
mod support;
#[path = "artifact/turn.rs"]
mod turn;

use support::*;

#[test]
fn excavation_start_is_atomic_and_emits_the_typed_event() {
    let map = map();
    let p1 = player("player-1");
    let unit_id = unit_id("scout");
    let artifact_id = artifact_id("sword");
    let state = game_state(
        vec![unit("scout", &p1, HexCoord::new(0, 0))],
        Vec::new(),
        vec![artifact(
            "sword",
            WorldArtifactLocation::Map(HexCoord::new(0, 0)),
        )],
        None,
        false,
    );

    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&p1, &map, RulesetDefinition::standard()),
        PlayerCommand::StartArtifactExcavation(StartArtifactExcavationCommand::new(9, &unit_id)),
    )
    .expect("start excavation");

    assert!(transition.is_accepted());
    assert_eq!(transition.revision(), StateRevision::new(10));
    let excavator = transition.state().unit(&unit_id).expect("excavator");
    assert_eq!(excavator.movement_units(), MovementUnits::ZERO);
    assert_eq!(
        excavator.activity().excavating_artifact_id(),
        Some(&artifact_id)
    );
    assert!(matches!(
        transition
            .state()
            .artifact(&artifact_id)
            .expect("artifact")
            .location(),
        WorldArtifactLocation::Excavation {
            unit_id: owner,
            coordinate,
            remaining_turns: 2,
        } if owner == &unit_id && *coordinate == HexCoord::new(0, 0)
    ));
    let [DomainEvent::ArtifactExcavationStarted(event)] = transition.events() else {
        panic!("typed excavation event")
    };
    assert_eq!(event.artifact_id(), &artifact_id);
    assert_eq!(event.owner_player_id(), &p1);
    assert_eq!(event.unit_id(), &unit_id);
}

#[test]
fn excavation_rejection_precedence_is_revision_control_then_artifact_state() {
    let map = map();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let foreign_unit = unit_id("foreign");
    let foreign_state = game_state(
        vec![unit("foreign", &p2, HexCoord::new(0, 0))],
        Vec::new(),
        Vec::new(),
        None,
        false,
    );
    let apply = |revision| {
        GameEngine::apply_player_owned(
            foreign_state.clone(),
            EngineContext::canonical(&p1, &map, RulesetDefinition::standard()),
            PlayerCommand::StartArtifactExcavation(StartArtifactExcavationCommand::new(
                revision,
                &foreign_unit,
            )),
        )
        .expect("normal rejection")
    };
    assert_eq!(
        apply(8).rejection().expect("stale").code(),
        CommandRejectionCode::StaleRevision
    );
    assert_eq!(
        apply(9).rejection().expect("control").code(),
        CommandRejectionCode::UnitNotControlled
    );

    let unit = carried_unit("carrier", &p1, HexCoord::new(1, 0), artifact_id("carried"));
    let carrying_state = game_state(
        vec![unit],
        Vec::new(),
        vec![
            artifact(
                "carried",
                WorldArtifactLocation::Carried(unit_id("carrier")),
            ),
            artifact(
                "map-artifact",
                WorldArtifactLocation::Map(HexCoord::new(1, 0)),
            ),
        ],
        None,
        false,
    );
    let carrying = GameEngine::apply_player_owned(
        carrying_state,
        EngineContext::canonical(&p1, &map, RulesetDefinition::standard()),
        PlayerCommand::StartArtifactExcavation(StartArtifactExcavationCommand::new(
            9,
            &unit_id("carrier"),
        )),
    )
    .expect("carrying rejection");
    assert_eq!(
        carrying.rejection().expect("rejection").code(),
        CommandRejectionCode::UnitAlreadyCarryingArtifact
    );

    let fortified = support::unit("fortified", &p1, HexCoord::new(2, 0)).after_fortify();
    let unavailable = GameEngine::apply_player_owned(
        game_state(
            vec![fortified],
            Vec::new(),
            vec![artifact(
                "map-artifact",
                WorldArtifactLocation::Map(HexCoord::new(2, 0)),
            )],
            None,
            false,
        ),
        EngineContext::canonical(&p1, &map, RulesetDefinition::standard()),
        PlayerCommand::StartArtifactExcavation(StartArtifactExcavationCommand::new(
            9,
            &unit_id("fortified"),
        )),
    )
    .expect("unavailable rejection");
    assert_eq!(
        unavailable.rejection().expect("rejection").code(),
        CommandRejectionCode::UnitUnavailable
    );
}

#[test]
fn carried_artifact_stores_only_in_one_owned_city_slot() {
    let map = map();
    let p1 = player("player-1");
    let carrier_id = unit_id("carrier");
    let artifact_key = artifact_id("seal");
    let city_key = city_id("capital");
    let state = game_state(
        vec![carried_unit(
            "carrier",
            &p1,
            HexCoord::new(1, 0),
            artifact_key.clone(),
        )],
        vec![city("capital", &p1, HexCoord::new(1, 0))],
        vec![artifact(
            "seal",
            WorldArtifactLocation::Carried(carrier_id.clone()),
        )],
        None,
        false,
    );
    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&p1, &map, RulesetDefinition::standard()),
        PlayerCommand::StoreArtifactInCity(StoreArtifactInCityCommand::new(
            9,
            &carrier_id,
            Some(&city_key),
        )),
    )
    .expect("store artifact");

    assert!(transition.is_accepted());
    assert!(
        transition
            .state()
            .unit(&carrier_id)
            .expect("carrier")
            .carried_artifact_id()
            .is_none()
    );
    assert_eq!(
        transition
            .state()
            .artifact(&artifact_key)
            .expect("artifact")
            .location(),
        &WorldArtifactLocation::Stored(city_key.clone())
    );
    let [DomainEvent::ArtifactStored(event)] = transition.events() else {
        panic!("typed storage event")
    };
    assert_eq!(event.source_unit_id(), Some(&carrier_id));
    assert_eq!(event.city_id(), &city_key);
    assert_eq!(event.artifact_id(), &artifact_key);
    assert_eq!(event.coordinate(), HexCoord::new(1, 0));

    let occupied = game_state(
        vec![carried_unit(
            "carrier",
            &p1,
            HexCoord::new(1, 0),
            artifact_id("seal"),
        )],
        vec![city("capital", &p1, HexCoord::new(1, 0))],
        vec![
            artifact("seal", WorldArtifactLocation::Carried(unit_id("carrier"))),
            artifact("crown", WorldArtifactLocation::Stored(city_id("capital"))),
        ],
        None,
        false,
    );
    let rejected = GameEngine::apply_player_owned(
        occupied,
        EngineContext::canonical(&p1, &map, RulesetDefinition::standard()),
        PlayerCommand::StoreArtifactInCity(StoreArtifactInCityCommand::new(9, &carrier_id, None)),
    )
    .expect("full slot rejection");
    assert_eq!(
        rejected.rejection().expect("rejection").code(),
        CommandRejectionCode::CityArtifactSlotFull
    );
}

#[test]
fn artifact_storage_requires_an_owned_city_below_the_carrier() {
    let map = map();
    let p1 = player("player-1");
    let p2 = player("player-2");
    for (city_owner, city_position, expected) in [
        (
            &p2,
            HexCoord::new(1, 0),
            CommandRejectionCode::CityNotControlled,
        ),
        (
            &p1,
            HexCoord::new(0, 0),
            CommandRejectionCode::UnitNotInCity,
        ),
    ] {
        let state = game_state(
            vec![carried_unit(
                "carrier",
                &p1,
                HexCoord::new(1, 0),
                artifact_id("seal"),
            )],
            vec![city("selected", city_owner, city_position)],
            vec![artifact(
                "seal",
                WorldArtifactLocation::Carried(unit_id("carrier")),
            )],
            None,
            false,
        );
        let result = GameEngine::apply_player_owned(
            state,
            EngineContext::canonical(&p1, &map, RulesetDefinition::standard()),
            PlayerCommand::StoreArtifactInCity(StoreArtifactInCityCommand::new(
                9,
                &unit_id("carrier"),
                Some(&city_id("selected")),
            )),
        )
        .expect("store rejection");
        assert_eq!(result.rejection().expect("rejection").code(), expected);
    }
}

#[test]
fn trade_uses_authenticated_actor_canonical_target_city_and_atomic_gold_transfer() {
    let map = map();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let artifact_id = artifact_id("seal");
    let state = game_state(
        Vec::new(),
        vec![
            city("source", &p1, HexCoord::new(0, 0)),
            city("target-b", &p2, HexCoord::new(2, 0)),
            city("target-a", &p2, HexCoord::new(1, 0)),
        ],
        vec![artifact(
            "seal",
            WorldArtifactLocation::Stored(city_id("source")),
        )],
        Some((17, 23)),
        false,
    );
    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&p1, &map, RulesetDefinition::standard()),
        PlayerCommand::TradeArtifact(TradeArtifactCommand::new(9, &p2, &artifact_id, 5)),
    )
    .expect("trade artifact");

    assert!(transition.is_accepted());
    assert_eq!(
        transition
            .state()
            .artifact(&artifact_id)
            .expect("artifact")
            .location(),
        &WorldArtifactLocation::Stored(city_id("target-a"))
    );
    assert_eq!(
        transition.state().economy().player_gold().get(&p1),
        Some(&12)
    );
    assert_eq!(
        transition.state().economy().player_gold().get(&p2),
        Some(&28)
    );
    let [DomainEvent::ArtifactStored(event)] = transition.events() else {
        panic!("typed trade storage event")
    };
    assert_eq!(event.owner_player_id(), &p2);
    assert_eq!(event.source_unit_id(), None);
    assert_eq!(event.city_id(), &city_id("target-a"));
    assert_eq!(event.artifact_id(), &artifact_id);
    assert_eq!(event.coordinate(), HexCoord::new(1, 0));
}

#[test]
fn trade_rejects_war_and_unavailable_gold_without_mutation() {
    let map = map();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let artifact_id = artifact_id("seal");
    let build = |war| {
        game_state(
            Vec::new(),
            vec![
                city("source", &p1, HexCoord::new(0, 0)),
                city("target", &p2, HexCoord::new(1, 0)),
            ],
            vec![artifact(
                "seal",
                WorldArtifactLocation::Stored(city_id("source")),
            )],
            Some((3, 0)),
            war,
        )
    };
    let apply = |state, gold| {
        GameEngine::apply_player_owned(
            state,
            EngineContext::canonical(&p1, &map, RulesetDefinition::standard()),
            PlayerCommand::TradeArtifact(TradeArtifactCommand::new(9, &p2, &artifact_id, gold)),
        )
        .expect("normal trade rejection")
    };

    let war = apply(build(true), 0);
    assert_eq!(
        war.rejection().expect("war rejection").code(),
        CommandRejectionCode::ArtifactTradeBlockedByWar
    );
    let unavailable = apply(build(false), 4);
    assert_eq!(
        unavailable.rejection().expect("gold rejection").code(),
        CommandRejectionCode::ArtifactTradeGoldUnavailable
    );
    assert_eq!(
        unavailable
            .state()
            .artifact(&artifact_id)
            .expect("artifact")
            .location(),
        &WorldArtifactLocation::Stored(city_id("source"))
    );

    let invalid_target = GameEngine::apply_player_owned(
        build(false),
        EngineContext::canonical(&p1, &map, RulesetDefinition::standard()),
        PlayerCommand::TradeArtifact(TradeArtifactCommand::new(9, &p1, &artifact_id, 0)),
    )
    .expect("target rejection");
    assert_eq!(
        invalid_target.rejection().expect("rejection").code(),
        CommandRejectionCode::ArtifactTradeTargetInvalid
    );
    let invalid_gold = apply(build(false), -1);
    assert_eq!(
        invalid_gold.rejection().expect("rejection").code(),
        CommandRejectionCode::ArtifactTradeGoldInvalid
    );

    for location in [
        WorldArtifactLocation::Map(HexCoord::new(0, 0)),
        WorldArtifactLocation::Stored(city_id("target")),
    ] {
        let rejected = apply(
            game_state(
                Vec::new(),
                vec![
                    city("source", &p1, HexCoord::new(0, 0)),
                    city("target", &p2, HexCoord::new(1, 0)),
                ],
                vec![artifact("seal", location)],
                Some((3, 0)),
                false,
            ),
            0,
        );
        assert_eq!(
            rejected.rejection().expect("rejection").code(),
            CommandRejectionCode::OfferedArtifactUnavailable
        );
    }
}

#[test]
fn artifact_error_surface_is_stable() {
    let rejected = ArtifactError::from(CommandRejectionCode::ArtifactNotFound);
    assert_eq!(rejected.code(), "artifact_not_found");
    assert_eq!(rejected.to_string(), "artifact_not_found");

    let invalid = ArtifactError::InvalidState("invalid artifact state".into());
    assert_eq!(invalid.code(), "artifact_state_invalid");
    assert_eq!(invalid.to_string(), "invalid artifact state");
    assert_eq!(
        CanonicalEngineError::Artifact(invalid).to_string(),
        "artifact failed: invalid artifact state"
    );
}
