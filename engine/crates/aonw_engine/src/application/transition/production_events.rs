use aonw_domain::{CityBuildingType, CityId, PlayerId, TechnologyId, UnitId, UnitKind, WonderType};

/// Accepted fact that one city completed a building.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CityBuiltBuildingEvent {
    city_id: CityId,
    building: CityBuildingType,
}

impl CityBuiltBuildingEvent {
    pub(crate) const fn new(city_id: CityId, building: CityBuildingType) -> Self {
        Self { city_id, building }
    }
    /// Returns the hosting city.
    #[must_use]
    pub const fn city_id(&self) -> &CityId {
        &self.city_id
    }
    /// Returns the completed building.
    #[must_use]
    pub const fn building(&self) -> CityBuildingType {
        self.building
    }
}

/// Accepted fact that one city produced a unit.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CityProducedUnitEvent {
    city_id: CityId,
    unit: UnitKind,
    produced_unit_id: UnitId,
}

impl CityProducedUnitEvent {
    pub(crate) const fn new(city_id: CityId, unit: UnitKind, produced_unit_id: UnitId) -> Self {
        Self {
            city_id,
            unit,
            produced_unit_id,
        }
    }
    /// Returns the producing city.
    #[must_use]
    pub const fn city_id(&self) -> &CityId {
        &self.city_id
    }
    /// Returns the produced unit kind.
    #[must_use]
    pub const fn unit(&self) -> UnitKind {
        self.unit
    }
    /// Returns the deterministic produced unit identity.
    #[must_use]
    pub const fn produced_unit_id(&self) -> &UnitId {
        &self.produced_unit_id
    }
}

/// Accepted fact that one city won a world-wonder race.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CityBuiltWonderEvent {
    city_id: CityId,
    owner_player_id: PlayerId,
    wonder: WonderType,
}

impl CityBuiltWonderEvent {
    pub(crate) const fn new(
        city_id: CityId,
        owner_player_id: PlayerId,
        wonder: WonderType,
    ) -> Self {
        Self {
            city_id,
            owner_player_id,
            wonder,
        }
    }
    /// Returns the hosting city.
    #[must_use]
    pub const fn city_id(&self) -> &CityId {
        &self.city_id
    }
    /// Returns the winner.
    #[must_use]
    pub const fn owner_player_id(&self) -> &PlayerId {
        &self.owner_player_id
    }
    /// Returns the completed wonder.
    #[must_use]
    pub const fn wonder(&self) -> WonderType {
        self.wonder
    }
}

/// Accepted fact that a losing wonder queue was converted to overflow.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct WonderProductionRefundedEvent {
    city_id: CityId,
    owner_player_id: PlayerId,
    wonder: WonderType,
    refunded_production: i64,
}

impl WonderProductionRefundedEvent {
    pub(crate) const fn new(
        city_id: CityId,
        owner_player_id: PlayerId,
        wonder: WonderType,
        refunded_production: i64,
    ) -> Self {
        Self {
            city_id,
            owner_player_id,
            wonder,
            refunded_production,
        }
    }
    /// Returns the refunded city.
    #[must_use]
    pub const fn city_id(&self) -> &CityId {
        &self.city_id
    }
    /// Returns the queue owner.
    #[must_use]
    pub const fn owner_player_id(&self) -> &PlayerId {
        &self.owner_player_id
    }
    /// Returns the lost wonder race.
    #[must_use]
    pub const fn wonder(&self) -> WonderType {
        self.wonder
    }
    /// Returns production transferred to city overflow.
    #[must_use]
    pub const fn refunded_production(&self) -> i64 {
        self.refunded_production
    }
}

/// Accepted fact that a completion effect unlocked the selected technology.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct TechnologyResearchedEvent {
    player_id: PlayerId,
    technology: TechnologyId,
}

impl TechnologyResearchedEvent {
    pub(crate) const fn new(player_id: PlayerId, technology: TechnologyId) -> Self {
        Self {
            player_id,
            technology,
        }
    }
    /// Returns the research owner.
    #[must_use]
    pub const fn player_id(&self) -> &PlayerId {
        &self.player_id
    }
    /// Returns the unlocked technology.
    #[must_use]
    pub const fn technology(&self) -> TechnologyId {
        self.technology
    }
}

#[cfg(test)]
mod tests {
    use aonw_domain::{
        CityBuildingType, CityId, PlayerId, TechnologyId, UnitId, UnitKind, WonderType,
    };

    use super::{
        CityBuiltBuildingEvent, CityBuiltWonderEvent, CityProducedUnitEvent,
        TechnologyResearchedEvent, WonderProductionRefundedEvent,
    };

    #[test]
    fn production_events_expose_every_authoritative_field() {
        let city = CityId::new("city").expect("city");
        let player = PlayerId::new("player").expect("player");
        let unit = UnitId::new("unit").expect("unit");
        let building = CityBuiltBuildingEvent::new(city.clone(), CityBuildingType::Workshop);
        assert_eq!(building.city_id(), &city);
        assert_eq!(building.building(), CityBuildingType::Workshop);

        let produced = CityProducedUnitEvent::new(city.clone(), UnitKind::Warrior, unit.clone());
        assert_eq!(produced.city_id(), &city);
        assert_eq!(produced.unit(), UnitKind::Warrior);
        assert_eq!(produced.produced_unit_id(), &unit);

        let wonder =
            CityBuiltWonderEvent::new(city.clone(), player.clone(), WonderType::GreatLibrary);
        assert_eq!(wonder.city_id(), &city);
        assert_eq!(wonder.owner_player_id(), &player);
        assert_eq!(wonder.wonder(), WonderType::GreatLibrary);

        let refund = WonderProductionRefundedEvent::new(
            city.clone(),
            player.clone(),
            WonderType::GreatLibrary,
            17,
        );
        assert_eq!(refund.city_id(), &city);
        assert_eq!(refund.owner_player_id(), &player);
        assert_eq!(refund.wonder(), WonderType::GreatLibrary);
        assert_eq!(refund.refunded_production(), 17);

        let technology = TechnologyResearchedEvent::new(player.clone(), TechnologyId::Writing);
        assert_eq!(technology.player_id(), &player);
        assert_eq!(technology.technology(), TechnologyId::Writing);
    }
}
