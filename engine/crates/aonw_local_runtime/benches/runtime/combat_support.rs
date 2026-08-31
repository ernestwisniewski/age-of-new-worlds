use std::collections::BTreeMap;

use aonw_contracts::client::{ClientCommandDto, ClientQueryDto, ClientRequestBodyDto};
use aonw_contracts::{CityConquestActionDto, CoordinateDto};
use aonw_domain::{
    CityConquestAction, FogOfWar, GameMode, GameState, HexCoord, MatchIdentity, MatchLifecycle,
    MatchRules, MovementUnits, Participant, PlayerCountry, PlayerId, PlayerKind, PlayerTurnState,
    StateRevision, TurnLifecycle, Unit, UnitId, UnitKind,
};
use aonw_local_runtime::{
    AttackHexRequest, CombatPreviewRequest, LocalRuntime, OpenSession, RuntimeQuery,
    RuntimeQueryResult,
};

use super::{
    COLS, ROWS, client_request, command_signature, map, mix, report_with_setup, signature_bytes,
};

pub(super) fn benchmark(unit_count: usize) {
    if unit_count < 2 {
        return;
    }
    let (base, attacker_id) = opened_combat_runtime(unit_count);
    let preview = RuntimeQuery::CombatPreview(CombatPreviewRequest {
        expected_revision: 1,
        attacker_unit_id: attacker_id.clone(),
        defender: HexCoord::new(1, 0),
    });
    report_with_setup(
        "runtime_combat_preview",
        unit_count,
        || base.clone(),
        |mut runtime| {
            let result = runtime.query(&preview).expect("combat preview");
            let RuntimeQueryResult::CombatPreview { preview, .. } = result else {
                unreachable!("combat preview result")
            };
            (
                mix(
                    u64::from(preview.outgoing_damage.0),
                    u64::from(preview.outgoing_damage.1),
                ),
                0,
            )
        },
    );
    let attack = AttackHexRequest {
        expected_revision: 1,
        attacker_unit_id: attacker_id.clone(),
        defender: HexCoord::new(1, 0),
        city_conquest_action: CityConquestAction::Capture,
    };
    report_with_setup(
        "runtime_combat_attack",
        unit_count,
        || base.clone(),
        |mut runtime| {
            let result = runtime.attack_hex(&attack).expect("combat attack");
            (command_signature(&result), 0)
        },
    );

    let preview_json = client_request(ClientRequestBodyDto::Query {
        query: ClientQueryDto::CombatPreview {
            expected_revision: 1,
            attacker_unit_id: attacker_id.as_str().to_owned(),
            defender: CoordinateDto { col: 1, row: 0 },
        },
    });
    report_with_setup(
        "client_json_combat_preview",
        unit_count,
        || base.clone(),
        |mut runtime| {
            let response =
                aonw_local_runtime::ClientProtocol::dispatch_json(&mut runtime, &preview_json);
            (signature_bytes(&response), response.len())
        },
    );
    let attack_json = client_request(ClientRequestBodyDto::Dispatch {
        command: ClientCommandDto::AttackHex {
            expected_revision: 1,
            attacker_unit_id: attacker_id.as_str().to_owned(),
            defender: CoordinateDto { col: 1, row: 0 },
            city_conquest_action: CityConquestActionDto::Capture,
        },
    });
    report_with_setup(
        "client_json_combat_attack",
        unit_count,
        || base.clone(),
        |mut runtime| {
            let response =
                aonw_local_runtime::ClientProtocol::dispatch_json(&mut runtime, &attack_json);
            (signature_bytes(&response), response.len())
        },
    );
}

fn opened_combat_runtime(unit_count: usize) -> (LocalRuntime, UnitId) {
    let map = map();
    let ruleset = aonw_content::RulesetDefinition::standard().clone();
    let occupancy_policy = ruleset.occupancy_policy();
    let actor = PlayerId::new("player-1").expect("actor");
    let defender = PlayerId::new("player-2").expect("defender");
    let identity = MatchIdentity::try_new(
        MatchRules::default(),
        [participant(&actor), participant(&defender)],
        GameMode::Multiplayer,
    )
    .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (actor.clone(), PlayerTurnState::Active),
            (defender.clone(), PlayerTurnState::Active),
        ]),
        [actor.clone(), defender.clone()],
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle");
    let attacker_id = UnitId::new("combat-attacker-0").expect("attacker id");
    let mut units = vec![
        unit(
            attacker_id.clone(),
            actor.clone(),
            UnitKind::Warrior,
            HexCoord::new(0, 0),
        ),
        unit(
            UnitId::new("combat-defender-0").expect("defender id"),
            defender.clone(),
            UnitKind::Settler,
            HexCoord::new(1, 0),
        ),
    ];
    let positions = (1..ROWS)
        .flat_map(|row| (0..COLS).map(move |col| HexCoord::new(i32::from(col), i32::from(row))));
    for (index, position) in positions.take(unit_count.saturating_sub(2)).enumerate() {
        units.push(unit(
            UnitId::new(format!("combat-padding-{index}")).expect("padding id"),
            actor.clone(),
            UnitKind::Warrior,
            position,
        ));
    }
    let state = GameState::builder(
        StateRevision::new(1),
        7,
        map.bounds(),
        occupancy_policy,
        units,
    )
    .with_fog_of_war(FogOfWar::default())
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("combat state");
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(map, ruleset, state, actor))
        .expect("open combat runtime");
    (runtime, attacker_id)
}

fn unit(id: UnitId, owner: PlayerId, kind: UnitKind, position: HexCoord) -> Unit {
    Unit::builder(
        id,
        owner,
        kind,
        "combat-unit",
        position,
        MovementUnits::new(10),
    )
    .build()
    .expect("unit")
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
