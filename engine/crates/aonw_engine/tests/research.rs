//! Research options and selection-command tests.

use std::collections::BTreeMap;

use aonw_content::{
    GridLayout, MapDefinition, ResourceType as ContentResource, RulesetDefinition, TerrainType,
    TileDefinition,
};
use aonw_domain::{
    ArtifactId, City, CityBuildingType, CityId, CitySpecializationType, FieldImprovement,
    FieldImprovementKind, GameLengthConfig, GameLengthKind, GameMode, GameState, HexCoord,
    InfrastructureState, InteractionState, KnowledgeState, MatchIdentity, MatchLifecycle,
    MatchRules, PaceProfile, Participant, PendingInteraction, PlayerCountry, PlayerId, PlayerKind,
    PlayerResearchState, PlayerTurnState, ResearchState, StateRevision, TechnologyId,
    TransportNetwork, TurnLifecycle, UnitOccupancyPolicy, VictoryRules, WonderRegistry, WonderType,
    WorldArtifact, WorldArtifactLocation, WorldArtifactType,
};
use aonw_engine::{
    CanonicalQueryError, CommandRejectionCode, EngineContext, GameEngine, GameQuery, PlayerCommand,
    QueryResult, ResearchError, ResearchOptionsQuery, SelectTechnologyCommand,
    TechnologyAvailability,
};

const SCIENCE_BUILDINGS: [CityBuildingType; 3] = [
    CityBuildingType::Archive,
    CityBuildingType::Academy,
    CityBuildingType::University,
];

#[test]
fn options_own_availability_cost_progress_prerequisites_and_boosts() {
    let (map, state, actor) = fixture();
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let QueryResult::ResearchOptions(options) = GameEngine::query(
        &state,
        context,
        GameQuery::ResearchOptions(ResearchOptionsQuery::new(9)),
    )
    .expect("research options") else {
        panic!("research options result")
    };
    assert_eq!(options.player_id(), &actor);
    assert_eq!(options.active_technology(), None);
    assert_eq!(options.science_overflow(), 10);
    assert_eq!(options.science_yield().total(), 12);
    assert_eq!(options.science_yield().sources().len(), 3);
    assert_eq!(
        options.science_yield().sources()[0].kind(),
        aonw_engine::ScienceYieldSourceKind::CityScience
    );
    assert_eq!(options.science_yield().sources()[0].amount(), 10);
    assert_eq!(
        options.science_yield().sources()[1].kind(),
        aonw_engine::ScienceYieldSourceKind::WorldArtifact
    );
    assert_eq!(
        options.science_yield().sources()[2].kind(),
        aonw_engine::ScienceYieldSourceKind::WorldWonder
    );
    assert_eq!(options.options().len(), 54);

    let agriculture = option(&options, TechnologyId::Agriculture);
    assert_eq!(agriculture.availability(), TechnologyAvailability::Unlocked);
    assert_eq!(agriculture.boost_discount_basis_points(), 2_500);

    let storage = option(&options, TechnologyId::Storage);
    assert_eq!(storage.availability(), TechnologyAvailability::Available);
    assert_eq!(storage.effective_cost(), 8);
    assert_eq!(storage.progress(), 1);
    assert_eq!(storage.boost_discount_basis_points(), 2_500);
    assert_eq!(storage.prerequisites(), [TechnologyId::Agriculture]);
    assert!(!storage.unlocks().is_empty());

    let writing = option(&options, TechnologyId::Education);
    assert_eq!(
        writing.availability(),
        TechnologyAvailability::LockedByPrerequisites
    );
}

#[test]
fn selection_applies_capped_overflow_clears_owned_pending_and_is_revision_bound() {
    let (map, state, actor) = fixture();
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let selected = GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::SelectTechnology(SelectTechnologyCommand::new(9, TechnologyId::Storage)),
    )
    .expect("selection");
    assert!(selected.is_accepted());
    assert_eq!(selected.revision().get(), 10);
    assert!(selected.events().is_empty());
    assert_eq!(selected.state().interaction().pending(), None);
    let research = selected
        .state()
        .research()
        .players()
        .get(&actor)
        .expect("actor research");
    assert_eq!(research.active_technology_id(), Some(TechnologyId::Storage));
    assert_eq!(
        research
            .progress_by_technology_id()
            .get(&TechnologyId::Storage),
        Some(&5)
    );
    assert_eq!(research.science_overflow(), 0);

    let repeated = GameEngine::apply_player_owned(
        selected.state().clone(),
        context,
        PlayerCommand::SelectTechnology(SelectTechnologyCommand::new(10, TechnologyId::Storage)),
    )
    .expect("repeat rejection");
    assert_eq!(
        repeated.rejection().expect("rejection").code(),
        CommandRejectionCode::TechnologyNotAvailable
    );
    assert_eq!(repeated.state(), selected.state());
}

#[test]
fn stale_revision_precedes_unavailable_technology_rejections() {
    let (map, state, actor) = fixture();
    let outsider = PlayerId::new("outsider").expect("outsider");
    let outsider_context = EngineContext::canonical(&outsider, &map, RulesetDefinition::standard());
    let stale_transition = GameEngine::apply_player_owned(
        state.clone(),
        outsider_context,
        PlayerCommand::SelectTechnology(SelectTechnologyCommand::new(8, TechnologyId::Education)),
    )
    .expect("stale rejection");
    assert_eq!(
        stale_transition.rejection().expect("rejection").code(),
        CommandRejectionCode::StaleRevision
    );
    let unavailable_for_new_participant = GameEngine::apply_player_owned(
        state.clone(),
        outsider_context,
        PlayerCommand::SelectTechnology(SelectTechnologyCommand::new(9, TechnologyId::Education)),
    )
    .expect("unavailable technology rejection");
    assert_eq!(
        unavailable_for_new_participant
            .rejection()
            .expect("rejection")
            .code(),
        CommandRejectionCode::TechnologyNotAvailable
    );

    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let locked = GameEngine::apply_player_owned(
        state.clone(),
        context,
        PlayerCommand::SelectTechnology(SelectTechnologyCommand::new(9, TechnologyId::Education)),
    )
    .expect("locked rejection");
    assert_eq!(
        locked.rejection().expect("rejection").code(),
        CommandRejectionCode::TechnologyNotAvailable
    );
    assert_eq!(locked.state(), &state);

    assert_eq!(
        GameEngine::query(
            &state,
            context,
            GameQuery::ResearchOptions(ResearchOptionsQuery::new(8)),
        ),
        Err(CanonicalQueryError::Research(ResearchError::Rejected(
            CommandRejectionCode::StaleRevision
        )))
    );
}

fn option(
    options: &aonw_engine::ResearchOptions,
    technology: TechnologyId,
) -> &aonw_engine::ResearchOption {
    options
        .options()
        .iter()
        .find(|option| option.technology() == technology)
        .expect("technology option")
}

fn fixture() -> (MapDefinition, GameState, PlayerId) {
    let map = map();
    let actor = PlayerId::new("player-1").expect("actor");
    let outsider = PlayerId::new("outsider").expect("outsider");
    let city_id = CityId::new("capital").expect("city");
    let farm_a = HexCoord::new(2, 1);
    let farm_b = HexCoord::new(1, 2);
    let city = City::builder(
        city_id.clone(),
        actor.clone(),
        "Capital",
        HexCoord::new(2, 2),
    )
    .with_controlled_hexes([farm_a, farm_b])
    .with_buildings(SCIENCE_BUILDINGS)
    .with_wonders([WonderType::GreatLibrary])
    .with_planning(Some(CitySpecializationType::Science), None)
    .build()
    .expect("city");
    let infrastructure = InfrastructureState::try_new(
        [
            FieldImprovement::new(farm_a, FieldImprovementKind::Farm, Some(city_id.clone())),
            FieldImprovement::new(farm_b, FieldImprovementKind::Farm, Some(city_id.clone())),
        ],
        TransportNetwork::default(),
    )
    .expect("infrastructure");
    let match_lifecycle = active_match(&actor, &outsider);
    let research = ResearchState::try_new([(
        actor.clone(),
        PlayerResearchState::try_new(
            [TechnologyId::Agriculture],
            None,
            [(TechnologyId::Storage, 1)],
            10,
        )
        .expect("research"),
    )])
    .expect("research state");
    let interaction = InteractionState::new(
        None,
        Some(PendingInteraction::ResearchSelection {
            owner_player_id: actor.clone(),
        }),
    );
    let state = GameState::builder(
        StateRevision::new(9),
        4,
        map.bounds(),
        UnitOccupancyPolicy::Exclusive,
        [],
    )
    .with_cities([city])
    .with_artifacts([WorldArtifact::new(
        ArtifactId::new("tablets").expect("artifact"),
        WorldArtifactType::AstronomersTablets,
        WorldArtifactLocation::Stored(city_id),
    )])
    .with_infrastructure(infrastructure)
    .with_knowledge(KnowledgeState::new(
        research,
        WonderRegistry::try_new([(WonderType::GreatLibrary, actor.clone())])
            .expect("wonder registry"),
    ))
    .with_interaction(interaction)
    .with_match_lifecycle(match_lifecycle)
    .try_build()
    .expect("state");
    (map, state, actor)
}

fn active_match(actor: &PlayerId, outsider: &PlayerId) -> MatchLifecycle {
    let participants = [
        Participant::try_new(
            actor.clone(),
            "Player",
            0xff00_0000,
            PlayerCountry::Poland,
            PlayerKind::Human,
            None,
        )
        .expect("participant"),
        Participant::try_new(
            outsider.clone(),
            "Outsider",
            0xff00_0001,
            PlayerCountry::France,
            PlayerKind::Human,
            None,
        )
        .expect("participant"),
    ];
    let game_length = GameLengthConfig::try_new(
        GameLengthKind::TargetMinutes,
        Some(60),
        None,
        PaceProfile::Standard60,
        false,
    )
    .expect("game length");
    let rules = MatchRules::new(game_length, VictoryRules::default(), BTreeMap::new());
    let identity =
        MatchIdentity::try_new(rules, participants, GameMode::Multiplayer).expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (actor.clone(), PlayerTurnState::Active),
            (outsider.clone(), PlayerTurnState::Active),
        ]),
        [actor.clone(), outsider.clone()],
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle");
    MatchLifecycle::new(identity, lifecycle)
}

fn map() -> MapDefinition {
    MapDefinition::try_new(
        "research-test",
        GridLayout::OddQFlatTop,
        5,
        5,
        (0..5)
            .flat_map(|row| {
                (0..5).map(move |col| {
                    let resources = if (col, row) == (2, 2) {
                        vec![ContentResource::Wheat]
                    } else {
                        Vec::new()
                    };
                    TileDefinition::try_new_for_simulation(
                        HexCoord::new(col, row),
                        vec![TerrainType::Plains],
                        resources,
                        0,
                    )
                    .expect("tile")
                })
            })
            .collect(),
        Vec::new(),
    )
    .expect("map")
}
