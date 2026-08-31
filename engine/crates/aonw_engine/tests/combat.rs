//! Canonical combat command and preview acceptance tests.

#[path = "combat/integrated_turn.rs"]
mod integrated_turn;
#[path = "combat/manifest.rs"]
mod manifest;
#[path = "combat/mechanics.rs"]
mod mechanics;
#[path = "combat/rejections.rs"]
mod rejections;
#[path = "combat/support.rs"]
mod support;

use std::collections::BTreeMap;

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    City, CityConquestAction, CityId, CombatState, Diplomacy, DiplomaticRelationStatus, FogOfWar,
    GameMode, GameState, HexCoord, IntendedAttack, MatchIdentity, MatchLifecycle, MatchRules,
    MovementUnits, Participant, PlayerCountry, PlayerId, PlayerKind, PlayerPair, PlayerTurnState,
    StateRevision, TurnLifecycle, Unit, UnitId, UnitKind, UnitOccupancyPolicy,
};
use aonw_engine::{
    AttackHexCommand, CombatPreviewQuery, CombatTarget, CommandRejectionCode, DomainEvent,
    EngineContext, ExecutionEvidence, GameEngine, GameQuery, PlayerCommand, QueryResult,
    TurnCommand,
};
use support::actor_fog;

#[test]
fn preview_and_attack_share_the_exact_combat_input() {
    let map = map();
    let actor = player("player_1");
    let defender_owner = player("player_2");
    let attacker_id = unit_id("attacker");
    let defender_id = unit_id("defender");
    let state = state(
        vec![
            unit(
                "attacker",
                &actor,
                UnitKind::Warrior,
                HexCoord::new(0, 0),
                None,
            ),
            unit(
                "defender",
                &defender_owner,
                UnitKind::Settler,
                HexCoord::new(1, 0),
                None,
            ),
        ],
        Vec::new(),
        FogOfWar::default(),
        Diplomacy::default(),
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());

    let QueryResult::CombatPreview(preview) = GameEngine::query(
        &state,
        context,
        GameQuery::CombatPreview(CombatPreviewQuery::new(
            11,
            &attacker_id,
            HexCoord::new(1, 0),
        )),
    )
    .expect("combat preview") else {
        panic!("combat preview result")
    };
    assert_eq!(preview.target, CombatTarget::Unit(defender_id.clone()));
    assert_eq!(preview.outgoing_damage, (1, 5));
    assert_eq!(preview.retaliation_damage, None);

    let transition = GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::AttackHex(AttackHexCommand::new(11, &attacker_id, HexCoord::new(1, 0))),
    )
    .expect("attack");
    assert!(transition.is_accepted());
    assert_eq!(transition.state().revision(), StateRevision::new(12));
    assert!(transition.state().unit(&defender_id).is_none());
    let attacker = transition.state().unit(&attacker_id).expect("attacker");
    assert_eq!(attacker.movement_units(), MovementUnits::ZERO);
    assert_eq!(attacker.experience_points(), 3);
    assert!(matches!(
        transition.events(),
        [
            DomainEvent::UnitAttacked(_),
            DomainEvent::CombatResolved(_),
            DomainEvent::UnitGainedExperience(_),
            DomainEvent::UnitKilled(_),
        ]
    ));
    let Some(ExecutionEvidence::Combat(execution)) = transition.evidence() else {
        panic!("combat evidence")
    };
    assert_eq!(execution.seed, 2_280_806_018);
    assert_eq!(execution.rolls.len(), 1);
    assert_eq!(execution.rolls[0].value, 0);
    assert_eq!(execution.preview, preview);
    assert_eq!(execution.outcome.outgoing_damage, 3);
    assert_eq!(execution.outcome.defender_hit_points, -2);

    let diplomacy = transition.state().diplomacy();
    assert_eq!(diplomacy.relations().len(), 1);
    assert_eq!(
        diplomacy.relations()[0].status(),
        DiplomaticRelationStatus::Hostile
    );
    assert_eq!(diplomacy.relations()[0].relation_score(), -10);
    assert_eq!(diplomacy.score_history().len(), 1);
    assert_eq!(diplomacy.score_history()[0].delta(), -10);
    assert_eq!(diplomacy.score_history()[0].source_id(), None);
}

#[test]
fn hidden_target_rejection_does_not_disclose_target_or_mutate_state() {
    let map = map();
    let actor = player("player_1");
    let defender_owner = player("player_2");
    let attacker_id = unit_id("attacker");
    let state = state(
        vec![
            unit(
                "attacker",
                &actor,
                UnitKind::Warrior,
                HexCoord::new(0, 0),
                None,
            ),
            unit(
                "hidden-defender",
                &defender_owner,
                UnitKind::Warrior,
                HexCoord::new(1, 0),
                None,
            ),
        ],
        Vec::new(),
        actor_fog(&actor, [HexCoord::new(0, 0)], [HexCoord::new(0, 0)]),
        Diplomacy::default(),
    );
    let original_digest = GameEngine::state_digest(&state);
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());

    let query_error = GameEngine::query(
        &state,
        context,
        GameQuery::CombatPreview(CombatPreviewQuery::new(
            11,
            &attacker_id,
            HexCoord::new(1, 0),
        )),
    )
    .expect_err("hidden preview");
    assert_eq!(query_error.code(), "attack_target_not_visible");

    let transition = GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::AttackHex(AttackHexCommand::new(11, &attacker_id, HexCoord::new(1, 0))),
    )
    .expect("hidden attack rejection");
    assert_eq!(
        transition.rejection().expect("rejection").code(),
        CommandRejectionCode::AttackTargetNotVisible
    );
    assert!(transition.events().is_empty());
    assert!(transition.evidence().is_none());
    assert_eq!(
        GameEngine::state_digest(transition.state()),
        original_digest
    );
}

#[test]
fn city_capture_and_destroy_are_explicit_and_city_attack_penalizes_observers() {
    let map = map();
    let actor = player("player_1");
    let defender_owner = player("player_2");
    let observer = player("player_3");
    let attacker_id = unit_id("tank");
    let city_id = city_id("city");
    let identity = identity();
    let diplomacy = Diplomacy::try_new(
        &identity,
        [
            PlayerPair::new(actor.clone(), defender_owner.clone()).expect("pair"),
            PlayerPair::new(actor.clone(), observer.clone()).expect("pair"),
            PlayerPair::new(defender_owner.clone(), observer).expect("pair"),
        ],
        [],
        [],
        [],
        [],
        [],
    )
    .expect("diplomacy");
    let base_state = state_with_identity(
        identity,
        vec![unit(
            "tank",
            &actor,
            UnitKind::Tank,
            HexCoord::new(0, 0),
            None,
        )],
        vec![city("city", &defender_owner, HexCoord::new(1, 0), Some(1))],
        FogOfWar::default(),
        diplomacy,
        CombatState::default(),
    );
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());

    let captured = GameEngine::apply_player_owned(
        base_state.clone(),
        context,
        PlayerCommand::AttackHex(
            AttackHexCommand::new(11, &attacker_id, HexCoord::new(1, 0))
                .with_city_conquest_action(CityConquestAction::Capture),
        ),
    )
    .expect("capture");
    assert!(captured.is_accepted());
    assert!(matches!(
        captured.events().first(),
        Some(DomainEvent::CityAttacked(_))
    ));
    assert!(matches!(
        captured.events().get(2),
        Some(DomainEvent::DiplomaticScoreChanged(_))
    ));
    let city = captured.state().city(&city_id).expect("captured city");
    assert_eq!(city.owner_player_id(), &actor);
    assert_eq!(city.hit_points(), Some(8));
    assert!(matches!(
        captured.events().last(),
        Some(DomainEvent::CityCaptured(_))
    ));
    let relations = captured.state().diplomacy().relations();
    assert!(relations.iter().any(|relation| {
        relation.pair() == &PlayerPair::new(actor.clone(), defender_owner.clone()).expect("pair")
            && relation.status() == DiplomaticRelationStatus::War
            && relation.relation_score() == -30
    }));
    assert!(relations.iter().any(|relation| {
        relation.pair() == &PlayerPair::new(actor.clone(), player("player_3")).expect("pair")
            && relation.relation_score() == -12
    }));

    let destroyed = GameEngine::apply_player_owned(
        base_state,
        context,
        PlayerCommand::AttackHex(
            AttackHexCommand::new(11, &attacker_id, HexCoord::new(1, 0))
                .with_city_conquest_action(CityConquestAction::Destroy),
        ),
    )
    .expect("destroy");
    assert!(destroyed.state().city(&city_id).is_none());
    assert!(matches!(
        destroyed.events().first(),
        Some(DomainEvent::CityAttacked(_))
    ));
    assert!(matches!(
        destroyed.events().last(),
        Some(DomainEvent::CityDestroyed(_))
    ));
}

#[test]
fn simultaneous_turn_resolves_intended_attacks_through_the_same_combat_evidence() {
    let map = map();
    let actor = player("player_1");
    let defender_owner = player("player_2");
    let third = player("player_3");
    let attacker_id = unit_id("attacker");
    let defender_id = unit_id("defender");
    let intended = CombatState::try_new([IntendedAttack::new(
        attacker_id.clone(),
        HexCoord::new(1, 0),
        StateRevision::new(11),
        actor.clone(),
        CityConquestAction::Capture,
    )])
    .expect("intended attack");
    let mut current = integrated_turn::state(&actor, &defender_owner, &third, intended);
    for (revision, submitting) in [(11, &actor), (12, &defender_owner)] {
        current = GameEngine::apply_player_owned(
            current,
            EngineContext::canonical(submitting, &map, RulesetDefinition::standard()),
            PlayerCommand::SubmitTurn(TurnCommand::new(revision, submitting)),
        )
        .expect("partial submit")
        .into_parts()
        .state;
    }
    let transition = GameEngine::apply_player_owned(
        current,
        EngineContext::canonical(&third, &map, RulesetDefinition::standard()),
        PlayerCommand::SubmitTurn(TurnCommand::new(13, &third)),
    )
    .expect("final submit");

    assert!(transition.is_accepted());
    assert!(transition.state().combat().intended_attacks().is_empty());
    assert!(transition.state().unit(&defender_id).is_none());
    assert!(
        transition
            .state()
            .city(&city_id("city_player_3_3_2"))
            .is_some()
    );
    assert!(
        transition
            .state()
            .transport_network()
            .at(HexCoord::new(0, 2))
            .is_some()
    );
    assert!(matches!(
        transition.events(),
        [
            DomainEvent::AllPlayersSubmitted(_),
            DomainEvent::UnitAttacked(_),
            DomainEvent::CombatResolved(_),
            DomainEvent::UnitGainedExperience(_),
            DomainEvent::UnitKilled(_),
            DomainEvent::CityFounded(_),
            DomainEvent::WorkerCompletedJob(_),
            DomainEvent::UnitMoved(_),
            DomainEvent::ResearchPointsGained(_),
            DomainEvent::TurnEnded(_),
            DomainEvent::TurnEnded(_),
            DomainEvent::TurnEnded(_),
        ]
    ));
    let Some(ExecutionEvidence::TurnKernel(evidence)) = transition.evidence() else {
        panic!("turn evidence")
    };
    assert_eq!(evidence.combat_executions().len(), 1);
    assert_eq!(evidence.founded_city_ids().len(), 1);
    assert_eq!(evidence.movement_executions().len(), 1);
    assert_eq!(evidence.combat_executions()[0].seed, 2_280_806_018);
    assert_eq!(evidence.combat_executions()[0].rolls[0].value, 0);
}

fn state(units: Vec<Unit>, cities: Vec<City>, fog: FogOfWar, diplomacy: Diplomacy) -> GameState {
    state_with_identity(
        identity(),
        units,
        cities,
        fog,
        diplomacy,
        CombatState::default(),
    )
}

fn state_with_identity(
    identity: MatchIdentity,
    units: Vec<Unit>,
    cities: Vec<City>,
    fog: FogOfWar,
    diplomacy: Diplomacy,
    combat: CombatState,
) -> GameState {
    let players = identity
        .participants()
        .iter()
        .map(|participant| participant.id().clone())
        .collect::<Vec<_>>();
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        players
            .iter()
            .cloned()
            .map(|id| (id, PlayerTurnState::Active))
            .collect::<BTreeMap<_, _>>(),
        players,
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("turn lifecycle");
    GameState::builder(
        StateRevision::new(11),
        7,
        map().bounds(),
        UnitOccupancyPolicy::Exclusive,
        units,
    )
    .with_cities(cities)
    .with_fog_of_war(fog)
    .with_diplomacy(diplomacy)
    .with_combat(combat)
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state")
}

fn identity() -> MatchIdentity {
    MatchIdentity::try_new(
        MatchRules::default(),
        [
            participant("player_1", 0xff00_0001),
            participant("player_2", 0xff00_0002),
            participant("player_3", 0xff00_0003),
        ],
        GameMode::Multiplayer,
    )
    .expect("identity")
}

fn participant(id: &str, color: u32) -> Participant {
    Participant::try_new(
        player(id),
        id,
        color,
        PlayerCountry::Poland,
        PlayerKind::Human,
        None,
    )
    .expect("participant")
}

fn map() -> MapDefinition {
    let tiles = (0..3)
        .flat_map(|row| {
            (0..4).map(move |col| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(col, row),
                    vec![TerrainType::Plains],
                    Vec::new(),
                    0,
                )
                .expect("tile")
            })
        })
        .collect();
    MapDefinition::try_new("combat", GridLayout::OddQFlatTop, 4, 3, tiles, Vec::new()).expect("map")
}

fn unit(
    id: &str,
    owner: &PlayerId,
    kind: UnitKind,
    position: HexCoord,
    hit_points: Option<u32>,
) -> Unit {
    Unit::builder(
        unit_id(id),
        owner.clone(),
        kind,
        id,
        position,
        MovementUnits::new(100),
    )
    .with_hit_points(hit_points)
    .build()
    .expect("unit")
}

fn city(id: &str, owner: &PlayerId, center: HexCoord, hit_points: Option<i64>) -> City {
    City::builder(city_id(id), owner.clone(), id, center)
        .with_hit_points(hit_points)
        .build()
        .expect("city")
}

fn unit_id(id: &str) -> UnitId {
    UnitId::new(id).expect("unit id")
}

fn city_id(id: &str) -> CityId {
    CityId::new(id).expect("city id")
}

fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player id")
}
