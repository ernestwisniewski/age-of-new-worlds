//! Thin filesystem and image-format adapter for the pure terrain compiler.

use std::env;
use std::error::Error;
use std::fs::{self, File};
use std::io::{self, BufWriter, Write};
use std::path::{Path, PathBuf};

use aonw_content::MapDocument;
use aonw_map_authoring::TerrainAuthoringProfile;
use aonw_map_compiler::{CompiledTerrain, HeightRaster, RasterConfig, RasterHash, compile_terrain};
use exr::prelude::write_rgb_file;
use serde_json::{Value, json};
use sha2::{Digest, Sha256};

fn main() {
    if let Err(error) = run() {
        eprintln!("terrain compilation failed: {error}");
        std::process::exit(1);
    }
}

fn run() -> Result<(), Box<dyn Error>> {
    let arguments = Arguments::parse()?;
    let map_source = fs::read(&arguments.map_path)?;
    let map = MapDocument::from_json(&map_source)?;
    let profile_source = fs::read(&arguments.profile_path)?;
    let profile = TerrainAuthoringProfile::from_json(&profile_source, map.map())?;
    let config = RasterConfig::try_new(arguments.samples_per_hex)?;
    let terrain = compile_terrain(&profile, config)?;

    fs::create_dir_all(&arguments.output_directory)?;
    let layers = [
        (
            "base",
            terrain.base(),
            terrain.metadata().base_raster_hash(),
        ),
        ("min", terrain.min(), terrain.metadata().min_raster_hash()),
        ("max", terrain.max(), terrain.metadata().max_raster_hash()),
    ];
    let mut layer_manifest = serde_json::Map::new();
    for (name, raster, hash) in layers {
        layer_manifest.insert(
            name.to_owned(),
            write_layer(&arguments.output_directory, name, raster, hash)?,
        );
    }
    let layers = Value::Object(layer_manifest);
    write_manifest(
        &arguments.output_directory,
        map.map().map_id(),
        &profile,
        &terrain,
        config,
        &layers,
    )?;
    Ok(())
}

struct Arguments {
    map_path: PathBuf,
    profile_path: PathBuf,
    output_directory: PathBuf,
    samples_per_hex: u16,
}

impl Arguments {
    fn parse() -> Result<Self, io::Error> {
        let mut values = env::args_os().skip(1);
        let map_path = required_argument(&mut values, "map.json")?;
        let profile_path = required_argument(&mut values, "terrain_authoring.json")?;
        let output_directory = required_argument(&mut values, "output directory")?;
        let samples_per_hex = values
            .next()
            .map(|value| {
                value
                    .to_str()
                    .ok_or_else(|| invalid_input("samples-per-hex must be UTF-8"))?
                    .parse::<u16>()
                    .map_err(|error| invalid_input(format!("invalid samples-per-hex: {error}")))
            })
            .transpose()?
            .unwrap_or(8);
        if values.next().is_some() {
            return Err(invalid_input(
                "usage: aonw-map-compiler <map.json> <terrain_authoring.json> <output-dir> [samples-per-hex]",
            ));
        }
        Ok(Self {
            map_path,
            profile_path,
            output_directory,
            samples_per_hex,
        })
    }
}

fn required_argument(
    values: &mut impl Iterator<Item = std::ffi::OsString>,
    name: &str,
) -> Result<PathBuf, io::Error> {
    values
        .next()
        .map(PathBuf::from)
        .ok_or_else(|| invalid_input(format!("missing {name}")))
}

fn invalid_input(message: impl Into<String>) -> io::Error {
    io::Error::new(io::ErrorKind::InvalidInput, message.into())
}

fn write_layer(
    output_directory: &Path,
    name: &str,
    raster: &HeightRaster,
    hash: RasterHash,
) -> Result<Value, Box<dyn Error>> {
    let exr_name = format!("{name}.exr");
    let r16_name = format!("{name}.r16");
    let exr_path = output_directory.join(&exr_name);
    let width = usize::try_from(raster.width()).expect("bounded width fits usize");
    let height = usize::try_from(raster.height()).expect("bounded height fits usize");
    write_rgb_file(exr_path, width, height, |x, y| {
        let value = raster.values()[y * width + x];
        (value, value, value)
    })?;
    let range = write_r16(&output_directory.join(&r16_name), raster.values())?;
    let exr_sha256 = file_sha256(&output_directory.join(&exr_name))?;
    let r16_sha256 = file_sha256(&output_directory.join(&r16_name))?;
    Ok(json!({
        "hash": hash.to_string(),
        "openExr": exr_name,
        "openExrSha256": exr_sha256,
        "rawR16": r16_name,
        "rawR16Sha256": r16_sha256,
        "r16RangeMeters": {"min": range.minimum, "max": range.maximum}
    }))
}

fn file_sha256(path: &Path) -> Result<String, io::Error> {
    let digest = Sha256::digest(fs::read(path)?);
    Ok(format!("{digest:x}"))
}

#[derive(Clone, Copy)]
struct EncodingRange {
    minimum: f32,
    maximum: f32,
}

fn write_r16(path: &Path, values: &[f32]) -> Result<EncodingRange, io::Error> {
    let actual_minimum = values.iter().copied().fold(f32::INFINITY, f32::min);
    let actual_maximum = values.iter().copied().fold(f32::NEG_INFINITY, f32::max);
    let range = non_empty_range(actual_minimum, actual_maximum);
    let span = f64::from(range.maximum) - f64::from(range.minimum);
    let mut output = BufWriter::new(File::create(path)?);
    for value in values {
        let normalized = ((f64::from(*value) - f64::from(range.minimum)) / span).clamp(0.0, 1.0);
        let encoded = normalized.mul_add(f64::from(u16::MAX), 0.0).round();
        #[expect(
            clippy::cast_possible_truncation,
            clippy::cast_sign_loss,
            reason = "the normalized and clamped R16 value is within u16 bounds"
        )]
        output.write_all(&(encoded as u16).to_le_bytes())?;
    }
    output.flush()?;
    Ok(range)
}

fn non_empty_range(minimum: f32, maximum: f32) -> EncodingRange {
    if minimum < maximum {
        return EncodingRange { minimum, maximum };
    }
    if maximum < f32::MAX {
        return EncodingRange {
            minimum,
            maximum: next_up(maximum),
        };
    }
    EncodingRange {
        minimum: next_down(minimum),
        maximum,
    }
}

fn next_up(value: f32) -> f32 {
    if value.to_bits() == (-0.0_f32).to_bits() {
        return f32::from_bits(1);
    }
    if value >= 0.0 {
        f32::from_bits(value.to_bits() + 1)
    } else {
        f32::from_bits(value.to_bits() - 1)
    }
}

fn next_down(value: f32) -> f32 {
    if value.to_bits() == 0.0_f32.to_bits() {
        return -f32::from_bits(1);
    }
    if value > 0.0 {
        f32::from_bits(value.to_bits() - 1)
    } else {
        f32::from_bits(value.to_bits() + 1)
    }
}

fn write_manifest(
    output_directory: &Path,
    map_id: &str,
    profile: &TerrainAuthoringProfile,
    terrain: &CompiledTerrain,
    config: RasterConfig,
    layers: &Value,
) -> Result<(), Box<dyn Error>> {
    let metadata = terrain.metadata();
    let manifest = json!({
        "mapId": map_id,
        "generatorVersion": metadata.generator_version(),
        "mapContentHash": metadata.map_content_hash().to_string(),
        "authoringProfileHash": metadata.authoring_profile_hash().to_string(),
        "generatedBaseHash": metadata.base_raster_hash().to_string(),
        "authoring": {
            "cols": profile.cols(),
            "rows": profile.rows(),
            "hexRadiusMeters": profile.hex_radius_meters(),
            "maxTerrainHeightMeters": profile.max_terrain_height_meters(),
            "worldOriginMeters": vector_json(profile.world_origin_meters()),
            "referenceTransform": {
                "translationMeters": vector_json(
                    profile.reference_transform().translation_meters()
                ),
                "rotationDegrees": vector_json(
                    profile.reference_transform().rotation_degrees()
                ),
                "scale": vector_json(profile.reference_transform().scale())
            },
            "edgeBlendMeters": profile.edge_blend_meters(),
            "cityCoreRadiusMeters": profile.city_core_radius_meters(),
            "maxCitySlope": profile.max_city_slope()
        },
        "raster": {
            "width": terrain.base().width(),
            "height": terrain.base().height(),
            "samplesPerHex": config.samples_per_hex(),
            "sampleSpacingMeters": terrain.base().sample_spacing_meters(),
            "worldMinMeters": {
                "x": terrain.base().world_min_x_meters(),
                "z": terrain.base().world_min_z_meters()
            }
        },
        "layers": layers
    });
    let mut bytes = serde_json::to_vec_pretty(&manifest)?;
    bytes.push(b'\n');
    fs::write(output_directory.join("terrain_compile.json"), bytes)?;
    Ok(())
}

fn vector_json(value: aonw_map_authoring::AuthoringVector3) -> Value {
    json!({"x": value.x(), "y": value.y(), "z": value.z()})
}

#[cfg(test)]
mod tests {
    use super::non_empty_range;

    #[test]
    fn constant_r16_ranges_remain_decodable() {
        for value in [-0.0, 0.0, 4.0, -4.0, f32::MAX] {
            let range = non_empty_range(value, value);
            assert!(range.minimum < range.maximum);
            assert!(value >= range.minimum);
            assert!(value <= range.maximum);
        }

        let signed_zero = non_empty_range(-0.0, 0.0);
        assert!(signed_zero.minimum < signed_zero.maximum);
    }
}
