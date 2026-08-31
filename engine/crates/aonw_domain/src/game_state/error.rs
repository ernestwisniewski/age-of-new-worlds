use crate::{
    ArtifactId, CityBuildError, CityId, CombatStateValidationError, DiplomacyStateBuildError,
    EconomyStateBuildError, GameOutcomeBuildError, HexCoord, InfrastructureValidationError,
    KnowledgeStateValidationError, ObjectiveStateBuildError, PlayerId, UnitId, WonderType,
};

/// Failure raised while constructing the canonical simulation aggregate.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum GameStateBuildError {
    /// More than one unit used an identifier.
    DuplicateUnitId(UnitId),
    /// A requested unit update does not belong to the aggregate.
    UnitNotFound(UnitId),
    /// A unit is outside the logical map.
    UnitOutOfBounds {
        /// Unit carrying the invalid position.
        unit_id: UnitId,
        /// Position outside aggregate bounds.
        position: HexCoord,
    },
    /// Two units occupy one coordinate while stacking is disabled.
    OccupiedCoordinate {
        /// Colliding position.
        position: HexCoord,
    },
    /// More than one city used an identifier.
    DuplicateCityId(CityId),
    /// A requested city update does not belong to the aggregate.
    CityNotFound(CityId),
    /// A city violates its entity-local numeric or topology invariants.
    InvalidCity {
        /// Invalid city.
        city_id: CityId,
        /// Local invariant failure.
        error: CityBuildError,
    },
    /// Two cities claim the same center or controlled coordinate.
    CityTerritoryOverlap {
        /// Shared coordinate.
        position: HexCoord,
        /// First city in canonical identifier order.
        first_city_id: CityId,
        /// Second city in canonical identifier order.
        second_city_id: CityId,
    },
    /// More than one artifact used an identifier.
    DuplicateArtifactId(ArtifactId),
    /// A requested artifact update does not belong to the aggregate.
    ArtifactNotFound(ArtifactId),
    /// A city center or controlled coordinate is outside the map.
    CityOutOfBounds {
        /// City carrying invalid topology.
        city_id: CityId,
        /// Coordinate outside aggregate bounds.
        position: HexCoord,
    },
    /// A fog coordinate is outside the map.
    FogOutOfBounds {
        /// Player carrying invalid fog.
        player_id: PlayerId,
        /// Coordinate outside aggregate bounds.
        position: HexCoord,
    },
    /// An artifact map coordinate is outside the map.
    ArtifactOutOfBounds {
        /// Artifact carrying the coordinate.
        artifact_id: ArtifactId,
        /// Invalid coordinate.
        position: HexCoord,
    },
    /// An artifact references an absent unit.
    ArtifactUnitNotFound {
        /// Artifact carrying the invalid reference.
        artifact_id: ArtifactId,
        /// Referenced unit.
        unit_id: UnitId,
    },
    /// An artifact references an absent city.
    ArtifactCityNotFound {
        /// Artifact carrying the invalid reference.
        artifact_id: ArtifactId,
        /// Referenced city.
        city_id: CityId,
    },
    /// More than one artifact occupies the single canonical city slot.
    CityArtifactSlotOccupied {
        /// City with the duplicate storage slot.
        city_id: CityId,
        /// First artifact in canonical identifier order.
        first_artifact_id: ArtifactId,
        /// Second artifact in canonical identifier order.
        second_artifact_id: ArtifactId,
    },
    /// Excavation duration is zero or its unit left the source coordinate.
    InvalidArtifactExcavation {
        /// Artifact carrying invalid excavation state.
        artifact_id: ArtifactId,
        /// Referenced excavating unit.
        unit_id: UnitId,
    },
    /// Unit and artifact ownership references differ.
    ArtifactUnitMismatch {
        /// Artifact carrying the invalid ownership.
        artifact_id: ArtifactId,
        /// Referenced unit.
        unit_id: UnitId,
    },
    /// A unit references an absent artifact.
    UnitArtifactNotFound {
        /// Unit carrying the invalid reference.
        unit_id: UnitId,
        /// Referenced artifact.
        artifact_id: ArtifactId,
    },
    /// A unit attempts to use both mutually exclusive artifact activity slots.
    UnitArtifactActivityConflict {
        /// Unit carrying and excavating simultaneously.
        unit_id: UnitId,
        /// Artifact already carried by the unit.
        carried_artifact_id: ArtifactId,
        /// Different artifact currently being excavated.
        excavating_artifact_id: ArtifactId,
    },
    /// Interaction state references an absent unit.
    InteractionUnitNotFound(UnitId),
    /// Interaction state references an absent city.
    InteractionCityNotFound(CityId),
    /// Interaction state contains an out-of-bounds coordinate.
    InteractionOutOfBounds(HexCoord),
    /// Interaction ownership differs from the referenced unit or city.
    InteractionOwnerMismatch,
    /// A unit owner is absent from the bound match identity.
    UnitPlayerNotFound {
        /// Unit carrying the invalid owner.
        unit_id: UnitId,
        /// Unknown player reference.
        player_id: PlayerId,
    },
    /// A current or founding city owner is absent from the bound match identity.
    CityPlayerNotFound {
        /// City carrying the invalid owner.
        city_id: CityId,
        /// Unknown player reference.
        player_id: PlayerId,
    },
    /// Fog state belongs to a player absent from the bound match identity.
    FogPlayerNotFound(PlayerId),
    /// Enabled fog does not contain state for one match participant.
    FogPlayerMissing(PlayerId),
    /// Interaction state belongs to a player absent from the bound match identity.
    InteractionPlayerNotFound(PlayerId),
    /// A pending turn skip does not match the skipped unit state.
    InvalidTurnSkipState(UnitId),
    /// Economy data violates participant ownership or map topology.
    InvalidEconomy(EconomyStateBuildError),
    /// Infrastructure data violates map or entity references.
    InvalidInfrastructure(InfrastructureValidationError),
    /// Research or wonder data references an identity outside the match.
    InvalidKnowledge(KnowledgeStateValidationError),
    /// A city lists a wonder absent from the authoritative completion registry.
    CityWonderNotRegistered {
        /// City hosting the unregistered wonder.
        city_id: CityId,
        /// Wonder absent from the completion registry.
        wonder: WonderType,
    },
    /// More than one city claims to host the same completed wonder.
    DuplicateWonderHost {
        /// Duplicated wonder.
        wonder: WonderType,
        /// First host in canonical city order.
        first_city_id: CityId,
        /// Second host in canonical city order.
        second_city_id: CityId,
    },
    /// Pending combat declarations violate aggregate references.
    InvalidCombat(CombatStateValidationError),
    /// Diplomacy data violates participant or contact references.
    InvalidDiplomacy(DiplomacyStateBuildError),
    /// Victory-progress state violates participant or sparse-value invariants.
    InvalidObjectives(ObjectiveStateBuildError),
    /// Persisted match result violates condition or participant invariants.
    InvalidOutcome(GameOutcomeBuildError),
}

impl core::fmt::Display for GameStateBuildError {
    #[allow(clippy::too_many_lines)]
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::DuplicateUnitId(id) => write!(formatter, "duplicate unit id: {id}"),
            Self::UnitNotFound(id) => write!(formatter, "unit not found: {id}"),
            Self::UnitOutOfBounds { unit_id, position } => write!(
                formatter,
                "unit {unit_id} is outside the map at ({}, {})",
                position.col(),
                position.row()
            ),
            Self::OccupiedCoordinate { position } => write!(
                formatter,
                "multiple units occupy ({}, {})",
                position.col(),
                position.row()
            ),
            Self::DuplicateCityId(id) => write!(formatter, "duplicate city id: {id}"),
            Self::CityNotFound(id) => write!(formatter, "city not found: {id}"),
            Self::InvalidCity { city_id, error } => {
                write!(formatter, "city {city_id} is invalid: {error}")
            }
            Self::CityTerritoryOverlap {
                position,
                first_city_id,
                second_city_id,
            } => write!(
                formatter,
                "cities {first_city_id} and {second_city_id} overlap at ({}, {})",
                position.col(),
                position.row()
            ),
            Self::DuplicateArtifactId(id) => write!(formatter, "duplicate artifact id: {id}"),
            Self::ArtifactNotFound(id) => write!(formatter, "artifact not found: {id}"),
            Self::CityOutOfBounds { city_id, position } => write!(
                formatter,
                "city {city_id} references ({}, {}) outside the map",
                position.col(),
                position.row()
            ),
            Self::FogOutOfBounds {
                player_id,
                position,
            } => write!(
                formatter,
                "fog for {player_id} references ({}, {}) outside the map",
                position.col(),
                position.row()
            ),
            Self::ArtifactOutOfBounds {
                artifact_id,
                position,
            } => write!(
                formatter,
                "artifact {artifact_id} is outside the map at ({}, {})",
                position.col(),
                position.row()
            ),
            Self::ArtifactUnitNotFound {
                artifact_id,
                unit_id,
            } => write!(
                formatter,
                "artifact {artifact_id} references missing unit {unit_id}"
            ),
            Self::ArtifactCityNotFound {
                artifact_id,
                city_id,
            } => write!(
                formatter,
                "artifact {artifact_id} references missing city {city_id}"
            ),
            Self::CityArtifactSlotOccupied {
                city_id,
                first_artifact_id,
                second_artifact_id,
            } => write!(
                formatter,
                "city {city_id} stores both artifacts {first_artifact_id} and {second_artifact_id}"
            ),
            Self::InvalidArtifactExcavation {
                artifact_id,
                unit_id,
            } => write!(
                formatter,
                "artifact {artifact_id} has invalid excavation state for unit {unit_id}"
            ),
            Self::ArtifactUnitMismatch {
                artifact_id,
                unit_id,
            } => write!(
                formatter,
                "artifact {artifact_id} and unit {unit_id} ownership differ"
            ),
            Self::UnitArtifactNotFound {
                unit_id,
                artifact_id,
            } => write!(
                formatter,
                "unit {unit_id} references missing artifact {artifact_id}"
            ),
            Self::UnitArtifactActivityConflict {
                unit_id,
                carried_artifact_id,
                excavating_artifact_id,
            } => write!(
                formatter,
                "unit {unit_id} carries {carried_artifact_id} while excavating {excavating_artifact_id}"
            ),
            Self::InteractionUnitNotFound(id) => {
                write!(formatter, "interaction references missing unit {id}")
            }
            Self::InteractionCityNotFound(id) => {
                write!(formatter, "interaction references missing city {id}")
            }
            Self::InteractionOutOfBounds(position) => write!(
                formatter,
                "interaction references ({}, {}) outside the map",
                position.col(),
                position.row()
            ),
            Self::InteractionOwnerMismatch => {
                formatter.write_str("interaction owner does not own its referenced entity")
            }
            Self::UnitPlayerNotFound { unit_id, player_id } => {
                write!(
                    formatter,
                    "unit {unit_id} references non-participant {player_id}"
                )
            }
            Self::CityPlayerNotFound { city_id, player_id } => {
                write!(
                    formatter,
                    "city {city_id} references non-participant {player_id}"
                )
            }
            Self::FogPlayerNotFound(player_id) => {
                write!(formatter, "fog references non-participant {player_id}")
            }
            Self::FogPlayerMissing(player_id) => {
                write!(formatter, "enabled fog is missing participant {player_id}")
            }
            Self::InteractionPlayerNotFound(player_id) => {
                write!(
                    formatter,
                    "interaction references non-participant {player_id}"
                )
            }
            Self::InvalidTurnSkipState(id) => {
                write!(formatter, "pending turn skip does not match unit {id}")
            }
            Self::InvalidEconomy(error) => error.fmt(formatter),
            Self::InvalidInfrastructure(error) => error.fmt(formatter),
            Self::InvalidKnowledge(error) => error.fmt(formatter),
            Self::CityWonderNotRegistered { city_id, wonder } => {
                write!(
                    formatter,
                    "city {city_id} hosts unregistered wonder {wonder:?}"
                )
            }
            Self::DuplicateWonderHost {
                wonder,
                first_city_id,
                second_city_id,
            } => write!(
                formatter,
                "wonder {wonder:?} is hosted by both {first_city_id} and {second_city_id}"
            ),
            Self::InvalidCombat(error) => error.fmt(formatter),
            Self::InvalidDiplomacy(error) => error.fmt(formatter),
            Self::InvalidObjectives(error) => error.fmt(formatter),
            Self::InvalidOutcome(error) => error.fmt(formatter),
        }
    }
}

impl std::error::Error for GameStateBuildError {}
