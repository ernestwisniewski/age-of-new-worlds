use aonw_local_runtime::{
    ArtifactCommandRequest, AttackHexRequest, AutoExploreUnitRequest, CommandResult,
    DetachTroopRequest, DiplomacyRequest, FoundCityRequest, LocalRuntime, MerchantCityRequest,
    MoveUnitRequest, ProductionCommandRequest, RuntimeError, SelectCityExpansionHexRequest,
    SelectTechnologyRequest, ToggleWorkedHexRequest, TurnCommandRequest, UnitActionRequest,
    WorkerImprovementRequest, WorkerUnitRequest,
};

#[cfg(test)]
mod tests;

/// Stable coarse command family used by policy and strength evidence.
#[derive(Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub enum PlannedCommandFamily {
    /// Research selection.
    Research,
    /// City founding, worked tiles, and expansion.
    City,
    /// Production queue, rush, and specialization.
    Production,
    /// Worker construction, assignment, roads, and automation.
    Worker,
    /// Artifact excavation, storage, and trade.
    Artifact,
    /// Attacks and city-conquest decisions.
    Combat,
    /// Exploration, merchant routing, and troop detachment.
    Logistics,
    /// Bilateral diplomacy and agreements.
    Diplomacy,
    /// Manual movement and unit posture.
    Movement,
    /// End/submit lifecycle progression.
    Turn,
}

/// One standard public runtime command selected by a planner.
#[derive(Clone, Debug, Eq, Hash, PartialEq)]
pub enum PlannedCommand {
    /// Current bilateral diplomacy operation.
    Diplomacy(DiplomacyRequest),
    /// Selects one available technology.
    SelectTechnology(SelectTechnologyRequest),
    /// Current artifact operation.
    Artifact(ArtifactCommandRequest),
    /// Schedules one city-founding job.
    FoundCity(FoundCityRequest),
    /// Toggles one controlled city tile.
    ToggleWorkedHex(ToggleWorkedHexRequest),
    /// Selects one preferred city expansion tile.
    SelectCityExpansionHex(SelectCityExpansionHexRequest),
    /// Current production or specialization operation.
    Production(ProductionCommandRequest),
    /// Starts one explicit worker improvement.
    SelectWorkerImprovement(WorkerImprovementRequest),
    /// Confirms a pending worker improvement.
    ConfirmWorkerImprovement(WorkerImprovementRequest),
    /// Cancels current worker construction.
    CancelWorkerJob(WorkerUnitRequest),
    /// Assigns a worker to its current improved tile.
    AssignWorkerToHex(WorkerUnitRequest),
    /// Cancels a worker assignment.
    CancelWorkerAssignment(WorkerUnitRequest),
    /// Starts road construction.
    BuildRoad(WorkerUnitRequest),
    /// Starts or continues worker automation.
    AutomateWorker(WorkerUnitRequest),
    /// Resolves one visible attack.
    AttackHex(AttackHexRequest),
    /// Revision-bound manual movement selected from `Reachable` query output.
    MoveUnit(MoveUnitRequest),
    /// Starts or continues scout auto-exploration.
    AutoExploreUnit(AutoExploreUnitRequest),
    /// Assigns a cyclic merchant route.
    AssignMerchantTradeRoute(MerchantCityRequest),
    /// Queues merchant travel to an owned city.
    MoveMerchantToCity(MerchantCityRequest),
    /// Detaches one legal troop.
    DetachTroop(DetachTroopRequest),
    /// Clears cancellable orders for one unit.
    CancelUnitAction(UnitActionRequest),
    /// Consumes one unit's remaining movement.
    SkipUnitTurn(UnitActionRequest),
    /// Fortifies one idle unit.
    FortifyUnit(UnitActionRequest),
    /// Completes the actor's turn through the mode-aware engine path.
    EndTurn(TurnCommandRequest),
    /// Submits the actor's simultaneous turn explicitly.
    SubmitTurn(TurnCommandRequest),
}

impl PlannedCommand {
    /// Executes the plan through the normal authoritative runtime boundary.
    ///
    /// # Errors
    ///
    /// Returns the same session or engine error as a client-issued command.
    pub fn execute(&self, runtime: &mut LocalRuntime) -> Result<CommandResult, RuntimeError> {
        match self {
            Self::Diplomacy(request) => runtime.diplomacy(request),
            Self::SelectTechnology(request) => runtime.select_technology(*request),
            Self::Artifact(request) => runtime.artifact(request),
            Self::FoundCity(request) => runtime.found_city(request),
            Self::ToggleWorkedHex(request) => runtime.toggle_worked_hex(request),
            Self::SelectCityExpansionHex(request) => runtime.select_city_expansion_hex(request),
            Self::Production(request) => runtime.production(request),
            Self::SelectWorkerImprovement(request) => runtime.select_worker_improvement(request),
            Self::ConfirmWorkerImprovement(request) => runtime.confirm_worker_improvement(request),
            Self::CancelWorkerJob(request) => runtime.cancel_worker_job(request),
            Self::AssignWorkerToHex(request) => runtime.assign_worker_to_hex(request),
            Self::CancelWorkerAssignment(request) => runtime.cancel_worker_assignment(request),
            Self::BuildRoad(request) => runtime.build_road(request),
            Self::AutomateWorker(request) => runtime.automate_worker(request),
            Self::AttackHex(request) => runtime.attack_hex(request),
            Self::MoveUnit(request) => runtime.dispatch(request),
            Self::AutoExploreUnit(request) => runtime.auto_explore_unit(request),
            Self::AssignMerchantTradeRoute(request) => runtime.assign_merchant_trade_route(request),
            Self::MoveMerchantToCity(request) => runtime.move_merchant_to_city(request),
            Self::DetachTroop(request) => runtime.detach_troop(request),
            Self::CancelUnitAction(request) => runtime.cancel_unit_action(request),
            Self::SkipUnitTurn(request) => runtime.skip_unit_turn(request),
            Self::FortifyUnit(request) => runtime.fortify_unit(request),
            Self::EndTurn(request) => runtime.end_turn(*request),
            Self::SubmitTurn(request) => runtime.submit_turn(*request),
        }
    }

    /// Returns the revision observed while this command was planned.
    #[must_use]
    pub const fn expected_revision(&self) -> u64 {
        match self {
            Self::Diplomacy(request) => diplomacy_revision(request),
            Self::SelectTechnology(request) => request.expected_revision,
            Self::Artifact(request) => artifact_revision(request),
            Self::FoundCity(request) => request.expected_revision,
            Self::ToggleWorkedHex(request) => request.expected_revision,
            Self::SelectCityExpansionHex(request) => request.expected_revision,
            Self::Production(request) => production_revision(request),
            Self::SelectWorkerImprovement(request) | Self::ConfirmWorkerImprovement(request) => {
                request.expected_revision
            }
            Self::CancelWorkerJob(request)
            | Self::AssignWorkerToHex(request)
            | Self::CancelWorkerAssignment(request)
            | Self::BuildRoad(request)
            | Self::AutomateWorker(request) => request.expected_revision,
            Self::AttackHex(request) => request.expected_revision,
            Self::MoveUnit(request) => request.expected_revision,
            Self::AutoExploreUnit(request) => request.expected_revision,
            Self::AssignMerchantTradeRoute(request) | Self::MoveMerchantToCity(request) => {
                request.expected_revision
            }
            Self::DetachTroop(request) => request.expected_revision,
            Self::CancelUnitAction(request)
            | Self::SkipUnitTurn(request)
            | Self::FortifyUnit(request) => request.expected_revision,
            Self::EndTurn(request) | Self::SubmitTurn(request) => request.expected_revision,
        }
    }

    /// Returns the coarse capability family exercised by this command.
    #[must_use]
    pub const fn family(&self) -> PlannedCommandFamily {
        match self {
            Self::Diplomacy(_) => PlannedCommandFamily::Diplomacy,
            Self::SelectTechnology(_) => PlannedCommandFamily::Research,
            Self::Artifact(_) => PlannedCommandFamily::Artifact,
            Self::FoundCity(_) | Self::ToggleWorkedHex(_) | Self::SelectCityExpansionHex(_) => {
                PlannedCommandFamily::City
            }
            Self::Production(_) => PlannedCommandFamily::Production,
            Self::SelectWorkerImprovement(_)
            | Self::ConfirmWorkerImprovement(_)
            | Self::CancelWorkerJob(_)
            | Self::AssignWorkerToHex(_)
            | Self::CancelWorkerAssignment(_)
            | Self::BuildRoad(_)
            | Self::AutomateWorker(_) => PlannedCommandFamily::Worker,
            Self::AttackHex(_) => PlannedCommandFamily::Combat,
            Self::AutoExploreUnit(_)
            | Self::AssignMerchantTradeRoute(_)
            | Self::MoveMerchantToCity(_)
            | Self::DetachTroop(_) => PlannedCommandFamily::Logistics,
            Self::MoveUnit(_)
            | Self::CancelUnitAction(_)
            | Self::SkipUnitTurn(_)
            | Self::FortifyUnit(_) => PlannedCommandFamily::Movement,
            Self::EndTurn(_) | Self::SubmitTurn(_) => PlannedCommandFamily::Turn,
        }
    }
}

const fn artifact_revision(request: &ArtifactCommandRequest) -> u64 {
    match request {
        ArtifactCommandRequest::StartExcavation {
            expected_revision, ..
        }
        | ArtifactCommandRequest::StoreInCity {
            expected_revision, ..
        }
        | ArtifactCommandRequest::Trade {
            expected_revision, ..
        } => *expected_revision,
    }
}

const fn diplomacy_revision(request: &DiplomacyRequest) -> u64 {
    match request {
        DiplomacyRequest::DeclareWar {
            expected_revision, ..
        }
        | DiplomacyRequest::SendGoldGift {
            expected_revision, ..
        }
        | DiplomacyRequest::OpenResourceTrade {
            expected_revision, ..
        }
        | DiplomacyRequest::OpenResourceExchange {
            expected_revision, ..
        }
        | DiplomacyRequest::Send {
            expected_revision, ..
        }
        | DiplomacyRequest::Respond {
            expected_revision, ..
        }
        | DiplomacyRequest::SendMessage {
            expected_revision, ..
        }
        | DiplomacyRequest::RespondMessage {
            expected_revision, ..
        } => *expected_revision,
    }
}

const fn production_revision(request: &ProductionCommandRequest) -> u64 {
    match request {
        ProductionCommandRequest::StartBuilding {
            expected_revision, ..
        }
        | ProductionCommandRequest::StartUnitProduction {
            expected_revision, ..
        }
        | ProductionCommandRequest::StartCityProject {
            expected_revision, ..
        }
        | ProductionCommandRequest::StartWonder {
            expected_revision, ..
        }
        | ProductionCommandRequest::SetCitySpecialization {
            expected_revision, ..
        }
        | ProductionCommandRequest::RushProduction {
            expected_revision, ..
        } => *expected_revision,
    }
}
