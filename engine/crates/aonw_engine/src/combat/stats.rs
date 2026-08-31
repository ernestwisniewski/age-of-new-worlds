use aonw_content::{RulesetDefinition, TerrainType};
use aonw_domain::{City, GameState, TroopKind, Unit, UnitKind, WorldArtifactLocation};

use crate::{
    TechnologyCombatStat, TechnologyUnlockQuery,
    combat::model::{CombatModifier, CombatModifierKind, CombatStatTarget, EffectiveCombatStats},
};

#[derive(Clone, Copy)]
pub(super) struct UnitCombatSituation<'state> {
    pub opponent: Option<&'state Unit>,
    pub defended_city: Option<&'state City>,
    pub attacker: bool,
    pub terrain_tags: &'state [TerrainType],
    pub opponent_terrain_tags: &'state [TerrainType],
}

pub(super) fn for_unit(
    state: &GameState,
    ruleset: &RulesetDefinition,
    unit: &Unit,
    situation: UnitCombatSituation<'_>,
) -> Option<EffectiveCombatStats> {
    let definition = ruleset.unit(unit.kind())?;
    let base = definition.combat();
    let (mut base_attack, mut base_defense, mut base_hit_points) =
        (base.attack(), base.defense(), base.hit_points());
    if unit.kind() == UnitKind::Commander {
        for troop in unit.army() {
            let troop_stats = match troop.kind() {
                TroopKind::Warrior => (2, 2, 3),
                TroopKind::Archer => (2, 1, 2),
                TroopKind::Settler => (0, 1, 1),
            };
            let count = troop.count();
            base_attack += troop_stats.0 * i32::try_from(count).ok()?;
            base_defense += troop_stats.1 * i32::try_from(count).ok()?;
            base_hit_points = base_hit_points.checked_add(troop_stats.2 * count)?;
        }
    }
    let mut modifiers = Vec::new();
    terrain_modifiers(situation.terrain_tags, &mut modifiers);
    counter_modifiers(
        unit,
        situation.opponent,
        situation.attacker,
        situation.terrain_tags,
        situation.opponent_terrain_tags,
        &mut modifiers,
    );
    if let Some(city) = situation.defended_city {
        push(
            &mut modifiers,
            CombatModifierKind::Fortification,
            &format!("city.{}.garrison", city.id().as_str()),
            CombatStatTarget::Defense,
            ruleset.combat().defended_city_unit_defense_bonus(),
        );
    }
    technology_modifiers(
        state,
        ruleset,
        unit,
        base_attack,
        situation.defended_city.is_some(),
        &mut modifiers,
    )?;
    if definition.capabilities().gains_experience() {
        veterancy_modifiers(unit, &mut modifiers);
    }
    if unit.kind() == UnitKind::Commander
        && unit
            .army()
            .iter()
            .any(|troop| troop.kind() == TroopKind::Warrior)
        && unit
            .army()
            .iter()
            .any(|troop| troop.kind() == TroopKind::Archer)
    {
        push(
            &mut modifiers,
            CombatModifierKind::TroopComposition,
            "troop.mixedCommanderArmy",
            CombatStatTarget::Attack,
            ruleset.combat().mixed_commander_army_attack_bonus(),
        );
    }
    Some(apply(
        base_attack,
        base_defense,
        base_hit_points,
        base.range(),
        base.mobility(),
        modifiers,
    ))
}

pub(super) fn for_city(
    state: &GameState,
    ruleset: &RulesetDefinition,
    city: &City,
) -> Option<EffectiveCombatStats> {
    let base = ruleset.combat().city();
    let artifact_defense = state
        .artifacts()
        .iter()
        .filter(|artifact| {
            matches!(artifact.location(), WorldArtifactLocation::Stored(id) if id == city.id())
        })
        .map(|artifact| artifact.artifact_type().stored_city_defense_bonus())
        .try_fold(0_i32, i32::checked_add)?;
    let hit_points = i64::from(base.hit_points()).checked_add(i64::from(artifact_defense))?;
    Some(apply(
        base.attack(),
        base.defense().checked_add(artifact_defense)?,
        u32::try_from(hit_points).ok()?,
        base.range(),
        base.mobility(),
        Vec::new(),
    ))
}

fn technology_modifiers(
    state: &GameState,
    ruleset: &RulesetDefinition,
    unit: &Unit,
    base_attack: i32,
    defended_city: bool,
    modifiers: &mut Vec<CombatModifier>,
) -> Option<()> {
    let Some(research) = state.research().players().get(unit.owner_player_id()) else {
        return Some(());
    };
    let army_unit = ruleset.unit(unit.kind())?.capabilities().military();
    for modifier in TechnologyUnlockQuery::new(ruleset, research)
        .combat_modifiers(base_attack, army_unit, defended_city)
        .ok()?
    {
        push(
            modifiers,
            CombatModifierKind::Technology,
            &modifier.label,
            technology_target(modifier.target),
            modifier.delta,
        );
    }
    Some(())
}

const fn technology_target(value: TechnologyCombatStat) -> CombatStatTarget {
    match value {
        TechnologyCombatStat::Attack => CombatStatTarget::Attack,
        TechnologyCombatStat::Defense => CombatStatTarget::Defense,
        TechnologyCombatStat::HitPoints => CombatStatTarget::HitPoints,
    }
}

fn terrain_modifiers(tags: &[TerrainType], modifiers: &mut Vec<CombatModifier>) {
    for terrain in tags {
        let defense = match terrain {
            TerrainType::Forest
            | TerrainType::Jungle
            | TerrainType::Hills
            | TerrainType::Wetlands
            | TerrainType::River => 1,
            TerrainType::Mountain => 2,
            TerrainType::Desert => -1,
            _ => 0,
        };
        push(
            modifiers,
            CombatModifierKind::Terrain,
            &format!("terrain.{}.defense", terrain.as_str()),
            CombatStatTarget::Defense,
            defense,
        );
    }
}

fn counter_modifiers(
    unit: &Unit,
    opponent: Option<&Unit>,
    attacker: bool,
    unit_tags: &[TerrainType],
    opponent_tags: &[TerrainType],
    modifiers: &mut Vec<CombatModifier>,
) {
    let Some(opponent) = opponent else {
        return;
    };
    if unit.kind() == UnitKind::Spearman
        && matches!(opponent.kind(), UnitKind::Cavalry | UnitKind::Tank)
    {
        push(
            modifiers,
            CombatModifierKind::Counter,
            if attacker {
                "counter.spearmanVsMounted.attack"
            } else {
                "counter.spearmanVsMounted.defense"
            },
            if attacker {
                CombatStatTarget::Attack
            } else {
                CombatStatTarget::Defense
            },
            if attacker { 2 } else { 3 },
        );
    }
    if !attacker && unit.kind() == UnitKind::Archer && defensive(unit_tags) {
        push(
            modifiers,
            CombatModifierKind::Counter,
            "counter.archerDefensiveTerrain.defense",
            CombatStatTarget::Defense,
            2,
        );
    }
    if attacker && unit.kind() == UnitKind::Cavalry && rough(opponent_tags) {
        push(
            modifiers,
            CombatModifierKind::Counter,
            "counter.cavalryRoughAttack.attack",
            CombatStatTarget::Attack,
            -2,
        );
    }
    if attacker
        && unit.kind() == UnitKind::Cavalry
        && open(opponent_tags)
        && matches!(
            opponent.kind(),
            UnitKind::Settler
                | UnitKind::Worker
                | UnitKind::Merchant
                | UnitKind::Scout
                | UnitKind::Catapult
        )
    {
        push(
            modifiers,
            CombatModifierKind::Counter,
            "counter.cavalryOpenRaid.attack",
            CombatStatTarget::Attack,
            2,
        );
    }
    if attacker
        && unit.kind() == UnitKind::HeavyInfantry
        && matches!(
            opponent.kind(),
            UnitKind::Warrior | UnitKind::Spearman | UnitKind::Rifleman
        )
    {
        push(
            modifiers,
            CombatModifierKind::Counter,
            "counter.heavyInfantryBreakthrough.attack",
            CombatStatTarget::Attack,
            2,
        );
    }
}

fn veterancy_modifiers(unit: &Unit, modifiers: &mut Vec<CombatModifier>) {
    let (attack, defense, hp, rank) = match unit.experience_points() {
        0..=2 => (0, 0, 0, "recruit"),
        3..=6 => (1, 0, 0, "seasoned"),
        7..=11 => (1, 1, 0, "veteran"),
        _ => (2, 1, 2, "elite"),
    };
    push(
        modifiers,
        CombatModifierKind::Veterancy,
        &format!("veterancy.{rank}.attack"),
        CombatStatTarget::Attack,
        attack,
    );
    push(
        modifiers,
        CombatModifierKind::Veterancy,
        &format!("veterancy.{rank}.defense"),
        CombatStatTarget::Defense,
        defense,
    );
    push(
        modifiers,
        CombatModifierKind::Veterancy,
        &format!("veterancy.{rank}.hp"),
        CombatStatTarget::HitPoints,
        hp,
    );
}

fn push(
    modifiers: &mut Vec<CombatModifier>,
    kind: CombatModifierKind,
    label: &str,
    target: CombatStatTarget,
    delta: i32,
) {
    if delta != 0 {
        modifiers.push(CombatModifier {
            kind,
            label: label.into(),
            target,
            delta,
        });
    }
}

fn apply(
    mut attack: i32,
    mut defense: i32,
    hit_points: u32,
    range: u32,
    mobility: u32,
    modifiers: Vec<CombatModifier>,
) -> EffectiveCombatStats {
    let mut hp = i64::from(hit_points);
    for modifier in &modifiers {
        match modifier.target {
            CombatStatTarget::Attack => attack = attack.saturating_add(modifier.delta),
            CombatStatTarget::Defense => defense = defense.saturating_add(modifier.delta),
            CombatStatTarget::HitPoints => hp = hp.saturating_add(i64::from(modifier.delta)),
        }
    }
    EffectiveCombatStats {
        attack,
        defense,
        hit_points: u32::try_from(hp.max(1)).unwrap_or(u32::MAX),
        range,
        mobility,
        modifiers: modifiers.into_boxed_slice(),
    }
}

fn defensive(tags: &[TerrainType]) -> bool {
    tags.iter().any(|tag| {
        matches!(
            tag,
            TerrainType::Forest
                | TerrainType::Jungle
                | TerrainType::Hills
                | TerrainType::Wetlands
                | TerrainType::Mountain
        )
    })
}
fn rough(tags: &[TerrainType]) -> bool {
    defensive(tags)
}
fn open(tags: &[TerrainType]) -> bool {
    !rough(tags)
        && tags.iter().any(|tag| {
            matches!(
                tag,
                TerrainType::Plains
                    | TerrainType::Grassland
                    | TerrainType::Desert
                    | TerrainType::Tundra
                    | TerrainType::Snow
            )
        })
}

#[cfg(test)]
mod tests;
