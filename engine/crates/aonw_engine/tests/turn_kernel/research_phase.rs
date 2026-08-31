use aonw_content::RulesetDefinition;
use aonw_domain::{
    CityProductionTarget, CityProjectType, GameMode, PlayerResearchState, TechnologyId,
    UnitOccupancyPolicy, WonderType,
};
use aonw_engine::{
    DomainEvent, EngineContext, GameEngine, PlayerCommand, ProcessorRequirement, TurnCommand,
    TurnProcessor,
};

use super::production_phase::{
    city, production_state, production_state_with_research, wonder_cost,
};
use super::{map, player};

#[test]
fn research_project_contributes_to_the_supported_research_processor() {
    let ruleset = RulesetDefinition::standard();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let map = map();
    let state = production_state(
        GameMode::HotSeat,
        [],
        [city(
            "city-2",
            &p2,
            1,
            CityProductionTarget::Project(CityProjectType::Research),
            0,
        )],
        UnitOccupancyPolicy::Exclusive,
    );
    assert_eq!(
        TurnProcessor::Research.requirement(&state, &map, std::slice::from_ref(&p2)),
        ProcessorRequirement::RequiredAndSupported
    );
    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&p1, &map, ruleset),
        PlayerCommand::EndTurn(TurnCommand::new(7, &p1)),
    )
    .expect("research project turn");
    assert!(transition.is_accepted());
    let DomainEvent::ResearchPointsGained(event) = &transition.events()[0] else {
        panic!("research points must precede lifecycle completion")
    };
    assert_eq!(event.player_id(), &p2);
    assert_eq!(event.points(), 3);
    assert!(matches!(transition.events()[1], DomainEvent::TurnEnded(_)));
}

#[test]
fn research_project_completes_active_technology_with_ordered_events() {
    let ruleset = RulesetDefinition::standard();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let state = production_state_with_research(
        GameMode::HotSeat,
        [],
        [city(
            "city-2",
            &p2,
            1,
            CityProductionTarget::Project(CityProjectType::Research),
            0,
        )],
        UnitOccupancyPolicy::Exclusive,
        &p2,
        PlayerResearchState::try_new(
            [],
            Some(TechnologyId::Agriculture),
            [(TechnologyId::Agriculture, 3)],
            0,
        )
        .expect("research"),
    );
    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&p1, &map(), ruleset),
        PlayerCommand::EndTurn(TurnCommand::new(7, &p1)),
    )
    .expect("research completion turn");
    assert!(matches!(
        transition.events(),
        [
            DomainEvent::ResearchPointsGained(_),
            DomainEvent::TechnologyResearched(_),
            DomainEvent::TurnEnded(_)
        ]
    ));
    let research = transition
        .state()
        .research()
        .players()
        .get(&p2)
        .expect("updated research");
    assert!(
        research
            .unlocked_technology_ids()
            .contains(&TechnologyId::Agriculture)
    );
    assert_eq!(research.active_technology_id(), None);
    assert_eq!(research.science_overflow(), 0);
}

#[test]
fn great_library_unlock_precedes_same_turn_science_and_replays_as_events() {
    let ruleset = RulesetDefinition::standard();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let state = production_state_with_research(
        GameMode::HotSeat,
        [],
        [city(
            "city-2",
            &p2,
            1,
            CityProductionTarget::Wonder(WonderType::GreatLibrary),
            wonder_cost(ruleset, WonderType::GreatLibrary),
        )],
        UnitOccupancyPolicy::Exclusive,
        &p2,
        PlayerResearchState::try_new([], Some(TechnologyId::Agriculture), [], 0).expect("research"),
    );
    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&p1, &map(), ruleset),
        PlayerCommand::EndTurn(TurnCommand::new(7, &p1)),
    )
    .expect("great library turn");
    assert!(matches!(
        transition.events(),
        [
            DomainEvent::CityBuiltWonder(_),
            DomainEvent::TechnologyResearched(_),
            DomainEvent::ResearchPointsGained(_),
            DomainEvent::TurnEnded(_)
        ]
    ));
    let DomainEvent::ResearchPointsGained(points) = &transition.events()[2] else {
        panic!("science event")
    };
    assert_eq!(points.points(), 3);
    let research = transition
        .state()
        .research()
        .players()
        .get(&p2)
        .expect("research");
    assert!(
        research
            .unlocked_technology_ids()
            .contains(&TechnologyId::Agriculture)
    );
}
