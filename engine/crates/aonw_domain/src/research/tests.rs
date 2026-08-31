use crate::{PlayerId, WonderType};

use super::{
    KnowledgeState, PlayerResearchState, PlayerResearchStateBuildError, ResearchState,
    ResearchTransitionError, TechnologyId, WonderRegistry,
};

#[test]
fn player_research_rejects_noncanonical_progress_and_unlocks() {
    assert_eq!(
        PlayerResearchState::try_new(
            [TechnologyId::Agriculture],
            Some(TechnologyId::Agriculture),
            [],
            0,
        ),
        Err(PlayerResearchStateBuildError::ActiveAlreadyUnlocked(
            TechnologyId::Agriculture
        ))
    );
    assert_eq!(
        PlayerResearchState::try_new([], None, [(TechnologyId::Mining, 0)], 0,),
        Err(PlayerResearchStateBuildError::NonPositiveProgress {
            technology: TechnologyId::Mining,
            amount: 0,
        })
    );
}

#[test]
fn wonder_completion_is_unique_and_preserves_research() {
    let owner = PlayerId::new("owner").expect("owner");
    let registry = WonderRegistry::default()
        .try_with_completed(WonderType::GreatLibrary, owner.clone())
        .expect("completion");
    let error = registry
        .try_with_completed(WonderType::GreatLibrary, owner.clone())
        .expect_err("duplicate completion");
    assert_eq!(error.wonder(), WonderType::GreatLibrary);
    assert_eq!(error.existing_owner(), &owner);
    assert!(error.to_string().contains("GreatLibrary"));

    let knowledge = KnowledgeState::new(ResearchState::default(), WonderRegistry::default())
        .with_wonder_registry(registry);
    assert!(knowledge.research().players().is_empty());
    assert_eq!(
        knowledge
            .wonder_registry()
            .completed_by()
            .get(&WonderType::GreatLibrary),
        Some(&owner)
    );
}

#[test]
fn active_technology_completion_is_explicit_and_preserves_other_progress() {
    let player = PlayerId::new("player").expect("player");
    let idle = PlayerResearchState::default();
    assert_eq!(idle.after_unlocking_active(), (idle.clone(), None));

    let selected = PlayerResearchState::try_new(
        [TechnologyId::Agriculture],
        Some(TechnologyId::Writing),
        [(TechnologyId::Writing, 3), (TechnologyId::Mining, 2)],
        1,
    )
    .expect("selected research");
    let (completed, technology) = selected.after_unlocking_active();
    assert_eq!(technology, Some(TechnologyId::Writing));
    assert_eq!(completed.active_technology_id(), None);
    assert!(
        completed
            .unlocked_technology_ids()
            .contains(&TechnologyId::Writing)
    );
    assert_eq!(
        completed
            .progress_by_technology_id()
            .get(&TechnologyId::Mining),
        Some(&2)
    );
    assert!(
        !completed
            .progress_by_technology_id()
            .contains_key(&TechnologyId::Writing)
    );
    assert_eq!(completed.science_overflow(), 1);

    let research = ResearchState::default().updating_player(player.clone(), completed.clone());
    assert_eq!(research.players().get(&player), Some(&completed));
}

#[test]
fn selection_caps_and_consumes_overflow_without_losing_other_progress() {
    let research = PlayerResearchState::try_new(
        [TechnologyId::Agriculture],
        None,
        [(TechnologyId::Writing, 3), (TechnologyId::Mining, 2)],
        10,
    )
    .expect("research");
    let selected = research
        .try_after_selecting(TechnologyId::Writing, 4)
        .expect("selection");
    assert_eq!(selected.active_technology_id(), Some(TechnologyId::Writing));
    assert_eq!(
        selected
            .progress_by_technology_id()
            .get(&TechnologyId::Writing),
        Some(&7)
    );
    assert_eq!(
        selected
            .progress_by_technology_id()
            .get(&TechnologyId::Mining),
        Some(&2)
    );
    assert_eq!(selected.science_overflow(), 0);
    assert_eq!(
        research.try_after_selecting(TechnologyId::Agriculture, 4),
        Err(ResearchTransitionError::TechnologyAlreadyUnlocked(
            TechnologyId::Agriculture
        ))
    );
}

#[test]
fn checked_science_progresses_then_completes_with_new_overflow() {
    let selected = PlayerResearchState::try_new(
        [],
        Some(TechnologyId::Writing),
        [(TechnologyId::Writing, 3), (TechnologyId::Mining, 2)],
        0,
    )
    .expect("selected research");
    let (progressed, completed) = selected.try_after_science(2, 8).expect("progress");
    assert_eq!(completed, None);
    assert_eq!(
        progressed
            .progress_by_technology_id()
            .get(&TechnologyId::Writing),
        Some(&5)
    );
    let (unlocked, completed) = progressed.try_after_science(6, 8).expect("completion");
    assert_eq!(completed, Some(TechnologyId::Writing));
    assert_eq!(unlocked.active_technology_id(), None);
    assert!(
        unlocked
            .unlocked_technology_ids()
            .contains(&TechnologyId::Writing)
    );
    assert_eq!(unlocked.science_overflow(), 3);
    assert_eq!(
        unlocked
            .progress_by_technology_id()
            .get(&TechnologyId::Mining),
        Some(&2)
    );
}

#[test]
fn research_transition_failures_are_atomic_and_explicit() {
    let selected = PlayerResearchState::try_new(
        [],
        Some(TechnologyId::Writing),
        [(TechnologyId::Writing, i64::MAX)],
        0,
    )
    .expect("selected research");
    assert_eq!(
        selected.try_after_science(-1, 8),
        Err(ResearchTransitionError::NegativeScience(-1))
    );
    assert_eq!(
        selected.try_after_science(1, 0),
        Err(ResearchTransitionError::ZeroEffectiveCost(
            TechnologyId::Writing
        ))
    );
    assert_eq!(
        selected.try_after_science(1, 8),
        Err(ResearchTransitionError::ProgressOverflow(
            TechnologyId::Writing
        ))
    );
    assert_eq!(
        selected.without_active_technology().active_technology_id(),
        None
    );
}
