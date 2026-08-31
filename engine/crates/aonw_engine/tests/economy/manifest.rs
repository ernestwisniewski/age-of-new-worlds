use serde::Deserialize;

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct EconomyManifest {
    capability: String,
    commands: Vec<String>,
    queries: Vec<String>,
    turn_processors: Vec<String>,
    client_api_version: u16,
    cases: Vec<String>,
}

#[test]
fn economy_manifest_is_strict_and_complete() {
    let root = std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .nth(3)
        .expect("repository root");
    let manifest: EconomyManifest = serde_json::from_slice(
        &std::fs::read(root.join("engine/fixtures/economy/manifest.json")).expect("manifest"),
    )
    .expect("strict manifest");

    assert_eq!(manifest.capability, "economy-read-model-ready");
    assert!(manifest.commands.is_empty());
    assert_eq!(
        manifest.queries,
        ["cityYield", "strategicResourceProjection"]
    );
    assert!(manifest.turn_processors.is_empty());
    assert_eq!(
        manifest.client_api_version,
        aonw_contracts::client::CLIENT_API_VERSION
    );
    assert!(manifest.cases.len() >= 12);

    let invalid = std::fs::read(root.join("engine/fixtures/economy/invalid/unknown-field.json"))
        .expect("negative fixture");
    assert!(serde_json::from_slice::<EconomyManifest>(&invalid).is_err());
}
