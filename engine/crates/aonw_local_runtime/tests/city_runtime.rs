//! Runtime, persistence, replay, and recipient-boundary tests for cities.

use std::collections::BTreeMap;

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_contracts::{ReplayEvidenceDto, ReplayLogDto, SaveGameDto};
use aonw_domain::{
    CityFoundingDraft, FogOfWar, GameMode, GameState, HexCoord, InteractionState, MatchIdentity,
    MatchLifecycle, MatchRules, MovementUnits, Participant, PlayerCountry, PlayerFog, PlayerId,
    PlayerKind, PlayerTurnState, StateRevision, TurnLifecycle, Unit, UnitId, UnitKind,
};
use aonw_engine::{DomainEvent, ExecutionEvidence, TurnProcessor};
use aonw_local_runtime::{
    CityFoundingOptionsRequest, FoundCityRequest, LocalRuntime, OpenSession, RuntimeQuery,
    RuntimeQueryResult, TurnCommandRequest,
};

#[test]
fn founding_draft_save_reopen_completion_and_replay_are_exact() {
    let (map, rules, state, p1, p2) = fixture();
    let founder_id = unit_id("settler-1");
    let city_id = aonw_domain::CityId::new("city_player-1_3_3").expect("city id");
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(
            map.clone(),
            rules.clone(),
            state,
            p1,
        ))
        .expect("open");

    let draft_snapshot = runtime.snapshot().expect("draft snapshot");
    let draft = draft_snapshot.city_founding_draft().expect("owned draft");
    assert_eq!(draft.founder_unit_id(), &founder_id);
    assert_eq!(draft.controlled_hexes(), [HexCoord::new(3, 2)]);
    let RuntimeQueryResult::CityFoundingOptions { options, .. } = runtime
        .query(&RuntimeQuery::CityFoundingOptions(
            CityFoundingOptionsRequest {
                expected_revision: 9,
                founder_unit_id: founder_id.clone(),
            },
        ))
        .expect("draft options")
    else {
        panic!("founding options")
    };
    assert_eq!(options.selected_controlled_hexes(), [HexCoord::new(3, 2)]);

    let partial_save = runtime.export_save_json().expect("partial save");
    let mut reopened = LocalRuntime::default();
    reopened
        .open_save_json(map.clone(), rules.clone(), &partial_save)
        .expect("reopen partial founding");
    assert_eq!(reopened.snapshot().expect("reopened draft"), draft_snapshot);

    let scheduled = reopened
        .found_city(&FoundCityRequest {
            expected_revision: 9,
            founder_unit_id: founder_id.clone(),
            controlled_hexes: vec![HexCoord::new(3, 2), HexCoord::new(2, 3)].into_boxed_slice(),
        })
        .expect("schedule founding");
    assert!(scheduled.is_accepted());
    assert!(scheduled.view_patch.city_founding_draft.is_none());

    let completed = reopened
        .end_turn(TurnCommandRequest {
            expected_revision: 10,
        })
        .expect("complete founding");
    assert_completed_city(&completed, &founder_id, &city_id);

    let completed_save = reopened.export_save_json().expect("completed save");
    let expected = reopened.snapshot().expect("completed snapshot");
    let mut completed_reopened = LocalRuntime::default();
    completed_reopened
        .open_save_json(map.clone(), rules.clone(), &completed_save)
        .expect("reopen completed city");
    assert_eq!(
        completed_reopened.snapshot().expect("reopened city"),
        expected
    );

    let replay_json = reopened.export_replay_json().expect("replay");
    let verification = LocalRuntime::verify_replay_json(map.clone(), rules.clone(), &replay_json)
        .expect("verify replay");
    assert_eq!(verification.entry_count, 2);
    assert_eq!(verification.final_stamp, completed.stamp);

    let mut tampered = ReplayLogDto::from_json(&replay_json).expect("replay DTO");
    let Some(ReplayEvidenceDto::TurnKernel {
        founded_city_ids, ..
    }) = tampered.segments[0].entries[1].result.evidence.as_mut()
    else {
        panic!("persisted turn evidence")
    };
    founded_city_ids[0] = "city_tampered".to_owned();
    let tampered_json = tampered.to_json().expect("tampered replay");
    assert!(LocalRuntime::verify_replay_json(map.clone(), rules.clone(), &tampered_json).is_err());

    let mut foreign_save = SaveGameDto::from_json(&completed_save).expect("save DTO");
    foreign_save.actor_player_id = p2.as_str().to_owned();
    let foreign_save = foreign_save.to_json().expect("foreign save");
    let mut foreign_runtime = LocalRuntime::default();
    foreign_runtime
        .open_save_json(map, rules, &foreign_save)
        .expect("open foreign recipient");
    let foreign_snapshot = foreign_runtime.snapshot().expect("foreign snapshot");
    assert!(foreign_snapshot.city_founding_draft().is_none());
    assert!(
        foreign_snapshot
            .cities()
            .iter()
            .all(|city| city.id() != &city_id)
    );
}

fn assert_completed_city(
    completed: &aonw_local_runtime::CommandResult,
    founder_id: &UnitId,
    city_id: &aonw_domain::CityId,
) {
    assert!(completed.is_accepted());
    assert!(completed.events.iter().any(|event| matches!(
        event,
        DomainEvent::CityFounded(value) if value.city_id() == city_id
    )));
    assert!(completed.view_patch.removed_unit_ids.contains(founder_id));
    assert!(
        completed
            .view_patch
            .upserted_cities
            .iter()
            .any(|city| city.id() == city_id && city.name() == "Warszawa")
    );
    let Some(ExecutionEvidence::TurnKernel(evidence)) = completed.evidence.as_ref() else {
        panic!("turn evidence")
    };
    assert!(evidence.processors().contains(&TurnProcessor::CityFounding));
    assert_eq!(evidence.founded_city_ids(), std::slice::from_ref(city_id));
}

fn fixture() -> (
    MapDefinition,
    RulesetDefinition,
    GameState,
    PlayerId,
    PlayerId,
) {
    let map = map();
    let rules = RulesetDefinition::standard().clone();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [participant(&p1), participant(&p2)],
        GameMode::HotSeat,
    )
    .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (p1.clone(), PlayerTurnState::Active),
            (p2.clone(), PlayerTurnState::Finished),
        ]),
        [p1.clone()],
        [],
        BTreeMap::new(),
        [],
        [p2.clone()],
        None,
    )
    .expect("lifecycle");
    let center = HexCoord::new(3, 3);
    let founder = Unit::builder(
        unit_id("settler-1"),
        p1.clone(),
        UnitKind::Settler,
        "settler",
        center,
        MovementUnits::new(10),
    )
    .build()
    .expect("settler");
    let observer = Unit::builder(
        unit_id("observer-1"),
        p2.clone(),
        UnitKind::Scout,
        "observer",
        HexCoord::new(7, 5),
        MovementUnits::new(10),
    )
    .build()
    .expect("observer");
    let fog = FogOfWar::try_new([
        PlayerFog::new(p1.clone(), [], [center]),
        PlayerFog::new(p2.clone(), [], [HexCoord::new(7, 5)]),
    ])
    .expect("fog");
    let interaction = InteractionState::new(
        Some(CityFoundingDraft::new(
            unit_id("settler-1"),
            p1.clone(),
            center,
            [HexCoord::new(3, 2)],
        )),
        None,
    );
    let state = GameState::builder(
        StateRevision::new(9),
        4,
        map.bounds(),
        rules.occupancy_policy(),
        [founder, observer],
    )
    .with_fog_of_war(fog)
    .with_interaction(interaction)
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state");
    (map, rules, state, p1, p2)
}

fn map() -> MapDefinition {
    MapDefinition::try_new(
        "runtime-city",
        GridLayout::OddQFlatTop,
        8,
        6,
        (0..6)
            .flat_map(|row| {
                (0..8).map(move |col| {
                    TileDefinition::try_new_for_simulation(
                        HexCoord::new(col, row),
                        vec![TerrainType::Plains],
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

fn participant(id: &PlayerId) -> Participant {
    Participant::try_new(
        id.clone(),
        id.as_str(),
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Human,
        None,
    )
    .expect("participant")
}

fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player")
}

fn unit_id(id: &str) -> UnitId {
    UnitId::new(id).expect("unit")
}
