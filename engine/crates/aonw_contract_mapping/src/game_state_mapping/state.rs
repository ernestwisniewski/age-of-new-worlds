use aonw_contracts::{
    FieldImprovementDto, GameStateDto, MAX_GAME_STATE_UNIT_COUNT, TransportSegmentDto,
    UnitOccupancyPolicyDto,
};
use aonw_domain::{
    City, FogOfWar, GameState, GameStateBuildError, HexGridBounds, InfrastructureState,
    MatchIdentity, StateRevision, TransportNetwork, UnitOccupancyPolicy,
};

use super::artifact::{decode_artifact, encode_artifact};
use super::city::{decode_city, encode_city};
use super::combat::{decode_combat, encode_combat};
use super::diplomacy::{decode_diplomacy, encode_diplomacy};
use super::economy::{decode_economy, encode_economy};
use super::error::GameStateMappingError;
use super::infrastructure::{
    decode_field_improvement, decode_transport, encode_field_improvement, encode_transport,
};
use super::interaction::{decode_interaction, encode_interaction};
use super::match_lifecycle::{decode_match_lifecycle, encode_match_lifecycle};
use super::objective::{
    decode_objectives, encode_cultural, encode_domination, encode_map_objectives,
};
use super::outcome::{decode_outcome, encode_game_outcome};
use super::research::{decode_knowledge, encode_research, encode_wonder_registry};
use super::unit::{decode_unit, encode_unit};
use super::world::{decode_fog, encode_fog};

/// Validates and maps a complete game-state DTO.
///
/// # Errors
///
/// Returns a path-aware error for violated invariants.
pub fn decode_game_state(dto: GameStateDto) -> Result<GameState, GameStateMappingError> {
    validate_unit_count(&dto)?;
    let match_lifecycle = decode_match_lifecycle(dto.match_identity, dto.turn_lifecycle)?;
    let bounds = HexGridBounds::new(dto.cols, dto.rows)
        .ok_or_else(|| GameStateMappingError::new("$", "map bounds must be non-empty"))?;
    let economy = decode_economy(match_lifecycle.identity(), bounds, dto.economy)?;
    let knowledge = decode_knowledge(
        match_lifecycle.identity(),
        dto.research,
        dto.wonder_registry,
    )?;
    let units = dto
        .units
        .into_iter()
        .enumerate()
        .map(|(index, unit)| decode_unit(index, unit))
        .collect::<Result<Vec<_>, _>>()?;
    let combat = decode_combat(
        match_lifecycle.identity(),
        bounds,
        &units,
        dto.intended_attacks,
    )?;
    let cities = dto
        .cities
        .into_iter()
        .enumerate()
        .map(|(index, city)| decode_city(index, match_lifecycle.identity(), bounds, city))
        .collect::<Result<Vec<_>, _>>()?;
    let artifacts = dto
        .artifacts
        .into_iter()
        .enumerate()
        .map(|(index, artifact)| decode_artifact(index, artifact))
        .collect::<Result<Vec<_>, _>>()?;
    let interaction = decode_interaction(dto.interaction)?;
    let fog = FogOfWar::try_new(
        dto.fog_of_war
            .into_iter()
            .enumerate()
            .map(|(index, fog)| decode_fog(index, fog))
            .collect::<Result<Vec<_>, _>>()?,
    )
    .map_err(|player| {
        GameStateMappingError::new("$.fogOfWar", format!("duplicate player: {player}"))
    })?;
    let diplomacy = decode_diplomacy(
        match_lifecycle.identity(),
        dto.diplomacy,
        dto.resource_trade_agreements,
    )?;
    let objectives = decode_objectives(
        match_lifecycle.identity(),
        dto.domination_hold_turns_by_player_id,
        dto.cultural_victory_hold_turns_by_player_id,
        dto.map_objective_hold_states,
    )?;
    let outcome = decode_outcome(match_lifecycle.identity(), dto.outcome)?;
    let infrastructure = decode_infrastructure_state(
        match_lifecycle.identity(),
        bounds,
        &cities,
        dto.field_improvements,
        dto.transport_network,
    )?;
    GameState::builder(
        StateRevision::new(dto.revision),
        dto.turn,
        bounds,
        match dto.occupancy_policy {
            UnitOccupancyPolicyDto::Exclusive => UnitOccupancyPolicy::Exclusive,
            UnitOccupancyPolicyDto::FriendlyStacking => UnitOccupancyPolicy::FriendlyStacking,
        },
        units,
    )
    .with_match_lifecycle(match_lifecycle)
    .with_economy(economy)
    .with_knowledge(knowledge)
    .with_combat(combat)
    .with_objectives(objectives)
    .with_outcome(outcome)
    .with_cities(cities)
    .with_artifacts(artifacts)
    .with_interaction(interaction)
    .with_fog_of_war(fog)
    .with_diplomacy(diplomacy)
    .with_infrastructure(infrastructure)
    .try_build()
    .map_err(|error| map_aggregate_error(&error))
}

fn map_aggregate_error(error: &GameStateBuildError) -> GameStateMappingError {
    let path = match error {
        GameStateBuildError::UnitPlayerNotFound { .. }
        | GameStateBuildError::UnitArtifactActivityConflict { .. } => "$.units",
        GameStateBuildError::CityPlayerNotFound { .. }
        | GameStateBuildError::InvalidCity { .. }
        | GameStateBuildError::CityTerritoryOverlap { .. }
        | GameStateBuildError::CityWonderNotRegistered { .. }
        | GameStateBuildError::DuplicateWonderHost { .. } => "$.cities",
        GameStateBuildError::FogPlayerNotFound(_) | GameStateBuildError::FogPlayerMissing(_) => {
            "$.fogOfWar"
        }
        GameStateBuildError::InteractionPlayerNotFound(_) => "$.interaction",
        GameStateBuildError::InvalidDiplomacy(_) => "$.diplomacy",
        _ => "$",
    };
    GameStateMappingError::new(path, error.to_string())
}

/// Validates and normalizes one typed canonical state document.
///
/// Map and set fields use their stable key order, entity registries use stable
/// identity order, and semantically ordered sequences retain their order.
///
/// # Errors
///
/// Returns a path-aware error for any violated canonical-state invariant.
pub fn canonicalize_game_state(dto: GameStateDto) -> Result<GameStateDto, GameStateMappingError> {
    decode_game_state(dto).map(|state| encode_game_state(&state))
}

fn decode_infrastructure_state(
    identity: &MatchIdentity,
    bounds: HexGridBounds,
    cities: &[City],
    field_improvements: Vec<FieldImprovementDto>,
    transport_network: Vec<TransportSegmentDto>,
) -> Result<InfrastructureState, GameStateMappingError> {
    let field_improvements = field_improvements
        .into_iter()
        .enumerate()
        .map(|(index, improvement)| decode_field_improvement(index, bounds, cities, improvement))
        .collect::<Result<Vec<_>, _>>()?;
    let transport = TransportNetwork::try_new(
        transport_network
            .into_iter()
            .enumerate()
            .map(|(index, segment)| decode_transport(index, identity, bounds, cities, segment))
            .collect::<Result<Vec<_>, _>>()?,
    )
    .map_err(|coordinate| {
        GameStateMappingError::new(
            "$.transportNetwork",
            format!(
                "duplicate coordinate: ({}, {})",
                coordinate.col(),
                coordinate.row()
            ),
        )
    })?;
    InfrastructureState::try_new(field_improvements, transport)
        .map_err(|error| GameStateMappingError::new("$.fieldImprovements", error.to_string()))
}

fn validate_unit_count(dto: &GameStateDto) -> Result<(), GameStateMappingError> {
    if dto.units.len() > MAX_GAME_STATE_UNIT_COUNT {
        return Err(GameStateMappingError::new(
            "$.units",
            format!(
                "contains {} units; maximum is {MAX_GAME_STATE_UNIT_COUNT}",
                dto.units.len()
            ),
        ));
    }
    Ok(())
}

/// Encodes the movement-complete canonical state.
#[must_use]
pub fn encode_game_state(state: &GameState) -> GameStateDto {
    let (match_identity, turn_lifecycle) = encode_match_lifecycle(state.match_lifecycle());
    let (diplomacy, resource_trade_agreements) = encode_diplomacy(state.diplomacy());
    GameStateDto {
        revision: state.revision().get(),
        turn: state.turn(),
        match_identity,
        turn_lifecycle,
        economy: encode_economy(state.economy()),
        research: encode_research(state.research()),
        wonder_registry: encode_wonder_registry(state.wonder_registry()),
        intended_attacks: encode_combat(state.combat()),
        cols: state.bounds().cols(),
        rows: state.bounds().rows(),
        occupancy_policy: match state.occupancy_policy() {
            UnitOccupancyPolicy::Exclusive => UnitOccupancyPolicyDto::Exclusive,
            UnitOccupancyPolicy::FriendlyStacking => UnitOccupancyPolicyDto::FriendlyStacking,
        },
        units: state.units().iter().map(encode_unit).collect(),
        cities: state.cities().iter().map(encode_city).collect(),
        artifacts: state.artifacts().iter().map(encode_artifact).collect(),
        field_improvements: state
            .field_improvements()
            .iter()
            .map(encode_field_improvement)
            .collect(),
        interaction: encode_interaction(state.interaction()),
        fog_of_war: state
            .fog_of_war()
            .players()
            .iter()
            .map(encode_fog)
            .collect(),
        diplomacy,
        resource_trade_agreements,
        domination_hold_turns_by_player_id: encode_domination(state.objectives()),
        cultural_victory_hold_turns_by_player_id: encode_cultural(state.objectives()),
        map_objective_hold_states: encode_map_objectives(state.objectives()),
        outcome: encode_game_outcome(state.outcome()),
        transport_network: state
            .transport_network()
            .segments()
            .iter()
            .map(encode_transport)
            .collect(),
    }
}

#[cfg(test)]
mod tests {
    use aonw_contracts::{UnitActivityDto, UnitDto, UnitKindDto, UnitPostureDto};
    use aonw_domain::{
        CityBuildError, CityId, DiplomacyStateBuildError, HexCoord, PlayerId, UnitId,
    };

    use super::*;

    #[test]
    fn aggregate_player_reference_errors_retain_their_contract_family() {
        let player = PlayerId::new("unknown").expect("player");
        let cases = [
            (
                GameStateBuildError::UnitPlayerNotFound {
                    unit_id: UnitId::new("unit").expect("unit"),
                    player_id: player.clone(),
                },
                "$.units",
            ),
            (
                GameStateBuildError::CityPlayerNotFound {
                    city_id: CityId::new("city").expect("city"),
                    player_id: player.clone(),
                },
                "$.cities",
            ),
            (
                GameStateBuildError::InvalidCity {
                    city_id: CityId::new("city").expect("city"),
                    error: CityBuildError::NonPositivePopulation(0),
                },
                "$.cities",
            ),
            (
                GameStateBuildError::CityTerritoryOverlap {
                    position: HexCoord::new(0, 0),
                    first_city_id: CityId::new("city-1").expect("city"),
                    second_city_id: CityId::new("city-2").expect("city"),
                },
                "$.cities",
            ),
            (
                GameStateBuildError::FogPlayerNotFound(player.clone()),
                "$.fogOfWar",
            ),
            (
                GameStateBuildError::InteractionPlayerNotFound(player),
                "$.interaction",
            ),
            (
                GameStateBuildError::InvalidDiplomacy(DiplomacyStateBuildError::EmptyId),
                "$.diplomacy",
            ),
        ];
        for (error, expected_path) in cases {
            assert_eq!(map_aggregate_error(&error).path(), expected_path);
        }

        let state = GameState::builder(
            StateRevision::new(0),
            0,
            HexGridBounds::new(1, 1).expect("bounds"),
            UnitOccupancyPolicy::Exclusive,
            std::iter::empty(),
        )
        .try_build()
        .expect("empty state");
        assert_eq!(
            encode_game_state(&state).occupancy_policy,
            UnitOccupancyPolicyDto::Exclusive
        );

        let mut oversized = encode_game_state(&state);
        oversized.units = vec![
            UnitDto {
                id: "unit".to_owned(),
                owner_player_id: "player".to_owned(),
                kind: UnitKindDto::Commander,
                name: "unit".to_owned(),
                col: 0,
                row: 0,
                movement_units: 0,
                army: Vec::new(),
                queued_path: None,
                merchant_trade_route: None,
                activity: UnitActivityDto::default(),
                worker_build_charges: 0,
                hit_points: None,
                experience_points: 0,
                posture: UnitPostureDto::Active,
                carried_artifact_id: None,
            };
            MAX_GAME_STATE_UNIT_COUNT + 1
        ];
        assert_eq!(
            validate_unit_count(&oversized).expect_err("limit").path(),
            "$.units"
        );
    }
}
