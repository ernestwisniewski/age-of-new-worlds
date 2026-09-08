//! Canonical local/server parity and recipient-privacy command corpus.

use std::path::{Path, PathBuf};

use aonw_content::RulesetDefinition;
use aonw_contract_mapping::{decode_game_state, encode_game_state};
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientCommandDto, ClientCommandOutcomeDto, ClientCommandResultDto,
    ClientOutcomeDto, ClientRequestBodyDto, ClientRequestDto, ClientResponseBodyDto,
};
use aonw_contracts::server::{PlayerCommandServerRequestDto, SERVER_HOST_API_VERSION};

use aonw_domain::PlayerId;
use aonw_local_runtime::{ClientProtocol, LocalRuntime, OpenSession};
use aonw_server_runtime::{PreparedServerWorld, apply_player_command_dto};
use aonw_testkit::{CanonicalFixture, CanonicalFixtureLoader};

#[path = "player_command_parity/cancellation.rs"]
mod cancellation;
#[path = "player_command_parity/command_shapes.rs"]
mod command_shapes;

use command_shapes::command_shapes;

const CANONICAL_COMMAND_FIXTURE_COUNT: usize = 44;
const INITIAL_EVENT_OFFSET: u64 = 73;

#[test]
fn canonical_commands_match_local_and_server_runtime_for_every_recipient() {
    let fixtures = CanonicalFixtureLoader::default()
        .load_corpus(repository_root().join("engine/fixtures/canonical_commands"))
        .expect("canonical command corpus");
    assert_eq!(fixtures.len(), CANONICAL_COMMAND_FIXTURE_COUNT);

    for fixture in fixtures {
        verify_fixture(&fixture);
    }
}

#[test]
fn every_closed_player_command_shape_matches_local_and_server_runtime() {
    let fixture = support::fixture([]);
    let map = support::map(2);
    let commands = command_shapes();
    assert_eq!(commands.len(), 40);

    for (label, command) in commands {
        verify_command_shape(label, &fixture, &map, command);
    }
}

fn verify_fixture(fixture: &CanonicalFixture) {
    let input = fixture.input();
    let actor = player(input.actor_player_id());
    let state = decode_game_state(input.state().clone()).expect("canonical fixture state");
    let ruleset = RulesetDefinition::standard().clone();
    let world = PreparedServerWorld::try_new(input.map().clone(), ruleset.clone())
        .expect("prepared server world");

    let mut local = LocalRuntime::default();
    local
        .open(
            OpenSession::from_state(
                input.map().clone(),
                ruleset.clone(),
                state.clone(),
                actor.clone(),
            )
            .with_event_offset(INITIAL_EVENT_OFFSET),
        )
        .expect("local fixture session");
    let local_result = dispatch_local(&mut local, input.command().clone());

    let server_result = apply_player_command_dto(
        world.clone(),
        PlayerCommandServerRequestDto {
            api_version: SERVER_HOST_API_VERSION,
            authenticated_actor_player_id: actor.as_str().to_owned(),
            command: input.command().clone(),
            initial_event_offset: INITIAL_EVENT_OFFSET,
            map_hash: world.map_hash().to_string(),
            ruleset_hash: world.ruleset_hash().to_string(),
            state: encode_game_state(&state),
        },
    )
    .unwrap_or_else(|error| panic!("{}: server command failed: {error}", fixture.id()));

    assert_eq!(
        server_result.state,
        *fixture.expected().state(),
        "{}: server canonical state differs from the reviewed fixture",
        fixture.id()
    );
    assert_eq!(
        server_result.final_event_offset,
        INITIAL_EVENT_OFFSET + u64::try_from(server_result.events.len()).expect("event count"),
        "{}: server event offset differs from authoritative events",
        fixture.id()
    );

    let actor_delivery = server_result
        .recipients
        .iter()
        .find(|recipient| recipient.recipient_player_id == actor.as_str())
        .unwrap_or_else(|| panic!("{}: actor delivery missing", fixture.id()));
    let server_actor_result = ClientCommandResultDto {
        stamp: server_result.stamp.clone(),
        outcome: server_result
            .rejection
            .map_or(ClientCommandOutcomeDto::Accepted, |code| {
                ClientCommandOutcomeDto::Rejected { code }
            }),
        events: actor_delivery.events.clone(),
        evidence: actor_delivery.evidence.clone(),
        view_patch: actor_delivery.patch.clone(),
    };
    assert_eq!(
        server_actor_result,
        local_result,
        "{}: authenticated client result differs between runtimes",
        fixture.id()
    );

    assert_eq!(
        actor_delivery.snapshot,
        local_snapshot(&mut local),
        "{}: authenticated post-command snapshot differs between runtimes",
        fixture.id()
    );

    let final_state = decode_game_state(server_result.state.clone())
        .expect("server result must remain a canonical state");
    for recipient in &server_result.recipients {
        let recipient_id = player(&recipient.recipient_player_id);
        let mut recipient_runtime = LocalRuntime::default();
        recipient_runtime
            .open(
                OpenSession::from_state(
                    input.map().clone(),
                    ruleset.clone(),
                    final_state.clone(),
                    recipient_id,
                )
                .with_event_offset(server_result.final_event_offset),
            )
            .unwrap_or_else(|error| panic!("{}: recipient session failed: {error}", fixture.id()));
        assert_eq!(
            recipient.snapshot,
            local_snapshot(&mut recipient_runtime),
            "{}: server leaked or omitted recipient projection data for {}",
            fixture.id(),
            recipient.recipient_player_id
        );
    }
}

fn dispatch_local(
    runtime: &mut LocalRuntime,
    command: aonw_contracts::client::ClientCommandDto,
) -> ClientCommandResultDto {
    match ClientProtocol::dispatch(
        runtime,
        ClientRequestDto {
            api_version: CLIENT_API_VERSION,
            request: ClientRequestBodyDto::Dispatch { command },
        },
    )
    .outcome
    {
        ClientOutcomeDto::Success { response } => {
            let ClientResponseBodyDto::Command { result } = *response else {
                panic!("command response expected")
            };
            *result
        }
        ClientOutcomeDto::Failure { error } => {
            panic!("local command failed at the protocol boundary: {error:?}")
        }
    }
}

fn local_snapshot(runtime: &mut LocalRuntime) -> aonw_contracts::client::PlayerViewSnapshotDto {
    match ClientProtocol::dispatch(
        runtime,
        ClientRequestDto {
            api_version: CLIENT_API_VERSION,
            request: ClientRequestBodyDto::Snapshot,
        },
    )
    .outcome
    {
        ClientOutcomeDto::Success { response } => {
            let ClientResponseBodyDto::Snapshot { snapshot } = *response else {
                panic!("snapshot response expected")
            };
            snapshot
        }
        ClientOutcomeDto::Failure { error } => {
            panic!("local snapshot failed at the protocol boundary: {error:?}")
        }
    }
}

fn verify_command_shape(
    label: &str,
    fixture: &support::Fixture,
    map: &aonw_content::MapDefinition,
    command: ClientCommandDto,
) {
    let actor = player("player-1");
    let ruleset = RulesetDefinition::standard().clone();
    let mut local = LocalRuntime::default();
    local
        .open(
            OpenSession::from_state(
                map.clone(),
                ruleset.clone(),
                fixture.state.clone(),
                actor.clone(),
            )
            .with_event_offset(INITIAL_EVENT_OFFSET),
        )
        .unwrap_or_else(|error| panic!("{label}: local session failed: {error}"));
    let local_result = dispatch_local(&mut local, command.clone());

    let server_result = apply_player_command_dto(
        fixture.world.clone(),
        PlayerCommandServerRequestDto {
            api_version: SERVER_HOST_API_VERSION,
            authenticated_actor_player_id: actor.as_str().to_owned(),
            command,
            initial_event_offset: INITIAL_EVENT_OFFSET,
            map_hash: fixture.world.map_hash().to_string(),
            ruleset_hash: fixture.world.ruleset_hash().to_string(),
            state: encode_game_state(&fixture.state),
        },
    )
    .unwrap_or_else(|error| panic!("{label}: server command failed: {error}"));
    let actor_delivery = server_result
        .recipients
        .iter()
        .find(|recipient| recipient.recipient_player_id == actor.as_str())
        .unwrap_or_else(|| panic!("{label}: actor delivery missing"));
    assert_eq!(
        ClientCommandResultDto {
            stamp: server_result.stamp.clone(),
            outcome: server_result
                .rejection
                .map_or(ClientCommandOutcomeDto::Accepted, |code| {
                    ClientCommandOutcomeDto::Rejected { code }
                },),
            events: actor_delivery.events.clone(),
            evidence: actor_delivery.evidence.clone(),
            view_patch: actor_delivery.patch.clone(),
        },
        local_result,
        "{label}: client result differs between runtimes"
    );
    assert_eq!(
        actor_delivery.snapshot,
        local_snapshot(&mut local),
        "{label}: actor snapshot differs between runtimes"
    );

    let final_state = decode_game_state(server_result.state)
        .unwrap_or_else(|error| panic!("{label}: invalid final state: {error}"));
    for recipient in &server_result.recipients {
        let mut recipient_runtime = LocalRuntime::default();
        recipient_runtime
            .open(
                OpenSession::from_state(
                    map.clone(),
                    ruleset.clone(),
                    final_state.clone(),
                    player(&recipient.recipient_player_id),
                )
                .with_event_offset(server_result.final_event_offset),
            )
            .unwrap_or_else(|error| panic!("{label}: recipient session failed: {error}"));
        assert_eq!(
            recipient.snapshot,
            local_snapshot(&mut recipient_runtime),
            "{label}: recipient projection differs for {}",
            recipient.recipient_player_id
        );
    }
}

fn repository_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .find(|path| path.join("engine/fixtures/canonical_commands").is_dir())
        .expect("repository root must contain canonical command fixtures")
        .to_path_buf()
}

fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("fixture player id")
}

#[path = "submit_turn/support.rs"]
#[allow(dead_code)]
mod support;
