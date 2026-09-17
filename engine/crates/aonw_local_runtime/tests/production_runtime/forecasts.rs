use super::*;

#[test]
fn quoted_final_increment_matches_the_command_and_survives_save_resume() {
    let mut runtime = opened_runtime();
    let before = *runtime.snapshot().expect("snapshot").stamp();
    let options = query(&mut runtime);
    assert_eq!(*runtime.snapshot().expect("snapshot").stamp(), before);
    let ClientResponseBodyDto::Query {
        result:
            ClientQueryResultDto::ProductionOptions {
                buildings,
                rush_quote,
                ..
            },
    } = &options
    else {
        panic!("production options");
    };
    let housing = buildings
        .iter()
        .find(|option| {
            option.target
                == aonw_contracts::CityProductionTargetDto::Building {
                    building_type: CityBuildingTypeDto::Housing,
                }
        })
        .expect("housing");
    assert_eq!(housing.forecast.invested_production, housing.cost - 1);
    assert_eq!(housing.forecast.estimated_turns, Some(1));
    assert_eq!(housing.forecast.project_output, None);
    // The fixture carries a queue without its owner having Construction.
    assert!(!housing.availability.technology_unlocked);
    assert!(!housing.availability.completed_in_city);
    assert_eq!(
        housing.availability.required_technology,
        Some(aonw_contracts::TechnologyIdDto::Construction)
    );
    assert_eq!(rush_quote.production, 1);
    assert_eq!(rush_quote.gold_cost, 2);
    assert_eq!(rush_quote.rejection, None);
    let save = runtime.export_save_json().expect("save");
    let (map, rules, _, _) = fixture();
    let mut resumed = LocalRuntime::default();
    resumed.open_save_json(map, rules, &save).expect("resume");
    assert_eq!(query(&mut resumed), options);
    let command = dispatch_client(
        &mut resumed,
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::RushProduction {
                expected_revision: 9,
                city_id: "capital".to_owned(),
            },
        },
    );
    let ClientResponseBodyDto::Command { result } = command else {
        panic!("command");
    };
    assert_eq!(result.outcome, ClientCommandOutcomeDto::Accepted);
    assert_eq!(
        result.view_patch.economy.expect("gold patch").gold,
        100 - rush_quote.gold_cost
    );
}

fn query(runtime: &mut LocalRuntime) -> ClientResponseBodyDto {
    dispatch_client(
        runtime,
        ClientRequestBodyDto::Query {
            query: ClientQueryDto::ProductionOptions {
                expected_revision: 9,
                city_id: "capital".to_owned(),
            },
        },
    )
}
