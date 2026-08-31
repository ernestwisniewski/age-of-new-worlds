use aonw_content::MapObjectiveType;
use aonw_domain::{HexCoord, PlayerId, RuleNumber};

/// Accepted fact that one player crossed a map objective's hold threshold.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MapObjectiveSecuredEvent {
    player_id: PlayerId,
    objective_id: String,
    objective_type: MapObjectiveType,
    coordinate: HexCoord,
    hold_turns: u32,
    required_hold_turns: u32,
    victory_points: u32,
    gold_per_turn: u32,
}

impl MapObjectiveSecuredEvent {
    #[allow(clippy::too_many_arguments)]
    pub(crate) fn new(
        player_id: PlayerId,
        objective_id: String,
        objective_type: MapObjectiveType,
        coordinate: HexCoord,
        hold_turns: u32,
        required_hold_turns: u32,
        victory_points: u32,
        gold_per_turn: u32,
    ) -> Self {
        Self {
            player_id,
            objective_id,
            objective_type,
            coordinate,
            hold_turns,
            required_hold_turns,
            victory_points,
            gold_per_turn,
        }
    }

    /// Returns the player that secured the objective.
    #[must_use]
    pub const fn player_id(&self) -> &PlayerId {
        &self.player_id
    }
    /// Returns the authored objective identity.
    #[must_use]
    pub fn objective_id(&self) -> &str {
        &self.objective_id
    }
    /// Returns the authored objective kind.
    #[must_use]
    pub const fn objective_type(&self) -> MapObjectiveType {
        self.objective_type
    }
    /// Returns the objective coordinate.
    #[must_use]
    pub const fn coordinate(&self) -> HexCoord {
        self.coordinate
    }
    /// Returns the current consecutive hold count.
    #[must_use]
    pub const fn hold_turns(&self) -> u32 {
        self.hold_turns
    }
    /// Returns the authored hold threshold.
    #[must_use]
    pub const fn required_hold_turns(&self) -> u32 {
        self.required_hold_turns
    }
    /// Returns the authored victory-point reward.
    #[must_use]
    pub const fn victory_points(&self) -> u32 {
        self.victory_points
    }
    /// Returns the authored per-turn gold reward.
    #[must_use]
    pub const fn gold_per_turn(&self) -> u32 {
        self.gold_per_turn
    }
}

/// Accepted fact that one player started a domination-threshold hold.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DominationThresholdReachedEvent {
    player_id: PlayerId,
    controlled_tile_count: u32,
    valid_tile_count: u32,
    required_control_percent: RuleNumber,
    hold_turns: u32,
    required_hold_turns: u32,
}

impl DominationThresholdReachedEvent {
    pub(crate) fn new(
        player_id: PlayerId,
        controlled_tile_count: u32,
        valid_tile_count: u32,
        required_control_percent: RuleNumber,
        hold_turns: u32,
        required_hold_turns: u32,
    ) -> Self {
        Self {
            player_id,
            controlled_tile_count,
            valid_tile_count,
            required_control_percent,
            hold_turns,
            required_hold_turns,
        }
    }

    /// Returns the player that started holding the threshold.
    #[must_use]
    pub const fn player_id(&self) -> &PlayerId {
        &self.player_id
    }
    /// Returns the exact controlled-tile numerator.
    #[must_use]
    pub const fn controlled_tile_count(&self) -> u32 {
        self.controlled_tile_count
    }
    /// Returns the exact passable-tile denominator.
    #[must_use]
    pub const fn valid_tile_count(&self) -> u32 {
        self.valid_tile_count
    }
    /// Returns the presentation percentage derived from exact integer counts.
    #[must_use]
    pub fn control_percent(&self) -> f64 {
        if self.valid_tile_count == 0 {
            0.0
        } else {
            f64::from(self.controlled_tile_count) * 100.0 / f64::from(self.valid_tile_count)
        }
    }
    /// Returns the exact configured JSON number for strict wire encoding.
    #[must_use]
    pub fn required_control_percent_text(&self) -> &str {
        self.required_control_percent.as_str()
    }
    /// Returns the current consecutive hold count.
    #[must_use]
    pub const fn hold_turns(&self) -> u32 {
        self.hold_turns
    }
    /// Returns the configured consecutive hold threshold.
    #[must_use]
    pub const fn required_hold_turns(&self) -> u32 {
        self.required_hold_turns
    }
}
