use aonw_domain::{ArtifactId, CityId, PlayerId, UnitId};

/// Revision-bound request to excavate the artifact at one controlled unit.
#[derive(Clone, Copy, Debug)]
pub struct StartArtifactExcavationCommand<'command> {
    expected_revision: u64,
    unit_id: &'command UnitId,
}

impl<'command> StartArtifactExcavationCommand<'command> {
    /// Constructs a current artifact-excavation command.
    #[must_use]
    pub const fn new(expected_revision: u64, unit_id: &'command UnitId) -> Self {
        Self {
            expected_revision,
            unit_id,
        }
    }

    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }

    pub(crate) const fn unit_id(self) -> &'command UnitId {
        self.unit_id
    }
}

/// Revision-bound request to store the artifact carried by one controlled unit.
#[derive(Clone, Copy, Debug)]
pub struct StoreArtifactInCityCommand<'command> {
    expected_revision: u64,
    unit_id: &'command UnitId,
    city_id: Option<&'command CityId>,
}

impl<'command> StoreArtifactInCityCommand<'command> {
    /// Constructs a storage command. An omitted city selects the city under the unit.
    #[must_use]
    pub const fn new(
        expected_revision: u64,
        unit_id: &'command UnitId,
        city_id: Option<&'command CityId>,
    ) -> Self {
        Self {
            expected_revision,
            unit_id,
            city_id,
        }
    }

    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }

    pub(crate) const fn unit_id(self) -> &'command UnitId {
        self.unit_id
    }

    pub(crate) const fn city_id(self) -> Option<&'command CityId> {
        self.city_id
    }
}

/// Current one-way artifact gift with an optional offered-gold payment.
///
/// The authenticated actor is intentionally not duplicated in this payload.
/// Requested artifacts and requested gold require a separate acceptance workflow
/// and therefore are not part of this command.
#[derive(Clone, Copy, Debug)]
pub struct TradeArtifactCommand<'command> {
    expected_revision: u64,
    target_player_id: &'command PlayerId,
    offered_artifact_id: &'command ArtifactId,
    offered_gold: i64,
}

impl<'command> TradeArtifactCommand<'command> {
    /// Constructs a current one-way artifact trade.
    #[must_use]
    pub const fn new(
        expected_revision: u64,
        target_player_id: &'command PlayerId,
        offered_artifact_id: &'command ArtifactId,
        offered_gold: i64,
    ) -> Self {
        Self {
            expected_revision,
            target_player_id,
            offered_artifact_id,
            offered_gold,
        }
    }

    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }

    pub(crate) const fn target_player_id(self) -> &'command PlayerId {
        self.target_player_id
    }

    pub(crate) const fn offered_artifact_id(self) -> &'command ArtifactId {
        self.offered_artifact_id
    }

    pub(crate) const fn offered_gold(self) -> i64 {
        self.offered_gold
    }
}
