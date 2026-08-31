use crate::{CityId, FieldImprovementKind, HexCoord, MovementUnits, PlayerId, Unit, UnitId};

/// Draft territory selected while founding a city.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CityFoundingDraft {
    unit_id: UnitId,
    owner_player_id: PlayerId,
    center: HexCoord,
    controlled_hexes: Box<[HexCoord]>,
}

impl CityFoundingDraft {
    /// Creates a draft from validated identifiers and coordinates.
    #[must_use]
    pub fn new(
        unit_id: UnitId,
        owner_player_id: PlayerId,
        center: HexCoord,
        controlled_hexes: impl IntoIterator<Item = HexCoord>,
    ) -> Self {
        Self {
            unit_id,
            owner_player_id,
            center,
            controlled_hexes: controlled_hexes.into_iter().collect(),
        }
    }

    /// Returns the founding unit.
    #[must_use]
    pub const fn unit_id(&self) -> &UnitId {
        &self.unit_id
    }

    /// Returns the owning player.
    #[must_use]
    pub const fn owner_player_id(&self) -> &PlayerId {
        &self.owner_player_id
    }

    /// Returns the planned center.
    #[must_use]
    pub const fn center(&self) -> HexCoord {
        self.center
    }

    /// Returns selected controlled coordinates.
    #[must_use]
    pub const fn controlled_hexes(&self) -> &[HexCoord] {
        &self.controlled_hexes
    }
}

/// Rule-relevant pending client action.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum PendingInteraction {
    /// Technology selection with no unit ownership.
    ResearchSelection { owner_player_id: PlayerId },
    /// Worked-hex selection for a city.
    CityWorkedHexSelection {
        owner_player_id: PlayerId,
        city_id: CityId,
    },
    /// Expansion-hex selection for a city.
    CityExpansionSelection {
        owner_player_id: PlayerId,
        city_id: CityId,
    },
    /// Worker action selection.
    WorkerActionSelection {
        owner_player_id: PlayerId,
        unit_id: UnitId,
        improvement: Option<FieldImprovementKind>,
    },
    /// Merchant trade-route selection.
    MerchantTradeRouteSelection {
        owner_player_id: PlayerId,
        unit_id: UnitId,
    },
    /// Merchant destination-city selection.
    MerchantMoveToCitySelection {
        owner_player_id: PlayerId,
        unit_id: UnitId,
    },
    /// Reversible current-turn movement skip.
    UnitTurnSkip {
        owner_player_id: PlayerId,
        unit_id: UnitId,
        restore_movement: MovementUnits,
    },
    /// Attack target selection.
    AttackTargeting {
        owner_player_id: PlayerId,
        unit_id: UnitId,
        defender: Option<HexCoord>,
    },
    /// Commander merge selection.
    CommanderMergeSelection {
        owner_player_id: PlayerId,
        unit_id: UnitId,
    },
}

impl PendingInteraction {
    /// Returns the owning player.
    #[must_use]
    pub const fn owner_player_id(&self) -> &PlayerId {
        match self {
            Self::ResearchSelection { owner_player_id }
            | Self::CityWorkedHexSelection {
                owner_player_id, ..
            }
            | Self::CityExpansionSelection {
                owner_player_id, ..
            }
            | Self::WorkerActionSelection {
                owner_player_id, ..
            }
            | Self::MerchantTradeRouteSelection {
                owner_player_id, ..
            }
            | Self::MerchantMoveToCitySelection {
                owner_player_id, ..
            }
            | Self::UnitTurnSkip {
                owner_player_id, ..
            }
            | Self::AttackTargeting {
                owner_player_id, ..
            }
            | Self::CommanderMergeSelection {
                owner_player_id, ..
            } => owner_player_id,
        }
    }

    /// Returns the unit owning the interaction when applicable.
    #[must_use]
    pub const fn unit_id(&self) -> Option<&UnitId> {
        match self {
            Self::ResearchSelection { .. }
            | Self::CityWorkedHexSelection { .. }
            | Self::CityExpansionSelection { .. } => None,
            Self::WorkerActionSelection { unit_id, .. }
            | Self::MerchantTradeRouteSelection { unit_id, .. }
            | Self::MerchantMoveToCitySelection { unit_id, .. }
            | Self::UnitTurnSkip { unit_id, .. }
            | Self::AttackTargeting { unit_id, .. }
            | Self::CommanderMergeSelection { unit_id, .. } => Some(unit_id),
        }
    }

    /// Returns the movement restored by a matching turn skip.
    #[must_use]
    pub fn turn_skip_restore(&self, unit_id: &UnitId) -> Option<MovementUnits> {
        match self {
            Self::UnitTurnSkip {
                unit_id: skipped,
                restore_movement,
                ..
            } if skipped == unit_id => Some(*restore_movement),
            _ => None,
        }
    }
}

/// Canonical interaction state that participates in command rules.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct InteractionState {
    city_founding_draft: Option<CityFoundingDraft>,
    pending: Option<PendingInteraction>,
}

impl InteractionState {
    /// Creates interaction state from its current slices.
    #[must_use]
    pub const fn new(
        city_founding_draft: Option<CityFoundingDraft>,
        pending: Option<PendingInteraction>,
    ) -> Self {
        Self {
            city_founding_draft,
            pending,
        }
    }

    /// Returns the city founding draft.
    #[must_use]
    pub const fn city_founding_draft(&self) -> Option<&CityFoundingDraft> {
        self.city_founding_draft.as_ref()
    }

    /// Returns the pending interaction.
    #[must_use]
    pub const fn pending(&self) -> Option<&PendingInteraction> {
        self.pending.as_ref()
    }

    /// Returns movement retained by a matching pending skip.
    #[must_use]
    pub fn turn_skip_restore(&self, unit_id: &UnitId) -> Option<MovementUnits> {
        self.pending
            .as_ref()
            .and_then(|pending| pending.turn_skip_restore(unit_id))
    }

    /// Clears interaction slices owned by a unit.
    #[must_use]
    pub fn without_unit(mut self, unit_id: &UnitId) -> Self {
        if self
            .city_founding_draft
            .as_ref()
            .is_some_and(|draft| draft.unit_id() == unit_id)
        {
            self.city_founding_draft = None;
        }
        if self.pending.as_ref().and_then(PendingInteraction::unit_id) == Some(unit_id) {
            self.pending = None;
        }
        self
    }

    /// Replaces the canonical city-founding draft.
    #[must_use]
    pub fn with_city_founding_draft(mut self, draft: Option<CityFoundingDraft>) -> Self {
        self.city_founding_draft = draft;
        self
    }

    /// Replaces the current pending interaction.
    #[must_use]
    pub fn with_pending(mut self, pending: Option<PendingInteraction>) -> Self {
        self.pending = pending;
        self
    }

    /// Replaces the pending interaction with a reversible unit skip.
    #[must_use]
    pub fn after_skip(mut self, unit: &Unit) -> Self {
        if self
            .city_founding_draft
            .as_ref()
            .is_some_and(|draft| draft.unit_id() == unit.id())
        {
            self.city_founding_draft = None;
        }
        self.pending = Some(PendingInteraction::UnitTurnSkip {
            owner_player_id: unit.owner_player_id().clone(),
            unit_id: unit.id().clone(),
            restore_movement: unit.movement_units(),
        });
        self
    }

    /// Expires a reversible skip when its owner begins a new turn.
    #[must_use]
    pub fn expire_turn_skip_for(
        mut self,
        player_ids: &std::collections::BTreeSet<PlayerId>,
    ) -> Self {
        if self.pending.as_ref().is_some_and(|pending| {
            matches!(pending, PendingInteraction::UnitTurnSkip { .. })
                && player_ids.contains(pending.owner_player_id())
        }) {
            self.pending = None;
        }
        self
    }
}
