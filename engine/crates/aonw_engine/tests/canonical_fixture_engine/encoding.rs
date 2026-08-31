#[path = "encoding/command_name.rs"]
mod command_name_encoding;
#[path = "encoding/diplomacy.rs"]
mod diplomacy_encoding;
#[path = "encoding/economy.rs"]
mod economy_encoding;
#[path = "encoding/movement.rs"]
mod movement_encoding;
#[path = "encoding/objective.rs"]
mod objective_encoding;

pub(super) use command_name_encoding::command_name;
use movement_encoding::{encode_movement_execution, encode_step};

use aonw_contract_mapping::{
    encode_city_building, encode_city_wonder, encode_improvement, encode_message_category,
    encode_message_response, encode_message_topic, encode_proposal_kind, encode_relation_reason,
    encode_relation_status, encode_score_reason, encode_technology, encode_troop, encode_unit_kind,
};
use aonw_contracts::client::{
    WorkerAutomationActionDto, WorkerAutomationMetricsDto, WorkerAutomationOptionDto,
    WorkerJobCompletionDto,
};
use aonw_contracts::{
    CombatExecutionDto, CombatModifierDto, CombatModifierKindDto, CombatOutcomeDto,
    CombatPreviewDto, CombatRollDto, CombatStatTargetDto, CombatStatsDto, CombatTargetDto,
    CoordinateDto, ReplayEventDto, ReplayEvidenceDto, ReplayLogisticsEvidenceDto,
};
use aonw_domain::HexCoord;
use aonw_engine::{
    CombatExecution, CombatModifierKind, CombatPreview, CombatStatTarget, CombatTarget,
    DomainEvent, EffectiveCombatStats, ExecutionEvidence, LogisticsExecution,
    WorkerAutomationAction, WorkerAutomationOption,
};
#[allow(clippy::too_many_lines)]
pub(super) fn encode_event(event: &DomainEvent) -> ReplayEventDto {
    match event {
        DomainEvent::ArtifactExcavationStarted(value) => {
            ReplayEventDto::ArtifactExcavationStarted {
                artifact_id: value.artifact_id().as_str().to_owned(),
                owner_player_id: value.owner_player_id().as_str().to_owned(),
                unit_id: value.unit_id().as_str().to_owned(),
                coordinate: coordinate(value.coordinate()),
            }
        }
        DomainEvent::ArtifactCarried(value) => ReplayEventDto::ArtifactCarried {
            artifact_id: value.artifact_id().as_str().to_owned(),
            owner_player_id: value.owner_player_id().as_str().to_owned(),
            unit_id: value.unit_id().as_str().to_owned(),
            coordinate: coordinate(value.coordinate()),
        },
        DomainEvent::ArtifactStored(value) => ReplayEventDto::ArtifactStored {
            artifact_id: value.artifact_id().as_str().to_owned(),
            owner_player_id: value.owner_player_id().as_str().to_owned(),
            source_unit_id: value.source_unit_id().map(|unit| unit.as_str().to_owned()),
            city_id: value.city_id().as_str().to_owned(),
            coordinate: coordinate(value.coordinate()),
        },
        DomainEvent::CityFounded(value) => ReplayEventDto::CityFounded {
            city_id: value.city_id().as_str().to_owned(),
            owner_player_id: value.owner_player_id().as_str().to_owned(),
        },
        DomainEvent::CityBuiltBuilding(value) => ReplayEventDto::CityBuiltBuilding {
            city_id: value.city_id().as_str().to_owned(),
            building_type: encode_city_building(value.building()),
        },
        DomainEvent::CityProducedUnit(value) => ReplayEventDto::CityProducedUnit {
            city_id: value.city_id().as_str().to_owned(),
            unit_type: encode_unit_kind(value.unit()),
            produced_unit_id: value.produced_unit_id().as_str().to_owned(),
        },
        DomainEvent::CityBuiltWonder(value) => ReplayEventDto::CityBuiltWonder {
            city_id: value.city_id().as_str().to_owned(),
            owner_player_id: value.owner_player_id().as_str().to_owned(),
            wonder_type: encode_city_wonder(value.wonder()),
        },
        DomainEvent::WonderProductionRefunded(value) => ReplayEventDto::WonderProductionRefunded {
            city_id: value.city_id().as_str().to_owned(),
            owner_player_id: value.owner_player_id().as_str().to_owned(),
            wonder_type: encode_city_wonder(value.wonder()),
            refunded_production: value.refunded_production(),
        },
        DomainEvent::TechnologyResearched(value) => ReplayEventDto::TechnologyResearched {
            player_id: value.player_id().as_str().to_owned(),
            technology_id: encode_technology(value.technology()),
        },
        DomainEvent::ResearchPointsGained(value) => ReplayEventDto::ResearchPointsGained {
            player_id: value.player_id().as_str().to_owned(),
            points: value.points(),
        },
        DomainEvent::CityClaimedHex(value) => economy_encoding::city_claimed(value),
        DomainEvent::StabilityBandChanged(value) => economy_encoding::stability_changed(value),
        DomainEvent::MapObjectiveSecured(value) => objective_encoding::map_secured(value),
        DomainEvent::DominationThresholdReached(value) => objective_encoding::domination(value),
        DomainEvent::MatchEnded(value) => ReplayEventDto::MatchEnded {
            turn: value.turn(),
            outcome: aonw_contract_mapping::encode_game_outcome(value.outcome()),
        },
        DomainEvent::UnitAttacked(value) => combat_event(value, |attacker_unit_id, target, _| {
            ReplayEventDto::UnitAttacked {
                attacker_unit_id,
                target,
            }
        }),
        DomainEvent::CityAttacked(value) => combat_event(value, |attacker_unit_id, target, _| {
            ReplayEventDto::CityAttacked {
                attacker_unit_id,
                target,
            }
        }),
        DomainEvent::CombatResolved(value) => combat_event(value, |attacker_unit_id, target, _| {
            ReplayEventDto::CombatResolved {
                attacker_unit_id,
                target,
            }
        }),
        DomainEvent::DiplomaticScoreChanged(value) => ReplayEventDto::DiplomaticScoreChanged {
            player_a_id: value.player_a_id().as_str().to_owned(),
            player_b_id: value.player_b_id().as_str().to_owned(),
            delta: value.delta(),
            score_after: value.score_after(),
            reason: encode_score_reason(value.reason()),
            source_id: value.source_id().map(str::to_owned),
        },
        DomainEvent::DiplomaticProposalSent(value) => ReplayEventDto::DiplomaticProposalSent {
            proposal_id: value.proposal_id().to_owned(),
            from_player_id: value.from_player_id().as_str().to_owned(),
            to_player_id: value.to_player_id().as_str().to_owned(),
            kind: encode_proposal_kind(value.kind()),
            expires_on_turn: value.expires_on_turn(),
        },
        DomainEvent::DiplomaticProposalResponded(value) => {
            ReplayEventDto::DiplomaticProposalResponded {
                proposal_id: value.proposal_id().to_owned(),
                from_player_id: value.from_player_id().as_str().to_owned(),
                to_player_id: value.to_player_id().as_str().to_owned(),
                kind: encode_proposal_kind(value.kind()),
                accepted: value.accepted(),
            }
        }
        DomainEvent::DiplomaticProposalExpired(value) => {
            diplomacy_encoding::proposal_expired(value)
        }
        DomainEvent::DiplomaticMessageSent(value) => ReplayEventDto::DiplomaticMessageSent {
            message_id: value.message_id().to_owned(),
            from_player_id: value.from_player_id().as_str().to_owned(),
            to_player_id: value.to_player_id().as_str().to_owned(),
            topic: encode_message_topic(value.topic()),
            category: encode_message_category(value.category()),
            expires_on_turn: value.expires_on_turn(),
        },
        DomainEvent::DiplomaticMessageResponded(value) => {
            ReplayEventDto::DiplomaticMessageResponded {
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
        DomainEvent::DiplomaticPromiseBroken(value) => diplomacy_encoding::promise_broken(value),
        DomainEvent::DiplomaticRelationChanged(value) => {
            ReplayEventDto::DiplomaticRelationChanged {
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
                ReplayEventDto::UnitGainedExperience {
                    attacker_unit_id,
                    target,
                    subject_unit_id: subject_unit_id.expect("experience subject"),
                }
            })
        }
        DomainEvent::UnitKilled(value) => {
            combat_event(value, |attacker_unit_id, target, subject_unit_id| {
                ReplayEventDto::UnitKilled {
                    attacker_unit_id,
                    target,
                    subject_unit_id: subject_unit_id.expect("casualty subject"),
                }
            })
        }
        DomainEvent::UnitRetreated(value) => {
            combat_event(value, |attacker_unit_id, target, subject_unit_id| {
                ReplayEventDto::UnitRetreated {
                    attacker_unit_id,
                    target,
                    subject_unit_id: subject_unit_id.expect("retreat subject"),
                }
            })
        }
        DomainEvent::CityCaptured(value) => combat_event(value, |attacker_unit_id, target, _| {
            ReplayEventDto::CityCaptured {
                attacker_unit_id,
                target,
            }
        }),
        DomainEvent::CityDestroyed(value) => combat_event(value, |attacker_unit_id, target, _| {
            ReplayEventDto::CityDestroyed {
                attacker_unit_id,
                target,
            }
        }),
        DomainEvent::UnitMoved(event) => ReplayEventDto::UnitMoved {
            unit_id: event.unit_id().as_str().to_owned(),
            from: coordinate(event.from()),
            to: coordinate(event.to()),
        },
        DomainEvent::AutoExplorePlanned(event) => ReplayEventDto::AutoExplorePlanned {
            unit_id: event.unit_id().as_str().to_owned(),
            target: coordinate(event.target()),
        },
        DomainEvent::MerchantRouteAssigned(event) => ReplayEventDto::MerchantRouteAssigned {
            unit_id: event.unit_id().as_str().to_owned(),
            origin_city_id: event.origin_city_id().as_str().to_owned(),
            destination_city_id: event.destination_city_id().as_str().to_owned(),
        },
        DomainEvent::MerchantTravelQueued(event) => ReplayEventDto::MerchantTravelQueued {
            unit_id: event.unit_id().as_str().to_owned(),
            destination_city_id: event.destination_city_id().as_str().to_owned(),
        },
        DomainEvent::TroopDetached(event) => ReplayEventDto::TroopDetached {
            source_unit_id: event.source_unit_id().as_str().to_owned(),
            detached_unit_id: event.detached_unit_id().as_str().to_owned(),
            troop_kind: encode_troop(event.troop_kind()),
            destination: coordinate(event.destination()),
        },
        DomainEvent::TurnEnded(event) => ReplayEventDto::TurnEnded {
            player_id: event.player_id().as_str().to_owned(),
        },
        DomainEvent::AllPlayersSubmitted(event) => ReplayEventDto::AllPlayersSubmitted {
            turn: event.turn(),
            player_ids: event
                .player_ids()
                .iter()
                .map(|player| player.as_str().to_owned())
                .collect(),
        },
        DomainEvent::PlayerTimedOut(event) => ReplayEventDto::PlayerTimedOut {
            turn: event.turn(),
            player_id: event.player_id().as_str().to_owned(),
        },
        DomainEvent::PlayerKicked(event) => ReplayEventDto::PlayerKicked {
            turn: event.turn(),
            player_id: event.player_id().as_str().to_owned(),
            reason: event.reason().to_owned(),
            timeout_streak: event.timeout_streak(),
        },
        DomainEvent::WorkerCompletedJob(event) => ReplayEventDto::WorkerCompletedJob {
            unit_id: event.unit_id().as_str().to_owned(),
            target: coordinate(event.target()),
            completion: match event.completion() {
                aonw_engine::WorkerJobCompletion::FieldImprovement(improvement) => {
                    WorkerJobCompletionDto::FieldImprovement {
                        improvement: encode_improvement(improvement),
                    }
                }
                aonw_engine::WorkerJobCompletion::Road => WorkerJobCompletionDto::Road,
            },
        },
    }
}

pub(super) fn encode_evidence(evidence: &ExecutionEvidence) -> ReplayEvidenceDto {
    match evidence {
        ExecutionEvidence::Combat(value) => ReplayEvidenceDto::Combat {
            execution: combat_execution(value),
        },
        ExecutionEvidence::UnitMovement(execution) => ReplayEvidenceDto::UnitMovement {
            unit_id: execution.unit_id().as_str().to_owned(),
            from: coordinate(execution.from()),
            steps: execution.steps().iter().map(encode_step).collect(),
        },
        ExecutionEvidence::Logistics(execution) => ReplayEvidenceDto::Logistics {
            execution: encode_logistics(execution),
        },
        ExecutionEvidence::TurnKernel(execution) => ReplayEvidenceDto::TurnKernel {
            processors: execution
                .processors()
                .iter()
                .map(|processor| processor.as_str().to_owned())
                .collect(),
            founded_city_ids: execution
                .founded_city_ids()
                .iter()
                .map(|city| city.as_str().to_owned())
                .collect(),
            combat_executions: execution
                .combat_executions()
                .iter()
                .map(combat_execution)
                .collect(),
            reset_unit_ids: execution
                .reset_unit_ids()
                .iter()
                .map(|unit| unit.as_str().to_owned())
                .collect(),
            movement_executions: execution
                .movement_executions()
                .iter()
                .map(encode_movement_execution)
                .collect(),
            invalidated_order_unit_ids: execution
                .invalidated_order_unit_ids()
                .iter()
                .map(|unit| unit.as_str().to_owned())
                .collect(),
            finished_auto_explore_unit_ids: execution
                .finished_auto_explore_unit_ids()
                .iter()
                .map(|unit| unit.as_str().to_owned())
                .collect(),
        },
        ExecutionEvidence::WorkerAutomation(execution) => ReplayEvidenceDto::WorkerAutomation {
            unit_id: execution.unit_id().as_str().to_owned(),
            option: worker_option(execution.option()),
            movement: execution.movement().map(encode_movement_execution),
        },
    }
}

fn worker_option(value: WorkerAutomationOption) -> WorkerAutomationOptionDto {
    let metrics = value.metrics();
    WorkerAutomationOptionDto {
        target: coordinate(value.target()),
        action: match value.action() {
            WorkerAutomationAction::Improve(improvement) => WorkerAutomationActionDto::Improve {
                improvement: encode_improvement(improvement),
            },
            WorkerAutomationAction::Assign => WorkerAutomationActionDto::Assign,
        },
        movement_cost_units: value.movement_cost_units(),
        metrics: WorkerAutomationMetricsDto {
            tiles_examined: metrics.tiles_examined(),
            legality_evaluations: metrics.legality_evaluations(),
            routes_planned: metrics.routes_planned(),
        },
    }
}

fn combat_event(
    value: &aonw_engine::CombatEvent,
    build: impl FnOnce(String, CombatTargetDto, Option<String>) -> ReplayEventDto,
) -> ReplayEventDto {
    build(
        value.attacker_unit_id().as_str().to_owned(),
        combat_target(value.target()),
        value.subject_unit_id().map(|unit| unit.as_str().to_owned()),
    )
}

fn combat_execution(value: &CombatExecution) -> CombatExecutionDto {
    CombatExecutionDto {
        seed: value.seed,
        rolls: value
            .rolls
            .iter()
            .map(|roll| CombatRollDto { value: roll.value })
            .collect(),
        preview: combat_preview(&value.preview),
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

fn combat_preview(value: &CombatPreview) -> CombatPreviewDto {
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

fn encode_logistics(execution: &LogisticsExecution) -> ReplayLogisticsEvidenceDto {
    match execution {
        LogisticsExecution::AutoExplore {
            unit_id,
            target,
            movement,
        } => ReplayLogisticsEvidenceDto::AutoExplore {
            unit_id: unit_id.as_str().to_owned(),
            target: coordinate(*target),
            movement: movement.as_ref().map(encode_movement_execution),
        },
        LogisticsExecution::MerchantRouteAssigned {
            unit_id,
            origin_city_id,
            destination_city_id,
            steps,
            transport_network_fingerprint,
        } => ReplayLogisticsEvidenceDto::MerchantRouteAssigned {
            unit_id: unit_id.as_str().to_owned(),
            origin_city_id: origin_city_id.as_str().to_owned(),
            destination_city_id: destination_city_id.as_str().to_owned(),
            steps: steps.iter().map(encode_step).collect(),
            transport_network_fingerprint: transport_network_fingerprint.to_string(),
        },
        LogisticsExecution::MerchantTravelQueued {
            unit_id,
            destination_city_id,
            steps,
        } => ReplayLogisticsEvidenceDto::MerchantTravelQueued {
            unit_id: unit_id.as_str().to_owned(),
            destination_city_id: destination_city_id.as_str().to_owned(),
            steps: steps.iter().map(encode_step).collect(),
        },
        LogisticsExecution::TroopDetached {
            source_unit_id,
            detached_unit_id,
            troop_kind,
            destination,
        } => ReplayLogisticsEvidenceDto::TroopDetached {
            source_unit_id: source_unit_id.as_str().to_owned(),
            detached_unit_id: detached_unit_id.as_str().to_owned(),
            troop_kind: encode_troop(*troop_kind),
            destination: coordinate(*destination),
        },
    }
}

const fn coordinate(value: HexCoord) -> CoordinateDto {
    CoordinateDto {
        col: value.col(),
        row: value.row(),
    }
}
