//! Current artifact protocol, projection, save, and replay coverage.

use std::collections::BTreeMap;

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientCommandDto, ClientCommandOutcomeDto, ClientFeatureDto,
    ClientOutcomeDto, ClientRequestBodyDto, ClientRequestDto, ClientResponseBodyDto,
    ClientResponseDto, PlayerArtifactLocationViewDto,
};
use aonw_contracts::{SaveGameDto, WorldArtifactTypeDto};
use aonw_domain::{
    ArtifactId, City, CityId, FogOfWar, GameMode, GameState, HexCoord, MatchIdentity,
    MatchLifecycle, MatchRules, MovementUnits, Participant, PlayerCountry, PlayerFog, PlayerId,
    PlayerKind, PlayerTurnState, StateRevision, TurnLifecycle, Unit, UnitId, UnitKind,
    WorldArtifact, WorldArtifactLocation, WorldArtifactType,
};
use aonw_local_runtime::{ClientProtocol, LocalRuntime, OpenSession, PersistenceError};

#[path = "artifact_runtime/catalog.rs"]
mod catalog;

use catalog::artifact_catalog;

#[test]
fn artifact_commands_projection_save_and_replay_are_exact() {
    let (map, rules, state, actor) = fixture();
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(
            map.clone(),
            rules.clone(),
            state,
            actor,
        ))
        .expect("open artifact runtime");

    let ClientResponseBodyDto::Capabilities { features } =
        dispatch_client(&mut runtime, ClientRequestBodyDto::Capabilities)
    else {
        panic!("capabilities response")
    };
    assert!(features.contains(&ClientFeatureDto::Artifacts));

    assert_initial_artifact_snapshot(&mut runtime);
    assert_protocol_failures(&mut runtime);
    assert_foreign_carried_projection(map.clone(), rules.clone(), &runtime);

    let started = command(
        &mut runtime,
        ClientCommandDto::StartArtifactExcavation {
            expected_revision: 9,
            unit_id: "excavator".to_owned(),
        },
    );
    assert_eq!(started.outcome, ClientCommandOutcomeDto::Accepted);
    assert!(
        started
            .view_patch
            .upserted_artifacts
            .iter()
            .any(|artifact| {
                artifact.id == "map-artifact"
                    && matches!(
                        artifact.location,
                        PlayerArtifactLocationViewDto::Excavation {
                            remaining_turns: 2,
                            ..
                        }
                    )
            })
    );
    assert_mid_excavation_reopens(map.clone(), rules.clone(), &runtime);

    let stored = command(
        &mut runtime,
        ClientCommandDto::StoreArtifactInCity {
            expected_revision: 10,
            unit_id: "carrier".to_owned(),
            city_id: Some("source".to_owned()),
        },
    );
    assert_eq!(stored.outcome, ClientCommandOutcomeDto::Accepted);
    assert!(stored.view_patch.upserted_artifacts.iter().any(|artifact| {
        artifact.id == "carried-artifact"
            && matches!(
                artifact.location,
                PlayerArtifactLocationViewDto::Stored { .. }
            )
    }));

    let traded = command(
        &mut runtime,
        ClientCommandDto::TradeArtifact {
            expected_revision: 11,
            target_player_id: "player-2".to_owned(),
            offered_artifact_id: "carried-artifact".to_owned(),
            offered_gold: 0,
        },
    );
    assert_eq!(traded.outcome, ClientCommandOutcomeDto::Accepted);
    assert_eq!(traded.view_patch.removed_artifact_ids, ["carried-artifact"]);

    let expected = runtime.snapshot().expect("artifact snapshot");
    let save = runtime.export_save_json().expect("artifact save");
    let mut reopened = LocalRuntime::default();
    reopened
        .open_save_json(map.clone(), rules.clone(), &save)
        .expect("reopen artifact save");
    assert_eq!(reopened.snapshot().expect("reopened snapshot"), expected);

    assert_foreign_projection(map.clone(), rules.clone(), &save);

    let replay = runtime.export_replay_json().expect("artifact replay");
    let verification =
        LocalRuntime::verify_replay_json(map, rules, &replay).expect("verify artifact replay");
    assert_eq!(verification.entry_count, 3);
    assert_eq!(
        verification.final_stamp.revision.get(),
        traded.stamp.revision
    );
    assert_eq!(
        verification.final_stamp.state_digest.to_string(),
        traded.stamp.state_digest
    );
}

fn assert_initial_artifact_snapshot(runtime: &mut LocalRuntime) {
    let ClientResponseBodyDto::Snapshot { snapshot } =
        dispatch_client(runtime, ClientRequestBodyDto::Snapshot)
    else {
        panic!("artifact snapshot response")
    };
    assert_eq!(snapshot.artifacts.len(), 9);
    assert!(
        snapshot
            .artifacts
            .iter()
            .any(|artifact| matches!(artifact.location, PlayerArtifactLocationViewDto::Map { .. }))
    );
    assert!(snapshot.artifacts.iter().any(|artifact| matches!(
        artifact.location,
        PlayerArtifactLocationViewDto::Carried { .. }
    )));
    for expected in [
        WorldArtifactTypeDto::AncientImperialCrown,
        WorldArtifactTypeDto::AstronomersTablets,
        WorldArtifactTypeDto::ProphetMask,
        WorldArtifactTypeDto::HeroSword,
        WorldArtifactTypeDto::MerchantsSeal,
        WorldArtifactTypeDto::FirstPeoplesChronicle,
        WorldArtifactTypeDto::TempleReliquary,
        WorldArtifactTypeDto::QueensMirror,
    ] {
        assert!(
            snapshot
                .artifacts
                .iter()
                .any(|artifact| artifact.artifact_type == expected),
            "missing encoded artifact type {expected:?}"
        );
    }
}

fn assert_protocol_failures(runtime: &mut LocalRuntime) {
    let unsupported = ClientProtocol::dispatch(
        runtime,
        ClientRequestDto {
            api_version: CLIENT_API_VERSION + 1,
            request: ClientRequestBodyDto::Capabilities,
        },
    );
    assert_failure(unsupported, "unsupported_client_api_version");

    let invalid_artifact = ClientProtocol::dispatch(
        runtime,
        ClientRequestDto {
            api_version: CLIENT_API_VERSION,
            request: ClientRequestBodyDto::Dispatch {
                command: ClientCommandDto::TradeArtifact {
                    expected_revision: 9,
                    target_player_id: "player-2".to_owned(),
                    offered_artifact_id: " ".to_owned(),
                    offered_gold: 0,
                },
            },
        },
    );
    assert_failure(invalid_artifact, "invalid_artifact_id");

    let closed_snapshot = ClientProtocol::dispatch(
        &mut LocalRuntime::default(),
        ClientRequestDto {
            api_version: CLIENT_API_VERSION,
            request: ClientRequestBodyDto::Snapshot,
        },
    );
    assert_failure(closed_snapshot, "session_not_open");

    let closed_save = ClientProtocol::dispatch(
        &mut LocalRuntime::default(),
        ClientRequestDto {
            api_version: CLIENT_API_VERSION,
            request: ClientRequestBodyDto::ExportSave,
        },
    );
    assert_failure(closed_save, "save_export_failed");

    let invalid_id = ArtifactId::new(" ").expect_err("invalid artifact id");
    assert!(
        PersistenceError::InvalidArtifact(invalid_id)
            .to_string()
            .starts_with("invalid artifact:")
    );
}

fn assert_failure(response: ClientResponseDto, expected_code: &str) {
    let ClientOutcomeDto::Failure { error } = response.outcome else {
        panic!("client failure response")
    };
    assert_eq!(error.code, expected_code);
    assert!(!error.message.is_empty());
}

fn assert_mid_excavation_reopens(
    map: MapDefinition,
    rules: RulesetDefinition,
    runtime: &LocalRuntime,
) {
    let expected = runtime.snapshot().expect("mid-excavation snapshot");
    let save = runtime.export_save_json().expect("mid-excavation save");
    let mut reopened = LocalRuntime::default();
    reopened
        .open_save_json(map, rules, &save)
        .expect("reopen mid-excavation save");
    assert_eq!(reopened.snapshot().expect("reopened excavation"), expected);
}

fn assert_foreign_carried_projection(
    map: MapDefinition,
    rules: RulesetDefinition,
    runtime: &LocalRuntime,
) {
    let save = runtime.export_save_json().expect("initial artifact save");
    let mut save = SaveGameDto::from_json(&save).expect("initial artifact save DTO");
    "player-2".clone_into(&mut save.actor_player_id);
    let mut foreign = LocalRuntime::default();
    foreign
        .open_save_json(map, rules, &save.to_json().expect("foreign carrier save"))
        .expect("open foreign carrier view");
    assert!(
        foreign
            .snapshot()
            .expect("foreign carrier snapshot")
            .artifacts()
            .iter()
            .any(|artifact| {
                artifact.id().as_str() == "carried-artifact"
                    && matches!(
                        artifact.location(),
                        aonw_local_runtime::PlayerArtifactLocationView::Carried(unit_id)
                            if unit_id.as_str() == "carrier"
                    )
            })
    );
}

fn assert_foreign_projection(map: MapDefinition, rules: RulesetDefinition, save: &str) {
    let mut save = SaveGameDto::from_json(save).expect("artifact save DTO");
    "player-2".clone_into(&mut save.actor_player_id);
    let mut runtime = LocalRuntime::default();
    runtime
        .open_save_json(map, rules, &save.to_json().expect("foreign save"))
        .expect("open foreign artifact view");
    let snapshot = runtime.snapshot().expect("foreign snapshot");
    assert_eq!(snapshot.artifacts().len(), 1);
    assert_eq!(snapshot.artifacts()[0].id().as_str(), "carried-artifact");
    assert!(matches!(
        snapshot.artifacts()[0].location(),
        aonw_local_runtime::PlayerArtifactLocationView::Stored(city_id)
            if city_id.as_str() == "target"
    ));
}

fn command(
    runtime: &mut LocalRuntime,
    command: ClientCommandDto,
) -> Box<aonw_contracts::client::ClientCommandResultDto> {
    let ClientResponseBodyDto::Command { result } =
        dispatch_client(runtime, ClientRequestBodyDto::Dispatch { command })
    else {
        panic!("artifact command response")
    };
    result
}

fn dispatch_client(
    runtime: &mut LocalRuntime,
    request: ClientRequestBodyDto,
) -> ClientResponseBodyDto {
    let request = ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request,
    }
    .to_json()
    .expect("request JSON");
    let response = ClientResponseDto::from_json(&ClientProtocol::dispatch_json(runtime, &request))
        .expect("response JSON");
    let ClientOutcomeDto::Success { response } = response.outcome else {
        panic!("client failure: {:?}", response.outcome)
    };
    *response
}

fn fixture() -> (MapDefinition, RulesetDefinition, GameState, PlayerId) {
    let map = map();
    let rules = RulesetDefinition::standard().clone();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [participant(p1.clone()), participant(p2.clone())],
        GameMode::HotSeat,
    )
    .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (p1.clone(), PlayerTurnState::Active),
            (p2.clone(), PlayerTurnState::Finished),
        ]),
        [p1.clone(), p2.clone()],
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle");
    let excavator = unit("excavator", &p1, HexCoord::new(0, 0), None);
    let carrier_artifact = artifact_id("carried-artifact");
    let carrier = unit(
        "carrier",
        &p1,
        HexCoord::new(1, 0),
        Some(carrier_artifact.clone()),
    );
    let mut artifacts = vec![
        artifact(
            "map-artifact",
            WorldArtifactLocation::Map(HexCoord::new(0, 0)),
        ),
        artifact(
            "carried-artifact",
            WorldArtifactLocation::Carried(unit_id("carrier")),
        ),
    ];
    artifacts.extend(artifact_catalog());
    let state = GameState::builder(
        StateRevision::new(9),
        4,
        map.bounds(),
        rules.occupancy_policy(),
        [excavator, carrier],
    )
    .with_cities([
        city("source", &p1, HexCoord::new(1, 0)),
        city("target", &p2, HexCoord::new(2, 0)),
    ])
    .with_artifacts(artifacts)
    .with_fog_of_war(
        FogOfWar::try_new([
            PlayerFog::new(
                p1.clone(),
                [],
                [
                    HexCoord::new(0, 0),
                    HexCoord::new(1, 0),
                    HexCoord::new(3, 0),
                ],
            ),
            PlayerFog::new(p2.clone(), [], [HexCoord::new(1, 0), HexCoord::new(2, 0)]),
        ])
        .expect("fog"),
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("artifact state");
    (map, rules, state, p1)
}

fn participant(id: PlayerId) -> Participant {
    Participant::try_new(
        id,
        "Player",
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Human,
        None,
    )
    .expect("participant")
}

fn unit(id: &str, owner: &PlayerId, at: HexCoord, artifact: Option<ArtifactId>) -> Unit {
    Unit::builder(
        unit_id(id),
        owner.clone(),
        UnitKind::Scout,
        id,
        at,
        MovementUnits::new(10),
    )
    .with_carried_artifact(artifact)
    .build()
    .expect("unit")
}

fn city(id: &str, owner: &PlayerId, at: HexCoord) -> City {
    City::builder(CityId::new(id).expect("city id"), owner.clone(), id, at)
        .build()
        .expect("city")
}

fn artifact(id: &str, location: WorldArtifactLocation) -> WorldArtifact {
    WorldArtifact::new(artifact_id(id), WorldArtifactType::HeroSword, location)
}

fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player id")
}

fn unit_id(id: &str) -> UnitId {
    UnitId::new(id).expect("unit id")
}

fn artifact_id(id: &str) -> ArtifactId {
    ArtifactId::new(id).expect("artifact id")
}

fn map() -> MapDefinition {
    MapDefinition::try_new(
        "artifact-runtime",
        GridLayout::OddQFlatTop,
        4,
        1,
        (0..4)
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
        Vec::new(),
    )
    .expect("map")
}
