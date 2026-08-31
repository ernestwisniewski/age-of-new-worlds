use serde::{Deserialize, Serialize};

use super::{CoordinateDto, FieldImprovementKindDto};

/// One persisted economic field improvement.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct FieldImprovementDto {
    pub coordinate: CoordinateDto,
    pub kind: FieldImprovementKindDto,
    pub built_by_city_id: Option<String>,
}

/// One persisted transport segment.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct TransportSegmentDto {
    pub coordinate: CoordinateDto,
    pub kind: TransportSegmentKindDto,
    pub condition: TransportConditionDto,
    pub built_by_player_id: String,
    pub built_by_city_id: Option<String>,
}

/// Persisted transport segment identity.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum TransportSegmentKindDto {
    Road,
}

/// Current transport segment condition.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum TransportConditionDto {
    Operational,
    Pillaged,
}
