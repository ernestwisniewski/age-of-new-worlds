use aonw_contracts::client::{ClientQueryDto, ClientQueryResultDto};
use aonw_domain::{CityId, UnitId};
use aonw_engine::{GameQuery, QueryResult, ResearchOptionsQuery};
use aonw_projection::SessionStamp;

mod decode;
mod encode;
mod research;

/// Invalid opaque identity found while mapping one strict client query.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerQueryMappingError {
    code: &'static str,
    message: String,
}

impl PlayerQueryMappingError {
    pub(super) fn new(code: &'static str, error: impl core::fmt::Display) -> Self {
        Self {
            code,
            message: error.to_string(),
        }
    }

    /// Returns the stable client-facing validation code.
    #[must_use]
    pub const fn code(&self) -> &'static str {
        self.code
    }
}

impl core::fmt::Display for PlayerQueryMappingError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        formatter.write_str(&self.message)
    }
}

impl std::error::Error for PlayerQueryMappingError {}

/// Maps one closed client query to an engine query for immediate use.
///
/// The callback prevents temporary decoded identities from escaping this
/// boundary. Visibility and actor ownership remain the caller's responsibility
/// through the canonical [`aonw_engine::EngineContext`].
///
/// # Errors
///
/// Returns an error when an opaque city or unit identity is invalid.
pub fn decode_client_player_query<R>(
    query: ClientQueryDto,
    execute: impl for<'query> FnOnce(GameQuery<'query>) -> R,
) -> Result<R, PlayerQueryMappingError> {
    match query {
        ClientQueryDto::ResearchOptions { expected_revision } => Ok(execute(
            GameQuery::ResearchOptions(ResearchOptionsQuery::new(expected_revision)),
        )),
        query @ (ClientQueryDto::CityFoundingOptions { .. }
        | ClientQueryDto::CityWorkedHexOptions { .. }
        | ClientQueryDto::CityExpansionOptions { .. }
        | ClientQueryDto::CityYield { .. }) => decode::city(query, execute),
        query @ (ClientQueryDto::StrategicResourceProjection { .. }
        | ClientQueryDto::ProductionOptions { .. }) => decode::economy(query, execute),
        query @ (ClientQueryDto::WorkerOptions { .. }
        | ClientQueryDto::CombatPreview { .. }
        | ClientQueryDto::Reachable { .. }
        | ClientQueryDto::RoutePlan { .. }
        | ClientQueryDto::UnitLogisticsOptions { .. }) => decode::unit(query, execute),
    }
}

/// Encodes one canonical query result with its authoritative state identity.
#[must_use]
pub fn encode_client_query_result(
    stamp: SessionStamp,
    result: &QueryResult,
) -> ClientQueryResultDto {
    encode::query_result(stamp, result)
}

pub(super) fn unit_id(value: String) -> Result<UnitId, PlayerQueryMappingError> {
    UnitId::new(value).map_err(|error| PlayerQueryMappingError::new("invalid_unit_id", error))
}

pub(super) fn city_id(value: String) -> Result<CityId, PlayerQueryMappingError> {
    CityId::new(value).map_err(|error| PlayerQueryMappingError::new("invalid_city_id", error))
}
