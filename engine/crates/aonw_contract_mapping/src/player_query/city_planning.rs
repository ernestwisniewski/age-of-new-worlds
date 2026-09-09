use aonw_contracts::{CoordinateDto, client::ClientQueryResultDto};
use aonw_domain::HexCoord;
use aonw_engine::CityPlanning;
use aonw_projection::SessionStamp;

/// Encodes the same disclosed markings for local and remote clients.
#[must_use]
pub fn encode_city_planning(stamp: SessionStamp, value: &CityPlanning) -> ClientQueryResultDto {
    let coordinate = |hex: &HexCoord| CoordinateDto {
        col: hex.col(),
        row: hex.row(),
    };
    ClientQueryResultDto::CityPlanning {
        stamp: crate::encode_client_stamp(stamp),
        city_sites: value.city_sites.iter().map(coordinate).collect(),
        growth_tiles: value.growth_tiles.iter().map(coordinate).collect(),
    }
}
