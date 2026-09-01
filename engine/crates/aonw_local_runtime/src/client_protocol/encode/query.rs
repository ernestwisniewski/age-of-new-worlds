use aonw_contract_mapping::{
    encode_city_building, encode_city_project, encode_city_specialization, encode_city_wonder,
    encode_client_stamp, encode_combat_preview, encode_command_rejection, encode_improvement,
    encode_resource, encode_troop, encode_unit_kind, encode_worker_automation_option,
};
use aonw_contracts::client::{
    AutoExploreOptionDto, CityExpansionCandidateDto, CitySpecializationOptionDto,
    CityYieldContributionDto, CityYieldContributionKindDto, ClientQueryResultDto,
    DetachmentOptionDto, MerchantDestinationOptionDto, MovementSearchMetricsDto,
    MovementStepViewDto, ProductionOptionDto, ReachableTileViewDto, StrategicResourceAmountDto,
    StrategicResourceSourceDto, UnitProductionOptionDto, WorkerImprovementOptionDto, YieldValueDto,
};
use aonw_contracts::{CityProductionTargetDto, StrategicResourceStockpileDto};
use aonw_domain::{CityProductionTarget, StrategicResourceStockpile};
use aonw_engine::{
    CityExpansionOptions, CityFoundingOptions, CityWorkedHexOptions, CityYieldBreakdown,
    CityYieldContributionKind, ProductionOption, ProductionOptions, StrategicResourceProjection,
    YieldValue,
};

use crate::{RuntimeQueryResult, SessionStamp};

use super::map_view::coordinate;
use super::research::research_options;

pub(crate) fn query_result(value: &RuntimeQueryResult) -> ClientQueryResultDto {
    match value {
        RuntimeQueryResult::ResearchOptions {
            stamp: value_stamp,
            options,
        } => research_options(*value_stamp, options),
        RuntimeQueryResult::CityFoundingOptions {
            stamp: value_stamp,
            options,
        } => city_founding_options(*value_stamp, options),
        RuntimeQueryResult::CityWorkedHexOptions {
            stamp: value_stamp,
            options,
        } => city_worked_hex_options(*value_stamp, options),
        RuntimeQueryResult::CityExpansionOptions {
            stamp: value_stamp,
            options,
        } => city_expansion_options(*value_stamp, options),
        RuntimeQueryResult::CityYield {
            stamp: value_stamp,
            breakdown,
        } => city_yield(*value_stamp, breakdown),
        RuntimeQueryResult::StrategicResourceProjection {
            stamp: value_stamp,
            projection,
        } => strategic_resource_projection(*value_stamp, projection),
        RuntimeQueryResult::ProductionOptions {
            stamp: value_stamp,
            options,
        } => production_options(*value_stamp, options),
        RuntimeQueryResult::CombatPreview {
            stamp: value_stamp,
            preview,
        } => ClientQueryResultDto::CombatPreview {
            stamp: encode_client_stamp(*value_stamp),
            preview: encode_combat_preview(preview),
        },
        RuntimeQueryResult::Reachable(value) => ClientQueryResultDto::Reachable {
            stamp: encode_client_stamp(value.stamp),
            unit_id: value.unit_id.as_str().to_owned(),
            available_movement_units: value.available_movement.get(),
            tiles: value
                .tiles
                .iter()
                .map(|tile| ReachableTileViewDto {
                    coordinate: coordinate(tile.coordinate),
                    cost_units: tile.cost.get(),
                    exhausts_movement: tile.exhausts_movement,
                })
                .collect(),
        },
        RuntimeQueryResult::RoutePlan(value) => ClientQueryResultDto::RoutePlan {
            stamp: encode_client_stamp(value.stamp),
            unit_id: value.unit_id.as_str().to_owned(),
            target: coordinate(value.target),
            destination: coordinate(value.destination),
            total_cost_units: value.total_cost.get(),
            available_movement_units: value.available_movement.get(),
            remaining_movement_units: value.remaining_movement.get(),
            estimated_turns: value.estimated_turns,
            steps: value
                .steps
                .iter()
                .map(|step| MovementStepViewDto {
                    coordinate: coordinate(step.coordinate),
                    enter_cost_units: step.enter_cost.get(),
                    cumulative_cost_units: step.cumulative_cost.get(),
                })
                .collect(),
        },
        RuntimeQueryResult::UnitLogisticsOptions(value) => logistics_options(value),
        RuntimeQueryResult::WorkerOptions {
            stamp: value_stamp,
            options,
        } => worker_options(*value_stamp, options),
    }
}

fn logistics_options(value: &crate::UnitLogisticsOptionsResult) -> ClientQueryResultDto {
    ClientQueryResultDto::UnitLogisticsOptions {
        stamp: encode_client_stamp(value.stamp),
        unit_id: value.unit_id.as_str().to_owned(),
        auto_explore: value.auto_explore.map(|option| AutoExploreOptionDto {
            target: coordinate(option.target),
            total_cost_units: option.total_cost.get(),
            search_metrics: movement_metrics(option.search_metrics),
        }),
        merchant_route_destinations: value
            .merchant_route_destinations
            .iter()
            .map(merchant_destination)
            .collect(),
        merchant_travel_destinations: value
            .merchant_travel_destinations
            .iter()
            .map(merchant_destination)
            .collect(),
        detachments: value
            .detachments
            .iter()
            .map(|option| DetachmentOptionDto {
                troop_kind: encode_troop(option.troop_kind),
                destination: coordinate(option.destination),
            })
            .collect(),
    }
}

fn production_options(
    value_stamp: SessionStamp,
    value: &ProductionOptions,
) -> ClientQueryResultDto {
    ClientQueryResultDto::ProductionOptions {
        stamp: encode_client_stamp(value_stamp),
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

fn city_yield(value_stamp: SessionStamp, value: &CityYieldBreakdown) -> ClientQueryResultDto {
    ClientQueryResultDto::CityYield {
        stamp: encode_client_stamp(value_stamp),
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
    value_stamp: SessionStamp,
    value: &StrategicResourceProjection,
) -> ClientQueryResultDto {
    ClientQueryResultDto::StrategicResourceProjection {
        stamp: encode_client_stamp(value_stamp),
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

fn worker_options(
    value_stamp: SessionStamp,
    options: &aonw_engine::WorkerOptions,
) -> ClientQueryResultDto {
    ClientQueryResultDto::WorkerOptions {
        stamp: encode_client_stamp(value_stamp),
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
    value_stamp: SessionStamp,
    options: &CityFoundingOptions,
) -> ClientQueryResultDto {
    ClientQueryResultDto::CityFoundingOptions {
        stamp: encode_client_stamp(value_stamp),
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
    value_stamp: SessionStamp,
    options: &CityWorkedHexOptions,
) -> ClientQueryResultDto {
    ClientQueryResultDto::CityWorkedHexOptions {
        stamp: encode_client_stamp(value_stamp),
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
    value_stamp: SessionStamp,
    options: &CityExpansionOptions,
) -> ClientQueryResultDto {
    ClientQueryResultDto::CityExpansionOptions {
        stamp: encode_client_stamp(value_stamp),
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

pub(super) fn movement_metrics(
    value: aonw_engine::MovementSearchMetrics,
) -> MovementSearchMetricsDto {
    MovementSearchMetricsDto {
        frontier_pops: value.frontier_pops(),
        expanded_tiles: value.expanded_tiles(),
        examined_edges: value.examined_edges(),
        heap_pushes: value.heap_pushes(),
        route_records: value.route_records(),
    }
}

pub(super) fn merchant_destination(
    value: &crate::MerchantDestinationView,
) -> MerchantDestinationOptionDto {
    MerchantDestinationOptionDto {
        city_id: value.city_id.as_str().to_owned(),
        total_cost_units: value.total_cost.get(),
    }
}

#[cfg(test)]
mod tests {
    use aonw_contracts::client::CityYieldContributionKindDto;
    use aonw_engine::CityYieldContributionKind;

    use super::yield_kind;

    #[test]
    fn city_yield_kind_mapping_is_total() {
        let cases = [
            (
                CityYieldContributionKind::Center,
                CityYieldContributionKindDto::Center,
            ),
            (
                CityYieldContributionKind::Population,
                CityYieldContributionKindDto::Population,
            ),
            (
                CityYieldContributionKind::Worker,
                CityYieldContributionKindDto::Worker,
            ),
            (
                CityYieldContributionKind::PassiveImprovement,
                CityYieldContributionKindDto::PassiveImprovement,
            ),
            (
                CityYieldContributionKind::Artifact,
                CityYieldContributionKindDto::Artifact,
            ),
        ];
        for (source, expected) in cases {
            assert_eq!(yield_kind(source), expected);
        }
    }
}
