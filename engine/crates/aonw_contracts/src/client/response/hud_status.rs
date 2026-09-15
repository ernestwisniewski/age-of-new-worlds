use serde::{Deserialize, Serialize};

/// Authoritative forecast warning for the treasury.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum TreasuryWarningDto {
    None,
    NegativeBalance,
    DeficitWithinThreeTurns,
}

/// Victory condition selected by the recipient-safe HUD policy.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum VictoryStatusKindDto {
    None,
    Conquest,
    Domination,
    Culture,
    Score,
}

/// Priority, severity and disclosed leader of the compact victory summary.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct VictoryStatusDto {
    pub kind: VictoryStatusKindDto,
    pub critical: bool,
    #[serde(deserialize_with = "Option::deserialize")]
    pub leader_player_id: Option<String>,
}
