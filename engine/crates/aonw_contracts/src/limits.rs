/// Maximum units accepted in one canonical game-state document.
pub const MAX_GAME_STATE_UNIT_COUNT: usize = 4_096;

/// Maximum route length including its origin.
pub const MAX_QUEUED_PATH_STEP_COUNT: usize = 1_200;

/// Highest fixed-point balance accepted before ruleset validation.
pub const MAX_MOVEMENT_BALANCE_UNITS: u32 = 14;
