//! City and territory acceptance tests.

use aonw_content::RulesetDefinition;
use aonw_domain::{
    ArmyTroop, City, CityFoundingDraft, HexCoord, InteractionState, MovementUnits,
    PendingInteraction, TroopKind, Unit, UnitKind,
};
use aonw_engine::{
    CityExpansionOptionsQuery, CityFoundingOptionsQuery, CityWorkedHexOptionsQuery,
    CommandRejectionCode, EngineContext, FoundCityCommand, GameEngine, GameQuery, PlayerCommand,
    QueryResult, SelectCityExpansionHexCommand, ToggleWorkedHexCommand,
};

#[path = "city/manifest.rs"]
mod manifest;
#[path = "city/support.rs"]
mod support;

use support::{city_id, map, player, state, unit, unit_id};

#[test]
fn founding_query_owns_legal_next_choices_and_preserves_the_canonical_draft() {
    let map = map(7, 7);
    let actor = player("player-1");
    let founder_id = unit_id("settler-1");
    let center = HexCoord::new(3, 3);
    let selected = HexCoord::new(3, 2);
    let interaction = InteractionState::new(
        Some(CityFoundingDraft::new(
            founder_id.clone(),
            actor.clone(),
            center,
            [selected],
        )),
        None,
    );
    let state = state(
        &map,
        vec![unit("settler-1", &actor, UnitKind::Settler, center)],
        Vec::new(),
        interaction,
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());

    let QueryResult::CityFoundingOptions(options) = GameEngine::query(
        &state,
        context,
        GameQuery::CityFoundingOptions(CityFoundingOptionsQuery::new(9, &founder_id)),
    )
    .expect("founding options") else {
        panic!("founding options result")
    };

    assert_eq!(options.center(), center);
    assert_eq!(options.required_controlled_hexes(), 2);
    assert_eq!(options.maximum_radius(), 2);
    assert_eq!(options.selected_controlled_hexes(), [selected]);
    assert!(!options.available_controlled_hexes().contains(&selected));
    assert!(
        options
            .available_controlled_hexes()
            .windows(2)
            .all(|pair| pair[0] < pair[1])
    );
    assert!(
        options
            .available_controlled_hexes()
            .iter()
            .all(|candidate| center.distance_to(*candidate) <= 2)
    );
    assert_eq!(
        options
            .ranked_available_controlled_hexes()
            .iter()
            .copied()
            .collect::<std::collections::BTreeSet<_>>(),
        options
            .available_controlled_hexes()
            .iter()
            .copied()
            .collect()
    );
}

#[test]
fn found_city_is_atomic_and_schedules_only_a_complete_connected_territory() {
    let map = map(7, 7);
    let actor = player("player-1");
    let founder_id = unit_id("settler-1");
    let center = HexCoord::new(3, 3);
    let state = state(
        &map,
        vec![unit("settler-1", &actor, UnitKind::Settler, center)],
        Vec::new(),
        InteractionState::new(
            Some(CityFoundingDraft::new(
                founder_id.clone(),
                actor.clone(),
                center,
                [HexCoord::new(3, 2)],
            )),
            Some(PendingInteraction::ResearchSelection {
                owner_player_id: actor.clone(),
            }),
        ),
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());

    let invalid = GameEngine::apply_player_owned(
        state.clone(),
        context,
        PlayerCommand::FoundCity(FoundCityCommand::new(
            9,
            &founder_id,
            &[HexCoord::new(3, 2)],
        )),
    )
    .expect("normal rejection");
    assert_eq!(
        invalid.rejection().expect("invalid territory").code(),
        CommandRejectionCode::CityControlledHexesInvalid
    );
    assert_eq!(invalid.state(), &state);

    let controlled = [HexCoord::new(3, 2), HexCoord::new(2, 3)];
    let accepted = GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::FoundCity(FoundCityCommand::new(9, &founder_id, &controlled)),
    )
    .expect("found city");
    assert!(accepted.is_accepted());
    assert_eq!(accepted.state().revision().get(), 10);
    assert!(
        accepted
            .state()
            .interaction()
            .city_founding_draft()
            .is_none()
    );
    assert!(matches!(
        accepted.state().interaction().pending(),
        Some(PendingInteraction::ResearchSelection { owner_player_id })
            if owner_player_id == &actor
    ));
    let founder = accepted.state().unit(&founder_id).expect("founder");
    let job = founder
        .activity()
        .city_founding_job()
        .expect("founding job");
    assert_eq!(job.center(), center);
    assert_eq!(
        job.controlled_hexes(),
        [HexCoord::new(2, 3), HexCoord::new(3, 2)]
    );
    assert_eq!(founder.movement_units(), MovementUnits::ZERO);
}

#[test]
fn founding_rejection_precedence_is_revision_then_control_then_founder_kind() {
    let map = map(5, 5);
    let actor = player("player-1");
    let foreign = player("player-2");
    let founder_id = unit_id("warrior-1");
    let foreign_state = state(
        &map,
        vec![
            unit(
                "warrior-1",
                &foreign,
                UnitKind::Warrior,
                HexCoord::new(2, 2),
            ),
            unit("actor-1", &actor, UnitKind::Warrior, HexCoord::new(0, 0)),
        ],
        Vec::new(),
        InteractionState::default(),
    );
    let controlled = [HexCoord::new(2, 1), HexCoord::new(1, 2)];
    let apply = |revision| {
        GameEngine::apply_player_owned(
            foreign_state.clone(),
            EngineContext::canonical(&actor, &map, RulesetDefinition::standard()),
            PlayerCommand::FoundCity(FoundCityCommand::new(revision, &founder_id, &controlled)),
        )
        .expect("rejection")
    };
    assert_eq!(
        apply(8).rejection().expect("stale").code(),
        CommandRejectionCode::StaleRevision
    );
    assert_eq!(
        apply(9).rejection().expect("control").code(),
        CommandRejectionCode::CityFounderNotControlled
    );

    let owned = state(
        &map,
        vec![unit(
            "warrior-1",
            &actor,
            UnitKind::Warrior,
            HexCoord::new(2, 2),
        )],
        Vec::new(),
        InteractionState::default(),
    );
    let rejected = GameEngine::apply_player_owned(
        owned,
        EngineContext::canonical(&actor, &map, RulesetDefinition::standard()),
        PlayerCommand::FoundCity(FoundCityCommand::new(9, &founder_id, &controlled)),
    )
    .expect("kind rejection");
    assert_eq!(
        rejected.rejection().expect("invalid founder").code(),
        CommandRejectionCode::CityFounderInvalid
    );
}

#[test]
fn commander_requires_and_consumes_a_real_settler_troop() {
    let map = map(6, 6);
    let actor = player("player-1");
    let founder_id = unit_id("commander-1");
    let commander = Unit::builder(
        founder_id.clone(),
        actor.clone(),
        UnitKind::Commander,
        "commander",
        HexCoord::new(2, 2),
        MovementUnits::new(10),
    )
    .with_army([ArmyTroop::new(TroopKind::Warrior, 1)])
    .build()
    .expect("commander");
    let state = state(
        &map,
        vec![commander],
        Vec::new(),
        InteractionState::default(),
    );
    let controlled = [HexCoord::new(2, 1), HexCoord::new(1, 2)];
    let rejected = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&actor, &map, RulesetDefinition::standard()),
        PlayerCommand::FoundCity(FoundCityCommand::new(9, &founder_id, &controlled)),
    )
    .expect("no settlers");
    assert_eq!(
        rejected.rejection().expect("no settlers").code(),
        CommandRejectionCode::CityFounderNoSettlers
    );
}

#[test]
fn worked_hex_query_exposes_only_legal_toggles_at_the_population_limit() {
    let map = map(7, 7);
    let actor = player("player-1");
    let city_id = city_id("city-a");
    let selected = HexCoord::new(4, 4);
    let city = City::builder(
        city_id.clone(),
        actor.clone(),
        "Warsaw",
        HexCoord::new(3, 3),
    )
    .with_progression(1, 0, 6, 2)
    .with_controlled_hexes([HexCoord::new(4, 3), selected, HexCoord::new(3, 4)])
    .with_worked_hexes([selected])
    .build()
    .expect("city");
    let state = state(
        &map,
        Vec::new(),
        vec![city],
        InteractionState::new(
            None,
            Some(PendingInteraction::CityWorkedHexSelection {
                owner_player_id: actor.clone(),
                city_id: city_id.clone(),
            }),
        ),
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());

    let QueryResult::CityWorkedHexOptions(options) = GameEngine::query(
        &state,
        context,
        GameQuery::CityWorkedHexOptions(CityWorkedHexOptionsQuery::new(9, &city_id)),
    )
    .expect("worked options") else {
        panic!("worked options result")
    };
    assert_eq!(options.limit(), 1);
    assert_eq!(options.selected_hexes(), [selected]);
    assert_eq!(options.effective_hexes(), [selected]);
    assert_eq!(options.available_hexes(), [selected]);
    assert!(
        options
            .controlled_hexes()
            .windows(2)
            .all(|pair| pair[0] < pair[1])
    );

    let unavailable = GameEngine::apply_player_owned(
        state.clone(),
        context,
        PlayerCommand::ToggleWorkedHex(ToggleWorkedHexCommand::new(
            9,
            &city_id,
            HexCoord::new(4, 3),
        )),
    )
    .expect("limit rejection");
    assert_eq!(
        unavailable.rejection().expect("limit").code(),
        CommandRejectionCode::WorkedHexLimitReached
    );
    assert_eq!(unavailable.state(), &state);

    let removed = GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::ToggleWorkedHex(ToggleWorkedHexCommand::new(9, &city_id, selected)),
    )
    .expect("remove worked hex");
    assert!(removed.is_accepted());
    assert!(
        removed
            .state()
            .city(&city_id)
            .expect("city")
            .worked_hexes()
            .is_empty()
    );
    assert!(matches!(
        removed.state().interaction().pending(),
        Some(PendingInteraction::CityWorkedHexSelection {
            owner_player_id,
            city_id: pending_city_id,
        }) if owner_player_id == &actor && pending_city_id == &city_id
    ));
}

#[test]
fn expansion_query_is_ranked_and_selection_is_atomic_and_idempotent() {
    let map = map(7, 7);
    let actor = player("player-1");
    let city_id = city_id("city-a");
    let city = City::builder(
        city_id.clone(),
        actor.clone(),
        "Warsaw",
        HexCoord::new(3, 3),
    )
    .with_controlled_hexes([HexCoord::new(4, 3), HexCoord::new(4, 4)])
    .build()
    .expect("city");
    let state = state(
        &map,
        Vec::new(),
        vec![city],
        InteractionState::new(
            None,
            Some(PendingInteraction::CityExpansionSelection {
                owner_player_id: actor.clone(),
                city_id: city_id.clone(),
            }),
        ),
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let QueryResult::CityExpansionOptions(options) = GameEngine::query(
        &state,
        context,
        GameQuery::CityExpansionOptions(CityExpansionOptionsQuery::new(9, &city_id)),
    )
    .expect("expansion options") else {
        panic!("expansion options result")
    };
    assert!(!options.candidates().is_empty());
    assert!(
        options
            .controlled_hexes()
            .windows(2)
            .all(|pair| pair[0] < pair[1])
    );
    assert!(options.candidates().windows(2).all(|pair| {
        pair[0].score() > pair[1].score()
            || pair[0].score() == pair[1].score()
                && (pair[0].distance(), pair[0].coordinate())
                    <= (pair[1].distance(), pair[1].coordinate())
    }));
    let target = options.candidates()[0].coordinate();

    let selected = GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::SelectCityExpansionHex(SelectCityExpansionHexCommand::new(
            9, &city_id, target,
        )),
    )
    .expect("select expansion");
    assert!(selected.is_accepted());
    assert_eq!(
        selected
            .state()
            .city(&city_id)
            .expect("city")
            .preferred_expansion_hex(),
        Some(target)
    );
    let repeated = GameEngine::apply_player_owned(
        selected.state().clone(),
        EngineContext::canonical(&actor, &map, RulesetDefinition::standard()),
        PlayerCommand::SelectCityExpansionHex(SelectCityExpansionHexCommand::new(
            10, &city_id, target,
        )),
    )
    .expect("idempotent selection");
    assert!(repeated.is_accepted());
    assert_eq!(repeated.state().revision().get(), 10);
    assert!(matches!(
        repeated.state().interaction().pending(),
        Some(PendingInteraction::CityExpansionSelection {
            owner_player_id,
            city_id: pending_city_id,
        }) if owner_player_id == &actor && pending_city_id == &city_id
    ));
}
