use core::cmp::Ordering;
use std::sync::Arc;

use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{
    ArtifactId, CityId, GameOutcome, GameState, HexCoord, PlayerId, TurnMode, UnitId,
};
use aonw_engine::CanonicalQueryError;

use crate::{
    CityFoundingDraftView, PendingActionView, PlayerArtifactView, PlayerCityView,
    PlayerDiplomacyView, PlayerEconomyView, PlayerFieldImprovementView, PlayerFogView,
    PlayerParticipantView, PlayerResearchView, PlayerRoadView, PlayerTurnLifecycleView,
    PlayerUnitView, PlayerViewSnapshot, SessionStamp, city_founding_draft, diplomacy_view,
    pending_action, visible_artifacts, visible_cities, visible_infrastructure, visible_units,
};

/// Recipient-safe view delta produced by one dispatch.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerViewPatch {
    /// Revision the patch applies to.
    pub from_revision: u64,
    /// Revision after the patch.
    pub to_revision: u64,
    /// Authoritative turn number after the patch.
    pub turn: u32,
    /// Authoritative participant turn resolution model.
    pub turn_mode: TurnMode,
    /// Replacement recipient fog state when visibility changed.
    pub fog: Option<PlayerFogView>,
    /// Replacement recipient economy state when any account or resource flow changed.
    pub economy: Option<PlayerEconomyView>,
    /// Replacement recipient research state when progress or science changed.
    pub research: Option<PlayerResearchView>,
    /// Replacement turn projection when lifecycle state changed.
    pub turn_lifecycle: Option<PlayerTurnLifecycleView>,
    /// Replacement authoritative match result when it changed.
    pub outcome: Option<GameOutcome>,
    /// New or changed visible units.
    pub upserted_units: Box<[PlayerUnitView]>,
    /// Units no longer visible.
    pub removed_unit_ids: Box<[UnitId]>,
    /// New or changed cities known to this recipient.
    pub upserted_cities: Box<[PlayerCityView]>,
    /// Cities no longer known to this recipient.
    pub removed_city_ids: Box<[CityId]>,
    /// New or changed visible artifacts.
    pub upserted_artifacts: Box<[PlayerArtifactView]>,
    /// Artifacts no longer visible.
    pub removed_artifact_ids: Box<[ArtifactId]>,
    /// New or changed field improvements known to the recipient.
    pub upserted_field_improvements: Box<[PlayerFieldImprovementView]>,
    /// Field improvements no longer known to the recipient.
    pub removed_field_improvement_coordinates: Box<[HexCoord]>,
    /// New or changed roads known to the recipient.
    pub upserted_roads: Box<[PlayerRoadView]>,
    /// Roads no longer known to the recipient.
    pub removed_road_coordinates: Box<[HexCoord]>,
    /// Current action awaiting input from this recipient.
    pub pending_action: Option<PendingActionView>,
    /// Current recipient-owned city-founding workflow.
    pub city_founding_draft: Option<CityFoundingDraftView>,
    /// Replacement bilateral diplomacy view when any visible record changed.
    pub diplomacy: Option<PlayerDiplomacyView>,
}

#[derive(Clone, Debug, Eq, PartialEq)]
/// Complete reusable recipient projection used to build snapshots and deltas.
pub struct ProjectedView {
    recipient_player_id: Arc<PlayerId>,
    turn_number: u32,
    turn_mode: TurnMode,
    participants: Arc<[PlayerParticipantView]>,
    fog: Arc<PlayerFogView>,
    economy: Arc<PlayerEconomyView>,
    research: Arc<PlayerResearchView>,
    turn: PlayerTurnLifecycleView,
    outcome: Arc<GameOutcome>,
    diplomacy: Arc<PlayerDiplomacyView>,
    units: Arc<[PlayerUnitView]>,
    cities: Arc<[PlayerCityView]>,
    artifacts: Arc<[PlayerArtifactView]>,
    field_improvements: Arc<[PlayerFieldImprovementView]>,
    roads: Arc<[PlayerRoadView]>,
    pending_action: Option<Arc<PendingActionView>>,
    city_founding_draft: Option<Arc<CityFoundingDraftView>>,
}

impl ProjectedView {
    #[cfg(test)]
    pub(crate) fn new(
        turn: PlayerTurnLifecycleView,
        outcome: GameOutcome,
        diplomacy: PlayerDiplomacyView,
        units: Vec<PlayerUnitView>,
        cities: Vec<PlayerCityView>,
        artifacts: Vec<PlayerArtifactView>,
        infrastructure: (Vec<PlayerFieldImprovementView>, Vec<PlayerRoadView>),
    ) -> Self {
        let (field_improvements, roads) = infrastructure;
        Self {
            recipient_player_id: Arc::new(PlayerId::new("test-player").expect("player id")),
            turn_number: 0,
            turn_mode: TurnMode::Sequential,
            participants: Arc::new([]),
            fog: Arc::new(PlayerFogView {
                enabled: false,
                discovered_hexes: Arc::from([]),
                visible_hexes: Arc::from([]),
            }),
            economy: Arc::new(PlayerEconomyView::empty()),
            research: Arc::new(PlayerResearchView::default()),
            turn,
            outcome: Arc::new(outcome),
            diplomacy: Arc::new(diplomacy),
            units: units.into(),
            cities: cities.into(),
            artifacts: artifacts.into(),
            field_improvements: field_improvements.into(),
            roads: roads.into(),
            pending_action: None,
            city_founding_draft: None,
        }
    }

    #[cfg(test)]
    fn with_turn_mode(mut self, turn_mode: TurnMode) -> Self {
        self.turn_mode = turn_mode;
        self
    }

    #[cfg(test)]
    fn with_fog(mut self, discovered_hexes: &[HexCoord], visible_hexes: &[HexCoord]) -> Self {
        self.fog = Arc::new(PlayerFogView {
            enabled: true,
            discovered_hexes: Arc::from(discovered_hexes),
            visible_hexes: Arc::from(visible_hexes),
        });
        self
    }

    #[cfg(test)]
    fn with_gold(mut self, gold: i64) -> Self {
        self.economy = Arc::new(PlayerEconomyView::empty().with_gold(gold));
        self
    }

    #[cfg(test)]
    fn with_science_per_turn(mut self, amount: i64) -> Self {
        self.research = Arc::new(PlayerResearchView::default().with_science_per_turn(amount));
        self
    }

    /// Builds a complete recipient-safe projection from canonical state and content.
    ///
    /// # Errors
    ///
    /// Returns an error when an authoritative economy or research projection cannot be computed.
    pub fn try_for_recipient(
        state: &GameState,
        actor: Arc<PlayerId>,
        map: &MapDefinition,
        ruleset: &RulesetDefinition,
    ) -> Result<Self, CanonicalQueryError> {
        let recipient = actor.as_ref();
        let (field_improvements, roads) = visible_infrastructure(state, recipient);
        let turn = PlayerTurnLifecycleView::new(state, recipient);
        let diplomacy = Arc::new(diplomacy_view(state, recipient));
        let units = visible_units(state, recipient).into();
        let cities = visible_cities(state, recipient).into();
        let artifacts = visible_artifacts(state, recipient).into();
        let pending_action = pending_action(state, recipient).map(Arc::new);
        let city_founding_draft = city_founding_draft(state, recipient).map(Arc::new);
        let fog = Arc::new(PlayerFogView::for_recipient(state, recipient));
        let economy = Arc::new(PlayerEconomyView::try_for_recipient(
            state, recipient, map, ruleset,
        )?);
        let research = Arc::new(PlayerResearchView::try_for_recipient(
            state, recipient, map, ruleset,
        )?);
        let participants = state
            .match_lifecycle()
            .identity()
            .participants()
            .iter()
            .map(PlayerParticipantView::from_participant)
            .collect::<Vec<_>>()
            .into();
        Ok(Self {
            recipient_player_id: actor,
            turn_number: state.turn(),
            turn_mode: state.match_lifecycle().identity().turn_mode(),
            participants,
            fog,
            economy,
            research,
            turn,
            outcome: Arc::new(state.outcome().clone()),
            diplomacy,
            units,
            cities,
            artifacts,
            field_improvements: field_improvements.into(),
            roads: roads.into(),
            pending_action,
            city_founding_draft,
        })
    }

    /// Materializes a complete recipient snapshot with authoritative identity.
    #[must_use]
    pub fn snapshot(&self, stamp: SessionStamp) -> PlayerViewSnapshot {
        PlayerViewSnapshot::from_parts(
            self.recipient_player_id.clone(),
            stamp,
            self.turn_number,
            self.turn_mode,
            self.participants.clone(),
            self.fog.clone(),
            self.economy.clone(),
            self.research.clone(),
            self.turn,
            self.outcome.clone(),
            self.pending_action.clone(),
            self.city_founding_draft.clone(),
            self.diplomacy.clone(),
            self.units.clone(),
            self.cities.clone(),
            self.artifacts.clone(),
            self.field_improvements.clone(),
            self.roads.clone(),
        )
    }

    /// Returns visible units in stable identity order.
    #[must_use]
    pub fn units(&self) -> &[PlayerUnitView] {
        &self.units
    }

    /// Returns visible cities in stable identity order.
    #[must_use]
    pub fn cities(&self) -> &[PlayerCityView] {
        &self.cities
    }
}

/// Computes one recipient-safe projection delta.
#[must_use]
pub fn diff_view(
    from_revision: u64,
    to_revision: u64,
    before: &ProjectedView,
    after: &ProjectedView,
) -> PlayerViewPatch {
    debug_assert!(
        before
            .units
            .windows(2)
            .all(|pair| pair[0].id() < pair[1].id())
    );
    debug_assert!(
        after
            .units
            .windows(2)
            .all(|pair| pair[0].id() < pair[1].id())
    );
    let outcome = (before.outcome != after.outcome).then(|| after.outcome.as_ref().clone());
    let diplomacy = (before.diplomacy != after.diplomacy).then(|| after.diplomacy.as_ref().clone());
    let fog = (before.fog != after.fog).then(|| after.fog.as_ref().clone());
    let economy = (before.economy != after.economy).then(|| after.economy.as_ref().clone());
    let research = (before.research != after.research).then(|| after.research.as_ref().clone());
    let mut before_units = before.units.iter().peekable();
    let mut after_units = after.units.iter().peekable();
    let mut upserted_units = Vec::new();
    let mut removed_unit_ids = Vec::new();
    while let (Some(previous), Some(current)) = (before_units.peek(), after_units.peek()) {
        match previous.id().cmp(current.id()) {
            Ordering::Less => {
                if let Some(previous) = before_units.next() {
                    removed_unit_ids.push(previous.id().clone());
                }
            }
            Ordering::Equal => {
                if let (Some(previous), Some(current)) = (before_units.next(), after_units.next())
                    && previous != current
                {
                    upserted_units.push(current.clone());
                }
            }
            Ordering::Greater => {
                if let Some(current) = after_units.next() {
                    upserted_units.push(current.clone());
                }
            }
        }
    }
    removed_unit_ids.extend(before_units.map(|unit| unit.id().clone()));
    upserted_units.extend(after_units.cloned());
    let (upserted_cities, removed_city_ids) = diff_cities(&before.cities, &after.cities);
    let (upserted_artifacts, removed_artifact_ids) =
        diff_artifacts(&before.artifacts, &after.artifacts);
    let (upserted_field_improvements, removed_field_improvement_coordinates) =
        diff_improvements(&before.field_improvements, &after.field_improvements);
    let (upserted_roads, removed_road_coordinates) = diff_roads(&before.roads, &after.roads);
    PlayerViewPatch {
        from_revision,
        to_revision,
        turn: after.turn_number,
        turn_mode: after.turn_mode,
        fog,
        economy,
        research,
        turn_lifecycle: (before.turn != after.turn).then_some(after.turn),
        outcome,
        upserted_units: upserted_units.into_boxed_slice(),
        removed_unit_ids: removed_unit_ids.into_boxed_slice(),
        upserted_cities,
        removed_city_ids,
        upserted_artifacts,
        removed_artifact_ids,
        upserted_field_improvements,
        removed_field_improvement_coordinates,
        upserted_roads,
        removed_road_coordinates,
        pending_action: after.pending_action.as_deref().cloned(),
        city_founding_draft: after.city_founding_draft.as_deref().cloned(),
        diplomacy,
    }
}

/// Returns an empty delta carrying current recipient-owned workflow state.
#[must_use]
pub fn unchanged_view(revision: u64, view: &ProjectedView) -> PlayerViewPatch {
    PlayerViewPatch {
        from_revision: revision,
        to_revision: revision,
        turn: view.turn_number,
        turn_mode: view.turn_mode,
        fog: None,
        economy: None,
        research: None,
        turn_lifecycle: None,
        outcome: None,
        upserted_units: Box::new([]),
        removed_unit_ids: Box::new([]),
        upserted_cities: Box::new([]),
        removed_city_ids: Box::new([]),
        upserted_artifacts: Box::new([]),
        removed_artifact_ids: Box::new([]),
        upserted_field_improvements: Box::new([]),
        removed_field_improvement_coordinates: Box::new([]),
        upserted_roads: Box::new([]),
        removed_road_coordinates: Box::new([]),
        pending_action: view.pending_action.as_deref().cloned(),
        city_founding_draft: view.city_founding_draft.as_deref().cloned(),
        diplomacy: None,
    }
}

fn diff_artifacts(
    before: &[PlayerArtifactView],
    after: &[PlayerArtifactView],
) -> (Box<[PlayerArtifactView]>, Box<[ArtifactId]>) {
    let mut before = before.iter().peekable();
    let mut after = after.iter().peekable();
    let mut upserted = Vec::new();
    let mut removed = Vec::new();
    while let (Some(previous), Some(current)) = (before.peek(), after.peek()) {
        match previous.id().cmp(current.id()) {
            Ordering::Less => removed.push(before.next().expect("previous artifact").id().clone()),
            Ordering::Equal => {
                let previous = before.next().expect("previous artifact");
                let current = after.next().expect("current artifact");
                if previous != current {
                    upserted.push(current.clone());
                }
            }
            Ordering::Greater => {
                upserted.push(after.next().expect("current artifact").clone());
            }
        }
    }
    removed.extend(before.map(|artifact| artifact.id().clone()));
    upserted.extend(after.cloned());
    (upserted.into_boxed_slice(), removed.into_boxed_slice())
}

fn diff_improvements(
    before: &[PlayerFieldImprovementView],
    after: &[PlayerFieldImprovementView],
) -> (Box<[PlayerFieldImprovementView]>, Box<[HexCoord]>) {
    diff_coordinate_views(before, after, PlayerFieldImprovementView::coordinate)
}

fn diff_roads(
    before: &[PlayerRoadView],
    after: &[PlayerRoadView],
) -> (Box<[PlayerRoadView]>, Box<[HexCoord]>) {
    diff_coordinate_views(before, after, PlayerRoadView::coordinate)
}

fn diff_coordinate_views<View: Copy + Eq>(
    before: &[View],
    after: &[View],
    coordinate: impl Fn(View) -> HexCoord,
) -> (Box<[View]>, Box<[HexCoord]>) {
    let mut before = before.iter().copied().peekable();
    let mut after = after.iter().copied().peekable();
    let mut upserted = Vec::new();
    let mut removed = Vec::new();
    while let (Some(previous), Some(current)) = (before.peek(), after.peek()) {
        match coordinate(*previous).cmp(&coordinate(*current)) {
            Ordering::Less => removed.push(coordinate(before.next().expect("previous view"))),
            Ordering::Equal => {
                let previous = before.next().expect("previous view");
                let current = after.next().expect("current view");
                if previous != current {
                    upserted.push(current);
                }
            }
            Ordering::Greater => upserted.push(after.next().expect("current view")),
        }
    }
    removed.extend(before.map(coordinate));
    upserted.extend(after);
    (upserted.into_boxed_slice(), removed.into_boxed_slice())
}

fn diff_cities(
    before: &[PlayerCityView],
    after: &[PlayerCityView],
) -> (Box<[PlayerCityView]>, Box<[CityId]>) {
    debug_assert!(before.windows(2).all(|pair| pair[0].id() < pair[1].id()));
    debug_assert!(after.windows(2).all(|pair| pair[0].id() < pair[1].id()));
    let mut before = before.iter().peekable();
    let mut after = after.iter().peekable();
    let mut upserted = Vec::new();
    let mut removed = Vec::new();
    while let (Some(previous), Some(current)) = (before.peek(), after.peek()) {
        match previous.id().cmp(current.id()) {
            Ordering::Less => {
                if let Some(previous) = before.next() {
                    removed.push(previous.id().clone());
                }
            }
            Ordering::Equal => {
                if let (Some(previous), Some(current)) = (before.next(), after.next())
                    && previous != current
                {
                    upserted.push(current.clone());
                }
            }
            Ordering::Greater => {
                if let Some(current) = after.next() {
                    upserted.push(current.clone());
                }
            }
        }
    }
    removed.extend(before.map(|city| city.id().clone()));
    upserted.extend(after.cloned());
    (upserted.into_boxed_slice(), removed.into_boxed_slice())
}

#[cfg(test)]
mod tests {
    use aonw_domain::{
        GameOutcome, HexCoord, MovementUnits, PlayerId, TurnMode, Unit, UnitId, UnitKind,
    };

    use super::{ProjectedView, diff_coordinate_views, diff_view};
    use crate::{PlayerDiplomacyView, PlayerTurnLifecycleView, PlayerUnitView};

    #[test]
    fn sorted_view_diff_reports_updates_insertions_and_removals() {
        let before = vec![view("unit-a", 0), view("unit-b", 1)];
        let after = vec![view("unit-b", 2), view("unit-c", 3)];

        let turn = PlayerTurnLifecycleView::default();
        let before = ProjectedView::new(
            turn,
            GameOutcome::ongoing(),
            PlayerDiplomacyView::default(),
            before,
            Vec::new(),
            Vec::new(),
            (Vec::new(), Vec::new()),
        )
        .with_turn_mode(TurnMode::Simultaneous);
        let after = ProjectedView::new(
            turn,
            GameOutcome::ongoing(),
            PlayerDiplomacyView::default(),
            after,
            Vec::new(),
            Vec::new(),
            (Vec::new(), Vec::new()),
        )
        .with_turn_mode(TurnMode::Simultaneous)
        .with_gold(25)
        .with_science_per_turn(7)
        .with_fog(
            &[HexCoord::new(1, 0), HexCoord::new(2, 0)],
            &[HexCoord::new(2, 0)],
        );
        let patch = diff_view(4, 5, &before, &after);

        assert_eq!(patch.from_revision, 4);
        assert_eq!(patch.to_revision, 5);
        assert_eq!(patch.turn, 0);
        assert_eq!(patch.turn_mode, TurnMode::Simultaneous);
        let fog = patch.fog.expect("changed fog");
        assert!(fog.enabled());
        assert_eq!(
            fog.discovered_hexes(),
            [HexCoord::new(1, 0), HexCoord::new(2, 0)]
        );
        assert_eq!(fog.visible_hexes(), [HexCoord::new(2, 0)]);
        assert_eq!(patch.economy.expect("changed economy").gold(), 25);
        assert_eq!(
            patch.research.expect("changed research").science_per_turn(),
            7
        );
        assert_eq!(
            patch
                .upserted_units
                .iter()
                .map(|unit| unit.id().as_str())
                .collect::<Vec<_>>(),
            ["unit-b", "unit-c"]
        );
        assert_eq!(
            patch
                .removed_unit_ids
                .iter()
                .map(UnitId::as_str)
                .collect::<Vec<_>>(),
            ["unit-a"]
        );
        assert_eq!(patch.pending_action, None);
    }

    #[test]
    fn coordinate_view_diff_reports_updates_insertions_and_removals() {
        #[derive(Clone, Copy, Debug, Eq, PartialEq)]
        struct View {
            coordinate: HexCoord,
            value: u8,
        }

        let view = |col, value| View {
            coordinate: HexCoord::new(col, 0),
            value,
        };
        let before = [view(0, 0), view(2, 0), view(4, 0)];
        let after = [view(1, 0), view(2, 1), view(3, 0)];

        let (upserted, removed) = diff_coordinate_views(&before, &after, |view| view.coordinate);

        assert_eq!(upserted.as_ref(), [view(1, 0), view(2, 1), view(3, 0)]);
        assert_eq!(removed.as_ref(), [HexCoord::new(0, 0), HexCoord::new(4, 0)]);
    }

    fn view(id: &str, col: i32) -> PlayerUnitView {
        let unit = Unit::builder(
            UnitId::new(id).expect("unit id"),
            PlayerId::new("player-1").expect("player id"),
            UnitKind::Commander,
            "Commander",
            HexCoord::new(col, 0),
            MovementUnits::new(10),
        )
        .build()
        .expect("unit");
        PlayerUnitView::from_unit(&unit, true)
    }
}
