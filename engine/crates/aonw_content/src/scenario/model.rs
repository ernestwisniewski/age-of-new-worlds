use aonw_domain::{HexCoord, PlayerId, UnitId, UnitKind};

use crate::{ContentHash, MapDefinition, RulesetDefinition, validation::validate_content_id};

use super::ScenarioValidationError;

/// Initial unit placement owned by scenario content.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ScenarioUnitDefinition {
    id: UnitId,
    owner_player_id: PlayerId,
    kind: UnitKind,
    name: Box<str>,
    position: HexCoord,
}

impl ScenarioUnitDefinition {
    /// Constructs one initial placement.
    #[must_use]
    pub fn new(
        id: UnitId,
        owner_player_id: PlayerId,
        kind: UnitKind,
        name: impl Into<Box<str>>,
        position: HexCoord,
    ) -> Self {
        Self {
            id,
            owner_player_id,
            kind,
            name: name.into(),
            position,
        }
    }
    /// Returns the unit identifier.
    #[must_use]
    pub const fn id(&self) -> &UnitId {
        &self.id
    }
    /// Returns the owner identifier.
    #[must_use]
    pub const fn owner_player_id(&self) -> &PlayerId {
        &self.owner_player_id
    }
    /// Returns the canonical unit kind.
    #[must_use]
    pub const fn kind(&self) -> UnitKind {
        self.kind
    }
    /// Returns the initial display name.
    #[must_use]
    pub fn name(&self) -> &str {
        &self.name
    }
    /// Returns the initial coordinate.
    #[must_use]
    pub const fn position(&self) -> HexCoord {
        self.position
    }
}

/// Immutable scenario linked to exact map and ruleset identities.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ScenarioDefinition {
    pub(super) schema_version: u16,
    pub(super) scenario_id: Box<str>,
    pub(super) map_id: Box<str>,
    pub(super) map_hash: ContentHash,
    pub(super) ruleset_id: Box<str>,
    pub(super) ruleset_hash: ContentHash,
    pub(super) initial_units: Box<[ScenarioUnitDefinition]>,
}

impl ScenarioDefinition {
    /// Validates a scenario against its referenced map and ruleset.
    ///
    /// # Errors
    ///
    /// Returns an error for invalid IDs, placements, duplicate units or unsupported kinds.
    pub fn try_new(
        scenario_id: impl Into<Box<str>>,
        map: &MapDefinition,
        ruleset: &RulesetDefinition,
        initial_units: impl IntoIterator<Item = ScenarioUnitDefinition>,
    ) -> Result<Self, ScenarioValidationError> {
        let scenario_id = scenario_id.into();
        validate_content_id("$.scenarioId", &scenario_id)
            .map_err(|error| ScenarioValidationError::new("$.scenarioId", error.to_string()))?;
        let initial_units = initial_units.into_iter().collect::<Vec<_>>();
        validate_units(map, ruleset, &initial_units)?;
        Ok(Self {
            schema_version: 1,
            scenario_id,
            map_id: map.map_id().into(),
            map_hash: map
                .content_hash()
                .map_err(|error| ScenarioValidationError::new("$.mapHash", error.to_string()))?,
            ruleset_id: ruleset.ruleset_id().into(),
            ruleset_hash: ruleset.content_hash().map_err(|error| {
                ScenarioValidationError::new("$.rulesetHash", error.to_string())
            })?,
            initial_units: initial_units.into_boxed_slice(),
        })
    }

    /// Returns the scenario identifier.
    #[must_use]
    pub fn scenario_id(&self) -> &str {
        &self.scenario_id
    }
    /// Returns the referenced map identifier.
    #[must_use]
    pub fn map_id(&self) -> &str {
        &self.map_id
    }
    /// Returns the referenced ruleset identifier.
    #[must_use]
    pub fn ruleset_id(&self) -> &str {
        &self.ruleset_id
    }
    /// Returns the referenced map hash.
    #[must_use]
    pub const fn map_hash(&self) -> ContentHash {
        self.map_hash
    }
    /// Returns the referenced ruleset hash.
    #[must_use]
    pub const fn ruleset_hash(&self) -> ContentHash {
        self.ruleset_hash
    }
    /// Returns initial units in authored order.
    #[must_use]
    pub const fn initial_units(&self) -> &[ScenarioUnitDefinition] {
        &self.initial_units
    }
}

fn validate_units(
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    initial_units: &[ScenarioUnitDefinition],
) -> Result<(), ScenarioValidationError> {
    for (index, unit) in initial_units.iter().enumerate() {
        if unit.name().trim().is_empty() {
            return Err(ScenarioValidationError::new(
                format!("$.initialUnits[{index}].name"),
                "must not be blank",
            ));
        }
        if map.tile_at(unit.position()).is_none() {
            return Err(ScenarioValidationError::new(
                format!("$.initialUnits[{index}]"),
                "position is outside the referenced map",
            ));
        }
        if ruleset.unit(unit.kind()).is_none() {
            return Err(ScenarioValidationError::new(
                format!("$.initialUnits[{index}].kind"),
                "unit kind is absent from the referenced ruleset",
            ));
        }
    }
    validate_unique_ids(initial_units)?;
    validate_occupancy(ruleset, initial_units)
}

fn validate_unique_ids(
    initial_units: &[ScenarioUnitDefinition],
) -> Result<(), ScenarioValidationError> {
    let mut by_id = initial_units.iter().collect::<Vec<_>>();
    by_id.sort_unstable_by(|left, right| left.id().cmp(right.id()));
    if let Some(pair) = by_id.windows(2).find(|pair| pair[0].id() == pair[1].id()) {
        return Err(ScenarioValidationError::new(
            "$.initialUnits",
            format!("duplicate unit id: {}", pair[0].id()),
        ));
    }
    Ok(())
}

fn validate_occupancy(
    ruleset: &RulesetDefinition,
    initial_units: &[ScenarioUnitDefinition],
) -> Result<(), ScenarioValidationError> {
    let mut by_position = initial_units.iter().collect::<Vec<_>>();
    by_position.sort_unstable_by_key(|unit| unit.position());
    let Some(pair) = by_position.windows(2).find(|pair| {
        pair[0].position() == pair[1].position()
            && !ruleset
                .occupancy_policy()
                .permits(pair[0].owner_player_id(), pair[1].owner_player_id())
    }) else {
        return Ok(());
    };
    Err(ScenarioValidationError::new(
        "$.initialUnits",
        format!(
            "disallowed shared unit position: ({}, {})",
            pair[0].position().col(),
            pair[0].position().row()
        ),
    ))
}
