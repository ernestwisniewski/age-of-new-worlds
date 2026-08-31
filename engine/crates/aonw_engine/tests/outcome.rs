//! Deterministic victory resolution and exact empire scoring.

use std::collections::BTreeMap;

use aonw_content::{
    GridLayout, MapDefinition, MapObjective, MapObjectiveType, RulesetDefinition, TerrainType,
    TileDefinition,
};
use aonw_domain::{
    ArtifactId, City, CityBuildingType, CityId, EconomyState, FieldImprovement,
    FieldImprovementKind, GameLengthConfig, GameMode, GameOutcomeCondition, GameState, HexCoord,
    InfrastructureState, InitialResourceDistribution, KnowledgeState, MapObjectiveHoldState,
    MatchIdentity, MatchLifecycle, MatchRules, MovementUnits, ObjectiveState, Participant,
    PlayerCountry, PlayerId, PlayerKind, PlayerResearchState, PlayerTurnState, ResearchState,
    RuleNumber, StateRevision, TechnologyId, TransportNetwork, TurnLifecycle, Unit, UnitId,
    UnitKind, VictoryRules, WonderRegistry, WorldArtifact, WorldArtifactLocation,
    WorldArtifactType,
};
use aonw_engine::{calculate_empire_scores, resolve_game_outcome};

#[path = "outcome/terminal_conditions.rs"]
mod terminal_conditions;
#[path = "outcome/victory_progress.rs"]
mod victory_progress;

#[test]
fn empire_score_uses_every_weight_and_owned_reference() {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let rules = score_rules(20);
    let identity = identity(rules, &p1, &p2);
    let objective = MapObjective::try_new(
        "central-ruins",
        MapObjectiveType::Ruins,
        HexCoord::new(0, 0),
        2,
        7,
        0,
    )
    .expect("objective");
    let map = map(vec![objective]);
    let city_id = CityId::new("city-1").expect("city id");
    let city = City::builder(city_id.clone(), p1.clone(), "Capital", HexCoord::new(0, 0))
        .with_progression(2, 0, 6, 2)
        .with_controlled_hexes([HexCoord::new(1, 0)])
        .with_buildings([CityBuildingType::Granary])
        .build()
        .expect("city");
    let infrastructure = InfrastructureState::try_new(
        [FieldImprovement::new(
            HexCoord::new(1, 0),
            FieldImprovementKind::Farm,
            Some(city_id),
        )],
        TransportNetwork::default(),
    )
    .expect("infrastructure");
    let research = ResearchState::try_new([(
        p1.clone(),
        PlayerResearchState::try_new([TechnologyId::Agriculture], None, [], 0).expect("research"),
    )])
    .expect("research state");
    let economy = EconomyState::try_new(
        &identity,
        map.bounds(),
        BTreeMap::from([(p1.clone(), 125)]),
        BTreeMap::new(),
        BTreeMap::new(),
        BTreeMap::new(),
        InitialResourceDistribution::default(),
    )
    .expect("economy");
    let objectives = ObjectiveState::try_new(
        &identity,
        BTreeMap::new(),
        BTreeMap::new(),
        [
            MapObjectiveHoldState::try_new("central-ruins".to_owned(), p1.clone(), 2)
                .expect("hold"),
        ],
    )
    .expect("objectives");
    let state = state_builder(
        &map,
        identity,
        20,
        [
            unit("unit-1", &p1, UnitKind::Warrior, 1, 12),
            unit("unit-2", &p2, UnitKind::Commander, 3, 0),
        ],
    )
    .with_cities([city])
    .with_infrastructure(infrastructure)
    .with_knowledge(KnowledgeState::new(research, WonderRegistry::default()))
    .with_economy(economy)
    .with_objectives(objectives)
    .try_build()
    .expect("scored state");

    let scores = calculate_empire_scores(&state, &map, RulesetDefinition::standard())
        .expect("empire scores");
    assert_eq!(scores.get(&p1), Some(&127));
    assert_eq!(scores.get(&p2), Some(&30));
}

#[test]
fn resolver_uses_conquest_before_later_victory_conditions() {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let rules = conquest_and_score_rules(7);
    let identity = identity(rules, &p1, &p2);
    let map = map(Vec::new());
    let state = state(
        &map,
        identity,
        7,
        [unit("unit-1", &p1, UnitKind::Commander, 0, 0)],
    );

    let outcome = resolve_game_outcome(&state, &map, RulesetDefinition::standard())
        .expect("conquest outcome");
    assert_eq!(outcome.condition(), GameOutcomeCondition::Conquest);
    assert_eq!(outcome.winner_player_id(), Some(&p1));
    assert!(outcome.score_by_player_id().is_empty());
}

#[test]
fn resolver_uses_domination_before_cultural_victory() {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let identity = identity(MatchRules::default(), &p1, &p2);
    let map = map_with_cols(8, Vec::new());
    let cities = (0..6)
        .map(|col| {
            let controlled = (col == 0).then_some(HexCoord::new(6, 0));
            City::new(
                CityId::new(format!("city-{col}")).expect("city id"),
                p1.clone(),
                HexCoord::new(col, 0),
                controlled,
            )
        })
        .collect::<Vec<_>>();
    let objectives = ObjectiveState::try_new(
        &identity,
        BTreeMap::from([(p1.clone(), 5)]),
        BTreeMap::from([(p1.clone(), 5)]),
        [],
    )
    .expect("objectives");
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
    .expect("victory state");

    let outcome = resolve_game_outcome(&state, &map, RulesetDefinition::standard())
        .expect("domination outcome");
    assert_eq!(outcome.condition(), GameOutcomeCondition::Domination);
    assert_eq!(outcome.winner_player_id(), Some(&p1));
}

#[test]
fn score_fallback_is_ongoing_before_limit_and_draws_on_exact_tie() {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let rules = score_rules(10);
    let map = map(Vec::new());
    let before = state(
        &map,
        identity(rules.clone(), &p1, &p2),
        9,
        [
            unit("unit-1", &p1, UnitKind::Commander, 0, 0),
            unit("unit-2", &p2, UnitKind::Commander, 3, 0),
        ],
    );
    assert_eq!(
        resolve_game_outcome(&before, &map, RulesetDefinition::standard())
            .expect("ongoing")
            .condition(),
        GameOutcomeCondition::Ongoing
    );

    let at_limit = state(
        &map,
        identity(rules, &p1, &p2),
        10,
        [
            unit("unit-1", &p1, UnitKind::Commander, 0, 0),
            unit("unit-2", &p2, UnitKind::Commander, 3, 0),
        ],
    );
    let outcome =
        resolve_game_outcome(&at_limit, &map, RulesetDefinition::standard()).expect("draw outcome");
    assert_eq!(outcome.condition(), GameOutcomeCondition::Draw);
    assert_eq!(outcome.winner_player_id(), None);
    assert_eq!(outcome.score_by_player_id().get(&p1), Some(&30));
    assert_eq!(outcome.score_by_player_id().get(&p2), Some(&30));
}

#[test]
fn score_fallback_selects_the_unique_highest_score() {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let rules = score_rules(10);
    let map = map(Vec::new());
    let state = state(
        &map,
        identity(rules, &p1, &p2),
        10,
        [
            unit("unit-1", &p1, UnitKind::Warrior, 0, 0),
            unit("unit-2", &p2, UnitKind::Scout, 3, 0),
        ],
    );

    let outcome =
        resolve_game_outcome(&state, &map, RulesetDefinition::standard()).expect("score outcome");
    assert_eq!(outcome.condition(), GameOutcomeCondition::Score);
    assert_eq!(outcome.winner_player_id(), Some(&p1));
    assert_eq!(outcome.score_by_player_id().get(&p1), Some(&15));
    assert_eq!(outcome.score_by_player_id().get(&p2), Some(&10));
}

fn score_rules(turn_limit: u32) -> MatchRules {
    outcome_rules(OutcomeRuleOptions {
        score_fallback: RuleToggle::Enabled,
        turn_limit: Some(turn_limit),
        ..OutcomeRuleOptions::default()
    })
}

fn conquest_and_score_rules(turn_limit: u32) -> MatchRules {
    outcome_rules(OutcomeRuleOptions {
        conquest: RuleToggle::Enabled,
        score_fallback: RuleToggle::Enabled,
        turn_limit: Some(turn_limit),
        ..OutcomeRuleOptions::default()
    })
}

#[derive(Clone, Copy)]
enum RuleToggle {
    Disabled,
    Enabled,
}

impl RuleToggle {
    const fn enabled(self) -> bool {
        matches!(self, Self::Enabled)
    }
}

#[derive(Clone, Copy)]
struct OutcomeRuleOptions<'a> {
    conquest: RuleToggle,
    domination: RuleToggle,
    domination_percent: &'a str,
    score_fallback: RuleToggle,
    turn_limit: Option<u32>,
    cultural: RuleToggle,
}

impl Default for OutcomeRuleOptions<'_> {
    fn default() -> Self {
        Self {
            conquest: RuleToggle::Disabled,
            domination: RuleToggle::Disabled,
            domination_percent: "60",
            score_fallback: RuleToggle::Disabled,
            turn_limit: None,
            cultural: RuleToggle::Disabled,
        }
    }
}

fn outcome_rules(options: OutcomeRuleOptions<'_>) -> MatchRules {
    MatchRules::new(
        GameLengthConfig::default(),
        VictoryRules::try_new(
            options.conquest.enabled(),
            options.domination.enabled(),
            RuleNumber::new(options.domination_percent).expect("percent"),
            5,
            options.score_fallback.enabled(),
            options.turn_limit,
            None,
            options.cultural.enabled(),
            6,
            5,
        )
        .expect("victory rules"),
        BTreeMap::new(),
    )
}

fn state(
    map: &MapDefinition,
    identity: MatchIdentity,
    turn: u32,
    units: impl IntoIterator<Item = Unit>,
) -> GameState {
    state_builder(map, identity, turn, units)
        .try_build()
        .expect("state")
}

fn state_builder(
    map: &MapDefinition,
    identity: MatchIdentity,
    turn: u32,
    units: impl IntoIterator<Item = Unit>,
) -> aonw_domain::GameStateBuilder {
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        identity
            .participants()
            .iter()
            .map(|participant| (participant.id().clone(), PlayerTurnState::Active))
            .collect(),
        identity
            .participants()
            .iter()
            .map(|participant| participant.id().clone()),
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle");
    GameState::builder(
        StateRevision::new(7),
        turn,
        map.bounds(),
        RulesetDefinition::standard().occupancy_policy(),
        units,
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
}

fn identity(rules: MatchRules, p1: &PlayerId, p2: &PlayerId) -> MatchIdentity {
    MatchIdentity::try_new(
        rules,
        [
            participant(p1.clone(), "One"),
            participant(p2.clone(), "Two"),
        ],
        GameMode::Multiplayer,
    )
    .expect("identity")
}

fn participant(id: PlayerId, name: &str) -> Participant {
    Participant::try_new(
        id,
        name,
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Human,
        None,
    )
    .expect("participant")
}

fn unit(id: &str, owner: &PlayerId, kind: UnitKind, col: i32, experience: u32) -> Unit {
    Unit::builder(
        UnitId::new(id).expect("unit id"),
        owner.clone(),
        kind,
        id,
        HexCoord::new(col, 0),
        MovementUnits::ZERO,
    )
    .with_experience_points(experience)
    .build()
    .expect("unit")
}

fn map(objectives: Vec<MapObjective>) -> MapDefinition {
    map_with_cols(4, objectives)
}

fn map_with_cols(cols: u16, objectives: Vec<MapObjective>) -> MapDefinition {
    MapDefinition::try_new(
        "outcome-test",
        GridLayout::OddQFlatTop,
        cols,
        1,
        (0..i32::from(cols))
            .map(|col| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(col, 0),
                    vec![TerrainType::Plains],
                    Vec::new(),
                    0,
                )
                .expect("tile")
            })
            .collect(),
        objectives,
    )
    .expect("map")
}

fn artifact_types() -> [WorldArtifactType; 6] {
    [
        WorldArtifactType::AncientImperialCrown,
        WorldArtifactType::AstronomersTablets,
        WorldArtifactType::ProphetMask,
        WorldArtifactType::HeroSword,
        WorldArtifactType::MerchantsSeal,
        WorldArtifactType::FirstPeoplesChronicle,
    ]
}

fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player id")
}
