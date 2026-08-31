#[path = "resource_trade/fixture.rs"]
mod fixture;

use aonw_domain::{DiplomaticRelationStatus, ResourceType, StateRevision};
use aonw_engine::{CommandRejectionCode, GameEngine, OpenResourceTradeCommand, PlayerCommand};

use fixture::{apply_exchange, apply_trade, assert_rejected, context, fixture};

#[test]
fn resource_for_gold_opens_one_deterministic_agreement_without_early_transfer() {
    let fixture = fixture(None, 20, true, []);
    let transition = apply_trade(
        fixture.state.clone(),
        &fixture,
        11,
        ResourceType::Marble,
        3,
        5,
        None,
    );
    assert!(transition.is_accepted());
    assert_eq!(transition.revision(), StateRevision::new(12));
    assert!(transition.events().is_empty());
    assert_eq!(transition.state().economy(), fixture.state.economy());
    let [agreement] = transition.state().diplomacy().resource_trade_agreements() else {
        panic!("one agreement")
    };
    assert_eq!(agreement.id(), "resource_trade_player-1_player-2_marble_0");
    assert_eq!(agreement.exporter_player_id(), &fixture.p2);
    assert_eq!(agreement.importer_player_id(), &fixture.p1);
    assert_eq!(agreement.resource(), ResourceType::Marble);
    assert_eq!(agreement.gold_per_turn(), 3);
    assert_eq!(agreement.remaining_turns(), 5);
    assert_eq!(agreement.amount_per_turn(), 1);
    assert_eq!(agreement.exchange_group_id(), None);
}

#[test]
fn resource_exchange_opens_two_reciprocal_legs_atomically() {
    let fixture = fixture(None, 20, true, []);
    let transition = apply_exchange(
        fixture.state.clone(),
        &fixture,
        11,
        ResourceType::Iron,
        ResourceType::Marble,
        6,
        None,
    );
    assert!(transition.is_accepted());
    assert!(transition.events().is_empty());
    assert_eq!(transition.state().economy(), fixture.state.economy());
    let agreements = transition.state().diplomacy().resource_trade_agreements();
    assert_eq!(agreements.len(), 2);
    let base = "resource_exchange_player-1_player-2_iron_marble_0";
    assert_eq!(agreements[0].id(), format!("{base}_offered"));
    assert_eq!(agreements[0].exporter_player_id(), &fixture.p1);
    assert_eq!(agreements[0].importer_player_id(), &fixture.p2);
    assert_eq!(agreements[0].resource(), ResourceType::Iron);
    assert_eq!(agreements[0].exchange_group_id(), Some(base));
    assert_eq!(agreements[1].id(), format!("{base}_requested"));
    assert_eq!(agreements[1].exporter_player_id(), &fixture.p2);
    assert_eq!(agreements[1].importer_player_id(), &fixture.p1);
    assert_eq!(agreements[1].resource(), ResourceType::Marble);
    assert_eq!(agreements[1].exchange_group_id(), Some(base));
}

#[test]
fn resource_trade_rejections_validate_revision_target_resource_and_terms_in_order() {
    let hidden = fixture(None, 20, false, []);
    assert_rejected(
        &apply_trade(
            hidden.state.clone(),
            &hidden,
            10,
            ResourceType::Wheat,
            -1,
            0,
            None,
        ),
        CommandRejectionCode::StaleRevision,
        &hidden.state,
    );
    assert_rejected(
        &apply_trade(
            hidden.state.clone(),
            &hidden,
            11,
            ResourceType::Marble,
            1,
            1,
            None,
        ),
        CommandRejectionCode::DiplomacyTargetNotDiscovered,
        &hidden.state,
    );

    let neutral = fixture(None, 20, true, []);
    let self_target = GameEngine::apply_player_owned(
        neutral.state.clone(),
        context(&neutral),
        PlayerCommand::OpenResourceTrade(OpenResourceTradeCommand::new(
            11,
            &neutral.p1,
            ResourceType::Wheat,
            -1,
            0,
            None,
        )),
    )
    .expect("self target");
    assert_rejected(
        &self_target,
        CommandRejectionCode::InvalidResourceTradeTarget,
        &neutral.state,
    );
    assert_rejected(
        &apply_trade(
            neutral.state.clone(),
            &neutral,
            11,
            ResourceType::Wheat,
            -1,
            0,
            None,
        ),
        CommandRejectionCode::InvalidResourceTradeResource,
        &neutral.state,
    );
    assert_rejected(
        &apply_trade(
            neutral.state.clone(),
            &neutral,
            11,
            ResourceType::Marble,
            -1,
            0,
            None,
        ),
        CommandRejectionCode::InvalidResourceTradeTerms,
        &neutral.state,
    );
}

#[test]
fn resource_trade_rejections_validate_policy_capacity_and_identity_in_order() {
    let war = fixture(Some(DiplomaticRelationStatus::War), 0, true, []);
    assert_rejected(
        &apply_trade(
            war.state.clone(),
            &war,
            11,
            ResourceType::Marble,
            3,
            4,
            None,
        ),
        CommandRejectionCode::ResourceTradeBlockedByWar,
        &war.state,
    );
    let poor = fixture(None, 2, true, []);
    assert_rejected(
        &apply_trade(
            poor.state.clone(),
            &poor,
            11,
            ResourceType::Marble,
            3,
            4,
            None,
        ),
        CommandRejectionCode::ResourceTradeGoldUnavailable,
        &poor.state,
    );

    let neutral = fixture(None, 20, true, []);
    let accepted = apply_trade(
        neutral.state.clone(),
        &neutral,
        11,
        ResourceType::Marble,
        3,
        4,
        Some("trade-1"),
    );
    assert_rejected(
        &apply_trade(
            accepted.state().clone(),
            &neutral,
            12,
            ResourceType::Marble,
            3,
            4,
            Some("another"),
        ),
        CommandRejectionCode::ResourceTradeAlreadyActive,
        accepted.state(),
    );
    assert_rejected(
        &apply_trade(
            accepted.state().clone(),
            &neutral,
            12,
            ResourceType::Iron,
            3,
            4,
            Some("trade-1"),
        ),
        CommandRejectionCode::ResourceTradeAgreementIdConflict,
        accepted.state(),
    );
    assert_rejected(
        &apply_trade(
            neutral.state.clone(),
            &neutral,
            11,
            ResourceType::Marble,
            3,
            4,
            Some("invalid id"),
        ),
        CommandRejectionCode::InvalidResourceTradeAgreementId,
        &neutral.state,
    );
    assert_rejected(
        &apply_trade(
            neutral.state.clone(),
            &neutral,
            11,
            ResourceType::Horses,
            3,
            4,
            None,
        ),
        CommandRejectionCode::ResourceTradeExportUnavailable,
        &neutral.state,
    );
}

#[test]
fn resource_exchange_validates_both_legs_in_order() {
    let fixture = fixture(None, 20, true, []);
    assert_rejected(
        &apply_exchange(
            fixture.state.clone(),
            &fixture,
            11,
            ResourceType::Wheat,
            ResourceType::Marble,
            0,
            None,
        ),
        CommandRejectionCode::InvalidResourceTradeResource,
        &fixture.state,
    );
    assert_rejected(
        &apply_exchange(
            fixture.state.clone(),
            &fixture,
            11,
            ResourceType::Iron,
            ResourceType::Iron,
            0,
            None,
        ),
        CommandRejectionCode::InvalidResourceTradeTerms,
        &fixture.state,
    );
    assert_rejected(
        &apply_exchange(
            fixture.state.clone(),
            &fixture,
            11,
            ResourceType::Horses,
            ResourceType::Marble,
            4,
            None,
        ),
        CommandRejectionCode::ResourceTradeOfferUnavailable,
        &fixture.state,
    );
    assert_rejected(
        &apply_exchange(
            fixture.state.clone(),
            &fixture,
            11,
            ResourceType::Iron,
            ResourceType::Horses,
            4,
            None,
        ),
        CommandRejectionCode::ResourceTradeRequestUnavailable,
        &fixture.state,
    );
}
