use super::*;

#[test]
fn resolver_selects_cultural_winner_from_distinct_owned_artifacts() {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let rules = outcome_rules(OutcomeRuleOptions {
        cultural: RuleToggle::Enabled,
        ..OutcomeRuleOptions::default()
    });
    let identity = identity(rules, &p1, &p2);
    let map = map_with_cols(8, Vec::new());
    let cities = (0..6)
        .map(|col| {
            City::new(
                CityId::new(format!("city-{col}")).expect("city id"),
                p1.clone(),
                HexCoord::new(col, 0),
                None,
            )
        })
        .collect::<Vec<_>>();
    let artifacts = artifact_types()
        .into_iter()
        .enumerate()
        .map(|(index, kind)| {
            WorldArtifact::new(
                ArtifactId::new(format!("artifact-{index}")).expect("artifact id"),
                kind,
                WorldArtifactLocation::Stored(
                    CityId::new(format!("city-{index}")).expect("city id"),
                ),
            )
        });
    let objectives = ObjectiveState::try_new(
        &identity,
        BTreeMap::new(),
        BTreeMap::from([(p1.clone(), 5)]),
        [],
    )
    .expect("objectives");
    let state = state_builder(
        &map,
        identity,
        7,
        [
            unit("unit-1", &p1, UnitKind::Commander, 0, 0),
            unit("unit-2", &p2, UnitKind::Commander, 7, 0),
        ],
    )
    .with_cities(cities)
    .with_artifacts(artifacts)
    .with_objectives(objectives)
    .try_build()
    .expect("cultural victory state");

    let outcome = resolve_game_outcome(&state, &map, RulesetDefinition::standard())
        .expect("cultural outcome");
    assert_eq!(outcome.condition(), GameOutcomeCondition::Cultural);
    assert_eq!(outcome.winner_player_id(), Some(&p1));
}

#[test]
fn tied_domination_candidates_do_not_end_the_match() {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let rules = outcome_rules(OutcomeRuleOptions {
        domination: RuleToggle::Enabled,
        domination_percent: "50",
        ..OutcomeRuleOptions::default()
    });
    let identity = identity(rules, &p1, &p2);
    let map = map(Vec::new());
    let cities = [
        City::new(
            CityId::new("city-1").expect("city id"),
            p1.clone(),
            HexCoord::new(0, 0),
            Some(HexCoord::new(1, 0)),
        ),
        City::new(
            CityId::new("city-2").expect("city id"),
            p2.clone(),
            HexCoord::new(2, 0),
            Some(HexCoord::new(3, 0)),
        ),
    ];
    let objectives = ObjectiveState::try_new(
        &identity,
        BTreeMap::from([(p1.clone(), 5), (p2.clone(), 5)]),
        BTreeMap::new(),
        [],
    )
    .expect("objectives");
    let state = state_builder(
        &map,
        identity,
        7,
        [
            unit("unit-1", &p1, UnitKind::Commander, 0, 0),
            unit("unit-2", &p2, UnitKind::Commander, 3, 0),
        ],
    )
    .with_cities(cities)
    .with_objectives(objectives)
    .try_build()
    .expect("tied domination state");

    assert_eq!(
        resolve_game_outcome(&state, &map, RulesetDefinition::standard())
            .expect("ongoing tied outcome")
            .condition(),
        GameOutcomeCondition::Ongoing
    );
}

#[test]
fn one_participant_match_remains_ongoing() {
    let p1 = player("player-1");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [participant(p1.clone(), "One")],
        GameMode::Multiplayer,
    )
    .expect("single-player identity");
    let map = map(Vec::new());
    let state = state(
        &map,
        identity,
        7,
        [unit("unit-1", &p1, UnitKind::Commander, 0, 0)],
    );

    assert_eq!(
        resolve_game_outcome(&state, &map, RulesetDefinition::standard())
            .expect("ongoing single-player outcome")
            .condition(),
        GameOutcomeCondition::Ongoing
    );
}
