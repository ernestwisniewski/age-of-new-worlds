/// Exact xorshift32 combat RNG used by the engine contract.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct CombatRng {
    seed: u32,
    state: u32,
}

impl CombatRng {
    /// Constructs an RNG and replaces the absorbing zero state deterministically.
    #[must_use]
    pub const fn new(seed: u32) -> Self {
        Self {
            seed,
            state: if seed == 0 { 0x9E37_79B9 } else { seed },
        }
    }

    /// Derives the deterministic seed from turn and UTF-16 identifiers.
    #[must_use]
    pub fn from_turn(turn: u32, attacker_id: &str, defender_id: &str) -> Self {
        let hash = mix_int(0x811C_9DC5, turn);
        let hash = mix_string(hash, attacker_id);
        Self::new(mix_string(hash, defender_id))
    }

    /// Returns the initial seed exposed in replay evidence.
    #[must_use]
    pub const fn seed(self) -> u32 {
        self.seed
    }

    /// Returns a signed uniform value in `-magnitude..=magnitude`.
    #[must_use]
    pub fn signed(&mut self, magnitude: u32) -> i32 {
        if magnitude == 0 {
            return 0;
        }
        let width = magnitude.saturating_mul(2).saturating_add(1);
        i32::try_from(self.next_u32() % width).unwrap_or(i32::MAX)
            - i32::try_from(magnitude).unwrap_or(i32::MAX)
    }

    fn next_u32(&mut self) -> u32 {
        let mut value = self.state;
        value ^= value.wrapping_shl(13);
        value ^= value.wrapping_shr(17);
        value ^= value.wrapping_shl(5);
        self.state = value;
        value
    }
}

fn mix_int(mut hash: u32, value: u32) -> u32 {
    for shift in [0, 8, 16, 24] {
        hash ^= (value >> shift) & 0xff;
        hash = hash.wrapping_mul(0x0100_0193);
    }
    hash
}

fn mix_string(mut hash: u32, value: &str) -> u32 {
    for code_unit in value.encode_utf16() {
        hash ^= u32::from(code_unit & 0xff);
        hash = hash.wrapping_mul(0x0100_0193);
        hash ^= u32::from(code_unit >> 8);
        hash = hash.wrapping_mul(0x0100_0193);
    }
    hash
}

#[cfg(test)]
mod tests {
    use super::CombatRng;

    #[test]
    fn reference_seed_and_roll_are_exact() {
        let mut rng = CombatRng::from_turn(7, "attacker", "defender");
        assert_eq!(rng.seed(), 2_280_806_018);
        assert_eq!(rng.signed(2), 0);
    }

    #[test]
    fn zero_seed_uses_a_non_absorbing_state() {
        let mut rng = CombatRng::new(0);
        assert_eq!(rng.seed(), 0);
        assert_eq!(rng.signed(0), 0);
        assert!((-2..=2).contains(&rng.signed(2)));
    }
}
