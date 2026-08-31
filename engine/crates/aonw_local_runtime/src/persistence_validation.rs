use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_contracts::{ReplayLogDto, SaveGameDto};

use crate::persistence::ENGINE_BEHAVIOR_FINGERPRINT;
use crate::persistence_error::PersistenceError;

pub(crate) fn validate_save_header(
    save: &SaveGameDto,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
) -> Result<(), PersistenceError> {
    if save.behavior_fingerprint != ENGINE_BEHAVIOR_FINGERPRINT {
        return Err(PersistenceError::BehaviorFingerprintMismatch);
    }
    validate_identity(
        &save.map_id,
        &save.map_hash,
        &save.ruleset_id,
        &save.ruleset_hash,
        map,
        ruleset,
    )
}

pub(crate) fn validate_replay_header(
    replay: &ReplayLogDto,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
) -> Result<(), PersistenceError> {
    if replay.behavior_fingerprint != ENGINE_BEHAVIOR_FINGERPRINT {
        return Err(PersistenceError::BehaviorFingerprintMismatch);
    }
    validate_identity(
        &replay.map_id,
        &replay.map_hash,
        &replay.ruleset_id,
        &replay.ruleset_hash,
        map,
        ruleset,
    )
}

fn validate_identity(
    map_id: &str,
    map_hash: &str,
    ruleset_id: &str,
    ruleset_hash: &str,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
) -> Result<(), PersistenceError> {
    if map_id != map.map_id() {
        return Err(PersistenceError::MapIdMismatch);
    }
    let actual_map_hash = map
        .content_hash()
        .map_err(|error| PersistenceError::ContentHash(error.to_string()))?;
    if map_hash != actual_map_hash.to_string() {
        return Err(PersistenceError::MapHashMismatch);
    }
    if ruleset_id != ruleset.ruleset_id() {
        return Err(PersistenceError::RulesetIdMismatch);
    }
    let actual_ruleset_hash = ruleset
        .content_hash()
        .map_err(|error| PersistenceError::ContentHash(error.to_string()))?;
    if ruleset_hash != actual_ruleset_hash.to_string() {
        return Err(PersistenceError::RulesetHashMismatch);
    }
    Ok(())
}
