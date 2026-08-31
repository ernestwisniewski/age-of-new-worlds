use aonw_content::MapDefinition;
use aonw_contracts::{GameStateDto, ReplayCommandDto, ReplayEventDto, ReplayEvidenceDto};
use serde::Serialize;

use crate::{JsonDifference, compare_json};

/// Fixture artifact version shared by canonical fixture producers and consumers.
pub const CANONICAL_FIXTURE_VERSION: u64 = 3;

/// One independently reviewed engine fixture.
#[derive(Clone, Debug, PartialEq)]
pub struct CanonicalFixture {
    pub(crate) version: u64,
    pub(crate) id: Box<str>,
    pub(crate) capability: Box<str>,
    pub(crate) input: CanonicalFixtureInput,
    pub(crate) expected: CanonicalFixtureOutput,
}

impl CanonicalFixture {
    /// Returns the cross-component fixture artifact version.
    #[must_use]
    pub const fn fixture_version(&self) -> u64 {
        self.version
    }

    /// Returns the kebab-case fixture identifier.
    #[must_use]
    pub fn id(&self) -> &str {
        &self.id
    }

    /// Returns the engine capability exercised by the fixture.
    #[must_use]
    pub fn capability(&self) -> &str {
        &self.capability
    }

    /// Returns the immutable canonical engine input.
    #[must_use]
    pub const fn input(&self) -> &CanonicalFixtureInput {
        &self.input
    }

    /// Returns the committed expected output.
    #[must_use]
    pub const fn expected(&self) -> &CanonicalFixtureOutput {
        &self.expected
    }

    /// Compares a complete typed implementation output with the expected output.
    ///
    /// # Panics
    ///
    /// Panics only if an already validated canonical DTO cannot be represented
    /// as JSON, which would violate its serialization contract.
    #[must_use]
    pub fn differences(&self, actual: &CanonicalFixtureOutput) -> Vec<JsonDifference> {
        if self.expected == *actual {
            return Vec::new();
        }
        let expected = serde_json::to_value(SerializableOutput::from(&self.expected))
            .expect("canonical fixture DTOs must serialize");
        let actual = serde_json::to_value(SerializableOutput::from(actual))
            .expect("canonical fixture DTOs must serialize");
        compare_json(&expected, &actual)
    }
}

/// Complete canonical engine input.
#[derive(Clone, Debug, PartialEq)]
pub struct CanonicalFixtureInput {
    pub(crate) actor_player_id: Box<str>,
    pub(crate) ruleset_id: Box<str>,
    pub(crate) map: MapDefinition,
    pub(crate) state: GameStateDto,
    pub(crate) command: ReplayCommandDto,
}

impl CanonicalFixtureInput {
    /// Returns the authenticated actor identifier.
    #[must_use]
    pub fn actor_player_id(&self) -> &str {
        &self.actor_player_id
    }

    /// Returns the immutable ruleset identifier.
    #[must_use]
    pub fn ruleset_id(&self) -> &str {
        &self.ruleset_id
    }

    /// Returns the validated canonical logical map.
    #[must_use]
    pub const fn map(&self) -> &MapDefinition {
        &self.map
    }

    /// Returns the complete canonical state DTO.
    #[must_use]
    pub const fn state(&self) -> &GameStateDto {
        &self.state
    }

    /// Returns the revision-bound command DTO.
    #[must_use]
    pub const fn command(&self) -> &ReplayCommandDto {
        &self.command
    }
}

/// Complete canonical command output returned by an engine executor.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CanonicalFixtureOutput {
    accepted: bool,
    rejection: Option<Box<str>>,
    state: GameStateDto,
    events: Box<[ReplayEventDto]>,
    evidence: Option<ReplayEvidenceDto>,
}

impl CanonicalFixtureOutput {
    /// Constructs an accepted output.
    #[must_use]
    pub fn accept(
        state: GameStateDto,
        events: impl Into<Box<[ReplayEventDto]>>,
        evidence: Option<ReplayEvidenceDto>,
    ) -> Self {
        Self {
            accepted: true,
            rejection: None,
            state,
            events: events.into(),
            evidence,
        }
    }

    /// Constructs a rejected output with unchanged canonical state.
    #[must_use]
    pub fn reject(rejection: impl Into<Box<str>>, state: GameStateDto) -> Self {
        Self {
            accepted: false,
            rejection: Some(rejection.into()),
            state,
            events: Box::new([]),
            evidence: None,
        }
    }

    pub(crate) fn try_from_parts(
        accepted: bool,
        rejection: Option<Box<str>>,
        state: GameStateDto,
        events: Vec<ReplayEventDto>,
        evidence: Option<ReplayEvidenceDto>,
    ) -> Result<Self, &'static str> {
        if accepted == rejection.is_some() {
            return Err("rejection must be null exactly when accepted is true");
        }
        if !accepted && (!events.is_empty() || evidence.is_some()) {
            return Err("a rejected output cannot contain events or evidence");
        }
        Ok(Self {
            accepted,
            rejection,
            state,
            events: events.into_boxed_slice(),
            evidence,
        })
    }

    /// Returns whether the command was accepted.
    #[must_use]
    pub const fn accepted(&self) -> bool {
        self.accepted
    }

    /// Returns the stable rejection code.
    #[must_use]
    pub fn rejection(&self) -> Option<&str> {
        self.rejection.as_deref()
    }

    /// Returns the complete returned canonical state.
    #[must_use]
    pub const fn state(&self) -> &GameStateDto {
        &self.state
    }

    /// Returns ordered authoritative events.
    #[must_use]
    pub const fn events(&self) -> &[ReplayEventDto] {
        &self.events
    }

    /// Returns exact deterministic execution evidence.
    #[must_use]
    pub const fn evidence(&self) -> Option<&ReplayEvidenceDto> {
        self.evidence.as_ref()
    }
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct SerializableOutput<'output> {
    accepted: bool,
    rejection: Option<&'output str>,
    state: &'output GameStateDto,
    events: &'output [ReplayEventDto],
    evidence: Option<&'output ReplayEvidenceDto>,
}

impl<'output> From<&'output CanonicalFixtureOutput> for SerializableOutput<'output> {
    fn from(value: &'output CanonicalFixtureOutput) -> Self {
        Self {
            accepted: value.accepted,
            rejection: value.rejection.as_deref(),
            state: &value.state,
            events: &value.events,
            evidence: value.evidence.as_ref(),
        }
    }
}
