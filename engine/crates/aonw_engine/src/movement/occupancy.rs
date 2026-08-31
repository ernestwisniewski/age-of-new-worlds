use aonw_content::MapDefinition;
use aonw_domain::Unit;

use crate::EngineContext;

/// Tile-indexed occupancy mask prepared for one moving unit and actor view.
#[derive(Clone, Debug, Eq, PartialEq)]
pub(crate) struct MovementOccupancy {
    words: Box<[u64]>,
}

impl MovementOccupancy {
    pub(crate) fn for_unit(
        units: &[Unit],
        map: &MapDefinition,
        unit: &Unit,
        context: EngineContext<'_>,
    ) -> Self {
        let mut words = vec![0_u64; map.bounds().tile_count().div_ceil(u64::BITS as usize)];
        for candidate in units {
            if candidate.id() == unit.id() || !context.observes_occupancy(unit, candidate) {
                continue;
            }
            if context.can_share_occupied_city(unit, candidate.position()) {
                continue;
            }
            if let Some(index) = map.tile_index(candidate.position()) {
                let index = index.get();
                words[index / u64::BITS as usize] |= 1_u64 << (index % u64::BITS as usize);
            }
        }
        Self {
            words: words.into_boxed_slice(),
        }
    }

    pub(crate) fn contains(&self, index: usize) -> bool {
        self.words
            .get(index / u64::BITS as usize)
            .is_some_and(|word| word & (1_u64 << (index % u64::BITS as usize)) != 0)
    }
}
