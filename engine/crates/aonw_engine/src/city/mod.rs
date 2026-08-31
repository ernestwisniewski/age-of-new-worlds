mod model;
mod rules;
mod turn;

pub use model::{
    CityExpansionCandidate, CityExpansionOptions, CityExpansionOptionsQuery, CityFoundingOptions,
    CityFoundingOptionsQuery, CityWorkedHexOptions, CityWorkedHexOptionsQuery, FoundCityCommand,
    SelectCityExpansionHexCommand, ToggleWorkedHexCommand,
};

pub(crate) use rules::expansion_after_growth;
pub(crate) use rules::{CityMutation, CityRuleError};
pub(crate) use rules::{apply_found_city, apply_select_expansion, apply_toggle_worked_hex};
pub(crate) use rules::{effective_worked_hexes, normalized_manual_hexes};
pub(crate) use rules::{query_expansion, query_founding, query_worked_hexes};
pub(crate) use turn::{CityFoundingTurnUpdate, advance_city_founding};
