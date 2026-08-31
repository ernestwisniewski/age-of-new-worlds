use aonw_content::{TerrainType, TileDefinition};

#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub(super) struct TerrainProfile {
    pub(super) base: Option<TerrainType>,
    features: u8,
}

impl TerrainProfile {
    const FOREST: u8 = 1 << 0;
    const JUNGLE: u8 = 1 << 1;
    const HILLS: u8 = 1 << 2;
    const WETLANDS: u8 = 1 << 3;

    pub(super) fn from_tile(tile: &TileDefinition) -> Self {
        let mut profile = Self {
            base: Some(tile.primary_movement_terrain()),
            features: 0,
        };
        for terrain in &tile.movement_terrains()[1..] {
            match terrain {
                TerrainType::Forest => profile.features |= Self::FOREST,
                TerrainType::Jungle => profile.features |= Self::JUNGLE,
                TerrainType::Hills => profile.features |= Self::HILLS,
                TerrainType::Wetlands => profile.features |= Self::WETLANDS,
                TerrainType::River => {}
                _ => unreachable!("validated tile features contain no primary terrain"),
            }
        }
        profile
    }

    pub(super) const fn has_forest(self) -> bool {
        self.has(Self::FOREST)
    }

    pub(super) const fn has_jungle(self) -> bool {
        self.has(Self::JUNGLE)
    }

    pub(super) const fn has_hills(self) -> bool {
        self.has(Self::HILLS)
    }

    pub(super) const fn has_wetlands(self) -> bool {
        self.has(Self::WETLANDS)
    }

    pub(super) const fn has_mountain(self) -> bool {
        matches!(self.base, Some(TerrainType::Mountain))
    }

    const fn has(self, flag: u8) -> bool {
        self.features & flag != 0
    }
}
