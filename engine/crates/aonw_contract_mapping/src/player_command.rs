use aonw_contracts::client::ClientCommandDto;
use aonw_domain::PlayerId;
use aonw_engine::{PlayerCommand, TurnCommand};

mod diplomacy;
mod economy;
mod movement;
mod value;

/// Invalid opaque identity found while mapping one strict client command.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerCommandMappingError {
    code: &'static str,
    message: String,
}

impl PlayerCommandMappingError {
    fn new(code: &'static str, error: impl core::fmt::Display) -> Self {
        Self {
            code,
            message: error.to_string(),
        }
    }

    /// Returns the stable client-facing validation code.
    #[must_use]
    pub const fn code(&self) -> &'static str {
        self.code
    }
}

impl core::fmt::Display for PlayerCommandMappingError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        formatter.write_str(&self.message)
    }
}

impl std::error::Error for PlayerCommandMappingError {}

/// Maps one closed client command to an engine command for immediate use.
///
/// The callback keeps borrowed command identities inside this mapping boundary,
/// so callers cannot accidentally retain references to temporary decoded values.
/// Turn commands are always bound to the authenticated actor.
///
/// # Errors
///
/// Returns an error when an opaque player, city, unit, or artifact identity is invalid.
pub fn decode_client_player_command<R>(
    command: ClientCommandDto,
    authenticated_actor: &PlayerId,
    apply: impl for<'command> FnOnce(PlayerCommand<'command>) -> R,
) -> Result<R, PlayerCommandMappingError> {
    match command {
        command @ (ClientCommandDto::DeclareWar { .. }
        | ClientCommandDto::SendGoldGift { .. }
        | ClientCommandDto::OpenResourceTrade { .. }
        | ClientCommandDto::OpenResourceExchange { .. }
        | ClientCommandDto::SendDiplomaticProposal { .. }
        | ClientCommandDto::RespondDiplomaticProposal { .. }
        | ClientCommandDto::SendDiplomaticMessage { .. }
        | ClientCommandDto::RespondDiplomaticMessage { .. }) => diplomacy::decode(command, apply),
        command @ (ClientCommandDto::SelectTechnology { .. }
        | ClientCommandDto::StartArtifactExcavation { .. }
        | ClientCommandDto::StoreArtifactInCity { .. }
        | ClientCommandDto::TradeArtifact { .. }
        | ClientCommandDto::FoundCity { .. }
        | ClientCommandDto::ToggleWorkedHex { .. }
        | ClientCommandDto::SelectCityExpansionHex { .. }
        | ClientCommandDto::StartBuilding { .. }
        | ClientCommandDto::StartUnitProduction { .. }
        | ClientCommandDto::StartCityProject { .. }
        | ClientCommandDto::StartWonder { .. }
        | ClientCommandDto::SetCitySpecialization { .. }
        | ClientCommandDto::RushProduction { .. }
        | ClientCommandDto::SelectWorkerImprovement { .. }
        | ClientCommandDto::ConfirmWorkerImprovement { .. }
        | ClientCommandDto::CancelWorkerJob { .. }
        | ClientCommandDto::AssignWorkerToHex { .. }
        | ClientCommandDto::CancelWorkerAssignment { .. }
        | ClientCommandDto::BuildRoad { .. }
        | ClientCommandDto::AutomateWorker { .. }) => economy::decode(command, apply),
        ClientCommandDto::EndTurn { expected_revision } => Ok(apply(PlayerCommand::EndTurn(
            TurnCommand::new(expected_revision, authenticated_actor),
        ))),
        ClientCommandDto::SubmitTurn { expected_revision } => Ok(apply(PlayerCommand::SubmitTurn(
            TurnCommand::new(expected_revision, authenticated_actor),
        ))),
        command @ (ClientCommandDto::AttackHex { .. }
        | ClientCommandDto::MoveUnit { .. }
        | ClientCommandDto::AutoExploreUnit { .. }
        | ClientCommandDto::AssignMerchantTradeRoute { .. }
        | ClientCommandDto::MoveMerchantToCity { .. }
        | ClientCommandDto::DetachTroop { .. }
        | ClientCommandDto::CancelUnitAction { .. }
        | ClientCommandDto::SkipUnitTurn { .. }
        | ClientCommandDto::FortifyUnit { .. }) => movement::decode(command, apply),
    }
}
