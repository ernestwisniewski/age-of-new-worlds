use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};

/// Player accounts and persisted match-start resource distribution.
#[allow(missing_docs)]
#[derive(Clone, Debug, Default, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct EconomyStateDto {
    pub player_gold: BTreeMap<String, i64>,
    pub player_war_weariness: BTreeMap<String, i64>,
    pub player_stability_net: BTreeMap<String, i64>,
    pub strategic_resources: BTreeMap<String, StrategicResourceStockpileDto>,
    pub initial_resource_distribution: InitialResourceDistributionDto,
}

/// Stockpiled strategic resources owned by one player.
#[allow(missing_docs)]
#[derive(Clone, Debug, Default, Eq, PartialEq, Deserialize, Serialize)]
#[serde(transparent)]
pub struct StrategicResourceStockpileDto(pub BTreeMap<ResourceTypeDto, i64>);

/// Persisted placements produced at match initialization.
#[allow(missing_docs)]
#[derive(Clone, Debug, Default, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct InitialResourceDistributionDto {
    pub seed: i64,
    pub placements: Vec<InitialResourcePlacementDto>,
}

/// One generated map resource.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct InitialResourcePlacementDto {
    pub col: i32,
    pub row: i32,
    pub resource: ResourceTypeDto,
}

/// Resource identifier shared by stockpiles and initial placements.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Ord, PartialEq, PartialOrd, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum ResourceTypeDto {
    Wheat,
    Fish,
    Deer,
    Sheep,
    Rice,
    Cow,
    Apple,
    Banana,
    Citrus,
    Gold,
    Silver,
    Gems,
    Silk,
    Spices,
    Cotton,
    Grapes,
    Ivory,
    Pearls,
    Coffee,
    Cocoa,
    Tobacco,
    Sugar,
    Iron,
    Coal,
    Oil,
    Aluminium,
    Uranium,
    Horses,
    Marble,
}
