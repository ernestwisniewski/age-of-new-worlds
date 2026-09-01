use aonw_contracts::client::{ClientCommandDto, ClientRequestBodyDto};

pub(super) fn requests() -> [ClientRequestBodyDto; 3] {
    [
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::StartArtifactExcavation {
                expected_revision: 8,
                unit_id: "scout-1".to_owned(),
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::StoreArtifactInCity {
                expected_revision: 9,
                unit_id: "scout-1".to_owned(),
                city_id: Some("capital".to_owned()),
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::TradeArtifact {
                expected_revision: 10,
                target_player_id: "player-2".to_owned(),
                offered_artifact_id: "artifact-1".to_owned(),
                offered_gold: 0,
            },
        },
    ]
}

#[test]
fn artifact_commands_reject_actor_fields() {
    let request_with_actor = r#"{"apiVersion":13,"request":{"type":"dispatch","command":{"type":"tradeArtifact","expectedRevision":10,"actorPlayerId":"player-1","targetPlayerId":"player-2","offeredArtifactId":"artifact-1","offeredGold":0,"requestedGold":4}}}"#;
    assert!(aonw_contracts::client::ClientRequestDto::from_json(request_with_actor).is_err());
}
