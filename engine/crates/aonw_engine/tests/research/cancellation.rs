use std::collections::BTreeMap;

use aonw_content::RulesetDefinition;
use aonw_domain::{
    CityId, GameState, PendingInteraction, PlayerId, PlayerTurnState, ResearchStateUpdate,
    StateRevision, TechnologyId, TurnLifecycle,
};
use aonw_engine::{
    CancelResearchSelectionCommand, CommandRejectionCode, EngineContext, GameEngine, PlayerCommand,
    SelectTechnologyCommand,
};

use super::fixture;

#[test]
fn cancellation_clears_only_owned_pending_choice_and_repeating_is_a_noop() {
    let (map, state, actor) = fixture();
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let expected = with_pending(&state, 10, None);
    let cancelled = GameEngine::apply_player_owned(state, context, cancel(9))
        .expect("cancel research selection");
    assert!(cancelled.is_accepted());
    assert_eq!(cancelled.state(), &expected);
    assert!(cancelled.events().is_empty());
    assert!(cancelled.evidence().is_none());
    assert_eq!(cancelled.digest(), GameEngine::state_digest(&expected));

    let repeated = GameEngine::apply_player_owned(expected.clone(), context, cancel(10))
        .expect("repeat cancellation");
    assert!(repeated.is_accepted());
    assert_eq!(repeated.state(), &expected);
    assert_eq!(repeated.digest(), cancelled.digest());
    assert!(repeated.events().is_empty());
}

#[test]
fn cancellation_preserves_active_research_and_accumulated_progress() {
    let (map, state, actor) = fixture();
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let selected = GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::SelectTechnology(SelectTechnologyCommand::new(9, TechnologyId::Storage)),
    )
    .expect("select technology");
    assert!(selected.is_accepted());
    for pending in [
        None,
        Some(PendingInteraction::ResearchSelection {
            owner_player_id: actor.clone(),
        }),
    ] {
        let expected_revision = if pending.is_some() { 11 } else { 10 };
        let state = with_pending(selected.state(), 10, pending);
        let cancelled = GameEngine::apply_player_owned(state, context, cancel(10))
            .expect("cancel while researching");
        assert!(cancelled.is_accepted());
        assert_eq!(
            cancelled.state(),
            &with_pending(selected.state(), expected_revision, None)
        );
    }
}

#[test]
fn cancellation_preserves_foreign_and_non_research_choices() {
    let (map, state, actor) = fixture();
    let outsider = PlayerId::new("outsider").expect("other participant");
    let cases = [
        (state.clone(), outsider),
        (
            with_pending(
                &state,
                9,
                Some(PendingInteraction::CityWorkedHexSelection {
                    owner_player_id: actor.clone(),
                    city_id: CityId::new("capital").expect("city"),
                }),
            ),
            actor,
        ),
    ];
    for (state, actor) in cases {
        let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
        let cancelled = GameEngine::apply_player_owned(state.clone(), context, cancel(9))
            .expect("unrelated cancellation");
        assert!(cancelled.is_accepted());
        assert_eq!(cancelled.state(), &state);
        assert_eq!(cancelled.digest(), GameEngine::state_digest(&state));
    }
}

#[test]
fn cancellation_rejects_stale_revision_even_without_a_pending_choice() {
    let (map, state, actor) = fixture();
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    for state in [state.clone(), with_pending(&state, 9, None)] {
        let rejected = GameEngine::apply_player_owned(state.clone(), context, cancel(8))
            .expect("stale cancellation");
        assert_eq!(
            rejected.rejection().expect("rejection").code(),
            CommandRejectionCode::StaleRevision
        );
        assert_eq!(rejected.state(), &state);
    }
}

#[test]
fn revision_overflow_rejects_mutation_but_allows_a_noop() {
    let (map, state, actor) = fixture();
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let state = with_pending(&state, u64::MAX, state.interaction().pending().cloned());
    let rejected = GameEngine::apply_player_owned(state.clone(), context, cancel(u64::MAX))
        .expect("overflow rejection");
    assert_eq!(
        rejected.rejection().expect("rejection").code(),
        CommandRejectionCode::StateRevisionOverflow
    );
    assert_eq!(rejected.state(), &state);

    let cleared = with_pending(&state, u64::MAX, None);
    let noop = GameEngine::apply_player_owned(cleared.clone(), context, cancel(u64::MAX))
        .expect("no revision change");
    assert!(noop.is_accepted());
    assert_eq!(noop.state(), &cleared);
}

#[test]
fn cancellation_respects_participant_and_turn_permissions() {
    let (map, state, actor) = fixture();
    let unknown = PlayerId::new("unknown").expect("unknown player");
    let context = EngineContext::canonical(&unknown, &map, RulesetDefinition::standard());
    let rejected = GameEngine::apply_player_owned(state.clone(), context, cancel(9))
        .expect("unknown participant rejection");
    assert_eq!(
        rejected.rejection().expect("rejection").code(),
        CommandRejectionCode::TurnPlayerNotActive
    );
    assert_eq!(rejected.state(), &state);

    for (turn_state, submitted) in [
        (PlayerTurnState::Finished, vec![]),
        (PlayerTurnState::Finished, vec![actor.clone()]),
    ] {
        let lifecycle = state.match_lifecycle();
        let mut states = lifecycle.turn().turn_states_by_player_id().clone();
        states.insert(actor.clone(), turn_state);
        let turn = TurnLifecycle::try_new(
            lifecycle.identity(),
            states,
            lifecycle
                .turn()
                .required_submission_player_ids()
                .iter()
                .cloned(),
            submitted,
            BTreeMap::new(),
            [],
            [],
            None,
        )
        .expect("turn lifecycle");
        let state = state
            .clone()
            .into_started_match(
                lifecycle.clone().with_turn(turn),
                state.fog_of_war().clone(),
                state.diplomacy().clone(),
            )
            .expect("restricted state");
        let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
        let rejected = GameEngine::apply_player_owned(state.clone(), context, cancel(9))
            .expect("inactive participant rejection");
        assert_eq!(
            rejected.rejection().expect("rejection").code(),
            CommandRejectionCode::TurnPlayerNotActive
        );
        assert_eq!(rejected.state(), &state);
    }
}

fn cancel(revision: u64) -> PlayerCommand<'static> {
    PlayerCommand::CancelResearchSelection(CancelResearchSelectionCommand::new(revision))
}

fn with_pending(
    state: &GameState,
    revision: u64,
    pending: Option<PendingInteraction>,
) -> GameState {
    state
        .clone()
        .into_after_research(ResearchStateUpdate {
            revision: StateRevision::new(revision),
            knowledge: state.knowledge().clone(),
            interaction: state.interaction().clone().with_pending(pending),
        })
        .expect("research state")
}
