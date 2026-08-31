use core::cmp::Ordering;

use aonw_domain::{CityId, PlayerId, UnitId};
use aonw_engine::{CombatExecution, CombatTarget, DomainEvent, ExecutionEvidence};

use crate::{PlayerCityView, PlayerUnitView};

#[derive(Clone, Debug, Eq, PartialEq)]
/// Recipient-specific visibility policy for events and execution evidence.
pub struct RecipientDisclosure {
    actor: PlayerId,
    unit_ids: Box<[UnitId]>,
    city_ids: Box<[CityId]>,
    combats: Box<[(UnitId, CombatTarget)]>,
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
            actor,
            unit_ids: visible_units.iter().map(|unit| unit.id().clone()).collect(),
            city_ids: visible_cities
                .iter()
                .map(|city| city.id().clone())
                .collect(),
            combats: combats.into_boxed_slice(),
        }
    }

    /// Creates a disclosure that reveals no entity-specific details.
    #[must_use]
    pub fn empty(actor: PlayerId) -> Self {
        Self {
            actor,
            unit_ids: Box::new([]),
            city_ids: Box::new([]),
            combats: Box::new([]),
        }
    }

    /// Returns whether one unit is visible to the recipient.
    #[must_use]
    pub fn allows_unit(&self, unit_id: &UnitId) -> bool {
        self.unit_ids.binary_search(unit_id).is_ok()
    }

    /// Returns whether all parties of one combat are visible.
    #[must_use]
    pub fn allows_combat(&self, execution: &CombatExecution) -> bool {
        self.allows(
            &execution.preview.attacker_unit_id,
            &execution.preview.target,
        )
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
                value.owner_player_id() == &self.actor || self.allows_unit(value.unit_id())
            }
            DomainEvent::ArtifactCarried(value) => {
                value.owner_player_id() == &self.actor || self.allows_unit(value.unit_id())
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
            DomainEvent::CityClaimedHex(value) => self.allows_city(value.city_id()),
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
            DomainEvent::UnitMoved(value) => self.allows_unit(value.unit_id()),
            DomainEvent::AutoExplorePlanned(value) => self.allows_unit(value.unit_id()),
            DomainEvent::MerchantRouteAssigned(value) => self.allows_unit(value.unit_id()),
            DomainEvent::MerchantTravelQueued(value) => self.allows_unit(value.unit_id()),
            DomainEvent::TroopDetached(value) => self.allows_unit(value.source_unit_id()),
            DomainEvent::WorkerCompletedJob(value) => self.allows_unit(value.unit_id()),
            DomainEvent::MatchEnded(_)
            | DomainEvent::DominationThresholdReached(_)
            | DomainEvent::TurnEnded(_)
            | DomainEvent::AllPlayersSubmitted(_)
            | DomainEvent::PlayerTimedOut(_)
            | DomainEvent::PlayerKicked(_) => true,
        }
    }

    fn allows(&self, attacker: &UnitId, target: &CombatTarget) -> bool {
        self.combats
            .binary_search_by(|candidate| compare_combat_parts(candidate, attacker, target))
            .is_ok()
    }
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
