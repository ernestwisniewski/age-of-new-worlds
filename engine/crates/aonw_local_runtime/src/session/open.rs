use aonw_content::{MapDefinition, RulesetDefinition, ScenarioBootstrapError, ScenarioDefinition};
use aonw_domain::{
    GameMode, GameState, MatchIdentity, MatchRules, Participant, PlayerCountry, PlayerId,
    PlayerKind,
};
use aonw_engine::{MatchStartError, start_match};

/// Fully validated input used to open one local session.
#[derive(Clone, Debug)]
pub struct OpenSession {
    pub(super) map: MapDefinition,
    pub(super) ruleset: RulesetDefinition,
    pub(super) state: GameState,
    pub(super) actor: PlayerId,
    pub(super) event_offset: u64,
}

impl OpenSession {
    /// Builds an open request from immutable scenario content.
    ///
    /// # Errors
    ///
    /// Returns an error when scenario content cannot bootstrap canonical state.
    pub fn from_scenario(
        map: MapDefinition,
        ruleset: RulesetDefinition,
        scenario: &ScenarioDefinition,
        actor: PlayerId,
    ) -> Result<Self, OpenSessionError> {
        let seed = scenario
            .bootstrap(&map, &ruleset)
            .map_err(OpenSessionError::Scenario)?;
        let identity = inferred_hot_seat_identity(&seed, &actor)?;
        let state =
            start_match(seed, &map, identity, false).map_err(OpenSessionError::MatchStart)?;
        Ok(Self {
            map,
            ruleset,
            state,
            actor,
            event_offset: 0,
        })
    }

    /// Builds a playable session from authored content and explicit immutable
    /// match identity.
    ///
    /// # Errors
    ///
    /// Returns an error when scenario bootstrap or atomic match start fails.
    pub fn from_scenario_with_match(
        map: MapDefinition,
        ruleset: RulesetDefinition,
        scenario: &ScenarioDefinition,
        actor: PlayerId,
        identity: MatchIdentity,
        fog_enabled: bool,
    ) -> Result<Self, OpenSessionError> {
        let seed = scenario
            .bootstrap(&map, &ruleset)
            .map_err(OpenSessionError::Scenario)?;
        let state =
            start_match(seed, &map, identity, fog_enabled).map_err(OpenSessionError::MatchStart)?;
        Ok(Self {
            map,
            ruleset,
            state,
            actor,
            event_offset: 0,
        })
    }

    /// Builds an open request from a previously decoded canonical snapshot.
    #[must_use]
    pub const fn from_state(
        map: MapDefinition,
        ruleset: RulesetDefinition,
        state: GameState,
        actor: PlayerId,
    ) -> Self {
        Self {
            map,
            ruleset,
            state,
            actor,
            event_offset: 0,
        }
    }

    /// Restores the authoritative event-log position owned by the runtime.
    #[must_use]
    pub const fn with_event_offset(mut self, event_offset: u64) -> Self {
        self.event_offset = event_offset;
        self
    }
}

/// Failure while preparing a new session.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum OpenSessionError {
    /// Scenario bootstrap failed.
    Scenario(ScenarioBootstrapError),
    /// Explicit match identity, lifecycle, or visibility could not be bound.
    MatchStart(MatchStartError),
    /// An inferred participant could not be constructed.
    InvalidParticipant(Box<str>),
    /// Inferred identity unexpectedly repeated a participant.
    DuplicateParticipant(PlayerId),
    /// A canonical state has no participant identity.
    EmptyParticipants,
    /// The requested actor is not a match participant.
    UnknownActor(PlayerId),
    /// State and map bounds differ.
    MapBoundsMismatch,
    /// State and ruleset occupancy policies differ.
    OccupancyPolicyMismatch,
    /// Immutable content identity could not be computed.
    ContentHash(Box<str>),
}

impl core::fmt::Display for OpenSessionError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::Scenario(source) => source.fmt(formatter),
            Self::MatchStart(source) => source.fmt(formatter),
            Self::InvalidParticipant(source) => {
                write!(formatter, "invalid inferred participant: {source}")
            }
            Self::DuplicateParticipant(player) => {
                write!(formatter, "duplicate inferred participant: {player}")
            }
            Self::EmptyParticipants => formatter.write_str("match has no participants"),
            Self::UnknownActor(player) => {
                write!(formatter, "session actor is not a participant: {player}")
            }
            Self::MapBoundsMismatch => formatter.write_str("state bounds do not match the map"),
            Self::OccupancyPolicyMismatch => {
                formatter.write_str("state occupancy policy does not match the ruleset")
            }
            Self::ContentHash(source) => write!(formatter, "content hash failed: {source}"),
        }
    }
}

impl std::error::Error for OpenSessionError {}

fn inferred_hot_seat_identity(
    seed: &GameState,
    actor: &PlayerId,
) -> Result<MatchIdentity, OpenSessionError> {
    let mut player_ids = seed
        .units()
        .iter()
        .map(|unit| unit.owner_player_id().clone())
        .collect::<Vec<_>>();
    if !player_ids.contains(actor) {
        player_ids.push(actor.clone());
    }
    player_ids.sort_unstable();
    player_ids.dedup();
    let participants = player_ids
        .into_iter()
        .enumerate()
        .map(|(index, player_id)| {
            let name = player_id.as_str().to_owned();
            Participant::try_new(
                player_id,
                name,
                default_participant_color(index),
                default_participant_country(index),
                PlayerKind::Human,
                None,
            )
            .map_err(|error| OpenSessionError::InvalidParticipant(error.into()))
        })
        .collect::<Result<Vec<_>, _>>()?;
    MatchIdentity::try_new(MatchRules::default(), participants, GameMode::HotSeat)
        .map_err(OpenSessionError::DuplicateParticipant)
}

const fn default_participant_color(index: usize) -> u32 {
    const COLORS: [u32; 8] = [
        0xff_42_85_f4,
        0xff_ea_43_35,
        0xff_34_a8_53,
        0xff_fb_bc_05,
        0xff_a1_42_f4,
        0xff_00_ac_c1,
        0xff_ff_70_43,
        0xff_7c_8b_a1,
    ];
    COLORS[index % COLORS.len()]
}

const fn default_participant_country(index: usize) -> PlayerCountry {
    const COUNTRIES: [PlayerCountry; 8] = [
        PlayerCountry::Poland,
        PlayerCountry::Ukraine,
        PlayerCountry::Germany,
        PlayerCountry::France,
        PlayerCountry::UnitedKingdom,
        PlayerCountry::Italy,
        PlayerCountry::Spain,
        PlayerCountry::Netherlands,
    ];
    COUNTRIES[index % COUNTRIES.len()]
}
