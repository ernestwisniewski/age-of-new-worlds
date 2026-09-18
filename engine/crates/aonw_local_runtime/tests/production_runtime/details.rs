use super::*;
use aonw_contracts::CityProductionTargetDto;
use aonw_contracts::client::ProductionTargetEffectsDto;

#[test]
fn selected_details_cache_keeps_targets_separate_and_queries_do_not_mutate_save() {
    let mut runtime = opened_runtime();
    let save = runtime.export_save_json().expect("save");
    let targets = [
        CityProductionTargetDto::Building {
            building_type: CityBuildingTypeDto::Workshop,
        },
        CityProductionTargetDto::Unit {
            unit_type: UnitKindDto::Warrior,
        },
        CityProductionTargetDto::Wonder {
            wonder_type: WonderTypeDto::GreatLibrary,
        },
        CityProductionTargetDto::Project {
            project_type: CityProjectTypeDto::Research,
        },
    ];
    let responses: Vec<_> = targets
        .iter()
        .map(|target| details(&mut runtime, *target, 9))
        .collect();
    for (target, response) in targets.iter().zip(&responses) {
        assert_eq!(details(&mut runtime, *target, 9), *response);
        let ClientResponseBodyDto::Query {
            result:
                ClientQueryResultDto::ProductionDetails {
                    option, effects, ..
                },
        } = response
        else {
            panic!("details");
        };
        assert_eq!(&option.target, target);
        match (target, effects) {
            (
                CityProductionTargetDto::Building { .. },
                ProductionTargetEffectsDto::Building(value),
            ) => {
                assert!(value.completed.production > value.current.production);
            }
            (CityProductionTargetDto::Unit { .. }, ProductionTargetEffectsDto::Unit(value)) => {
                assert!(value.maximum_movement_units > 0);
            }
            (CityProductionTargetDto::Wonder { .. }, ProductionTargetEffectsDto::Wonder(value)) => {
                assert!(value.grants_free_active_technology);
            }
            (CityProductionTargetDto::Project { .. }, ProductionTargetEffectsDto::Project) => {}
            _ => panic!("target/effect mismatch"),
        }
    }
    let ranking = ranks(&mut runtime, 9);
    let ClientResponseBodyDto::Query {
        result: ClientQueryResultDto::ProductionBuildingRanks { buildings, .. },
    } = &ranking
    else {
        panic!("ranks");
    };
    assert_eq!(buildings.len(), 59);
    assert_eq!(ranks(&mut runtime, 9), ranking);
    assert_eq!(
        runtime.export_save_json().expect("save after queries"),
        save
    );
    let (map, rules, _, _) = fixture();
    let mut resumed = LocalRuntime::default();
    resumed.open_save_json(map, rules, &save).expect("resume");
    for (target, response) in targets.into_iter().zip(responses) {
        assert_eq!(details(&mut resumed, target, 9), response);
    }
    assert_eq!(ranks(&mut resumed, 9), ranking);
}

#[test]
fn details_and_ranks_invalidate_after_completion_and_keep_replay_exact() {
    let mut runtime = opened_runtime();
    let target = CityProductionTargetDto::Building {
        building_type: CityBuildingTypeDto::Housing,
    };
    let before = details(&mut runtime, target, 9);
    let before_ranks = ranks(&mut runtime, 9);
    dispatch_client(
        &mut runtime,
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::RushProduction {
                expected_revision: 9,
                city_id: "capital".to_owned(),
            },
        },
    );
    let after = details(&mut runtime, target, 10);
    assert_ne!(before, after);
    assert_ne!(before_ranks, ranks(&mut runtime, 10));
    let ClientResponseBodyDto::Query {
        result:
            ClientQueryResultDto::ProductionDetails {
                option,
                effects: ProductionTargetEffectsDto::Building(value),
                ..
            },
    } = after
    else {
        panic!("building details");
    };
    assert!(option.availability.completed_in_city);
    assert_eq!(value.current, value.completed);
    let (map, rules, _, _) = fixture();
    let replay = runtime.export_replay_json().expect("replay");
    assert_eq!(
        LocalRuntime::verify_replay_json(map, rules, &replay)
            .expect("verify")
            .entry_count,
        1
    );
}

fn details(
    runtime: &mut LocalRuntime,
    target: CityProductionTargetDto,
    revision: u64,
) -> ClientResponseBodyDto {
    dispatch_client(
        runtime,
        ClientRequestBodyDto::Query {
            query: ClientQueryDto::ProductionDetails {
                expected_revision: revision,
                city_id: "capital".to_owned(),
                target,
            },
        },
    )
}

fn ranks(runtime: &mut LocalRuntime, revision: u64) -> ClientResponseBodyDto {
    dispatch_client(
        runtime,
        ClientRequestBodyDto::Query {
            query: ClientQueryDto::ProductionBuildingRanks {
                expected_revision: revision,
                city_id: "capital".to_owned(),
            },
        },
    )
}
