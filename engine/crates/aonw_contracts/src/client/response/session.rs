use serde::{Deserialize, Serialize};

use super::ClientSessionStampDto;

/// Replay verification summary returned to a client.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ClientReplayVerificationDto {
    /// Number of verified commands.
    pub entry_count: u64,
    /// Final event offset.
    pub final_event_offset: u64,
    /// Final authoritative identity.
    pub final_stamp: ClientSessionStampDto,
}

/// Stable client failure independent of transport details.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ClientErrorDto {
    /// Stable machine-readable code.
    pub code: String,
    /// Human-readable diagnostic message.
    pub message: String,
}
