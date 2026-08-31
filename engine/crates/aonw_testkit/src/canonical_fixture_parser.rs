use std::path::Path;

use aonw_content::MapDefinition;
use aonw_contracts::{GameStateDto, ReplayCommandDto};
use serde::de::DeserializeOwned;
use serde_json::{Map, Value};

use crate::FixtureLoadError;
use crate::canonical_fixture::{
    CANONICAL_FIXTURE_VERSION, CanonicalFixture, CanonicalFixtureInput, CanonicalFixtureOutput,
};

const ROOT_KEYS: &[&str] = &["capability", "expected", "fixtureVersion", "id", "input"];
const INPUT_KEYS: &[&str] = &["actorPlayerId", "command", "map", "rulesetId", "state"];
const EXPECTED_KEYS: &[&str] = &["accepted", "events", "evidence", "rejection", "state"];

pub(super) fn parse_canonical_fixture(
    value: Value,
    path: Option<&Path>,
) -> Result<CanonicalFixture, FixtureLoadError> {
    let mut root = require_object(value, "$", path)?;
    require_exact_keys(&root, ROOT_KEYS, "$", path)?;
    let version = take_u64(&mut root, "fixtureVersion", "$.fixtureVersion", path)?;
    if version != CANONICAL_FIXTURE_VERSION {
        return Err(FixtureLoadError::UnsupportedVersion {
            path: path.map(Path::to_path_buf),
            found: version,
            supported: CANONICAL_FIXTURE_VERSION,
        });
    }

    let id = take_kebab_case(&mut root, "id", "$.id", path)?;
    let capability = take_kebab_case(&mut root, "capability", "$.capability", path)?;
    let input = parse_input(take(&mut root, "input", "$.input", path)?, path)?;
    let expected = parse_expected(take(&mut root, "expected", "$.expected", path)?, path)?;
    validate_capability(&capability, &input.command, path)?;
    validate_state_bounds(&input, expected.state(), path)?;
    Ok(CanonicalFixture {
        version,
        id: id.into_boxed_str(),
        capability: capability.into_boxed_str(),
        input,
        expected,
    })
}

fn validate_capability(
    capability: &str,
    command: &ReplayCommandDto,
    path: Option<&Path>,
) -> Result<(), FixtureLoadError> {
    let matches = matches!(
        (capability, command),
        ("movement", ReplayCommandDto::MoveUnit { .. })
            | (
                "unit-action",
                ReplayCommandDto::CancelUnitAction { .. }
                    | ReplayCommandDto::SkipUnitTurn { .. }
                    | ReplayCommandDto::FortifyUnit { .. }
            )
            | (
                "turn-kernel-ready",
                ReplayCommandDto::EndTurn { .. } | ReplayCommandDto::SubmitTurn { .. }
            )
    );
    if matches {
        Ok(())
    } else {
        Err(invalid(
            path,
            "$.capability",
            "must match the current command capability",
        ))
    }
}

fn validate_state_bounds(
    input: &CanonicalFixtureInput,
    expected: &GameStateDto,
    path: Option<&Path>,
) -> Result<(), FixtureLoadError> {
    let map = &input.map;
    let expected_bounds = (map.cols(), map.rows());
    if (input.state.cols, input.state.rows) != expected_bounds {
        return Err(invalid(
            path,
            "$.input.state",
            "state bounds must equal the embedded map bounds",
        ));
    }
    if (expected.cols, expected.rows) != expected_bounds {
        return Err(invalid(
            path,
            "$.expected.state",
            "state bounds must equal the embedded map bounds",
        ));
    }
    Ok(())
}

fn parse_input(
    value: Value,
    path: Option<&Path>,
) -> Result<CanonicalFixtureInput, FixtureLoadError> {
    let mut input = require_object(value, "$.input", path)?;
    require_exact_keys(&input, INPUT_KEYS, "$.input", path)?;
    let actor = take_non_empty_string(&mut input, "actorPlayerId", "$.input.actorPlayerId", path)?;
    let ruleset = take_non_empty_string(&mut input, "rulesetId", "$.input.rulesetId", path)?;
    if ruleset != "standard" {
        return Err(invalid(
            path,
            "$.input.rulesetId",
            "canonical fixtures require the standard ruleset",
        ));
    }
    let map_value = take(&mut input, "map", "$.input.map", path)?;
    let map_bytes = serde_json::to_vec(&map_value)
        .map_err(|error| invalid(path, "$.input.map", error.to_string()))?;
    let map = MapDefinition::from_canonical_json(&map_bytes)
        .map_err(|error| invalid(path, "$.input.map", error.to_string()))?;
    Ok(CanonicalFixtureInput {
        actor_player_id: actor.into_boxed_str(),
        ruleset_id: ruleset.into_boxed_str(),
        map,
        state: deserialize(
            take(&mut input, "state", "$.input.state", path)?,
            "$.input.state",
            path,
        )?,
        command: deserialize(
            take(&mut input, "command", "$.input.command", path)?,
            "$.input.command",
            path,
        )?,
    })
}

fn parse_expected(
    value: Value,
    path: Option<&Path>,
) -> Result<CanonicalFixtureOutput, FixtureLoadError> {
    let mut expected = require_object(value, "$.expected", path)?;
    require_exact_keys(&expected, EXPECTED_KEYS, "$.expected", path)?;
    let accepted = take_bool(&mut expected, "accepted", "$.expected.accepted", path)?;
    let rejection = take_optional_string(&mut expected, "rejection", "$.expected.rejection", path)?
        .map(String::into_boxed_str);
    let state = deserialize(
        take(&mut expected, "state", "$.expected.state", path)?,
        "$.expected.state",
        path,
    )?;
    let events = deserialize(
        take(&mut expected, "events", "$.expected.events", path)?,
        "$.expected.events",
        path,
    )?;
    let evidence = deserialize(
        take(&mut expected, "evidence", "$.expected.evidence", path)?,
        "$.expected.evidence",
        path,
    )?;
    CanonicalFixtureOutput::try_from_parts(accepted, rejection, state, events, evidence)
        .map_err(|message| invalid(path, "$.expected", message))
}

fn deserialize<T: DeserializeOwned>(
    value: Value,
    field: &str,
    path: Option<&Path>,
) -> Result<T, FixtureLoadError> {
    serde_json::from_value(value).map_err(|error| invalid(path, field, error.to_string()))
}

fn require_exact_keys(
    object: &Map<String, Value>,
    expected: &[&str],
    field: &str,
    path: Option<&Path>,
) -> Result<(), FixtureLoadError> {
    if object.len() == expected.len() && expected.iter().all(|key| object.contains_key(*key)) {
        return Ok(());
    }
    Err(invalid(
        path,
        field,
        format!("keys must be exactly [{}]", expected.join(", ")),
    ))
}

fn require_object(
    value: Value,
    field: &str,
    path: Option<&Path>,
) -> Result<Map<String, Value>, FixtureLoadError> {
    match value {
        Value::Object(object) => Ok(object),
        _ => Err(invalid(path, field, "must be a JSON object")),
    }
}

fn take(
    object: &mut Map<String, Value>,
    key: &str,
    field: &str,
    path: Option<&Path>,
) -> Result<Value, FixtureLoadError> {
    object
        .remove(key)
        .ok_or_else(|| invalid(path, field, "is required"))
}

fn take_kebab_case(
    object: &mut Map<String, Value>,
    key: &str,
    field: &str,
    path: Option<&Path>,
) -> Result<String, FixtureLoadError> {
    let value = take_non_empty_string(object, key, field, path)?;
    if value.starts_with('-')
        || value.ends_with('-')
        || value
            .bytes()
            .any(|byte| !(byte.is_ascii_lowercase() || byte.is_ascii_digit() || byte == b'-'))
        || value.as_bytes().windows(2).any(|pair| pair == b"--")
    {
        return Err(invalid(path, field, "must be lowercase kebab-case"));
    }
    Ok(value)
}

fn take_non_empty_string(
    object: &mut Map<String, Value>,
    key: &str,
    field: &str,
    path: Option<&Path>,
) -> Result<String, FixtureLoadError> {
    match take(object, key, field, path)? {
        Value::String(value) if !value.is_empty() => Ok(value),
        _ => Err(invalid(path, field, "must be a non-empty string")),
    }
}

fn take_optional_string(
    object: &mut Map<String, Value>,
    key: &str,
    field: &str,
    path: Option<&Path>,
) -> Result<Option<String>, FixtureLoadError> {
    match take(object, key, field, path)? {
        Value::Null => Ok(None),
        Value::String(value) if !value.is_empty() => Ok(Some(value)),
        _ => Err(invalid(path, field, "must be null or a non-empty string")),
    }
}

fn take_u64(
    object: &mut Map<String, Value>,
    key: &str,
    field: &str,
    path: Option<&Path>,
) -> Result<u64, FixtureLoadError> {
    take(object, key, field, path)?
        .as_u64()
        .ok_or_else(|| invalid(path, field, "must be a non-negative integer"))
}

fn take_bool(
    object: &mut Map<String, Value>,
    key: &str,
    field: &str,
    path: Option<&Path>,
) -> Result<bool, FixtureLoadError> {
    take(object, key, field, path)?
        .as_bool()
        .ok_or_else(|| invalid(path, field, "must be a boolean"))
}

fn invalid(
    path: Option<&Path>,
    field: impl Into<Box<str>>,
    message: impl Into<Box<str>>,
) -> FixtureLoadError {
    FixtureLoadError::Invalid {
        path: path.map(Path::to_path_buf),
        field: field.into(),
        message: message.into(),
    }
}
