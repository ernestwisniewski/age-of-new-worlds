use aonw_contracts::client::{ClientQueryDto, ClientRequestBodyDto};
use aonw_contracts::{
    CityBuildingTypeDto, CityProductionTargetDto, CityProjectTypeDto, UnitKindDto, WonderTypeDto,
};
use aonw_local_runtime::ClientProtocol;

use super::{client_request, production_support, report_with_setup, signature_bytes};

pub(super) fn benchmark(unit_count: usize) {
    for (name, target, cached) in [
        (
            "building",
            Some(CityProductionTargetDto::Building {
                building_type: CityBuildingTypeDto::Workshop,
            }),
            false,
        ),
        (
            "completed_building",
            Some(CityProductionTargetDto::Building {
                building_type: CityBuildingTypeDto::Granary,
            }),
            false,
        ),
        (
            "unit",
            Some(CityProductionTargetDto::Unit {
                unit_type: UnitKindDto::Warrior,
            }),
            false,
        ),
        (
            "wonder",
            Some(CityProductionTargetDto::Wonder {
                wonder_type: WonderTypeDto::GreatLibrary,
            }),
            false,
        ),
        (
            "project",
            Some(CityProductionTargetDto::Project {
                project_type: CityProjectTypeDto::Research,
            }),
            false,
        ),
        ("ranks", None, false),
        (
            "building_cached",
            Some(CityProductionTargetDto::Building {
                building_type: CityBuildingTypeDto::Workshop,
            }),
            true,
        ),
        ("ranks_cached", None, true),
    ] {
        let mut base = production_support::opened(unit_count, None);
        let request = client_request(ClientRequestBodyDto::Query {
            query: target.map_or_else(
                || ClientQueryDto::ProductionBuildingRanks {
                    expected_revision: 0,
                    city_id: "capital".to_owned(),
                },
                |target| ClientQueryDto::ProductionDetails {
                    expected_revision: 0,
                    city_id: "capital".to_owned(),
                    target,
                },
            ),
        });
        let response = ClientProtocol::dispatch_json(&mut base, &request);
        validate(&response, target);
        if !cached {
            base = production_support::opened(unit_count, None);
        }
        report_with_setup(
            &format!("client_json_production_details_{name}"),
            unit_count,
            || base.clone(),
            |mut runtime| {
                let response = ClientProtocol::dispatch_json(&mut runtime, &request);
                (signature_bytes(&response), response.len())
            },
        );
    }
}

fn validate(response: &str, target: Option<CityProductionTargetDto>) {
    let document: serde_json::Value = serde_json::from_str(response).expect("details JSON");
    let result = &document["outcome"]["response"]["result"];
    if let Some(target) = target {
        assert_eq!(result["type"], "productionDetails");
        assert_eq!(
            result["option"]["target"],
            serde_json::to_value(target).expect("target")
        );
        if target
            == (CityProductionTargetDto::Building {
                building_type: CityBuildingTypeDto::Granary,
            })
        {
            assert_eq!(
                result["effects"]["details"]["current"],
                result["effects"]["details"]["completed"]
            );
        }
    } else {
        assert_eq!(result["type"], "productionBuildingRanks");
        assert_eq!(result["buildings"].as_array().expect("ranks").len(), 59);
    }
}
