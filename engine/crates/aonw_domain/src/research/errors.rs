use crate::{PlayerId, WonderType};

use super::TechnologyId;

/// Checked failure while changing one player's canonical research state.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum ResearchTransitionError {
    /// A completed technology cannot become active again.
    TechnologyAlreadyUnlocked(TechnologyId),
    /// Per-turn science must not be negative.
    NegativeScience(i64),
    /// Every selectable technology must have a positive effective cost.
    ZeroEffectiveCost(TechnologyId),
    /// Stored progress and newly applied science or overflow exceeded `i64`.
    ProgressOverflow(TechnologyId),
}

impl core::fmt::Display for ResearchTransitionError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::TechnologyAlreadyUnlocked(technology) => {
                write!(formatter, "technology is already unlocked: {technology:?}")
            }
            Self::NegativeScience(science) => {
                write!(
                    formatter,
                    "research science must be non-negative: {science}"
                )
            }
            Self::ZeroEffectiveCost(technology) => {
                write!(
                    formatter,
                    "research cost must be positive for {technology:?}"
                )
            }
            Self::ProgressOverflow(technology) => {
                write!(formatter, "research progress overflow for {technology:?}")
            }
        }
    }
}

impl std::error::Error for ResearchTransitionError {}

/// Attempt to complete a world wonder that already has a canonical owner.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct WonderCompletionError {
    pub(super) wonder: WonderType,
    pub(super) existing_owner: PlayerId,
}

impl WonderCompletionError {
    /// Returns the duplicated wonder identity.
    #[must_use]
    pub const fn wonder(&self) -> WonderType {
        self.wonder
    }

    /// Returns the canonical owner that won the completion race.
    #[must_use]
    pub const fn existing_owner(&self) -> &PlayerId {
        &self.existing_owner
    }
}

impl core::fmt::Display for WonderCompletionError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        write!(
            formatter,
            "wonder {:?} was already completed by {}",
            self.wonder, self.existing_owner
        )
    }
}

impl std::error::Error for WonderCompletionError {}

/// Structural player-research validation failure.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum PlayerResearchStateBuildError {
    /// An unlocked technology appeared more than once.
    DuplicateUnlocked(TechnologyId),
    /// The active selection was already unlocked.
    ActiveAlreadyUnlocked(TechnologyId),
    /// A progress entry appeared more than once.
    DuplicateProgress(TechnologyId),
    /// A progress entry was zero or negative.
    NonPositiveProgress {
        /// Technology carrying invalid progress.
        technology: TechnologyId,
        /// Invalid progress value.
        amount: i64,
    },
    /// An unlocked technology retained progress.
    ProgressForUnlocked(TechnologyId),
    /// Science overflow was negative.
    NegativeScienceOverflow(i64),
}

impl core::fmt::Display for PlayerResearchStateBuildError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::DuplicateUnlocked(value) => {
                write!(formatter, "duplicate unlocked technology: {value:?}")
            }
            Self::ActiveAlreadyUnlocked(value) => write!(
                formatter,
                "active technology is already unlocked: {value:?}"
            ),
            Self::DuplicateProgress(value) => {
                write!(formatter, "duplicate technology progress: {value:?}")
            }
            Self::NonPositiveProgress { technology, amount } => write!(
                formatter,
                "technology progress must be positive for {technology:?}: {amount}"
            ),
            Self::ProgressForUnlocked(value) => {
                write!(formatter, "unlocked technology retains progress: {value:?}")
            }
            Self::NegativeScienceOverflow(value) => {
                write!(formatter, "science overflow must be non-negative: {value}")
            }
        }
    }
}

impl std::error::Error for PlayerResearchStateBuildError {}

/// Cross-section knowledge-state validation failure.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum KnowledgeStateValidationError {
    /// Research was keyed by a non-participant player.
    ResearchPlayerNotFound(PlayerId),
    /// A completed wonder was attributed to a non-participant player.
    WonderOwnerNotFound {
        /// Wonder carrying invalid attribution.
        wonder: WonderType,
        /// Player absent from match identity.
        player_id: PlayerId,
    },
}

impl core::fmt::Display for KnowledgeStateValidationError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::ResearchPlayerNotFound(player) => {
                write!(formatter, "research references non-participant {player}")
            }
            Self::WonderOwnerNotFound { wonder, player_id } => write!(
                formatter,
                "wonder {wonder:?} references non-participant {player_id}"
            ),
        }
    }
}

impl std::error::Error for KnowledgeStateValidationError {}
