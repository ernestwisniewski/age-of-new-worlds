mod commands;
mod error;
mod model;
mod rules;
mod science;
mod turn;

pub use error::ResearchError;
pub use model::{ResearchOption, ResearchOptions, ResearchOptionsQuery, SelectTechnologyCommand};
pub use science::{ScienceYieldBreakdown, ScienceYieldSource, ScienceYieldSourceKind};

pub(crate) use commands::{ResearchMutation, apply_select_technology};
pub(crate) use rules::query_options;
pub(crate) use turn::advance_turn_research;
