use aonw_contracts::client::{CLIENT_API_VERSION, ClientQueryDto, ClientResponseDto};

const FIXTURES: [&str; 5] = [
    include_str!("../../../../fixtures/client_protocol/production_building_details_response.json"),
    include_str!("../../../../fixtures/client_protocol/production_unit_details_response.json"),
    include_str!("../../../../fixtures/client_protocol/production_wonder_details_response.json"),
    include_str!("../../../../fixtures/client_protocol/production_project_details_response.json"),
    include_str!("../../../../fixtures/client_protocol/production_building_ranks_response.json"),
];

#[test]
fn production_detail_fixtures_round_trip_with_every_effect_family() {
    for document in FIXTURES {
        let response = ClientResponseDto::from_json(document).expect("fixture");
        assert_eq!(response.api_version, CLIENT_API_VERSION);
        assert_eq!(
            serde_json::to_value(response).expect("serialize"),
            serde_json::from_str::<serde_json::Value>(document).expect("value")
        );
    }
}

#[test]
fn production_detail_objects_reject_missing_and_unknown_fields_recursively() {
    for document in FIXTURES {
        let original: serde_json::Value = serde_json::from_str(document).expect("fixture");
        let mut paths = Vec::new();
        object_paths(
            &original["outcome"]["response"]["result"],
            "/outcome/response/result",
            &mut paths,
        );
        for path in paths {
            // Resource stockpiles are keyed maps, so an empty map remains valid.
            if path.ends_with("/resourceOptions/0") {
                continue;
            }
            let object = original
                .pointer(&path)
                .expect("path")
                .as_object()
                .expect("object");
            for field in object.keys() {
                let mut missing = original.clone();
                missing
                    .pointer_mut(&path)
                    .expect("path")
                    .as_object_mut()
                    .expect("object")
                    .remove(field);
                assert!(
                    serde_json::from_value::<ClientResponseDto>(missing).is_err(),
                    "missing {path}/{field}"
                );
            }
            let mut unknown = original.clone();
            unknown
                .pointer_mut(&path)
                .expect("path")
                .as_object_mut()
                .expect("object")
                .insert(
                    "privateOpponentCity".to_owned(),
                    serde_json::json!("hidden"),
                );
            assert!(
                serde_json::from_value::<ClientResponseDto>(unknown).is_err(),
                "unknown {path}"
            );
        }
    }
}

#[test]
fn selected_target_requests_reject_actor_injection_and_wrong_target_shape() {
    for target in [
        serde_json::json!({"kind":"building","buildingType":"workshop"}),
        serde_json::json!({"kind":"unit","unitType":"warrior"}),
        serde_json::json!({"kind":"wonder","wonderType":"greatLibrary"}),
        serde_json::json!({"kind":"project","projectType":"research"}),
    ] {
        let value = serde_json::json!({"type":"productionDetails","expectedRevision":8,"cityId":"city-1","target":target});
        let query: ClientQueryDto = serde_json::from_value(value.clone()).expect("query");
        assert_eq!(serde_json::to_value(query).expect("serialize"), value);
        let mut injected = value.clone();
        injected["actorPlayerId"] = serde_json::json!("other");
        assert!(serde_json::from_value::<ClientQueryDto>(injected).is_err());
        let mut wrong = value;
        wrong["target"]["unitId"] = serde_json::json!("private-unit");
        assert!(serde_json::from_value::<ClientQueryDto>(wrong).is_err());
    }
}

fn object_paths(value: &serde_json::Value, path: &str, paths: &mut Vec<String>) {
    match value {
        serde_json::Value::Object(fields) => {
            paths.push(path.to_owned());
            for (field, value) in fields {
                object_paths(value, &format!("{path}/{field}"), paths);
            }
        }
        serde_json::Value::Array(values) => {
            for (index, value) in values.iter().enumerate() {
                object_paths(value, &format!("{path}/{index}"), paths);
            }
        }
        _ => {}
    }
}
