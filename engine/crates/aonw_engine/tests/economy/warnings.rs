use aonw_engine::strategic_resource_shortages;

use super::*;

#[test]
fn stockpile_warnings_use_only_the_recipients_unlocked_production() {
    let map = economy_map();
    let first = player("player-1");
    let second = player("player-2");
    let research = ResearchState::try_new([(
        second.clone(),
        PlayerResearchState::try_new(
            [TechnologyId::Combustion, TechnologyId::Flight],
            None,
            [],
            0,
        )
        .unwrap(),
    )])
    .unwrap();
    let state = state_with_resource_parts(
        &map,
        vec![
            unit("unit-1", &first, UnitKind::Commander, HexCoord::new(0, 0)),
            unit("unit-2", &second, UnitKind::Commander, HexCoord::new(2, 0)),
        ],
        Vec::new(),
        InteractionState::default(),
        InfrastructureState::default(),
        Vec::new(),
        InitialResourceDistribution::default(),
        research,
    );
    let rules = RulesetDefinition::standard();
    assert_eq!(
        strategic_resource_shortages(&state, EngineContext::canonical(&first, &map, rules)).count(),
        0
    );
    assert_eq!(
        strategic_resource_shortages(&state, EngineContext::canonical(&second, &map, rules))
            .collect::<Vec<_>>(),
        [ResourceType::Oil, ResourceType::Aluminium]
    );
}
