use aonw_engine::{EconomyQueryError, StrategicResourceInventory, strategic_resource_inventory};

use super::*;

#[path = "inventory_support.rs"]
mod fixture;
use fixture::{advanced_research, inventory_state, trade};

fn inventory(state: &aonw_domain::GameState) -> StrategicResourceInventory {
    strategic_resource_inventory(
        state,
        EngineContext::canonical(
            &player("player-1"),
            &resource_map(),
            RulesetDefinition::standard(),
        ),
    )
    .unwrap()
}

#[test]
fn inventory_keeps_seven_kinds_and_hides_foreign_research_stock_and_allocations() {
    let empty = inventory(&inventory_state(
        ResearchState::default(),
        0,
        0,
        true,
        vec![],
    ));
    let rival = inventory(&inventory_state(
        advanced_research("player-2"),
        0,
        0,
        true,
        vec![],
    ));
    assert_eq!(empty, rival);
    assert_eq!(
        empty.balances.map(|row| row.resource),
        [
            ResourceType::Iron,
            ResourceType::Coal,
            ResourceType::Oil,
            ResourceType::Aluminium,
            ResourceType::Uranium,
            ResourceType::Horses,
            ResourceType::Marble,
        ]
    );
    assert_eq!(empty.available_type_count, 2);
    assert_eq!(empty.shortage_type_count, 0);
    assert!(empty.allocations.is_empty());
    assert!(empty.production.sources().is_empty());
    assert_eq!(
        empty
            .deposits
            .iter()
            .map(|row| row.resource)
            .collect::<Vec<_>>(),
        [ResourceType::Iron, ResourceType::Marble]
    );
    for row in empty.balances {
        let visible = matches!(row.resource, ResourceType::Iron | ResourceType::Marble);
        assert_eq!(row.available, i64::from(visible));
        assert_eq!(row.controlled_deposits, i64::from(visible));
        assert_eq!(row.allocated, 0);
    }
}

#[test]
fn inventory_reports_deposits_without_extraction_and_deduplicates_placed_resources() {
    let state = inventory_state(advanced_research("player-1"), 5, 2, false, vec![]);
    let result = inventory(&state);
    assert_eq!(result.deposits.len(), 7);
    assert_eq!(result.available_type_count, 6);
    assert_eq!(result.shortage_type_count, 0);
    assert!(
        result
            .deposits
            .iter()
            .all(|row| row.city_id == city_id("city-1")
                && row.coordinate == HexCoord::new(1, 0)
                && row.improvement.is_none()
                && row.amount_per_turn.is_none())
    );
    assert!(result.production.sources().is_empty());
    for row in result.balances {
        assert_eq!(row.controlled_deposits, 1);
        assert_eq!(row.domestic_production, 0);
        assert_eq!(row.source_count, i64::from(!row.stockpiled));
    }
    assert_eq!(
        inventory(&state),
        result,
        "read model is repeatable and does not reserve/refund"
    );
}

#[test]
fn inventory_distinguishes_free_stock_reservations_and_agreed_trade_flows() {
    let state = inventory_state(
        advanced_research("player-1"),
        5,
        2,
        true,
        vec![
            trade("oil-in", ResourceType::Oil, true, 3),
            trade("oil-out", ResourceType::Oil, false, 6),
            trade("iron-in", ResourceType::Iron, true, 4),
            trade("iron-out", ResourceType::Iron, false, 1),
        ],
    );
    let result = inventory(&state);
    let oil = result
        .balances
        .iter()
        .find(|row| row.resource == ResourceType::Oil)
        .unwrap();
    assert_eq!((oil.available, oil.allocated, oil.stored_total), (5, 2, 7));
    assert_eq!(
        (
            oil.domestic_production,
            oil.imports,
            oil.exports,
            oil.net_per_turn
        ),
        (1, 3, 6, -2)
    );
    assert_eq!((oil.controlled_deposits, oil.source_count), (1, 1));
    assert!(!oil.shortage);
    let iron = result
        .balances
        .iter()
        .find(|row| row.resource == ResourceType::Iron)
        .unwrap();
    assert_eq!((iron.available, iron.imports, iron.exports), (2, 4, 1));
    assert_eq!(iron.net_per_turn, 3);
    assert_eq!(result.allocations.len(), 1);
    assert_eq!(result.allocations[0].city_id, city_id("city-1"));
    assert_eq!(result.allocations[0].amount, 2);
    let deposit = result
        .deposits
        .iter()
        .find(|row| row.resource == ResourceType::Oil)
        .unwrap();
    assert_eq!(deposit.improvement, Some(FieldImprovementKind::OilWell));
    assert_eq!(deposit.amount_per_turn, Some(1));
}

#[test]
fn inventory_does_not_refund_a_city_allocation_or_credit_future_imports_for_shortages() {
    let result = inventory(&inventory_state(
        advanced_research("player-1"),
        0,
        20,
        true,
        vec![trade("oil-in", ResourceType::Oil, true, 9)],
    ));
    let oil = result
        .balances
        .iter()
        .find(|row| row.resource == ResourceType::Oil)
        .unwrap();
    assert_eq!(
        (oil.available, oil.stored_total, oil.net_per_turn),
        (0, 20, 10)
    );
    assert!(oil.shortage);
    assert!(oil.no_free_stock);
    assert_eq!(result.shortage_type_count, 2);
    assert_eq!(result.attention_count, 2);
}

#[test]
fn inventory_warns_for_agreements_with_one_or_two_turns_left() {
    let result = inventory(&inventory_state(
        ResearchState::default(),
        0,
        0,
        false,
        vec![
            trade("one", ResourceType::Iron, true, 1)
                .try_with_remaining_turns(1)
                .unwrap(),
            trade("two", ResourceType::Iron, false, 1)
                .try_with_remaining_turns(2)
                .unwrap(),
            trade("three", ResourceType::Marble, false, 1),
        ],
    ));
    assert_eq!(result.expiring_trade_ids.as_ref(), ["one", "two"]);
    assert_eq!(result.attention_count, 2);
}

#[test]
fn inventory_rejects_overflow_and_unknown_recipients_without_a_partial_result() {
    let state = inventory_state(advanced_research("player-1"), i64::MAX, 1, false, vec![]);
    let map = resource_map();
    let actor = player("player-1");
    assert_eq!(
        strategic_resource_inventory(
            &state,
            EngineContext::canonical(&actor, &map, RulesetDefinition::standard())
        ),
        Err(EconomyQueryError::ArithmeticOverflow)
    );
    let stranger = player("stranger");
    assert!(matches!(
        strategic_resource_inventory(
            &state,
            EngineContext::canonical(&stranger, &map, RulesetDefinition::standard())
        ),
        Err(EconomyQueryError::ProjectionInvalid(_))
    ));
}
