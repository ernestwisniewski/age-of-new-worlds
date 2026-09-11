use aonw_content::RulesetDefinition;
use aonw_domain::{GameState, PlayerId, PlayerResearchState, ResearchStateUpdate, TechnologyId};
use aonw_engine::{
    EngineContext, GameEngine, GameQuery, QueryResult, ResearchOptions, ResearchOptionsQuery,
    TechnologyAvailability,
};

use super::fixture;

#[test]
fn recommendations_use_only_the_recipients_research_and_do_not_mutate_state() {
    let (map, state, actor) = fixture();
    let before = state.clone();
    let query = |state: &GameState| -> ResearchOptions {
        let QueryResult::ResearchOptions(options) = GameEngine::query(
            state,
            EngineContext::canonical(&actor, &map, RulesetDefinition::standard()),
            GameQuery::ResearchOptions(ResearchOptionsQuery::new(9)),
        )
        .expect("options") else {
            panic!("research options");
        };
        options
    };
    let expected = query(&state);
    assert_eq!(state, before);
    assert_eq!(expected.recommendations().len(), 3);
    for recommendation in expected.recommendations() {
        let option = super::option(&expected, recommendation.technology());
        assert_eq!(option.availability(), TechnologyAvailability::Available);
    }
    let outsider = PlayerId::new("outsider").expect("outsider");
    let foreign = PlayerResearchState::try_new(
        [TechnologyId::Agriculture, TechnologyId::Mining],
        Some(TechnologyId::Storage),
        [(TechnologyId::Storage, 100)],
        1000,
    )
    .expect("foreign research");
    let research = state
        .knowledge()
        .research()
        .updating_player(outsider, foreign);
    let altered = state
        .clone()
        .into_after_research(ResearchStateUpdate {
            revision: state.revision(),
            knowledge: state.knowledge().with_research(research),
            interaction: state.interaction().clone(),
        })
        .expect("altered private state");
    assert_eq!(query(&altered), expected);
}
