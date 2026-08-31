use serde::Deserialize;

use super::support::repository_root;

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct LogisticsManifest {
    capability: String,
    commands: Vec<String>,
    queries: Vec<String>,
    turn_processors: Vec<String>,
    cases: Vec<String>,
}

#[test]
fn logistics_manifest_is_strict_and_complete() {
    let root = repository_root();
    let manifest: LogisticsManifest = serde_json::from_slice(
        &std::fs::read(root.join("engine/fixtures/movement_logistics/manifest.json"))
            .expect("manifest"),
    )
    .expect("strict manifest");

    assert_eq!(manifest.capability, "movement-logistics-ready");
    assert_eq!(manifest.commands.len(), 4);
    assert_eq!(manifest.queries, ["unitLogisticsOptions"]);
    assert_eq!(
        manifest.turn_processors,
        ["queuedMovement", "tradeRoutes", "autoExplore"]
    );
    assert!(manifest.cases.len() >= 7);
    let invalid =
        std::fs::read(root.join("engine/fixtures/movement_logistics/invalid/unknown-field.json"))
            .expect("negative fixture");
    assert!(serde_json::from_slice::<LogisticsManifest>(&invalid).is_err());
}
