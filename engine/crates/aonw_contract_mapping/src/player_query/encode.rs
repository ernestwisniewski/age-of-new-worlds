use aonw_contracts::client::{
    AutoExploreOptionDto, CityExpansionCandidateDto, CitySpecializationOptionDto,
    CityYieldContributionDto, CityYieldContributionKindDto, ClientQueryResultDto,
    DetachmentOptionDto, MerchantDestinationOptionDto, MovementSearchMetricsDto,
    MovementStepViewDto, ProductionOptionDto, ReachableTileViewDto, StrategicResourceAmountDto,
    StrategicResourceSourceDto, UnitProductionOptionDto, WorkerImprovementOptionDto, YieldValueDto,
};
use aonw_contracts::{CityProductionTargetDto, CoordinateDto, StrategicResourceStockpileDto};
use aonw_domain::{CityProductionTarget, HexCoord, StrategicResourceStockpile};
use aonw_engine::{
    CityExpansionOptions, CityFoundingOptions, CityWorkedHexOptions, CityYieldBreakdown,
    CityYieldContributionKind, MovementSearchMetrics, ProductionOption, ProductionOptions,
    QueryResult, StrategicResourceProjection, UnitLogisticsOptions, WorkerOptions, YieldValue,
};
use aonw_projection::SessionStamp;

use crate::{
    encode_city_building, encode_city_project, encode_city_specialization, encode_city_wonder,
    encode_client_stamp, encode_combat_preview, encode_command_rejection, encode_improvement,
    encode_resource, encode_troop, encode_unit_kind, encode_worker_automation_option,
};

use super::research::research_options;

pub(super) fn query_result(stamp: SessionStamp, value: &QueryResult) -> ClientQueryResultDto {
    match value {
        QueryResult::ResearchOptions(options) => research_options(stamp, options),
        QueryResult::CityFoundingOptions(options) => city_founding_options(stamp, options),
        QueryResult::CityWorkedHexOptions(options) => city_worked_hex_options(stamp, options),
        QueryResult::CityExpansionOptions(options) => city_expansion_options(stamp, options),
        QueryResult::CityYield(breakdown) => city_yield(stamp, breakdown),
        QueryResult::StrategicResourceProjection(projection) => {
            strategic_resource_projection(stamp, projection)
        }
        QueryResult::ProductionOptions(options) => production_options(stamp, options),
        QueryResult::CombatPreview(preview) => ClientQueryResultDto::CombatPreview {
            stamp: encode_client_stamp(stamp),
            preview: encode_combat_preview(preview),
        },
        QueryResult::Reachable(result) => ClientQueryResultDto::Reachable {
            stamp: encode_client_stamp(stamp),
            unit_id: result.unit_id().as_str().to_owned(),
            available_movement_units: result.available_movement().get(),
            tiles: result
                .tiles()
                .iter()
                .map(|tile| ReachableTileViewDto {
                    coordinate: coordinate(tile.coordinate()),
                    cost_units: tile.cost().get(),
                    exhausts_movement: tile.exhausts_movement(),
                })
                .collect(),
        },
        QueryResult::Route(result) => ClientQueryResultDto::RoutePlan {
            stamp: encode_client_stamp(stamp),
            unit_id: result.unit_id().as_str().to_owned(),
            target: coordinate(result.target()),
            destination: coordinate(result.destination()),
            total_cost_units: result.total_cost().get(),
            available_movement_units: result.available_movement().get(),
            remaining_movement_units: result.remaining_movement().get(),
            steps: result
                .steps()
                .iter()
                .map(|step| MovementStepViewDto {
                    coordinate: coordinate(step.coordinate()),
                    enter_cost_units: step.enter_cost().get(),
                    cumulative_cost_units: step.cumulative_cost().get(),
                })
                .collect(),
        },
        QueryResult::UnitLogisticsOptions(options) => logistics_options(stamp, options),
        QueryResult::WorkerOptions(options) => worker_options(stamp, options),
        QueryResult::EconomyForecast(_) => {
            unreachable!("economy forecast has no public client query variant")
        }
    }
}

fn logistics_options(stamp: SessionStamp, value: &UnitLogisticsOptions) -> ClientQueryResultDto {
    ClientQueryResultDto::UnitLogisticsOptions {
        stamp: encode_client_stamp(stamp),
        unit_id: value.unit_id().as_str().to_owned(),
        auto_explore: value.auto_explore().map(|option| AutoExploreOptionDto {
            target: coordinate(option.target()),
            total_cost_units: option.total_cost_units(),
            search_metrics: movement_metrics(option.search_metrics()),
        }),
        merchant_route_destinations: value
            .merchant_route_destinations()
            .iter()
            .map(merchant_destination)
            .collect(),
        merchant_travel_destinations: value
            .merchant_travel_destinations()
            .iter()
            .map(merchant_destination)
            .collect(),
        detachments: value
            .detachments()
            .iter()
            .map(|option| DetachmentOptionDto {
                troop_kind: encode_troop(option.troop_kind()),
                destination: coordinate(option.destination()),
            })
            .collect(),
    }
}

fn production_options(stamp: SessionStamp, value: &ProductionOptions) -> ClientQueryResultDto {
    ClientQueryResultDto::ProductionOptions {
        stamp: encode_client_stamp(stamp),
        city_id: value.city_id().as_str().to_owned(),
        current_target: value.current_target().map(production_target),
        invested_production: value.invested_production(),
        production_overflow: value.production_overflow(),
        buildings: value
            .buildings()
            .iter()
            .copied()
            .map(production_option)
            .collect(),
        units: value
            .units()
            .iter()
            .map(|value| UnitProductionOptionDto {
                option: production_option(value.option()),
                resource_options: value.resource_options().iter().map(stockpile).collect(),
                affordable_resource_option_indices: value
                    .affordable_resource_option_indices()
                    .to_vec(),
            })
            .collect(),
        projects: value
            .projects()
            .iter()
            .copied()
            .map(production_option)
            .collect(),
        wonders: value
            .wonders()
            .iter()
            .copied()
            .map(production_option)
            .collect(),
        specializations: value
            .specializations()
            .iter()
            .copied()
            .map(|value| CitySpecializationOptionDto {
                specialization: encode_city_specialization(value.specialization()),
                required_building: encode_city_building(value.required_building()),
                rejection: value.rejection().map(encode_command_rejection),
            })
            .collect(),
    }
}

fn production_option(value: ProductionOption) -> ProductionOptionDto {
    ProductionOptionDto {
        target: production_target(value.target()),
        cost: value.cost(),
        rejection: value.rejection().map(encode_command_rejection),
    }
}

fn production_target(value: CityProductionTarget) -> CityProductionTargetDto {
    match value {
        CityProductionTarget::Building(building) => CityProductionTargetDto::Building {
            building_type: encode_city_building(building),
        },
        CityProductionTarget::Unit(unit) => CityProductionTargetDto::Unit {
            unit_type: encode_unit_kind(unit),
        },
        CityProductionTarget::Project(project) => CityProductionTargetDto::Project {
            project_type: encode_city_project(project),
        },
        CityProductionTarget::Wonder(wonder) => CityProductionTargetDto::Wonder {
            wonder_type: encode_city_wonder(wonder),
        },
    }
}

fn stockpile(value: &StrategicResourceStockpile) -> StrategicResourceStockpileDto {
    StrategicResourceStockpileDto(
        value
            .amounts()
            .iter()
            .map(|(resource, amount)| (encode_resource(*resource), *amount))
            .collect(),
    )
}

fn city_yield(stamp: SessionStamp, value: &CityYieldBreakdown) -> ClientQueryResultDto {
    ClientQueryResultDto::CityYield {
        stamp: encode_client_stamp(stamp),
        city_id: value.city_id().as_str().to_owned(),
        contributions: value
            .contributions()
            .iter()
            .map(|contribution| CityYieldContributionDto {
                kind: yield_kind(contribution.kind()),
                coordinate: coordinate(contribution.coordinate()),
                value: yield_value(contribution.value()),
            })
            .collect(),
        total: yield_value(value.total()),
    }
}

fn strategic_resource_projection(
    stamp: SessionStamp,
    value: &StrategicResourceProjection,
) -> ClientQueryResultDto {
    ClientQueryResultDto::StrategicResourceProjection {
        stamp: encode_client_stamp(stamp),
        player_id: value.player_id().as_str().to_owned(),
        output: value
            .output()
            .iter()
            .map(|(resource, amount)| StrategicResourceAmountDto {
                resource: encode_resource(*resource),
                amount: *amount,
            })
            .collect(),
        sources: value
            .sources()
            .iter()
            .map(|source| StrategicResourceSourceDto {
                city_id: source.city_id().as_str().to_owned(),
                coordinate: coordinate(source.coordinate()),
                resource: encode_resource(source.resource()),
                improvement: encode_improvement(source.improvement()),
                amount_per_turn: source.amount_per_turn(),
            })
            .collect(),
    }
}

const fn yield_kind(value: CityYieldContributionKind) -> CityYieldContributionKindDto {
    match value {
        CityYieldContributionKind::Center => CityYieldContributionKindDto::Center,
        CityYieldContributionKind::Population => CityYieldContributionKindDto::Population,
        CityYieldContributionKind::Worker => CityYieldContributionKindDto::Worker,
        CityYieldContributionKind::PassiveImprovement => {
            CityYieldContributionKindDto::PassiveImprovement
        }
        CityYieldContributionKind::Artifact => CityYieldContributionKindDto::Artifact,
    }
}

const fn yield_value(value: YieldValue) -> YieldValueDto {
    YieldValueDto {
        food: value.food,
        production: value.production,
        gold: value.gold,
        defense: value.defense,
    }
}

fn worker_options(stamp: SessionStamp, options: &WorkerOptions) -> ClientQueryResultDto {
    ClientQueryResultDto::WorkerOptions {
        stamp: encode_client_stamp(stamp),
        unit_id: options.unit_id().as_str().to_owned(),
        coordinate: coordinate(options.coordinate()),
        improvements: options
            .improvements()
            .iter()
            .map(|option| WorkerImprovementOptionDto {
                improvement: encode_improvement(option.kind()),
                build_turns: option.build_turns(),
            })
            .collect(),
        can_assign: options.can_assign(),
        can_build_road: options.can_build_road(),
        automation: options.automation().map(encode_worker_automation_option),
    }
}

fn city_founding_options(
    stamp: SessionStamp,
    options: &CityFoundingOptions,
) -> ClientQueryResultDto {
    ClientQueryResultDto::CityFoundingOptions {
        stamp: encode_client_stamp(stamp),
        founder_unit_id: options.founder_unit_id().as_str().to_owned(),
        center: coordinate(options.center()),
        selected_controlled_hexes: options
            .selected_controlled_hexes()
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
        available_controlled_hexes: options
            .available_controlled_hexes()
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
        required_controlled_hexes: options.required_controlled_hexes(),
        maximum_radius: options.maximum_radius(),
    }
}

fn city_worked_hex_options(
    stamp: SessionStamp,
    options: &CityWorkedHexOptions,
) -> ClientQueryResultDto {
    ClientQueryResultDto::CityWorkedHexOptions {
        stamp: encode_client_stamp(stamp),
        city_id: options.city_id().as_str().to_owned(),
        center: coordinate(options.center()),
        controlled_hexes: options
            .controlled_hexes()
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
        available_hexes: options
            .available_hexes()
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
        selected_hexes: options
            .selected_hexes()
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
        effective_hexes: options
            .effective_hexes()
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
        limit: options.limit(),
    }
}

fn city_expansion_options(
    stamp: SessionStamp,
    options: &CityExpansionOptions,
) -> ClientQueryResultDto {
    ClientQueryResultDto::CityExpansionOptions {
        stamp: encode_client_stamp(stamp),
        city_id: options.city_id().as_str().to_owned(),
        controlled_hexes: options
            .controlled_hexes()
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
        preferred_hex: options.preferred_hex().map(coordinate),
        candidates: options
            .candidates()
            .iter()
            .map(|candidate| CityExpansionCandidateDto {
                coordinate: coordinate(candidate.coordinate()),
                score: candidate.score(),
                distance: candidate.distance(),
            })
            .collect(),
    }
}

fn movement_metrics(value: MovementSearchMetrics) -> MovementSearchMetricsDto {
    MovementSearchMetricsDto {
        frontier_pops: value.frontier_pops(),
        expanded_tiles: value.expanded_tiles(),
        examined_edges: value.examined_edges(),
        heap_pushes: value.heap_pushes(),
        route_records: value.route_records(),
    }
}

fn merchant_destination(
    value: &aonw_engine::MerchantDestinationOption,
) -> MerchantDestinationOptionDto {
    MerchantDestinationOptionDto {
        city_id: value.city_id().as_str().to_owned(),
        total_cost_units: value.total_cost_units(),
    }
}

const fn coordinate(value: HexCoord) -> CoordinateDto {
    CoordinateDto {
        col: value.col(),
        row: value.row(),
    }
}
