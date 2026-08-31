mod artifact;
mod city;
mod combat;
mod diplomacy;
mod economy;
mod error;
mod infrastructure;
mod interaction;
mod match_lifecycle;
mod objective;
mod outcome;
mod research;
mod state;
mod unit;
mod value;
mod world;

pub use city::{
    decode_city_building, decode_city_project, decode_city_specialization, decode_city_wonder,
    encode_city_building, encode_city_production_queue, encode_city_project,
    encode_city_specialization, encode_city_wonder,
};
pub use economy::{decode_resource, encode_resource};
pub use error::GameStateMappingError;
pub use match_lifecycle::decode_match_identity;
pub(crate) use match_lifecycle::encode_turn_mode;
pub use outcome::encode_game_outcome;
pub use research::{decode_technology, encode_technology};
pub use state::{canonicalize_game_state, decode_game_state, encode_game_state};
pub use unit::{encode_merchant_trade_route, encode_unit_activity};
pub use value::{decode_improvement, decode_troop, encode_improvement, encode_troop};
