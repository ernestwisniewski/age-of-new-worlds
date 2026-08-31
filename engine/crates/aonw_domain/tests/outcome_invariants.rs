//! Structural invariants for persisted authoritative match outcomes.

use std::collections::BTreeMap;

use aonw_domain::{
    GameMode, GameOutcome, GameOutcomeBuildError, GameOutcomeCondition, MatchIdentity, MatchRules,
    Participant, PlayerCountry, PlayerId, PlayerKind,
};

#[test]
fn terminal_winner_conditions_require_one_known_winner_and_no_scores() {
    let (identity, p1, _p2) = identity();

    let conquest = GameOutcome::try_new(
        &identity,
        GameOutcomeCondition::Conquest,
        Some(p1.clone()),
        BTreeMap::new(),
    )
    .expect("conquest outcome");
    assert!(conquest.is_terminal());
    assert_eq!(conquest.winner_player_id(), Some(&p1));

    assert_eq!(
        GameOutcome::try_new(
            &identity,
            GameOutcomeCondition::Domination,
            None,
            BTreeMap::new(),
        ),
        Err(GameOutcomeBuildError::InvalidConditionShape)
    );
    assert_eq!(
        GameOutcome::try_new(
            &identity,
            GameOutcomeCondition::Ongoing,
            Some(p1),
            BTreeMap::new(),
        ),
        Err(GameOutcomeBuildError::InvalidConditionShape)
    );
}

#[test]
fn score_and_draw_shapes_are_fail_closed() {
    let (identity, p1, p2) = identity();
    let scores = BTreeMap::from([(p1.clone(), 12), (p2.clone(), 7)]);
    let score_outcome = GameOutcome::try_new(
        &identity,
        GameOutcomeCondition::Score,
        Some(p1.clone()),
        scores,
    )
    .expect("unique score winner");
    assert_eq!(score_outcome.score_by_player_id().get(&p2), Some(&7));

    assert_eq!(
        GameOutcome::try_new(
            &identity,
            GameOutcomeCondition::Score,
            Some(p1.clone()),
            BTreeMap::from([(p1.clone(), 12), (p2.clone(), 12)]),
        ),
        Err(GameOutcomeBuildError::InvalidConditionShape)
    );
    let draw = GameOutcome::try_new(
        &identity,
        GameOutcomeCondition::Draw,
        None,
        BTreeMap::from([(p1.clone(), 12), (p2.clone(), 12)]),
    )
    .expect("tied draw");
    assert!(draw.is_terminal());

    assert_eq!(
        GameOutcome::try_new(
            &identity,
            GameOutcomeCondition::Draw,
            None,
            BTreeMap::from([(p1.clone(), 12), (p2, 11)]),
        ),
        Err(GameOutcomeBuildError::InvalidConditionShape)
    );
    assert_eq!(
        GameOutcome::try_new(
            &identity,
            GameOutcomeCondition::Score,
            Some(p1.clone()),
            BTreeMap::from([(p1.clone(), -1)]),
        ),
        Err(GameOutcomeBuildError::NegativeScore(p1))
    );
}

#[test]
fn outcome_references_must_belong_to_the_match() {
    let (identity, p1, _p2) = identity();
    let foreign = player("player-3");
    assert_eq!(
        GameOutcome::try_new(
            &identity,
            GameOutcomeCondition::Cultural,
            Some(foreign.clone()),
            BTreeMap::new(),
        ),
        Err(GameOutcomeBuildError::PlayerNotFound(foreign.clone()))
    );
    assert_eq!(
        GameOutcome::try_new(
            &identity,
            GameOutcomeCondition::Score,
            Some(p1.clone()),
            BTreeMap::from([(p1, 10), (foreign.clone(), 1)]),
        ),
        Err(GameOutcomeBuildError::PlayerNotFound(foreign))
    );
}

fn identity() -> (MatchIdentity, PlayerId, PlayerId) {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [
            participant(p1.clone(), "One"),
            participant(p2.clone(), "Two"),
        ],
        GameMode::Multiplayer,
    )
    .expect("identity");
    (identity, p1, p2)
}

fn participant(id: PlayerId, name: &str) -> Participant {
    Participant::try_new(
        id,
        name,
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Human,
        None,
    )
    .expect("participant")
}

fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player id")
}
