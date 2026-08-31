use std::collections::BTreeSet;

use crate::{HexCoord, HexGridBounds, MatchIdentity, PlayerId, StateRevision, Unit, UnitId};

/// Requested disposition of a defeated city.
#[derive(Clone, Copy, Debug, Default, Eq, Hash, PartialEq)]
pub enum CityConquestAction {
    /// Transfer the city to the attacker.
    #[default]
    Capture,
    /// Remove the defeated city.
    Destroy,
}

/// One persisted simultaneous-combat declaration.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct IntendedAttack {
    attacker_unit_id: UnitId,
    defender: HexCoord,
    declared_at_tick: StateRevision,
    declaring_player_id: PlayerId,
    city_conquest_action: CityConquestAction,
}

impl IntendedAttack {
    /// Constructs one typed combat declaration.
    #[must_use]
    pub const fn new(
        attacker_unit_id: UnitId,
        defender: HexCoord,
        declared_at_tick: StateRevision,
        declaring_player_id: PlayerId,
        city_conquest_action: CityConquestAction,
    ) -> Self {
        Self {
            attacker_unit_id,
            defender,
            declared_at_tick,
            declaring_player_id,
            city_conquest_action,
        }
    }

    /// Returns the attacking unit identity.
    #[must_use]
    pub const fn attacker_unit_id(&self) -> &UnitId {
        &self.attacker_unit_id
    }
    /// Returns the target coordinate.
    #[must_use]
    pub const fn defender(&self) -> HexCoord {
        self.defender
    }
    /// Returns the host-provided declaration tick.
    #[must_use]
    pub const fn declared_at_tick(&self) -> StateRevision {
        self.declared_at_tick
    }
    /// Returns the player who declared the attack.
    #[must_use]
    pub const fn declaring_player_id(&self) -> &PlayerId {
        &self.declaring_player_id
    }
    /// Returns the requested city disposition.
    #[must_use]
    pub const fn city_conquest_action(&self) -> CityConquestAction {
        self.city_conquest_action
    }
}

/// Canonical pending combat declarations in attacker-identifier order.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct CombatState {
    intended_attacks: Box<[IntendedAttack]>,
}

impl CombatState {
    /// Validates that one unit has at most one pending declaration.
    ///
    /// # Errors
    ///
    /// Returns the duplicated attacker identity.
    pub fn try_new(
        intended_attacks: impl IntoIterator<Item = IntendedAttack>,
    ) -> Result<Self, UnitId> {
        let mut intended_attacks = intended_attacks.into_iter().collect::<Vec<_>>();
        intended_attacks
            .sort_unstable_by(|left, right| left.attacker_unit_id().cmp(right.attacker_unit_id()));
        let mut attackers = BTreeSet::new();
        for attack in &intended_attacks {
            if !attackers.insert(attack.attacker_unit_id().clone()) {
                return Err(attack.attacker_unit_id().clone());
            }
        }
        Ok(Self {
            intended_attacks: intended_attacks.into_boxed_slice(),
        })
    }

    /// Returns declarations in attacker-identifier order.
    #[must_use]
    pub const fn intended_attacks(&self) -> &[IntendedAttack] {
        &self.intended_attacks
    }

    /// Validates map, participant and attacker ownership references.
    ///
    /// # Errors
    ///
    /// Returns the first invalid declaration reference.
    pub fn validate_for(
        &self,
        identity: &MatchIdentity,
        bounds: HexGridBounds,
        units: &[Unit],
    ) -> Result<(), CombatStateValidationError> {
        for attack in &self.intended_attacks {
            if !bounds.contains(attack.defender()) {
                return Err(CombatStateValidationError::TargetOutOfBounds {
                    attacker_unit_id: attack.attacker_unit_id().clone(),
                    defender: attack.defender(),
                });
            }
            if !identity.contains(attack.declaring_player_id()) {
                return Err(CombatStateValidationError::PlayerNotFound(
                    attack.declaring_player_id().clone(),
                ));
            }
            let Some(attacker) = units
                .iter()
                .find(|unit| unit.id() == attack.attacker_unit_id())
            else {
                return Err(CombatStateValidationError::AttackerNotFound(
                    attack.attacker_unit_id().clone(),
                ));
            };
            if attacker.owner_player_id() != attack.declaring_player_id() {
                return Err(CombatStateValidationError::AttackerOwnerMismatch(
                    attack.attacker_unit_id().clone(),
                ));
            }
        }
        Ok(())
    }
}

/// Cross-section pending-combat validation failure.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum CombatStateValidationError {
    /// A target coordinate is outside the logical map.
    TargetOutOfBounds {
        /// Attacker carrying the invalid target.
        attacker_unit_id: UnitId,
        /// Target outside logical bounds.
        defender: HexCoord,
    },
    /// A declaration names a non-participant player.
    PlayerNotFound(PlayerId),
    /// A declaration names an absent attacker.
    AttackerNotFound(UnitId),
    /// A declaration is attributed to a player other than the attacker owner.
    AttackerOwnerMismatch(UnitId),
}

impl core::fmt::Display for CombatStateValidationError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::TargetOutOfBounds {
                attacker_unit_id,
                defender,
            } => write!(
                formatter,
                "attack by {attacker_unit_id} targets ({}, {}) outside the map",
                defender.col(),
                defender.row()
            ),
            Self::PlayerNotFound(player) => {
                write!(formatter, "attack references non-participant {player}")
            }
            Self::AttackerNotFound(unit) => {
                write!(formatter, "attack references missing unit {unit}")
            }
            Self::AttackerOwnerMismatch(unit) => write!(
                formatter,
                "attack declaring player does not own unit {unit}"
            ),
        }
    }
}

impl std::error::Error for CombatStateValidationError {}
