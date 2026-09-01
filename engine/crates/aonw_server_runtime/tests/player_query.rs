//! Local/server parity and privacy contract for authenticated player queries.

use aonw_content::RulesetDefinition;
use aonw_contract_mapping::encode_game_state;
use aonw_contracts::CoordinateDto;
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientOutcomeDto, ClientQueryDto, ClientRequestBodyDto, ClientRequestDto,
    ClientResponseBodyDto,
};
use aonw_contracts::server::{
    PlayerQueryServerRequestDto, SERVER_HOST_API_VERSION, ServerPlayerQueryOutcomeDto,
};
use aonw_local_runtime::{ClientProtocol, LocalRuntime, OpenSession};
use aonw_server_runtime::{ServerBoundaryError, ServerHostError, query_player_dto};

#[test]
fn strict_server_queries_match_the_local_client_protocol() {
    let fixture = fixture([]);
    let actor = player("player-1");
    let queries = [
        ClientQueryDto::ResearchOptions {
            expected_revision: 7,
        },
        ClientQueryDto::CityFoundingOptions {
            expected_revision: 7,
            founder_unit_id: "unit-1".to_owned(),
        },
        ClientQueryDto::CityWorkedHexOptions {
            expected_revision: 7,
            city_id: "city-1".to_owned(),
        },
        ClientQueryDto::CityExpansionOptions {
            expected_revision: 7,
            city_id: "city-1".to_owned(),
        },
        ClientQueryDto::CityYield {
            expected_revision: 7,
            city_id: "city-1".to_owned(),
        },
        ClientQueryDto::StrategicResourceProjection {
            expected_revision: 7,
        },
        ClientQueryDto::ProductionOptions {
            expected_revision: 7,
            city_id: "city-1".to_owned(),
        },
        ClientQueryDto::WorkerOptions {
            expected_revision: 7,
            unit_id: "unit-1".to_owned(),
        },
        ClientQueryDto::CombatPreview {
            expected_revision: 7,
            attacker_unit_id: "unit-1".to_owned(),
            defender: CoordinateDto { col: 1, row: 0 },
        },
        ClientQueryDto::Reachable {
            expected_revision: 7,
            unit_id: "unit-1".to_owned(),
        },
        ClientQueryDto::RoutePlan {
            expected_revision: 7,
            unit_id: "unit-1".to_owned(),
            target: CoordinateDto { col: 1, row: 0 },
        },
        ClientQueryDto::UnitLogisticsOptions {
            expected_revision: 7,
            unit_id: "unit-1".to_owned(),
        },
    ];

    let mut local = LocalRuntime::default();
    local
        .open(OpenSession::from_state(
            map(2),
            RulesetDefinition::standard().clone(),
            fixture.state.clone(),
            actor,
        ))
        .expect("local runtime");

    for query in queries {
        let local_outcome = local_query(&mut local, query.clone());
        let server_outcome =
            query_player_dto(fixture.world.clone(), request(&fixture, "player-1", query))
                .expect("server boundary");
        assert_eq!(server_outcome, local_outcome);
    }
}

#[test]
fn invalid_query_identity_is_a_client_failure_without_state_mutation() {
    let fixture = fixture([]);
    let outcome = query_player_dto(
        fixture.world.clone(),
        request(
            &fixture,
            "player-1",
            ClientQueryDto::Reachable {
                expected_revision: 7,
                unit_id: "   ".to_owned(),
            },
        ),
    )
    .expect("contained query failure");

    let ServerPlayerQueryOutcomeDto::Failure { error } = outcome else {
        panic!("invalid query must fail")
    };
    assert_eq!(error.code, "invalid_unit_id");
}

#[test]
fn unauthenticated_participant_fails_at_the_host_boundary() {
    let fixture = fixture([]);
    let result = query_player_dto(
        fixture.world.clone(),
        request(
            &fixture,
            "foreign-player",
            ClientQueryDto::ResearchOptions {
                expected_revision: 7,
            },
        ),
    );

    assert_eq!(
        result,
        Err(ServerBoundaryError::Host(
            ServerHostError::UnknownAuthenticatedActor(player("foreign-player"))
        ))
    );
}

fn request(
    fixture: &support::Fixture,
    actor: &str,
    query: ClientQueryDto,
) -> PlayerQueryServerRequestDto {
    PlayerQueryServerRequestDto {
        api_version: SERVER_HOST_API_VERSION,
        authenticated_actor_player_id: actor.to_owned(),
        query,
        map_hash: fixture.world.map_hash().to_string(),
        ruleset_hash: fixture.world.ruleset_hash().to_string(),
        state: encode_game_state(&fixture.state),
    }
}

fn local_query(runtime: &mut LocalRuntime, query: ClientQueryDto) -> ServerPlayerQueryOutcomeDto {
    match ClientProtocol::dispatch(
        runtime,
        ClientRequestDto {
            api_version: CLIENT_API_VERSION,
            request: ClientRequestBodyDto::Query { query },
        },
    )
    .outcome
    {
        ClientOutcomeDto::Success { response } => {
            let ClientResponseBodyDto::Query { result } = *response else {
                panic!("query response expected")
            };
            ServerPlayerQueryOutcomeDto::Success {
                result: Box::new(result),
            }
        }
        ClientOutcomeDto::Failure { error } => ServerPlayerQueryOutcomeDto::Failure { error },
    }
}

#[path = "submit_turn/support.rs"]
#[allow(dead_code)]
mod support;

use support::{fixture, map, player};
