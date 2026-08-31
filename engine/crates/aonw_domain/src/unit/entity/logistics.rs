use crate::{HexCoord, MovementUnits, QueuedMovePath, UnitPosture};

use super::{ArmyTroop, MerchantTradeRoute, TroopKind, Unit, UnitBuildError};

impl Unit {
    /// Applies movement performed by persistent automation.
    ///
    /// # Errors
    ///
    /// Returns an error when a retained path does not start at the destination.
    pub fn after_automated_movement(
        &self,
        position: HexCoord,
        movement_units: MovementUnits,
        queued_path: Option<QueuedMovePath>,
        posture: UnitPosture,
    ) -> Result<Self, UnitBuildError> {
        let mut updated = self.after_movement(position, movement_units, queued_path)?;
        updated.posture = posture;
        Ok(updated)
    }

    /// Starts auto-exploration and clears a stale manual route.
    #[must_use]
    pub fn after_auto_explore_started(&self) -> Self {
        let mut updated = self.clone();
        updated.queued_path = None;
        updated.merchant_trade_route = None;
        updated.posture = UnitPosture::AutoExploring;
        updated
    }

    /// Finishes auto-exploration when no further target exists.
    #[must_use]
    pub fn after_auto_explore_finished(&self) -> Self {
        let mut updated = self.clone();
        updated.queued_path = None;
        updated.posture = UnitPosture::Active;
        updated
    }

    /// Assigns one persistent merchant route and clears manual travel.
    #[must_use]
    pub fn after_merchant_route_assigned(&self, route: MerchantTradeRoute) -> Self {
        let mut updated = self.clone();
        updated.queued_path = None;
        updated.merchant_trade_route = Some(route);
        updated.posture = UnitPosture::Active;
        updated
    }

    /// Queues explicit merchant travel and clears cyclic trade routing.
    ///
    /// # Errors
    ///
    /// Returns an error when the route does not start at the unit position.
    pub fn after_merchant_travel_queued(
        &self,
        path: QueuedMovePath,
    ) -> Result<Self, UnitBuildError> {
        let mut updated = self.clone();
        updated.queued_path = Some(path);
        updated.merchant_trade_route = None;
        updated.posture = UnitPosture::Active;
        super::validate_queued_path_origin(updated.position, updated.queued_path.as_ref())?;
        Ok(updated)
    }

    /// Removes an invalidated merchant route without changing other state.
    #[must_use]
    pub fn without_merchant_route(&self) -> Self {
        let mut updated = self.clone();
        updated.merchant_trade_route = None;
        updated
    }

    /// Removes an invalidated queued route without changing other state.
    #[must_use]
    pub fn without_queued_path(&self) -> Self {
        let mut updated = self.clone();
        updated.queued_path = None;
        updated
    }

    /// Removes exactly one troop of the requested kind from this army.
    #[must_use]
    pub fn after_troop_detached(&self, kind: TroopKind) -> Option<Self> {
        let mut army = self.army.to_vec();
        let troop = army.iter_mut().find(|troop| troop.kind() == kind)?;
        let remaining = troop.count().checked_sub(1)?;
        *troop = ArmyTroop::new(kind, remaining);
        army.retain(|troop| troop.count() > 0);
        let mut updated = self.clone();
        updated.army = army.into_boxed_slice();
        Some(updated)
    }
}
