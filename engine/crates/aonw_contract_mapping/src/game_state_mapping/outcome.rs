use std::collections::BTreeMap;

use aonw_contracts::{GameOutcomeConditionDto, GameOutcomeDto};
use aonw_domain::{
    GameOutcome, GameOutcomeBuildError, GameOutcomeCondition, MatchIdentity, PlayerId,
};

use super::error::GameStateMappingError;

pub(super) fn decode_outcome(
    identity: &MatchIdentity,
    dto: GameOutcomeDto,
) -> Result<GameOutcome, GameStateMappingError> {
    let winner = dto
        .winner_player_id
        .map(|value| parse_player("$.outcome.winnerPlayerId", value))
        .transpose()?;
    if let Some(player) = winner.as_ref().filter(|player| !identity.contains(player)) {
        return Err(GameStateMappingError::new(
            "$.outcome.winnerPlayerId",
            GameOutcomeBuildError::PlayerNotFound(player.clone()).to_string(),
        ));
    }
    let scores = dto
        .score_by_player_id
        .into_iter()
        .map(|(player, score)| {
            parse_player("$.outcome.scoreByPlayerId", player).map(|player| (player, score))
        })
        .collect::<Result<BTreeMap<_, _>, _>>()?;
    GameOutcome::try_new(identity, decode_condition(dto.condition), winner, scores).map_err(
        |error| {
            let path = match error {
                GameOutcomeBuildError::PlayerNotFound(_)
                | GameOutcomeBuildError::NegativeScore(_) => "$.outcome.scoreByPlayerId",
                GameOutcomeBuildError::InvalidConditionShape => "$.outcome",
            };
            GameStateMappingError::new(path, error.to_string())
        },
    )
}

/// Encodes one validated authoritative match result.
#[must_use]
pub fn encode_game_outcome(value: &GameOutcome) -> GameOutcomeDto {
    GameOutcomeDto {
        condition: encode_condition(value.condition()),
        winner_player_id: value
            .winner_player_id()
            .map(|player| player.as_str().to_owned()),
        score_by_player_id: value
            .score_by_player_id()
            .iter()
            .map(|(player, score)| (player.as_str().to_owned(), *score))
            .collect(),
    }
}

fn parse_player(path: &'static str, value: String) -> Result<PlayerId, GameStateMappingError> {
    PlayerId::new(value).map_err(|error| GameStateMappingError::new(path, error.to_string()))
}

const fn decode_condition(value: GameOutcomeConditionDto) -> GameOutcomeCondition {
    match value {
        GameOutcomeConditionDto::Ongoing => GameOutcomeCondition::Ongoing,
        GameOutcomeConditionDto::Conquest => GameOutcomeCondition::Conquest,
        GameOutcomeConditionDto::Domination => GameOutcomeCondition::Domination,
        GameOutcomeConditionDto::Cultural => GameOutcomeCondition::Cultural,
        GameOutcomeConditionDto::Score => GameOutcomeCondition::Score,
        GameOutcomeConditionDto::Resignation => GameOutcomeCondition::Resignation,
        GameOutcomeConditionDto::Draw => GameOutcomeCondition::Draw,
    }
}

const fn encode_condition(value: GameOutcomeCondition) -> GameOutcomeConditionDto {
    match value {
        GameOutcomeCondition::Ongoing => GameOutcomeConditionDto::Ongoing,
        GameOutcomeCondition::Conquest => GameOutcomeConditionDto::Conquest,
        GameOutcomeCondition::Domination => GameOutcomeConditionDto::Domination,
        GameOutcomeCondition::Cultural => GameOutcomeConditionDto::Cultural,
        GameOutcomeCondition::Score => GameOutcomeConditionDto::Score,
        GameOutcomeCondition::Resignation => GameOutcomeConditionDto::Resignation,
        GameOutcomeCondition::Draw => GameOutcomeConditionDto::Draw,
    }
}
