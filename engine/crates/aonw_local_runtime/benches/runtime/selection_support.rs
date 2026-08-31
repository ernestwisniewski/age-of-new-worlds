use aonw_content::{MapDefinition, RulesetDefinition, ScenarioDefinition, ScenarioUnitDefinition};
use aonw_contracts::client::{ClientQueryDto, ClientRequestBodyDto};
use aonw_domain::{HexCoord, PlayerId, UnitId, UnitKind};
use aonw_local_runtime::{ClientProtocol, LocalRuntime, OpenSession};

use super::{client_request, report_with_setup, signature_bytes};

pub(super) fn benchmark(
    base: &LocalRuntime,
    map: MapDefinition,
    ruleset: RulesetDefinition,
    unit_count: usize,
) {
    let reachable = query(ClientQueryDto::Reachable {
        expected_revision: 0,
        unit_id: "unit-0".to_owned(),
    });
    report_json("client_json_reachable", unit_count, base, &reachable);

    let logistics = query(ClientQueryDto::UnitLogisticsOptions {
        expected_revision: 0,
        unit_id: "unit-0".to_owned(),
    });
    report_json(
        "client_json_unit_logistics_options",
        unit_count,
        base,
        &logistics,
    );

    let worker = opened_worker_runtime(map, ruleset, unit_count);
    let worker_options = query(ClientQueryDto::WorkerOptions {
        expected_revision: 0,
        unit_id: "worker-0".to_owned(),
    });
    report_json(
        "client_json_worker_options",
        unit_count,
        &worker,
        &worker_options,
    );
}

fn report_json(workload: &str, unit_count: usize, base: &LocalRuntime, request: &str) {
    report_with_setup(
        workload,
        unit_count,
        || base.clone(),
        |mut runtime| {
            let response = ClientProtocol::dispatch_json(&mut runtime, request);
            (signature_bytes(&response), response.len())
        },
    );
}

fn query(query: ClientQueryDto) -> String {
    client_request(ClientRequestBodyDto::Query { query })
}

fn opened_worker_runtime(
    map: MapDefinition,
    ruleset: RulesetDefinition,
    unit_count: usize,
) -> LocalRuntime {
    let actor = PlayerId::new("player-1").expect("actor");
    let units = positions(unit_count).enumerate().map(|(index, position)| {
        let kind = if index == 0 {
            UnitKind::Worker
        } else {
            UnitKind::Commander
        };
        ScenarioUnitDefinition::new(
            UnitId::new(if index == 0 {
                "worker-0".to_owned()
            } else {
                format!("unit-{index}")
            })
            .expect("unit id"),
            actor.clone(),
            kind,
            "Benchmark unit",
            position,
        )
    });
    let scenario = ScenarioDefinition::try_new("selection_benchmark", &map, &ruleset, units)
        .expect("worker scenario");
    let open = OpenSession::from_scenario(map, ruleset, &scenario, actor).expect("worker open");
    let mut runtime = LocalRuntime::default();
    runtime.open(open).expect("worker runtime");
    runtime
}

fn positions(unit_count: usize) -> impl Iterator<Item = HexCoord> {
    (0..30)
        .flat_map(|row| (0..40).map(move |col| HexCoord::new(col, row)))
        .take(unit_count)
}
