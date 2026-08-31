mod diplomacy;
mod economy;
mod logistics;
mod movement;
mod objective;

use crate::{
    encode_city_building, encode_city_wonder, encode_message_category, encode_message_response,
    encode_message_topic, encode_proposal_kind, encode_relation_reason, encode_relation_status,
    encode_score_reason, encode_technology, encode_troop, encode_unit_kind,
};
use aonw_contracts::client::{ClientEventDto, ClientEvidenceDto, WorkerJobCompletionDto};
use aonw_contracts::{
    CombatExecutionDto, CombatModifierDto, CombatModifierKindDto, CombatOutcomeDto,
    CombatPreviewDto, CombatRollDto, CombatStatTargetDto, CombatStatsDto, CombatTargetDto,
};
use aonw_engine::{
    CombatExecution, CombatModifierKind, CombatPreview, CombatStatTarget, CombatTarget,
    DomainEvent, EffectiveCombatStats, ExecutionEvidence,
};

use aonw_projection::RecipientDisclosure;

use super::coordinate;
use super::worker::encode_worker_automation_option;
use logistics::{logistics_evidence, movement_execution};

#[allow(clippy::too_many_lines)]
/// Maps a canonical domain event to its strict current client DTO.
///
/// # Panics
///
/// Panics if an engine-produced unit combat event omits its required subject unit.
#[must_use]
pub fn encode_client_event(value: &DomainEvent) -> ClientEventDto {
    match value {
        DomainEvent::ArtifactExcavationStarted(value) => {
            ClientEventDto::ArtifactExcavationStarted {
                artifact_id: value.artifact_id().as_str().to_owned(),
                owner_player_id: value.owner_player_id().as_str().to_owned(),
                unit_id: value.unit_id().as_str().to_owned(),
                coordinate: coordinate(value.coordinate()),
            }
        }
        DomainEvent::ArtifactCarried(value) => ClientEventDto::ArtifactCarried {
            artifact_id: value.artifact_id().as_str().to_owned(),
            owner_player_id: value.owner_player_id().as_str().to_owned(),
            unit_id: value.unit_id().as_str().to_owned(),
            coordinate: coordinate(value.coordinate()),
        },
        DomainEvent::ArtifactStored(value) => ClientEventDto::ArtifactStored {
            artifact_id: value.artifact_id().as_str().to_owned(),
            owner_player_id: value.owner_player_id().as_str().to_owned(),
            source_unit_id: value.source_unit_id().map(|unit| unit.as_str().to_owned()),
            city_id: value.city_id().as_str().to_owned(),
            coordinate: coordinate(value.coordinate()),
        },
        DomainEvent::CityFounded(value) => ClientEventDto::CityFounded {
            city_id: value.city_id().as_str().to_owned(),
            owner_player_id: value.owner_player_id().as_str().to_owned(),
        },
        DomainEvent::CityBuiltBuilding(value) => ClientEventDto::CityBuiltBuilding {
            city_id: value.city_id().as_str().to_owned(),
            building_type: encode_city_building(value.building()),
        },
        DomainEvent::CityProducedUnit(value) => ClientEventDto::CityProducedUnit {
            city_id: value.city_id().as_str().to_owned(),
            unit_type: encode_unit_kind(value.unit()),
            produced_unit_id: value.produced_unit_id().as_str().to_owned(),
        },
        DomainEvent::CityBuiltWonder(value) => ClientEventDto::CityBuiltWonder {
            city_id: value.city_id().as_str().to_owned(),
            owner_player_id: value.owner_player_id().as_str().to_owned(),
            wonder_type: encode_city_wonder(value.wonder()),
        },
        DomainEvent::WonderProductionRefunded(value) => ClientEventDto::WonderProductionRefunded {
            city_id: value.city_id().as_str().to_owned(),
            owner_player_id: value.owner_player_id().as_str().to_owned(),
            wonder_type: encode_city_wonder(value.wonder()),
            refunded_production: value.refunded_production(),
        },
        DomainEvent::TechnologyResearched(value) => ClientEventDto::TechnologyResearched {
            player_id: value.player_id().as_str().to_owned(),
            technology_id: encode_technology(value.technology()),
        },
        DomainEvent::ResearchPointsGained(value) => ClientEventDto::ResearchPointsGained {
            player_id: value.player_id().as_str().to_owned(),
            points: value.points(),
        },
        DomainEvent::CityClaimedHex(value) => economy::city_claimed(value),
        DomainEvent::StabilityBandChanged(value) => economy::stability_changed(value),
        DomainEvent::MapObjectiveSecured(value) => objective::map_secured(value),
        DomainEvent::DominationThresholdReached(value) => objective::domination(value),
        DomainEvent::MatchEnded(value) => ClientEventDto::MatchEnded {
            turn: value.turn(),
            outcome: crate::encode_game_outcome(value.outcome()),
        },
        DomainEvent::UnitAttacked(value) => combat_event(value, |attacker_unit_id, target, _| {
            ClientEventDto::UnitAttacked {
                attacker_unit_id,
                target,
            }
        }),
        DomainEvent::CityAttacked(value) => combat_event(value, |attacker_unit_id, target, _| {
            ClientEventDto::CityAttacked {
                attacker_unit_id,
                target,
            }
        }),
        DomainEvent::CombatResolved(value) => combat_event(value, |attacker_unit_id, target, _| {
            ClientEventDto::CombatResolved {
                attacker_unit_id,
                target,
            }
        }),
        DomainEvent::DiplomaticScoreChanged(value) => ClientEventDto::DiplomaticScoreChanged {
            player_a_id: value.player_a_id().as_str().to_owned(),
            player_b_id: value.player_b_id().as_str().to_owned(),
            delta: value.delta(),
            score_after: value.score_after(),
            reason: encode_score_reason(value.reason()),
            source_id: value.source_id().map(str::to_owned),
        },
        DomainEvent::DiplomaticProposalSent(value) => ClientEventDto::DiplomaticProposalSent {
            proposal_id: value.proposal_id().to_owned(),
            from_player_id: value.from_player_id().as_str().to_owned(),
            to_player_id: value.to_player_id().as_str().to_owned(),
            kind: encode_proposal_kind(value.kind()),
            expires_on_turn: value.expires_on_turn(),
        },
        DomainEvent::DiplomaticProposalResponded(value) => {
            ClientEventDto::DiplomaticProposalResponded {
                proposal_id: value.proposal_id().to_owned(),
                from_player_id: value.from_player_id().as_str().to_owned(),
                to_player_id: value.to_player_id().as_str().to_owned(),
                kind: encode_proposal_kind(value.kind()),
                accepted: value.accepted(),
            }
        }
        DomainEvent::DiplomaticProposalExpired(value) => diplomacy::proposal_expired(value),
        DomainEvent::DiplomaticMessageSent(value) => ClientEventDto::DiplomaticMessageSent {
            message_id: value.message_id().to_owned(),
            from_player_id: value.from_player_id().as_str().to_owned(),
            to_player_id: value.to_player_id().as_str().to_owned(),
            topic: encode_message_topic(value.topic()),
            category: encode_message_category(value.category()),
            expires_on_turn: value.expires_on_turn(),
        },
        DomainEvent::DiplomaticMessageResponded(value) => {
            ClientEventDto::DiplomaticMessageResponded {
                message_id: value.message_id().to_owned(),
                from_player_id: value.from_player_id().as_str().to_owned(),
                to_player_id: value.to_player_id().as_str().to_owned(),
                topic: encode_message_topic(value.topic()),
                response: encode_message_response(value.response()),
                relation_delta: value.relation_delta(),
                relation_score_after: value.relation_score_after(),
                promise_due_turn: value.promise_due_turn(),
            }
        }
        DomainEvent::DiplomaticPromiseBroken(value) => diplomacy::promise_broken(value),
        DomainEvent::DiplomaticRelationChanged(value) => {
            ClientEventDto::DiplomaticRelationChanged {
                player_a_id: value.player_a_id().as_str().to_owned(),
                player_b_id: value.player_b_id().as_str().to_owned(),
                old_status: encode_relation_status(value.old_status()),
                new_status: encode_relation_status(value.new_status()),
                reason: encode_relation_reason(value.reason()),
                expires_on_turn: value.expires_on_turn(),
            }
        }
        DomainEvent::UnitGainedExperience(value) => {
            combat_event(value, |attacker_unit_id, target, subject_unit_id| {
                ClientEventDto::UnitGainedExperience {
                    attacker_unit_id,
                    target,
                    subject_unit_id: subject_unit_id.expect("experience subject"),
                }
            })
        }
        DomainEvent::UnitKilled(value) => {
            combat_event(value, |attacker_unit_id, target, subject_unit_id| {
                ClientEventDto::UnitKilled {
                    attacker_unit_id,
                    target,
                    subject_unit_id: subject_unit_id.expect("casualty subject"),
                }
            })
        }
        DomainEvent::UnitRetreated(value) => {
            combat_event(value, |attacker_unit_id, target, subject_unit_id| {
                ClientEventDto::UnitRetreated {
                    attacker_unit_id,
                    target,
                    subject_unit_id: subject_unit_id.expect("retreat subject"),
                }
            })
        }
        DomainEvent::CityCaptured(value) => combat_event(value, |attacker_unit_id, target, _| {
            ClientEventDto::CityCaptured {
                attacker_unit_id,
                target,
            }
        }),
        DomainEvent::CityDestroyed(value) => combat_event(value, |attacker_unit_id, target, _| {
            ClientEventDto::CityDestroyed {
                attacker_unit_id,
                target,
            }
        }),
        DomainEvent::UnitMoved(value) => ClientEventDto::UnitMoved {
            unit_id: value.unit_id().as_str().to_owned(),
            from: coordinate(value.from()),
            to: coordinate(value.to()),
        },
        DomainEvent::AutoExplorePlanned(value) => ClientEventDto::AutoExplorePlanned {
            unit_id: value.unit_id().as_str().to_owned(),
            target: coordinate(value.target()),
        },
        DomainEvent::MerchantRouteAssigned(value) => ClientEventDto::MerchantRouteAssigned {
            unit_id: value.unit_id().as_str().to_owned(),
            origin_city_id: value.origin_city_id().as_str().to_owned(),
            destination_city_id: value.destination_city_id().as_str().to_owned(),
        },
        DomainEvent::MerchantTravelQueued(value) => ClientEventDto::MerchantTravelQueued {
            unit_id: value.unit_id().as_str().to_owned(),
            destination_city_id: value.destination_city_id().as_str().to_owned(),
        },
        DomainEvent::TroopDetached(value) => ClientEventDto::TroopDetached {
            source_unit_id: value.source_unit_id().as_str().to_owned(),
            detached_unit_id: value.detached_unit_id().as_str().to_owned(),
            troop_kind: encode_troop(value.troop_kind()),
            destination: coordinate(value.destination()),
        },
        DomainEvent::TurnEnded(value) => ClientEventDto::TurnEnded {
            player_id: value.player_id().as_str().to_owned(),
        },
        DomainEvent::AllPlayersSubmitted(value) => ClientEventDto::AllPlayersSubmitted {
            turn: value.turn(),
            player_ids: value
                .player_ids()
                .iter()
                .map(|player| player.as_str().to_owned())
                .collect(),
        },
        DomainEvent::PlayerTimedOut(value) => ClientEventDto::PlayerTimedOut {
            turn: value.turn(),
            player_id: value.player_id().as_str().to_owned(),
        },
        DomainEvent::PlayerKicked(value) => ClientEventDto::PlayerKicked {
            turn: value.turn(),
            player_id: value.player_id().as_str().to_owned(),
            reason: value.reason().to_owned(),
            timeout_streak: value.timeout_streak(),
        },
        DomainEvent::WorkerCompletedJob(value) => ClientEventDto::WorkerCompletedJob {
            unit_id: value.unit_id().as_str().to_owned(),
            target: coordinate(value.target()),
            completion: match value.completion() {
                aonw_engine::WorkerJobCompletion::FieldImprovement(improvement) => {
                    WorkerJobCompletionDto::FieldImprovement {
                        improvement: crate::encode_improvement(improvement),
                    }
                }
                aonw_engine::WorkerJobCompletion::Road => WorkerJobCompletionDto::Road,
            },
        },
    }
}

/// Maps complete command execution evidence to its strict current client DTO.
///
/// # Panics
///
/// Panics if complete evidence is unexpectedly rejected by the unfiltered encoder.
#[must_use]
pub fn encode_client_evidence(value: &ExecutionEvidence) -> ClientEvidenceDto {
    encode_evidence(value, |_| true, |_| true, |_| true)
        .expect("unfiltered evidence is always visible")
}

/// Maps command evidence only when the recipient disclosure permits it.
#[must_use]
pub fn encode_recipient_evidence(
    value: &ExecutionEvidence,
    disclosure: &RecipientDisclosure,
) -> Option<ClientEvidenceDto> {
    encode_evidence(
        value,
        |combat| disclosure.allows_combat(combat),
        |unit| disclosure.allows_unit(unit),
        |city| disclosure.allows_city(city),
    )
}

fn encode_evidence(
    value: &ExecutionEvidence,
    allows_combat: impl Fn(&CombatExecution) -> bool,
    allows_unit: impl Fn(&aonw_domain::UnitId) -> bool,
    allows_city: impl Fn(&aonw_domain::CityId) -> bool,
) -> Option<ClientEvidenceDto> {
    match value {
        ExecutionEvidence::Combat(value) => {
            allows_combat(value).then(|| ClientEvidenceDto::Combat {
                execution: combat_execution(value),
            })
        }
        ExecutionEvidence::UnitMovement(value) => Some(ClientEvidenceDto::UnitMovement {
            unit_id: value.unit_id().as_str().to_owned(),
            from: coordinate(value.from()),
            steps: value.steps().iter().map(movement::step).collect(),
        }),
        ExecutionEvidence::Logistics(value) => Some(ClientEvidenceDto::Logistics {
            execution: logistics_evidence(value),
        }),
        ExecutionEvidence::TurnKernel(value) => Some(ClientEvidenceDto::TurnKernel {
            processors: value
                .processors()
                .iter()
                .map(|processor| processor.as_str().to_owned())
                .collect(),
            founded_city_ids: value
                .founded_city_ids()
                .iter()
                .filter(|city| allows_city(city))
                .map(|city| city.as_str().to_owned())
                .collect(),
            combat_executions: value
                .combat_executions()
                .iter()
                .filter(|combat| allows_combat(combat))
                .map(combat_execution)
                .collect(),
            reset_unit_ids: value
                .reset_unit_ids()
                .iter()
                .filter(|unit| allows_unit(unit))
                .map(|unit| unit.as_str().to_owned())
                .collect(),
            movement_executions: value
                .movement_executions()
                .iter()
                .filter(|movement| allows_unit(movement.unit_id()))
                .map(movement_execution)
                .collect(),
            invalidated_order_unit_ids: value
                .invalidated_order_unit_ids()
                .iter()
                .filter(|unit| allows_unit(unit))
                .map(|unit| unit.as_str().to_owned())
                .collect(),
            finished_auto_explore_unit_ids: value
                .finished_auto_explore_unit_ids()
                .iter()
                .filter(|unit| allows_unit(unit))
                .map(|unit| unit.as_str().to_owned())
                .collect(),
        }),
        ExecutionEvidence::WorkerAutomation(value) => {
            allows_unit(value.unit_id()).then(|| ClientEvidenceDto::WorkerAutomation {
                unit_id: value.unit_id().as_str().to_owned(),
                option: encode_worker_automation_option(value.option()),
                movement: value.movement().map(movement_execution),
            })
        }
    }
}

fn combat_event(
    value: &aonw_engine::CombatEvent,
    build: impl FnOnce(String, CombatTargetDto, Option<String>) -> ClientEventDto,
) -> ClientEventDto {
    build(
        value.attacker_unit_id().as_str().to_owned(),
        combat_target(value.target()),
        value.subject_unit_id().map(|unit| unit.as_str().to_owned()),
    )
}

/// Maps a canonical combat preview to its strict current client DTO.
#[must_use]
pub fn encode_combat_preview(value: &CombatPreview) -> CombatPreviewDto {
    CombatPreviewDto {
        attacker_unit_id: value.attacker_unit_id.as_str().to_owned(),
        target: combat_target(&value.target),
        distance: value.distance,
        attacker: combat_stats(&value.attacker),
        defender: combat_stats(&value.defender),
        outgoing_damage_min: value.outgoing_damage.0,
        outgoing_damage_max: value.outgoing_damage.1,
        retaliation_damage_min: value.retaliation_damage.map(|bounds| bounds.0),
        retaliation_damage_max: value.retaliation_damage.map(|bounds| bounds.1),
    }
}

fn combat_execution(value: &CombatExecution) -> CombatExecutionDto {
    CombatExecutionDto {
        seed: value.seed,
        rolls: value
            .rolls
            .iter()
            .map(|roll| CombatRollDto { value: roll.value })
            .collect(),
        preview: encode_combat_preview(&value.preview),
        outcome: CombatOutcomeDto {
            attacker_hit_points: value.outcome.attacker_hit_points,
            defender_hit_points: value.outcome.defender_hit_points,
            attacker_killed: value.outcome.attacker_killed,
            defender_killed: value.outcome.defender_killed,
            defender_retreat: value.outcome.defender_retreat.map(coordinate),
            outgoing_damage: value.outcome.outgoing_damage,
            retaliation_damage: value.outcome.retaliation_damage,
        },
    }
}

fn combat_target(value: &CombatTarget) -> CombatTargetDto {
    match value {
        CombatTarget::Unit(id) => CombatTargetDto::Unit {
            unit_id: id.as_str().to_owned(),
        },
        CombatTarget::City(id) => CombatTargetDto::City {
            city_id: id.as_str().to_owned(),
        },
    }
}

fn combat_stats(value: &EffectiveCombatStats) -> CombatStatsDto {
    CombatStatsDto {
        attack: value.attack,
        defense: value.defense,
        hit_points: value.hit_points,
        range: value.range,
        mobility: value.mobility,
        modifiers: value
            .modifiers
            .iter()
            .map(|modifier| CombatModifierDto {
                kind: match modifier.kind {
                    CombatModifierKind::Terrain => CombatModifierKindDto::Terrain,
                    CombatModifierKind::Fortification => CombatModifierKindDto::Fortification,
                    CombatModifierKind::Technology => CombatModifierKindDto::Technology,
                    CombatModifierKind::Counter => CombatModifierKindDto::Counter,
                    CombatModifierKind::TroopComposition => CombatModifierKindDto::TroopComposition,
                    CombatModifierKind::Veterancy => CombatModifierKindDto::Veterancy,
                },
                label: modifier.label.to_string(),
                target: match modifier.target {
                    CombatStatTarget::Attack => CombatStatTargetDto::Attack,
                    CombatStatTarget::Defense => CombatStatTargetDto::Defense,
                    CombatStatTarget::HitPoints => CombatStatTargetDto::HitPoints,
                },
                delta: modifier.delta,
            })
            .collect(),
    }
}
