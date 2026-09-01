use aonw_content::ContentHash;
use aonw_domain::{GameState, PlayerId, PlayerTurnState};

use super::{CommandRejectionCode, DomainTransition, ExecutionEvidence};
use crate::unit_action::{UnitActionKind, apply_unit_action};
use crate::{
    AssignMerchantTradeRouteCommand, AssignWorkerToHexCommand, AttackHexCommand,
    AutoExploreUnitCommand, AutomateWorkerCommand, BuildRoadCommand, CancelWorkerAssignmentCommand,
    CancelWorkerJobCommand, ConfirmWorkerImprovementCommand, DeclareWarCommand, DetachTroopCommand,
    EngineContext, FoundCityCommand, GameEngine, MoveMerchantToCityCommand, MoveUnitCommand,
    OpenResourceExchangeCommand, OpenResourceTradeCommand, RespondDiplomaticMessageCommand,
    RespondDiplomaticProposalCommand, RushProductionCommand, SelectCityExpansionHexCommand,
    SelectTechnologyCommand, SelectWorkerImprovementCommand, SendDiplomaticMessageCommand,
    SendDiplomaticProposalCommand, SendGoldGiftCommand, SetCitySpecializationCommand,
    StartArtifactExcavationCommand, StartBuildingCommand, StartCityProjectCommand,
    StartUnitProductionCommand, StartWonderCommand, StateDigest, StoreArtifactInCityCommand,
    ToggleWorkedHexCommand, TradeArtifactCommand, TurnCommand, UnitActionCommand,
};

mod budget;
mod canonical_transition;
mod error;

pub use budget::EventBudget;
use canonical_transition::{
    apply_artifact, apply_city, apply_combat, apply_diplomacy, apply_move, apply_production,
    apply_research, apply_worker,
};
pub use error::CanonicalEngineError;

/// Authoritative command family available to player-facing adapters.
#[derive(Clone, Copy, Debug)]
pub enum PlayerCommand<'command> {
    /// Declares war on one discovered participant.
    DeclareWar(DeclareWarCommand<'command>),
    /// Transfers a positive gold gift to one discovered participant.
    SendGoldGift(SendGoldGiftCommand<'command>),
    /// Opens one resource-for-gold agreement.
    OpenResourceTrade(OpenResourceTradeCommand<'command>),
    /// Opens one atomic two-resource exchange.
    OpenResourceExchange(OpenResourceExchangeCommand<'command>),
    /// Sends one friendship or truce proposal to a discovered participant.
    SendDiplomaticProposal(SendDiplomaticProposalCommand<'command>),
    /// Accepts or rejects one proposal addressed to the authenticated actor.
    RespondDiplomaticProposal(RespondDiplomaticProposalCommand<'command>),
    /// Sends one private message to a discovered participant.
    SendDiplomaticMessage(SendDiplomaticMessageCommand<'command>),
    /// Responds to one private message addressed to the authenticated actor.
    RespondDiplomaticMessage(RespondDiplomaticMessageCommand<'command>),
    /// Selects one currently available technology for the authenticated actor.
    SelectTechnology(SelectTechnologyCommand),
    /// Starts excavating the artifact at one controlled unit.
    StartArtifactExcavation(StartArtifactExcavationCommand<'command>),
    /// Stores the artifact carried by one controlled unit.
    StoreArtifactInCity(StoreArtifactInCityCommand<'command>),
    /// Transfers one stored artifact and optional offered gold to another player.
    TradeArtifact(TradeArtifactCommand<'command>),
    /// Schedules a validated city-founding job.
    FoundCity(FoundCityCommand<'command>),
    /// Toggles one manually worked controlled coordinate.
    ToggleWorkedHex(ToggleWorkedHexCommand<'command>),
    /// Selects the preferred next territory expansion.
    SelectCityExpansionHex(SelectCityExpansionHexCommand<'command>),
    /// Starts one building target.
    StartBuilding(StartBuildingCommand<'command>),
    /// Starts one unit target with an optional strategic-resource alternative.
    StartUnitProduction(StartUnitProductionCommand<'command>),
    /// Starts one continuous project.
    StartCityProject(StartCityProjectCommand<'command>),
    /// Starts one globally unique world wonder.
    StartWonder(StartWonderCommand<'command>),
    /// Selects one city specialization.
    SetCitySpecialization(SetCitySpecializationCommand<'command>),
    /// Buys one bounded production increment.
    RushProduction(RushProductionCommand<'command>),
    /// Starts one explicitly selected field improvement.
    SelectWorkerImprovement(SelectWorkerImprovementCommand<'command>),
    /// Confirms an explicit or matching pending field improvement.
    ConfirmWorkerImprovement(ConfirmWorkerImprovementCommand<'command>),
    /// Cancels current worker construction.
    CancelWorkerJob(CancelWorkerJobCommand<'command>),
    /// Assigns a worker to its current improved coordinate.
    AssignWorkerToHex(AssignWorkerToHexCommand<'command>),
    /// Cancels a worker assignment.
    CancelWorkerAssignment(CancelWorkerAssignmentCommand<'command>),
    /// Starts road construction at the current coordinate.
    BuildRoad(BuildRoadCommand<'command>),
    /// Starts or continues deterministic worker automation.
    AutomateWorker(AutomateWorkerCommand<'command>),
    /// Resolves one visible unit or city attack.
    AttackHex(AttackHexCommand<'command>),
    /// Revision-bound manual unit movement.
    MoveUnit(MoveUnitCommand<'command>),
    /// Starts or continues deterministic scout auto-exploration.
    AutoExploreUnit(AutoExploreUnitCommand<'command>),
    /// Assigns a cyclic route between owned cities.
    AssignMerchantTradeRoute(AssignMerchantTradeRouteCommand<'command>),
    /// Queues explicit merchant travel to an owned city.
    MoveMerchantToCity(MoveMerchantToCityCommand<'command>),
    /// Detaches one troop from an army into a deterministic adjacent hex.
    DetachTroop(DetachTroopCommand<'command>),
    /// Clears every cancellable order owned by one unit.
    CancelUnitAction(UnitActionCommand<'command>),
    /// Consumes one unit's remaining movement for the current turn.
    SkipUnitTurn(UnitActionCommand<'command>),
    /// Places one idle unit in persistent fortification.
    FortifyUnit(UnitActionCommand<'command>),
    /// Completes one sequential participant turn.
    EndTurn(TurnCommand<'command>),
    /// Marks one simultaneous participant ready and finalizes when scope completes.
    SubmitTurn(TurnCommand<'command>),
}

impl GameEngine {
    /// Applies a command while reusing owned canonical-state storage.
    ///
    /// # Errors
    ///
    /// Returns an error only when canonical state or an engine-produced update
    /// violates internal invariants.
    #[allow(clippy::too_many_lines)]
    pub fn apply_player_owned(
        state: GameState,
        context: EngineContext<'_>,
        command: PlayerCommand<'_>,
    ) -> Result<DomainTransition, CanonicalEngineError> {
        let (map_hash, ruleset_hash) = content_hashes(context)?;
        if state.outcome().is_terminal() {
            return Ok(DomainTransition::rejected(
                state,
                CommandRejectionCode::MatchFinished,
                map_hash,
                ruleset_hash,
            ));
        }
        if !matches!(
            command,
            PlayerCommand::EndTurn(_) | PlayerCommand::SubmitTurn(_)
        ) && let Some(code) =
            player_action_lifecycle_rejection(&state, context.actor_player_id(), context.can_act())
        {
            return Ok(DomainTransition::rejected(
                state,
                code,
                map_hash,
                ruleset_hash,
            ));
        }
        let map = context.map();
        match command {
            PlayerCommand::DeclareWar(command) => {
                let mutation = crate::diplomacy::apply_declare_war(&state, context, command);
                apply_diplomacy(state, mutation, map_hash, ruleset_hash)
            }
            PlayerCommand::SendGoldGift(command) => {
                let mutation = crate::diplomacy::apply_send_gold_gift(&state, context, command);
                apply_diplomacy(state, mutation, map_hash, ruleset_hash)
            }
            PlayerCommand::OpenResourceTrade(command) => {
                let mutation =
                    crate::diplomacy::apply_open_resource_trade(&state, context, command);
                apply_diplomacy(state, mutation, map_hash, ruleset_hash)
            }
            PlayerCommand::OpenResourceExchange(command) => {
                let mutation =
                    crate::diplomacy::apply_open_resource_exchange(&state, context, command);
                apply_diplomacy(state, mutation, map_hash, ruleset_hash)
            }
            PlayerCommand::SendDiplomaticProposal(command) => {
                let mutation = crate::diplomacy::apply_send_proposal(&state, context, command);
                apply_diplomacy(state, mutation, map_hash, ruleset_hash)
            }
            PlayerCommand::RespondDiplomaticProposal(command) => {
                let mutation = crate::diplomacy::apply_respond_proposal(&state, context, command);
                apply_diplomacy(state, mutation, map_hash, ruleset_hash)
            }
            PlayerCommand::SendDiplomaticMessage(command) => {
                let mutation = crate::diplomacy::apply_send_message(&state, context, command);
                apply_diplomacy(state, mutation, map_hash, ruleset_hash)
            }
            PlayerCommand::RespondDiplomaticMessage(command) => {
                let mutation = crate::diplomacy::apply_respond_message(&state, context, command);
                apply_diplomacy(state, mutation, map_hash, ruleset_hash)
            }
            PlayerCommand::SelectTechnology(command) => {
                let mutation = crate::research::apply_select_technology(&state, context, command);
                apply_research(state, mutation, map_hash, ruleset_hash)
            }
            PlayerCommand::StartArtifactExcavation(command) => {
                let mutation = crate::artifact::apply_start_excavation(&state, context, command);
                apply_artifact(state, mutation, map_hash, ruleset_hash)
            }
            PlayerCommand::StoreArtifactInCity(command) => {
                let mutation = crate::artifact::apply_store_in_city(&state, context, command);
                apply_artifact(state, mutation, map_hash, ruleset_hash)
            }
            PlayerCommand::TradeArtifact(command) => {
                let mutation = crate::artifact::apply_trade(&state, context, command);
                apply_artifact(state, mutation, map_hash, ruleset_hash)
            }
            PlayerCommand::FoundCity(command) => {
                let mutation = crate::city::apply_found_city(&state, context, command);
                apply_city(state, mutation, map_hash, ruleset_hash)
            }
            PlayerCommand::ToggleWorkedHex(command) => {
                let mutation = crate::city::apply_toggle_worked_hex(&state, context, command);
                apply_city(state, mutation, map_hash, ruleset_hash)
            }
            PlayerCommand::SelectCityExpansionHex(command) => {
                let mutation = crate::city::apply_select_expansion(&state, context, command);
                apply_city(state, mutation, map_hash, ruleset_hash)
            }
            PlayerCommand::StartBuilding(command) => {
                let mutation = crate::production::apply_start_building(&state, context, command);
                apply_production(state, mutation, map_hash, ruleset_hash)
            }
            PlayerCommand::StartUnitProduction(command) => {
                let mutation = crate::production::apply_start_unit(&state, context, command);
                apply_production(state, mutation, map_hash, ruleset_hash)
            }
            PlayerCommand::StartCityProject(command) => {
                let mutation = crate::production::apply_start_project(&state, context, command);
                apply_production(state, mutation, map_hash, ruleset_hash)
            }
            PlayerCommand::StartWonder(command) => {
                let mutation = crate::production::apply_start_wonder(&state, context, command);
                apply_production(state, mutation, map_hash, ruleset_hash)
            }
            PlayerCommand::SetCitySpecialization(command) => {
                let mutation =
                    crate::production::apply_set_specialization(&state, context, command);
                apply_production(state, mutation, map_hash, ruleset_hash)
            }
            PlayerCommand::RushProduction(command) => {
                let mutation = crate::production::apply_rush(&state, context, command);
                apply_production(state, mutation, map_hash, ruleset_hash)
            }
            PlayerCommand::SelectWorkerImprovement(command) => apply_worker_command(
                state,
                context,
                command,
                crate::worker::apply_select,
                map_hash,
                ruleset_hash,
            ),
            PlayerCommand::ConfirmWorkerImprovement(command) => apply_worker_command(
                state,
                context,
                command,
                crate::worker::apply_confirm,
                map_hash,
                ruleset_hash,
            ),
            PlayerCommand::CancelWorkerJob(command) => apply_worker_command(
                state,
                context,
                command,
                crate::worker::apply_cancel_job,
                map_hash,
                ruleset_hash,
            ),
            PlayerCommand::AssignWorkerToHex(command) => apply_worker_command(
                state,
                context,
                command,
                crate::worker::apply_assign,
                map_hash,
                ruleset_hash,
            ),
            PlayerCommand::CancelWorkerAssignment(command) => apply_worker_command(
                state,
                context,
                command,
                crate::worker::apply_cancel_assignment,
                map_hash,
                ruleset_hash,
            ),
            PlayerCommand::BuildRoad(command) => apply_worker_command(
                state,
                context,
                command,
                crate::worker::apply_build_road,
                map_hash,
                ruleset_hash,
            ),
            PlayerCommand::AutomateWorker(command) => apply_worker_command(
                state,
                context,
                command,
                crate::worker::apply_automation,
                map_hash,
                ruleset_hash,
            ),
            PlayerCommand::AttackHex(command) => {
                let update = crate::combat::apply(&state, context, command);
                apply_combat(state, update, map_hash, ruleset_hash)
            }
            PlayerCommand::MoveUnit(command) => {
                let movement =
                    GameEngine::apply_move_unit(&state, context.with_world(&state), command);
                apply_move(state, map, movement, map_hash, ruleset_hash)
            }
            PlayerCommand::AutoExploreUnit(command) => apply_movement_logistics(
                state,
                context,
                command,
                crate::movement::apply_auto_explore,
                map_hash,
                ruleset_hash,
            ),
            PlayerCommand::AssignMerchantTradeRoute(command) => apply_movement_logistics(
                state,
                context,
                command,
                crate::movement::apply_assign_route,
                map_hash,
                ruleset_hash,
            ),
            PlayerCommand::MoveMerchantToCity(command) => apply_movement_logistics(
                state,
                context,
                command,
                crate::movement::apply_move_to_city,
                map_hash,
                ruleset_hash,
            ),
            PlayerCommand::DetachTroop(command) => apply_movement_logistics(
                state,
                context,
                command,
                crate::movement::apply_detach_troop,
                map_hash,
                ruleset_hash,
            ),
            PlayerCommand::CancelUnitAction(command) => apply_canonical_unit_action(
                state,
                context,
                command,
                UnitActionKind::Cancel,
                map_hash,
                ruleset_hash,
            ),
            PlayerCommand::SkipUnitTurn(command) => apply_canonical_unit_action(
                state,
                context,
                command,
                UnitActionKind::Skip,
                map_hash,
                ruleset_hash,
            ),
            PlayerCommand::FortifyUnit(command) => apply_canonical_unit_action(
                state,
                context,
                command,
                UnitActionKind::Fortify,
                map_hash,
                ruleset_hash,
            ),
            PlayerCommand::EndTurn(command) => {
                crate::turn_kernel::apply_end_turn(state, context, command, map_hash, ruleset_hash)
            }
            PlayerCommand::SubmitTurn(command) => crate::turn_kernel::apply_submit_turn(
                state,
                context,
                command,
                map_hash,
                ruleset_hash,
            ),
        }
    }

    /// Computes canonical state identity.
    #[must_use]
    pub fn state_digest(state: &GameState) -> StateDigest {
        crate::state_digest::digest_state(state)
    }
}

fn player_action_lifecycle_rejection(
    state: &GameState,
    actor_player_id: &PlayerId,
    boundary_can_act: bool,
) -> Option<CommandRejectionCode> {
    if !boundary_can_act {
        return Some(CommandRejectionCode::TurnPlayerNotActive);
    }
    let lifecycle = state.match_lifecycle();
    let identity = lifecycle.identity();
    if identity.participants().is_empty() {
        // Bare engine states predate match startup and remain useful for embedders and fixtures.
        return None;
    }
    let turn = lifecycle.turn();
    if !identity.contains(actor_player_id)
        || turn.is_removed(actor_player_id)
        || turn.submitted_player_ids().contains(actor_player_id)
        || turn.turn_states_by_player_id().get(actor_player_id) != Some(&PlayerTurnState::Active)
    {
        return Some(CommandRejectionCode::TurnPlayerNotActive);
    }
    None
}

fn apply_worker_command<Command>(
    state: GameState,
    context: EngineContext<'_>,
    command: Command,
    resolve: impl FnOnce(
        &GameState,
        EngineContext<'_>,
        Command,
    ) -> Result<crate::worker::WorkerMutation, crate::worker::WorkerRuleError>,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    let mutation = resolve(&state, context.with_world(&state), command);
    apply_worker(state, mutation, map_hash, ruleset_hash)
}

fn apply_movement_logistics<Command>(
    state: GameState,
    context: EngineContext<'_>,
    command: Command,
    apply: impl FnOnce(
        &GameState,
        EngineContext<'_>,
        Command,
    ) -> Result<
        crate::movement::MovementLogisticsUpdate,
        crate::MovementLogisticsError,
    >,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    let update = match apply(&state, context.with_world(&state), command) {
        Ok(update) => update,
        Err(rejection) => {
            return Ok(DomainTransition::rejected(
                state,
                rejection.code(),
                map_hash,
                ruleset_hash,
            ));
        }
    };
    let next_state = state
        .into_after_movement_logistics(
            update.revision,
            update.units,
            update.fog_of_war,
            update.diplomacy,
            update.interaction,
        )
        .map_err(CanonicalEngineError::State)?;
    Ok(DomainTransition::accepted(
        next_state,
        update.events,
        Some(ExecutionEvidence::Logistics(update.evidence)),
        map_hash,
        ruleset_hash,
    ))
}

fn content_hashes(
    context: EngineContext<'_>,
) -> Result<(ContentHash, ContentHash), CanonicalEngineError> {
    if let Some(compiled) = context.compiled_movement_map() {
        return Ok((compiled.map_hash(), compiled.ruleset_hash()));
    }
    let map_hash = context
        .map()
        .content_hash()
        .map_err(|error| CanonicalEngineError::ContentHash(error.to_string().into()))?;
    let ruleset_hash = context
        .ruleset()
        .content_hash()
        .map_err(|error| CanonicalEngineError::ContentHash(error.to_string().into()))?;
    Ok((map_hash, ruleset_hash))
}

fn apply_canonical_unit_action(
    state: GameState,
    context: EngineContext<'_>,
    command: UnitActionCommand<'_>,
    kind: UnitActionKind,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    let update = match apply_unit_action(&state, context, command, kind) {
        Ok(update) => update,
        Err(rejection) => {
            return Ok(DomainTransition::rejected(
                state,
                rejection.code(),
                map_hash,
                ruleset_hash,
            ));
        }
    };
    let next_state = state
        .into_after_unit_action(
            update.revision,
            update.unit,
            update.interaction,
            update.cancelled_excavation,
        )
        .map_err(CanonicalEngineError::State)?;
    Ok(DomainTransition::accepted(
        next_state,
        Box::new([]),
        None,
        map_hash,
        ruleset_hash,
    ))
}

#[cfg(test)]
mod tests;
