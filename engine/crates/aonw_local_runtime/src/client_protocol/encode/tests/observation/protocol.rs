use crate::{ClientProtocol, LocalRuntime};
use aonw_content::MapDocument;
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientOutcomeDto, ClientRequestBodyDto, ClientRequestDto,
    ClientResponseBodyDto, ClientResponseDto,
};

use super::{ScriptedDriver, opened};

#[test]
fn protocol_delivers_recipient_frames_for_ai_and_sequential_replay() {
    let (map, _, mut runtime) = opened();
    let request = request_json(ClientRequestBodyDto::AdvanceAiTurn {
        actor_player_id: "ai".to_owned(),
        command_budget: 3,
    });
    let json =
        ClientProtocol::dispatch_json_with_ai(&mut runtime, &request, &mut ScriptedDriver::new(3));
    let ClientResponseBodyDto::AiTurnAdvanced {
        recipient_player_id,
        actor_player_id,
        commands,
        ..
    } = success_body(&json)
    else {
        panic!("AI response");
    };
    assert_eq!(recipient_player_id, "human");
    assert_eq!(actor_player_id, "ai");
    assert_eq!(commands.len(), 3);
    assert!(commands[0].evidence.is_some());
    assert!(commands[1].evidence.is_none());
    assert!(commands[1].events.is_empty());
    assert!(commands[2].view_patch.research.is_none());
    assert_eq!(
        json,
        include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/../../fixtures/client_protocol/observed_ai_turn_response.json"
        ))
        .trim()
    );

    let replay_document = runtime.export_replay_json().expect("replay");
    let map_document = MapDocument::try_new(map, 1.0)
        .expect("map")
        .to_versioned_json()
        .expect("map JSON");
    let initial = dispatch(
        &mut runtime,
        ClientRequestBodyDto::OpenReplay {
            map_document,
            replay_document,
            recipient_player_id: "human".to_owned(),
        },
    );
    assert!(matches!(
        success_body(&initial),
        ClientResponseBodyDto::ReplayFrame { command: None, .. }
    ));
    let json = dispatch(
        &mut runtime,
        ClientRequestBodyDto::SeekReplay { position: 1 },
    );
    let ClientResponseBodyDto::ReplayFrame {
        command: Some(command),
        snapshot,
        ..
    } = success_body(&json)
    else {
        panic!("forward command");
    };
    assert_eq!(*command, commands[0]);
    assert_eq!(snapshot.participants[0].id, "human");
    assert_eq!(snapshot.victory.domination[0].player_id, "ai");
    assert_eq!(snapshot.victory.domination[1].player_id, "human");
    assert_eq!(
        json,
        include_str!(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/../../fixtures/client_protocol/observed_replay_frame_response.json"
        ))
        .trim()
    );
    for position in [1, 3, 0] {
        let json = dispatch(&mut runtime, ClientRequestBodyDto::SeekReplay { position });
        assert!(matches!(
            success_body(&json),
            ClientResponseBodyDto::ReplayFrame { command: None, .. }
        ));
    }
}

fn request_json(request: ClientRequestBodyDto) -> String {
    ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request,
    }
    .to_json()
    .expect("request")
}

fn dispatch(runtime: &mut LocalRuntime, request: ClientRequestBodyDto) -> String {
    ClientProtocol::dispatch_json(runtime, &request_json(request))
}

fn success_body(json: &str) -> ClientResponseBodyDto {
    let response = ClientResponseDto::from_json(json).expect("strict response");
    let ClientOutcomeDto::Success { response } = response.outcome else {
        panic!("protocol failure: {json}");
    };
    *response
}
