use aonw_domain::GameState;

use crate::{
    CityExpansionOptions, CityExpansionOptionsQuery, CityFoundingOptions, CityFoundingOptionsQuery,
    CityWorkedHexOptions, CityWorkedHexOptionsQuery, CityYieldBreakdown, CityYieldQuery,
    CombatPreview, CombatPreviewQuery, EconomyForecast, EconomyForecastQuery, EngineContext,
    GameEngine, MovementSearchWorkspace, ProductionOptions, ProductionOptionsQuery,
    ReachableMovement, ReachableMovementQuery, ResearchOptions, ResearchOptionsQuery,
    StrategicResourceProjection, StrategicResourceProjectionQuery, TerrainMovementPlan,
    TerrainMovementQuery, TerrainMovementQueryError, UnitLogisticsOptions,
    UnitLogisticsOptionsQuery, WorkerOptions, WorkerOptionsQuery,
};

/// Read-only game query family.
#[derive(Clone, Copy, Debug)]
pub enum GameQuery<'query> {
    /// Returns founding legality and engine-owned initial territory choices.
    CityFoundingOptions(CityFoundingOptionsQuery<'query>),
    /// Returns controlled/manual/effective worked coordinates.
    CityWorkedHexOptions(CityWorkedHexOptionsQuery<'query>),
    /// Returns deterministically ranked expansion candidates.
    CityExpansionOptions(CityExpansionOptionsQuery<'query>),
    /// Returns a display-ready breakdown of tile-level city yield.
    CityYield(CityYieldQuery<'query>),
    /// Returns actor-owned gold, upkeep, and stability forecast evidence.
    EconomyForecast(EconomyForecastQuery),
    /// Returns actor-owned strategic resource extraction after technology gates.
    StrategicResourceProjection(StrategicResourceProjectionQuery),
    /// Returns complete production and specialization availability for one city.
    ProductionOptions(ProductionOptionsQuery<'query>),
    /// Recipient-safe combat preview without seed or rolls.
    CombatPreview(CombatPreviewQuery<'query>),
    /// Route preview for one target.
    PlanRoute(TerrainMovementQuery<'query>),
    /// Current-turn reachable overlay.
    Reachable(ReachableMovementQuery<'query>),
    /// Complete engine-owned logistics options for one unit.
    UnitLogisticsOptions(UnitLogisticsOptionsQuery<'query>),
    /// Complete legal worker options and deterministic automation target.
    WorkerOptions(WorkerOptionsQuery<'query>),
    /// Every technology with engine-owned availability, cost, and progress.
    ResearchOptions(ResearchOptionsQuery),
}

/// Typed query result.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum QueryResult {
    /// Legal initial territory for one founder.
    CityFoundingOptions(CityFoundingOptions),
    /// Legal worked-hex state for one city.
    CityWorkedHexOptions(CityWorkedHexOptions),
    /// Legal preferred-expansion candidates for one city.
    CityExpansionOptions(CityExpansionOptions),
    /// Checked tile-level city yield contributions.
    CityYield(CityYieldBreakdown),
    /// Complete actor-owned next-settlement economy forecast.
    EconomyForecast(EconomyForecast),
    /// Checked strategic resource output and sources.
    StrategicResourceProjection(StrategicResourceProjection),
    /// Complete city production choices and blockers.
    ProductionOptions(ProductionOptions),
    /// Effective combat statistics and damage bounds.
    CombatPreview(CombatPreview),
    /// Planned route.
    Route(TerrainMovementPlan),
    /// Reachable coordinates.
    Reachable(ReachableMovement),
    /// Auto-explore, merchant, and detachment options.
    UnitLogisticsOptions(UnitLogisticsOptions),
    /// Improvement, assignment, road, and automation options.
    WorkerOptions(WorkerOptions),
    /// Complete actor-owned research selection choices.
    ResearchOptions(ResearchOptions),
}

/// Failure from a canonical read-only query.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum CanonicalQueryError {
    /// City query was rejected by deterministic city rules.
    City(crate::CommandRejectionCode),
    /// City query referenced incomplete technology content.
    Technology(crate::TechnologyQueryError),
    /// Combat preview was rejected without disclosing hidden target state.
    Combat(crate::CommandRejectionCode),
    /// Query was rejected by deterministic rules.
    Rejected(TerrainMovementQueryError),
    /// Logistics options were rejected by deterministic rules.
    Logistics(crate::MovementLogisticsError),
    /// Worker options were rejected by deterministic rules.
    Worker(crate::CommandRejectionCode),
    /// Economy query failed or overflowed.
    Economy(crate::EconomyQueryError),
    /// Production query was rejected or found corrupt state/content.
    Production(crate::ProductionError),
    /// Research query was rejected or found corrupt state/content.
    Research(crate::ResearchError),
    /// Victory and score projection found corrupt state/content.
    Outcome(crate::OutcomeResolutionError),
}

impl CanonicalQueryError {
    /// Returns the stable rejection or internal error code.
    #[must_use]
    pub const fn code(&self) -> &'static str {
        match self {
            Self::Technology(_) => "technology_query_invalid",
            Self::Economy(error) => error.code(),
            Self::Production(error) => error.code(),
            Self::Research(error) => error.code(),
            Self::Outcome(_) => "outcome_projection_invalid",
            Self::City(rejection) | Self::Combat(rejection) | Self::Worker(rejection) => {
                rejection.as_str()
            }
            Self::Rejected(rejection) => rejection.code().as_str(),
            Self::Logistics(rejection) => rejection.code().as_str(),
        }
    }
}

impl core::fmt::Display for CanonicalQueryError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::Technology(source) => source.fmt(formatter),
            Self::Economy(source) => source.fmt(formatter),
            Self::Production(source) => source.fmt(formatter),
            Self::Research(source) => source.fmt(formatter),
            Self::Outcome(source) => source.fmt(formatter),
            Self::City(source) | Self::Combat(source) | Self::Worker(source) => {
                source.fmt(formatter)
            }
            Self::Rejected(source) => source.fmt(formatter),
            Self::Logistics(source) => source.fmt(formatter),
        }
    }
}

impl std::error::Error for CanonicalQueryError {}

impl GameEngine {
    /// Executes a query without accepting client-owned visibility.
    ///
    /// # Errors
    ///
    /// Returns a deterministic query rejection or an invalid-state error.
    pub fn query(
        state: &GameState,
        context: EngineContext<'_>,
        query: GameQuery<'_>,
    ) -> Result<QueryResult, CanonicalQueryError> {
        let mut workspace = MovementSearchWorkspace::default();
        Self::query_with_workspace(state, context, query, &mut workspace)
    }

    /// Executes a query while reusing caller-owned search storage.
    ///
    /// # Errors
    ///
    /// Returns a deterministic query rejection or an invalid-state error.
    pub fn query_with_workspace(
        state: &GameState,
        context: EngineContext<'_>,
        query: GameQuery<'_>,
        workspace: &mut MovementSearchWorkspace,
    ) -> Result<QueryResult, CanonicalQueryError> {
        let context = context.with_world(state);
        match query {
            GameQuery::CityFoundingOptions(query) => {
                crate::city::query_founding(state, context, query)
                    .map(QueryResult::CityFoundingOptions)
                    .map_err(city_query_error)
            }
            GameQuery::CityWorkedHexOptions(query) => {
                crate::city::query_worked_hexes(state, context, query)
                    .map(QueryResult::CityWorkedHexOptions)
                    .map_err(city_query_error)
            }
            GameQuery::CityExpansionOptions(query) => {
                crate::city::query_expansion(state, context, query)
                    .map(QueryResult::CityExpansionOptions)
                    .map_err(city_query_error)
            }
            GameQuery::CityYield(query) => crate::economy::query_city_yield(state, context, query)
                .map(QueryResult::CityYield)
                .map_err(CanonicalQueryError::Economy),
            GameQuery::EconomyForecast(query) => {
                crate::economy::query_economy_forecast(state, context, query)
                    .map(QueryResult::EconomyForecast)
                    .map_err(CanonicalQueryError::Economy)
            }
            GameQuery::StrategicResourceProjection(query) => {
                crate::economy::query_strategic_resource_projection(state, context, query)
                    .map(QueryResult::StrategicResourceProjection)
                    .map_err(CanonicalQueryError::Economy)
            }
            GameQuery::ProductionOptions(query) => {
                crate::production::query_options(state, context, query)
                    .map(QueryResult::ProductionOptions)
                    .map_err(CanonicalQueryError::Production)
            }
            GameQuery::CombatPreview(query) => crate::combat::preview(state, context, query)
                .map(QueryResult::CombatPreview)
                .map_err(CanonicalQueryError::Combat),
            GameQuery::PlanRoute(query) => Self::plan_terrain_route(state, context, query)
                .map(QueryResult::Route)
                .map_err(CanonicalQueryError::Rejected),
            GameQuery::Reachable(query) => {
                Self::reachable_movement_with_workspace(state, context, query, workspace)
                    .map(QueryResult::Reachable)
                    .map_err(CanonicalQueryError::Rejected)
            }
            GameQuery::UnitLogisticsOptions(query) => {
                crate::movement::query_logistics_options(state, context, query, workspace)
                    .map(QueryResult::UnitLogisticsOptions)
                    .map_err(CanonicalQueryError::Logistics)
            }
            GameQuery::WorkerOptions(query) => crate::worker::query_options(state, context, query)
                .map(QueryResult::WorkerOptions)
                .map_err(worker_query_error),
            GameQuery::ResearchOptions(query) => {
                crate::research::query_options(state, context, query)
                    .map(QueryResult::ResearchOptions)
                    .map_err(CanonicalQueryError::Research)
            }
        }
    }
}

fn worker_query_error(error: crate::worker::WorkerRuleError) -> CanonicalQueryError {
    match error {
        crate::worker::WorkerRuleError::Rejected(code) => CanonicalQueryError::Worker(code),
    }
}

fn city_query_error(error: crate::city::CityRuleError) -> CanonicalQueryError {
    match error {
        crate::city::CityRuleError::Rejected(code) => CanonicalQueryError::City(code),
        crate::city::CityRuleError::Technology(error) => CanonicalQueryError::Technology(error),
    }
}

#[cfg(test)]
mod tests;
