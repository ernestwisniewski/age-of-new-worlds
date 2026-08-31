//! Current economy query response fixtures.

use aonw_contracts::client::{
    CityYieldContributionDto, CityYieldContributionKindDto, ClientEventDto, ClientQueryResultDto,
    ClientResponseBodyDto, StrategicResourceAmountDto, StrategicResourceSourceDto, YieldValueDto,
};
use aonw_contracts::{FieldImprovementKindDto, ReplayEventDto, ResourceTypeDto, StabilityBandDto};

use super::{coordinate, stamp};

pub(super) fn responses() -> Vec<ClientResponseBodyDto> {
    vec![city_yield(), strategic_resource_projection()]
}

#[test]
fn economy_events_round_trip_with_strict_shapes() {
    let client_events = [
        ClientEventDto::CityClaimedHex {
            city_id: "capital".to_owned(),
            col: 3,
            row: 4,
        },
        ClientEventDto::StabilityBandChanged {
            player_id: "player-1".to_owned(),
            previous_band: StabilityBandDto::Stable,
            new_band: StabilityBandDto::Strained,
            net: -2,
        },
    ];
    for event in client_events {
        assert_strict_round_trip(&event);
    }

    let replay_events = [
        ReplayEventDto::CityClaimedHex {
            city_id: "capital".to_owned(),
            col: 3,
            row: 4,
        },
        ReplayEventDto::StabilityBandChanged {
            player_id: "player-1".to_owned(),
            previous_band: StabilityBandDto::Stable,
            new_band: StabilityBandDto::Strained,
            net: -2,
        },
    ];
    for event in replay_events {
        assert_strict_round_trip(&event);
    }
}

fn assert_strict_round_trip<T>(value: &T)
where
    T: serde::Serialize + serde::de::DeserializeOwned + PartialEq + core::fmt::Debug,
{
    let json = serde_json::to_string(value).expect("event JSON");
    let decoded = serde_json::from_str::<T>(&json).expect("event");
    assert_eq!(&decoded, value);
    let unknown = json.replacen('{', r#"{"unexpectedField":true,"#, 1);
    assert!(serde_json::from_str::<T>(&unknown).is_err());
}

fn city_yield() -> ClientResponseBodyDto {
    ClientResponseBodyDto::Query {
        result: ClientQueryResultDto::CityYield {
            stamp: stamp(),
            city_id: "city-1".to_owned(),
            contributions: vec![CityYieldContributionDto {
                kind: CityYieldContributionKindDto::Center,
                coordinate: coordinate(3, 4),
                value: YieldValueDto {
                    food: 2,
                    production: 1,
                    gold: 0,
                    defense: 0,
                },
            }],
            total: YieldValueDto {
                food: 2,
                production: 1,
                gold: 0,
                defense: 0,
            },
        },
    }
}

fn strategic_resource_projection() -> ClientResponseBodyDto {
    ClientResponseBodyDto::Query {
        result: ClientQueryResultDto::StrategicResourceProjection {
            stamp: stamp(),
            player_id: "player-1".to_owned(),
            output: vec![StrategicResourceAmountDto {
                resource: ResourceTypeDto::Oil,
                amount: 1,
            }],
            sources: vec![StrategicResourceSourceDto {
                city_id: "city-1".to_owned(),
                coordinate: coordinate(4, 4),
                resource: ResourceTypeDto::Oil,
                improvement: FieldImprovementKindDto::OilWell,
                amount_per_turn: 1,
            }],
        },
    }
}
