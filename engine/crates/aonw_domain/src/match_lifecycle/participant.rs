use std::collections::BTreeSet;

use crate::PlayerId;

use super::MatchRules;

/// Match participation mode.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum GameMode {
    /// Multiple players share one local client session.
    HotSeat,
    /// Players participate through independently hosted clients.
    Multiplayer,
}

/// Human or engine-controlled participant.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum PlayerKind {
    /// Human-controlled participant.
    Human,
    /// Engine-controlled participant.
    Ai,
}

/// Country selected for a participant.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum PlayerCountry {
    Poland,
    Ukraine,
    Germany,
    France,
    UnitedKingdom,
    Italy,
    Spain,
    Netherlands,
    Sweden,
    Russia,
    UnitedStates,
    Canada,
    China,
    Korea,
    Japan,
    Portugal,
    India,
    Brazil,
    Indonesia,
    Mexico,
    Turkey,
    SaudiArabia,
    Egypt,
    Greece,
}

/// AI strategy implementation identity.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum AiStrategyId {
    Random,
    Basic,
    Scripted,
    Utility,
    Mcts,
}

/// AI difficulty selection.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum AiDifficulty {
    Easy,
    Normal,
    Hard,
    VeryHard,
}

/// AI behavioral persona.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum AiPersona {
    Balanced,
    Aggressive,
    Expansive,
    Economic,
    Scientific,
}

/// Deterministic AI configuration stored with a participant.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct AiPlayer {
    strategy_id: AiStrategyId,
    difficulty: AiDifficulty,
    persona: AiPersona,
    seed: i64,
}

impl AiPlayer {
    /// Constructs deterministic AI identity.
    #[must_use]
    pub const fn new(
        strategy_id: AiStrategyId,
        difficulty: AiDifficulty,
        persona: AiPersona,
        seed: i64,
    ) -> Self {
        Self {
            strategy_id,
            difficulty,
            persona,
            seed,
        }
    }
    /// Returns strategy identity.
    #[must_use]
    pub const fn strategy_id(self) -> AiStrategyId {
        self.strategy_id
    }
    /// Returns difficulty.
    #[must_use]
    pub const fn difficulty(self) -> AiDifficulty {
        self.difficulty
    }
    /// Returns persona.
    #[must_use]
    pub const fn persona(self) -> AiPersona {
        self.persona
    }
    /// Returns deterministic seed.
    #[must_use]
    pub const fn seed(self) -> i64 {
        self.seed
    }
}

/// Ordered canonical participant including persisted display identity.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Participant {
    id: PlayerId,
    name: Box<str>,
    color_value: u32,
    country: PlayerCountry,
    kind: PlayerKind,
    ai: Option<AiPlayer>,
}

impl Participant {
    /// Constructs a participant after boundary validation.
    ///
    /// # Errors
    ///
    /// Returns an error for an empty name or AI data attached to a human.
    pub fn try_new(
        id: PlayerId,
        name: impl Into<Box<str>>,
        color_value: u32,
        country: PlayerCountry,
        kind: PlayerKind,
        ai: Option<AiPlayer>,
    ) -> Result<Self, &'static str> {
        let name = name.into();
        if name.is_empty() {
            return Err("participant name must not be empty");
        }
        if ai.is_some() && kind != PlayerKind::Ai {
            return Err("AI configuration requires an AI participant");
        }
        Ok(Self {
            id,
            name,
            color_value,
            country,
            kind,
            ai,
        })
    }

    /// Returns player identity.
    #[must_use]
    pub const fn id(&self) -> &PlayerId {
        &self.id
    }
    /// Returns the persisted participant name.
    #[must_use]
    pub const fn name(&self) -> &str {
        &self.name
    }
    /// Returns the persisted participant ARGB color.
    #[must_use]
    pub const fn color_value(&self) -> u32 {
        self.color_value
    }
    /// Returns country identity.
    #[must_use]
    pub const fn country(&self) -> PlayerCountry {
        self.country
    }
    /// Returns participant kind.
    #[must_use]
    pub const fn kind(&self) -> PlayerKind {
        self.kind
    }
    /// Returns optional deterministic AI configuration.
    #[must_use]
    pub const fn ai(&self) -> Option<AiPlayer> {
        self.ai
    }
}

/// Immutable rules and ordered participant identities for one match.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MatchIdentity {
    match_rules: MatchRules,
    participants: Box<[Participant]>,
    game_mode: GameMode,
}

impl Default for MatchIdentity {
    fn default() -> Self {
        Self {
            match_rules: MatchRules::default(),
            participants: Box::new([]),
            game_mode: GameMode::HotSeat,
        }
    }
}

impl MatchIdentity {
    /// Constructs match identity while preserving participant order.
    ///
    /// # Errors
    ///
    /// Returns the duplicated identifier when participant identities repeat.
    pub fn try_new(
        match_rules: MatchRules,
        participants: impl IntoIterator<Item = Participant>,
        game_mode: GameMode,
    ) -> Result<Self, PlayerId> {
        let participants = participants.into_iter().collect::<Vec<_>>();
        let mut ids = BTreeSet::new();
        for participant in &participants {
            if !ids.insert(participant.id().clone()) {
                return Err(participant.id().clone());
            }
        }
        Ok(Self {
            match_rules,
            participants: participants.into_boxed_slice(),
            game_mode,
        })
    }

    /// Returns immutable rules.
    #[must_use]
    pub const fn match_rules(&self) -> &MatchRules {
        &self.match_rules
    }
    /// Returns participants in canonical turn order.
    #[must_use]
    pub const fn participants(&self) -> &[Participant] {
        &self.participants
    }
    /// Returns participation mode.
    #[must_use]
    pub const fn game_mode(&self) -> GameMode {
        self.game_mode
    }
    /// Returns whether an identifier belongs to this match.
    #[must_use]
    pub fn contains(&self, player_id: &PlayerId) -> bool {
        self.participants
            .iter()
            .any(|participant| participant.id() == player_id)
    }
}
