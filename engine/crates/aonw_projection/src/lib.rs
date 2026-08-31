//! Framework-independent recipient-safe projections for every authoritative host.

#![forbid(unsafe_code)]

use aonw_domain::{
    CityId, FieldImprovementKind, GameState, HexCoord, PendingInteraction, PlayerId,
    PlayerTurnState, TurnMode, UnitId,
};
use std::sync::Arc;

use aonw_content::ContentHash;
use aonw_engine::StateDigest;

mod artifact;
mod city;
mod diplomacy;
mod disclosure;
mod infrastructure;
mod unit;
mod view_diff;

pub(crate) use artifact::visible_artifacts;
pub use artifact::{PlayerArtifactLocationView, PlayerArtifactView};
pub use city::{CityFoundingDraftView, OwnedCityDetailsView, PlayerCityView};
pub(crate) use city::{city_founding_draft, visible_cities};
pub(crate) use diplomacy::diplomacy_view;
pub use diplomacy::{
    PlayerDiplomacyView, PlayerDiplomaticMessageView, PlayerDiplomaticProposalView,
    PlayerDiplomaticRelationView, PlayerResourceTradeAgreementView,
};
pub use disclosure::RecipientDisclosure;
pub(crate) use infrastructure::visible_infrastructure;
pub use infrastructure::{PlayerFieldImprovementView, PlayerRoadView};
pub(crate) use unit::visible_units;
pub use unit::{OwnedUnitDetailsView, PlayerUnitView};
pub use view_diff::{PlayerViewPatch, ProjectedView, diff_view, unchanged_view};

/// Identity metadata carried by every recipient projection.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct SessionStamp {
    /// Canonical state revision.
    pub revision: aonw_domain::StateRevision,
    /// Canonical state digest.
    pub state_digest: StateDigest,
    /// Validated map hash.
    pub map_hash: ContentHash,
    /// Validated ruleset hash.
    pub ruleset_hash: ContentHash,
}

/// Recipient-owned action currently awaiting player input.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum PendingActionView {
    ResearchSelection,
    CityWorkedHexSelection {
        city_id: CityId,
    },
    CityExpansionSelection {
        city_id: CityId,
    },
    WorkerActionSelection {
        unit_id: UnitId,
        improvement: Option<FieldImprovementKind>,
    },
    MerchantTradeRouteSelection {
        unit_id: UnitId,
    },
    MerchantMoveToCitySelection {
        unit_id: UnitId,
    },
    UnitTurnSkip {
        unit_id: UnitId,
        restore_movement_units: u32,
    },
    AttackTargeting {
        unit_id: UnitId,
        defender: Option<HexCoord>,
    },
    CommanderMergeSelection {
        unit_id: UnitId,
    },
}

/// Complete recipient-safe presentation snapshot.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerViewSnapshot {
    recipient_player_id: Arc<PlayerId>,
    stamp: SessionStamp,
    turn: u32,
    turn_mode: TurnMode,
    outcome: Arc<aonw_domain::GameOutcome>,
    turn_lifecycle: PlayerTurnLifecycleView,
    pending_action: Option<Arc<PendingActionView>>,
    city_founding_draft: Option<Arc<CityFoundingDraftView>>,
    diplomacy: Arc<PlayerDiplomacyView>,
    units: Arc<[PlayerUnitView]>,
    cities: Arc<[PlayerCityView]>,
    artifacts: Arc<[PlayerArtifactView]>,
    field_improvements: Arc<[PlayerFieldImprovementView]>,
    roads: Arc<[PlayerRoadView]>,
}

impl PlayerViewSnapshot {
    #[allow(clippy::too_many_arguments)]
    pub(crate) fn from_parts(
        recipient_player_id: Arc<PlayerId>,
        stamp: SessionStamp,
        turn: u32,
        turn_mode: TurnMode,
        turn_lifecycle: PlayerTurnLifecycleView,
        outcome: Arc<aonw_domain::GameOutcome>,
        pending_action: Option<Arc<PendingActionView>>,
        city_founding_draft: Option<Arc<CityFoundingDraftView>>,
        diplomacy: Arc<PlayerDiplomacyView>,
        units: Arc<[PlayerUnitView]>,
        cities: Arc<[PlayerCityView]>,
        artifacts: Arc<[PlayerArtifactView]>,
        field_improvements: Arc<[PlayerFieldImprovementView]>,
        roads: Arc<[PlayerRoadView]>,
    ) -> Self {
        Self {
            recipient_player_id,
            stamp,
            turn,
            turn_mode,
            outcome,
            turn_lifecycle,
            pending_action,
            city_founding_draft,
            diplomacy,
            units,
            cities,
            artifacts,
            field_improvements,
            roads,
        }
    }

    /// Returns the player identity this recipient-safe snapshot was projected for.
    #[must_use]
    pub fn recipient_player_id(&self) -> &PlayerId {
        &self.recipient_player_id
    }

    /// Returns version and authoritative identity metadata.
    #[must_use]
    pub const fn stamp(&self) -> &SessionStamp {
        &self.stamp
    }
    /// Returns the authoritative turn number.
    #[must_use]
    pub const fn turn(&self) -> u32 {
        self.turn
    }
    /// Returns the authoritative participant turn resolution model.
    #[must_use]
    pub const fn turn_mode(&self) -> TurnMode {
        self.turn_mode
    }
    /// Returns the persisted authoritative match result.
    #[must_use]
    pub fn outcome(&self) -> &aonw_domain::GameOutcome {
        &self.outcome
    }
    /// Returns recipient-owned lifecycle and aggregate submission progress.
    #[must_use]
    pub const fn turn_lifecycle(&self) -> &PlayerTurnLifecycleView {
        &self.turn_lifecycle
    }
    /// Returns the action awaiting input from this recipient.
    #[must_use]
    pub fn pending_action(&self) -> Option<&PendingActionView> {
        self.pending_action.as_deref()
    }
    /// Returns the recipient-owned persisted founding workflow.
    #[must_use]
    pub fn city_founding_draft(&self) -> Option<&CityFoundingDraftView> {
        self.city_founding_draft.as_deref()
    }
    /// Returns bilateral diplomacy records involving this recipient.
    #[must_use]
    pub fn diplomacy(&self) -> &PlayerDiplomacyView {
        &self.diplomacy
    }
    /// Returns all units visible to this local player.
    #[must_use]
    pub fn units(&self) -> &[PlayerUnitView] {
        &self.units
    }
    /// Returns all cities known to this recipient.
    #[must_use]
    pub fn cities(&self) -> &[PlayerCityView] {
        &self.cities
    }
    /// Returns artifacts visible to this recipient.
    #[must_use]
    pub fn artifacts(&self) -> &[PlayerArtifactView] {
        &self.artifacts
    }
    /// Returns field improvements known to this recipient.
    #[must_use]
    pub fn field_improvements(&self) -> &[PlayerFieldImprovementView] {
        &self.field_improvements
    }
    /// Returns roads known to this recipient.
    #[must_use]
    pub fn roads(&self) -> &[PlayerRoadView] {
        &self.roads
    }
}

/// Recipient-safe turn state without per-opponent readiness identities.
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub struct PlayerTurnLifecycleView {
    own_state: Option<PlayerTurnState>,
    own_submitted: bool,
    required_submission_count: u32,
    submitted_count: u32,
}

impl PlayerTurnLifecycleView {
    pub(crate) fn new(state: &GameState, actor: &PlayerId) -> Self {
        let turn = state.match_lifecycle().turn();
        let required = turn.required_submission_player_ids();
        let required_submission_count = if required.is_empty() {
            state
                .match_lifecycle()
                .identity()
                .participants()
                .iter()
                .filter(|participant| !turn.kicked_player_ids().contains(participant.id()))
                .count()
        } else {
            required.len()
        };
        let submitted_count = turn
            .submitted_player_ids()
            .iter()
            .filter(|player| required.is_empty() || required.contains(*player))
            .count();
        Self {
            own_state: turn.turn_states_by_player_id().get(actor).copied(),
            own_submitted: turn.submitted_player_ids().contains(actor),
            required_submission_count: u32::try_from(required_submission_count).unwrap_or(u32::MAX),
            submitted_count: u32::try_from(submitted_count).unwrap_or(u32::MAX),
        }
    }

    /// Returns the recipient's own lifecycle status.
    #[must_use]
    pub const fn own_state(self) -> Option<PlayerTurnState> {
        self.own_state
    }

    /// Returns whether the recipient submitted.
    #[must_use]
    pub const fn own_submitted(self) -> bool {
        self.own_submitted
    }

    /// Returns the required submission count.
    #[must_use]
    pub const fn required_submission_count(self) -> u32 {
        self.required_submission_count
    }

    /// Returns the received required-submission count.
    #[must_use]
    pub const fn submitted_count(self) -> u32 {
        self.submitted_count
    }
}

pub(crate) fn pending_action(state: &GameState, actor: &PlayerId) -> Option<PendingActionView> {
    let pending = state.interaction().pending()?;
    if pending.owner_player_id() != actor {
        return None;
    }
    Some(match pending {
        PendingInteraction::ResearchSelection { .. } => PendingActionView::ResearchSelection,
        PendingInteraction::CityWorkedHexSelection { city_id, .. } => {
            PendingActionView::CityWorkedHexSelection {
                city_id: city_id.clone(),
            }
        }
        PendingInteraction::CityExpansionSelection { city_id, .. } => {
            PendingActionView::CityExpansionSelection {
                city_id: city_id.clone(),
            }
        }
        PendingInteraction::WorkerActionSelection {
            unit_id,
            improvement,
            ..
        } => PendingActionView::WorkerActionSelection {
            unit_id: unit_id.clone(),
            improvement: *improvement,
        },
        PendingInteraction::MerchantTradeRouteSelection { unit_id, .. } => {
            PendingActionView::MerchantTradeRouteSelection {
                unit_id: unit_id.clone(),
            }
        }
        PendingInteraction::MerchantMoveToCitySelection { unit_id, .. } => {
            PendingActionView::MerchantMoveToCitySelection {
                unit_id: unit_id.clone(),
            }
        }
        PendingInteraction::UnitTurnSkip {
            unit_id,
            restore_movement,
            ..
        } => PendingActionView::UnitTurnSkip {
            unit_id: unit_id.clone(),
            restore_movement_units: restore_movement.get(),
        },
        PendingInteraction::AttackTargeting {
            unit_id, defender, ..
        } => PendingActionView::AttackTargeting {
            unit_id: unit_id.clone(),
            defender: *defender,
        },
        PendingInteraction::CommanderMergeSelection { unit_id, .. } => {
            PendingActionView::CommanderMergeSelection {
                unit_id: unit_id.clone(),
            }
        }
    })
}

#[cfg(test)]
mod tests {
    use aonw_domain::{
        GameState, HexGridBounds, InteractionState, PlayerId, StateRevision, UnitOccupancyPolicy,
    };

    use super::{PendingActionView, pending_action};

    #[test]
    fn pending_action_is_visible_only_to_its_owner() {
        let actor = PlayerId::new("player-1").expect("actor id");
        let foreign = PlayerId::new("player-2").expect("foreign id");
        let state = GameState::builder(
            StateRevision::INITIAL,
            1,
            HexGridBounds::new(2, 2).expect("bounds"),
            UnitOccupancyPolicy::Exclusive,
            [],
        )
        .with_interaction(InteractionState::new(
            None,
            Some(aonw_domain::PendingInteraction::ResearchSelection {
                owner_player_id: actor.clone(),
            }),
        ))
        .try_build()
        .expect("state");

        assert_eq!(
            pending_action(&state, &actor),
            Some(PendingActionView::ResearchSelection)
        );
        assert_eq!(pending_action(&state, &foreign), None);
    }
}
