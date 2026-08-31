use serde::{Deserialize, Serialize};

use crate::CoordinateDto;

/// Visible combat target identity.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum CombatTargetDto {
    Unit { unit_id: String },
    City { city_id: String },
}

/// Combat statistic affected by a modifier.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum CombatStatTargetDto {
    Attack,
    Defense,
    HitPoints,
}

/// Typed modifier source.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum CombatModifierKindDto {
    Terrain,
    Fortification,
    Technology,
    Counter,
    TroopComposition,
    Veterancy,
}

/// One exact ordered combat modifier.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct CombatModifierDto {
    /// Source category.
    pub kind: CombatModifierKindDto,
    /// Stable engine-owned label.
    pub label: String,
    /// Affected statistic.
    pub target: CombatStatTargetDto,
    /// Signed delta.
    pub delta: i32,
}

/// Effective combat statistics.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct CombatStatsDto {
    /// Attack strength.
    pub attack: i32,
    /// Defense strength.
    pub defense: i32,
    /// Maximum hit points.
    pub hit_points: u32,
    /// Attack range.
    pub range: u32,
    /// Retreat mobility.
    pub mobility: u32,
    /// Ordered applied modifiers.
    pub modifiers: Vec<CombatModifierDto>,
}

/// Recipient-safe preview without seed or random rolls.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct CombatPreviewDto {
    /// Attacking unit.
    pub attacker_unit_id: String,
    /// Visible target.
    pub target: CombatTargetDto,
    /// Hex distance.
    pub distance: u32,
    /// Effective attacker statistics.
    pub attacker: CombatStatsDto,
    /// Effective defender statistics.
    pub defender: CombatStatsDto,
    /// Inclusive outgoing damage bounds.
    pub outgoing_damage_min: u32,
    /// Inclusive outgoing damage bounds.
    pub outgoing_damage_max: u32,
    /// Inclusive retaliation damage bounds when retaliation is possible.
    pub retaliation_damage_min: Option<u32>,
    /// Inclusive retaliation damage bounds when retaliation is possible.
    pub retaliation_damage_max: Option<u32>,
}

/// One signed deterministic combat roll.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct CombatRollDto {
    /// Signed roll value consumed by combat resolution.
    pub value: i32,
}

/// Exact resolved combat result.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct CombatOutcomeDto {
    /// Attacker health after combat.
    pub attacker_hit_points: i32,
    /// Defender health after combat.
    pub defender_hit_points: i32,
    /// Whether the attacker was removed.
    pub attacker_killed: bool,
    /// Whether the defender was defeated.
    pub defender_killed: bool,
    /// Defender retreat destination.
    pub defender_retreat: Option<CoordinateDto>,
    /// Outgoing damage.
    pub outgoing_damage: u32,
    /// Retaliation damage.
    pub retaliation_damage: u32,
}

/// Exact combat evidence persisted and exposed to current clients.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct CombatExecutionDto {
    /// Initial deterministic seed.
    pub seed: u32,
    /// Rolls in consumption order.
    pub rolls: Vec<CombatRollDto>,
    /// Exact shared preview input.
    pub preview: CombatPreviewDto,
    /// Exact outcome.
    pub outcome: CombatOutcomeDto,
}
