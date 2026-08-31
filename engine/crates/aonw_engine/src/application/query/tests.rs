use super::CanonicalQueryError;
use crate::{CommandRejectionCode, MovementLogisticsError, TerrainMovementQueryError};

#[test]
fn canonical_query_error_formats_and_codes_every_source_family() {
    let errors = [
        CanonicalQueryError::Combat(CommandRejectionCode::AttackTargetNotFound),
        CanonicalQueryError::Rejected(TerrainMovementQueryError::UnitNotFound),
        CanonicalQueryError::Logistics(MovementLogisticsError::new(
            CommandRejectionCode::UnitNotScout,
        )),
    ];
    for error in errors {
        assert!(!error.code().is_empty());
        assert!(!error.to_string().is_empty());
    }
}
