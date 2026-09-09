use aonw_content::TerrainType;

pub(crate) const fn can_found_on_terrain(terrain: TerrainType) -> bool {
    !matches!(
        terrain,
        TerrainType::Ocean | TerrainType::Lake | TerrainType::Mountain | TerrainType::River
    )
}
