use super::*;
use aonw_contracts::{
    CityBuildingTypeDto, CityProductionTargetDto, CityProjectTypeDto, UnitKindDto, WonderTypeDto,
};

#[test]
fn production_details_and_ranks_match_local_for_every_target_and_rejection() {
    let fixture = production_fixture();
    let mut local = LocalRuntime::default();
    local
        .open(OpenSession::from_state(
            map(2),
            RulesetDefinition::standard().clone(),
            fixture.state.clone(),
            player("player-1"),
        ))
        .expect("local");
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
    for (revision, city) in [(7, "city-1"), (6, "city-1"), (7, "missing"), (7, " ")] {
        let mut queries: Vec<_> = targets
            .iter()
            .map(|target| ClientQueryDto::ProductionDetails {
                expected_revision: revision,
                city_id: city.to_owned(),
                target: *target,
            })
            .collect();
        queries.push(ClientQueryDto::ProductionBuildingRanks {
            expected_revision: revision,
            city_id: city.to_owned(),
        });
        for query in queries {
            let expected = local_query(&mut local, query.clone());
            let actual =
                query_player_dto(fixture.world.clone(), request(&fixture, "player-1", query))
                    .expect("boundary");
            assert_eq!(actual, expected);
            assert_eq!(
                matches!(actual, ServerPlayerQueryOutcomeDto::Success { .. }),
                revision == 7 && city == "city-1"
            );
        }
    }
}

#[test]
fn another_participant_cannot_inspect_city_effects_or_ranks() {
    let fixture = production_fixture();
    for query in [
        ClientQueryDto::ProductionDetails {
            expected_revision: 7,
            city_id: "city-1".to_owned(),
            target: CityProductionTargetDto::Building {
                building_type: CityBuildingTypeDto::Workshop,
            },
        },
        ClientQueryDto::ProductionBuildingRanks {
            expected_revision: 7,
            city_id: "city-1".to_owned(),
        },
    ] {
        let outcome = query_player_dto(fixture.world.clone(), request(&fixture, "player-2", query))
            .expect("boundary");
        let ServerPlayerQueryOutcomeDto::Failure { error } = outcome else {
            panic!("foreign city must fail")
        };
        assert_eq!(error.code, "city_not_controlled");
    }
}

fn production_fixture() -> support::Fixture {
    let mut fixture = fixture([]);
    let city = aonw_domain::City::builder(
        aonw_domain::CityId::new("city-1").expect("city"),
        player("player-1"),
        "Capital",
        aonw_domain::HexCoord::new(0, 0),
    )
    .build()
    .expect("city");
    let update = aonw_domain::CityStateUpdate {
        revision: fixture.state.revision(),
        units: fixture.state.units().to_vec(),
        cities: vec![city],
        interaction: fixture.state.interaction().clone(),
    };
    fixture.state = fixture.state.into_after_city(update).expect("city fixture");
    fixture
}
