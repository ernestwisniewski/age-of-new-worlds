use crate::CoordinateDto;
use serde::{Deserialize, Serialize};

/// Read-only queries available to local clients.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ClientQueryDto {
    /// Returns the actor-filtered profile of one map hex.
    HexInspection {
        expected_revision: u64,
        coordinate: CoordinateDto,
    },
    /// Returns every technology with current availability, cost, and progress.
    ResearchOptions { expected_revision: u64 },
    /// Returns legal initial territory choices for one founder.
    CityFoundingOptions {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Controlled settler or commander carrying settlers.
        founder_unit_id: String,
    },
    /// Returns controlled, manual, and effective worked coordinates.
    CityWorkedHexOptions {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Controlled city.
        city_id: String,
    },
    /// Returns deterministically ranked territory-expansion candidates.
    CityExpansionOptions {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Controlled city.
        city_id: String,
    },
    /// Returns a complete display-ready tile yield for one city.
    CityYield {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Controlled city.
        city_id: String,
    },
    /// Returns actor-owned strategic resource output after technology gates.
    StrategicResourceProjection {
        /// Revision observed by the client.
        expected_revision: u64,
    },
    /// Returns complete production choices and blockers for one city.
    ProductionOptions {
        expected_revision: u64,
        city_id: String,
    },
    /// Returns current worker actions and an engine-selected automation target.
    WorkerOptions {
        expected_revision: u64,
        unit_id: String,
    },
    /// Returns effective combat stats and damage bounds without RNG evidence.
    CombatPreview {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Controlled attacking unit.
        attacker_unit_id: String,
        /// Visible target coordinate.
        defender: CoordinateDto,
    },
    /// Returns every current-turn reachable coordinate.
    Reachable {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Unit inspected by the query.
        unit_id: String,
    },
    /// Plans a deterministic route toward one coordinate.
    RoutePlan {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Unit inspected by the query.
        unit_id: String,
        /// Requested target.
        target: CoordinateDto,
    },
    /// Returns engine-owned logistics options for one controlled unit.
    UnitLogisticsOptions {
        /// Revision observed by the client.
        expected_revision: u64,
        /// Unit inspected by the query.
        unit_id: String,
    },
}
