use crate::{
    encode_city_building, encode_city_project, encode_city_specialization, encode_city_wonder,
    encode_client_stamp, encode_command_rejection, encode_resource, encode_technology,
    encode_unit_kind,
};
use aonw_contracts::client::{
    CitySpecializationOptionDto, ClientQueryResultDto, ProductionAvailabilityDto,
    ProductionForecastDto, ProductionOptionDto, ProductionRushQuoteDto, UnitProductionOptionDto,
};
use aonw_contracts::{CityProductionTargetDto, StrategicResourceStockpileDto};
use aonw_domain::{CityProductionTarget, StrategicResourceStockpile};
use aonw_engine::{ProductionOption, ProductionOptions};
use aonw_projection::SessionStamp;

/// Encodes city production identically for local and authenticated server queries.
pub fn encode_production_options(
    value_stamp: SessionStamp,
    value: &ProductionOptions,
) -> ClientQueryResultDto {
    ClientQueryResultDto::ProductionOptions {
        stamp: encode_client_stamp(value_stamp),
        city_id: value.city_id().as_str().to_owned(),
        current_target: value.current_target().map(production_target),
        invested_production: value.invested_production(),
        production_overflow: value.production_overflow(),
        rush_quote: ProductionRushQuoteDto {
            production: value.rush_quote().production(),
            gold_cost: value.rush_quote().gold_cost(),
            rejection: value.rush_quote().rejection().map(encode_command_rejection),
        },
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
        availability: ProductionAvailabilityDto {
            required_technology: value
                .availability()
                .required_technology()
                .map(encode_technology),
            technology_unlocked: value.availability().technology_unlocked(),
            completed_in_city: value.availability().completed_in_city(),
        },
        forecast: ProductionForecastDto {
            invested_production: value.forecast().invested_production(),
            production_per_turn: value.forecast().production_per_turn(),
            estimated_turns: value.forecast().estimated_turns(),
            project_output: value.forecast().project_output(),
            spawn_blocked: value.forecast().spawn_blocked(),
        },
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
