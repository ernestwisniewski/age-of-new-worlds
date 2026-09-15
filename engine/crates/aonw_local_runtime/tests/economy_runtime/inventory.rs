use aonw_contracts::client::{ClientCommandDto, ClientCommandOutcomeDto, PlayerViewSnapshotDto};

use super::*;

#[test]
fn inventory_projection_and_turn_patch_match_the_authoritative_snapshot() {
    let map = map();
    let ruleset = RulesetDefinition::standard().clone();
    let actor = PlayerId::new("player-1").unwrap();
    let city_id = CityId::new("city-1").unwrap();
    let state = state(&map, &ruleset, &actor, &city_id);
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(map, ruleset, state, actor))
        .unwrap();
    let initial = snapshot(&mut runtime);
    let inventory = &initial.economy.strategic_resource_inventory;
    assert_eq!(inventory.balances.len(), 7);
    assert_eq!(inventory.available_type_count, 1);
    assert_eq!(inventory.deposits.len(), 1);
    assert_eq!(inventory.deposits[0].city_id, "city-1");
    assert_eq!(inventory.deposits[0].amount_per_turn, Some(1));
    assert_eq!(inventory.balances[2].available, 2);
    assert_eq!(inventory.balances[2].controlled_deposits, 1);
    assert_eq!(inventory.balances[2].net_per_turn, 1);
    let request = ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request: ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::SubmitTurn {
                expected_revision: 9,
            },
        },
    };
    let ClientOutcomeDto::Success { response } =
        ClientProtocol::dispatch(&mut runtime, request).outcome
    else {
        panic!("turn response");
    };
    let ClientResponseBodyDto::Command { result } = *response else {
        panic!("command result");
    };
    assert_eq!(result.outcome, ClientCommandOutcomeDto::Accepted);
    let after = snapshot(&mut runtime);
    let patch = result.view_patch.economy.expect("updated economy");
    assert_eq!(
        patch.strategic_resource_inventory,
        after.economy.strategic_resource_inventory
    );
    assert_eq!(
        after.economy.strategic_resource_inventory.balances[2].available,
        3
    );
    assert_eq!(
        initial.economy.strategic_resource_inventory.balances[2].available,
        2
    );
}

fn snapshot(runtime: &mut LocalRuntime) -> PlayerViewSnapshotDto {
    let ClientOutcomeDto::Success { response } = ClientProtocol::dispatch(
        runtime,
        ClientRequestDto {
            api_version: CLIENT_API_VERSION,
            request: ClientRequestBodyDto::Snapshot,
        },
    )
    .outcome
    else {
        panic!("snapshot success");
    };
    let ClientResponseBodyDto::Snapshot { snapshot } = *response else {
        panic!("snapshot response");
    };
    snapshot
}
