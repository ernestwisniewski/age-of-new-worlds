use aonw_contracts::client::{
    ClientQueryResultDto, ClientResponseBodyDto, MovementStepViewDto, ReachableTileViewDto,
};

use super::{coordinate, stamp};

pub(super) fn responses() -> Vec<ClientResponseBodyDto> {
    let query_stamp = stamp();
    vec![
        ClientResponseBodyDto::Query {
            result: ClientQueryResultDto::Reachable {
                stamp: query_stamp.clone(),
                unit_id: "unit-1".to_owned(),
                available_movement_units: 8,
                can_start_targeting: true,
                can_retain_targeting: true,
                tiles: vec![ReachableTileViewDto {
                    coordinate: coordinate(4, 4),
                    cost_units: 2,
                    exhausts_movement: false,
                }],
            },
        },
        ClientResponseBodyDto::Query {
            result: ClientQueryResultDto::RoutePlan {
                stamp: query_stamp,
                unit_id: "unit-1".to_owned(),
                target: coordinate(4, 4),
                destination: coordinate(4, 4),
                total_cost_units: 2,
                available_movement_units: 8,
                remaining_movement_units: 6,
                estimated_turns: 1,
                step_turns: vec![1],
                steps: vec![MovementStepViewDto {
                    coordinate: coordinate(4, 4),
                    enter_cost_units: 2,
                    cumulative_cost_units: 2,
                }],
            },
        },
    ]
}
