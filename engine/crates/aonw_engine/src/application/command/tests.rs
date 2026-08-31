use std::collections::BTreeMap;

use aonw_domain::{
    CityId, DiplomacyStateBuildError, GameMode, GameState, GameStateBuildError, HexCoord,
    HexGridBounds, MatchIdentity, MatchLifecycle, MatchRules, Participant, PlayerCountry, PlayerId,
    PlayerKind, PlayerTurnState, StateRevision, TurnLifecycle, TurnLifecycleBuildError, UnitId,
    UnitOccupancyPolicy,
};

use super::{CanonicalEngineError, EventBudget, PlayerCommand, player_action_lifecycle_rejection};
use crate::{
    CommandRejectionCode, MoveUnitCommand, SelectCityExpansionHexCommand, ToggleWorkedHexCommand,
    UnitActionCommand,
};

#[test]
fn player_commands_publish_reviewed_event_budgets() {
    let unit_id = UnitId::new("unit-1").expect("unit id");
    let state = GameState::try_new(
        StateRevision::INITIAL,
        1,
        HexGridBounds::new(1, 1).expect("bounds"),
        UnitOccupancyPolicy::Exclusive,
        [],
    )
    .expect("state");

    assert_eq!(
        PlayerCommand::MoveUnit(MoveUnitCommand::new(0, &unit_id, HexCoord::new(1, 0)))
            .event_budget(&state),
        EventBudget::SINGLE
    );
    assert_eq!(
        PlayerCommand::FortifyUnit(UnitActionCommand::new(0, &unit_id)).event_budget(&state),
        EventBudget::NONE
    );
    let city_id = CityId::new("city-1").expect("city id");
    assert_eq!(
        PlayerCommand::ToggleWorkedHex(ToggleWorkedHexCommand::new(
            0,
            &city_id,
            HexCoord::new(0, 0),
        ))
        .event_budget(&state),
        EventBudget::NONE
    );
    assert_eq!(
        PlayerCommand::SelectCityExpansionHex(SelectCityExpansionHexCommand::new(
            0,
            &city_id,
            HexCoord::new(0, 0),
        ))
        .event_budget(&state),
        EventBudget::NONE
    );
}

#[test]
fn canonical_engine_error_formats_every_source_family() {
    let player = PlayerId::new("player").expect("player id");
    let unit = UnitId::new("unit").expect("unit id");
    for error in [
        CanonicalEngineError::ContentHash("hash".into()),
        CanonicalEngineError::State(GameStateBuildError::UnitNotFound(unit)),
        CanonicalEngineError::TurnLifecycle(TurnLifecycleBuildError::UnknownPlayer(player)),
        CanonicalEngineError::Diplomacy(DiplomacyStateBuildError::EmptyId),
    ] {
        assert!(!error.to_string().is_empty());
    }
}

#[test]
fn player_action_lifecycle_gate_accepts_states_without_match_identity() {
    let actor = PlayerId::new("player").expect("player id");
    let bare_state = empty_state();
    assert_eq!(
        player_action_lifecycle_rejection(&bare_state, &actor, true),
        None
    );

    let active_state = state_with_turn_state(&actor, PlayerTurnState::Active, false);
    assert_eq!(
        player_action_lifecycle_rejection(&active_state, &actor, true),
        None
    );
    assert_eq!(
        player_action_lifecycle_rejection(&active_state, &actor, false),
        Some(CommandRejectionCode::TurnPlayerNotActive)
    );

    let finished_state = state_with_turn_state(&actor, PlayerTurnState::Finished, false);
    assert_eq!(
        player_action_lifecycle_rejection(&finished_state, &actor, true),
        Some(CommandRejectionCode::TurnPlayerNotActive)
    );

    let submitted_state = state_with_turn_state(&actor, PlayerTurnState::Finished, true);
    assert_eq!(
        player_action_lifecycle_rejection(&submitted_state, &actor, true),
        Some(CommandRejectionCode::TurnPlayerNotActive)
    );

    let outsider = PlayerId::new("outsider").expect("player id");
    assert_eq!(
        player_action_lifecycle_rejection(&active_state, &outsider, true),
        Some(CommandRejectionCode::TurnPlayerNotActive)
    );
}

fn state_with_turn_state(
    actor: &PlayerId,
    turn_state: PlayerTurnState,
    submitted: bool,
) -> GameState {
    let participant = Participant::try_new(
        actor.clone(),
        "Player",
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Human,
        None,
    )
    .expect("participant");
    let identity =
        MatchIdentity::try_new(MatchRules::default(), [participant], GameMode::Multiplayer)
            .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([(actor.clone(), turn_state)]),
        [actor.clone()],
        submitted.then(|| actor.clone()),
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("turn lifecycle");
    GameState::builder(
        StateRevision::INITIAL,
        1,
        HexGridBounds::new(1, 1).expect("bounds"),
        UnitOccupancyPolicy::Exclusive,
        [],
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state")
}

fn empty_state() -> GameState {
    GameState::try_new(
        StateRevision::INITIAL,
        1,
        HexGridBounds::new(1, 1).expect("bounds"),
        UnitOccupancyPolicy::Exclusive,
        [],
    )
    .expect("state")
}
