use crate::{
    ArtifactId, HexCoord, MovementUnits, PlayerId, QueuedMovePath, UnitId, UnitKind, UnitPosture,
};

use super::CityFoundingJob;
use super::{ArmyTroop, MerchantTradeRoute, TroopKind, UnitActivity, WorkerJob};

mod artifact;
mod logistics;
mod worker;

const MAX_UNIT_NAME_BYTES: usize = 256;

/// Failure raised while constructing a canonical unit.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum UnitBuildError {
    /// The display name is blank.
    EmptyName,
    /// The display name exceeds the boundary limit.
    NameTooLong,
    /// A troop count is zero.
    EmptyTroop(TroopKind),
    /// More than one entry uses the same troop kind.
    DuplicateTroop(TroopKind),
    /// A queued path does not start at the unit position.
    QueuedPathOriginMismatch {
        /// Current unit position.
        expected: HexCoord,
        /// Origin embedded in the queued path.
        actual: HexCoord,
    },
    /// A job has an invalid remaining/total duration.
    InvalidJobDuration,
    /// Explicit combat hit points must be positive.
    ZeroHitPoints,
}

impl core::fmt::Display for UnitBuildError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::EmptyName => formatter.write_str("unit name must not be blank"),
            Self::NameTooLong => formatter.write_str("unit name exceeds 256 bytes"),
            Self::EmptyTroop(kind) => write!(formatter, "troop {kind:?} has zero count"),
            Self::DuplicateTroop(kind) => write!(formatter, "troop {kind:?} is duplicated"),
            Self::QueuedPathOriginMismatch { expected, actual } => write!(
                formatter,
                "queued path origin ({}, {}) does not match unit position ({}, {})",
                actual.col(),
                actual.row(),
                expected.col(),
                expected.row()
            ),
            Self::InvalidJobDuration => formatter.write_str("unit job duration is invalid"),
            Self::ZeroHitPoints => formatter.write_str("unit hit points must be positive"),
        }
    }
}

impl std::error::Error for UnitBuildError {}

/// Complete canonical unit entity.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Unit {
    id: UnitId,
    owner_player_id: PlayerId,
    kind: UnitKind,
    name: Box<str>,
    position: HexCoord,
    movement_units: MovementUnits,
    army: Box<[ArmyTroop]>,
    queued_path: Option<QueuedMovePath>,
    merchant_trade_route: Option<MerchantTradeRoute>,
    activity: UnitActivity,
    worker_build_charges: u32,
    hit_points: Option<u32>,
    experience_points: u32,
    posture: UnitPosture,
    carried_artifact_id: Option<ArtifactId>,
}

impl Unit {
    /// Starts a validated builder with required identity and movement fields.
    #[must_use]
    pub fn builder(
        id: UnitId,
        owner_player_id: PlayerId,
        kind: UnitKind,
        name: impl Into<Box<str>>,
        position: HexCoord,
        movement_units: MovementUnits,
    ) -> UnitBuilder {
        UnitBuilder {
            id,
            owner_player_id,
            kind,
            name: name.into(),
            position,
            movement_units,
            army: Vec::new(),
            queued_path: None,
            merchant_trade_route: None,
            activity: UnitActivity::default(),
            worker_build_charges: 0,
            hit_points: None,
            experience_points: 0,
            posture: UnitPosture::Active,
            carried_artifact_id: None,
        }
    }

    /// Returns the identifier.
    #[must_use]
    pub const fn id(&self) -> &UnitId {
        &self.id
    }
    /// Returns the owner.
    #[must_use]
    pub const fn owner_player_id(&self) -> &PlayerId {
        &self.owner_player_id
    }
    /// Returns the canonical kind.
    #[must_use]
    pub const fn kind(&self) -> UnitKind {
        self.kind
    }
    /// Returns the display name token or authored name.
    #[must_use]
    pub fn name(&self) -> &str {
        &self.name
    }
    /// Returns the map position.
    #[must_use]
    pub const fn position(&self) -> HexCoord {
        self.position
    }
    /// Returns current movement balance.
    #[must_use]
    pub const fn movement_units(&self) -> MovementUnits {
        self.movement_units
    }
    /// Returns army troops in canonical order.
    #[must_use]
    pub const fn army(&self) -> &[ArmyTroop] {
        &self.army
    }
    /// Returns the queued manual route.
    #[must_use]
    pub const fn queued_path(&self) -> Option<&QueuedMovePath> {
        self.queued_path.as_ref()
    }
    /// Returns the assigned merchant route.
    #[must_use]
    pub const fn merchant_trade_route(&self) -> Option<&MerchantTradeRoute> {
        self.merchant_trade_route.as_ref()
    }
    /// Returns concrete activity state.
    #[must_use]
    pub const fn activity(&self) -> &UnitActivity {
        &self.activity
    }
    /// Returns remaining worker construction charges.
    #[must_use]
    pub const fn worker_build_charges(&self) -> u32 {
        self.worker_build_charges
    }
    /// Returns explicit combat hit points when applicable.
    #[must_use]
    pub const fn hit_points(&self) -> Option<u32> {
        self.hit_points
    }
    /// Returns accumulated experience.
    #[must_use]
    pub const fn experience_points(&self) -> u32 {
        self.experience_points
    }
    /// Returns persistent posture.
    #[must_use]
    pub const fn posture(&self) -> UnitPosture {
        self.posture
    }
    /// Returns the carried artifact.
    #[must_use]
    pub const fn carried_artifact_id(&self) -> Option<&ArtifactId> {
        self.carried_artifact_id.as_ref()
    }

    /// Applies an authoritative movement result while preserving all unrelated fields.
    ///
    /// # Errors
    ///
    /// Returns an error when a retained path does not start at the destination.
    pub fn after_movement(
        &self,
        position: HexCoord,
        movement_units: MovementUnits,
        queued_path: Option<QueuedMovePath>,
    ) -> Result<Self, UnitBuildError> {
        let mut updated = self.clone();
        updated.position = position;
        updated.movement_units = movement_units;
        updated.queued_path = queued_path;
        updated.posture = UnitPosture::Active;
        validate_queued_path_origin(updated.position, updated.queued_path.as_ref())?;
        Ok(updated)
    }

    /// Clears all cancellable orders and wakes the unit.
    #[must_use]
    pub fn after_cancel_action(
        &self,
        maximum_movement: MovementUnits,
        skipped_movement_restore: Option<MovementUnits>,
    ) -> Self {
        let mut updated = self.clone();
        updated.movement_units = skipped_movement_restore.unwrap_or_else(|| {
            if self.posture == UnitPosture::Fortified {
                maximum_movement
            } else {
                self.movement_units
            }
        });
        updated.queued_path = None;
        updated.merchant_trade_route = None;
        updated.activity = UnitActivity::default();
        updated.posture = UnitPosture::Active;
        updated
    }

    /// Consumes current movement for a turn skip.
    #[must_use]
    pub fn after_skip_turn(&self) -> Self {
        let mut updated = self.clone();
        updated.movement_units = MovementUnits::ZERO;
        updated.queued_path = None;
        updated.posture = UnitPosture::Active;
        updated
    }

    /// Enters persistent fortification and clears manual movement orders.
    #[must_use]
    pub fn after_fortify(&self) -> Self {
        let mut updated = self.clone();
        updated.movement_units = MovementUnits::ZERO;
        updated.queued_path = None;
        updated.posture = UnitPosture::Fortified;
        updated
    }

    /// Resets movement at the start of a turn without running later automation.
    #[must_use]
    pub fn after_turn_movement_reset(&self, maximum_movement: MovementUnits) -> Self {
        let mut updated = self.clone();
        updated.movement_units =
            if self.posture == UnitPosture::Fortified || self.activity.blocks_manual_movement() {
                MovementUnits::ZERO
            } else {
                maximum_movement
            };
        if self.posture == UnitPosture::Fortified || self.activity.blocks_manual_movement() {
            updated.queued_path = None;
        }
        updated
    }

    /// Applies one authoritative combat result while preserving non-combat state.
    #[must_use]
    pub fn after_combat(
        &self,
        position: HexCoord,
        hit_points: Option<u32>,
        experience_points: u32,
        consume_movement: bool,
    ) -> Self {
        let mut updated = self.clone();
        updated.position = position;
        updated.hit_points = hit_points;
        updated.experience_points = experience_points;
        if consume_movement {
            updated.movement_units = MovementUnits::ZERO;
        }
        updated
    }

    /// Schedules or advances authoritative city-founding work.
    #[must_use]
    pub fn with_city_founding_job(&self, job: Option<CityFoundingJob>) -> Self {
        let mut updated = self.clone();
        updated.activity = updated.activity.with_city_founding_job(job);
        updated.queued_path = None;
        if updated.activity.city_founding_job().is_some() {
            updated.movement_units = MovementUnits::ZERO;
            updated.posture = UnitPosture::Active;
        }
        updated
    }

    /// Consumes one settler troop and clears completed city-founding work.
    ///
    /// Standalone settler units are removed by the aggregate processor and
    /// therefore return `None`. A non-founder or malformed commander also
    /// returns `None`; callers validate the pending job before committing.
    #[must_use]
    pub fn after_city_founded(&self) -> Option<Self> {
        if self.kind == UnitKind::Settler {
            return None;
        }
        let mut updated = self.clone();
        let index = updated
            .army
            .iter()
            .position(|troop| troop.kind() == TroopKind::Settler && troop.count() > 0)?;
        let troop = updated.army[index];
        let mut army = updated.army.into_vec();
        if troop.count() == 1 {
            army.remove(index);
        } else {
            army[index] = ArmyTroop::new(TroopKind::Settler, troop.count() - 1);
        }
        updated.army = army.into_boxed_slice();
        updated.activity = updated.activity.with_city_founding_job(None);
        updated.queued_path = None;
        Some(updated)
    }
}

/// Builder for the complete unit entity.
#[derive(Clone, Debug)]
pub struct UnitBuilder {
    id: UnitId,
    owner_player_id: PlayerId,
    kind: UnitKind,
    name: Box<str>,
    position: HexCoord,
    movement_units: MovementUnits,
    army: Vec<ArmyTroop>,
    queued_path: Option<QueuedMovePath>,
    merchant_trade_route: Option<MerchantTradeRoute>,
    activity: UnitActivity,
    worker_build_charges: u32,
    hit_points: Option<u32>,
    experience_points: u32,
    posture: UnitPosture,
    carried_artifact_id: Option<ArtifactId>,
}

impl UnitBuilder {
    /// Sets army troops.
    #[must_use]
    pub fn with_army(mut self, army: impl IntoIterator<Item = ArmyTroop>) -> Self {
        self.army = army.into_iter().collect();
        self
    }
    /// Sets the queued manual route.
    #[must_use]
    pub fn with_queued_path(mut self, path: Option<QueuedMovePath>) -> Self {
        self.queued_path = path;
        self
    }
    /// Sets the merchant route.
    #[must_use]
    pub fn with_merchant_trade_route(mut self, route: Option<MerchantTradeRoute>) -> Self {
        self.merchant_trade_route = route;
        self
    }
    /// Sets concrete activity slots.
    #[must_use]
    pub fn with_activity(mut self, activity: UnitActivity) -> Self {
        self.activity = activity;
        self
    }
    /// Sets worker construction charges.
    #[must_use]
    pub const fn with_worker_build_charges(mut self, charges: u32) -> Self {
        self.worker_build_charges = charges;
        self
    }
    /// Sets optional combat hit points.
    #[must_use]
    pub const fn with_hit_points(mut self, hit_points: Option<u32>) -> Self {
        self.hit_points = hit_points;
        self
    }
    /// Sets accumulated experience.
    #[must_use]
    pub const fn with_experience_points(mut self, experience_points: u32) -> Self {
        self.experience_points = experience_points;
        self
    }
    /// Sets persistent posture.
    #[must_use]
    pub const fn with_posture(mut self, posture: UnitPosture) -> Self {
        self.posture = posture;
        self
    }
    /// Sets the carried artifact.
    #[must_use]
    pub fn with_carried_artifact(mut self, artifact_id: Option<ArtifactId>) -> Self {
        self.carried_artifact_id = artifact_id;
        self
    }

    /// Validates and constructs the unit.
    ///
    /// # Errors
    ///
    /// Returns [`UnitBuildError`] when an entity invariant is violated.
    pub fn build(self) -> Result<Unit, UnitBuildError> {
        if self.name.trim().is_empty() {
            return Err(UnitBuildError::EmptyName);
        }
        if self.name.len() > MAX_UNIT_NAME_BYTES {
            return Err(UnitBuildError::NameTooLong);
        }
        let mut kinds = self
            .army
            .iter()
            .map(|troop| troop.kind())
            .collect::<Vec<_>>();
        if let Some(troop) = self.army.iter().find(|troop| troop.count() == 0) {
            return Err(UnitBuildError::EmptyTroop(troop.kind()));
        }
        kinds.sort_unstable();
        if let Some(pair) = kinds.windows(2).find(|pair| pair[0] == pair[1]) {
            return Err(UnitBuildError::DuplicateTroop(pair[0]));
        }
        validate_activity(&self.activity)?;
        if self.hit_points == Some(0) {
            return Err(UnitBuildError::ZeroHitPoints);
        }
        let unit = Unit {
            id: self.id,
            owner_player_id: self.owner_player_id,
            kind: self.kind,
            name: self.name,
            position: self.position,
            movement_units: self.movement_units,
            army: self.army.into_boxed_slice(),
            queued_path: self.queued_path,
            merchant_trade_route: self.merchant_trade_route,
            activity: self.activity,
            worker_build_charges: self.worker_build_charges,
            hit_points: self.hit_points,
            experience_points: self.experience_points,
            posture: self.posture,
            carried_artifact_id: self.carried_artifact_id,
        };
        validate_queued_path_origin(unit.position, unit.queued_path.as_ref())?;
        Ok(unit)
    }
}

fn validate_queued_path_origin(
    position: HexCoord,
    queued_path: Option<&QueuedMovePath>,
) -> Result<(), UnitBuildError> {
    let Some(path) = queued_path else {
        return Ok(());
    };
    let actual = path
        .steps()
        .first()
        .map_or(path.target(), |step| step.coordinate());
    if actual == position {
        return Ok(());
    }
    Err(UnitBuildError::QueuedPathOriginMismatch {
        expected: position,
        actual,
    })
}

fn validate_activity(activity: &UnitActivity) -> Result<(), UnitBuildError> {
    let worker_duration = activity.worker_job().map(|job| match job {
        WorkerJob::FieldImprovement {
            remaining_turns,
            total_turns,
            ..
        }
        | WorkerJob::RoadConstruction {
            remaining_turns,
            total_turns,
            ..
        } => (*remaining_turns, *total_turns),
    });
    let founding_duration = activity
        .city_founding_job()
        .map(|job| (job.remaining_turns(), job.total_turns()));
    if [worker_duration, founding_duration]
        .into_iter()
        .flatten()
        .any(|(remaining, total)| total == 0 || remaining > total)
    {
        return Err(UnitBuildError::InvalidJobDuration);
    }
    Ok(())
}

#[cfg(test)]
mod tests;
