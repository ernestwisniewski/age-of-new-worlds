use aonw_contract_mapping::encode_client_stamp;
use aonw_contracts::client::ClientReplayVerificationDto;

use crate::ReplayVerification;

pub(crate) fn replay_verification(value: ReplayVerification) -> ClientReplayVerificationDto {
    ClientReplayVerificationDto {
        entry_count: u64::try_from(value.entry_count).unwrap_or(u64::MAX),
        final_event_offset: value.final_event_offset,
        final_stamp: encode_client_stamp(value.final_stamp),
    }
}
