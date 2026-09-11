mod commands;
mod error;
mod model;
mod recommendation;
mod rules;
mod science;
mod turn;

pub use error::ResearchError;
pub use model::{
    CancelResearchSelectionCommand, ResearchOption, ResearchOptions, ResearchOptionsQuery,
    SelectTechnologyCommand,
};
pub use recommendation::{ResearchRecommendation, ResearchRecommendationReason};
pub use science::{ScienceYieldBreakdown, ScienceYieldSource, ScienceYieldSourceKind};

pub(crate) use commands::{
    ResearchMutation, apply_cancel_research_selection, apply_select_technology,
};
pub(crate) use rules::query_options;
pub(crate) use turn::advance_turn_research;
