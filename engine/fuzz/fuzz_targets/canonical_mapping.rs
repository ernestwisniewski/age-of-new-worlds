#![no_main]

use aonw_contract_mapping::{decode_game_state, encode_game_state};
use aonw_contracts::GameStateDto;
use libfuzzer_sys::fuzz_target;

const MAX_FUZZ_STATE_BYTES: usize = 65_536;
const BASELINE: &str = include_str!("../../fixtures/canonical_commands/fortify-unit-accepted.json");

fuzz_target!(|data: &[u8]| {
    exercise(BASELINE);
    if let Ok(input) = core::str::from_utf8(data) {
        exercise(input);
    }
});

fn exercise(input: &str) {
    let Ok(value) = serde_json::from_str::<serde_json::Value>(input) else {
        return;
    };
    let candidate = value.pointer("/input/state").unwrap_or(&value);
    let Ok(document) = serde_json::to_string(candidate) else {
        return;
    };
    let Ok(dto) = GameStateDto::from_json(&document, MAX_FUZZ_STATE_BYTES) else {
        return;
    };
    let Ok(state) = decode_game_state(dto) else {
        return;
    };
    let canonical = encode_game_state(&state);
    let decoded = decode_game_state(canonical.clone()).expect("encoded domain state must decode");
    assert_eq!(encode_game_state(&decoded), canonical);
}
