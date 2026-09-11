use super::*;

fn option(technology: TechnologyId, discount: u32, cost: u32, progress: i64) -> ResearchOption {
    ResearchOption::new(
        technology,
        TechnologyAvailability::Available,
        cost,
        progress,
        discount,
        Vec::new(),
        Vec::new(),
        Vec::new(),
    )
}

#[test]
fn weights_worker_boost_and_completion_without_mutating_option_order() {
    let options = [
        option(TechnologyId::Mining, 0, 9, 0),
        option(TechnologyId::Agriculture, 2500, 9, 0),
    ];
    let result = recommend(&options, 3, RulesetDefinition::standard());
    assert_eq!(result[0].technology(), TechnologyId::Agriculture);
    assert_eq!(result[0].score(), 143); // boost 80 + worker 48 + three-turn bonus 15
    assert_eq!(result[0].turns_remaining(), Some(3));
    assert_eq!(
        result[0].reasons().collect::<Vec<_>>(),
        &[
            ResearchRecommendationReason::Boost,
            ResearchRecommendationReason::WorkerYields,
            ResearchRecommendationReason::NearCompletion
        ]
    );
    assert_eq!(options[0].technology(), TechnologyId::Mining);
}

#[test]
fn estimates_ceiling_and_bounds_extreme_progress_and_science() {
    assert_eq!(
        turns_remaining(&option(TechnologyId::Mining, 0, 10, 0), 3),
        Some(4)
    );
    assert_eq!(
        turns_remaining(&option(TechnologyId::Mining, 0, 10, 5), 3),
        Some(2)
    );
    assert_eq!(
        turns_remaining(&option(TechnologyId::Mining, 0, u32::MAX, i64::MIN), 1),
        Some(i64::from(u32::MAX))
    );
    assert_eq!(
        turns_remaining(&option(TechnologyId::Mining, 0, 10, i64::MAX), 1),
        None
    );
    assert_eq!(
        turns_remaining(&option(TechnologyId::Mining, 0, 10, 0), i64::MAX),
        Some(1)
    );
    assert_eq!(
        turns_remaining(&option(TechnologyId::Mining, 0, 10, 0), 0),
        None
    );
    assert_eq!(
        turns_remaining(&option(TechnologyId::Mining, 0, 0, 0), 1),
        None
    );
}

#[test]
fn filters_unavailable_and_uses_authored_priority_for_ties() {
    let mut options = [
        TechnologyId::Hunting,
        TechnologyId::Mining,
        TechnologyId::Agriculture,
        TechnologyId::Fishing,
        TechnologyId::Woodworking,
    ]
    .map(|id| option(id, 0, 10, 0))
    .to_vec();
    let result = recommend(&options, 0, RulesetDefinition::standard());
    assert_eq!(
        result
            .iter()
            .map(ResearchRecommendation::technology)
            .collect::<Vec<_>>(),
        [
            TechnologyId::Agriculture,
            TechnologyId::Mining,
            TechnologyId::Hunting
        ]
    );
    options.reverse();
    assert_eq!(
        recommend(&options, 0, RulesetDefinition::standard()),
        result
    );
    let excluded = [
        TechnologyAvailability::Unlocked,
        TechnologyAvailability::Active,
        TechnologyAvailability::LockedByPrerequisites,
        TechnologyAvailability::LockedByTechnology,
    ]
    .map(|availability| {
        ResearchOption::new(
            TechnologyId::Mining,
            availability,
            1,
            0,
            2500,
            Vec::new(),
            Vec::new(),
            Vec::new(),
        )
    });
    assert!(recommend(&excluded, 1, RulesetDefinition::standard()).is_empty());
}

#[test]
fn matches_independent_reference_rankings_and_catalog_priorities() {
    let fixture: serde_json::Value = serde_json::from_str(include_str!(
        "../../tests/fixtures/research_recommendations_reference.json"
    ))
    .expect("reference fixture");
    let ruleset = RulesetDefinition::standard();
    for node in fixture["technologies"].as_array().expect("technologies") {
        let definition = ruleset
            .technologies()
            .iter()
            .find(|definition| definition.label() == node["id"].as_str().expect("id"))
            .expect("catalog technology");
        let (column, row) = priority::catalog_priority(definition.id());
        assert_eq!(u64::from(column), node["column"].as_u64().expect("column"));
        assert_eq!(u64::from(row), node["row"].as_u64().expect("row"));
    }
    for case in fixture["cases"].as_array().expect("cases") {
        let candidates = case["candidates"]
            .as_array()
            .expect("candidates")
            .iter()
            .map(|id| {
                let definition = ruleset
                    .technologies()
                    .iter()
                    .find(|definition| definition.label() == id.as_str().expect("id"))
                    .expect("candidate");
                let reference = fixture["technologies"]
                    .as_array()
                    .expect("catalog")
                    .iter()
                    .find(|node| node["id"] == *id)
                    .expect("reference node");
                let count = usize::try_from(reference["unlocks"].as_u64().expect("unlocks"))
                    .expect("count");
                let effects = usize::try_from(reference["effects"].as_u64().expect("effects"))
                    .expect("count");
                // Scoring consumes cardinality; payload kinds do not affect this policy.
                let unlocks = vec![ruleset.technologies()[0].unlocks()[0]; count];
                let option = ResearchOption::new(
                    definition.id(),
                    TechnologyAvailability::Available,
                    u32::try_from(reference["cost"].as_u64().expect("cost")).expect("cost range"),
                    0,
                    if case["boostMining"] == true && definition.id() == TechnologyId::Mining {
                        2500
                    } else {
                        0
                    },
                    Vec::new(),
                    Vec::new(),
                    unlocks,
                );
                score(&option, case["science"].as_i64().expect("science"), effects)
            })
            .collect::<Vec<_>>();
        let result = rank(candidates);
        let ids = result
            .iter()
            .map(|entry| {
                ruleset
                    .technology(entry.technology())
                    .expect("recommended")
                    .label()
            })
            .collect::<Vec<_>>();
        let expected = case["expected"]
            .as_array()
            .expect("expected")
            .iter()
            .map(|id| id.as_str().expect("id"))
            .collect::<Vec<_>>();
        assert_eq!(ids, expected, "reference scenario: {case}");
    }
}
