//! Focused policy-family coverage for current recipient-safe decisions.

use std::collections::BTreeMap;

use aonw_ai::{PlannedCommandFamily, StrategicPlanner, StrategicPlanningOutcome};
use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    ArtifactId, City, CityBuildingType, CityId, CityProductionQueue, CityProductionTarget,
    Diplomacy, DiplomaticMessage, DiplomaticMessageCategory, DiplomaticMessageTopic,
    DiplomaticProposal, DiplomaticProposalKind, FieldImprovementKind, FogOfWar, GameLengthConfig,
    GameMode, GameOutcome, GameOutcomeCondition, GameState, HexCoord, InteractionState,
    KnowledgeState, MatchIdentity, MatchLifecycle, MatchRules, MovementUnits, Participant,
    PendingInteraction, PlayerCountry, PlayerFog, PlayerId, PlayerKind, PlayerPair,
    PlayerResearchState, PlayerTurnState, ResearchState, StateRevision, StrategicResourceStockpile,
    TechnologyId, TurnLifecycle, Unit, UnitId, UnitKind, VictoryRules, WonderRegistry,
    WorldArtifact, WorldArtifactLocation, WorldArtifactType,
};
use aonw_local_runtime::{LocalRuntime, OpenSession};

#[path = "strategic_policy_families/lifecycle.rs"]
mod lifecycle;
#[path = "strategic_policy_families/pending.rs"]
mod pending;
#[path = "strategic_policy_families/profiles.rs"]
mod profiles;

#[test]
fn policy_accepts_an_incoming_diplomatic_proposal_first() {
    let world = World::new("ai-policy-diplomacy", 4, 4);
    let proposal = DiplomaticProposal::try_new(
        "proposal-1".to_owned(),
        world.foreign.clone(),
        world.actor.clone(),
        DiplomaticProposalKind::Friendship,
        4,
        8,
        0,
    )
    .expect("proposal");
    let contact = PlayerPair::new(world.actor.clone(), world.foreign.clone()).expect("contact");
    let diplomacy = Diplomacy::try_new(&world.identity, [contact], [], [proposal], [], [], [])
        .expect("diplomacy");
    let state = world
        .state([], [])
        .with_diplomacy(diplomacy)
        .try_build()
        .expect("state");
    assert_family_executes(world, state, PlannedCommandFamily::Diplomacy);
}

#[test]
fn policy_answers_an_unresolved_diplomatic_message() {
    let world = World::new("ai-policy-message", 4, 4);
    let message = DiplomaticMessage::try_new(
        "message-1".to_owned(),
        world.foreign.clone(),
        world.actor.clone(),
        DiplomaticMessageTopic::WithdrawScouts,
        DiplomaticMessageCategory::Request,
        4,
        8,
        None,
        None,
        0,
        None,
        None,
        false,
    )
    .expect("message");
    let contact = PlayerPair::new(world.actor.clone(), world.foreign.clone()).expect("contact");
    let diplomacy = Diplomacy::try_new(&world.identity, [contact], [], [], [message], [], [])
        .expect("diplomacy");
    let state = world
        .state([], [])
        .with_diplomacy(diplomacy)
        .try_build()
        .expect("state");
    assert_family_executes(world, state, PlannedCommandFamily::Diplomacy);
}

#[test]
fn policy_starts_visible_artifact_excavation() {
    let world = World::new("ai-policy-artifact", 4, 1);
    let coordinate = HexCoord::new(0, 0);
    let unit = unit("excavator", &world.actor, UnitKind::Scout, coordinate);
    let artifact = WorldArtifact::new(
        ArtifactId::new("artifact-1").expect("artifact id"),
        WorldArtifactType::HeroSword,
        WorldArtifactLocation::Map(coordinate),
    );
    let fog = actor_fog(&world, [], [coordinate]);
    let state = world
        .state([unit], [])
        .with_artifacts([artifact])
        .with_fog_of_war(fog)
        .try_build()
        .expect("state");
    assert_family_executes(world, state, PlannedCommandFamily::Artifact);
}

#[test]
fn policy_stores_a_carried_artifact_in_the_city_under_the_unit() {
    let world = World::new("ai-policy-artifact-store", 3, 1);
    let coordinate = HexCoord::new(0, 0);
    let artifact_id = ArtifactId::new("artifact-1").expect("artifact id");
    let carrier = Unit::builder(
        UnitId::new("carrier").expect("unit id"),
        world.actor.clone(),
        UnitKind::Scout,
        "carrier",
        coordinate,
        MovementUnits::new(10),
    )
    .with_carried_artifact(Some(artifact_id.clone()))
    .build()
    .expect("carrier");
    let artifact = WorldArtifact::new(
        artifact_id,
        WorldArtifactType::HeroSword,
        WorldArtifactLocation::Carried(carrier.id().clone()),
    );
    let state = world
        .state([carrier], [city("capital", &world.actor, coordinate)])
        .with_artifacts([artifact])
        .try_build()
        .expect("state");
    assert_family_executes(world, state, PlannedCommandFamily::Artifact);
}

#[test]
fn policy_ignores_an_artifact_without_an_eligible_unit() {
    let world = World::new("ai-policy-artifact-unreachable", 2, 1);
    let artifact = WorldArtifact::new(
        ArtifactId::new("artifact-1").expect("artifact id"),
        WorldArtifactType::HeroSword,
        WorldArtifactLocation::Map(HexCoord::new(1, 0)),
    );
    let state = world
        .state([], [])
        .with_artifacts([artifact])
        .try_build()
        .expect("state");
    assert_family_executes(world, state, PlannedCommandFamily::Turn);
}

#[test]
fn policy_schedules_a_legal_city_foundation() {
    let world = World::new("ai-policy-founding", 5, 5);
    let settler = unit(
        "settler",
        &world.actor,
        UnitKind::Settler,
        HexCoord::new(2, 2),
    );
    let state = world.state([settler], []).try_build().expect("state");
    assert_family_executes(world, state, PlannedCommandFamily::City);
}

#[test]
fn policy_skips_a_founding_site_without_required_territory() {
    let world = World::new("ai-policy-founding-small", 1, 1);
    let settler = unit(
        "settler",
        &world.actor,
        UnitKind::Settler,
        HexCoord::new(0, 0),
    );
    let state = world.state([settler], []).try_build().expect("state");
    assert_family_executes(world, state, PlannedCommandFamily::Turn);
}

#[test]
fn policy_selects_a_favorable_visible_attack() {
    let world = World::new("ai-policy-combat", 3, 1);
    let attacker = unit(
        "attacker",
        &world.actor,
        UnitKind::Warrior,
        HexCoord::new(0, 0),
    );
    let defender = unit(
        "defender",
        &world.foreign,
        UnitKind::Settler,
        HexCoord::new(1, 0),
    );
    let state = world
        .state([attacker, defender], [])
        .try_build()
        .expect("state");
    assert_family_executes(world, state, PlannedCommandFamily::Combat);
}

#[test]
fn policy_declines_a_disadvantageous_visible_attack() {
    let world = World::new("ai-policy-combat-decline", 3, 1);
    let attacker = unit(
        "attacker",
        &world.actor,
        UnitKind::Scout,
        HexCoord::new(0, 0),
    );
    let defender = unit(
        "defender",
        &world.foreign,
        UnitKind::Warrior,
        HexCoord::new(1, 0),
    );
    let state = world
        .state([attacker, defender], [])
        .try_build()
        .expect("state");
    assert_family_executes(world, state, PlannedCommandFamily::Turn);
}

#[test]
fn policy_uses_engine_selected_scout_exploration() {
    let world = World::new("ai-policy-logistics", 5, 5);
    let origin = HexCoord::new(2, 2);
    let scout = unit("scout", &world.actor, UnitKind::Scout, origin);
    let fog = actor_fog(&world, [origin], [origin]);
    let state = world
        .state([scout], [])
        .with_fog_of_war(fog)
        .try_build()
        .expect("state");
    assert_family_executes(world, state, PlannedCommandFamily::Logistics);
}

#[test]
fn policy_falls_back_to_movement_when_logistics_has_no_action() {
    let merchant_world = World::new("ai-policy-logistics-empty-merchant", 2, 1);
    let merchant = unit(
        "merchant",
        &merchant_world.actor,
        UnitKind::Merchant,
        HexCoord::new(0, 0),
    );
    let merchant_state = merchant_world
        .state(
            [merchant],
            [producing_city(
                "capital",
                &merchant_world.actor,
                HexCoord::new(0, 0),
            )],
        )
        .try_build()
        .expect("merchant state");
    assert_family_executes(merchant_world, merchant_state, PlannedCommandFamily::Turn);

    let scout_world = World::new("ai-policy-logistics-empty-scout", 2, 1);
    let scout = unit(
        "scout",
        &scout_world.actor,
        UnitKind::Scout,
        HexCoord::new(0, 0),
    );
    let visible = [HexCoord::new(0, 0), HexCoord::new(1, 0)];
    let fog = actor_fog(&scout_world, visible, visible);
    let scout_state = scout_world
        .state([scout], [])
        .with_fog_of_war(fog)
        .try_build()
        .expect("scout state");
    assert_family_executes(scout_world, scout_state, PlannedCommandFamily::Movement);
}

fn assert_family_executes(world: World, state: GameState, family: PlannedCommandFamily) {
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(
            world.map.clone(),
            world.rules.clone(),
            state,
            world.actor,
        ))
        .expect("open");
    let StrategicPlanningOutcome::Planned(plan) =
        StrategicPlanner.plan(&mut runtime).expect("plan")
    else {
        panic!("expected policy command")
    };
    assert_eq!(plan.command().family(), family);
    assert!(
        plan.execute(&mut runtime)
            .expect("execute plan")
            .is_accepted()
    );
    let replay = runtime.export_replay_json().expect("replay");
    let verification =
        LocalRuntime::verify_replay_json(world.map, world.rules, &replay).expect("verify replay");
    assert_eq!(verification.entry_count, 1);
}

fn actor_fog(
    world: &World,
    discovered: impl IntoIterator<Item = HexCoord>,
    visible: impl IntoIterator<Item = HexCoord>,
) -> FogOfWar {
    FogOfWar::try_new([
        PlayerFog::new(world.actor.clone(), discovered, visible),
        PlayerFog::new(world.foreign.clone(), [], []),
    ])
    .expect("fog")
}

struct World {
    map: MapDefinition,
    rules: RulesetDefinition,
    actor: PlayerId,
    foreign: PlayerId,
    identity: MatchIdentity,
    lifecycle: TurnLifecycle,
    knowledge: KnowledgeState,
}

impl World {
    fn new(id: &str, columns: u16, rows: u16) -> Self {
        let map = map(id, columns, rows);
        let rules = RulesetDefinition::standard().clone();
        let actor = player("player-1");
        let foreign = player("player-2");
        let identity = MatchIdentity::try_new(
            MatchRules::new(
                GameLengthConfig::default(),
                VictoryRules::try_new(
                    false,
                    false,
                    aonw_domain::RuleNumber::new("60").expect("percent"),
                    1,
                    true,
                    Some(20),
                    None,
                    false,
                    1,
                    1,
                )
                .expect("victory rules"),
                BTreeMap::new(),
            ),
            [participant(&actor), participant(&foreign)],
            GameMode::Multiplayer,
        )
        .expect("identity");
        let lifecycle = TurnLifecycle::try_new(
            &identity,
            BTreeMap::from([
                (actor.clone(), PlayerTurnState::Active),
                (foreign.clone(), PlayerTurnState::Active),
            ]),
            [actor.clone(), foreign.clone()],
            [],
            BTreeMap::new(),
            [],
            [],
            None,
        )
        .expect("lifecycle");
        let knowledge = KnowledgeState::new(
            ResearchState::try_new([
                (
                    actor.clone(),
                    PlayerResearchState::try_new([], Some(TechnologyId::Agriculture), [], 0)
                        .expect("actor research"),
                ),
                (foreign.clone(), PlayerResearchState::default()),
            ])
            .expect("research"),
            WonderRegistry::default(),
        );
        Self {
            map,
            rules,
            actor,
            foreign,
            identity,
            lifecycle,
            knowledge,
        }
    }

    fn state<const U: usize, const C: usize>(
        &self,
        units: [Unit; U],
        cities: [City; C],
    ) -> aonw_domain::GameStateBuilder {
        GameState::builder(
            StateRevision::new(9),
            4,
            self.map.bounds(),
            self.rules.occupancy_policy(),
            units,
        )
        .with_cities(cities)
        .with_knowledge(self.knowledge.clone())
        .with_match_lifecycle(MatchLifecycle::new(
            self.identity.clone(),
            self.lifecycle.clone(),
        ))
    }
}

fn map(id: &str, columns: u16, rows: u16) -> MapDefinition {
    MapDefinition::try_new(
        id,
        GridLayout::OddQFlatTop,
        columns,
        rows,
        (0..rows)
            .flat_map(|row| {
                (0..columns).map(move |col| {
                    TileDefinition::try_new_for_simulation(
                        HexCoord::new(i32::from(col), i32::from(row)),
                        vec![TerrainType::Grassland],
                        Vec::new(),
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

fn unit(id: &str, owner: &PlayerId, kind: UnitKind, at: HexCoord) -> Unit {
    Unit::builder(
        UnitId::new(id).expect("unit id"),
        owner.clone(),
        kind,
        id,
        at,
        MovementUnits::new(10),
    )
    .build()
    .expect("unit")
}

fn city(id: &str, owner: &PlayerId, at: HexCoord) -> City {
    City::builder(CityId::new(id).expect("city id"), owner.clone(), id, at)
        .build()
        .expect("city")
}

fn producing_city(id: &str, owner: &PlayerId, at: HexCoord) -> City {
    City::builder(CityId::new(id).expect("city id"), owner.clone(), id, at)
        .with_production(
            Some(
                CityProductionQueue::try_new(
                    CityProductionTarget::Building(CityBuildingType::Granary),
                    0,
                    StrategicResourceStockpile::default(),
                )
                .expect("production queue"),
            ),
            0,
        )
        .build()
        .expect("city")
}

fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player")
}

fn participant(player: &PlayerId) -> Participant {
    Participant::try_new(
        player.clone(),
        player.as_str(),
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Ai,
        None,
    )
    .expect("participant")
}
