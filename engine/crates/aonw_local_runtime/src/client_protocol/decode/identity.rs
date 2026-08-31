use aonw_domain::{CityId, UnitId};

use super::ClientDecodeError;

pub(super) fn decode_unit_id(value: String) -> Result<UnitId, ClientDecodeError> {
    UnitId::new(value).map_err(|error| ClientDecodeError::new("invalid_unit_id", error))
}

pub(super) fn decode_city_id(value: String) -> Result<CityId, ClientDecodeError> {
    CityId::new(value).map_err(|error| ClientDecodeError::new("invalid_city_id", error))
}
