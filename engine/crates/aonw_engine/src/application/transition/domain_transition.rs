use aonw_content::ContentHash;
use aonw_domain::{GameState, StateRevision};

use super::{CommandRejectionCode, DomainEvent, ExecutionEvidence};
use crate::StateDigest;

/// Stable command rejection independent of presentation language.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct DomainRejection {
    code: CommandRejectionCode,
}

impl DomainRejection {
    /// Returns the stable wire code.
    #[must_use]
    pub const fn code(self) -> CommandRejectionCode {
        self.code
    }
}

/// Complete authoritative outcome of one command.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DomainTransition {
    state: GameState,
    rejection: Option<DomainRejection>,
    events: Box<[DomainEvent]>,
    evidence: Option<ExecutionEvidence>,
    digest: Option<StateDigest>,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
}

/// Owned components of one authoritative transition.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DomainTransitionParts {
    /// Unchanged or next canonical state.
    pub state: GameState,
    /// Stable rejection code, absent when accepted.
    pub rejection: Option<DomainRejection>,
    /// Ordered authoritative events.
    pub events: Box<[DomainEvent]>,
    /// Exact execution evidence.
    pub evidence: Option<ExecutionEvidence>,
    /// Canonical identity of a changed `state`; rejected transitions reuse the
    /// caller's existing identity without recomputing it.
    pub digest: Option<StateDigest>,
    /// Exact logical map identity.
    pub map_hash: ContentHash,
    /// Exact immutable ruleset identity.
    pub ruleset_hash: ContentHash,
}

impl DomainTransition {
    pub(crate) fn accepted(
        state: GameState,
        events: Box<[super::DomainEvent]>,
        evidence: Option<ExecutionEvidence>,
        map_hash: ContentHash,
        ruleset_hash: ContentHash,
    ) -> Self {
        Self {
            digest: Some(crate::state_digest::digest_state(&state)),
            state,
            rejection: None,
            events,
            evidence,
            map_hash,
            ruleset_hash,
        }
    }

    pub(crate) fn rejected(
        state: GameState,
        code: CommandRejectionCode,
        map_hash: ContentHash,
        ruleset_hash: ContentHash,
    ) -> Self {
        Self {
            digest: None,
            state,
            rejection: Some(DomainRejection { code }),
            events: Box::new([]),
            evidence: None,
            map_hash,
            ruleset_hash,
        }
    }

    pub(crate) fn with_evidence(mut self, evidence: Option<ExecutionEvidence>) -> Self {
        self.evidence = evidence;
        self
    }

    /// Returns whether the command was accepted.
    #[must_use]
    pub const fn is_accepted(&self) -> bool {
        self.rejection.is_none()
    }

    /// Returns the unchanged or next canonical state.
    #[must_use]
    pub const fn state(&self) -> &GameState {
        &self.state
    }

    /// Returns a stable rejection when the command was not accepted.
    #[must_use]
    pub const fn rejection(&self) -> Option<DomainRejection> {
        self.rejection
    }

    /// Returns ordered domain events.
    #[must_use]
    pub const fn events(&self) -> &[super::DomainEvent] {
        &self.events
    }

    /// Returns exact command execution evidence.
    #[must_use]
    pub const fn evidence(&self) -> Option<&ExecutionEvidence> {
        self.evidence.as_ref()
    }

    /// Returns the revision of the returned state.
    #[must_use]
    pub const fn revision(&self) -> StateRevision {
        self.state.revision()
    }

    /// Returns canonical state identity.
    #[must_use]
    pub fn digest(&self) -> StateDigest {
        self.digest
            .unwrap_or_else(|| crate::state_digest::digest_state(&self.state))
    }

    /// Returns the exact map identity used by the transition.
    #[must_use]
    pub const fn map_hash(&self) -> ContentHash {
        self.map_hash
    }

    /// Returns the exact ruleset identity used by the transition.
    #[must_use]
    pub const fn ruleset_hash(&self) -> ContentHash {
        self.ruleset_hash
    }

    /// Consumes the transition without cloning its canonical state.
    #[must_use]
    pub fn into_parts(self) -> DomainTransitionParts {
        DomainTransitionParts {
            state: self.state,
            rejection: self.rejection,
            events: self.events,
            evidence: self.evidence,
            digest: self.digest,
            map_hash: self.map_hash,
            ruleset_hash: self.ruleset_hash,
        }
    }
}
