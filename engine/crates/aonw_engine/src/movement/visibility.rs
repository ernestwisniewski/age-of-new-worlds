use aonw_content::MapDefinition;
use aonw_domain::{FogVisibility, GameState, HexCoord, HexTileIndex, PlayerId};

/// Tile-indexed visibility prepared for one actor and state revision.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MovementVisibility {
    unrestricted: bool,
    discovered: Box<[u64]>,
    visible: Box<[u64]>,
}

impl MovementVisibility {
    /// Builds a compact visibility view from canonical fog.
    #[must_use]
    pub fn for_player(state: &GameState, map: &MapDefinition, player_id: &PlayerId) -> Self {
        let word_count = map.bounds().tile_count().div_ceil(u64::BITS as usize);
        let Some(fog) = state.fog_of_war().player(player_id) else {
            return Self {
                unrestricted: true,
                discovered: vec![0; word_count].into_boxed_slice(),
                visible: vec![0; word_count].into_boxed_slice(),
            };
        };
        let mut discovered = vec![0_u64; word_count];
        let mut visible = vec![0_u64; word_count];
        for coordinate in fog.discovered_hexes() {
            set(&mut discovered, map, *coordinate);
        }
        for coordinate in fog.visible_hexes() {
            set(&mut discovered, map, *coordinate);
            set(&mut visible, map, *coordinate);
        }
        Self {
            unrestricted: false,
            discovered: discovered.into_boxed_slice(),
            visible: visible.into_boxed_slice(),
        }
    }

    /// Returns visibility at one coordinate.
    #[must_use]
    pub fn at(&self, map: &MapDefinition, coordinate: HexCoord) -> FogVisibility {
        if self.unrestricted {
            return FogVisibility::Visible;
        }
        let Some(index) = map.tile_index(coordinate).map(HexTileIndex::get) else {
            return FogVisibility::Hidden;
        };
        if contains(&self.visible, index) {
            FogVisibility::Visible
        } else if contains(&self.discovered, index) {
            FogVisibility::Discovered
        } else {
            FogVisibility::Hidden
        }
    }
}

fn set(words: &mut [u64], map: &MapDefinition, coordinate: HexCoord) {
    if let Some(index) = map.tile_index(coordinate).map(HexTileIndex::get) {
        words[index / u64::BITS as usize] |= 1_u64 << (index % u64::BITS as usize);
    }
}

fn contains(words: &[u64], index: usize) -> bool {
    words
        .get(index / u64::BITS as usize)
        .is_some_and(|word| word & (1_u64 << (index % u64::BITS as usize)) != 0)
}
