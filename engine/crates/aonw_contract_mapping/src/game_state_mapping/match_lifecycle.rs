use std::collections::BTreeMap;

use aonw_contracts::{
    AiDifficultyDto, AiPersonaDto, AiPlayerDto, AiStrategyIdDto, GameLengthConfigDto,
    GameLengthKindDto, GameModeDto, MatchIdentityDto, MatchRulesDto, PaceProfileDto,
    ParticipantDto, PlayerCountryDto, PlayerKindDto, PlayerTurnStateDto, RuleValueDto,
    TurnLifecycleDto, TurnModeDto, VictoryRulesDto,
};
use aonw_domain::{
    AiDifficulty, AiPersona, AiPlayer, AiStrategyId, GameLengthConfig, GameLengthKind, GameMode,
    MatchIdentity, MatchLifecycle, MatchRules, PaceProfile, Participant, PlayerCountry, PlayerId,
    PlayerKind, PlayerTurnState, RuleNumber, RuleValue, TurnLifecycle, TurnMode, UtcTimestamp,
    VictoryRules,
};

use super::error::GameStateMappingError;

pub(super) fn decode_match_lifecycle(
    identity: MatchIdentityDto,
    turn: TurnLifecycleDto,
) -> Result<MatchLifecycle, GameStateMappingError> {
    let identity = decode_match_identity(identity)?;
    let turn = decode_turn(&identity, turn)?;
    Ok(MatchLifecycle::new(identity, turn))
}

pub(super) fn encode_match_lifecycle(
    value: &MatchLifecycle,
) -> (MatchIdentityDto, TurnLifecycleDto) {
    (encode_identity(value.identity()), encode_turn(value.turn()))
}

/// Validates and maps immutable match identity supplied at a client boundary.
///
/// # Errors
///
/// Returns a path-aware error for invalid participant identities or rules.
pub fn decode_match_identity(
    dto: MatchIdentityDto,
) -> Result<MatchIdentity, GameStateMappingError> {
    let game_mode = decode_game_mode(dto.game_mode);
    let turn_mode = dto
        .turn_mode
        .map_or_else(|| game_mode.default_turn_mode(), decode_turn_mode);
    let participants = dto
        .participants
        .into_iter()
        .enumerate()
        .map(|(index, participant)| decode_participant(index, participant))
        .collect::<Result<Vec<_>, _>>()?;
    MatchIdentity::try_new_with_turn_mode(
        decode_rules(dto.match_rules)?,
        participants,
        game_mode,
        turn_mode,
    )
    .map_err(|player| {
        GameStateMappingError::new(
            "$.matchIdentity.participants",
            format!("duplicate participant id: {player}"),
        )
    })
}

fn encode_identity(value: &MatchIdentity) -> MatchIdentityDto {
    MatchIdentityDto {
        match_rules: encode_rules(value.match_rules()),
        participants: value
            .participants()
            .iter()
            .map(encode_participant)
            .collect(),
        game_mode: encode_game_mode(value.game_mode()),
        turn_mode: Some(encode_turn_mode(value.turn_mode())),
    }
}

fn decode_rules(dto: MatchRulesDto) -> Result<MatchRules, GameStateMappingError> {
    let game_length = decode_game_length(&dto.game_length).map_err(|error| {
        GameStateMappingError::new("$.matchIdentity.matchRules.gameLength", error.to_string())
    })?;
    let victory = decode_victory(&dto.victory)?;
    Ok(MatchRules::new(
        game_length,
        victory,
        dto.balance
            .into_iter()
            .map(|(key, value)| (key.into_boxed_str(), decode_rule_value(value)))
            .collect(),
    ))
}

fn encode_rules(value: &MatchRules) -> MatchRulesDto {
    MatchRulesDto {
        game_length: encode_game_length(value.game_length()),
        victory: encode_victory(value.victory()),
        balance: value
            .balance()
            .iter()
            .map(|(key, value)| (key.to_string(), encode_rule_value(value)))
            .collect(),
    }
}

fn decode_game_length(
    dto: &GameLengthConfigDto,
) -> Result<GameLengthConfig, aonw_domain::MatchRulesBuildError> {
    GameLengthConfig::try_new(
        match dto.kind {
            GameLengthKindDto::Unlimited => GameLengthKind::Unlimited,
            GameLengthKindDto::TargetMinutes => GameLengthKind::TargetMinutes,
        },
        dto.target_minutes,
        dto.turn_limit,
        match dto.pace_profile {
            PaceProfileDto::Unlimited => PaceProfile::Unlimited,
            PaceProfileDto::Standard60 => PaceProfile::Standard60,
            PaceProfileDto::Normal90 => PaceProfile::Normal90,
            PaceProfileDto::Long120 => PaceProfile::Long120,
        },
        dto.score_fallback_enabled,
    )
}

fn encode_game_length(value: &GameLengthConfig) -> GameLengthConfigDto {
    GameLengthConfigDto {
        kind: match value.kind() {
            GameLengthKind::Unlimited => GameLengthKindDto::Unlimited,
            GameLengthKind::TargetMinutes => GameLengthKindDto::TargetMinutes,
        },
        target_minutes: value.target_minutes(),
        turn_limit: value.turn_limit(),
        pace_profile: match value.pace_profile() {
            PaceProfile::Unlimited => PaceProfileDto::Unlimited,
            PaceProfile::Standard60 => PaceProfileDto::Standard60,
            PaceProfile::Normal90 => PaceProfileDto::Normal90,
            PaceProfile::Long120 => PaceProfileDto::Long120,
        },
        score_fallback_enabled: value.score_fallback_enabled(),
    }
}

fn decode_victory(dto: &VictoryRulesDto) -> Result<VictoryRules, GameStateMappingError> {
    let percent = RuleNumber::new(dto.domination_control_percent.to_string()).map_err(|error| {
        GameStateMappingError::new(
            "$.matchIdentity.matchRules.victory.dominationControlPercent",
            error.to_string(),
        )
    })?;
    VictoryRules::try_new(
        dto.conquest_enabled,
        dto.domination_enabled,
        percent,
        dto.domination_hold_turns,
        dto.score_fallback_enabled,
        dto.turn_limit,
        dto.hard_time_limit_minutes,
        dto.cultural_enabled,
        dto.cultural_required_artifacts,
        dto.cultural_hold_turns,
    )
    .map_err(|error| {
        GameStateMappingError::new("$.matchIdentity.matchRules.victory", error.to_string())
    })
}

fn encode_victory(value: &VictoryRules) -> VictoryRulesDto {
    VictoryRulesDto {
        conquest_enabled: value.conquest_enabled(),
        domination_enabled: value.domination_enabled(),
        domination_control_percent: value
            .domination_control_percent()
            .as_str()
            .parse()
            .expect("validated JSON number"),
        domination_hold_turns: value.domination_hold_turns(),
        score_fallback_enabled: value.score_fallback_enabled(),
        turn_limit: value.turn_limit(),
        hard_time_limit_minutes: value.hard_time_limit_minutes(),
        cultural_enabled: value.cultural_enabled(),
        cultural_required_artifacts: value.cultural_required_artifacts(),
        cultural_hold_turns: value.cultural_hold_turns(),
    }
}

fn decode_rule_value(value: RuleValueDto) -> RuleValue {
    match value {
        RuleValueDto::Null => RuleValue::Null,
        RuleValueDto::Bool(value) => RuleValue::Bool(value),
        RuleValueDto::Number(value) => RuleValue::Number(
            RuleNumber::new(value.to_string()).expect("serde JSON number is valid"),
        ),
        RuleValueDto::String(value) => RuleValue::String(value.into_boxed_str()),
        RuleValueDto::Array(values) => RuleValue::Array(
            values
                .into_iter()
                .map(decode_rule_value)
                .collect::<Vec<_>>()
                .into_boxed_slice(),
        ),
        RuleValueDto::Object(values) => RuleValue::Object(
            values
                .into_iter()
                .map(|(key, value)| (key.into_boxed_str(), decode_rule_value(value)))
                .collect(),
        ),
    }
}

fn encode_rule_value(value: &RuleValue) -> RuleValueDto {
    match value {
        RuleValue::Null => RuleValueDto::Null,
        RuleValue::Bool(value) => RuleValueDto::Bool(*value),
        RuleValue::Number(value) => {
            RuleValueDto::Number(value.as_str().parse().expect("validated JSON number"))
        }
        RuleValue::String(value) => RuleValueDto::String(value.to_string()),
        RuleValue::Array(values) => {
            RuleValueDto::Array(values.iter().map(encode_rule_value).collect())
        }
        RuleValue::Object(values) => RuleValueDto::Object(
            values
                .iter()
                .map(|(key, value)| (key.to_string(), encode_rule_value(value)))
                .collect(),
        ),
    }
}

fn decode_participant(
    index: usize,
    dto: ParticipantDto,
) -> Result<Participant, GameStateMappingError> {
    let path = format!("$.matchIdentity.participants[{index}]");
    let id = PlayerId::new(dto.id)
        .map_err(|error| GameStateMappingError::new(format!("{path}.id"), error.to_string()))?;
    Participant::try_new(
        id,
        dto.name,
        dto.color_value,
        decode_country(dto.country),
        decode_player_kind(dto.kind),
        dto.ai.map(decode_ai),
    )
    .map_err(|error| GameStateMappingError::new(path, error))
}

fn encode_participant(value: &Participant) -> ParticipantDto {
    ParticipantDto {
        id: value.id().as_str().to_owned(),
        name: value.name().to_owned(),
        color_value: value.color_value(),
        country: encode_country(value.country()),
        kind: encode_player_kind(value.kind()),
        ai: value.ai().map(encode_ai),
    }
}

fn decode_turn(
    identity: &MatchIdentity,
    dto: TurnLifecycleDto,
) -> Result<TurnLifecycle, GameStateMappingError> {
    let turn_states = dto
        .turn_states_by_player_id
        .into_iter()
        .map(|(player, state)| {
            Ok((
                player_id(player, "$.turnLifecycle.turnStatesByPlayerId")?,
                decode_turn_state(state),
            ))
        })
        .collect::<Result<BTreeMap<_, _>, GameStateMappingError>>()?;
    let submitted = decode_player_list(
        dto.submitted_player_ids,
        "$.turnLifecycle.submittedPlayerIds",
    )?;
    let required = decode_player_list(
        dto.required_submission_player_ids,
        "$.turnLifecycle.requiredSubmissionPlayerIds",
    )?;
    let timeout_streaks = dto
        .timeout_streaks_by_player_id
        .into_iter()
        .map(|(player, streak)| {
            Ok((
                player_id(player, "$.turnLifecycle.timeoutStreaksByPlayerId")?,
                streak,
            ))
        })
        .collect::<Result<BTreeMap<_, _>, GameStateMappingError>>()?;
    let afk = decode_player_list(dto.afk_player_ids, "$.turnLifecycle.afkPlayerIds")?;
    let kicked = decode_player_list(dto.kicked_player_ids, "$.turnLifecycle.kickedPlayerIds")?;
    let started = dto
        .turn_started_at
        .map(UtcTimestamp::new)
        .transpose()
        .map_err(|error| GameStateMappingError::new("$.turnLifecycle.turnStartedAt", error))?;
    TurnLifecycle::try_new(
        identity,
        turn_states,
        required,
        submitted,
        timeout_streaks,
        afk,
        kicked,
        started,
    )
    .map_err(|error| GameStateMappingError::new("$.turnLifecycle", error.to_string()))
}

fn encode_turn(value: &TurnLifecycle) -> TurnLifecycleDto {
    TurnLifecycleDto {
        turn_states_by_player_id: value
            .turn_states_by_player_id()
            .iter()
            .map(|(player, state)| (player.as_str().to_owned(), encode_turn_state(*state)))
            .collect(),
        required_submission_player_ids: value
            .required_submission_player_ids()
            .iter()
            .map(|player| player.as_str().to_owned())
            .collect(),
        submitted_player_ids: value
            .submitted_player_ids()
            .iter()
            .map(|player| player.as_str().to_owned())
            .collect(),
        timeout_streaks_by_player_id: value
            .timeout_streaks_by_player_id()
            .iter()
            .map(|(player, streak)| (player.as_str().to_owned(), *streak))
            .collect(),
        afk_player_ids: value
            .afk_player_ids()
            .iter()
            .map(|player| player.as_str().to_owned())
            .collect(),
        kicked_player_ids: value
            .kicked_player_ids()
            .iter()
            .map(|player| player.as_str().to_owned())
            .collect(),
        turn_started_at: value.turn_started_at().map(|time| time.as_str().to_owned()),
    }
}

fn decode_player_list(
    values: Vec<String>,
    path: &'static str,
) -> Result<Vec<PlayerId>, GameStateMappingError> {
    values
        .into_iter()
        .enumerate()
        .map(|(index, value)| player_id(value, &format!("{path}[{index}]")))
        .collect()
}

fn player_id(value: String, path: &str) -> Result<PlayerId, GameStateMappingError> {
    PlayerId::new(value)
        .map_err(|error| GameStateMappingError::new(path.to_owned(), error.to_string()))
}

macro_rules! map_enum {
    ($value:expr, $($source:path => $target:path),+ $(,)?) => {
        match $value { $($source => $target),+ }
    };
}

fn decode_game_mode(value: GameModeDto) -> GameMode {
    map_enum!(value, GameModeDto::HotSeat => GameMode::HotSeat, GameModeDto::Multiplayer => GameMode::Multiplayer)
}
fn encode_game_mode(value: GameMode) -> GameModeDto {
    map_enum!(value, GameMode::HotSeat => GameModeDto::HotSeat, GameMode::Multiplayer => GameModeDto::Multiplayer)
}
fn decode_turn_mode(value: TurnModeDto) -> TurnMode {
    map_enum!(value, TurnModeDto::Sequential => TurnMode::Sequential, TurnModeDto::Simultaneous => TurnMode::Simultaneous)
}
pub(crate) fn encode_turn_mode(value: TurnMode) -> TurnModeDto {
    map_enum!(value, TurnMode::Sequential => TurnModeDto::Sequential, TurnMode::Simultaneous => TurnModeDto::Simultaneous)
}
fn decode_player_kind(value: PlayerKindDto) -> PlayerKind {
    map_enum!(value, PlayerKindDto::Human => PlayerKind::Human, PlayerKindDto::Ai => PlayerKind::Ai)
}
pub(crate) fn encode_player_kind(value: PlayerKind) -> PlayerKindDto {
    map_enum!(value, PlayerKind::Human => PlayerKindDto::Human, PlayerKind::Ai => PlayerKindDto::Ai)
}
fn decode_turn_state(value: PlayerTurnStateDto) -> PlayerTurnState {
    map_enum!(value, PlayerTurnStateDto::Active => PlayerTurnState::Active, PlayerTurnStateDto::Finished => PlayerTurnState::Finished)
}
fn encode_turn_state(value: PlayerTurnState) -> PlayerTurnStateDto {
    map_enum!(value, PlayerTurnState::Active => PlayerTurnStateDto::Active, PlayerTurnState::Finished => PlayerTurnStateDto::Finished)
}

fn decode_ai(value: AiPlayerDto) -> AiPlayer {
    AiPlayer::new(
        map_enum!(value.strategy_id,
            AiStrategyIdDto::Random => AiStrategyId::Random,
            AiStrategyIdDto::Basic => AiStrategyId::Basic,
            AiStrategyIdDto::Scripted => AiStrategyId::Scripted,
            AiStrategyIdDto::Utility => AiStrategyId::Utility,
            AiStrategyIdDto::Mcts => AiStrategyId::Mcts),
        map_enum!(value.difficulty,
            AiDifficultyDto::Easy => AiDifficulty::Easy,
            AiDifficultyDto::Normal => AiDifficulty::Normal,
            AiDifficultyDto::Hard => AiDifficulty::Hard,
            AiDifficultyDto::VeryHard => AiDifficulty::VeryHard),
        map_enum!(value.persona,
            AiPersonaDto::Balanced => AiPersona::Balanced,
            AiPersonaDto::Aggressive => AiPersona::Aggressive,
            AiPersonaDto::Expansive => AiPersona::Expansive,
            AiPersonaDto::Economic => AiPersona::Economic,
            AiPersonaDto::Scientific => AiPersona::Scientific),
        value.seed,
    )
}

fn encode_ai(value: AiPlayer) -> AiPlayerDto {
    AiPlayerDto {
        strategy_id: map_enum!(value.strategy_id(),
            AiStrategyId::Random => AiStrategyIdDto::Random,
            AiStrategyId::Basic => AiStrategyIdDto::Basic,
            AiStrategyId::Scripted => AiStrategyIdDto::Scripted,
            AiStrategyId::Utility => AiStrategyIdDto::Utility,
            AiStrategyId::Mcts => AiStrategyIdDto::Mcts),
        difficulty: map_enum!(value.difficulty(),
            AiDifficulty::Easy => AiDifficultyDto::Easy,
            AiDifficulty::Normal => AiDifficultyDto::Normal,
            AiDifficulty::Hard => AiDifficultyDto::Hard,
            AiDifficulty::VeryHard => AiDifficultyDto::VeryHard),
        persona: map_enum!(value.persona(),
            AiPersona::Balanced => AiPersonaDto::Balanced,
            AiPersona::Aggressive => AiPersonaDto::Aggressive,
            AiPersona::Expansive => AiPersonaDto::Expansive,
            AiPersona::Economic => AiPersonaDto::Economic,
            AiPersona::Scientific => AiPersonaDto::Scientific),
        seed: value.seed(),
    }
}

fn decode_country(value: PlayerCountryDto) -> PlayerCountry {
    map_enum!(value,
        PlayerCountryDto::Poland => PlayerCountry::Poland,
        PlayerCountryDto::Ukraine => PlayerCountry::Ukraine,
        PlayerCountryDto::Germany => PlayerCountry::Germany,
        PlayerCountryDto::France => PlayerCountry::France,
        PlayerCountryDto::UnitedKingdom => PlayerCountry::UnitedKingdom,
        PlayerCountryDto::Italy => PlayerCountry::Italy,
        PlayerCountryDto::Spain => PlayerCountry::Spain,
        PlayerCountryDto::Netherlands => PlayerCountry::Netherlands,
        PlayerCountryDto::Sweden => PlayerCountry::Sweden,
        PlayerCountryDto::Russia => PlayerCountry::Russia,
        PlayerCountryDto::UnitedStates => PlayerCountry::UnitedStates,
        PlayerCountryDto::Canada => PlayerCountry::Canada,
        PlayerCountryDto::China => PlayerCountry::China,
        PlayerCountryDto::Korea => PlayerCountry::Korea,
        PlayerCountryDto::Japan => PlayerCountry::Japan,
        PlayerCountryDto::Portugal => PlayerCountry::Portugal,
        PlayerCountryDto::India => PlayerCountry::India,
        PlayerCountryDto::Brazil => PlayerCountry::Brazil,
        PlayerCountryDto::Indonesia => PlayerCountry::Indonesia,
        PlayerCountryDto::Mexico => PlayerCountry::Mexico,
        PlayerCountryDto::Turkey => PlayerCountry::Turkey,
        PlayerCountryDto::SaudiArabia => PlayerCountry::SaudiArabia,
        PlayerCountryDto::Egypt => PlayerCountry::Egypt,
        PlayerCountryDto::Greece => PlayerCountry::Greece)
}

pub(crate) fn encode_country(value: PlayerCountry) -> PlayerCountryDto {
    map_enum!(value,
        PlayerCountry::Poland => PlayerCountryDto::Poland,
        PlayerCountry::Ukraine => PlayerCountryDto::Ukraine,
        PlayerCountry::Germany => PlayerCountryDto::Germany,
        PlayerCountry::France => PlayerCountryDto::France,
        PlayerCountry::UnitedKingdom => PlayerCountryDto::UnitedKingdom,
        PlayerCountry::Italy => PlayerCountryDto::Italy,
        PlayerCountry::Spain => PlayerCountryDto::Spain,
        PlayerCountry::Netherlands => PlayerCountryDto::Netherlands,
        PlayerCountry::Sweden => PlayerCountryDto::Sweden,
        PlayerCountry::Russia => PlayerCountryDto::Russia,
        PlayerCountry::UnitedStates => PlayerCountryDto::UnitedStates,
        PlayerCountry::Canada => PlayerCountryDto::Canada,
        PlayerCountry::China => PlayerCountryDto::China,
        PlayerCountry::Korea => PlayerCountryDto::Korea,
        PlayerCountry::Japan => PlayerCountryDto::Japan,
        PlayerCountry::Portugal => PlayerCountryDto::Portugal,
        PlayerCountry::India => PlayerCountryDto::India,
        PlayerCountry::Brazil => PlayerCountryDto::Brazil,
        PlayerCountry::Indonesia => PlayerCountryDto::Indonesia,
        PlayerCountry::Mexico => PlayerCountryDto::Mexico,
        PlayerCountry::Turkey => PlayerCountryDto::Turkey,
        PlayerCountry::SaudiArabia => PlayerCountryDto::SaudiArabia,
        PlayerCountry::Egypt => PlayerCountryDto::Egypt,
        PlayerCountry::Greece => PlayerCountryDto::Greece)
}
