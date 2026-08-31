use std::collections::BTreeMap;

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    Diplomacy, DiplomaticRelation, DiplomaticRelationChangeReason, DiplomaticRelationStatus,
    FogOfWar, GameMode, GameState, HexCoord, KnowledgeState, MatchIdentity, MatchLifecycle,
    MatchRules, MovementUnits, Participant, PlayerCountry, PlayerFog, PlayerId, PlayerKind,
    PlayerPair, PlayerResearchState, PlayerTurnState, ResearchState, StateRevision, TechnologyId,
    TurnLifecycle, Unit, UnitId, UnitKind, WonderRegistry,
};
use aonw_local_runtime::{LocalRuntime, OpenSession};

use super::StrengthCase;

pub(super) fn opened(case: &StrengthCase) -> LocalRuntime {
    let map = map(case);
    let rules = RulesetDefinition::standard().clone();
    let actor = player("strength-actor");
    let opponent = player("strength-opponent");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [participant(&actor), participant(&opponent)],
        GameMode::HotSeat,
    )
    .expect("strength identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (actor.clone(), PlayerTurnState::Active),
            (opponent.clone(), PlayerTurnState::Active),
        ]),
        [actor.clone(), opponent.clone()],
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("strength lifecycle");
    let pair = PlayerPair::new(actor.clone(), opponent.clone()).expect("player pair");
    let relation = DiplomaticRelation::try_new(
        pair.clone(),
        DiplomaticRelationStatus::War,
        -100,
        None,
        Some(0),
        Some(DiplomaticRelationChangeReason::DeclarationOfWar),
    )
    .expect("war relation");
    let diplomacy = Diplomacy::try_new(&identity, [pair], [relation], [], [], [], [])
        .expect("strength diplomacy");
    let research = ResearchState::try_new([
        (
            actor.clone(),
            PlayerResearchState::try_new([], Some(TechnologyId::Agriculture), [], 0)
                .expect("actor research"),
        ),
        (
            opponent.clone(),
            PlayerResearchState::try_new([], Some(TechnologyId::Agriculture), [], 0)
                .expect("opponent research"),
        ),
    ])
    .expect("strength research");
    let visible = map
        .tiles()
        .iter()
        .map(TileDefinition::coordinate)
        .collect::<Vec<_>>();
    let fog = FogOfWar::try_new([
        PlayerFog::new(actor.clone(), [], visible.iter().copied()),
        PlayerFog::new(opponent.clone(), [], visible.iter().copied()),
    ])
    .expect("strength visibility");
    let state = GameState::builder(
        StateRevision::INITIAL,
        0,
        map.bounds(),
        rules.occupancy_policy(),
        [
            unit("strength-unit", &actor, case.actor, case.movement_units),
            unit("strength-target", &opponent, case.opponent, 0),
        ],
    )
    .with_fog_of_war(fog)
    .with_diplomacy(diplomacy)
    .with_knowledge(KnowledgeState::new(research, WonderRegistry::default()))
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("strength state");
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(map, rules, state, actor))
        .expect("open strength runtime");
    runtime
}

pub(super) fn unit_id() -> UnitId {
    UnitId::new("strength-unit").expect("strength unit id")
}

fn map(case: &StrengthCase) -> MapDefinition {
    MapDefinition::try_new(
        format!("ai-strength-{}", case.id),
        GridLayout::OddQFlatTop,
        case.cols,
        case.rows,
        (0..case.rows)
            .flat_map(|row| {
                (0..case.cols).map(move |col| {
                    TileDefinition::try_new_for_simulation(
                        HexCoord::new(i32::from(col), i32::from(row)),
                        vec![TerrainType::Grassland],
                        Vec::new(),
                        0,
                    )
                    .expect("strength tile")
                })
            })
            .collect(),
        Vec::new(),
    )
    .expect("strength map")
}

fn participant(id: &PlayerId) -> Participant {
    Participant::try_new(
        id.clone(),
        id.as_str(),
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Ai,
        None,
    )
    .expect("strength participant")
}

fn unit(id: &str, owner: &PlayerId, position: HexCoord, movement_units: u64) -> Unit {
    Unit::builder(
        UnitId::new(id).expect("unit id"),
        owner.clone(),
        UnitKind::Commander,
        id,
        position,
        MovementUnits::new(u32::try_from(movement_units).expect("bounded movement")),
    )
    .build()
    .expect("strength unit")
}

fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player")
}
