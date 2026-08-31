use std::collections::BTreeMap;

use crate::{
    City, CityFoundingDraft, Diplomacy, FogOfWar, HexGridBounds, InfrastructureState,
    InteractionState, MatchIdentity, PendingInteraction, Unit, UnitPosture, WonderRegistry,
    WonderType, WorldArtifact, WorldArtifactLocation,
};

use super::{GameStateBuildError, UnitOccupancyPolicy};

pub(super) fn validate_wonder_hosts(
    cities: &[City],
    registry: &WonderRegistry,
) -> Result<(), GameStateBuildError> {
    let mut hosts = BTreeMap::<WonderType, crate::CityId>::new();
    for city in cities {
        for wonder in city.wonders() {
            if !registry.completed_by().contains_key(wonder) {
                return Err(GameStateBuildError::CityWonderNotRegistered {
                    city_id: city.id().clone(),
                    wonder: *wonder,
                });
            }
            if let Some(first_city_id) = hosts.insert(*wonder, city.id().clone()) {
                return Err(GameStateBuildError::DuplicateWonderHost {
                    wonder: *wonder,
                    first_city_id,
                    second_city_id: city.id().clone(),
                });
            }
        }
    }
    Ok(())
}

pub(super) fn validate_player_references(
    identity: &MatchIdentity,
    units: &[Unit],
    cities: &[City],
    interaction: &InteractionState,
    fog_of_war: &FogOfWar,
    diplomacy: &Diplomacy,
) -> Result<(), GameStateBuildError> {
    // Scenario content is assembled before a runtime binds its match identity.
    // Once any participants are bound, every aggregate reference is strict.
    if identity.participants().is_empty() {
        return Ok(());
    }
    for unit in units {
        if !identity.contains(unit.owner_player_id()) {
            return Err(GameStateBuildError::UnitPlayerNotFound {
                unit_id: unit.id().clone(),
                player_id: unit.owner_player_id().clone(),
            });
        }
    }
    for city in cities {
        for player_id in
            core::iter::once(city.owner_player_id()).chain(city.founding_owner_player_id())
        {
            if !identity.contains(player_id) {
                return Err(GameStateBuildError::CityPlayerNotFound {
                    city_id: city.id().clone(),
                    player_id: player_id.clone(),
                });
            }
        }
    }
    for player in fog_of_war.players() {
        if !identity.contains(player.player_id()) {
            return Err(GameStateBuildError::FogPlayerNotFound(
                player.player_id().clone(),
            ));
        }
    }
    if !fog_of_war.players().is_empty() {
        for participant in identity.participants() {
            if !fog_of_war.tracks(participant.id()) {
                return Err(GameStateBuildError::FogPlayerMissing(
                    participant.id().clone(),
                ));
            }
        }
    }
    for player_id in interaction
        .city_founding_draft()
        .map(CityFoundingDraft::owner_player_id)
        .into_iter()
        .chain(
            interaction
                .pending()
                .map(PendingInteraction::owner_player_id),
        )
    {
        if !identity.contains(player_id) {
            return Err(GameStateBuildError::InteractionPlayerNotFound(
                player_id.clone(),
            ));
        }
    }
    diplomacy
        .validate_for(identity)
        .map_err(GameStateBuildError::InvalidDiplomacy)
}

pub(super) fn unit_position_indices(
    bounds: HexGridBounds,
    occupancy_policy: UnitOccupancyPolicy,
    units: &[Unit],
) -> Result<Vec<usize>, GameStateBuildError> {
    for unit in units {
        if !bounds.contains(unit.position()) {
            return Err(GameStateBuildError::UnitOutOfBounds {
                unit_id: unit.id().clone(),
                position: unit.position(),
            });
        }
    }
    if let Some(pair) = units.windows(2).find(|pair| pair[0].id() == pair[1].id()) {
        return Err(GameStateBuildError::DuplicateUnitId(pair[0].id().clone()));
    }
    let mut indices = (0..units.len()).collect::<Vec<_>>();
    indices.sort_unstable_by(|left, right| {
        units[*left]
            .position()
            .cmp(&units[*right].position())
            .then_with(|| units[*left].id().cmp(units[*right].id()))
    });
    if let Some(pair) = indices.windows(2).find(|pair| {
        units[pair[0]].position() == units[pair[1]].position()
            && !occupancy_policy.permits(
                units[pair[0]].owner_player_id(),
                units[pair[1]].owner_player_id(),
            )
    }) {
        return Err(GameStateBuildError::OccupiedCoordinate {
            position: units[pair[0]].position(),
        });
    }
    Ok(indices)
}

pub(super) fn city_territory_indices(
    bounds: HexGridBounds,
    cities: &[City],
) -> Result<Vec<(crate::HexCoord, usize)>, GameStateBuildError> {
    for city in cities {
        city.validate()
            .map_err(|error| GameStateBuildError::InvalidCity {
                city_id: city.id().clone(),
                error,
            })?;
        for position in core::iter::once(city.center())
            .chain(city.controlled_hexes().iter().copied())
            .chain(city.worked_hexes().iter().copied())
            .chain(city.preferred_expansion_hex())
        {
            if !bounds.contains(position) {
                return Err(GameStateBuildError::CityOutOfBounds {
                    city_id: city.id().clone(),
                    position,
                });
            }
        }
    }
    if let Some(pair) = cities.windows(2).find(|pair| pair[0].id() == pair[1].id()) {
        return Err(GameStateBuildError::DuplicateCityId(pair[0].id().clone()));
    }
    let mut territory = cities
        .iter()
        .enumerate()
        .flat_map(|(index, city)| {
            core::iter::once(city.center())
                .chain(city.controlled_hexes().iter().copied())
                .map(move |coordinate| (coordinate, index))
        })
        .collect::<Vec<_>>();
    territory.sort_unstable_by(|left, right| {
        left.0
            .cmp(&right.0)
            .then_with(|| cities[left.1].id().cmp(cities[right.1].id()))
    });
    territory.dedup();
    if let Some(pair) = territory
        .windows(2)
        .find(|pair| pair[0].0 == pair[1].0 && pair[0].1 != pair[1].1)
    {
        return Err(GameStateBuildError::CityTerritoryOverlap {
            position: pair[0].0,
            first_city_id: cities[pair[0].1].id().clone(),
            second_city_id: cities[pair[1].1].id().clone(),
        });
    }
    Ok(territory)
}

pub(super) fn validate_artifact_ids(
    artifacts: &[WorldArtifact],
) -> Result<(), GameStateBuildError> {
    if let Some(pair) = artifacts
        .windows(2)
        .find(|pair| pair[0].id() == pair[1].id())
    {
        return Err(GameStateBuildError::DuplicateArtifactId(
            pair[0].id().clone(),
        ));
    }
    Ok(())
}

pub(super) fn validate_artifacts(
    bounds: HexGridBounds,
    units: &[Unit],
    cities: &[City],
    artifacts: &[WorldArtifact],
) -> Result<(), GameStateBuildError> {
    for artifact in artifacts {
        if let Some(position) = artifact.location().map_coordinate()
            && !bounds.contains(position)
        {
            return Err(GameStateBuildError::ArtifactOutOfBounds {
                artifact_id: artifact.id().clone(),
                position,
            });
        }
        match artifact.location() {
            WorldArtifactLocation::Map(_) => {}
            WorldArtifactLocation::Carried(unit_id) => {
                let unit = find_unit(units, unit_id).ok_or_else(|| {
                    GameStateBuildError::ArtifactUnitNotFound {
                        artifact_id: artifact.id().clone(),
                        unit_id: unit_id.clone(),
                    }
                })?;
                if unit.carried_artifact_id() != Some(artifact.id()) {
                    return Err(GameStateBuildError::ArtifactUnitMismatch {
                        artifact_id: artifact.id().clone(),
                        unit_id: unit_id.clone(),
                    });
                }
            }
            WorldArtifactLocation::Stored(city_id) => {
                if !cities.iter().any(|city| city.id() == city_id) {
                    return Err(GameStateBuildError::ArtifactCityNotFound {
                        artifact_id: artifact.id().clone(),
                        city_id: city_id.clone(),
                    });
                }
            }
            WorldArtifactLocation::Excavation {
                unit_id,
                coordinate,
                remaining_turns,
            } => {
                let unit = find_unit(units, unit_id).ok_or_else(|| {
                    GameStateBuildError::ArtifactUnitNotFound {
                        artifact_id: artifact.id().clone(),
                        unit_id: unit_id.clone(),
                    }
                })?;
                if unit.activity().excavating_artifact_id() != Some(artifact.id()) {
                    return Err(GameStateBuildError::ArtifactUnitMismatch {
                        artifact_id: artifact.id().clone(),
                        unit_id: unit_id.clone(),
                    });
                }
                if *remaining_turns == 0 || unit.position() != *coordinate {
                    return Err(GameStateBuildError::InvalidArtifactExcavation {
                        artifact_id: artifact.id().clone(),
                        unit_id: unit_id.clone(),
                    });
                }
            }
        }
    }
    let mut stored = artifacts
        .iter()
        .filter_map(|artifact| match artifact.location() {
            WorldArtifactLocation::Stored(city_id) => Some((city_id, artifact.id())),
            _ => None,
        })
        .collect::<Vec<_>>();
    stored.sort_unstable();
    if let Some(pair) = stored.windows(2).find(|pair| pair[0].0 == pair[1].0) {
        return Err(GameStateBuildError::CityArtifactSlotOccupied {
            city_id: pair[0].0.clone(),
            first_artifact_id: pair[0].1.clone(),
            second_artifact_id: pair[1].1.clone(),
        });
    }
    for unit in units {
        validate_unit_artifacts(unit, artifacts)?;
    }
    Ok(())
}

fn validate_unit_artifacts(
    unit: &Unit,
    artifacts: &[WorldArtifact],
) -> Result<(), GameStateBuildError> {
    if let (Some(carried_artifact_id), Some(excavating_artifact_id)) = (
        unit.carried_artifact_id(),
        unit.activity().excavating_artifact_id(),
    ) {
        return Err(GameStateBuildError::UnitArtifactActivityConflict {
            unit_id: unit.id().clone(),
            carried_artifact_id: carried_artifact_id.clone(),
            excavating_artifact_id: excavating_artifact_id.clone(),
        });
    }
    if let Some(artifact_id) = unit.carried_artifact_id() {
        let artifact = referenced_artifact(unit, artifact_id, artifacts)?;
        if artifact.location() != &WorldArtifactLocation::Carried(unit.id().clone()) {
            return Err(GameStateBuildError::ArtifactUnitMismatch {
                artifact_id: artifact_id.clone(),
                unit_id: unit.id().clone(),
            });
        }
    }
    if let Some(artifact_id) = unit.activity().excavating_artifact_id() {
        let artifact = referenced_artifact(unit, artifact_id, artifacts)?;
        if !matches!(
            artifact.location(),
            WorldArtifactLocation::Excavation { unit_id, .. } if unit_id == unit.id()
        ) {
            return Err(GameStateBuildError::ArtifactUnitMismatch {
                artifact_id: artifact_id.clone(),
                unit_id: unit.id().clone(),
            });
        }
    }
    Ok(())
}

fn referenced_artifact<'a>(
    unit: &Unit,
    artifact_id: &crate::ArtifactId,
    artifacts: &'a [WorldArtifact],
) -> Result<&'a WorldArtifact, GameStateBuildError> {
    artifacts
        .iter()
        .find(|artifact| artifact.id() == artifact_id)
        .ok_or_else(|| GameStateBuildError::UnitArtifactNotFound {
            unit_id: unit.id().clone(),
            artifact_id: artifact_id.clone(),
        })
}

pub(super) fn validate_interaction(
    bounds: HexGridBounds,
    units: &[Unit],
    cities: &[City],
    interaction: &InteractionState,
) -> Result<(), GameStateBuildError> {
    if let Some(draft) = interaction.city_founding_draft() {
        let unit = find_unit(units, draft.unit_id())
            .ok_or_else(|| GameStateBuildError::InteractionUnitNotFound(draft.unit_id().clone()))?;
        if unit.owner_player_id() != draft.owner_player_id() {
            return Err(GameStateBuildError::InteractionOwnerMismatch);
        }
        if let Some(position) = core::iter::once(draft.center())
            .chain(draft.controlled_hexes().iter().copied())
            .find(|position| !bounds.contains(*position))
        {
            return Err(GameStateBuildError::InteractionOutOfBounds(position));
        }
    }
    let Some(pending) = interaction.pending() else {
        return Ok(());
    };
    if let Some(unit_id) = pending.unit_id() {
        let unit = find_unit(units, unit_id)
            .ok_or_else(|| GameStateBuildError::InteractionUnitNotFound(unit_id.clone()))?;
        if unit.owner_player_id() != pending.owner_player_id() {
            return Err(GameStateBuildError::InteractionOwnerMismatch);
        }
        if matches!(pending, PendingInteraction::UnitTurnSkip { .. })
            && (unit.movement_units().get() != 0 || unit.posture() != UnitPosture::Active)
        {
            return Err(GameStateBuildError::InvalidTurnSkipState(unit_id.clone()));
        }
    }
    match pending {
        PendingInteraction::CityWorkedHexSelection {
            owner_player_id,
            city_id,
        }
        | PendingInteraction::CityExpansionSelection {
            owner_player_id,
            city_id,
        } => {
            let city = cities
                .iter()
                .find(|city| city.id() == city_id)
                .ok_or_else(|| GameStateBuildError::InteractionCityNotFound(city_id.clone()))?;
            if city.owner_player_id() != owner_player_id {
                return Err(GameStateBuildError::InteractionOwnerMismatch);
            }
        }
        PendingInteraction::AttackTargeting {
            defender: Some(position),
            ..
        } if !bounds.contains(*position) => {
            return Err(GameStateBuildError::InteractionOutOfBounds(*position));
        }
        _ => {}
    }
    Ok(())
}

pub(super) fn validate_environment(
    bounds: HexGridBounds,
    identity: &MatchIdentity,
    cities: &[City],
    fog_of_war: &FogOfWar,
    infrastructure: &InfrastructureState,
) -> Result<(), GameStateBuildError> {
    for player_fog in fog_of_war.players() {
        if let Some(position) = player_fog
            .discovered_hexes()
            .iter()
            .find(|coordinate| !bounds.contains(**coordinate))
        {
            return Err(GameStateBuildError::FogOutOfBounds {
                player_id: player_fog.player_id().clone(),
                position: *position,
            });
        }
    }
    infrastructure
        .validate_for(bounds, identity, cities)
        .map_err(GameStateBuildError::InvalidInfrastructure)?;
    Ok(())
}

fn find_unit<'a>(units: &'a [Unit], unit_id: &crate::UnitId) -> Option<&'a Unit> {
    units.iter().find(|unit| unit.id() == unit_id)
}
