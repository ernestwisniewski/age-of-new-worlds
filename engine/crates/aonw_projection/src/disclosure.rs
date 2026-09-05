use core::cmp::Ordering;

use aonw_domain::{CityId, HexCoord, PlayerId, UnitId};
use aonw_engine::{
    CombatExecution, CombatTarget, DomainEvent, ExecutionEvidence, LogisticsExecution,
    UnitMovementExecution,
};

use crate::{PlayerCityView, PlayerFogView, PlayerUnitView, ProjectedView};

#[derive(Clone, Debug, Eq, PartialEq)]
/// Recipient-specific visibility policy for events and execution evidence.
pub struct RecipientDisclosure {
    actor: PlayerId,
    unit_ids: Box<[UnitId]>,
    owned_unit_ids: Box<[UnitId]>,
    city_ids: Box<[CityId]>,
    combats: Box<[(UnitId, CombatTarget)]>,
    observed_fog: Option<(PlayerFogView, PlayerFogView)>,
}

impl RecipientDisclosure {
    /// Captures visibility before one accepted transition.
    #[must_use]
    pub fn new(
        actor: PlayerId,
        visible_units: &[PlayerUnitView],
        visible_cities: &[PlayerCityView],
        evidence: Option<&ExecutionEvidence>,
    ) -> Self {
        debug_assert!(
            visible_units
                .windows(2)
                .all(|pair| pair[0].id() < pair[1].id())
        );
        debug_assert!(
            visible_cities
                .windows(2)
                .all(|pair| pair[0].id() < pair[1].id())
        );
        let mut combats = Vec::new();
        match evidence {
            Some(ExecutionEvidence::Combat(execution)) => {
                push_visible_combat(&mut combats, execution, visible_units, visible_cities);
            }
            Some(ExecutionEvidence::TurnKernel(execution)) => {
                for combat in execution.combat_executions() {
                    push_visible_combat(&mut combats, combat, visible_units, visible_cities);
                }
            }
            Some(
                ExecutionEvidence::UnitMovement(_)
                | ExecutionEvidence::Logistics(_)
                | ExecutionEvidence::WorkerAutomation(_),
            )
            | None => {}
        }
        combats.sort_unstable_by(compare_combat);
        combats.dedup();
        Self {
            owned_unit_ids: visible_units
                .iter()
                .filter(|unit| unit.owner_player_id() == &actor)
                .map(|unit| unit.id().clone())
                .collect(),
            actor,
            unit_ids: visible_units.iter().map(|unit| unit.id().clone()).collect(),
            city_ids: visible_cities
                .iter()
                .map(|city| city.id().clone())
                .collect(),
            combats: combats.into_boxed_slice(),
            observed_fog: None,
        }
    }

    /// Captures a fixed viewer's disclosure across another actor's command.
    #[must_use]
    pub fn observed_transition(
        actor: PlayerId,
        before: &ProjectedView,
        after: &ProjectedView,
        evidence: Option<&ExecutionEvidence>,
    ) -> Self {
        let fog = before.fog();
        let visible_cities: Vec<_> = before
            .cities()
            .iter()
            .filter(|city| {
                city.owner_player_id() == &actor
                    || !fog.enabled()
                    || fog.visible_hexes().binary_search(&city.center()).is_ok()
            })
            .cloned()
            .collect();
        let mut value = Self::new(actor, before.units(), &visible_cities, evidence);
        value.unit_ids = extend_ids(
            value.unit_ids,
            after.units().iter().map(|unit| unit.id().clone()),
        );
        value.owned_unit_ids = extend_ids(
            value.owned_unit_ids,
            after
                .units()
                .iter()
                .filter(|unit| unit.owner_player_id() == &value.actor)
                .map(|unit| unit.id().clone()),
        );
        value.city_ids = extend_ids(
            value.city_ids,
            after
                .cities()
                .iter()
                .filter(|city| {
                    city.owner_player_id() == &value.actor
                        || !after.fog().enabled()
                        || after
                            .fog()
                            .visible_hexes()
                            .binary_search(&city.center())
                            .is_ok()
                })
                .map(|city| city.id().clone()),
        );
        if fog.enabled() && after.fog().enabled() {
            value.observed_fog = Some((fog.clone(), after.fog().clone()));
        }
        value
    }

    /// Creates a disclosure that reveals no entity-specific details.
    #[must_use]
    pub fn empty(actor: PlayerId) -> Self {
        Self {
            actor,
            unit_ids: Box::new([]),
            owned_unit_ids: Box::new([]),
            city_ids: Box::new([]),
            combats: Box::new([]),
            observed_fog: None,
        }
    }

    /// Returns whether one unit is visible to the recipient.
    #[must_use]
    pub fn allows_unit(&self, unit_id: &UnitId) -> bool {
        self.unit_ids.binary_search(unit_id).is_ok()
    }

    /// Returns whether private orders belong to the recipient.
    #[must_use]
    pub fn owns_unit(&self, unit_id: &UnitId) -> bool {
        self.owned_unit_ids.binary_search(unit_id).is_ok()
    }

    /// Returns whether an entire executed path is known to the recipient.
    #[must_use]
    pub fn allows_movement(&self, execution: &UnitMovementExecution) -> bool {
        self.allows_unit(execution.unit_id())
            && (self.owns_unit(execution.unit_id())
                || (self.allows_coordinate(execution.from())
                    && execution
                        .steps()
                        .iter()
                        .all(|step| self.allows_coordinate(step.coordinate()))))
    }

    /// Returns whether the recipient owns the orders described by logistics evidence.
    #[must_use]
    pub fn allows_logistics(&self, execution: &LogisticsExecution) -> bool {
        let unit_id = match execution {
            LogisticsExecution::AutoExplore { unit_id, .. }
            | LogisticsExecution::MerchantRouteAssigned { unit_id, .. }
            | LogisticsExecution::MerchantTravelQueued { unit_id, .. } => unit_id,
            LogisticsExecution::TroopDetached { source_unit_id, .. } => source_unit_id,
        };
        self.owns_unit(unit_id)
    }

    /// Returns whether all parties of one combat are visible.
    #[must_use]
    pub fn allows_combat(&self, execution: &CombatExecution) -> bool {
        self.allows(
            &execution.preview.attacker_unit_id,
            &execution.preview.target,
        ) && execution
            .outcome
            .defender_retreat
            .is_none_or(|coordinate| self.allows_coordinate(coordinate))
    }

    /// Returns whether one city is visible to the recipient.
    #[must_use]
    pub fn allows_city(&self, city_id: &CityId) -> bool {
        self.city_ids.binary_search(city_id).is_ok()
    }

    /// Returns whether one authoritative event is safe for the recipient.
    #[must_use]
    pub fn allows_event(&self, event: &DomainEvent) -> bool {
        match event {
            DomainEvent::ArtifactExcavationStarted(value) => {
                value.owner_player_id() == &self.actor
                    || (self.allows_unit(value.unit_id())
                        && self.allows_coordinate(value.coordinate()))
            }
            DomainEvent::ArtifactCarried(value) => {
                value.owner_player_id() == &self.actor
                    || (self.allows_unit(value.unit_id())
                        && self.allows_coordinate(value.coordinate()))
            }
            DomainEvent::ArtifactStored(value) => {
                value.owner_player_id() == &self.actor || self.allows_city(value.city_id())
            }
            DomainEvent::CityFounded(value) => {
                value.owner_player_id() == &self.actor || self.allows_city(value.city_id())
            }
            DomainEvent::CityBuiltBuilding(value) => self.allows_city(value.city_id()),
            DomainEvent::CityProducedUnit(value) => {
                self.allows_city(value.city_id()) || self.allows_unit(value.produced_unit_id())
            }
            DomainEvent::CityBuiltWonder(value) => {
                value.owner_player_id() == &self.actor || self.allows_city(value.city_id())
            }
            DomainEvent::WonderProductionRefunded(value) => {
                value.owner_player_id() == &self.actor || self.allows_city(value.city_id())
            }
            DomainEvent::TechnologyResearched(value) => value.player_id() == &self.actor,
            DomainEvent::ResearchPointsGained(value) => value.player_id() == &self.actor,
            DomainEvent::CityClaimedHex(value) => {
                self.allows_city(value.city_id()) && self.allows_coordinate(value.coordinate())
            }
            DomainEvent::StabilityBandChanged(value) => value.player_id() == &self.actor,
            DomainEvent::MapObjectiveSecured(value) => value.player_id() == &self.actor,
            DomainEvent::UnitAttacked(value)
            | DomainEvent::CityAttacked(value)
            | DomainEvent::CombatResolved(value)
            | DomainEvent::UnitGainedExperience(value)
            | DomainEvent::UnitKilled(value)
            | DomainEvent::UnitRetreated(value)
            | DomainEvent::CityCaptured(value)
            | DomainEvent::CityDestroyed(value) => {
                self.allows(value.attacker_unit_id(), value.target())
            }
            DomainEvent::DiplomaticScoreChanged(value) => {
                value.player_a_id() == &self.actor || value.player_b_id() == &self.actor
            }
            DomainEvent::DiplomaticProposalSent(value) => {
                value.from_player_id() == &self.actor || value.to_player_id() == &self.actor
            }
            DomainEvent::DiplomaticProposalResponded(value) => {
                value.from_player_id() == &self.actor || value.to_player_id() == &self.actor
            }
            DomainEvent::DiplomaticProposalExpired(value) => {
                value.from_player_id() == &self.actor || value.to_player_id() == &self.actor
            }
            DomainEvent::DiplomaticMessageSent(value) => {
                value.from_player_id() == &self.actor || value.to_player_id() == &self.actor
            }
            DomainEvent::DiplomaticMessageResponded(value) => {
                value.from_player_id() == &self.actor || value.to_player_id() == &self.actor
            }
            DomainEvent::DiplomaticPromiseBroken(value) => {
                value.player_a_id() == &self.actor || value.player_b_id() == &self.actor
            }
            DomainEvent::DiplomaticRelationChanged(value) => {
                value.player_a_id() == &self.actor || value.player_b_id() == &self.actor
            }
            DomainEvent::UnitMoved(value) => {
                self.owns_unit(value.unit_id())
                    || (self.allows_unit(value.unit_id())
                        && self.allows_coordinate(value.from())
                        && self.allows_coordinate(value.to()))
            }
            DomainEvent::AutoExplorePlanned(value) => self.owns_unit(value.unit_id()),
            DomainEvent::MerchantRouteAssigned(value) => self.owns_unit(value.unit_id()),
            DomainEvent::MerchantTravelQueued(value) => self.owns_unit(value.unit_id()),
            DomainEvent::TroopDetached(value) => self.owns_unit(value.source_unit_id()),
            DomainEvent::WorkerCompletedJob(value) => {
                self.owns_unit(value.unit_id())
                    || (self.allows_unit(value.unit_id()) && self.allows_coordinate(value.target()))
            }
            DomainEvent::MatchEnded(_)
            | DomainEvent::DominationThresholdReached(_)
            | DomainEvent::TurnEnded(_)
            | DomainEvent::AllPlayersSubmitted(_)
            | DomainEvent::PlayerTimedOut(_)
            | DomainEvent::PlayerKicked(_)
            | DomainEvent::PlayerResigned(_) => true,
        }
    }

    fn allows(&self, attacker: &UnitId, target: &CombatTarget) -> bool {
        self.combats
            .binary_search_by(|candidate| compare_combat_parts(candidate, attacker, target))
            .is_ok()
    }

    fn allows_coordinate(&self, coordinate: HexCoord) -> bool {
        self.observed_fog.as_ref().is_none_or(|(before, after)| {
            before.visible_hexes().binary_search(&coordinate).is_ok()
                || after.visible_hexes().binary_search(&coordinate).is_ok()
        })
    }
}

fn extend_ids<T: Ord>(current: Box<[T]>, next: impl Iterator<Item = T>) -> Box<[T]> {
    let mut values = current.into_vec();
    values.extend(next);
    values.sort_unstable();
    values.dedup();
    values.into_boxed_slice()
}

fn push_visible_combat(
    output: &mut Vec<(UnitId, CombatTarget)>,
    execution: &CombatExecution,
    visible_units: &[PlayerUnitView],
    visible_cities: &[PlayerCityView],
) {
    let preview = &execution.preview;
    let attacker_visible = visible_units
        .binary_search_by(|unit| unit.id().cmp(&preview.attacker_unit_id))
        .is_ok();
    let target_visible = match &preview.target {
        CombatTarget::Unit(id) => visible_units
            .binary_search_by(|unit| unit.id().cmp(id))
            .is_ok(),
        CombatTarget::City(id) => visible_cities
            .binary_search_by(|city| city.id().cmp(id))
            .is_ok(),
    };
    if attacker_visible && target_visible {
        output.push((preview.attacker_unit_id.clone(), preview.target.clone()));
    }
}

fn compare_combat(left: &(UnitId, CombatTarget), right: &(UnitId, CombatTarget)) -> Ordering {
    compare_combat_parts(left, &right.0, &right.1)
}

fn compare_combat_parts(
    left: &(UnitId, CombatTarget),
    right_attacker: &UnitId,
    right_target: &CombatTarget,
) -> Ordering {
    left.0
        .cmp(right_attacker)
        .then_with(|| compare_target(&left.1, right_target))
}

fn compare_target(left: &CombatTarget, right: &CombatTarget) -> Ordering {
    match (left, right) {
        (CombatTarget::Unit(left), CombatTarget::Unit(right)) => left.cmp(right),
        (CombatTarget::City(left), CombatTarget::City(right)) => left.cmp(right),
        (CombatTarget::Unit(_), CombatTarget::City(_)) => Ordering::Less,
        (CombatTarget::City(_), CombatTarget::Unit(_)) => Ordering::Greater,
    }
}
