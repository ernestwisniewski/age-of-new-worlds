use aonw_domain::{HexCoord, HexGridBounds, HexTileIndex};

use crate::catalog::{GridLayout, MapObjectiveType, ResourceType, TerrainType};
use crate::validation::{MapValidationError, validate_content_id};

/// Minimum logical map width accepted by the content domain.
pub const MIN_MAP_COLS: u16 = 1;
/// Maximum logical map width accepted by the content domain.
pub const MAX_MAP_COLS: u16 = 40;
/// Minimum logical map height accepted by the content domain.
pub const MIN_MAP_ROWS: u16 = 1;
/// Maximum logical map height accepted by the content domain.
pub const MAX_MAP_ROWS: u16 = 30;
const MAX_HEIGHT: u8 = 5;
const MAX_TILE_COUNT: usize = MAX_MAP_COLS as usize * MAX_MAP_ROWS as usize;
const OBJECTIVE_OCCUPANCY_WORDS: usize = MAX_TILE_COUNT.div_ceil(u64::BITS as usize);

#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct TerrainProfile {
    terrain_tags: Box<[TerrainType]>,
    movement_terrains: Box<[TerrainType]>,
    yield_terrain: TerrainType,
}

#[allow(missing_docs)]
impl TerrainProfile {
    /// Constructs one validated terrain source of truth.
    ///
    /// Tag order expresses authored precedence: the first tag is used for
    /// display and the first non-river tag owns the base economic yield.
    ///
    /// # Errors
    ///
    /// Returns [`MapValidationError`] when tags are empty, duplicated, or do
    /// not resolve to a movement primary and an economic yield terrain.
    pub fn try_new(terrain_tags: Vec<TerrainType>) -> Result<Self, MapValidationError> {
        Self::try_new_at("$", terrain_tags)
    }

    pub(crate) fn try_new_at(
        path: &str,
        terrain_tags: Vec<TerrainType>,
    ) -> Result<Self, MapValidationError> {
        if terrain_tags.is_empty() {
            return Err(MapValidationError::new(
                format!("{path}.terrainTags"),
                "must contain at least one terrain tag",
            ));
        }
        validate_unique_values(
            &format!("{path}.terrainTags"),
            &terrain_tags,
            TerrainType::canonical_rank,
        )?;
        let yield_terrain = terrain_tags
            .iter()
            .copied()
            .find(|terrain| terrain.is_yield_terrain())
            .ok_or_else(|| {
                MapValidationError::new(
                    format!("{path}.terrainTags"),
                    "must contain a non-river yield terrain",
                )
            })?;
        let movement_terrains = derive_movement_terrains(path, &terrain_tags)?;
        Ok(Self {
            terrain_tags: terrain_tags.into_boxed_slice(),
            movement_terrains: movement_terrains.into_boxed_slice(),
            yield_terrain,
        })
    }

    #[must_use]
    pub fn terrain_tags(&self) -> &[TerrainType] {
        &self.terrain_tags
    }

    #[must_use]
    pub const fn display_terrain(&self) -> TerrainType {
        self.terrain_tags[0]
    }

    #[must_use]
    pub const fn yield_terrain(&self) -> TerrainType {
        self.yield_terrain
    }

    #[must_use]
    pub fn movement_terrains(&self) -> &[TerrainType] {
        &self.movement_terrains
    }
}

#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct TileDefinition {
    coordinate: HexCoord,
    terrain: TerrainProfile,
    resources: Box<[ResourceType]>,
    height: u8,
}

#[allow(missing_docs)]
impl TileDefinition {
    /// Constructs a validated logical map tile.
    ///
    /// # Errors
    ///
    /// Returns [`MapValidationError`] for duplicate resources or unsupported height.
    pub fn try_new(
        coordinate: HexCoord,
        terrain: TerrainProfile,
        resources: Vec<ResourceType>,
        height: u8,
    ) -> Result<Self, MapValidationError> {
        Self::try_new_at("$", coordinate, terrain, resources, height)
    }

    /// Constructs a rules-only fixture tile with neutral presentation semantics.
    ///
    /// The primary movement terrain is used for display and yields, while all
    /// movement terrains become tags. Authored map content must use [`Self::try_new`].
    ///
    /// # Errors
    ///
    /// Returns [`MapValidationError`] for invalid terrain data, duplicate resources,
    /// or unsupported height.
    pub fn try_new_for_simulation(
        coordinate: HexCoord,
        mut movement_terrains: Vec<TerrainType>,
        resources: Vec<ResourceType>,
        height: u8,
    ) -> Result<Self, MapValidationError> {
        normalize_movement_terrains("$", &mut movement_terrains)?;
        let terrain = TerrainProfile::try_new(movement_terrains)?;
        Self::try_new(coordinate, terrain, resources, height)
    }

    pub(crate) fn try_new_at(
        path: &str,
        coordinate: HexCoord,
        terrain: TerrainProfile,
        mut resources: Vec<ResourceType>,
        height: u8,
    ) -> Result<Self, MapValidationError> {
        validate_unique_values(
            &format!("{path}.resources"),
            &resources,
            ResourceType::canonical_rank,
        )?;
        if height > MAX_HEIGHT {
            return Err(MapValidationError::new(
                format!("{path}.height"),
                format!("must be in range 0..={MAX_HEIGHT}"),
            ));
        }
        resources.sort_unstable_by_key(|resource| resource.canonical_rank());
        Ok(Self {
            coordinate,
            terrain,
            resources: resources.into_boxed_slice(),
            height,
        })
    }

    #[must_use]
    pub const fn coordinate(&self) -> HexCoord {
        self.coordinate
    }

    #[must_use]
    pub fn movement_terrains(&self) -> &[TerrainType] {
        self.terrain.movement_terrains()
    }

    #[must_use]
    pub const fn primary_movement_terrain(&self) -> TerrainType {
        self.terrain.movement_terrains[0]
    }

    #[must_use]
    pub fn has_movement_terrain(&self, terrain: TerrainType) -> bool {
        self.terrain.movement_terrains.contains(&terrain)
    }

    #[must_use]
    pub const fn display_terrain(&self) -> TerrainType {
        self.terrain.display_terrain()
    }

    #[must_use]
    pub const fn yield_terrain(&self) -> TerrainType {
        self.terrain.yield_terrain()
    }

    #[must_use]
    pub fn terrain_tags(&self) -> &[TerrainType] {
        self.terrain.terrain_tags()
    }

    #[must_use]
    pub const fn terrain(&self) -> &TerrainProfile {
        &self.terrain
    }

    #[must_use]
    pub fn resources(&self) -> &[ResourceType] {
        &self.resources
    }

    #[must_use]
    pub const fn height(&self) -> u8 {
        self.height
    }
}

fn derive_movement_terrains(
    path: &str,
    terrain_tags: &[TerrainType],
) -> Result<Vec<TerrainType>, MapValidationError> {
    let primary = if terrain_tags.contains(&TerrainType::Mountain) {
        Some(TerrainType::Mountain)
    } else {
        terrain_tags
            .iter()
            .copied()
            .filter(|terrain| terrain.is_primary())
            .fold(None, |selected, candidate| match selected {
                None => Some(candidate),
                Some(current) if is_open_water(current) && !is_open_water(candidate) => {
                    Some(candidate)
                }
                Some(current) => Some(current),
            })
            .or_else(|| {
                terrain_tags
                    .iter()
                    .any(|terrain| is_vegetated_feature(*terrain))
                    .then_some(TerrainType::Grassland)
            })
            .or_else(|| {
                terrain_tags
                    .contains(&TerrainType::Hills)
                    .then_some(TerrainType::Plains)
            })
    }
    .ok_or_else(|| {
        MapValidationError::new(
            format!("{path}.terrainTags"),
            "must resolve to a primary movement terrain",
        )
    })?;

    let mut movement = vec![primary];
    for feature in [
        TerrainType::Hills,
        TerrainType::Wetlands,
        TerrainType::Jungle,
        TerrainType::Forest,
        TerrainType::River,
    ] {
        if terrain_tags.contains(&feature) {
            movement.push(feature);
        }
    }
    Ok(movement)
}

pub(crate) fn normalize_movement_terrains(
    path: &str,
    movement_terrains: &mut [TerrainType],
) -> Result<(), MapValidationError> {
    if movement_terrains.is_empty() {
        return Err(MapValidationError::new(
            format!("{path}.terrains"),
            "must contain at least one terrain",
        ));
    }
    validate_unique_values(
        &format!("{path}.terrains"),
        movement_terrains,
        TerrainType::canonical_rank,
    )?;
    if !movement_terrains[0].is_primary() {
        return Err(MapValidationError::new(
            format!("{path}.terrains[0]"),
            "must be a primary terrain",
        ));
    }
    if let Some((index, _)) = movement_terrains
        .iter()
        .enumerate()
        .skip(1)
        .find(|(_, terrain)| !terrain.is_feature())
    {
        return Err(MapValidationError::new(
            format!("{path}.terrains[{index}]"),
            "must be a terrain feature",
        ));
    }
    movement_terrains[1..].sort_unstable_by_key(|terrain| terrain.canonical_rank());
    Ok(())
}

const fn is_open_water(terrain: TerrainType) -> bool {
    matches!(terrain, TerrainType::Ocean | TerrainType::Lake)
}

const fn is_vegetated_feature(terrain: TerrainType) -> bool {
    matches!(
        terrain,
        TerrainType::Wetlands | TerrainType::Jungle | TerrainType::Forest
    )
}

#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MapObjective {
    id: Box<str>,
    objective_type: MapObjectiveType,
    coordinate: HexCoord,
    required_hold_turns: u32,
    victory_points: u32,
    gold_per_turn: u32,
}

#[allow(missing_docs)]
impl MapObjective {
    /// Constructs a validated logical map objective.
    ///
    /// # Errors
    ///
    /// Returns [`MapValidationError`] for an invalid identifier or zero hold duration.
    #[allow(clippy::too_many_arguments)]
    pub fn try_new(
        id: impl Into<Box<str>>,
        objective_type: MapObjectiveType,
        coordinate: HexCoord,
        required_hold_turns: u32,
        victory_points: u32,
        gold_per_turn: u32,
    ) -> Result<Self, MapValidationError> {
        Self::try_new_at(
            "$",
            id.into(),
            objective_type,
            coordinate,
            required_hold_turns,
            victory_points,
            gold_per_turn,
        )
    }

    #[allow(clippy::too_many_arguments)]
    pub(crate) fn try_new_at(
        path: &str,
        id: Box<str>,
        objective_type: MapObjectiveType,
        coordinate: HexCoord,
        required_hold_turns: u32,
        victory_points: u32,
        gold_per_turn: u32,
    ) -> Result<Self, MapValidationError> {
        validate_content_id(&format!("{path}.id"), &id)?;
        if required_hold_turns == 0 {
            return Err(MapValidationError::new(
                format!("{path}.requiredHoldTurns"),
                "must be positive",
            ));
        }
        Ok(Self {
            id,
            objective_type,
            coordinate,
            required_hold_turns,
            victory_points,
            gold_per_turn,
        })
    }

    #[must_use]
    pub fn id(&self) -> &str {
        &self.id
    }

    #[must_use]
    pub const fn objective_type(&self) -> MapObjectiveType {
        self.objective_type
    }

    #[must_use]
    pub const fn coordinate(&self) -> HexCoord {
        self.coordinate
    }

    #[must_use]
    pub const fn required_hold_turns(&self) -> u32 {
        self.required_hold_turns
    }

    #[must_use]
    pub const fn victory_points(&self) -> u32 {
        self.victory_points
    }

    #[must_use]
    pub const fn gold_per_turn(&self) -> u32 {
        self.gold_per_turn
    }
}

#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MapDefinition {
    map_id: Box<str>,
    grid_layout: GridLayout,
    cols: u16,
    rows: u16,
    bounds: HexGridBounds,
    tiles: Box<[TileDefinition]>,
    objectives: Box<[MapObjective]>,
}

#[allow(missing_docs)]
impl MapDefinition {
    /// Constructs a complete validated logical map.
    ///
    /// # Errors
    ///
    /// Returns [`MapValidationError`] for invalid dimensions, identifiers,
    /// tile coverage, objective identifiers, positions, or occupancy.
    pub fn try_new(
        map_id: impl Into<Box<str>>,
        grid_layout: GridLayout,
        cols: u16,
        rows: u16,
        mut tiles: Vec<TileDefinition>,
        mut objectives: Vec<MapObjective>,
    ) -> Result<Self, MapValidationError> {
        let map_id = map_id.into();
        validate_content_id("$.mapName", &map_id)?;
        validate_dimension("$.cols", cols, MIN_MAP_COLS, MAX_MAP_COLS)?;
        validate_dimension("$.rows", rows, MIN_MAP_ROWS, MAX_MAP_ROWS)?;
        let bounds = HexGridBounds::new(cols, rows).ok_or_else(|| {
            MapValidationError::new("$", "validated map dimensions must be non-zero")
        })?;
        validate_tiles(&mut tiles, cols, rows)?;
        validate_objectives(&mut objectives, cols, rows)?;
        Ok(Self {
            map_id,
            grid_layout,
            cols,
            rows,
            bounds,
            tiles: tiles.into_boxed_slice(),
            objectives: objectives.into_boxed_slice(),
        })
    }

    #[must_use]
    pub fn map_id(&self) -> &str {
        &self.map_id
    }

    #[must_use]
    pub const fn grid_layout(&self) -> GridLayout {
        self.grid_layout
    }

    #[must_use]
    pub const fn cols(&self) -> u16 {
        self.cols
    }

    #[must_use]
    pub const fn rows(&self) -> u16 {
        self.rows
    }

    #[must_use]
    pub fn tiles(&self) -> &[TileDefinition] {
        &self.tiles
    }

    #[must_use]
    pub fn objectives(&self) -> &[MapObjective] {
        &self.objectives
    }

    /// Returns the non-empty rectangular bounds validated for this map.
    #[must_use]
    pub const fn bounds(&self) -> HexGridBounds {
        self.bounds
    }

    /// Returns the row-major tile index for an in-bounds coordinate.
    #[must_use]
    pub fn tile_index(&self, coordinate: HexCoord) -> Option<HexTileIndex> {
        self.bounds().index_of(coordinate)
    }

    /// Returns the coordinate at a row-major tile index.
    #[must_use]
    pub fn coordinate_at(&self, index: HexTileIndex) -> Option<HexCoord> {
        self.bounds().coordinate_at(index)
    }

    /// Iterates in-bounds adjacent coordinates in canonical odd-q order.
    pub fn neighbors(&self, coordinate: HexCoord) -> impl Iterator<Item = HexCoord> {
        self.bounds().neighbors(coordinate)
    }

    #[must_use]
    pub fn tile_at(&self, coordinate: HexCoord) -> Option<&TileDefinition> {
        let index = self.tile_index(coordinate)?;
        self.tiles
            .get(index.get())
            .filter(|tile| tile.coordinate == coordinate)
    }

    /// Returns a new validated aggregate with exactly one tile replaced.
    ///
    /// # Errors
    ///
    /// Returns [`MapValidationError`] when the replacement coordinate is
    /// outside this map or the rebuilt aggregate violates an invariant.
    pub fn replacing_tile(&self, replacement: TileDefinition) -> Result<Self, MapValidationError> {
        let coordinate = replacement.coordinate();
        let index = self.tile_index(coordinate).ok_or_else(|| {
            MapValidationError::new(
                "$.tile",
                format!(
                    "coordinate ({}, {}) is outside map bounds",
                    coordinate.col(),
                    coordinate.row()
                ),
            )
        })?;
        let mut tiles = self.tiles.to_vec();
        tiles[index.get()] = replacement;
        Self::try_new(
            self.map_id.clone(),
            self.grid_layout,
            self.cols,
            self.rows,
            tiles,
            self.objectives.to_vec(),
        )
    }
}

fn validate_tiles(
    tiles: &mut [TileDefinition],
    cols: u16,
    rows: u16,
) -> Result<(), MapValidationError> {
    let expected_count = usize::from(cols) * usize::from(rows);
    if tiles.len() != expected_count {
        return Err(MapValidationError::new(
            "$.tiles",
            format!(
                "must contain exactly {expected_count} tiles for a {cols}x{rows} map; found {}",
                tiles.len()
            ),
        ));
    }
    tiles.sort_unstable_by_key(|tile| (tile.coordinate.row(), tile.coordinate.col()));
    for (index, tile) in tiles.iter().enumerate() {
        let expected = HexCoord::new(
            i32::try_from(index % usize::from(cols)).expect("map width fits i32"),
            i32::try_from(index / usize::from(cols)).expect("map height fits i32"),
        );
        if tile.coordinate != expected {
            return Err(MapValidationError::new(
                "$.tiles",
                format!(
                    "tile coverage is incomplete or duplicated; expected ({}, {})",
                    expected.col(),
                    expected.row()
                ),
            ));
        }
    }
    Ok(())
}

fn validate_objectives(
    objectives: &mut [MapObjective],
    cols: u16,
    rows: u16,
) -> Result<(), MapValidationError> {
    objectives.sort_unstable_by(|left, right| left.id.cmp(&right.id));
    if let Some(pair) = objectives.windows(2).find(|pair| pair[0].id == pair[1].id) {
        return Err(MapValidationError::new(
            "$.objectives",
            format!("duplicate objective id {:?}", pair[0].id),
        ));
    }
    let mut occupied = [0_u64; OBJECTIVE_OCCUPANCY_WORDS];
    for objective in objectives {
        let col = usize::try_from(objective.coordinate.col()).map_err(|_| {
            MapValidationError::new("$.objectives", "objective coordinate is outside map bounds")
        })?;
        let row = usize::try_from(objective.coordinate.row()).map_err(|_| {
            MapValidationError::new("$.objectives", "objective coordinate is outside map bounds")
        })?;
        if col >= usize::from(cols) || row >= usize::from(rows) {
            return Err(MapValidationError::new(
                "$.objectives",
                "objective coordinate is outside map bounds",
            ));
        }
        let index = row * usize::from(cols) + col;
        let bit = 1_u64 << (index % u64::BITS as usize);
        let word = &mut occupied[index / u64::BITS as usize];
        if *word & bit != 0 {
            return Err(MapValidationError::new(
                "$.objectives",
                "only one objective may occupy a tile",
            ));
        }
        *word |= bit;
    }
    Ok(())
}

fn validate_unique_values<Value: Copy>(
    path: &str,
    values: &[Value],
    rank: fn(Value) -> u8,
) -> Result<(), MapValidationError> {
    let mut seen = 0_u64;
    for value in values {
        let bit = 1_u64 << rank(*value);
        if seen & bit != 0 {
            return Err(MapValidationError::new(path, "must not contain duplicates"));
        }
        seen |= bit;
    }
    Ok(())
}

fn validate_dimension(
    path: &str,
    value: u16,
    minimum: u16,
    maximum: u16,
) -> Result<(), MapValidationError> {
    if (minimum..=maximum).contains(&value) {
        return Ok(());
    }
    Err(MapValidationError::new(
        path,
        format!("must be in range {minimum}..={maximum}"),
    ))
}
