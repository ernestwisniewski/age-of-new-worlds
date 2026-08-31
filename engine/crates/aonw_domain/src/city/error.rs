use crate::HexCoord;

use super::{CityBuildingType, WonderType};

/// Structural complete-city validation failure.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum CityBuildError {
    /// Population must remain positive while a city exists.
    NonPositivePopulation(i64),
    /// Stored food cannot be negative.
    NegativeStoredFood(i64),
    /// Territory capacity must remain positive.
    NonPositiveMaxHexes(i64),
    /// A completion effect cannot reduce territory capacity.
    NegativeMaxHexesDelta(i64),
    /// Applying a completion effect exceeded the canonical integer range.
    MaxHexesOverflow,
    /// Territory radius cannot be negative.
    NegativeTerritoryRadius(i64),
    /// Persisted production overflow cannot be negative.
    NegativeProductionOverflow(i64),
    /// Persisted combat health must be positive when present.
    NonPositiveHitPoints(i64),
    /// A controlled coordinate occurred more than once.
    DuplicateControlledHex(HexCoord),
    /// The city center was repeated in controlled coordinates.
    CenterInControlledHexes,
    /// A worked coordinate occurred more than once.
    DuplicateWorkedHex(HexCoord),
    /// A worked coordinate was not a non-center controlled coordinate.
    WorkedHexNotControlled(HexCoord),
    /// A building identity occurred more than once.
    DuplicateBuilding(CityBuildingType),
    /// A wonder identity occurred more than once.
    DuplicateWonder(WonderType),
}

impl core::fmt::Display for CityBuildError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::NonPositivePopulation(value) => {
                write!(formatter, "city population must be positive, got {value}")
            }
            Self::NegativeStoredFood(value) => {
                write!(formatter, "stored food cannot be negative, got {value}")
            }
            Self::NonPositiveMaxHexes(value) => {
                write!(formatter, "city max hexes must be positive, got {value}")
            }
            Self::NegativeMaxHexesDelta(value) => {
                write!(
                    formatter,
                    "city max hexes delta cannot be negative, got {value}"
                )
            }
            Self::MaxHexesOverflow => formatter.write_str("city max hexes overflow"),
            Self::NegativeTerritoryRadius(value) => {
                write!(
                    formatter,
                    "territory radius cannot be negative, got {value}"
                )
            }
            Self::NegativeProductionOverflow(value) => {
                write!(
                    formatter,
                    "production overflow cannot be negative, got {value}"
                )
            }
            Self::NonPositiveHitPoints(value) => {
                write!(formatter, "city hit points must be positive, got {value}")
            }
            Self::DuplicateControlledHex(value) => write!(
                formatter,
                "duplicate controlled hex: ({}, {})",
                value.col(),
                value.row()
            ),
            Self::CenterInControlledHexes => {
                formatter.write_str("city center must not be repeated in controlled hexes")
            }
            Self::DuplicateWorkedHex(value) => write!(
                formatter,
                "duplicate worked hex: ({}, {})",
                value.col(),
                value.row()
            ),
            Self::WorkedHexNotControlled(value) => write!(
                formatter,
                "worked hex is not controlled: ({}, {})",
                value.col(),
                value.row()
            ),
            Self::DuplicateBuilding(value) => write!(formatter, "duplicate building: {value:?}"),
            Self::DuplicateWonder(value) => write!(formatter, "duplicate wonder: {value:?}"),
        }
    }
}

impl std::error::Error for CityBuildError {}
