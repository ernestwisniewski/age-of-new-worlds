use aonw_domain::{DiplomaticRelation, DiplomaticRelationStatus, MovementUnits, PlayerPair, Unit};

use super::*;

#[test]
fn rejection_precedence_is_stable_and_hides_unknown_targets() {
    let actor = player("player_1");
    let defender = player("player_2");
    let attacker_id = unit_id("attacker");

    let ordinary = state(
        vec![
            unit(
                "attacker",
                &actor,
                UnitKind::Warrior,
                HexCoord::new(0, 0),
                None,
            ),
            unit(
                "defender",
                &defender,
                UnitKind::Warrior,
                HexCoord::new(1, 0),
                None,
            ),
        ],
        Vec::new(),
        FogOfWar::default(),
        Diplomacy::default(),
    );
    assert_eq!(
        rejection(
            &ordinary,
            &actor,
            10,
            &unit_id("missing"),
            HexCoord::new(9, 9)
        ),
        CommandRejectionCode::StaleRevision
    );
    assert_eq!(
        rejection(
            &ordinary,
            &actor,
            11,
            &unit_id("missing"),
            HexCoord::new(9, 9)
        ),
        CommandRejectionCode::AttackerNotFound
    );
    assert_eq!(
        rejection(&ordinary, &defender, 11, &attacker_id, HexCoord::new(9, 9)),
        CommandRejectionCode::AttackerNotControlled
    );

    let exhausted = state(
        vec![
            Unit::builder(
                attacker_id.clone(),
                actor.clone(),
                UnitKind::Warrior,
                "attacker",
                HexCoord::new(0, 0),
                MovementUnits::ZERO,
            )
            .build()
            .expect("exhausted attacker"),
            unit(
                "defender",
                &defender,
                UnitKind::Warrior,
                HexCoord::new(1, 0),
                None,
            ),
        ],
        Vec::new(),
        FogOfWar::default(),
        Diplomacy::default(),
    );
    assert_eq!(
        rejection(&exhausted, &actor, 11, &attacker_id, HexCoord::new(9, 9)),
        CommandRejectionCode::AttackerExhausted
    );
}

#[test]
fn attack_capability_and_visibility_precede_target_identity() {
    let actor = player("player_1");
    let attacker_id = unit_id("attacker");
    let worker = state(
        vec![unit(
            "attacker",
            &actor,
            UnitKind::Worker,
            HexCoord::new(0, 0),
            None,
        )],
        Vec::new(),
        FogOfWar::default(),
        Diplomacy::default(),
    );
    assert_eq!(
        rejection(&worker, &actor, 11, &attacker_id, HexCoord::new(9, 9)),
        CommandRejectionCode::AttackTargetOutOfBounds
    );
    assert_eq!(
        rejection(&worker, &actor, 11, &attacker_id, HexCoord::new(1, 0)),
        CommandRejectionCode::AttackerCannotAttack
    );

    let hidden = state(
        vec![unit(
            "attacker",
            &actor,
            UnitKind::Warrior,
            HexCoord::new(0, 0),
            None,
        )],
        Vec::new(),
        actor_fog(&actor, [HexCoord::new(0, 0)], [HexCoord::new(0, 0)]),
        Diplomacy::default(),
    );
    assert_eq!(
        rejection(&hidden, &actor, 11, &attacker_id, HexCoord::new(1, 0)),
        CommandRejectionCode::AttackTargetNotVisible
    );
    assert_eq!(
        rejection(
            &worker_to_warrior(&worker, &actor),
            &actor,
            11,
            &attacker_id,
            HexCoord::new(1, 0)
        ),
        CommandRejectionCode::AttackTargetNotFound
    );
}

#[test]
fn friendly_targets_are_rejected_before_range() {
    let actor = player("player_1");
    let attacker_id = unit_id("attacker");
    let friendly_target = state(
        vec![
            unit(
                "attacker",
                &actor,
                UnitKind::Warrior,
                HexCoord::new(0, 0),
                None,
            ),
            unit(
                "friendly",
                &actor,
                UnitKind::Warrior,
                HexCoord::new(3, 2),
                None,
            ),
        ],
        Vec::new(),
        FogOfWar::default(),
        Diplomacy::default(),
    );
    assert_eq!(
        rejection(
            &friendly_target,
            &actor,
            11,
            &attacker_id,
            HexCoord::new(3, 2)
        ),
        CommandRejectionCode::AttackTargetNotEnemy
    );

    let friendly_city = state(
        vec![unit(
            "attacker",
            &actor,
            UnitKind::Warrior,
            HexCoord::new(0, 0),
            None,
        )],
        vec![city("friendly-city", &actor, HexCoord::new(1, 0), None)],
        FogOfWar::default(),
        Diplomacy::default(),
    );
    assert_eq!(
        rejection(
            &friendly_city,
            &actor,
            11,
            &attacker_id,
            HexCoord::new(1, 0)
        ),
        CommandRejectionCode::AttackTargetNotEnemy
    );
}

#[test]
fn treaty_is_rejected_before_range() {
    let actor = player("player_1");
    let defender = player("player_2");
    let attacker_id = unit_id("attacker");
    let identity = identity();
    let pair = PlayerPair::new(actor.clone(), defender.clone()).expect("pair");
    let relation = DiplomaticRelation::try_new(
        pair.clone(),
        DiplomaticRelationStatus::Friendly,
        10,
        None,
        None,
        None,
    )
    .expect("relation");
    let diplomacy =
        Diplomacy::try_new(&identity, [pair], [relation], [], [], [], []).expect("diplomacy");
    let protected = state_with_identity(
        identity,
        vec![
            unit(
                "attacker",
                &actor,
                UnitKind::Warrior,
                HexCoord::new(0, 0),
                None,
            ),
            unit(
                "defender",
                &defender,
                UnitKind::Warrior,
                HexCoord::new(3, 2),
                None,
            ),
        ],
        Vec::new(),
        FogOfWar::default(),
        diplomacy,
        CombatState::default(),
    );
    assert_eq!(
        rejection(&protected, &actor, 11, &attacker_id, HexCoord::new(3, 2)),
        CommandRejectionCode::AttackTargetProtectedByTreaty
    );

    let distant = state(
        vec![
            unit(
                "attacker",
                &actor,
                UnitKind::Warrior,
                HexCoord::new(0, 0),
                None,
            ),
            unit(
                "defender",
                &defender,
                UnitKind::Warrior,
                HexCoord::new(3, 2),
                None,
            ),
        ],
        Vec::new(),
        FogOfWar::default(),
        Diplomacy::default(),
    );
    assert_eq!(
        rejection(&distant, &actor, 11, &attacker_id, HexCoord::new(3, 2)),
        CommandRejectionCode::AttackTargetOutOfRange
    );
}

fn rejection(
    state: &GameState,
    actor: &PlayerId,
    revision: u64,
    attacker: &UnitId,
    target: HexCoord,
) -> CommandRejectionCode {
    let map = map();
    let context = EngineContext::canonical(actor, &map, RulesetDefinition::standard());
    let error = GameEngine::query(
        state,
        context,
        GameQuery::CombatPreview(CombatPreviewQuery::new(revision, attacker, target)),
    )
    .expect_err("rejection");
    let aonw_engine::CanonicalQueryError::Combat(code) = error else {
        panic!("combat rejection")
    };
    code
}

fn worker_to_warrior(state: &GameState, actor: &PlayerId) -> GameState {
    state_with_identity(
        state.match_lifecycle().identity().clone(),
        vec![unit(
            "attacker",
            actor,
            UnitKind::Warrior,
            HexCoord::new(0, 0),
            None,
        )],
        Vec::new(),
        FogOfWar::default(),
        Diplomacy::default(),
        CombatState::default(),
    )
}
