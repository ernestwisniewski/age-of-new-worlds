use aonw_domain::{CityConquestAction, HexCoord, UnitKind, UnitPosture};
use aonw_local_runtime::{
    AttackHexRequest, AutoExploreUnitRequest, CombatPreviewRequest, LocalRuntime,
    MerchantCityRequest, PlayerViewSnapshot, RuntimeError, RuntimeQuery, RuntimeQueryResult,
    UnitActionRequest, UnitLogisticsOptionsRequest,
};

use super::{PolicyDecision, optional_query};
use crate::{
    AiProfile, MctsPlanner, MctsPlanningOutcome, PlannedCommand, RandomPlanner,
    RandomPlanningOutcome, StrategicAssessment, actions::best_move_command,
    policy_scoring::combat_is_acceptable, profile::AiTacticalStrategy,
};

pub(super) fn combat_command(
    runtime: &mut LocalRuntime,
    snapshot: &PlayerViewSnapshot,
    profile: AiProfile,
) -> Result<Option<PlannedCommand>, RuntimeError> {
    let actor = snapshot.recipient_player_id();
    let revision = snapshot.stamp().revision.get();
    let targets = snapshot
        .units()
        .iter()
        .filter(|unit| unit.owner_player_id() != actor)
        .map(|unit| HexCoord::new(unit.col(), unit.row()))
        .chain(
            snapshot
                .cities()
                .iter()
                .filter(|city| city.owner_player_id() != actor)
                .map(aonw_local_runtime::PlayerCityView::center),
        )
        .collect::<std::collections::BTreeSet<_>>();
    for unit in snapshot.units().iter().filter(|unit| {
        unit.owner_player_id() == actor
            && unit.movement_units() > 0
            && unit.posture() == UnitPosture::Active
    }) {
        for target in &targets {
            let query = RuntimeQuery::CombatPreview(CombatPreviewRequest {
                expected_revision: revision,
                attacker_unit_id: unit.id().clone(),
                defender: *target,
            });
            let Some(RuntimeQueryResult::CombatPreview { preview, .. }) =
                optional_query(runtime, &query)?
            else {
                continue;
            };
            let retaliation = preview.retaliation_damage.map_or(0, |(_, maximum)| maximum);
            if combat_is_acceptable(preview.outgoing_damage.1, retaliation, profile) {
                let request = AttackHexRequest {
                    expected_revision: revision,
                    attacker_unit_id: unit.id().clone(),
                    defender: *target,
                    city_conquest_action: CityConquestAction::Capture,
                };
                return Ok(Some(PlannedCommand::AttackHex(request)));
            }
        }
    }
    Ok(None)
}

pub(super) fn movement_command(
    runtime: &mut LocalRuntime,
    snapshot: &PlayerViewSnapshot,
    assessment: &StrategicAssessment,
    profile: AiProfile,
) -> Result<Option<PolicyDecision>, RuntimeError> {
    let tactical_pressure = assessment.empire().hostile_relation_count() > 0
        && assessment.empire().visible_enemy_military_count() > 0;
    if tactical_pressure {
        match profile.tactical_strategy() {
            AiTacticalStrategy::Direct => {}
            AiTacticalStrategy::Random => {
                return match RandomPlanner::new(profile.search_seed(snapshot.turn()))
                    .plan(runtime)?
                {
                    RandomPlanningOutcome::Planned(plan) => {
                        Ok(Some(PolicyDecision::direct(plan.command())))
                    }
                    RandomPlanningOutcome::NoLegalCommand { .. } => Ok(None),
                };
            }
            AiTacticalStrategy::Mcts => {
                if let Some(budget) = profile.difficulty().tactical_budget() {
                    return match MctsPlanner::new(profile.search_seed(snapshot.turn()), budget)
                        .plan(runtime)?
                    {
                        MctsPlanningOutcome::Planned(plan) => {
                            let evidence = crate::TacticalSearchEvidence::new(
                                plan.search_fingerprint(),
                                plan.budget(),
                                plan.stats(),
                            );
                            Ok(Some(PolicyDecision::searched(plan.command(), evidence)))
                        }
                        MctsPlanningOutcome::NoLegalCommand { .. } => Ok(None),
                    };
                }
            }
        }
    }
    Ok(best_move_command(runtime, snapshot)?.map(PolicyDecision::direct))
}

pub(super) fn logistics_command(
    runtime: &mut LocalRuntime,
    snapshot: &PlayerViewSnapshot,
) -> Result<Option<PlannedCommand>, RuntimeError> {
    let actor = snapshot.recipient_player_id();
    let revision = snapshot.stamp().revision.get();
    for unit in snapshot.units().iter().filter(|unit| {
        unit.owner_player_id() == actor
            && unit.movement_units() > 0
            && unit.posture() == UnitPosture::Active
            && matches!(unit.kind(), UnitKind::Scout | UnitKind::Merchant)
    }) {
        let result = runtime_result!(optional_query(
            runtime,
            &RuntimeQuery::UnitLogisticsOptions(UnitLogisticsOptionsRequest {
                expected_revision: revision,
                unit_id: unit.id().clone(),
            }),
        ));
        let result = some_or_continue!(result);
        let options = query_variant!(
            result,
            RuntimeQueryResult::UnitLogisticsOptions(options) => options,
            "logistics query returns logistics options"
        );
        if unit.kind() == UnitKind::Merchant {
            if let Some(destination) = options.merchant_route_destinations.first() {
                return Ok(Some(PlannedCommand::AssignMerchantTradeRoute(
                    merchant_request(revision, unit.id(), &destination.city_id),
                )));
            }
            if let Some(destination) = options.merchant_travel_destinations.first() {
                return Ok(Some(PlannedCommand::MoveMerchantToCity(merchant_request(
                    revision,
                    unit.id(),
                    &destination.city_id,
                ))));
            }
        } else if options.auto_explore.is_some() {
            return Ok(Some(PlannedCommand::AutoExploreUnit(
                AutoExploreUnitRequest {
                    expected_revision: revision,
                    unit_id: unit.id().clone(),
                },
            )));
        }
    }
    Ok(None)
}

pub(super) fn merchant_pending_command(
    runtime: &mut LocalRuntime,
    revision: u64,
    unit_id: &aonw_domain::UnitId,
    route: bool,
) -> Result<Option<PlannedCommand>, RuntimeError> {
    let result = runtime_result!(runtime.query(&RuntimeQuery::UnitLogisticsOptions(
        UnitLogisticsOptionsRequest {
            expected_revision: revision,
            unit_id: unit_id.clone(),
        }
    ),));
    let options = query_variant!(
        result,
        RuntimeQueryResult::UnitLogisticsOptions(options) => options,
        "logistics query returns logistics options"
    );
    let destination = if route {
        options.merchant_route_destinations.first()
    } else {
        options.merchant_travel_destinations.first()
    };
    Ok(Some(destination.map_or_else(
        || {
            PlannedCommand::CancelUnitAction(UnitActionRequest {
                expected_revision: revision,
                unit_id: unit_id.clone(),
            })
        },
        |destination| {
            let request = merchant_request(revision, unit_id, &destination.city_id);
            if route {
                PlannedCommand::AssignMerchantTradeRoute(request)
            } else {
                PlannedCommand::MoveMerchantToCity(request)
            }
        },
    )))
}

fn merchant_request(
    expected_revision: u64,
    unit_id: &aonw_domain::UnitId,
    city_id: &aonw_domain::CityId,
) -> MerchantCityRequest {
    MerchantCityRequest {
        expected_revision,
        unit_id: unit_id.clone(),
        destination_city_id: city_id.clone(),
    }
}
