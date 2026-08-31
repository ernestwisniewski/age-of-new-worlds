use aonw_domain::{CityId, HexCoord, MovementStep, MovementUnits, TroopKind, UnitId};
use aonw_engine::{
    CombatExecution, CombatModifier, CombatModifierKind, CombatOutcome, CombatPreview, CombatRoll,
    CombatStatTarget, CombatTarget, EffectiveCombatStats, ExecutionEvidence, LogisticsExecution,
};

use super::encode_evidence;

#[test]
fn replay_encoder_maps_every_logistics_evidence_variant() {
    let unit_id = UnitId::new("unit-1").expect("unit id");
    let detached_id = UnitId::new("unit-2").expect("unit id");
    let origin_city_id = CityId::new("city-1").expect("city id");
    let destination_city_id = CityId::new("city-2").expect("city id");
    let step = MovementStep::new(
        HexCoord::new(1, 0),
        MovementUnits::new(2),
        MovementUnits::new(2),
    );
    let executions = [
        LogisticsExecution::AutoExplore {
            unit_id: unit_id.clone(),
            target: HexCoord::new(1, 0),
            movement: None,
        },
        LogisticsExecution::MerchantRouteAssigned {
            unit_id: unit_id.clone(),
            origin_city_id,
            destination_city_id: destination_city_id.clone(),
            steps: vec![step].into_boxed_slice(),
            transport_network_fingerprint: "network".into(),
        },
        LogisticsExecution::MerchantTravelQueued {
            unit_id: unit_id.clone(),
            destination_city_id,
            steps: vec![step].into_boxed_slice(),
        },
        LogisticsExecution::TroopDetached {
            source_unit_id: unit_id,
            detached_unit_id: detached_id,
            troop_kind: TroopKind::Archer,
            destination: HexCoord::new(0, 1),
        },
    ];
    for execution in executions {
        let _ = encode_evidence(&ExecutionEvidence::Logistics(execution));
    }
}

#[test]
fn replay_encoder_maps_every_combat_modifier_and_stat_target() {
    let modifiers = [
        (CombatModifierKind::Terrain, CombatStatTarget::Attack),
        (CombatModifierKind::Fortification, CombatStatTarget::Defense),
        (CombatModifierKind::Technology, CombatStatTarget::HitPoints),
        (CombatModifierKind::Counter, CombatStatTarget::Attack),
        (
            CombatModifierKind::TroopComposition,
            CombatStatTarget::Defense,
        ),
        (CombatModifierKind::Veterancy, CombatStatTarget::HitPoints),
    ]
    .into_iter()
    .enumerate()
    .map(|(index, (kind, target))| CombatModifier {
        kind,
        label: format!("modifier-{index}").into(),
        target,
        delta: 1,
    })
    .collect::<Vec<_>>()
    .into_boxed_slice();
    let stats = EffectiveCombatStats {
        attack: 4,
        defense: 3,
        hit_points: 8,
        range: 2,
        mobility: 2,
        modifiers,
    };
    let execution = CombatExecution {
        seed: 7,
        rolls: vec![CombatRoll { value: 1 }].into_boxed_slice(),
        preview: CombatPreview {
            attacker_unit_id: UnitId::new("attacker").expect("unit id"),
            target: CombatTarget::City(CityId::new("city").expect("city id")),
            distance: 2,
            attacker: stats.clone(),
            defender: stats,
            outgoing_damage: (1, 5),
            retaliation_damage: Some((1, 2)),
        },
        outcome: CombatOutcome {
            attacker_hit_points: 5,
            defender_hit_points: 2,
            attacker_killed: false,
            defender_killed: false,
            defender_retreat: Some(HexCoord::new(2, 0)),
            outgoing_damage: 3,
            retaliation_damage: 1,
        },
    };
    let _ = encode_evidence(&ExecutionEvidence::Combat(execution));
}
