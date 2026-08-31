use crate::{
    City, CityId, FieldImprovementKind, HexCoord, HexGridBounds, MatchIdentity, PlayerId,
    TransportNetwork,
};

/// One economic field improvement occupying a map coordinate.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct FieldImprovement {
    coordinate: HexCoord,
    kind: FieldImprovementKind,
    built_by_city_id: Option<CityId>,
}

impl FieldImprovement {
    /// Constructs a persisted field improvement.
    #[must_use]
    pub const fn new(
        coordinate: HexCoord,
        kind: FieldImprovementKind,
        built_by_city_id: Option<CityId>,
    ) -> Self {
        Self {
            coordinate,
            kind,
            built_by_city_id,
        }
    }

    /// Returns the occupied map coordinate.
    #[must_use]
    pub const fn coordinate(&self) -> HexCoord {
        self.coordinate
    }

    /// Returns the improvement identity.
    #[must_use]
    pub const fn kind(&self) -> FieldImprovementKind {
        self.kind
    }

    /// Returns the city credited with construction when retained by the state.
    #[must_use]
    pub const fn built_by_city_id(&self) -> Option<&CityId> {
        self.built_by_city_id.as_ref()
    }
}

/// Complete economic and transport infrastructure state.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct InfrastructureState {
    field_improvements: Box<[FieldImprovement]>,
    transport_network: TransportNetwork,
}

impl InfrastructureState {
    /// Validates unique field-improvement coordinates and normalizes their order.
    ///
    /// # Errors
    ///
    /// Returns the duplicated field-improvement coordinate.
    pub fn try_new(
        field_improvements: impl IntoIterator<Item = FieldImprovement>,
        transport_network: TransportNetwork,
    ) -> Result<Self, InfrastructureStateBuildError> {
        let mut field_improvements = field_improvements.into_iter().collect::<Vec<_>>();
        if !field_improvements
            .windows(2)
            .all(|pair| pair[0].coordinate() <= pair[1].coordinate())
        {
            field_improvements.sort_unstable_by_key(FieldImprovement::coordinate);
        }
        if let Some(pair) = field_improvements
            .windows(2)
            .find(|pair| pair[0].coordinate() == pair[1].coordinate())
        {
            return Err(InfrastructureStateBuildError::DuplicateFieldImprovement(
                pair[0].coordinate(),
            ));
        }
        Ok(Self {
            field_improvements: field_improvements.into_boxed_slice(),
            transport_network,
        })
    }

    /// Wraps an already validated transport network without field improvements.
    #[must_use]
    pub fn from_transport(transport_network: TransportNetwork) -> Self {
        Self {
            field_improvements: Box::default(),
            transport_network,
        }
    }

    /// Returns field improvements in coordinate order.
    #[must_use]
    pub const fn field_improvements(&self) -> &[FieldImprovement] {
        &self.field_improvements
    }

    /// Returns the field improvement at a coordinate.
    #[must_use]
    pub fn field_improvement_at(&self, coordinate: HexCoord) -> Option<&FieldImprovement> {
        self.field_improvements
            .binary_search_by_key(&coordinate, FieldImprovement::coordinate)
            .ok()
            .map(|index| &self.field_improvements[index])
    }

    /// Returns canonical road infrastructure.
    #[must_use]
    pub const fn transport_network(&self) -> &TransportNetwork {
        &self.transport_network
    }

    /// Validates map and entity references against the containing game state.
    ///
    /// # Errors
    ///
    /// Returns the first invalid coordinate or entity reference.
    pub fn validate_for(
        &self,
        bounds: HexGridBounds,
        identity: &MatchIdentity,
        cities: &[City],
    ) -> Result<(), InfrastructureValidationError> {
        for improvement in self.field_improvements() {
            if !bounds.contains(improvement.coordinate()) {
                return Err(InfrastructureValidationError::FieldImprovementOutOfBounds(
                    improvement.coordinate(),
                ));
            }
            if let Some(city_id) = improvement.built_by_city_id()
                && !cities.iter().any(|city| city.id() == city_id)
            {
                return Err(
                    InfrastructureValidationError::FieldImprovementCityNotFound {
                        position: improvement.coordinate(),
                        city_id: city_id.clone(),
                    },
                );
            }
        }
        for segment in self.transport_network().segments() {
            if !bounds.contains(segment.coordinate()) {
                return Err(InfrastructureValidationError::TransportOutOfBounds(
                    segment.coordinate(),
                ));
            }
            if !identity.participants().is_empty()
                && !identity.contains(segment.built_by_player_id())
            {
                return Err(InfrastructureValidationError::TransportPlayerNotFound {
                    position: segment.coordinate(),
                    player_id: segment.built_by_player_id().clone(),
                });
            }
            if let Some(city_id) = segment.built_by_city_id()
                && !cities.iter().any(|city| city.id() == city_id)
            {
                return Err(InfrastructureValidationError::TransportCityNotFound {
                    position: segment.coordinate(),
                    city_id: city_id.clone(),
                });
            }
        }
        Ok(())
    }
}

/// Structural infrastructure-state validation failure.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum InfrastructureStateBuildError {
    /// More than one field improvement occupies a coordinate.
    DuplicateFieldImprovement(HexCoord),
}

impl core::fmt::Display for InfrastructureStateBuildError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::DuplicateFieldImprovement(coordinate) => write!(
                formatter,
                "duplicate field improvement at ({}, {})",
                coordinate.col(),
                coordinate.row()
            ),
        }
    }
}

impl std::error::Error for InfrastructureStateBuildError {}

/// Cross-section infrastructure validation failure.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum InfrastructureValidationError {
    /// A field improvement is outside the map.
    FieldImprovementOutOfBounds(HexCoord),
    /// A field improvement references an absent city.
    FieldImprovementCityNotFound {
        /// Coordinate carrying the invalid city reference.
        position: HexCoord,
        /// Referenced city.
        city_id: CityId,
    },
    /// A transport segment is outside the map.
    TransportOutOfBounds(HexCoord),
    /// A transport segment references a non-participant builder.
    TransportPlayerNotFound {
        /// Coordinate carrying the invalid player reference.
        position: HexCoord,
        /// Referenced player.
        player_id: PlayerId,
    },
    /// A transport segment references an absent city.
    TransportCityNotFound {
        /// Coordinate carrying the invalid city reference.
        position: HexCoord,
        /// Referenced city.
        city_id: CityId,
    },
}

impl core::fmt::Display for InfrastructureValidationError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::FieldImprovementOutOfBounds(position) => write!(
                formatter,
                "field improvement at ({}, {}) is outside the map",
                position.col(),
                position.row()
            ),
            Self::FieldImprovementCityNotFound { position, city_id } => write!(
                formatter,
                "field improvement at ({}, {}) references missing city {city_id}",
                position.col(),
                position.row()
            ),
            Self::TransportOutOfBounds(position) => write!(
                formatter,
                "transport segment at ({}, {}) is outside the map",
                position.col(),
                position.row()
            ),
            Self::TransportPlayerNotFound {
                position,
                player_id,
            } => write!(
                formatter,
                "transport segment at ({}, {}) references non-participant {player_id}",
                position.col(),
                position.row()
            ),
            Self::TransportCityNotFound { position, city_id } => write!(
                formatter,
                "transport segment at ({}, {}) references missing city {city_id}",
                position.col(),
                position.row()
            ),
        }
    }
}

impl std::error::Error for InfrastructureValidationError {}

#[cfg(test)]
mod tests {
    use crate::{FieldImprovementKind, HexCoord, TransportNetwork};

    use super::{FieldImprovement, InfrastructureState, InfrastructureStateBuildError};

    #[test]
    fn infrastructure_normalizes_order_and_rejects_duplicate_coordinates() {
        let mine = FieldImprovement::new(HexCoord::new(2, 1), FieldImprovementKind::Mine, None);
        let farm = FieldImprovement::new(HexCoord::new(0, 1), FieldImprovementKind::Farm, None);
        let state =
            InfrastructureState::try_new([mine.clone(), farm.clone()], TransportNetwork::default())
                .expect("infrastructure");
        assert_eq!(state.field_improvements(), &[farm.clone(), mine]);
        assert_eq!(state.field_improvement_at(farm.coordinate()), Some(&farm));

        assert_eq!(
            InfrastructureState::try_new([farm.clone(), farm], TransportNetwork::default(),),
            Err(InfrastructureStateBuildError::DuplicateFieldImprovement(
                HexCoord::new(0, 1)
            ))
        );
    }
}
