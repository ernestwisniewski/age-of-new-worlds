use crate::{ArtifactId, MovementUnits, UnitPosture};

use super::Unit;

impl Unit {
    /// Starts excavation and consumes current movement without changing unrelated state.
    #[must_use]
    pub fn after_artifact_excavation_started(&self, artifact_id: ArtifactId) -> Self {
        let mut updated = self.clone();
        updated.movement_units = MovementUnits::ZERO;
        updated.queued_path = None;
        updated.activity = updated.activity.with_artifact_excavation(Some(artifact_id));
        updated.posture = UnitPosture::Active;
        updated
    }

    /// Completes the matching excavation and begins carrying the artifact.
    #[must_use]
    pub fn after_artifact_excavation_completed(&self, artifact_id: &ArtifactId) -> Option<Self> {
        if self.activity.excavating_artifact_id() != Some(artifact_id)
            || self.carried_artifact_id.is_some()
        {
            return None;
        }
        let mut updated = self.clone();
        updated.activity = updated.activity.with_artifact_excavation(None);
        updated.carried_artifact_id = Some(artifact_id.clone());
        Some(updated)
    }

    /// Cancels only the matching excavation slot.
    #[must_use]
    pub fn after_artifact_excavation_cancelled(&self, artifact_id: &ArtifactId) -> Option<Self> {
        if self.activity.excavating_artifact_id() != Some(artifact_id) {
            return None;
        }
        let mut updated = self.clone();
        updated.activity = updated.activity.with_artifact_excavation(None);
        Some(updated)
    }

    /// Stores the matching carried artifact in a city.
    #[must_use]
    pub fn after_artifact_stored(&self, artifact_id: &ArtifactId) -> Option<Self> {
        if self.carried_artifact_id() != Some(artifact_id) {
            return None;
        }
        let mut updated = self.clone();
        updated.carried_artifact_id = None;
        Some(updated)
    }
}

#[cfg(test)]
mod tests {
    use crate::{
        ArtifactId, HexCoord, MovementUnits, PlayerId, Unit, UnitActivity, UnitId, UnitKind,
    };

    #[test]
    fn artifact_transitions_preserve_unrelated_unit_state_and_fail_closed() {
        let artifact = ArtifactId::new("artifact").expect("artifact id");
        let unit = Unit::builder(
            UnitId::new("unit").expect("unit id"),
            PlayerId::new("player").expect("player id"),
            UnitKind::Scout,
            "Scout",
            HexCoord::new(1, 2),
            MovementUnits::new(7),
        )
        .build()
        .expect("unit");
        let excavating = unit.after_artifact_excavation_started(artifact.clone());
        assert_eq!(excavating.movement_units(), MovementUnits::ZERO);
        assert_eq!(
            excavating.activity().excavating_artifact_id(),
            Some(&artifact)
        );
        assert!(
            excavating
                .after_artifact_excavation_completed(
                    &ArtifactId::new("other").expect("artifact id")
                )
                .is_none()
        );
        let carried = excavating
            .after_artifact_excavation_completed(&artifact)
            .expect("complete excavation");
        assert_eq!(carried.carried_artifact_id(), Some(&artifact));
        assert!(carried.activity().excavating_artifact_id().is_none());
        assert!(
            unit.after_artifact_excavation_cancelled(&artifact)
                .is_none()
        );
        let cancelled = excavating
            .after_artifact_excavation_cancelled(&artifact)
            .expect("cancel excavation");
        assert!(cancelled.activity().excavating_artifact_id().is_none());
        let other_artifact = ArtifactId::new("other").expect("artifact id");
        assert!(carried.after_artifact_stored(&other_artifact).is_none());
        assert!(
            carried
                .after_artifact_stored(&artifact)
                .expect("store artifact")
                .carried_artifact_id()
                .is_none()
        );

        let occupied = Unit::builder(
            UnitId::new("occupied").expect("unit id"),
            PlayerId::new("player").expect("player id"),
            UnitKind::Scout,
            "Scout",
            HexCoord::new(1, 2),
            MovementUnits::ZERO,
        )
        .with_activity(UnitActivity::new(None, None, None, Some(artifact.clone())))
        .with_carried_artifact(Some(other_artifact))
        .build()
        .expect("unit");
        assert!(
            occupied
                .after_artifact_excavation_completed(&artifact)
                .is_none()
        );
    }
}
