use serde::{Deserialize, Serialize};

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Deserialize, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum GridLayout {
    OddQFlatTop,
}

#[allow(missing_docs)]
impl GridLayout {
    #[must_use]
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::OddQFlatTop => "oddQFlatTop",
        }
    }
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Deserialize, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum TerrainType {
    Ocean,
    Coast,
    Lake,
    Plains,
    Grassland,
    Desert,
    Tundra,
    Snow,
    Mountain,
    Hills,
    Wetlands,
    Jungle,
    Forest,
    River,
}

#[allow(missing_docs)]
impl TerrainType {
    /// Complete stable palette exposed to framework-neutral authoring clients.
    pub const ALL: [Self; 14] = [
        Self::Ocean,
        Self::Coast,
        Self::Lake,
        Self::Plains,
        Self::Grassland,
        Self::Desert,
        Self::Tundra,
        Self::Snow,
        Self::Mountain,
        Self::Hills,
        Self::Wetlands,
        Self::Jungle,
        Self::Forest,
        Self::River,
    ];

    #[must_use]
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::Ocean => "ocean",
            Self::Coast => "coast",
            Self::Lake => "lake",
            Self::Plains => "plains",
            Self::Grassland => "grassland",
            Self::Desert => "desert",
            Self::Tundra => "tundra",
            Self::Snow => "snow",
            Self::Mountain => "mountain",
            Self::Hills => "hills",
            Self::Wetlands => "wetlands",
            Self::Jungle => "jungle",
            Self::Forest => "forest",
            Self::River => "river",
        }
    }

    #[must_use]
    pub const fn is_primary(self) -> bool {
        matches!(
            self,
            Self::Ocean
                | Self::Coast
                | Self::Lake
                | Self::Plains
                | Self::Grassland
                | Self::Desert
                | Self::Tundra
                | Self::Snow
                | Self::Mountain
        )
    }

    #[must_use]
    pub const fn is_feature(self) -> bool {
        matches!(
            self,
            Self::Hills | Self::Wetlands | Self::Jungle | Self::Forest | Self::River
        )
    }

    #[must_use]
    pub const fn is_yield_terrain(self) -> bool {
        !matches!(self, Self::River)
    }

    pub(crate) const fn canonical_rank(self) -> u8 {
        match self {
            Self::Ocean => 0,
            Self::Coast => 1,
            Self::Lake => 2,
            Self::Plains => 3,
            Self::Grassland => 4,
            Self::Desert => 5,
            Self::Tundra => 6,
            Self::Snow => 7,
            Self::Mountain => 8,
            Self::Hills => 9,
            Self::Wetlands => 10,
            Self::Jungle => 11,
            Self::Forest => 12,
            Self::River => 13,
        }
    }
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Deserialize, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum ResourceType {
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

#[allow(missing_docs)]
impl ResourceType {
    /// Complete stable palette exposed to framework-neutral authoring clients.
    pub const ALL: [Self; 29] = [
        Self::Wheat,
        Self::Fish,
        Self::Deer,
        Self::Sheep,
        Self::Rice,
        Self::Cow,
        Self::Apple,
        Self::Banana,
        Self::Citrus,
        Self::Gold,
        Self::Silver,
        Self::Gems,
        Self::Silk,
        Self::Spices,
        Self::Cotton,
        Self::Grapes,
        Self::Ivory,
        Self::Pearls,
        Self::Coffee,
        Self::Cocoa,
        Self::Tobacco,
        Self::Sugar,
        Self::Iron,
        Self::Coal,
        Self::Oil,
        Self::Aluminium,
        Self::Uranium,
        Self::Horses,
        Self::Marble,
    ];

    #[must_use]
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::Wheat => "wheat",
            Self::Fish => "fish",
            Self::Deer => "deer",
            Self::Sheep => "sheep",
            Self::Rice => "rice",
            Self::Cow => "cow",
            Self::Apple => "apple",
            Self::Banana => "banana",
            Self::Citrus => "citrus",
            Self::Gold => "gold",
            Self::Silver => "silver",
            Self::Gems => "gems",
            Self::Silk => "silk",
            Self::Spices => "spices",
            Self::Cotton => "cotton",
            Self::Grapes => "grapes",
            Self::Ivory => "ivory",
            Self::Pearls => "pearls",
            Self::Coffee => "coffee",
            Self::Cocoa => "cocoa",
            Self::Tobacco => "tobacco",
            Self::Sugar => "sugar",
            Self::Iron => "iron",
            Self::Coal => "coal",
            Self::Oil => "oil",
            Self::Aluminium => "aluminium",
            Self::Uranium => "uranium",
            Self::Horses => "horses",
            Self::Marble => "marble",
        }
    }

    pub(crate) const fn canonical_rank(self) -> u8 {
        match self {
            Self::Wheat => 0,
            Self::Fish => 1,
            Self::Deer => 2,
            Self::Sheep => 3,
            Self::Rice => 4,
            Self::Cow => 5,
            Self::Apple => 6,
            Self::Banana => 7,
            Self::Citrus => 8,
            Self::Gold => 9,
            Self::Silver => 10,
            Self::Gems => 11,
            Self::Silk => 12,
            Self::Spices => 13,
            Self::Cotton => 14,
            Self::Grapes => 15,
            Self::Ivory => 16,
            Self::Pearls => 17,
            Self::Coffee => 18,
            Self::Cocoa => 19,
            Self::Tobacco => 20,
            Self::Sugar => 21,
            Self::Iron => 22,
            Self::Coal => 23,
            Self::Oil => 24,
            Self::Aluminium => 25,
            Self::Uranium => 26,
            Self::Horses => 27,
            Self::Marble => 28,
        }
    }
}

#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum MapObjectiveType {
    Ruins,
    StrategicPass,
    HolySite,
    LegendaryResource,
}

#[allow(missing_docs)]
impl MapObjectiveType {
    #[must_use]
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::Ruins => "ruins",
            Self::StrategicPass => "strategicPass",
            Self::HolySite => "holySite",
            Self::LegendaryResource => "legendaryResource",
        }
    }
}
