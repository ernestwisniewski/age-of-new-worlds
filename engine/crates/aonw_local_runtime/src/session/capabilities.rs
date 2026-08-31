/// Runtime capabilities independent of session state.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct RuntimeCapabilities {
    features: u16,
}

use super::runtime::LocalRuntime;

impl LocalRuntime {
    /// Returns supported operations and versions.
    #[must_use]
    pub const fn capabilities() -> RuntimeCapabilities {
        RuntimeCapabilities::CURRENT
    }
}

impl RuntimeCapabilities {
    const ROUTE_PLAN: u16 = 1 << 0;
    const REACHABLE: u16 = 1 << 1;
    const MOVE_UNIT: u16 = 1 << 2;
    const SAVE_GAME: u16 = 1 << 3;
    const REPLAY_VERIFICATION: u16 = 1 << 4;
    const UNIT_ACTIONS: u16 = 1 << 5;
    const TURN_KERNEL: u16 = 1 << 6;
    const MOVEMENT_LOGISTICS: u16 = 1 << 7;
    const COMBAT: u16 = 1 << 8;
    const CITIES: u16 = 1 << 9;
    const WORKERS: u16 = 1 << 10;
    const PRODUCTION: u16 = 1 << 11;
    const ARTIFACTS: u16 = 1 << 12;
    const RESEARCH: u16 = 1 << 13;
    const DIPLOMACY: u16 = 1 << 14;

    pub(super) const CURRENT: Self = Self {
        features: Self::ROUTE_PLAN
            | Self::REACHABLE
            | Self::MOVE_UNIT
            | Self::SAVE_GAME
            | Self::REPLAY_VERIFICATION
            | Self::UNIT_ACTIONS
            | Self::TURN_KERNEL
            | Self::MOVEMENT_LOGISTICS
            | Self::COMBAT
            | Self::CITIES
            | Self::WORKERS
            | Self::PRODUCTION
            | Self::ARTIFACTS
            | Self::RESEARCH
            | Self::DIPLOMACY,
    };

    /// Returns whether route planning is available.
    #[must_use]
    pub const fn route_plan(self) -> bool {
        self.features & Self::ROUTE_PLAN != 0
    }

    /// Returns whether reachable overlays are available.
    #[must_use]
    pub const fn reachable(self) -> bool {
        self.features & Self::REACHABLE != 0
    }

    /// Returns whether manual movement dispatch is available.
    #[must_use]
    pub const fn move_unit(self) -> bool {
        self.features & Self::MOVE_UNIT != 0
    }

    /// Returns whether canonical save export and restore are available.
    #[must_use]
    pub const fn save_game(self) -> bool {
        self.features & Self::SAVE_GAME != 0
    }

    /// Returns whether deterministic replay export and verification are available.
    #[must_use]
    pub const fn replay_verification(self) -> bool {
        self.features & Self::REPLAY_VERIFICATION != 0
    }

    /// Returns whether cancel, skip, and fortify commands are available.
    #[must_use]
    pub const fn unit_actions(self) -> bool {
        self.features & Self::UNIT_ACTIONS != 0
    }

    /// Returns whether capability-gated `EndTurn` and `SubmitTurn` are available.
    #[must_use]
    pub const fn turn_kernel(self) -> bool {
        self.features & Self::TURN_KERNEL != 0
    }

    /// Returns whether auto-exploration, merchant routing, and detachment are available.
    #[must_use]
    pub const fn movement_logistics(self) -> bool {
        self.features & Self::MOVEMENT_LOGISTICS != 0
    }

    /// Returns whether combat preview and visible attacks are available.
    #[must_use]
    pub const fn combat(self) -> bool {
        self.features & Self::COMBAT != 0
    }

    /// Returns whether city commands, queries, and projections are available.
    #[must_use]
    pub const fn cities(self) -> bool {
        self.features & Self::CITIES != 0
    }
    /// Returns whether worker and infrastructure operations are available.
    #[must_use]
    pub const fn workers(self) -> bool {
        self.features & Self::WORKERS != 0
    }
    /// Returns whether city production queries and queue commands are available.
    #[must_use]
    pub const fn production(self) -> bool {
        self.features & Self::PRODUCTION != 0
    }

    /// Returns whether artifact operations are available.
    #[must_use]
    pub const fn artifacts(self) -> bool {
        self.features & Self::ARTIFACTS != 0
    }

    /// Returns whether research options and selection are available.
    #[must_use]
    pub const fn research(self) -> bool {
        self.features & Self::RESEARCH != 0
    }

    /// Returns whether bilateral proposal commands are available.
    #[must_use]
    pub const fn diplomacy(self) -> bool {
        self.features & Self::DIPLOMACY != 0
    }
}
