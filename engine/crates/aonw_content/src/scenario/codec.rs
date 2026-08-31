use aonw_domain::{HexCoord, PlayerId, UnitId, UnitKind};
use serde::Deserialize;

use crate::{MapDefinition, RulesetDefinition};

use super::{MAX_SCENARIO_UNITS, ScenarioDefinition, ScenarioLoadError, ScenarioUnitDefinition};

const CURRENT_SCENARIO_SCHEMA_VERSION: u16 = 1;
const MAX_SCENARIO_JSON_BYTES: usize = 1024 * 1024;

#[derive(Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct RawScenario {
    schema_version: u16,
    scenario_id: String,
    map_id: String,
    ruleset_id: String,
    initial_units: Vec<RawScenarioUnit>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct RawScenarioUnit {
    id: String,
    owner_player_id: String,
    kind: String,
    name: String,
    col: i32,
    row: i32,
}

impl ScenarioDefinition {
    /// Decodes a strict current scenario and binds it to supplied content.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized, malformed, future, mismatched, or
    /// domain-invalid content.
    pub fn from_json(
        input: &[u8],
        map: &MapDefinition,
        ruleset: &RulesetDefinition,
    ) -> Result<Self, ScenarioLoadError> {
        if input.len() > MAX_SCENARIO_JSON_BYTES {
            return Err(ScenarioLoadError::TooLarge {
                actual: input.len(),
                maximum: MAX_SCENARIO_JSON_BYTES,
            });
        }
        let raw: RawScenario = serde_json::from_slice(input).map_err(ScenarioLoadError::Json)?;
        if raw.schema_version != CURRENT_SCENARIO_SCHEMA_VERSION {
            return Err(ScenarioLoadError::UnsupportedVersion(raw.schema_version));
        }
        if raw.map_id != map.map_id() {
            return Err(ScenarioLoadError::ContentMismatch("map"));
        }
        if raw.ruleset_id != ruleset.ruleset_id() {
            return Err(ScenarioLoadError::ContentMismatch("ruleset"));
        }
        if raw.initial_units.len() > MAX_SCENARIO_UNITS {
            return Err(ScenarioLoadError::TooManyUnits(raw.initial_units.len()));
        }
        let initial_units = raw
            .initial_units
            .into_iter()
            .enumerate()
            .map(|(index, unit)| decode_scenario_unit(index, unit))
            .collect::<Result<Vec<_>, _>>()?;
        Self::try_new(raw.scenario_id, map, ruleset, initial_units)
            .map_err(ScenarioLoadError::Validation)
    }
}

fn decode_scenario_unit(
    index: usize,
    raw: RawScenarioUnit,
) -> Result<ScenarioUnitDefinition, ScenarioLoadError> {
    let path = format!("$.initialUnits[{index}]");
    let id = UnitId::new(raw.id).map_err(|error| ScenarioLoadError::InvalidField {
        path: format!("{path}.id").into(),
        message: error.to_string().into(),
    })?;
    let owner =
        PlayerId::new(raw.owner_player_id).map_err(|error| ScenarioLoadError::InvalidField {
            path: format!("{path}.ownerPlayerId").into(),
            message: error.to_string().into(),
        })?;
    let kind = parse_unit_kind(&raw.kind).ok_or_else(|| ScenarioLoadError::InvalidField {
        path: format!("{path}.kind").into(),
        message: format!("unknown unit kind: {}", raw.kind).into(),
    })?;
    Ok(ScenarioUnitDefinition::new(
        id,
        owner,
        kind,
        raw.name,
        HexCoord::new(raw.col, raw.row),
    ))
}

const fn parse_unit_kind(value: &str) -> Option<UnitKind> {
    match value.as_bytes() {
        b"commander" => Some(UnitKind::Commander),
        b"warrior" => Some(UnitKind::Warrior),
        b"archer" => Some(UnitKind::Archer),
        b"settler" => Some(UnitKind::Settler),
        b"worker" => Some(UnitKind::Worker),
        b"merchant" => Some(UnitKind::Merchant),
        b"scout" => Some(UnitKind::Scout),
        b"spearman" => Some(UnitKind::Spearman),
        b"cavalry" => Some(UnitKind::Cavalry),
        b"catapult" => Some(UnitKind::Catapult),
        b"heavyInfantry" => Some(UnitKind::HeavyInfantry),
        b"fieldCannon" => Some(UnitKind::FieldCannon),
        b"rifleman" => Some(UnitKind::Rifleman),
        b"tank" => Some(UnitKind::Tank),
        b"scoutShip" => Some(UnitKind::ScoutShip),
        b"warship" => Some(UnitKind::Warship),
        b"reconPlane" => Some(UnitKind::ReconPlane),
        _ => None,
    }
}
