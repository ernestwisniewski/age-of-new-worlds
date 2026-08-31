use serde::Deserialize;

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct CombatManifest {
    capability: String,
    commands: Vec<String>,
    queries: Vec<String>,
    turn_processors: Vec<String>,
    cases: Vec<String>,
}

#[test]
fn combat_manifest_is_strict_and_complete() {
    let root = repository_root();
    let manifest: CombatManifest = serde_json::from_slice(
        &std::fs::read(root.join("engine/fixtures/combat/manifest.json")).expect("manifest"),
    )
    .expect("strict manifest");

    assert_eq!(manifest.capability, "combat-ready");
    assert_eq!(manifest.commands, ["attackHex"]);
    assert_eq!(manifest.queries, ["combatPreview"]);
    assert_eq!(manifest.turn_processors, ["combat"]);
    assert!(manifest.cases.len() >= 9);

    let invalid = std::fs::read(root.join("engine/fixtures/combat/invalid/unknown-field.json"))
        .expect("negative fixture");
    assert!(serde_json::from_slice::<CombatManifest>(&invalid).is_err());
}

fn repository_root() -> std::path::PathBuf {
    std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .nth(3)
        .expect("repository root")
        .to_path_buf()
}
