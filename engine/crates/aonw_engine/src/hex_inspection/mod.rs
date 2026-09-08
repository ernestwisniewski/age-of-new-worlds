mod improvements;
mod kind;
mod model;
mod query;
mod recommendation;
mod score;

pub use model::{
    HexAssessmentKind, HexAssessmentScore, HexAssessmentTag, HexImprovementAccess,
    HexImprovementOption, HexInspection, HexInspectionQuery, HexRecommendation,
};
pub use query::HexInspectionError;

#[cfg(test)]
mod tests;

impl crate::GameEngine {
    /// Inspects a map hex using canonical actor visibility and research.
    /// Static terrain can be inspected anywhere; dynamic city/improvement facts
    /// follow the same disclosure policy as recipient projections.
    ///
    /// # Errors
    ///
    /// Rejects a stale revision, unknown participant, missing hex or yield overflow.
    pub fn inspect_hex(
        state: &aonw_domain::GameState,
        context: crate::EngineContext<'_>,
        query: HexInspectionQuery,
    ) -> Result<HexInspection, HexInspectionError> {
        query::inspect(state, context.with_world(state), query)
    }
}
