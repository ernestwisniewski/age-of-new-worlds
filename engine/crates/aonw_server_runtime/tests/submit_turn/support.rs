use std::collections::{BTreeMap, BTreeSet};

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_contracts::{
    GameModeDto, MatchIdentityDto, MatchRulesDto, ParticipantDto, PlayerCountryDto, PlayerKindDto,
    TurnModeDto,
};
use aonw_domain::{
    EconomyState, FogOfWar, GameMode, GameState, HexCoord, InitialResourceDistribution,
    KnowledgeState, MatchIdentity, MatchLifecycle, MatchRules, MovementUnits, Participant,
    PlayerCountry, PlayerFog, PlayerId, PlayerKind, PlayerResearchState, PlayerTurnState,
    ResearchState, ResourceType, StateRevision, StrategicResourceStockpile, TechnologyId,
    TurnLifecycle, Unit, UnitId, UnitKind, WonderRegistry,
};
use aonw_server_runtime::{PreparedServerWorld, SubmitTurnRequest};

pub(super) struct Fixture {
    pub(super) state: GameState,
    pub(super) world: PreparedServerWorld,
}

impl Fixture {
    pub(super) fn request(
        &self,
        actor: &str,
        expected_revision: u64,
        initial_event_offset: u64,
    ) -> SubmitTurnRequest {
        SubmitTurnRequest {
            state: self.state.clone(),
            world: self.world.clone(),
            authenticated_actor: player(actor),
            expected_revision,
            initial_event_offset,
        }
    }

    pub(super) fn request_with_world(
        &self,
        actor: &str,
        expected_revision: u64,
        initial_event_offset: u64,
        world: PreparedServerWorld,
    ) -> SubmitTurnRequest {
        SubmitTurnRequest {
            state: self.state.clone(),
            world,
            authenticated_actor: player(actor),
            expected_revision,
            initial_event_offset,
        }
    }
}

pub(super) fn fixture(submitted: impl IntoIterator<Item = PlayerId>) -> Fixture {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let map = map(2);
    let ruleset = RulesetDefinition::standard().clone();
    let participants = [
        participant(p1.clone(), "One"),
        participant(p2.clone(), "Two"),
    ];
    let identity =
        MatchIdentity::try_new(MatchRules::default(), participants, GameMode::Multiplayer)
            .expect("identity");
    let submitted = submitted.into_iter().collect::<BTreeSet<_>>();
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (
                p1.clone(),
                if submitted.contains(&p1) {
                    PlayerTurnState::Finished
                } else {
                    PlayerTurnState::Active
                },
            ),
            (
                p2.clone(),
                if submitted.contains(&p2) {
                    PlayerTurnState::Finished
                } else {
                    PlayerTurnState::Active
                },
            ),
        ]),
        [p1.clone(), p2.clone()],
        submitted,
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle");
    let economy = EconomyState::try_new(
        &identity,
        map.bounds(),
        BTreeMap::from([(p1.clone(), 17), (p2.clone(), 91)]),
        BTreeMap::from([(p1.clone(), 2), (p2.clone(), 8)]),
        BTreeMap::new(),
        BTreeMap::from([
            (
                p1.clone(),
                StrategicResourceStockpile::try_new(BTreeMap::from([(ResourceType::Oil, 4)]))
                    .expect("player one stockpile"),
            ),
            (
                p2.clone(),
                StrategicResourceStockpile::try_new(BTreeMap::from([(ResourceType::Aluminium, 9)]))
                    .expect("player two stockpile"),
            ),
        ]),
        InitialResourceDistribution::default(),
    )
    .expect("economy");
    let units = [unit("unit-1", &p1, 0), unit("unit-2", &p2, 1)];
    let research = fixture_research(&p1, &p2);
    let fog = FogOfWar::try_new([
        PlayerFog::new(p1, [], [HexCoord::new(0, 0)]),
        PlayerFog::new(p2, [], [HexCoord::new(1, 0)]),
    ])
    .expect("fog");
    let state = GameState::builder(
        StateRevision::new(7),
        7,
        map.bounds(),
        ruleset.occupancy_policy(),
        units,
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .with_economy(economy)
    .with_knowledge(KnowledgeState::new(research, WonderRegistry::default()))
    .with_fog_of_war(fog)
    .try_build()
    .expect("state");
    let world = PreparedServerWorld::try_new(map, ruleset).expect("prepared world");
    Fixture { state, world }
}

fn fixture_research(player_one: &PlayerId, player_two: &PlayerId) -> ResearchState {
    ResearchState::try_new([
        (
            player_one.clone(),
            PlayerResearchState::try_new(
                [],
                Some(TechnologyId::Agriculture),
                [(TechnologyId::Agriculture, 3)],
                1,
            )
            .expect("player one research"),
        ),
        (
            player_two.clone(),
            PlayerResearchState::try_new(
                [],
                Some(TechnologyId::Mining),
                [(TechnologyId::Mining, 11)],
                4,
            )
            .expect("player two research"),
        ),
    ])
    .expect("research")
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

fn unit(id: &str, owner: &PlayerId, col: i32) -> Unit {
    Unit::builder(
        UnitId::new(id).expect("unit id"),
        owner.clone(),
        UnitKind::Commander,
        id,
        HexCoord::new(col, 0),
        MovementUnits::ZERO,
    )
    .build()
    .expect("unit")
}

pub(super) fn map(cols: u16) -> MapDefinition {
    MapDefinition::try_new(
        "server-host-test",
        GridLayout::OddQFlatTop,
        cols,
        1,
        (0..cols)
            .map(|col| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(i32::from(col), 0),
                    vec![TerrainType::Plains],
                    Vec::new(),
                    0,
                )
                .expect("tile")
            })
            .collect(),
        Vec::new(),
    )
    .expect("map")
}

pub(super) fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player id")
}

pub(super) fn expected_economy(player: &PlayerId) -> (i64, i64, i64, ResourceType, i64) {
    if player.as_str() == "player-1" {
        (17, 2, 0, ResourceType::Oil, 4)
    } else {
        (91, 8, 0, ResourceType::Aluminium, 9)
    }
}

pub(super) fn expected_research(player: &PlayerId) -> (TechnologyId, i64, i64) {
    if player.as_str() == "player-1" {
        (TechnologyId::Agriculture, 3, 1)
    } else {
        (TechnologyId::Mining, 11, 4)
    }
}

pub(super) fn match_identity(game_mode: GameModeDto) -> MatchIdentityDto {
    MatchIdentityDto {
        match_rules: MatchRulesDto::default(),
        participants: [
            ("player-1", "One", PlayerCountryDto::Poland),
            ("player-2", "Two", PlayerCountryDto::Germany),
        ]
        .into_iter()
        .map(|(id, name, country)| ParticipantDto {
            id: id.to_owned(),
            name: name.to_owned(),
            color_value: 0xff00_0000,
            country,
            kind: PlayerKindDto::Human,
            ai: None,
        })
        .collect(),
        game_mode,
        turn_mode: Some(match game_mode {
            GameModeDto::HotSeat => TurnModeDto::Sequential,
            GameModeDto::Multiplayer => TurnModeDto::Simultaneous,
        }),
    }
}
