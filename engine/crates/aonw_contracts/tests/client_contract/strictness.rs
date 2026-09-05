use aonw_contracts::client::{CLIENT_API_VERSION, ClientRequestDto, ClientResponseDto};

#[test]
fn malformed_unknown_duplicate_and_future_documents_fail_closed() {
    let unknown = r#"{"apiVersion":18,"request":{"type":"snapshot"},"extra":true}"#;
    let duplicate = r#"{"apiVersion":18,"apiVersion":18,"request":{"type":"snapshot"}}"#;
    let future = format!(
        r#"{{"apiVersion":{},"request":{{"type":"snapshot"}}}}"#,
        CLIENT_API_VERSION + 1
    );
    let malformed_nested = r#"{"apiVersion":18,"request":{"type":"query","query":{"type":"reachable","expectedRevision":0,"unitId":"u","extra":true}}}"#;
    let malformed_logistics = r#"{"apiVersion":18,"request":{"type":"dispatch","command":{"type":"autoExploreUnit","expectedRevision":0,"unitId":"u","unexpectedField":[]}}}"#;
    let malformed_worker = r#"{"apiVersion":18,"request":{"type":"dispatch","command":{"type":"buildRoad","expectedRevision":0,"unitId":"u","unexpectedField":true}}}"#;

    for invalid in [
        unknown,
        duplicate,
        &future,
        malformed_nested,
        malformed_logistics,
        malformed_worker,
    ] {
        assert!(ClientRequestDto::from_json(invalid).is_err());
    }

    let future_response = format!(
        r#"{{"apiVersion":{},"outcome":{{"status":"success","response":{{"type":"sessionClosed"}}}}}}"#,
        CLIENT_API_VERSION + 1
    );
    let unknown_response = r#"{"apiVersion":18,"outcome":{"status":"failure","error":{"code":"failed","message":"failed","extra":true}}}"#;
    let old_command_shape = r#"{"apiVersion":18,"outcome":{"status":"success","response":{"type":"command","result":{"stamp":{"revision":0,"stateDigest":"d","mapHash":"m","rulesetHash":"r"},"accepted":true,"rejection":null,"events":[],"evidence":null,"viewPatch":{"fromRevision":0,"toRevision":0,"upsertedUnits":[],"removedUnitIds":[],"pendingAction":null}}}}}"#;
    let unknown_rejection = r#"{"apiVersion":18,"outcome":{"status":"success","response":{"type":"command","result":{"stamp":{"revision":0,"stateDigest":"d","mapHash":"m","rulesetHash":"r"},"outcome":{"status":"rejected","code":"future_rejection"},"events":[],"evidence":null,"viewPatch":{"fromRevision":0,"toRevision":0,"upsertedUnits":[],"removedUnitIds":[],"pendingAction":null}}}}}"#;
    assert!(ClientResponseDto::from_json(&future_response).is_err());
    assert!(ClientResponseDto::from_json(unknown_response).is_err());
    assert!(ClientResponseDto::from_json(old_command_shape).is_err());
    assert!(ClientResponseDto::from_json(unknown_rejection).is_err());
}
