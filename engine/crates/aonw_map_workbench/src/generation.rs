use core::fmt::Write as _;

use aonw_content::{
    GridLayout, MapDefinition, MapDocument, ResourceType, TerrainProfile, TerrainType,
    TileDefinition,
};
use aonw_domain::HexCoord;
use aonw_map_authoring::TerrainAuthoringProfile;
use serde::Serialize;
use sha2::{Digest, Sha256};

use crate::spec::{PersistedGenerationSpec, pretty_json};
use crate::{MapGenerationSpec, MapWorkbenchError};

const SQRT_3: f64 = 1.732_050_807_568_877_2;

/// Complete deterministic document package returned to a persistence adapter.
#[derive(Clone, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct GeneratedMapPackage {
    map_document: String,
    terrain_authoring_document: String,
    generation_document: String,
    generated_decoration_plan_document: String,
    map_content_hash: String,
    authoring_profile_hash: String,
    generation_spec_hash: String,
    generated_decoration_plan_hash: String,
}

#[allow(missing_docs)]
impl GeneratedMapPackage {
    /// Generates a canonical logical map and its authoring artifacts.
    ///
    /// # Errors
    ///
    /// Returns [`MapWorkbenchError`] if any generated aggregate or document
    /// violates its authoritative Rust model.
    pub fn generate(spec: &MapGenerationSpec) -> Result<Self, MapWorkbenchError> {
        let map_document = logical_map(spec)?;
        let map = map_document.map();
        let terrain_profile = TerrainAuthoringProfile::standard(
            map,
            spec.hex_radius_meters(),
            spec.max_terrain_height_meters(),
        )?;
        let map_content_hash = map.content_hash()?.to_string();
        let authoring_profile_hash = terrain_profile.authoring_profile_hash()?.to_string();
        let generation_spec_hash = spec.spec_hash()?.to_string();
        let decoration_plan = GeneratedDecorationPlan {
            source_map_content_hash: &map_content_hash,
            generation_spec_hash: &generation_spec_hash,
            generator_id: spec.generator_id(),
            generator_version: spec.generator_version(),
            seed: spec.seed().to_string(),
            placements: generated_decorations(spec, map),
        };
        let decoration_bytes = serde_json::to_vec(&decoration_plan)?;
        let generated_decoration_plan_hash = sha256_hex(&decoration_bytes);
        let generation_document = pretty_json(&GenerationProvenance {
            spec: PersistedGenerationSpec::from(spec),
            generation_spec_hash: &generation_spec_hash,
            map_content_hash: &map_content_hash,
            authoring_profile_hash: &authoring_profile_hash,
            generated_decoration_plan_hash: &generated_decoration_plan_hash,
        })?;
        Ok(Self {
            map_document: map_document.to_versioned_json()?,
            terrain_authoring_document: terrain_profile.to_versioned_json()?,
            generation_document,
            generated_decoration_plan_document: pretty_json(&decoration_plan)?,
            map_content_hash,
            authoring_profile_hash,
            generation_spec_hash,
            generated_decoration_plan_hash,
        })
    }

    #[must_use]
    pub fn map_document(&self) -> &str {
        &self.map_document
    }

    #[must_use]
    pub fn terrain_authoring_document(&self) -> &str {
        &self.terrain_authoring_document
    }

    #[must_use]
    pub fn generation_document(&self) -> &str {
        &self.generation_document
    }

    #[must_use]
    pub fn generated_decoration_plan_document(&self) -> &str {
        &self.generated_decoration_plan_document
    }

    #[must_use]
    pub fn map_content_hash(&self) -> &str {
        &self.map_content_hash
    }

    #[must_use]
    pub fn authoring_profile_hash(&self) -> &str {
        &self.authoring_profile_hash
    }

    #[must_use]
    pub fn generation_spec_hash(&self) -> &str {
        &self.generation_spec_hash
    }

    #[must_use]
    pub fn generated_decoration_plan_hash(&self) -> &str {
        &self.generated_decoration_plan_hash
    }
}

fn logical_map(spec: &MapGenerationSpec) -> Result<MapDocument, MapWorkbenchError> {
    let mut tiles = Vec::with_capacity(usize::from(spec.cols()) * usize::from(spec.rows()));
    for row in 0..spec.rows() {
        for col in 0..spec.cols() {
            let cell = generated_cell(spec, col, row);
            tiles.push(TileDefinition::try_new(
                HexCoord::new(i32::from(col), i32::from(row)),
                TerrainProfile::try_new(vec![cell.terrain])?,
                cell.resources,
                cell.height,
            )?);
        }
    }
    let map = MapDefinition::try_new(
        spec.map_id(),
        GridLayout::OddQFlatTop,
        spec.cols(),
        spec.rows(),
        tiles,
        Vec::new(),
    )?;
    Ok(MapDocument::try_new(map, spec.default_zoom())?)
}

struct GeneratedCell {
    terrain: TerrainType,
    resources: Vec<ResourceType>,
    height: u8,
}

fn generated_cell(spec: &MapGenerationSpec, col: u16, row: u16) -> GeneratedCell {
    if spec.generator_id() == crate::BLANK_GENERATOR_ID {
        return GeneratedCell {
            terrain: TerrainType::Grassland,
            resources: Vec::new(),
            height: 0,
        };
    }

    let elevation_noise = fractal_noise(spec.seed(), col, row, 0x65_6c_65_76);
    let radial = radial_distance(col, row, spec.cols(), spec.rows());
    let elevation_score = i32::try_from(elevation_noise).expect("noise fits i32") + 320
        - i32::try_from(radial * 3 / 4).expect("radial distance fits i32");
    let (terrain, height) = classify_terrain(spec, col, row, elevation_score);
    GeneratedCell {
        terrain,
        resources: generated_resources(spec.seed(), col, row, terrain),
        height,
    }
}

fn classify_terrain(
    spec: &MapGenerationSpec,
    col: u16,
    row: u16,
    elevation_score: i32,
) -> (TerrainType, u8) {
    if elevation_score < 500 {
        return (TerrainType::Ocean, 0);
    }
    if elevation_score < 575 {
        return (TerrainType::Coast, 0);
    }

    let height = u8::try_from(((elevation_score - 500) / 135 + 1).clamp(1, 5))
        .expect("clamped logical height fits u8");
    let moisture = fractal_noise(spec.seed(), col, row, 0x6d_6f_69_73);
    let climate_noise = fractal_noise(spec.seed(), col, row, 0x74_65_6d_70);
    let latitude = axis_distance(row, spec.rows());
    let temperature = 1_000_i32 - i32::try_from(latitude * 4 / 5).expect("latitude fits i32")
        + i32::try_from(climate_noise / 5).expect("noise fits i32")
        - 100;
    let ruggedness = lattice_value(spec.seed(), u64::from(col), u64::from(row), 0x72_75_67_67);

    let terrain = if height >= 4 {
        TerrainType::Mountain
    } else if temperature < 240 {
        TerrainType::Snow
    } else if temperature < 360 {
        TerrainType::Tundra
    } else if height >= 3 && ruggedness > 480 {
        TerrainType::Hills
    } else if moisture < 240 {
        TerrainType::Desert
    } else if height == 1 && moisture > 820 {
        TerrainType::Wetlands
    } else if moisture > 760 && temperature > 680 {
        TerrainType::Jungle
    } else if moisture > 650 {
        TerrainType::Forest
    } else if moisture < 430 {
        TerrainType::Plains
    } else {
        TerrainType::Grassland
    };
    (terrain, height)
}

fn generated_resources(seed: u64, col: u16, row: u16, terrain: TerrainType) -> Vec<ResourceType> {
    let value = mixed(seed, u64::from(col), u64::from(row), 0x72_65_73_6f);
    let chance = if matches!(terrain, TerrainType::Ocean | TerrainType::Coast) {
        22
    } else {
        15
    };
    if value % 100 >= chance {
        return Vec::new();
    }
    let resource = match terrain {
        TerrainType::Ocean | TerrainType::Lake => ResourceType::Fish,
        TerrainType::Coast => [ResourceType::Fish, ResourceType::Pearls][(value >> 8) as usize % 2],
        TerrainType::Mountain => [
            ResourceType::Iron,
            ResourceType::Coal,
            ResourceType::Gold,
            ResourceType::Marble,
        ][(value >> 8) as usize % 4],
        TerrainType::Hills => [
            ResourceType::Sheep,
            ResourceType::Iron,
            ResourceType::Horses,
        ][(value >> 8) as usize % 3],
        TerrainType::Forest => {
            [ResourceType::Deer, ResourceType::Apple, ResourceType::Silk][(value >> 8) as usize % 3]
        }
        TerrainType::Jungle => [
            ResourceType::Spices,
            ResourceType::Banana,
            ResourceType::Cocoa,
        ][(value >> 8) as usize % 3],
        TerrainType::Desert => {
            [ResourceType::Oil, ResourceType::Uranium][(value >> 8) as usize % 2]
        }
        TerrainType::Wetlands => {
            [ResourceType::Rice, ResourceType::Sugar][(value >> 8) as usize % 2]
        }
        TerrainType::Tundra | TerrainType::Snow => {
            [ResourceType::Silver, ResourceType::Deer][(value >> 8) as usize % 2]
        }
        TerrainType::Plains | TerrainType::Grassland => [
            ResourceType::Wheat,
            ResourceType::Cow,
            ResourceType::Horses,
            ResourceType::Grapes,
        ][(value >> 8) as usize % 4],
        TerrainType::River => ResourceType::Rice,
    };
    vec![resource]
}

fn generated_decorations(
    spec: &MapGenerationSpec,
    map: &MapDefinition,
) -> Vec<GeneratedDecorationPlacement> {
    if spec.generator_id() == crate::BLANK_GENERATOR_ID {
        return Vec::new();
    }
    let mut placements = Vec::new();
    for tile in map.tiles() {
        let coordinate = tile.coordinate();
        let col = u16::try_from(coordinate.col()).expect("generated col is non-negative");
        let row = u16::try_from(coordinate.row()).expect("generated row is non-negative");
        let terrain = tile.display_terrain();
        let selector = mixed(spec.seed(), u64::from(col), u64::from(row), 0x64_65_63_6f);
        let (kind, count) = match terrain {
            TerrainType::Forest | TerrainType::Jungle => ("tree", 3),
            TerrainType::Mountain | TerrainType::Hills => ("rock", 2),
            TerrainType::Ocean | TerrainType::Coast | TerrainType::Lake
                if selector.is_multiple_of(3) =>
            {
                ("water", 1)
            }
            TerrainType::Grassland
            | TerrainType::Plains
            | TerrainType::Desert
            | TerrainType::Tundra
            | TerrainType::Snow
            | TerrainType::Wetlands
                if selector.is_multiple_of(4) =>
            {
                ("detail", 1)
            }
            _ => continue,
        };
        for index in 0..count {
            placements.push(decoration_placement(spec, tile, kind, index));
        }
    }
    placements
}

fn decoration_placement(
    spec: &MapGenerationSpec,
    tile: &TileDefinition,
    kind: &str,
    index: u8,
) -> GeneratedDecorationPlacement {
    let coordinate = tile.coordinate();
    let col = u16::try_from(coordinate.col()).expect("generated col is non-negative");
    let row = u16::try_from(coordinate.row()).expect("generated row is non-negative");
    let value = mixed(
        spec.seed(),
        u64::from(col),
        u64::from(row),
        0x70_6c_61_63_u64.wrapping_add(u64::from(index)),
    );
    let radius = spec.hex_radius_meters();
    let center_x = f64::from(col) * radius * 1.5;
    let center_z = (f64::from(row) + if col & 1 == 0 { 0.0 } else { 0.5 }) * radius * SQRT_3;
    let offset_x = signed_unit(value) * radius * 0.38;
    let offset_z = signed_unit(value.rotate_left(21)) * radius * 0.38;
    GeneratedDecorationPlacement {
        placement_id: format!("{kind}_{col}_{row}_{index}"),
        kind: kind.to_owned(),
        source_col: i32::from(col),
        source_row: i32::from(row),
        x_meters: center_x + offset_x,
        y_meters: f64::from(tile.height()) / 5.0 * spec.max_terrain_height_meters(),
        z_meters: center_z + offset_z,
        rotation_degrees_y: f64::from(
            u16::try_from(value.rotate_left(37) % 3_600).expect("rotation fits u16"),
        ) / 10.0,
        scale: 0.75
            + f64::from(u16::try_from(value.rotate_left(49) % 501).expect("scale fits u16"))
                / 1_000.0,
    }
}

fn signed_unit(value: u64) -> f64 {
    f64::from(u16::try_from(value % 2_001).expect("signed unit fits u16")) / 1_000.0 - 1.0
}

fn radial_distance(col: u16, row: u16, cols: u16, rows: u16) -> u32 {
    let x = axis_distance(col, cols);
    let y = axis_distance(row, rows);
    (x * x + y * y) / 2_000
}

fn axis_distance(position: u16, length: u16) -> u32 {
    if length <= 1 {
        return 0;
    }
    let doubled_position = i32::from(position) * 2;
    let extent = i32::from(length) - 1;
    (doubled_position - extent).unsigned_abs() * 1_000
        / u32::try_from(extent).expect("positive extent fits u32")
}

fn fractal_noise(seed: u64, col: u16, row: u16, salt: u64) -> u32 {
    (value_noise(seed, col, row, 8, salt) * 4
        + value_noise(seed, col, row, 4, salt.rotate_left(17)) * 2
        + value_noise(seed, col, row, 2, salt.rotate_left(33)))
        / 7
}

fn value_noise(seed: u64, col: u16, row: u16, cell_size: u16, salt: u64) -> u32 {
    let x0 = col / cell_size;
    let y0 = row / cell_size;
    let x_fraction = u32::from(col % cell_size);
    let y_fraction = u32::from(row % cell_size);
    let divisor = u32::from(cell_size);
    let top = interpolate(
        lattice_value(seed, u64::from(x0), u64::from(y0), salt),
        lattice_value(seed, u64::from(x0 + 1), u64::from(y0), salt),
        x_fraction,
        divisor,
    );
    let bottom = interpolate(
        lattice_value(seed, u64::from(x0), u64::from(y0 + 1), salt),
        lattice_value(seed, u64::from(x0 + 1), u64::from(y0 + 1), salt),
        x_fraction,
        divisor,
    );
    interpolate(top, bottom, y_fraction, divisor)
}

fn interpolate(first: u32, second: u32, numerator: u32, denominator: u32) -> u32 {
    (first * (denominator - numerator) + second * numerator) / denominator
}

fn lattice_value(seed: u64, col: u64, row: u64, salt: u64) -> u32 {
    u32::try_from(mixed(seed, col, row, salt) % 1_024).expect("noise fits u32")
}

fn mixed(seed: u64, col: u64, row: u64, salt: u64) -> u64 {
    let mut value = seed
        ^ salt
        ^ col.wrapping_mul(0x9e37_79b9_7f4a_7c15)
        ^ row.wrapping_mul(0xbf58_476d_1ce4_e5b9);
    value = (value ^ (value >> 30)).wrapping_mul(0xbf58_476d_1ce4_e5b9);
    value = (value ^ (value >> 27)).wrapping_mul(0x94d0_49bb_1331_11eb);
    value ^ (value >> 31)
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct GenerationProvenance<'a> {
    spec: PersistedGenerationSpec<'a>,
    generation_spec_hash: &'a str,
    map_content_hash: &'a str,
    authoring_profile_hash: &'a str,
    generated_decoration_plan_hash: &'a str,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct GeneratedDecorationPlan<'a> {
    source_map_content_hash: &'a str,
    generation_spec_hash: &'a str,
    generator_id: &'a str,
    generator_version: u16,
    seed: String,
    placements: Vec<GeneratedDecorationPlacement>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct GeneratedDecorationPlacement {
    placement_id: String,
    kind: String,
    source_col: i32,
    source_row: i32,
    x_meters: f64,
    y_meters: f64,
    z_meters: f64,
    rotation_degrees_y: f64,
    scale: f64,
}

fn sha256_hex(bytes: &[u8]) -> String {
    let mut output = String::with_capacity(64);
    for byte in Sha256::digest(bytes) {
        write!(&mut output, "{byte:02x}").expect("writing to String cannot fail");
    }
    output
}
