use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{GameState, PlayerId};
use aonw_engine::{
    EngineContext, EventBudget, GameEngine, MovementVisibility, StateDigest, SystemContext,
};
use aonw_projection::ProjectedView;
use std::sync::Arc;

use crate::SessionStamp;
use crate::persistence::ReplayRecorder;
use crate::prepared_world::PreparedWorld;

use super::{OpenSession, OpenSessionError, RuntimeError};

#[derive(Clone, Debug)]
pub(crate) struct Session {
    world: Arc<PreparedWorld>,
    state: Option<GameState>,
    actor: Arc<PlayerId>,
    state_digest: StateDigest,
    visibility: Arc<MovementVisibility>,
    event_offset: u64,
    replay: Arc<ReplayRecorder>,
    records_replay: bool,
    projection: Arc<ProjectedView>,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub(crate) struct EventReservation {
    initial_offset: u64,
    budget: EventBudget,
}

impl EventReservation {
    fn try_new(initial_offset: u64, budget: EventBudget) -> Result<Self, RuntimeError> {
        initial_offset
            .checked_add(budget.maximum())
            .ok_or(RuntimeError::EventOffsetOverflow)?;
        Ok(Self {
            initial_offset,
            budget,
        })
    }

    fn committed_offset(self, actual: usize) -> Result<u64, RuntimeError> {
        let actual = u64::try_from(actual).map_err(|_| RuntimeError::EventBudgetExceeded {
            maximum: self.budget.maximum(),
            actual: u64::MAX,
        })?;
        if !self.budget.accepts(actual) {
            return Err(RuntimeError::EventBudgetExceeded {
                maximum: self.budget.maximum(),
                actual,
            });
        }
        self.initial_offset
            .checked_add(actual)
            .ok_or(RuntimeError::EventOffsetOverflow)
    }
}

impl Session {
    pub(super) fn try_open(request: OpenSession) -> Result<Self, OpenSessionError> {
        let identity = request.state.match_lifecycle().identity();
        if identity.participants().is_empty() {
            return Err(OpenSessionError::EmptyParticipants);
        }
        if !identity.contains(&request.actor) {
            return Err(OpenSessionError::UnknownActor(request.actor));
        }
        let world = Arc::new(PreparedWorld::try_new(
            request.map,
            request.ruleset,
            &request.state,
        )?);
        let actor = Arc::new(request.actor);
        let state_digest = GameEngine::state_digest(&request.state);
        let visibility = Arc::new(MovementVisibility::for_player(
            &request.state,
            world.map(),
            actor.as_ref(),
        ));
        let replay = Arc::new(ReplayRecorder::new(
            &request.state,
            state_digest,
            request.event_offset,
        ));
        let projection = Arc::new(
            ProjectedView::try_for_recipient(
                &request.state,
                actor.clone(),
                world.map(),
                world.ruleset(),
            )
            .map_err(OpenSessionError::Projection)?,
        );
        Ok(Self {
            world,
            state: Some(request.state),
            actor,
            state_digest,
            visibility,
            event_offset: request.event_offset,
            replay,
            records_replay: true,
            projection,
        })
    }

    pub(crate) const fn state(&self) -> &GameState {
        self.state.as_ref().expect("open session owns state")
    }

    pub(crate) fn actor(&self) -> &PlayerId {
        self.actor.as_ref()
    }

    pub(crate) fn shared_actor(&self) -> Arc<PlayerId> {
        self.actor.clone()
    }

    pub(crate) fn handoff_actor(
        &mut self,
        actor: PlayerId,
    ) -> Result<(), aonw_engine::CanonicalQueryError> {
        let actor = Arc::new(actor);
        let projection = Arc::new(ProjectedView::try_for_recipient(
            self.state(),
            actor.clone(),
            self.world.map(),
            self.world.ruleset(),
        )?);
        self.visibility = Arc::new(MovementVisibility::for_player(
            self.state(),
            self.world.map(),
            actor.as_ref(),
        ));
        self.projection = projection;
        self.actor = actor;
        Ok(())
    }

    pub(crate) fn map(&self) -> &MapDefinition {
        self.world.map()
    }

    pub(crate) fn ruleset(&self) -> &RulesetDefinition {
        self.world.ruleset()
    }

    pub(crate) const fn event_offset(&self) -> u64 {
        self.event_offset
    }

    pub(crate) fn reserve_event_capacity(
        &self,
        budget: EventBudget,
    ) -> Result<EventReservation, RuntimeError> {
        EventReservation::try_new(self.event_offset, budget)
    }

    pub(crate) fn commit_event_reservation(
        &mut self,
        reservation: EventReservation,
        actual: usize,
    ) -> Result<(), RuntimeError> {
        debug_assert_eq!(reservation.initial_offset, self.event_offset);
        self.event_offset = reservation.committed_offset(actual)?;
        Ok(())
    }

    pub(crate) fn replay(&self) -> &ReplayRecorder {
        self.replay.as_ref()
    }

    pub(crate) fn projection(&self) -> &ProjectedView {
        self.projection.as_ref()
    }

    pub(crate) const fn records_replay(&self) -> bool {
        self.records_replay
    }

    pub(crate) fn disable_replay(&mut self) {
        self.records_replay = false;
    }

    pub(crate) fn prepare_replay_segment(&mut self) {
        if !self.records_replay {
            return;
        }
        if self.replay.is_full() {
            let checkpoint =
                ReplayRecorder::checkpoint(self.state(), self.state_digest, self.event_offset);
            Arc::make_mut(&mut self.replay).rollover(checkpoint);
        }
    }

    pub(crate) fn push_replay(&mut self, entry: aonw_contracts::ReplayEntryDto) {
        if self.records_replay {
            let replacement = self.replay.requires_checkpoint_for(&entry).then(|| {
                ReplayRecorder::checkpoint(self.state(), self.state_digest, self.event_offset)
            });
            Arc::make_mut(&mut self.replay).push_bounded(entry, replacement);
        }
    }

    pub(crate) fn context(&self) -> EngineContext<'_> {
        EngineContext::canonical(self.actor(), self.world.map(), self.world.ruleset())
            .with_compiled_movement_map(self.world.movement_map())
            .with_movement_visibility(self.visibility.as_ref())
    }

    pub(crate) fn system_context(&self) -> SystemContext<'_> {
        SystemContext::canonical(self.world.map(), self.world.ruleset())
    }

    pub(crate) fn replace_state(
        &mut self,
        state: GameState,
        state_digest: StateDigest,
        projection: ProjectedView,
    ) {
        self.state_digest = state_digest;
        self.visibility = Arc::new(MovementVisibility::for_player(
            &state,
            self.world.map(),
            self.actor.as_ref(),
        ));
        self.state = Some(state);
        self.projection = Arc::new(projection);
    }

    pub(crate) fn restore_rejected_state(&mut self, state: GameState) {
        self.state = Some(state);
    }

    pub(crate) fn take_state(&mut self) -> GameState {
        self.state.take().expect("open session owns state")
    }

    pub(crate) const fn is_valid(&self) -> bool {
        self.state.is_some()
    }

    pub(crate) fn stamp(&self) -> SessionStamp {
        SessionStamp {
            revision: self.state().revision(),
            state_digest: self.state_digest,
            map_hash: self.world.map_hash(),
            ruleset_hash: self.world.ruleset_hash(),
        }
    }
}

#[cfg(test)]
mod tests {
    use aonw_engine::{EventBudget, MoveUnitCommand, PlayerCommand};

    use super::EventReservation;
    use crate::RuntimeError;

    fn movement_budget() -> EventBudget {
        let unit_id = aonw_domain::UnitId::new("unit-1").expect("unit id");
        PlayerCommand::MoveUnit(MoveUnitCommand::new(
            0,
            &unit_id,
            aonw_domain::HexCoord::new(1, 0),
        ))
        .event_budget(
            &aonw_domain::GameState::try_new(
                aonw_domain::StateRevision::INITIAL,
                1,
                aonw_domain::HexGridBounds::new(1, 1).expect("bounds"),
                aonw_domain::UnitOccupancyPolicy::Exclusive,
                [],
            )
            .expect("state"),
        )
    }

    #[test]
    fn reservation_preflights_offset_and_enforces_actual_count() {
        let budget = movement_budget();
        assert_eq!(
            EventReservation::try_new(u64::MAX, budget),
            Err(RuntimeError::EventOffsetOverflow)
        );

        let reservation = EventReservation::try_new(7, budget).expect("reserve");
        assert_eq!(reservation.committed_offset(1), Ok(8));

        let reservation = EventReservation::try_new(7, budget).expect("reserve");
        assert_eq!(
            reservation.committed_offset(2),
            Err(RuntimeError::EventBudgetExceeded {
                maximum: 1,
                actual: 2,
            })
        );

        let reservation = EventReservation::try_new(7, EventBudget::new(3)).expect("reserve");
        assert_eq!(reservation.committed_offset(2), Ok(9));
    }
}
