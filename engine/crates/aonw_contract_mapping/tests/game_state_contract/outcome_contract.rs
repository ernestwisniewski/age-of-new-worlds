use std::collections::BTreeMap;

use aonw_contract_mapping::{decode_game_state, encode_game_state};
use aonw_contracts::{GameOutcomeConditionDto, GameOutcomeDto};

use super::contract;

#[test]
fn terminal_outcome_round_trip_preserves_winner_and_exact_scores() {
    let mut source = contract();
    source.outcome = GameOutcomeDto {
        condition: GameOutcomeConditionDto::Score,
        winner_player_id: Some("player-1".to_owned()),
        score_by_player_id: BTreeMap::from([
            ("player-1".to_owned(), 127),
            ("player-2".to_owned(), 30),
        ]),
    };

    let state = decode_game_state(source.clone()).expect("decode score outcome");
    assert!(state.outcome().is_terminal());
    assert_eq!(encode_game_state(&state), source);
}

#[test]
fn outcome_rejects_unknown_players_negative_scores_and_invalid_shapes_with_paths() {
    let mut unknown_winner = contract();
    unknown_winner.outcome = GameOutcomeDto {
        condition: GameOutcomeConditionDto::Conquest,
        winner_player_id: Some("player-3".to_owned()),
        score_by_player_id: BTreeMap::new(),
    };
    assert_eq!(
        decode_game_state(unknown_winner)
            .expect_err("unknown outcome winner")
            .path(),
        "$.outcome.winnerPlayerId"
    );

    let mut negative_score = contract();
    negative_score.outcome = GameOutcomeDto {
        condition: GameOutcomeConditionDto::Score,
        winner_player_id: Some("player-1".to_owned()),
        score_by_player_id: BTreeMap::from([
            ("player-1".to_owned(), 10),
            ("player-2".to_owned(), -1),
        ]),
    };
    assert_eq!(
        decode_game_state(negative_score)
            .expect_err("negative outcome score")
            .path(),
        "$.outcome.scoreByPlayerId"
    );

    let mut invalid_draw = contract();
    invalid_draw.outcome = GameOutcomeDto {
        condition: GameOutcomeConditionDto::Draw,
        winner_player_id: None,
        score_by_player_id: BTreeMap::from([
            ("player-1".to_owned(), 10),
            ("player-2".to_owned(), 9),
        ]),
    };
    assert_eq!(
        decode_game_state(invalid_draw)
            .expect_err("untied draw")
            .path(),
        "$.outcome"
    );
}
