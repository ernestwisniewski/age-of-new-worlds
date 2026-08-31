use aonw_content::{ContentHash, MapDefinition, RulesetDefinition};
use aonw_domain::{HexGridBounds, HexTileIndex, UnitMovementDomain};

use super::{MovementCost, terrain_entry_cost};

const MAX_NEIGHBORS: usize = 6;
const MAX_NEIGHBORS_U8: u8 = 6;

/// Immutable movement data prepared once for one map and ruleset identity.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CompiledMovementMap {
    map: MapDefinition,
    ruleset: RulesetDefinition,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
    neighbors: Box<[[usize; MAX_NEIGHBORS]]>,
    neighbor_counts: Box<[u8]>,
    entry_costs: Box<[[MovementCost; 3]]>,
    passable_tile_counts: [usize; 3],
}

/// Failure while preparing immutable movement data.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CompiledMovementMapError(Box<str>);

impl core::fmt::Display for CompiledMovementMapError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        formatter.write_str(&self.0)
    }
}

impl std::error::Error for CompiledMovementMapError {}

impl CompiledMovementMap {
    /// Precomputes movement data while taking ownership of validated content.
    ///
    /// # Errors
    ///
    /// Returns an error when either immutable content identity cannot be serialized.
    pub fn compile_owned(
        map: MapDefinition,
        ruleset: RulesetDefinition,
    ) -> Result<Self, CompiledMovementMapError> {
        let mut neighbors = Vec::with_capacity(map.bounds().tile_count());
        let mut neighbor_counts = Vec::with_capacity(map.bounds().tile_count());
        let mut entry_costs = Vec::with_capacity(map.bounds().tile_count());
        let mut passable_tile_counts = [0; 3];
        for tile in map.tiles() {
            let coordinate = tile.coordinate();
            let mut indices = [usize::MAX; MAX_NEIGHBORS];
            let mut count = 0;
            for neighbor in map.neighbors(coordinate) {
                let Some(index) = map.tile_index(neighbor) else {
                    continue;
                };
                indices[count] = index.get();
                count += 1;
            }
            neighbors.push(indices);
            neighbor_counts.push(u8::try_from(count).unwrap_or(MAX_NEIGHBORS_U8));
            let costs = [
                terrain_entry_cost(tile, UnitMovementDomain::Land),
                terrain_entry_cost(tile, UnitMovementDomain::Naval),
                terrain_entry_cost(tile, UnitMovementDomain::Air),
            ];
            for (index, cost) in costs.iter().enumerate() {
                if matches!(cost, MovementCost::Passable(_)) {
                    passable_tile_counts[index] += 1;
                }
            }
            entry_costs.push(costs);
        }
        Ok(Self {
            map_hash: map
                .content_hash()
                .map_err(|error| CompiledMovementMapError(error.to_string().into()))?,
            ruleset_hash: ruleset
                .content_hash()
                .map_err(|error| CompiledMovementMapError(error.to_string().into()))?,
            map,
            ruleset,
            neighbors: neighbors.into_boxed_slice(),
            neighbor_counts: neighbor_counts.into_boxed_slice(),
            entry_costs: entry_costs.into_boxed_slice(),
            passable_tile_counts,
        })
    }

    /// Returns the logical bounds compiled by this value.
    #[must_use]
    pub const fn bounds(&self) -> HexGridBounds {
        self.map.bounds()
    }

    /// Returns the validated map used to build every prepared value.
    #[must_use]
    pub const fn map(&self) -> &MapDefinition {
        &self.map
    }

    /// Returns the validated ruleset used to build every prepared value.
    #[must_use]
    pub const fn ruleset(&self) -> &RulesetDefinition {
        &self.ruleset
    }

    /// Returns the exact map identity.
    #[must_use]
    pub const fn map_hash(&self) -> ContentHash {
        self.map_hash
    }

    /// Returns the exact ruleset identity.
    #[must_use]
    pub const fn ruleset_hash(&self) -> ContentHash {
        self.ruleset_hash
    }

    pub(crate) fn neighbors(&self, index: usize) -> &[usize] {
        let count = usize::from(self.neighbor_counts[index]);
        &self.neighbors[index][..count]
    }

    pub(crate) fn entry_cost(&self, index: usize, domain: UnitMovementDomain) -> MovementCost {
        self.entry_costs[index][domain_index(domain)]
    }

    pub(crate) const fn passable_tile_count(&self, domain: UnitMovementDomain) -> usize {
        self.passable_tile_counts[domain_index(domain)]
    }
}

const fn domain_index(domain: UnitMovementDomain) -> usize {
    match domain {
        UnitMovementDomain::Land => 0,
        UnitMovementDomain::Naval => 1,
        UnitMovementDomain::Air => 2,
    }
}

pub(crate) fn neighbor_indices(
    map: &MapDefinition,
    compiled: Option<&CompiledMovementMap>,
    index: usize,
) -> ([usize; MAX_NEIGHBORS], usize) {
    if let Some(compiled) = compiled {
        let source = compiled.neighbors(index);
        let mut result = [usize::MAX; MAX_NEIGHBORS];
        result[..source.len()].copy_from_slice(source);
        return (result, source.len());
    }
    let mut result = [usize::MAX; MAX_NEIGHBORS];
    let Some(coordinate) = map.coordinate_at(HexTileIndex::new(index)) else {
        return (result, 0);
    };
    let mut count = 0;
    for neighbor in map.neighbors(coordinate) {
        result[count] = map
            .tile_index(neighbor)
            .expect("bounded neighbor has an index")
            .get();
        count += 1;
    }
    (result, count)
}

#[cfg(test)]
mod tests {
    use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
    use aonw_domain::{HexCoord, UnitMovementDomain};

    use super::CompiledMovementMap;
    use crate::{MovementCost, terrain_entry_cost};

    #[test]
    fn compiled_map_preserves_neighbors_costs_and_content_identity() {
        let tiles = (0..3)
            .flat_map(|row| {
                (0..3).map(move |col| {
                    TileDefinition::try_new_for_simulation(
                        HexCoord::new(col, row),
                        vec![TerrainType::Grassland],
                        Vec::new(),
                        0,
                    )
                    .expect("tile")
                })
            })
            .collect();
        let map = MapDefinition::try_new(
            "compiled-map",
            GridLayout::OddQFlatTop,
            3,
            3,
            tiles,
            Vec::new(),
        )
        .expect("map");
        let ruleset = RulesetDefinition::standard();
        let compiled =
            CompiledMovementMap::compile_owned(map.clone(), ruleset.clone()).expect("compiled map");

        assert_eq!(compiled.neighbors(4).len(), 6);
        assert_eq!(compiled.map_hash(), map.content_hash().expect("map hash"));
        assert_eq!(
            compiled.entry_cost(0, UnitMovementDomain::Land),
            terrain_entry_cost(
                map.tile_at(HexCoord::new(0, 0)).expect("tile"),
                UnitMovementDomain::Land
            )
        );
        assert!(matches!(
            compiled.entry_cost(0, UnitMovementDomain::Land),
            MovementCost::Passable(_)
        ));
    }
}
