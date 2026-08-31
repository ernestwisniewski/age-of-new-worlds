use std::io::{self, Write};

use aonw_domain::UnitKind;
use serde::ser::{SerializeSeq, SerializeStruct};
use serde::{Serialize, Serializer};
use sha2::{Digest, Sha256};

use crate::ContentHash;

use super::{ScenarioDefinition, ScenarioUnitDefinition};

impl ScenarioDefinition {
    /// Computes SHA-256 over stable canonical scenario bytes.
    ///
    /// # Errors
    ///
    /// Returns an error when canonical serialization fails.
    pub fn content_hash(&self) -> Result<ContentHash, serde_json::Error> {
        let mut writer = HashWriter(Sha256::new());
        serde_json::to_writer(&mut writer, &CanonicalScenario(self))?;
        Ok(ContentHash(writer.0.finalize().into()))
    }
}

struct CanonicalScenario<'a>(&'a ScenarioDefinition);
impl Serialize for CanonicalScenario<'_> {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        let scenario = self.0;
        let mut value = serializer.serialize_struct("CanonicalScenario", 7)?;
        value.serialize_field("schemaVersion", &scenario.schema_version)?;
        value.serialize_field("scenarioId", &scenario.scenario_id)?;
        value.serialize_field("mapId", &scenario.map_id)?;
        value.serialize_field("mapHash", scenario.map_hash.as_bytes())?;
        value.serialize_field("rulesetId", &scenario.ruleset_id)?;
        value.serialize_field("rulesetHash", scenario.ruleset_hash.as_bytes())?;
        value.serialize_field("initialUnits", &CanonicalUnits(&scenario.initial_units))?;
        value.end()
    }
}

struct CanonicalUnits<'a>(&'a [ScenarioUnitDefinition]);
impl Serialize for CanonicalUnits<'_> {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        let mut sequence = serializer.serialize_seq(Some(self.0.len()))?;
        for unit in self.0 {
            sequence.serialize_element(&CanonicalUnit(unit))?;
        }
        sequence.end()
    }
}

struct CanonicalUnit<'a>(&'a ScenarioUnitDefinition);
impl Serialize for CanonicalUnit<'_> {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        let unit = self.0;
        let mut value = serializer.serialize_struct("CanonicalScenarioUnit", 6)?;
        value.serialize_field("id", unit.id().as_str())?;
        value.serialize_field("ownerPlayerId", unit.owner_player_id().as_str())?;
        value.serialize_field("kind", unit_kind_name(unit.kind()))?;
        value.serialize_field("name", unit.name())?;
        value.serialize_field("col", &unit.position().col())?;
        value.serialize_field("row", &unit.position().row())?;
        value.end()
    }
}

const fn unit_kind_name(kind: UnitKind) -> &'static str {
    match kind {
        UnitKind::Commander => "commander",
        UnitKind::Warrior => "warrior",
        UnitKind::Archer => "archer",
        UnitKind::Settler => "settler",
        UnitKind::Worker => "worker",
        UnitKind::Merchant => "merchant",
        UnitKind::Scout => "scout",
        UnitKind::Spearman => "spearman",
        UnitKind::Cavalry => "cavalry",
        UnitKind::Catapult => "catapult",
        UnitKind::HeavyInfantry => "heavyInfantry",
        UnitKind::FieldCannon => "fieldCannon",
        UnitKind::Rifleman => "rifleman",
        UnitKind::Tank => "tank",
        UnitKind::ScoutShip => "scoutShip",
        UnitKind::Warship => "warship",
        UnitKind::ReconPlane => "reconPlane",
    }
}

struct HashWriter(Sha256);
impl Write for HashWriter {
    fn write(&mut self, buffer: &[u8]) -> io::Result<usize> {
        self.0.update(buffer);
        Ok(buffer.len())
    }
    fn flush(&mut self) -> io::Result<()> {
        Ok(())
    }
}
