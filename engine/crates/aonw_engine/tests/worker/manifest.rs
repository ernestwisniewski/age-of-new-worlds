use serde::Deserialize;

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct WorkerManifest {
    capability: String,
    commands: Vec<String>,
    queries: Vec<String>,
    turn_processors: Vec<String>,
    automation_tile_budget: u32,
    automation_legality_budget: u32,
    client_api_version: u16,
    cases: Vec<String>,
}

#[test]
fn worker_manifest_is_strict_and_complete() {
    let root = std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .nth(3)
        .expect("repository root");
    let manifest: WorkerManifest = serde_json::from_slice(
        &std::fs::read(root.join("engine/fixtures/worker/manifest.json")).expect("manifest"),
    )
    .expect("strict manifest");

    assert_eq!(manifest.capability, "worker-infrastructure-ready");
    assert_eq!(
        manifest.commands,
        [
            "assignWorkerToHex",
            "automateWorker",
            "buildRoad",
            "cancelWorkerAssignment",
            "cancelWorkerJob",
            "confirmWorkerImprovement",
            "selectWorkerImprovement",
        ]
    );
    assert_eq!(manifest.queries, ["workerOptions"]);
    assert_eq!(manifest.turn_processors, ["workerJobs", "workerAutomation"]);
    assert_eq!(
        manifest.automation_tile_budget,
        aonw_content::RulesetDefinition::standard()
            .worker()
            .automation_tile_budget()
    );
    assert_eq!(
        manifest.automation_legality_budget,
        aonw_content::RulesetDefinition::standard()
            .worker()
            .automation_legality_budget()
    );
    assert_eq!(
        manifest.client_api_version,
        aonw_contracts::client::CLIENT_API_VERSION
    );
    assert!(manifest.cases.len() >= 14);

    let invalid = std::fs::read(root.join("engine/fixtures/worker/invalid/unknown-field.json"))
        .expect("negative fixture");
    assert!(serde_json::from_slice::<WorkerManifest>(&invalid).is_err());
}
