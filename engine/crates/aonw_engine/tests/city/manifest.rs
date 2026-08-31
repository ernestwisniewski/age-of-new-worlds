use serde::Deserialize;

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct CityManifest {
    capability: String,
    commands: Vec<String>,
    queries: Vec<String>,
    turn_processors: Vec<String>,
    cases: Vec<String>,
}

#[test]
fn city_manifest_is_strict_and_complete() {
    let root = std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .nth(3)
        .expect("repository root");
    let manifest: CityManifest = serde_json::from_slice(
        &std::fs::read(root.join("engine/fixtures/city/manifest.json")).expect("manifest"),
    )
    .expect("strict manifest");

    assert_eq!(manifest.capability, "city-territory-ready");
    assert_eq!(
        manifest.commands,
        ["foundCity", "selectCityExpansionHex", "toggleWorkedHex"]
    );
    assert_eq!(
        manifest.queries,
        [
            "cityExpansionOptions",
            "cityFoundingOptions",
            "cityWorkedHexOptions"
        ]
    );
    assert_eq!(manifest.turn_processors, ["cityFounding"]);
    assert!(manifest.cases.len() >= 10);

    let invalid = std::fs::read(root.join("engine/fixtures/city/invalid/unknown-field.json"))
        .expect("negative fixture");
    assert!(serde_json::from_slice::<CityManifest>(&invalid).is_err());
}
