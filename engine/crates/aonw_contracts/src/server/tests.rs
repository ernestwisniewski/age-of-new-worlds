use super::{PrepareServerWorldRequestDto, SERVER_HOST_API_VERSION};

#[test]
fn prepare_request_requires_exact_identity_and_shape() {
    let valid = format!(
        r#"{{"apiVersion":{SERVER_HOST_API_VERSION},"mapDocument":"{{}}","rulesetId":"standard"}}"#
    );
    assert!(PrepareServerWorldRequestDto::from_json(&valid).is_ok());
    assert!(
        PrepareServerWorldRequestDto::from_json(&valid.replace('}', ",\"extra\":true}")).is_err()
    );
}
