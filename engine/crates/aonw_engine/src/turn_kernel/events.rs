use aonw_domain::PlayerId;

use crate::{AllPlayersSubmittedEvent, DomainEvent, PlayerTimedOutEvent, TurnEndedEvent};

pub(super) struct TurnPhaseEvents {
    pub(super) settlement: Vec<DomainEvent>,
    pub(super) movement: Vec<DomainEvent>,
    pub(super) research: Vec<DomainEvent>,
    pub(super) diplomacy: Vec<DomainEvent>,
    pub(super) objectives: Vec<DomainEvent>,
    pub(super) stability: Vec<DomainEvent>,
    pub(super) outcome: Vec<DomainEvent>,
}

pub(super) fn sequential_phase_events(
    phases: TurnPhaseEvents,
    player_id: &PlayerId,
) -> Box<[DomainEvent]> {
    let mut events = Vec::with_capacity(
        phases.settlement.len()
            + phases.movement.len()
            + phases.research.len()
            + phases.diplomacy.len()
            + phases.objectives.len()
            + phases.stability.len()
            + phases.outcome.len()
            + 1,
    );
    events.extend(phases.settlement);
    events.extend(phases.movement);
    events.extend(phases.research);
    events.extend(phases.diplomacy);
    events.extend(phases.objectives);
    events.extend(phases.stability);
    events.extend(phases.outcome);
    events.push(DomainEvent::TurnEnded(TurnEndedEvent::new(
        player_id.clone(),
    )));
    events.into_boxed_slice()
}

pub(super) fn simultaneous_phase_events(
    current_turn: u32,
    scope: &[PlayerId],
    skipped: &[PlayerId],
    combat: Box<[DomainEvent]>,
    phases: TurnPhaseEvents,
) -> Box<[DomainEvent]> {
    let mut events = Vec::with_capacity(
        skipped.len()
            + 1
            + combat.len()
            + phases.settlement.len()
            + phases.movement.len()
            + phases.research.len()
            + phases.diplomacy.len()
            + phases.objectives.len()
            + phases.stability.len()
            + phases.outcome.len()
            + scope.len(),
    );
    events.extend(
        skipped.iter().cloned().map(|player| {
            DomainEvent::PlayerTimedOut(PlayerTimedOutEvent::new(current_turn, player))
        }),
    );
    events.push(DomainEvent::AllPlayersSubmitted(
        AllPlayersSubmittedEvent::new(current_turn, scope.to_vec()),
    ));
    events.extend(combat);
    events.extend(phases.settlement);
    events.extend(phases.movement);
    events.extend(phases.research);
    events.extend(phases.diplomacy);
    events.extend(phases.objectives);
    events.extend(phases.stability);
    events.extend(phases.outcome);
    events.extend(
        scope
            .iter()
            .cloned()
            .map(TurnEndedEvent::new)
            .map(DomainEvent::TurnEnded),
    );
    events.into_boxed_slice()
}
