use aonw_contracts::{ReplayEventDto, StabilityBandDto};
use aonw_engine::{CityClaimedHexEvent, StabilityBand, StabilityBandChangedEvent};

pub(super) fn city_claimed(value: &CityClaimedHexEvent) -> ReplayEventDto {
    ReplayEventDto::CityClaimedHex {
        city_id: value.city_id().as_str().to_owned(),
        col: value.coordinate().col(),
        row: value.coordinate().row(),
    }
}

pub(super) fn stability_changed(value: &StabilityBandChangedEvent) -> ReplayEventDto {
    ReplayEventDto::StabilityBandChanged {
        player_id: value.player_id().as_str().to_owned(),
        previous_band: stability_band(value.previous_band()),
        new_band: stability_band(value.new_band()),
        net: value.net(),
    }
}

const fn stability_band(value: StabilityBand) -> StabilityBandDto {
    match value {
        StabilityBand::Content => StabilityBandDto::Content,
        StabilityBand::Stable => StabilityBandDto::Stable,
        StabilityBand::Strained => StabilityBandDto::Strained,
        StabilityBand::Unrest => StabilityBandDto::Unrest,
    }
}
