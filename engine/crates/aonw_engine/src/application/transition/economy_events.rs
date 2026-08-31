use aonw_domain::{CityId, HexCoord, PlayerId};

/// Stability band selected from one player's current effective net.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum StabilityBand {
    /// Positive stability at or above the content threshold.
    Content,
    /// Non-negative stability below the content threshold.
    Stable,
    /// Negative stability above the unrest threshold.
    Strained,
    /// Stability at or below the unrest threshold.
    Unrest,
}

/// Accepted fact that growth claimed one deterministic territory hex.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CityClaimedHexEvent {
    city_id: CityId,
    coordinate: HexCoord,
}

impl CityClaimedHexEvent {
    pub(crate) const fn new(city_id: CityId, coordinate: HexCoord) -> Self {
        Self {
            city_id,
            coordinate,
        }
    }
    /// Returns the expanding city.
    #[must_use]
    pub const fn city_id(&self) -> &CityId {
        &self.city_id
    }
    /// Returns the claimed coordinate.
    #[must_use]
    pub const fn coordinate(&self) -> HexCoord {
        self.coordinate
    }
}

/// Accepted fact that recomputed stability crossed a presentation band.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct StabilityBandChangedEvent {
    player_id: PlayerId,
    previous_band: StabilityBand,
    new_band: StabilityBand,
    net: i64,
}

impl StabilityBandChangedEvent {
    pub(crate) const fn new(
        player_id: PlayerId,
        previous_band: StabilityBand,
        new_band: StabilityBand,
        net: i64,
    ) -> Self {
        Self {
            player_id,
            previous_band,
            new_band,
            net,
        }
    }
    /// Returns the affected player.
    #[must_use]
    pub const fn player_id(&self) -> &PlayerId {
        &self.player_id
    }
    /// Returns the previous band.
    #[must_use]
    pub const fn previous_band(&self) -> StabilityBand {
        self.previous_band
    }
    /// Returns the new band.
    #[must_use]
    pub const fn new_band(&self) -> StabilityBand {
        self.new_band
    }
    /// Returns the newly computed effective stability net.
    #[must_use]
    pub const fn net(&self) -> i64 {
        self.net
    }
}
