use super::{kind, query, recommendation, score};
use crate::EngineContext;
use aonw_content::{
    GridLayout, MapDefinition, ResourceType, RulesetDefinition, TerrainType, TileDefinition,
};
use aonw_domain::{HexCoord, PlayerId};
use serde::Deserialize;

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct ReferenceCase {
    terrain: TerrainType,
    river: bool,
    resources: Vec<ResourceType>,
    kind: String,
    recommendation: String,
    score: [i32; 3],
    #[serde(rename = "yield")]
    yield_value: [i64; 4],
    #[serde(rename = "canFound")]
    can_found: bool,
    tags: Vec<String>,
}

#[test]
fn assessment_matches_independent_reference_vectors() {
    let cases = reference_cases();
    assert_eq!(cases.len(), 980);
    for (index, case) in cases.iter().enumerate() {
        let score = score::score(case.terrain, case.river, &case.resources);
        assert_eq!(
            [score.city, score.defense, score.economy],
            case.score,
            "case {index}"
        );
        let kind = kind::classify(case.terrain, case.river, &case.resources, score);
        assert_eq!(format!("{kind:?}"), variant(&case.kind), "case {index}");
        let recommendation = recommendation::recommend(case.terrain, kind, score);
        assert_eq!(
            format!("{recommendation:?}"),
            variant(&case.recommendation),
            "case {index}"
        );
        assert_eq!(
            recommendation::can_found(case.terrain),
            case.can_found,
            "case {index}"
        );
        let tags = recommendation::tags(case.terrain, case.river, &case.resources, kind, score);
        assert_eq!(
            tags.iter()
                .map(|tag| format!("{tag:?}"))
                .collect::<Vec<_>>(),
            case.tags.iter().map(|tag| variant(tag)).collect::<Vec<_>>(),
            "case {index}"
        );
    }
}

#[test]
fn disclosed_base_yield_matches_independent_reference_vectors() {
    let tile = TileDefinition::try_new_for_simulation(
        HexCoord::new(0, 0),
        vec![TerrainType::Plains],
        vec![],
        0,
    )
    .expect("tile");
    let map = MapDefinition::try_new(
        "inspection",
        GridLayout::OddQFlatTop,
        1,
        1,
        vec![tile],
        vec![],
    )
    .expect("map");
    let actor = PlayerId::new("player-1").expect("player");
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    assert!(aonw_content::TerrainProfile::try_new(vec![TerrainType::River]).is_err());
    let cases = reference_cases();
    let valid = cases
        .iter()
        .filter(|case| case.terrain != TerrainType::River)
        .collect::<Vec<_>>();
    assert_eq!(valid.len(), 910);
    for (index, case) in valid.iter().enumerate() {
        let value = query::disclosed_yield(context, case.terrain, case.river, &case.resources)
            .expect("yield");
        assert_eq!(
            [value.food, value.production, value.gold, value.defense],
            case.yield_value,
            "case {index}"
        );
    }
}

fn reference_cases() -> Vec<ReferenceCase> {
    serde_json::from_str(include_str!(
        "../../../../fixtures/hex_inspection/reference_assessments.json"
    ))
    .expect("reference fixture")
}

fn variant(value: &str) -> String {
    let mut chars = value.chars();
    let first = chars.next().expect("nonempty enum").to_ascii_uppercase();
    format!("{first}{}", chars.as_str())
}
