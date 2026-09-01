//! Transaction and privacy contract for the first remote multiplayer command.

use aonw_content::RulesetDefinition;
use aonw_contract_mapping::encode_game_state;
use aonw_contracts::server::{
    CreateServerMatchRequestDto, SERVER_HOST_API_VERSION, SubmitTurnServerRequestDto,
};
use aonw_contracts::{GameModeDto, TurnModeDto};
use aonw_domain::{GameState, StateRevision};
use aonw_engine::{CommandRejectionCode, DomainEvent, GameEngine};
use aonw_server_runtime::{
    PreparedServerWorld, RecipientOutcome, ServerBoundaryError, ServerHostError, apply_submit_turn,
    apply_submit_turn_dto, create_server_match_dto,
};

#[test]
fn final_submit_returns_exact_offsets_and_every_recipient_projection() {
    let fixture = fixture([player("player-1")]);
    let expected_map_hash = fixture.world.map_hash();
    let expected_ruleset_hash = fixture.world.ruleset_hash();
    let outcome = apply_submit_turn(fixture.request("player-2", 7, 40)).expect("submit turn");

    assert_eq!(outcome.rejection, None);
    assert_eq!(outcome.initial_event_offset, 40);
    assert_eq!(outcome.final_event_offset, 43);
    assert_eq!(outcome.state.revision(), StateRevision::new(8));
    assert_eq!(outcome.state.turn(), 8);
    assert_eq!(
        outcome.stamp.state_digest,
        GameEngine::state_digest(&outcome.state)
    );
    assert_eq!(outcome.stamp.map_hash, expected_map_hash);
    assert_eq!(outcome.stamp.ruleset_hash, expected_ruleset_hash);
    assert!(matches!(
        outcome.events.as_ref(),
        [
            DomainEvent::AllPlayersSubmitted(_),
            DomainEvent::TurnEnded(_),
            DomainEvent::TurnEnded(_)
        ]
    ));
    assert_eq!(outcome.recipients.len(), 2);
    for recipient in &outcome.recipients {
        assert_eq!(
            recipient.snapshot.recipient_player_id(),
            &recipient.recipient_player_id
        );
        assert_eq!(recipient.snapshot.stamp(), &outcome.stamp);
        assert_eq!(recipient.patch.from_revision, 7);
        assert_eq!(recipient.patch.to_revision, 8);
        assert_eq!(recipient.events.as_ref(), outcome.events.as_ref());

        let own_unit = recipient
            .snapshot
            .units()
            .iter()
            .find(|unit| unit.owner_player_id() == &recipient.recipient_player_id)
            .expect("own unit");
        assert!(own_unit.owned_details().is_some());
        assert!(
            recipient
                .snapshot
                .units()
                .iter()
                .filter(|unit| unit.owner_player_id() != &recipient.recipient_player_id)
                .all(|unit| unit.owned_details().is_none())
        );
        assert_recipient_economy(recipient, &outcome.state);
        let actor = &recipient.recipient_player_id;
        let (technology, progress, overflow) = expected_research(actor);
        assert_eq!(
            recipient.snapshot.research().active_technology_id(),
            Some(technology)
        );
        assert_eq!(
            recipient.snapshot.research().active_progress(),
            Some(progress)
        );
        assert_eq!(recipient.snapshot.research().science_overflow(), overflow);
        assert_eq!(recipient.snapshot.victory().score_by_player_id().len(), 2);
        assert_eq!(recipient.snapshot.victory().domination().len(), 2);
        assert_eq!(recipient.snapshot.victory().own_cultural().hold_turns(), 0);
    }
}

fn assert_recipient_economy(recipient: &RecipientOutcome, state: &GameState) {
    let canonical = state.economy();
    let actor = &recipient.recipient_player_id;
    let projected = recipient.snapshot.economy();
    assert_eq!(
        projected.gold(),
        canonical.player_gold().get(actor).copied().unwrap_or(0)
    );
    assert_eq!(
        projected.war_weariness(),
        canonical
            .player_war_weariness()
            .get(actor)
            .copied()
            .unwrap_or(0)
    );
    assert_eq!(
        projected.stability_net(),
        canonical
            .player_stability_net()
            .get(actor)
            .copied()
            .unwrap_or(0)
    );
    let forecast = projected.forecast();
    assert_eq!(forecast.treasury, projected.gold());
    assert_eq!(
        forecast.stability.war_weariness_cost,
        projected.war_weariness()
    );
    let stockpile = projected.strategic_resource_stockpile();
    let canonical_stockpile = canonical
        .strategic_resources()
        .get(actor)
        .expect("actor stockpile");
    assert_eq!(stockpile.len(), canonical_stockpile.amounts().len());
    for (projected, (resource, amount)) in stockpile.iter().zip(canonical_stockpile.amounts()) {
        assert_eq!(projected.resource(), *resource);
        assert_eq!(projected.amount(), *amount);
    }
}

#[test]
fn stale_submit_is_an_exact_unchanged_outcome() {
    let fixture = fixture([]);
    let before_state = fixture.state.clone();
    let before_digest = GameEngine::state_digest(&before_state);
    let outcome = apply_submit_turn(fixture.request("player-1", 6, 19)).expect("rejection");

    assert_eq!(outcome.rejection, Some(CommandRejectionCode::StaleRevision));
    assert_eq!(outcome.state, before_state);
    assert_eq!(outcome.stamp.state_digest, before_digest);
    assert_eq!(outcome.initial_event_offset, 19);
    assert_eq!(outcome.final_event_offset, 19);
    assert!(outcome.events.is_empty());
    assert!(outcome.evidence.is_none());
    assert!(outcome.recipients.iter().all(|recipient| {
        recipient.events.is_empty()
            && recipient.patch.from_revision == 7
            && recipient.patch.to_revision == 7
            && recipient.snapshot.stamp().state_digest == before_digest
    }));
}

#[test]
fn authenticated_actor_and_event_capacity_fail_before_transition() {
    let world = fixture([]);
    assert_eq!(
        apply_submit_turn(world.request("foreign-player", 7, 0)),
        Err(ServerHostError::UnknownAuthenticatedActor(player(
            "foreign-player"
        )))
    );

    let world = fixture([]);
    assert_eq!(
        apply_submit_turn(world.request("player-1", 7, u64::MAX)),
        Err(ServerHostError::EventOffsetOverflow)
    );
}

#[test]
fn immutable_content_mismatch_fails_closed() {
    let world = fixture([]);
    let mismatched = PreparedServerWorld::try_new(map(1), RulesetDefinition::standard().clone())
        .expect("mismatched world");
    assert_eq!(
        apply_submit_turn(world.request_with_world("player-1", 7, 0, mismatched)),
        Err(ServerHostError::MapBoundsMismatch)
    );

    let world = fixture([]);
    let mut request = world.request("player-1", 7, 0);
    request.state = GameState::builder(
        request.state.revision(),
        request.state.turn(),
        request.state.bounds(),
        aonw_domain::UnitOccupancyPolicy::Exclusive,
        request.state.units().iter().cloned(),
    )
    .with_match_lifecycle(request.state.match_lifecycle().clone())
    .with_fog_of_war(request.state.fog_of_war().clone())
    .try_build()
    .expect("exclusive state");
    assert_eq!(
        apply_submit_turn(request),
        Err(ServerHostError::OccupancyPolicyMismatch)
    );
}

#[test]
fn strict_dto_maps_transactional_and_recipient_safe_output() {
    let fixture = fixture([]);
    let map_hash = fixture.world.map_hash().to_string();
    let ruleset_hash = fixture.world.ruleset_hash().to_string();
    let result = apply_submit_turn_dto(
        fixture.world.clone(),
        SubmitTurnServerRequestDto {
            api_version: SERVER_HOST_API_VERSION,
            authenticated_actor_player_id: "player-1".to_owned(),
            expected_revision: 7,
            initial_event_offset: 80,
            map_hash: map_hash.clone(),
            ruleset_hash: ruleset_hash.clone(),
            state: encode_game_state(&fixture.state),
        },
    )
    .expect("strict DTO request");

    assert_eq!(result.initial_event_offset, 80);
    assert_eq!(result.stamp.map_hash, map_hash);
    assert_eq!(result.stamp.ruleset_hash, ruleset_hash);
    assert_eq!(result.recipients.len(), 2);
    assert!(result.recipients.iter().all(|recipient| {
        recipient
            .snapshot
            .units
            .iter()
            .filter(|unit| unit.owner_player_id != recipient.recipient_player_id)
            .all(|unit| unit.owned_details.is_none())
    }));
    for recipient in &result.recipients {
        let (gold, war_weariness, _, resource, amount) =
            expected_economy(&player(&recipient.recipient_player_id));
        assert_eq!(recipient.snapshot.economy.gold, gold);
        assert_eq!(recipient.snapshot.economy.war_weariness, war_weariness);
        assert_eq!(
            recipient
                .snapshot
                .economy
                .strategic_resource_stockpile
                .len(),
            1
        );
        assert_eq!(
            recipient.snapshot.economy.strategic_resource_stockpile[0].resource,
            aonw_contract_mapping::encode_resource(resource)
        );
        assert_eq!(
            recipient.snapshot.economy.strategic_resource_stockpile[0].amount,
            amount
        );
        let (technology, progress, overflow) =
            expected_research(&player(&recipient.recipient_player_id));
        assert_eq!(
            recipient.snapshot.research.active_technology_id,
            Some(aonw_contract_mapping::encode_technology(technology))
        );
        assert_eq!(recipient.snapshot.research.active_progress, Some(progress));
        assert_eq!(recipient.snapshot.research.science_overflow, overflow);
        assert_eq!(recipient.snapshot.victory.score_by_player_id.len(), 2);
        assert_eq!(recipient.snapshot.victory.domination.len(), 2);
        assert_eq!(recipient.snapshot.victory.own_cultural.hold_turns, 0);
    }
}

#[test]
fn strict_dto_rejects_version_and_content_identity_before_execution() {
    let fixture = fixture([]);
    let request = SubmitTurnServerRequestDto {
        api_version: SERVER_HOST_API_VERSION + 1,
        authenticated_actor_player_id: "player-1".to_owned(),
        expected_revision: 7,
        initial_event_offset: 0,
        map_hash: fixture.world.map_hash().to_string(),
        ruleset_hash: fixture.world.ruleset_hash().to_string(),
        state: encode_game_state(&fixture.state),
    };
    assert_eq!(
        apply_submit_turn_dto(fixture.world.clone(), request.clone()),
        Err(ServerBoundaryError::UnsupportedApiVersion {
            actual: SERVER_HOST_API_VERSION + 1,
        })
    );

    let mut request = request;
    request.api_version = SERVER_HOST_API_VERSION;
    request.map_hash = "wrong-map".to_owned();
    assert_eq!(
        apply_submit_turn_dto(fixture.world.clone(), request),
        Err(ServerBoundaryError::ContentIdentityMismatch)
    );
}

#[test]
fn rust_constructs_and_projects_multiplayer_matches() {
    let map = map(2);
    let ruleset = RulesetDefinition::standard().clone();
    let scenario_document = serde_json::json!({
        "schemaVersion": 1,
        "scenarioId": "server-created-match",
        "mapId": map.map_id(),
        "rulesetId": ruleset.ruleset_id(),
        "initialUnits": [
            {
                "id": "unit-1",
                "ownerPlayerId": "player-1",
                "kind": "commander",
                "name": "One",
                "col": 0,
                "row": 0
            },
            {
                "id": "unit-2",
                "ownerPlayerId": "player-2",
                "kind": "commander",
                "name": "Two",
                "col": 1,
                "row": 0
            }
        ]
    })
    .to_string();
    let world = PreparedServerWorld::try_new(map, ruleset).expect("world");
    let request = CreateServerMatchRequestDto {
        api_version: SERVER_HOST_API_VERSION,
        map_hash: world.map_hash().to_string(),
        ruleset_hash: world.ruleset_hash().to_string(),
        scenario_document,
        match_identity: match_identity(GameModeDto::Multiplayer),
        fog_enabled: true,
    };

    let result = create_server_match_dto(&world, request).expect("created match");

    assert_eq!(
        result.state.match_identity.game_mode,
        GameModeDto::Multiplayer
    );
    assert_eq!(result.projection.recipients.len(), 2);
    assert_eq!(result.projection.stamp.revision, result.state.revision);
    for recipient in result.projection.recipients {
        assert!(recipient.snapshot.units.iter().all(|unit| {
            unit.owner_player_id == recipient.recipient_player_id || unit.owned_details.is_none()
        }));
    }
}

#[test]
fn server_match_creation_requires_multiplayer_with_simultaneous_turns() {
    let map = map(2);
    let ruleset = RulesetDefinition::standard().clone();
    let scenario_document = serde_json::json!({
        "schemaVersion": 1,
        "scenarioId": "server-hot-seat-rejected",
        "mapId": map.map_id(),
        "rulesetId": ruleset.ruleset_id(),
        "initialUnits": [{
            "id": "unit-1",
            "ownerPlayerId": "player-1",
            "kind": "commander",
            "name": "One",
            "col": 0,
            "row": 0
        }]
    })
    .to_string();
    let world = PreparedServerWorld::try_new(map, ruleset).expect("world");
    let request = CreateServerMatchRequestDto {
        api_version: SERVER_HOST_API_VERSION,
        map_hash: world.map_hash().to_string(),
        ruleset_hash: world.ruleset_hash().to_string(),
        scenario_document: scenario_document.clone(),
        match_identity: match_identity(GameModeDto::HotSeat),
        fog_enabled: false,
    };

    assert_eq!(
        create_server_match_dto(&world, request),
        Err(ServerBoundaryError::UnsupportedGameMode)
    );

    let mut sequential_multiplayer = match_identity(GameModeDto::Multiplayer);
    sequential_multiplayer.turn_mode = Some(TurnModeDto::Sequential);
    let request = CreateServerMatchRequestDto {
        api_version: SERVER_HOST_API_VERSION,
        map_hash: world.map_hash().to_string(),
        ruleset_hash: world.ruleset_hash().to_string(),
        scenario_document,
        match_identity: sequential_multiplayer,
        fog_enabled: false,
    };
    assert_eq!(
        create_server_match_dto(&world, request),
        Err(ServerBoundaryError::UnsupportedGameMode)
    );
}

#[path = "submit_turn/support.rs"]
mod support;

use support::{expected_economy, expected_research, fixture, map, match_identity, player};
