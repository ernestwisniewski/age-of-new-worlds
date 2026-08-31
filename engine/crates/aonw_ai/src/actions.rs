use core::cmp::Ordering;

use aonw_domain::{HexCoord, MovementUnits};
use aonw_local_runtime::{
    LocalRuntime, MoveUnitRequest, PlayerViewSnapshot, ReachableRequest, RuntimeError,
    RuntimeQuery, RuntimeQueryResult,
};

use crate::PlannedCommand;

#[derive(Clone, Debug, Eq, PartialEq)]
pub(crate) struct MoveCandidate {
    request: MoveUnitRequest,
    distance_to_known_opponent: Option<u64>,
    cost: MovementUnits,
}

impl MoveCandidate {
    pub(crate) fn request(&self) -> &MoveUnitRequest {
        &self.request
    }

    pub(crate) fn into_request(self) -> MoveUnitRequest {
        self.request
    }

    pub(crate) fn into_command(self) -> PlannedCommand {
        PlannedCommand::MoveUnit(self.request)
    }

    pub(crate) const fn distance_to_known_opponent(&self) -> Option<u64> {
        self.distance_to_known_opponent
    }
}

pub(crate) fn legal_move_candidates(
    runtime: &mut LocalRuntime,
    snapshot: &PlayerViewSnapshot,
) -> Result<Vec<MoveCandidate>, RuntimeError> {
    let mut candidates = Vec::new();
    visit_legal_move_candidates(runtime, snapshot, false, |candidate| {
        candidates.push(candidate);
    })?;
    candidates.sort_by(compare_candidates);
    Ok(candidates)
}

pub(crate) fn bounded_tactical_move_candidates(
    runtime: &mut LocalRuntime,
    snapshot: &PlayerViewSnapshot,
    limit: usize,
) -> Result<Vec<MoveCandidate>, RuntimeError> {
    let mut candidates = Vec::with_capacity(limit);
    visit_legal_move_candidates(runtime, snapshot, true, |candidate| {
        let index = candidates
            .binary_search_by(|current| compare_candidates(current, &candidate))
            .unwrap_or_else(core::convert::identity);
        if index < limit {
            candidates.insert(index, candidate);
            if candidates.len() > limit {
                candidates.pop();
            }
        }
    })?;
    Ok(candidates)
}

pub(crate) fn best_move_command(
    runtime: &mut LocalRuntime,
    snapshot: &PlayerViewSnapshot,
) -> Result<Option<PlannedCommand>, RuntimeError> {
    let mut selected: Option<MoveCandidate> = None;
    visit_legal_move_candidates(runtime, snapshot, false, |candidate| {
        if selected
            .as_ref()
            .is_none_or(|current| compare_candidates(&candidate, current).is_lt())
        {
            selected = Some(candidate);
        }
    })?;
    Ok(selected.map(MoveCandidate::into_command))
}

fn visit_legal_move_candidates(
    runtime: &mut LocalRuntime,
    snapshot: &PlayerViewSnapshot,
    tactical_only: bool,
    mut visit: impl FnMut(MoveCandidate),
) -> Result<(), RuntimeError> {
    let recipient = snapshot.recipient_player_id();
    let known_opponents = snapshot
        .units()
        .iter()
        .filter(|unit| unit.owner_player_id() != recipient)
        .map(|unit| HexCoord::new(unit.col(), unit.row()))
        .chain(
            snapshot
                .cities()
                .iter()
                .filter(|city| city.owner_player_id() != recipient)
                .map(aonw_local_runtime::PlayerCityView::center),
        )
        .collect::<Vec<_>>();
    let revision = snapshot.stamp().revision.get();
    for unit in snapshot.units().iter().filter(|unit| {
        unit.owner_player_id() == recipient
            && unit.movement_units() > 0
            && (!tactical_only || crate::strategy::is_military(unit.kind()))
    }) {
        let origin = HexCoord::new(unit.col(), unit.row());
        let response = match runtime.query(&RuntimeQuery::Reachable(ReachableRequest {
            expected_revision: revision,
            unit_id: unit.id().clone(),
        })) {
            Ok(response) => response,
            Err(RuntimeError::Query(_)) => continue,
            Err(error) => return Err(error),
        };
        let RuntimeQueryResult::Reachable(reachable) = response else {
            unreachable!("reachable query returns reachable response")
        };
        for tile in reachable
            .tiles
            .iter()
            .filter(|tile| tile.coordinate != origin)
        {
            visit(MoveCandidate {
                request: MoveUnitRequest {
                    expected_revision: revision,
                    unit_id: unit.id().clone(),
                    target: tile.coordinate,
                },
                distance_to_known_opponent: known_opponents
                    .iter()
                    .map(|target| tile.coordinate.distance_to(*target))
                    .min(),
                cost: tile.cost,
            });
        }
    }
    Ok(())
}

pub(crate) fn compare_move_requests(left: &MoveUnitRequest, right: &MoveUnitRequest) -> Ordering {
    left.unit_id
        .cmp(&right.unit_id)
        .then_with(|| left.target.cmp(&right.target))
}

fn compare_candidates(left: &MoveCandidate, right: &MoveCandidate) -> Ordering {
    compare_immediate_utility(left, right)
        .then_with(|| compare_move_requests(&left.request, &right.request))
}

fn compare_immediate_utility(left: &MoveCandidate, right: &MoveCandidate) -> Ordering {
    left.distance_to_known_opponent
        .unwrap_or(u64::MAX)
        .cmp(&right.distance_to_known_opponent.unwrap_or(u64::MAX))
        .then_with(|| left.cost.cmp(&right.cost))
}
