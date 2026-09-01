use aonw_domain::{
    ArmyTroop, ArtifactId, FogVisibility, GameState, MerchantTradeRoute, PlayerId, QueuedMovePath,
    Unit, UnitActivity, UnitId, UnitKind, UnitPosture,
};

/// Complete unit state disclosed only to the owning recipient.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct OwnedUnitDetailsView {
    army: Box<[ArmyTroop]>,
    queued_path: Option<QueuedMovePath>,
    merchant_trade_route: Option<MerchantTradeRoute>,
    activity: UnitActivity,
    worker_build_charges: u32,
    experience_points: u32,
}

impl OwnedUnitDetailsView {
    /// Returns army troops in canonical order.
    #[must_use]
    pub const fn army(&self) -> &[ArmyTroop] {
        &self.army
    }
    /// Returns the persisted manual route.
    #[must_use]
    pub const fn queued_path(&self) -> Option<&QueuedMovePath> {
        self.queued_path.as_ref()
    }
    /// Returns the persisted merchant route.
    #[must_use]
    pub const fn merchant_trade_route(&self) -> Option<&MerchantTradeRoute> {
        self.merchant_trade_route.as_ref()
    }
    /// Returns all mutually exclusive and independent activity slots.
    #[must_use]
    pub const fn activity(&self) -> &UnitActivity {
        &self.activity
    }
    /// Returns remaining worker construction charges.
    #[must_use]
    pub const fn worker_build_charges(&self) -> u32 {
        self.worker_build_charges
    }
    /// Returns accumulated unit experience.
    #[must_use]
    pub const fn experience_points(&self) -> u32 {
        self.experience_points
    }
}

/// Recipient-safe unit view for presentation.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerUnitView {
    id: UnitId,
    owner_player_id: PlayerId,
    kind: UnitKind,
    name: Box<str>,
    col: i32,
    row: i32,
    movement_units: u32,
    posture: UnitPosture,
    hit_points: Option<u32>,
    maximum_hit_points: Option<u32>,
    carried_artifact_id: Option<ArtifactId>,
    owned_details: Option<OwnedUnitDetailsView>,
}

impl PlayerUnitView {
    pub(crate) fn from_unit(
        state: &GameState,
        ruleset: &aonw_content::RulesetDefinition,
        unit: &Unit,
        disclose_worker: bool,
    ) -> Self {
        let maximum_hit_points = unit
            .hit_points()
            .and_then(|_| aonw_engine::unit_max_hit_points(state, ruleset, unit));
        Self {
            id: unit.id().clone(),
            owner_player_id: unit.owner_player_id().clone(),
            kind: unit.kind(),
            name: unit.name().into(),
            col: unit.position().col(),
            row: unit.position().row(),
            movement_units: unit.movement_units().get(),
            posture: unit.posture(),
            hit_points: unit.hit_points(),
            maximum_hit_points,
            carried_artifact_id: unit.carried_artifact_id().cloned(),
            owned_details: disclose_worker.then(|| OwnedUnitDetailsView {
                army: unit.army().to_vec().into_boxed_slice(),
                queued_path: unit.queued_path().cloned(),
                merchant_trade_route: unit.merchant_trade_route().cloned(),
                activity: unit.activity().clone(),
                worker_build_charges: unit.worker_build_charges(),
                experience_points: unit.experience_points(),
            }),
        }
    }

    /// Returns the unit identifier.
    #[must_use]
    pub const fn id(&self) -> &UnitId {
        &self.id
    }
    /// Returns the visible owner identifier.
    #[must_use]
    pub const fn owner_player_id(&self) -> &PlayerId {
        &self.owner_player_id
    }
    /// Returns the visible unit kind.
    #[must_use]
    pub const fn kind(&self) -> UnitKind {
        self.kind
    }
    /// Returns the authored display name.
    #[must_use]
    pub fn name(&self) -> &str {
        &self.name
    }
    /// Returns the map column.
    #[must_use]
    pub const fn col(&self) -> i32 {
        self.col
    }
    /// Returns the map row.
    #[must_use]
    pub const fn row(&self) -> i32 {
        self.row
    }
    /// Returns current fixed-point movement units.
    #[must_use]
    pub const fn movement_units(&self) -> u32 {
        self.movement_units
    }
    /// Returns the persistent unit posture.
    #[must_use]
    pub const fn posture(&self) -> UnitPosture {
        self.posture
    }
    /// Returns public combat health when the unit type uses it.
    #[must_use]
    pub const fn hit_points(&self) -> Option<u32> {
        self.hit_points
    }
    /// Returns authoritative maximum combat health when explicit health is used.
    #[must_use]
    pub const fn maximum_hit_points(&self) -> Option<u32> {
        self.maximum_hit_points
    }
    /// Returns the publicly visible carried artifact.
    #[must_use]
    pub const fn carried_artifact_id(&self) -> Option<&ArtifactId> {
        self.carried_artifact_id.as_ref()
    }
    /// Returns complete private state only for a recipient-owned unit.
    #[must_use]
    pub const fn owned_details(&self) -> Option<&OwnedUnitDetailsView> {
        self.owned_details.as_ref()
    }
}

pub(crate) fn visible_units(
    state: &GameState,
    actor: &PlayerId,
    ruleset: &aonw_content::RulesetDefinition,
) -> Vec<PlayerUnitView> {
    state
        .units()
        .iter()
        .filter(|unit| {
            unit.owner_player_id() == actor
                || state.fog_of_war().visibility(actor, unit.position()) == FogVisibility::Visible
        })
        .map(|unit| {
            PlayerUnitView::from_unit(state, ruleset, unit, unit.owner_player_id() == actor)
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use aonw_content::RulesetDefinition;
    use aonw_domain::{
        FogOfWar, GameState, HexCoord, HexGridBounds, MovementUnits, PlayerFog, PlayerId,
        StateRevision, Unit, UnitId, UnitKind, UnitOccupancyPolicy,
    };

    use super::visible_units;

    #[test]
    fn visible_units_have_stable_identifier_order() {
        let actor = PlayerId::new("player-1").expect("player id");
        let state = GameState::try_new(
            StateRevision::INITIAL,
            0,
            HexGridBounds::new(5, 5).expect("bounds"),
            UnitOccupancyPolicy::Exclusive,
            [
                unit("unit-z", &actor, HexCoord::new(1, 1)),
                unit("unit-a", &actor, HexCoord::new(2, 1)),
            ],
        )
        .expect("state");

        let identifiers = visible_units(&state, &actor, RulesetDefinition::standard())
            .into_iter()
            .map(|unit| unit.id().as_str().to_owned())
            .collect::<Vec<_>>();
        assert_eq!(identifiers, ["unit-a", "unit-z"]);
    }

    #[test]
    fn visible_units_never_leak_foreign_units_through_fog() {
        let actor = PlayerId::new("player-1").expect("actor id");
        let foreign = PlayerId::new("player-2").expect("foreign id");
        let visible = HexCoord::new(2, 1);
        let discovered = HexCoord::new(3, 1);
        let owned_hidden = HexCoord::new(4, 1);
        let foreign_hidden = HexCoord::new(5, 1);
        let fog = FogOfWar::try_new([PlayerFog::new(actor.clone(), [discovered], [visible])])
            .expect("fog");
        let state = GameState::builder(
            StateRevision::INITIAL,
            0,
            HexGridBounds::new(6, 4).expect("bounds"),
            UnitOccupancyPolicy::Exclusive,
            [
                unit("owned-hidden", &actor, owned_hidden),
                unit("foreign-visible", &foreign, visible),
                unit("foreign-discovered", &foreign, discovered),
                unit("foreign-hidden", &foreign, foreign_hidden),
            ],
        )
        .with_fog_of_war(fog)
        .try_build()
        .expect("state");

        let identifiers = visible_units(&state, &actor, RulesetDefinition::standard())
            .into_iter()
            .map(|unit| unit.id().as_str().to_owned())
            .collect::<Vec<_>>();
        assert_eq!(identifiers, ["foreign-visible", "owned-hidden"]);
    }

    #[test]
    fn visible_unit_health_includes_authoritative_maximum() {
        let actor = PlayerId::new("player-1").expect("actor id");
        let damaged = Unit::builder(
            UnitId::new("damaged").expect("unit id"),
            actor.clone(),
            UnitKind::Commander,
            "Commander",
            HexCoord::new(1, 1),
            MovementUnits::new(10),
        )
        .with_hit_points(Some(3))
        .build()
        .expect("unit");
        let state = GameState::try_new(
            StateRevision::INITIAL,
            0,
            HexGridBounds::new(3, 3).expect("bounds"),
            UnitOccupancyPolicy::Exclusive,
            [damaged],
        )
        .expect("state");

        let view = visible_units(&state, &actor, RulesetDefinition::standard())
            .into_iter()
            .next()
            .expect("visible unit");
        assert_eq!(view.hit_points(), Some(3));
        assert_eq!(view.maximum_hit_points(), Some(8));
    }

    fn unit(id: &str, actor: &PlayerId, position: HexCoord) -> Unit {
        Unit::builder(
            UnitId::new(id).expect("unit id"),
            actor.clone(),
            UnitKind::Commander,
            "Commander",
            position,
            MovementUnits::new(10),
        )
        .build()
        .expect("unit")
    }
}
