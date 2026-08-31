use aonw_domain::{CityProductionTarget, UnitKind, UnitPosture};
use aonw_local_runtime::{
    LocalRuntime, PlayerViewSnapshot, ProductionCommandRequest, ProductionOptionsRequest,
    RuntimeError, RuntimeQuery, RuntimeQueryResult, UnitActionRequest, WorkerImprovementRequest,
    WorkerOptionsRequest, WorkerUnitRequest,
};

use crate::PlannedCommand;
use crate::{AiProfile, StrategicAssessment, policy_scoring::production_utility};

pub(super) fn production_command(
    runtime: &mut LocalRuntime,
    snapshot: &PlayerViewSnapshot,
    assessment: &StrategicAssessment,
    profile: AiProfile,
) -> Result<Option<PlannedCommand>, RuntimeError> {
    let actor = snapshot.recipient_player_id();
    let revision = snapshot.stamp().revision.get();
    for city in snapshot
        .cities()
        .iter()
        .filter(|city| city.owner_player_id() == actor)
    {
        let result = runtime_result!(runtime.query(&RuntimeQuery::ProductionOptions(
            ProductionOptionsRequest {
                expected_revision: revision,
                city_id: city.id().clone(),
            }
        )));
        let options = query_variant!(
            result,
            RuntimeQueryResult::ProductionOptions { options, .. } => options,
            "production query returns production options"
        );
        if options.current_target().is_some() {
            continue;
        }
        let finite = options
            .buildings()
            .iter()
            .copied()
            .filter(|option| option.is_available())
            .chain(
                options
                    .units()
                    .iter()
                    .map(aonw_engine::UnitProductionOption::option)
                    .filter(|option| option.is_available()),
            )
            .chain(
                options
                    .wonders()
                    .iter()
                    .copied()
                    .filter(|option| option.is_available()),
            )
            .max_by_key(|option| {
                (
                    production_utility(*option, assessment, profile),
                    core::cmp::Reverse(option.cost()),
                    core::cmp::Reverse(crate::policy_scoring::production_order(option.target())),
                )
            });
        let target = some_or_continue!(finite.or_else(|| options.projects().first().copied()));
        let resource_option_index = unit_resource_option_index(target.target(), &options);
        let request = production_request(
            revision,
            city.id().clone(),
            target.target(),
            resource_option_index,
        );
        return Ok(Some(PlannedCommand::Production(request)));
    }
    Ok(None)
}

fn production_request(
    expected_revision: u64,
    city_id: aonw_domain::CityId,
    target: CityProductionTarget,
    resource_option_index: Option<u32>,
) -> ProductionCommandRequest {
    match target {
        CityProductionTarget::Building(building) => ProductionCommandRequest::StartBuilding {
            expected_revision,
            city_id,
            building,
        },
        CityProductionTarget::Unit(unit) => ProductionCommandRequest::StartUnitProduction {
            expected_revision,
            city_id,
            unit,
            resource_option_index,
        },
        CityProductionTarget::Project(project) => ProductionCommandRequest::StartCityProject {
            expected_revision,
            city_id,
            project,
        },
        CityProductionTarget::Wonder(wonder) => ProductionCommandRequest::StartWonder {
            expected_revision,
            city_id,
            wonder,
        },
    }
}

fn unit_resource_option_index(
    target: CityProductionTarget,
    options: &aonw_engine::ProductionOptions,
) -> Option<u32> {
    options
        .units()
        .iter()
        .find(|option| option.option().target() == target)
        .and_then(|option| option.affordable_resource_option_indices().first().copied())
}

pub(super) fn worker_command(
    runtime: &mut LocalRuntime,
    snapshot: &PlayerViewSnapshot,
) -> Result<Option<PlannedCommand>, RuntimeError> {
    let actor = snapshot.recipient_player_id();
    let revision = snapshot.stamp().revision.get();
    for unit in snapshot.units().iter().filter(|unit| {
        unit.owner_player_id() == actor
            && unit.kind() == UnitKind::Worker
            && unit.posture() == UnitPosture::Active
            && unit
                .owned_details()
                .is_some_and(|details| details.activity().worker_job().is_none())
    }) {
        let result = runtime_result!(runtime.query(&RuntimeQuery::WorkerOptions(
            WorkerOptionsRequest {
                expected_revision: revision,
                unit_id: unit.id().clone(),
            }
        )));
        let options = query_variant!(
            result,
            RuntimeQueryResult::WorkerOptions { options, .. } => options,
            "worker query returns worker options"
        );
        let command = some_or_continue!(worker_request(
            revision,
            unit.id(),
            options.automation().is_some(),
            options.improvements().first().map(|value| value.kind()),
            options.can_assign(),
            options.can_build_road(),
        ));
        return Ok(Some(command));
    }
    Ok(None)
}

pub(super) fn worker_selection_command(
    runtime: &mut LocalRuntime,
    revision: u64,
    unit_id: &aonw_domain::UnitId,
) -> Result<Option<PlannedCommand>, RuntimeError> {
    let result = runtime_result!(runtime.query(&RuntimeQuery::WorkerOptions(
        WorkerOptionsRequest {
            expected_revision: revision,
            unit_id: unit_id.clone(),
        }
    )));
    let options = query_variant!(
        result,
        RuntimeQueryResult::WorkerOptions { options, .. } => options,
        "worker query returns worker options"
    );
    Ok(Some(worker_selection_request(
        revision,
        unit_id,
        options.improvements().first().map(|value| value.kind()),
    )))
}

fn worker_request(
    expected_revision: u64,
    unit_id: &aonw_domain::UnitId,
    can_automate: bool,
    improvement: Option<aonw_domain::FieldImprovementKind>,
    can_assign: bool,
    can_build_road: bool,
) -> Option<PlannedCommand> {
    let request = || WorkerUnitRequest {
        expected_revision,
        unit_id: unit_id.clone(),
    };
    if can_automate {
        Some(PlannedCommand::AutomateWorker(request()))
    } else if let Some(improvement) = improvement {
        Some(PlannedCommand::SelectWorkerImprovement(
            WorkerImprovementRequest {
                expected_revision,
                unit_id: unit_id.clone(),
                improvement: Some(improvement),
            },
        ))
    } else if can_assign {
        Some(PlannedCommand::AssignWorkerToHex(request()))
    } else if can_build_road {
        Some(PlannedCommand::BuildRoad(request()))
    } else {
        None
    }
}

fn worker_selection_request(
    expected_revision: u64,
    unit_id: &aonw_domain::UnitId,
    improvement: Option<aonw_domain::FieldImprovementKind>,
) -> PlannedCommand {
    improvement.map_or_else(
        || {
            PlannedCommand::CancelUnitAction(UnitActionRequest {
                expected_revision,
                unit_id: unit_id.clone(),
            })
        },
        |improvement| {
            PlannedCommand::SelectWorkerImprovement(WorkerImprovementRequest {
                expected_revision,
                unit_id: unit_id.clone(),
                improvement: Some(improvement),
            })
        },
    )
}

#[cfg(test)]
mod tests {
    use aonw_domain::{
        CityBuildingType, CityId, CityProductionTarget, CityProjectType, FieldImprovementKind,
        UnitId, UnitKind, WonderType,
    };
    use aonw_local_runtime::ProductionCommandRequest;
    use aonw_local_runtime::{ProductionOptionsRequest, RuntimeQuery, RuntimeQueryResult};

    use super::{
        production_request, unit_resource_option_index, worker_request, worker_selection_request,
    };
    use crate::PlannedCommand;

    #[test]
    fn every_production_target_maps_to_its_public_request() {
        let city = CityId::new("city-1").expect("city");
        let cases = [
            CityProductionTarget::Building(CityBuildingType::Granary),
            CityProductionTarget::Unit(UnitKind::Worker),
            CityProductionTarget::Project(CityProjectType::Research),
            CityProductionTarget::Wonder(WonderType::GreatLibrary),
        ];
        let requests = cases.map(|target| production_request(7, city.clone(), target, Some(2)));
        assert!(matches!(
            requests[0],
            ProductionCommandRequest::StartBuilding { .. }
        ));
        assert!(matches!(
            requests[1],
            ProductionCommandRequest::StartUnitProduction {
                resource_option_index: Some(2),
                ..
            }
        ));
        assert!(matches!(
            requests[2],
            ProductionCommandRequest::StartCityProject { .. }
        ));
        assert!(matches!(
            requests[3],
            ProductionCommandRequest::StartWonder { .. }
        ));
    }

    #[test]
    fn worker_priority_and_pending_fallback_are_exhaustive() {
        let unit = UnitId::new("worker-1").expect("worker");
        assert!(matches!(
            worker_request(7, &unit, true, None, false, false),
            Some(PlannedCommand::AutomateWorker(_))
        ));
        assert!(matches!(
            worker_request(
                7,
                &unit,
                false,
                Some(FieldImprovementKind::Farm),
                false,
                false
            ),
            Some(PlannedCommand::SelectWorkerImprovement(_))
        ));
        assert!(matches!(
            worker_request(7, &unit, false, None, true, false),
            Some(PlannedCommand::AssignWorkerToHex(_))
        ));
        assert!(matches!(
            worker_request(7, &unit, false, None, false, true),
            Some(PlannedCommand::BuildRoad(_))
        ));
        assert_eq!(worker_request(7, &unit, false, None, false, false), None);
        assert!(matches!(
            worker_selection_request(7, &unit, Some(FieldImprovementKind::Mine)),
            PlannedCommand::SelectWorkerImprovement(_)
        ));
        assert!(matches!(
            worker_selection_request(7, &unit, None),
            PlannedCommand::CancelUnitAction(_)
        ));
    }

    #[test]
    fn unit_resource_lookup_visits_the_matching_unit_option() {
        let mut runtime = crate::mcts_search::tests::opened_runtime();
        let result = runtime
            .query(&RuntimeQuery::ProductionOptions(ProductionOptionsRequest {
                expected_revision: 0,
                city_id: CityId::new("city-1").expect("city"),
            }))
            .expect("production options");
        let options = query_variant!(
            result,
            RuntimeQueryResult::ProductionOptions { options, .. } => options,
            "production options response"
        );
        let index =
            unit_resource_option_index(CityProductionTarget::Unit(UnitKind::Worker), &options);
        assert_eq!(
            index,
            options
                .units()
                .iter()
                .find(|option| {
                    option.option().target() == CityProductionTarget::Unit(UnitKind::Worker)
                })
                .and_then(|option| option.affordable_resource_option_indices().first().copied())
        );
    }
}
