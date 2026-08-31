//! Contract tests for canonical engine fixtures.

use aonw_testkit::{CANONICAL_FIXTURE_VERSION, CanonicalFixtureLoader, FixtureLoadError};
use serde_json::{Value, json};

fn fixture_json() -> Value {
    json!({
        "fixtureVersion": CANONICAL_FIXTURE_VERSION,
        "id": "fortify-unit-accepted",
        "capability": "unit-action",
        "input": {
            "actorPlayerId": "player-1",
            "rulesetId": "standard",
            "map": map_json(),
            "state": state_json(4, "active", 10),
            "command": {
                "type": "fortifyUnit",
                "expectedRevision": 4,
                "unitId": "unit-1"
            }
        },
        "expected": {
            "accepted": true,
            "rejection": null,
            "state": state_json(5, "fortified", 0),
            "events": [],
            "evidence": null
        }
    })
}

fn map_json() -> Value {
    let tiles = (0..5)
        .flat_map(|row| {
            (0..5).map(move |col| {
                json!({
                    "col": col,
                    "row": row,
                    "terrainTags": ["plains"],
                    "resources": [],
                    "height": 0
                })
            })
        })
        .collect::<Vec<_>>();
    json!({
        "schemaVersion": 1,
        "gridLayout": "oddQFlatTop",
        "cols": 5,
        "rows": 5,
        "mapName": "canonical-fixture-plains",
        "objectives": [],
        "tiles": tiles
    })
}

fn state_json(revision: u64, posture: &str, movement_units: u32) -> Value {
    json!({
        "revision": revision,
        "turn": 1,
        "matchIdentity": {
            "matchRules": {
                "gameLength": {
                    "kind": "unlimited",
                    "targetMinutes": null,
                    "turnLimit": null,
                    "paceProfile": "unlimited",
                    "scoreFallbackEnabled": false
                },
                "victory": {
                    "conquestEnabled": true,
                    "dominationEnabled": true,
                    "dominationControlPercent": 60,
                    "dominationHoldTurns": 5,
                    "scoreFallbackEnabled": false,
                    "turnLimit": null,
                    "hardTimeLimitMinutes": null,
                    "culturalEnabled": true,
                    "culturalRequiredArtifacts": 6,
                    "culturalHoldTurns": 5
                },
                "balance": {}
            },
            "participants": [{
                "id": "player-1",
                "name": "Player 1",
                "colorValue": 4_278_190_335_u32,
                "country": "poland",
                "kind": "human",
                "ai": null
            }],
            "gameMode": "hotSeat"
        },
        "turnLifecycle": {
            "turnStatesByPlayerId": {"player-1": "active"},
            "requiredSubmissionPlayerIds":[],"submittedPlayerIds": [],
            "timeoutStreaksByPlayerId": {},
            "afkPlayerIds": [],
            "kickedPlayerIds": [],
            "turnStartedAt": null
        },
        "economy": {
            "playerGold": {},
            "playerWarWeariness": {},
            "playerStabilityNet": {},
            "strategicResources": {},
            "initialResourceDistribution": {"seed": 0, "placements": []}
        },
        "research": {"players": {}},
        "wonderRegistry": {},
        "intendedAttacks": [],
        "cols": 5,
        "rows": 5,
        "occupancyPolicy": "friendlyStacking",
        "units": [{
            "id": "unit-1",
            "ownerPlayerId": "player-1",
            "kind": "commander",
            "name": "unit.commander",
            "col": 2,
            "row": 2,
            "movementUnits": movement_units,
            "army": [],
            "queuedPath": null,
            "merchantTradeRoute": null,
            "activity": {
                "workerJob": null,
                "cityFoundingJob": null,
                "workerAssignment": null,
                "excavatingArtifactId": null
            },
            "workerBuildCharges": 0,
            "hitPoints": null,
            "experiencePoints": 0,
            "posture": posture,
            "carriedArtifactId": null
        }],
        "cities": [],
        "artifacts": [],
        "fieldImprovements": [],
        "interaction": {"cityFoundingDraft": null, "pending": null},
        "fogOfWar": [],
        "diplomacy": {
            "contacts": [],
            "relations": [],
            "pendingProposals": [],
            "messages": [],
            "scoreHistory": []
        },
        "resourceTradeAgreements": [],
        "dominationHoldTurnsByPlayerId": {},
        "culturalVictoryHoldTurnsByPlayerId": {},
        "mapObjectiveHoldStates": [],
        "outcome": {"condition": "ongoing", "winnerPlayerId": null, "scoreByPlayerId": {}},
        "transportNetwork": []
    })
}

fn encoded(value: &Value) -> Vec<u8> {
    serde_json::to_vec(value).expect("fixture must encode")
}

#[test]
fn canonical_fixture_owns_typed_contracts() {
    let fixture = CanonicalFixtureLoader::default()
        .parse(&encoded(&fixture_json()))
        .expect("valid canonical fixture");

    assert_eq!(fixture.fixture_version(), 3);
    assert_eq!(fixture.id(), "fortify-unit-accepted");
    assert_eq!(fixture.capability(), "unit-action");
    assert_eq!(fixture.input().state().revision, 4);
    assert_eq!(fixture.expected().state().revision, 5);
    assert!(fixture.expected().accepted());
}

#[test]
fn canonical_fixture_rejects_alternate_envelope_fields() {
    for field in ["now", "tick", "match", "save"] {
        let mut value = fixture_json();
        value["input"][field] = json!(null);

        assert!(matches!(
            CanonicalFixtureLoader::default().parse(&encoded(&value)),
            Err(FixtureLoadError::Invalid { ref field, .. }) if field.as_ref() == "$.input"
        ));
    }
}

#[test]
fn canonical_fixture_rejects_unknown_nested_dto_fields() {
    let mut value = fixture_json();
    value["input"]["command"]["unsupportedType"] = json!("FortifyUnit");

    assert!(matches!(
        CanonicalFixtureLoader::default().parse(&encoded(&value)),
        Err(FixtureLoadError::Invalid { ref field, .. }) if field.as_ref() == "$.input.command"
    ));
}

#[test]
fn canonical_fixture_version_fails_closed() {
    let mut value = fixture_json();
    value["fixtureVersion"] = json!(2);

    assert!(matches!(
        CanonicalFixtureLoader::default().parse(&encoded(&value)),
        Err(FixtureLoadError::UnsupportedVersion {
            found: 2,
            supported: 3,
            ..
        })
    ));
}

#[test]
fn canonical_fixture_rejects_duplicate_json_keys() {
    let source = br#"{
      "fixtureVersion": 3,
      "fixtureVersion": 3,
      "id": "duplicate-version",
      "capability": "unit-action",
      "input": {},
      "expected": {}
    }"#;

    assert!(matches!(
        CanonicalFixtureLoader::default().parse(source),
        Err(FixtureLoadError::Json { .. })
    ));
}

#[test]
fn capability_must_match_the_typed_command() {
    let mut value = fixture_json();
    value["capability"] = json!("movement");

    assert!(matches!(
        CanonicalFixtureLoader::default().parse(&encoded(&value)),
        Err(FixtureLoadError::Invalid { ref field, .. }) if field.as_ref() == "$.capability"
    ));
}

#[test]
fn canonical_states_must_share_the_embedded_map_bounds() {
    for state_path in [["input", "state"], ["expected", "state"]] {
        let mut value = fixture_json();
        value[state_path[0]][state_path[1]]["cols"] = json!(6);

        assert!(matches!(
            CanonicalFixtureLoader::default().parse(&encoded(&value)),
            Err(FixtureLoadError::Invalid { ref field, .. })
                if field.as_ref() == format!("$.{}.state", state_path[0])
        ));
    }
}

#[test]
fn rejected_output_cannot_carry_events_or_evidence() {
    let mut value = fixture_json();
    value["expected"]["accepted"] = json!(false);
    value["expected"]["rejection"] = json!("unit_busy");
    value["expected"]["events"] = json!([{
        "type": "unitMoved",
        "unitId": "unit-1",
        "from": {"col": 2, "row": 2},
        "to": {"col": 3, "row": 2}
    }]);

    assert!(matches!(
        CanonicalFixtureLoader::default().parse(&encoded(&value)),
        Err(FixtureLoadError::Invalid { ref field, .. }) if field.as_ref() == "$.expected"
    ));
}
