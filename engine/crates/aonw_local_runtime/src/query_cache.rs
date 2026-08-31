use aonw_content::ContentHash;
use aonw_domain::{CityId, HexCoord, UnitId};
use aonw_engine::StateDigest;

use crate::{RuntimeQuery, RuntimeQueryResult, SessionStamp};

const MAX_QUERY_CACHE_ENTRIES: usize = 64;

#[derive(Clone, Debug, Eq, PartialEq)]
enum QueryKind {
    ResearchOptions,
    CityFoundingOptions,
    CityWorkedHexOptions,
    CityExpansionOptions,
    CityYield,
    StrategicResourceProjection,
    ProductionOptions,
    CombatPreview(HexCoord),
    Reachable,
    RoutePlan(HexCoord),
    UnitLogisticsOptions,
    WorkerOptions,
}

#[derive(Clone, Debug, Eq, PartialEq)]
enum QuerySubject {
    Actor,
    Unit(UnitId),
    City(CityId),
}

#[derive(Clone, Debug, Eq, PartialEq)]
struct QueryCacheKey {
    revision: u64,
    expected_revision: u64,
    subject: QuerySubject,
    visibility_digest: StateDigest,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
    kind: QueryKind,
}

impl QueryCacheKey {
    fn new(stamp: SessionStamp, request: &RuntimeQuery) -> Self {
        let (expected_revision, subject, kind) = match request {
            RuntimeQuery::ResearchOptions(request) => (
                request.expected_revision,
                QuerySubject::Actor,
                QueryKind::ResearchOptions,
            ),
            RuntimeQuery::CityFoundingOptions(request) => (
                request.expected_revision,
                QuerySubject::Unit(request.founder_unit_id.clone()),
                QueryKind::CityFoundingOptions,
            ),
            RuntimeQuery::CityWorkedHexOptions(request) => (
                request.expected_revision,
                QuerySubject::City(request.city_id.clone()),
                QueryKind::CityWorkedHexOptions,
            ),
            RuntimeQuery::CityExpansionOptions(request) => (
                request.expected_revision,
                QuerySubject::City(request.city_id.clone()),
                QueryKind::CityExpansionOptions,
            ),
            RuntimeQuery::CityYield(request) => (
                request.expected_revision,
                QuerySubject::City(request.city_id.clone()),
                QueryKind::CityYield,
            ),
            RuntimeQuery::StrategicResourceProjection(request) => (
                request.expected_revision,
                QuerySubject::Actor,
                QueryKind::StrategicResourceProjection,
            ),
            RuntimeQuery::ProductionOptions(request) => (
                request.expected_revision,
                QuerySubject::City(request.city_id.clone()),
                QueryKind::ProductionOptions,
            ),
            RuntimeQuery::CombatPreview(request) => (
                request.expected_revision,
                QuerySubject::Unit(request.attacker_unit_id.clone()),
                QueryKind::CombatPreview(request.defender),
            ),
            RuntimeQuery::Reachable(request) => (
                request.expected_revision,
                QuerySubject::Unit(request.unit_id.clone()),
                QueryKind::Reachable,
            ),
            RuntimeQuery::RoutePlan(request) => (
                request.expected_revision,
                QuerySubject::Unit(request.unit_id.clone()),
                QueryKind::RoutePlan(request.target),
            ),
            RuntimeQuery::UnitLogisticsOptions(request) => (
                request.expected_revision,
                QuerySubject::Unit(request.unit_id.clone()),
                QueryKind::UnitLogisticsOptions,
            ),
            RuntimeQuery::WorkerOptions(request) => (
                request.expected_revision,
                QuerySubject::Unit(request.unit_id.clone()),
                QueryKind::WorkerOptions,
            ),
        };
        Self {
            revision: stamp.revision.get(),
            expected_revision,
            subject,
            visibility_digest: stamp.state_digest,
            map_hash: stamp.map_hash,
            ruleset_hash: stamp.ruleset_hash,
            kind,
        }
    }
}

/// Diagnostic counters for the bounded runtime query cache.
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub struct QueryCacheStats {
    /// Exact-key cache hits.
    pub hits: u64,
    /// Queries requiring engine execution.
    pub misses: u64,
}

#[derive(Clone, Debug, Default)]
pub(crate) struct QueryCache {
    scope: Option<SessionStamp>,
    entries: Vec<(QueryCacheKey, RuntimeQueryResult)>,
    stats: QueryCacheStats,
}

impl QueryCache {
    pub(crate) fn get(
        &mut self,
        stamp: SessionStamp,
        request: &RuntimeQuery,
    ) -> Option<RuntimeQueryResult> {
        self.prepare_scope(stamp);
        let key = QueryCacheKey::new(stamp, request);
        if let Some(index) = self
            .entries
            .iter()
            .position(|(cached_key, _)| cached_key == &key)
        {
            self.stats.hits = self.stats.hits.saturating_add(1);
            let entry = self.entries.remove(index);
            let result = entry.1.clone();
            self.entries.push(entry);
            return Some(result);
        }
        self.stats.misses = self.stats.misses.saturating_add(1);
        None
    }

    pub(crate) fn insert(
        &mut self,
        stamp: SessionStamp,
        request: &RuntimeQuery,
        result: &RuntimeQueryResult,
    ) {
        self.prepare_scope(stamp);
        if self.entries.len() == MAX_QUERY_CACHE_ENTRIES {
            self.entries.remove(0);
        }
        self.entries
            .push((QueryCacheKey::new(stamp, request), result.clone()));
    }

    pub(crate) fn clear(&mut self) {
        self.scope = None;
        self.entries.clear();
    }

    pub(crate) const fn stats(&self) -> QueryCacheStats {
        self.stats
    }

    fn prepare_scope(&mut self, stamp: SessionStamp) {
        if self.scope != Some(stamp) {
            self.scope = Some(stamp);
            self.entries.clear();
        }
    }
}
