use std::collections::BTreeMap;

use aonw_contracts::{
    EconomyStateDto, InitialResourceDistributionDto, InitialResourcePlacementDto, ResourceTypeDto,
    StrategicResourceStockpileDto,
};
use aonw_domain::{
    EconomyState, EconomyStateBuildError, HexCoord, HexGridBounds, InitialResourceDistribution,
    InitialResourcePlacement, MatchIdentity, PlayerId, ResourceType, StrategicResourceStockpile,
};

use super::error::GameStateMappingError;

pub(super) fn decode_economy(
    identity: &MatchIdentity,
    bounds: HexGridBounds,
    dto: EconomyStateDto,
) -> Result<EconomyState, GameStateMappingError> {
    let player_gold = decode_player_accounts(identity, dto.player_gold, "$.economy.playerGold")?;
    let player_war_weariness = decode_player_accounts(
        identity,
        dto.player_war_weariness,
        "$.economy.playerWarWeariness",
    )?;
    let player_stability_net = decode_player_accounts(
        identity,
        dto.player_stability_net,
        "$.economy.playerStabilityNet",
    )?;
    let strategic_resources = dto
        .strategic_resources
        .into_iter()
        .map(|(player, stockpile)| {
            let path = format!("$.economy.strategicResources.{player}");
            let player = decode_player_id(player, &path)?;
            if !identity.contains(&player) {
                return Err(GameStateMappingError::new(
                    path,
                    format!("economy player is not a participant: {player}"),
                ));
            }
            let stockpile = decode_stockpile(stockpile, &path)?;
            Ok((player, stockpile))
        })
        .collect::<Result<BTreeMap<_, _>, GameStateMappingError>>()?;
    let distribution = decode_distribution(bounds, dto.initial_resource_distribution)?;

    EconomyState::try_new(
        identity,
        bounds,
        player_gold,
        player_war_weariness,
        player_stability_net,
        strategic_resources,
        distribution,
    )
    .map_err(|error| map_economy_error(&error))
}

#[must_use]
pub(super) fn encode_economy(value: &EconomyState) -> EconomyStateDto {
    EconomyStateDto {
        player_gold: encode_player_accounts(value.player_gold()),
        player_war_weariness: encode_player_accounts(value.player_war_weariness()),
        player_stability_net: encode_player_accounts(value.player_stability_net()),
        strategic_resources: value
            .strategic_resources()
            .iter()
            .map(|(player, stockpile)| (player.as_str().to_owned(), encode_stockpile(stockpile)))
            .collect(),
        initial_resource_distribution: InitialResourceDistributionDto {
            seed: value.initial_resource_distribution().seed(),
            placements: value
                .initial_resource_distribution()
                .placements()
                .iter()
                .map(|placement| InitialResourcePlacementDto {
                    col: placement.coordinate().col(),
                    row: placement.coordinate().row(),
                    resource: encode_resource(placement.resource()),
                })
                .collect(),
        },
    }
}

fn decode_player_accounts(
    identity: &MatchIdentity,
    accounts: BTreeMap<String, i64>,
    path: &str,
) -> Result<BTreeMap<PlayerId, i64>, GameStateMappingError> {
    accounts
        .into_iter()
        .map(|(player, value)| {
            let entry_path = format!("{path}.{player}");
            let player = decode_player_id(player, &entry_path)?;
            if !identity.contains(&player) {
                return Err(GameStateMappingError::new(
                    entry_path,
                    format!("economy player is not a participant: {player}"),
                ));
            }
            Ok((player, value))
        })
        .collect()
}

fn encode_player_accounts(accounts: &BTreeMap<PlayerId, i64>) -> BTreeMap<String, i64> {
    accounts
        .iter()
        .map(|(player, value)| (player.as_str().to_owned(), *value))
        .collect()
}

fn decode_player_id(value: String, path: &str) -> Result<PlayerId, GameStateMappingError> {
    PlayerId::new(value).map_err(|error| GameStateMappingError::new(path, error.to_string()))
}

pub(super) fn decode_stockpile(
    dto: StrategicResourceStockpileDto,
    path: &str,
) -> Result<StrategicResourceStockpile, GameStateMappingError> {
    StrategicResourceStockpile::try_new(
        dto.0
            .into_iter()
            .map(|(resource, amount)| (decode_resource(resource), amount))
            .collect(),
    )
    .map_err(|error| GameStateMappingError::new(path, error.to_string()))
}

#[must_use]
pub(super) fn encode_stockpile(
    value: &StrategicResourceStockpile,
) -> StrategicResourceStockpileDto {
    StrategicResourceStockpileDto(
        value
            .amounts()
            .iter()
            .map(|(resource, amount)| (encode_resource(*resource), *amount))
            .collect(),
    )
}

fn decode_distribution(
    bounds: HexGridBounds,
    dto: InitialResourceDistributionDto,
) -> Result<InitialResourceDistribution, GameStateMappingError> {
    for (index, placement) in dto.placements.iter().enumerate() {
        let coordinate = HexCoord::new(placement.col, placement.row);
        if !bounds.contains(coordinate) {
            return Err(GameStateMappingError::new(
                format!("$.economy.initialResourceDistribution.placements[{index}]"),
                format!(
                    "initial resource at ({}, {}) is outside the map",
                    coordinate.col(),
                    coordinate.row()
                ),
            ));
        }
    }
    InitialResourceDistribution::try_new(
        dto.seed,
        dto.placements.into_iter().map(|placement| {
            InitialResourcePlacement::new(
                HexCoord::new(placement.col, placement.row),
                decode_resource(placement.resource),
            )
        }),
    )
    .map_err(|error| map_economy_error(&error))
}

fn map_economy_error(error: &EconomyStateBuildError) -> GameStateMappingError {
    let path = match error {
        EconomyStateBuildError::UnknownPlayer(_)
        | EconomyStateBuildError::AccountOverflow { .. }
        | EconomyStateBuildError::InsufficientBalance { .. } => "$.economy".to_owned(),
        EconomyStateBuildError::NegativeGold { player, .. } => {
            format!("$.economy.playerGold.{}", player.as_str())
        }
        EconomyStateBuildError::NegativeWarWeariness { player, .. } => {
            format!("$.economy.playerWarWeariness.{}", player.as_str())
        }
        EconomyStateBuildError::ResourceNotStockpiled(_)
        | EconomyStateBuildError::NonPositiveResourceAmount { .. } => {
            "$.economy.strategicResources".to_owned()
        }
        EconomyStateBuildError::DuplicateInitialResource(_)
        | EconomyStateBuildError::InitialResourceOutOfBounds(_) => {
            "$.economy.initialResourceDistribution.placements".to_owned()
        }
    };
    GameStateMappingError::new(path, error.to_string())
}

macro_rules! resource_mapping {
    ($value:expr, $source:path => $target:path, $($rest_source:path => $rest_target:path),+ $(,)?) => {
        match $value {
            $source => $target,
            $($rest_source => $rest_target),+
        }
    };
}

/// Converts the current wire resource identity into the canonical domain value.
#[must_use]
pub const fn decode_resource(value: ResourceTypeDto) -> ResourceType {
    resource_mapping!(
        value,
        ResourceTypeDto::Wheat => ResourceType::Wheat,
        ResourceTypeDto::Fish => ResourceType::Fish,
        ResourceTypeDto::Deer => ResourceType::Deer,
        ResourceTypeDto::Sheep => ResourceType::Sheep,
        ResourceTypeDto::Rice => ResourceType::Rice,
        ResourceTypeDto::Cow => ResourceType::Cow,
        ResourceTypeDto::Apple => ResourceType::Apple,
        ResourceTypeDto::Banana => ResourceType::Banana,
        ResourceTypeDto::Citrus => ResourceType::Citrus,
        ResourceTypeDto::Gold => ResourceType::Gold,
        ResourceTypeDto::Silver => ResourceType::Silver,
        ResourceTypeDto::Gems => ResourceType::Gems,
        ResourceTypeDto::Silk => ResourceType::Silk,
        ResourceTypeDto::Spices => ResourceType::Spices,
        ResourceTypeDto::Cotton => ResourceType::Cotton,
        ResourceTypeDto::Grapes => ResourceType::Grapes,
        ResourceTypeDto::Ivory => ResourceType::Ivory,
        ResourceTypeDto::Pearls => ResourceType::Pearls,
        ResourceTypeDto::Coffee => ResourceType::Coffee,
        ResourceTypeDto::Cocoa => ResourceType::Cocoa,
        ResourceTypeDto::Tobacco => ResourceType::Tobacco,
        ResourceTypeDto::Sugar => ResourceType::Sugar,
        ResourceTypeDto::Iron => ResourceType::Iron,
        ResourceTypeDto::Coal => ResourceType::Coal,
        ResourceTypeDto::Oil => ResourceType::Oil,
        ResourceTypeDto::Aluminium => ResourceType::Aluminium,
        ResourceTypeDto::Uranium => ResourceType::Uranium,
        ResourceTypeDto::Horses => ResourceType::Horses,
        ResourceTypeDto::Marble => ResourceType::Marble,
    )
}

/// Converts a canonical resource identity into the current wire value.
#[must_use]
pub const fn encode_resource(value: ResourceType) -> ResourceTypeDto {
    resource_mapping!(
        value,
        ResourceType::Wheat => ResourceTypeDto::Wheat,
        ResourceType::Fish => ResourceTypeDto::Fish,
        ResourceType::Deer => ResourceTypeDto::Deer,
        ResourceType::Sheep => ResourceTypeDto::Sheep,
        ResourceType::Rice => ResourceTypeDto::Rice,
        ResourceType::Cow => ResourceTypeDto::Cow,
        ResourceType::Apple => ResourceTypeDto::Apple,
        ResourceType::Banana => ResourceTypeDto::Banana,
        ResourceType::Citrus => ResourceTypeDto::Citrus,
        ResourceType::Gold => ResourceTypeDto::Gold,
        ResourceType::Silver => ResourceTypeDto::Silver,
        ResourceType::Gems => ResourceTypeDto::Gems,
        ResourceType::Silk => ResourceTypeDto::Silk,
        ResourceType::Spices => ResourceTypeDto::Spices,
        ResourceType::Cotton => ResourceTypeDto::Cotton,
        ResourceType::Grapes => ResourceTypeDto::Grapes,
        ResourceType::Ivory => ResourceTypeDto::Ivory,
        ResourceType::Pearls => ResourceTypeDto::Pearls,
        ResourceType::Coffee => ResourceTypeDto::Coffee,
        ResourceType::Cocoa => ResourceTypeDto::Cocoa,
        ResourceType::Tobacco => ResourceTypeDto::Tobacco,
        ResourceType::Sugar => ResourceTypeDto::Sugar,
        ResourceType::Iron => ResourceTypeDto::Iron,
        ResourceType::Coal => ResourceTypeDto::Coal,
        ResourceType::Oil => ResourceTypeDto::Oil,
        ResourceType::Aluminium => ResourceTypeDto::Aluminium,
        ResourceType::Uranium => ResourceTypeDto::Uranium,
        ResourceType::Horses => ResourceTypeDto::Horses,
        ResourceType::Marble => ResourceTypeDto::Marble,
    )
}
