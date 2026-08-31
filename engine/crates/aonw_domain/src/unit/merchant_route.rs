use crate::{CityId, MovementStep};

/// Persisted route assigned to a merchant.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MerchantTradeRoute {
    origin_city_id: CityId,
    destination_city_id: CityId,
    steps: Box<[MovementStep]>,
    transport_network_fingerprint: Box<str>,
}

impl MerchantTradeRoute {
    /// Constructs an immutable merchant route.
    #[must_use]
    pub fn new(
        origin_city_id: CityId,
        destination_city_id: CityId,
        steps: impl IntoIterator<Item = MovementStep>,
        transport_network_fingerprint: impl Into<Box<str>>,
    ) -> Self {
        Self {
            origin_city_id,
            destination_city_id,
            steps: steps.into_iter().collect(),
            transport_network_fingerprint: transport_network_fingerprint.into(),
        }
    }

    /// Returns the origin city.
    #[must_use]
    pub const fn origin_city_id(&self) -> &CityId {
        &self.origin_city_id
    }

    /// Returns the destination city.
    #[must_use]
    pub const fn destination_city_id(&self) -> &CityId {
        &self.destination_city_id
    }

    /// Returns route steps in execution order.
    #[must_use]
    pub const fn steps(&self) -> &[MovementStep] {
        &self.steps
    }

    /// Returns the transport network identity used for planning.
    #[must_use]
    pub fn transport_network_fingerprint(&self) -> &str {
        &self.transport_network_fingerprint
    }
}
