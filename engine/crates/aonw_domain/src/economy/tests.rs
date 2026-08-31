use std::collections::BTreeMap;

use crate::{
    GameMode, HexCoord, HexGridBounds, MatchIdentity, MatchRules, Participant, PlayerCountry,
    PlayerId, PlayerKind,
};

use super::{
    EconomyAccountChange, EconomyAccountKind, EconomyState, EconomyStateBuildError,
    InitialResourceDistribution, InitialResourcePlacement, ResourceType,
    StrategicResourceStockpile,
};

#[test]
fn stockpiles_accept_only_positive_oil_and_aluminium() {
    assert!(StrategicResourceStockpile::try_new(BTreeMap::from([(ResourceType::Oil, 2)])).is_ok());
    assert_eq!(
        StrategicResourceStockpile::try_new(BTreeMap::from([(ResourceType::Iron, 2)])),
        Err(EconomyStateBuildError::ResourceNotStockpiled(
            ResourceType::Iron
        ))
    );
    assert!(StrategicResourceStockpile::try_new(BTreeMap::from([(ResourceType::Oil, 0)])).is_err());
}

#[test]
fn economy_rejects_negative_gold_and_war_weariness() {
    let player = PlayerId::new("player").expect("player id");
    let identity = identity(&player);
    let bounds = HexGridBounds::new(1, 1).expect("bounds");
    let build = |gold, weariness| {
        EconomyState::try_new(
            &identity,
            bounds,
            BTreeMap::from([(player.clone(), gold)]),
            BTreeMap::from([(player.clone(), weariness)]),
            BTreeMap::new(),
            BTreeMap::new(),
            InitialResourceDistribution::default(),
        )
    };
    assert_eq!(
        build(-1, 0),
        Err(EconomyStateBuildError::NegativeGold {
            player: player.clone(),
            value: -1,
        })
    );
    assert_eq!(
        build(0, -1),
        Err(EconomyStateBuildError::NegativeWarWeariness { player, value: -1 })
    );
}

#[test]
fn resource_distribution_normalizes_coordinate_order() {
    let distribution = InitialResourceDistribution::try_new(
        7,
        [
            InitialResourcePlacement::new(HexCoord::new(1, 0), ResourceType::Oil),
            InitialResourcePlacement::new(HexCoord::new(0, 0), ResourceType::Wheat),
        ],
    )
    .expect("distribution");
    assert_eq!(
        distribution
            .placements()
            .iter()
            .map(|placement| placement.coordinate())
            .collect::<Vec<_>>(),
        [HexCoord::new(0, 0), HexCoord::new(1, 0)]
    );
}

#[test]
fn account_changes_are_checked_canonical_and_atomic() {
    let player = PlayerId::new("player").expect("player id");
    let identity = identity(&player);
    let bounds = HexGridBounds::new(1, 1).expect("bounds");
    let state = EconomyState::try_new(
        &identity,
        bounds,
        BTreeMap::from([(player.clone(), 10)]),
        BTreeMap::from([(player.clone(), 1)]),
        BTreeMap::from([(player.clone(), 0)]),
        BTreeMap::from([(
            player.clone(),
            StrategicResourceStockpile::try_new(BTreeMap::from([(ResourceType::Oil, 2)]))
                .expect("stockpile"),
        )]),
        InitialResourceDistribution::default(),
    )
    .expect("economy");
    let updated = state
        .try_after_changes(
            &identity,
            bounds,
            [
                EconomyAccountChange::Gold {
                    player: player.clone(),
                    delta: -3,
                },
                EconomyAccountChange::WarWeariness {
                    player: player.clone(),
                    delta: 2,
                },
                EconomyAccountChange::Stability {
                    player: player.clone(),
                    delta: -5,
                },
                EconomyAccountChange::StrategicResource {
                    player: player.clone(),
                    resource: ResourceType::Oil,
                    delta: -2,
                },
            ],
        )
        .expect("checked changes");
    assert_eq!(updated.player_gold().get(&player), Some(&7));
    assert_eq!(updated.player_war_weariness().get(&player), Some(&3));
    assert_eq!(updated.player_stability_net().get(&player), Some(&-5));
    assert!(!updated.strategic_resources().contains_key(&player));

    let failure = state.try_after_changes(
        &identity,
        bounds,
        [
            EconomyAccountChange::Stability {
                player: player.clone(),
                delta: 1,
            },
            EconomyAccountChange::Gold {
                player: player.clone(),
                delta: -11,
            },
        ],
    );
    assert_eq!(
        failure,
        Err(EconomyStateBuildError::InsufficientBalance {
            player: player.clone(),
            account: EconomyAccountKind::Gold,
            available: 10,
            requested: 11,
        })
    );
    assert_eq!(state.player_stability_net().get(&player), Some(&0));
}

#[test]
fn account_overflow_is_rejected() {
    let player = PlayerId::new("player").expect("player id");
    let identity = identity(&player);
    let bounds = HexGridBounds::new(1, 1).expect("bounds");
    let state = EconomyState::try_new(
        &identity,
        bounds,
        BTreeMap::from([(player.clone(), i64::MAX)]),
        BTreeMap::new(),
        BTreeMap::new(),
        BTreeMap::new(),
        InitialResourceDistribution::default(),
    )
    .expect("economy");
    assert_eq!(
        state.try_after_changes(
            &identity,
            bounds,
            [EconomyAccountChange::Gold {
                player: player.clone(),
                delta: 1,
            }],
        ),
        Err(EconomyStateBuildError::AccountOverflow {
            player,
            account: EconomyAccountKind::Gold,
        })
    );
}

#[test]
fn account_change_failures_cover_every_checked_account_family() {
    let player = PlayerId::new("player").expect("player id");
    let foreign = PlayerId::new("foreign").expect("foreign id");
    let identity = identity(&player);
    let bounds = HexGridBounds::new(1, 1).expect("bounds");
    let saturated = EconomyState::try_new(
        &identity,
        bounds,
        BTreeMap::new(),
        BTreeMap::from([(player.clone(), 1)]),
        BTreeMap::from([(player.clone(), i64::MAX)]),
        BTreeMap::from([(
            player.clone(),
            StrategicResourceStockpile::try_new(BTreeMap::from([(ResourceType::Oil, i64::MAX)]))
                .expect("stockpile"),
        )]),
        InitialResourceDistribution::default(),
    )
    .expect("economy");

    assert_eq!(
        saturated.try_after_changes(
            &identity,
            bounds,
            [EconomyAccountChange::Gold {
                player: foreign.clone(),
                delta: 1,
            }],
        ),
        Err(EconomyStateBuildError::UnknownPlayer(foreign))
    );
    let stability_overflow = saturated
        .try_after_changes(
            &identity,
            bounds,
            [EconomyAccountChange::Stability {
                player: player.clone(),
                delta: 1,
            }],
        )
        .expect_err("stability overflow");
    assert_eq!(
        stability_overflow.to_string(),
        "economy account Stability overflows for player"
    );
    assert_eq!(
        saturated.try_after_changes(
            &identity,
            bounds,
            [EconomyAccountChange::StrategicResource {
                player: player.clone(),
                resource: ResourceType::Iron,
                delta: 1,
            }],
        ),
        Err(EconomyStateBuildError::ResourceNotStockpiled(
            ResourceType::Iron
        ))
    );
    assert_eq!(
        saturated.try_after_changes(
            &identity,
            bounds,
            [EconomyAccountChange::StrategicResource {
                player: player.clone(),
                resource: ResourceType::Oil,
                delta: 1,
            }],
        ),
        Err(EconomyStateBuildError::AccountOverflow {
            player: player.clone(),
            account: EconomyAccountKind::StrategicResource,
        })
    );

    let insufficient = EconomyState::default()
        .try_after_changes(
            &identity,
            bounds,
            [EconomyAccountChange::StrategicResource {
                player,
                resource: ResourceType::Oil,
                delta: -1,
            }],
        )
        .expect_err("insufficient stockpile");
    assert_eq!(
        insufficient.to_string(),
        "economy account StrategicResource for player has 0, cannot debit 1"
    );
}

#[test]
fn strategic_resource_credit_creates_a_canonical_stockpile() {
    let player = PlayerId::new("player").expect("player id");
    let identity = identity(&player);
    let bounds = HexGridBounds::new(1, 1).expect("bounds");
    let updated = EconomyState::default()
        .try_after_changes(
            &identity,
            bounds,
            [EconomyAccountChange::StrategicResource {
                player: player.clone(),
                resource: ResourceType::Oil,
                delta: 2,
            }],
        )
        .expect("resource credit");
    assert_eq!(
        updated.strategic_resources()[&player].amounts(),
        &BTreeMap::from([(ResourceType::Oil, 2)])
    );
}

#[test]
fn economy_state_rejects_foreign_accounts_and_out_of_bounds_distribution() {
    let player = PlayerId::new("player").expect("player id");
    let foreign = PlayerId::new("foreign").expect("foreign id");
    let identity = identity(&player);
    let bounds = HexGridBounds::new(1, 1).expect("bounds");
    assert_eq!(
        EconomyState::try_new(
            &identity,
            bounds,
            BTreeMap::from([(foreign.clone(), 1)]),
            BTreeMap::new(),
            BTreeMap::new(),
            BTreeMap::new(),
            InitialResourceDistribution::default(),
        ),
        Err(EconomyStateBuildError::UnknownPlayer(foreign.clone()))
    );
    assert_eq!(
        EconomyStateBuildError::UnknownPlayer(foreign).to_string(),
        "economy player is not a participant: foreign"
    );

    let outside = HexCoord::new(1, 0);
    let distribution = InitialResourceDistribution::try_new(
        1,
        [InitialResourcePlacement::new(outside, ResourceType::Wheat)],
    )
    .expect("distribution");
    assert_eq!(
        EconomyState::try_new(
            &identity,
            bounds,
            BTreeMap::new(),
            BTreeMap::new(),
            BTreeMap::new(),
            BTreeMap::new(),
            distribution,
        ),
        Err(EconomyStateBuildError::InitialResourceOutOfBounds(outside))
    );
    assert_eq!(
        EconomyStateBuildError::InitialResourceOutOfBounds(outside).to_string(),
        "initial resource at (1, 0) is outside the map"
    );
}

fn identity(player: &PlayerId) -> MatchIdentity {
    MatchIdentity::try_new(
        MatchRules::default(),
        [Participant::try_new(
            player.clone(),
            "Player",
            0xff00_0000,
            PlayerCountry::Poland,
            PlayerKind::Human,
            None,
        )
        .expect("participant")],
        GameMode::HotSeat,
    )
    .expect("identity")
}
