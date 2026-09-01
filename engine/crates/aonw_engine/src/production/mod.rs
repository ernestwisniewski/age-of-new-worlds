mod commands;
mod error;
mod model;
mod rules;
mod rush;
mod spawn;
mod supply;
mod support;
mod turn;
mod wonder;
mod yield_rules;

pub use error::ProductionError;
pub use model::{
    CitySpecializationOption, ProductionOption, ProductionOptions, ProductionOptionsQuery,
    RushProductionCommand, SetCitySpecializationCommand, StartBuildingCommand,
    StartCityProjectCommand, StartUnitProductionCommand, StartWonderCommand, UnitProductionOption,
};

pub(crate) use commands::{
    ProductionMutation, apply_set_specialization, apply_start_building, apply_start_project,
    apply_start_unit, apply_start_wonder,
};
pub(crate) use rules::query_options;
pub(crate) use rush::apply_rush;
pub(crate) use turn::{
    ResearchProjectScience, advance_turn_production, selected_research_project_science,
    selected_wealth_project_gold,
};
