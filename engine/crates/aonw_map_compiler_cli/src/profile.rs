//! Filesystem adapter for a standard terrain-authoring profile.

use std::env;
use std::error::Error;
use std::fs;
use std::io;
use std::path::PathBuf;

use aonw_content::MapDocument;
use aonw_map_authoring::TerrainAuthoringProfile;

const DEFAULT_HEX_RADIUS_METERS: f64 = 10.0;
const DEFAULT_MAX_TERRAIN_HEIGHT_METERS: f64 = 20.0;

fn main() {
    if let Err(error) = run() {
        eprintln!("terrain profile generation failed: {error}");
        std::process::exit(1);
    }
}

fn run() -> Result<(), Box<dyn Error>> {
    let arguments = Arguments::parse()?;
    let map_source = fs::read(&arguments.map_path)?;
    let map = MapDocument::from_json(&map_source)?;
    let profile = TerrainAuthoringProfile::standard(
        map.map(),
        arguments.hex_radius_meters,
        arguments.max_terrain_height_meters,
    )?;
    if let Some(parent) = arguments.output_path.parent() {
        fs::create_dir_all(parent)?;
    }
    fs::write(arguments.output_path, profile.to_versioned_json()?)?;
    Ok(())
}

struct Arguments {
    map_path: PathBuf,
    output_path: PathBuf,
    hex_radius_meters: f64,
    max_terrain_height_meters: f64,
}

impl Arguments {
    fn parse() -> Result<Self, io::Error> {
        let mut values = env::args_os().skip(1);
        let map_path = required_argument(&mut values, "map.json")?;
        let output_path = required_argument(&mut values, "output profile")?;
        let hex_radius_meters = values
            .next()
            .map(|value| {
                value
                    .to_str()
                    .ok_or_else(|| invalid_input("hex radius must be UTF-8"))?
                    .parse::<f64>()
                    .map_err(|error| invalid_input(format!("invalid hex radius: {error}")))
            })
            .transpose()?
            .unwrap_or(DEFAULT_HEX_RADIUS_METERS);
        let max_terrain_height_meters = values
            .next()
            .map(|value| {
                value
                    .to_str()
                    .ok_or_else(|| invalid_input("maximum terrain height must be UTF-8"))?
                    .parse::<f64>()
                    .map_err(|error| {
                        invalid_input(format!("invalid maximum terrain height: {error}"))
                    })
            })
            .transpose()?
            .unwrap_or(DEFAULT_MAX_TERRAIN_HEIGHT_METERS);
        if values.next().is_some() {
            return Err(invalid_input(
                "usage: aonw-map-profile <map.json> <output-profile> [hex-radius-meters] [max-terrain-height-meters]",
            ));
        }
        Ok(Self {
            map_path,
            output_path,
            hex_radius_meters,
            max_terrain_height_meters,
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
