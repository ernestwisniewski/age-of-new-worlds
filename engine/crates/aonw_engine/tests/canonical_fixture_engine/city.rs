use aonw_contracts::CoordinateDto;
use aonw_domain::{CityId, GameState, HexCoord, UnitId};
use aonw_engine::{
    DomainTransition, EngineContext, FoundCityCommand, GameEngine, PlayerCommand,
    SelectCityExpansionHexCommand, ToggleWorkedHexCommand,
};

use super::{ExecutionError, display_error};

pub(super) fn apply_found(
    state: GameState,
    context: EngineContext<'_>,
    expected_revision: u64,
    founder_unit_id: &str,
    controlled_hexes: &[CoordinateDto],
) -> Result<DomainTransition, ExecutionError> {
    let founder = UnitId::new(founder_unit_id).map_err(display_error)?;
    let controlled_hexes = controlled_hexes
        .iter()
        .map(|coordinate| HexCoord::new(coordinate.col, coordinate.row))
        .collect::<Vec<_>>();
    GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::FoundCity(FoundCityCommand::new(
            expected_revision,
            &founder,
            &controlled_hexes,
        )),
    )
    .map_err(display_error)
}

pub(super) fn apply_toggle_worked(
    state: GameState,
    context: EngineContext<'_>,
    expected_revision: u64,
    city_id: &str,
    target: CoordinateDto,
) -> Result<DomainTransition, ExecutionError> {
    let city = CityId::new(city_id).map_err(display_error)?;
    GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::ToggleWorkedHex(ToggleWorkedHexCommand::new(
            expected_revision,
            &city,
            HexCoord::new(target.col, target.row),
        )),
    )
    .map_err(display_error)
}

pub(super) fn apply_select_expansion(
    state: GameState,
    context: EngineContext<'_>,
    expected_revision: u64,
    city_id: &str,
    target: CoordinateDto,
) -> Result<DomainTransition, ExecutionError> {
    let city = CityId::new(city_id).map_err(display_error)?;
    GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::SelectCityExpansionHex(SelectCityExpansionHexCommand::new(
            expected_revision,
            &city,
            HexCoord::new(target.col, target.row),
        )),
    )
    .map_err(display_error)
}
