use aonw_domain::{
    City, CityBuildingType, CityFoundingDraft, CityId, CityProductionQueue, CitySpecializationType,
    FogVisibility, GameState, HexCoord, PlayerId, UnitId, WonderType,
};

/// Complete city state visible only to the owning recipient.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct OwnedCityDetailsView {
    population: i64,
    stored_food: i64,
    max_hexes: i64,
    territory_radius: i64,
    worked_hexes: Box<[HexCoord]>,
    buildings: Box<[CityBuildingType]>,
    wonders: Box<[WonderType]>,
    production_queue: Option<CityProductionQueue>,
    production_overflow: i64,
    specialization: Option<CitySpecializationType>,
    preferred_expansion_hex: Option<HexCoord>,
}

impl OwnedCityDetailsView {
    /// Returns current population.
    #[must_use]
    pub const fn population(&self) -> i64 {
        self.population
    }
    /// Returns stored food.
    #[must_use]
    pub const fn stored_food(&self) -> i64 {
        self.stored_food
    }
    /// Returns current territory capacity.
    #[must_use]
    pub const fn max_hexes(&self) -> i64 {
        self.max_hexes
    }
    /// Returns current territory radius.
    #[must_use]
    pub const fn territory_radius(&self) -> i64 {
        self.territory_radius
    }
    /// Returns canonical manual worked coordinates.
    #[must_use]
    pub const fn worked_hexes(&self) -> &[HexCoord] {
        &self.worked_hexes
    }
    /// Returns constructed buildings in stable order.
    #[must_use]
    pub const fn buildings(&self) -> &[CityBuildingType] {
        &self.buildings
    }
    /// Returns constructed wonders in stable order.
    #[must_use]
    pub const fn wonders(&self) -> &[WonderType] {
        &self.wonders
    }
    /// Returns the current production queue.
    #[must_use]
    pub const fn production_queue(&self) -> Option<&CityProductionQueue> {
        self.production_queue.as_ref()
    }
    /// Returns stored production overflow.
    #[must_use]
    pub const fn production_overflow(&self) -> i64 {
        self.production_overflow
    }
    /// Returns the current city specialization.
    #[must_use]
    pub const fn specialization(&self) -> Option<CitySpecializationType> {
        self.specialization
    }
    /// Returns the private preferred expansion coordinate.
    #[must_use]
    pub const fn preferred_expansion_hex(&self) -> Option<HexCoord> {
        self.preferred_expansion_hex
    }
}

/// Recipient-safe current city projection.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerCityView {
    id: CityId,
    owner_player_id: PlayerId,
    name: Box<str>,
    center: HexCoord,
    visible_controlled_hexes: Box<[HexCoord]>,
    hit_points: Option<i64>,
    owned_details: Option<OwnedCityDetailsView>,
}

impl PlayerCityView {
    fn from_city(city: &City, state: &GameState, actor: &PlayerId) -> Self {
        let owned = city.owner_player_id() == actor;
        let visible_controlled_hexes = city
            .controlled_hexes()
            .iter()
            .copied()
            .filter(|coordinate| {
                owned || state.fog_of_war().visibility(actor, *coordinate) != FogVisibility::Hidden
            })
            .collect::<Vec<_>>();
        let owned_details = owned.then(|| {
            let mut worked_hexes = city.worked_hexes().to_vec();
            worked_hexes.sort_unstable();
            OwnedCityDetailsView {
                population: city.population(),
                stored_food: city.stored_food(),
                max_hexes: city.max_hexes(),
                territory_radius: city.territory_radius(),
                worked_hexes: worked_hexes.into_boxed_slice(),
                buildings: city.buildings().iter().copied().collect(),
                wonders: city.wonders().iter().copied().collect(),
                production_queue: city.production_queue().cloned(),
                production_overflow: city.production_overflow(),
                specialization: city.specialization(),
                preferred_expansion_hex: city.preferred_expansion_hex(),
            }
        });
        Self {
            id: city.id().clone(),
            owner_player_id: city.owner_player_id().clone(),
            name: city.name().into(),
            center: city.center(),
            visible_controlled_hexes: visible_controlled_hexes.into_boxed_slice(),
            hit_points: city.hit_points(),
            owned_details,
        }
    }

    /// Returns city identity.
    #[must_use]
    pub const fn id(&self) -> &CityId {
        &self.id
    }
    /// Returns visible owner identity.
    #[must_use]
    pub const fn owner_player_id(&self) -> &PlayerId {
        &self.owner_player_id
    }
    /// Returns the public name.
    #[must_use]
    pub fn name(&self) -> &str {
        &self.name
    }
    /// Returns the public center.
    #[must_use]
    pub const fn center(&self) -> HexCoord {
        self.center
    }
    /// Returns controlled coordinates discovered by this recipient.
    #[must_use]
    pub const fn visible_controlled_hexes(&self) -> &[HexCoord] {
        &self.visible_controlled_hexes
    }
    /// Returns public combat health when present.
    #[must_use]
    pub const fn hit_points(&self) -> Option<i64> {
        self.hit_points
    }
    /// Returns complete private state only for an owned city.
    #[must_use]
    pub const fn owned_details(&self) -> Option<&OwnedCityDetailsView> {
        self.owned_details.as_ref()
    }
}

/// Recipient-owned city-founding workflow.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CityFoundingDraftView {
    founder_unit_id: UnitId,
    center: HexCoord,
    controlled_hexes: Box<[HexCoord]>,
}

impl CityFoundingDraftView {
    fn from_draft(draft: &CityFoundingDraft) -> Self {
        let mut controlled_hexes = draft.controlled_hexes().to_vec();
        controlled_hexes.sort_unstable();
        Self {
            founder_unit_id: draft.unit_id().clone(),
            center: draft.center(),
            controlled_hexes: controlled_hexes.into_boxed_slice(),
        }
    }
    /// Returns founder identity.
    #[must_use]
    pub const fn founder_unit_id(&self) -> &UnitId {
        &self.founder_unit_id
    }
    /// Returns the immutable center.
    #[must_use]
    pub const fn center(&self) -> HexCoord {
        self.center
    }
    /// Returns canonical current selection.
    #[must_use]
    pub const fn controlled_hexes(&self) -> &[HexCoord] {
        &self.controlled_hexes
    }
}

pub(crate) fn visible_cities(state: &GameState, actor: &PlayerId) -> Vec<PlayerCityView> {
    state
        .cities()
        .iter()
        .filter(|city| {
            city.owner_player_id() == actor
                || state.fog_of_war().visibility(actor, city.center()) != FogVisibility::Hidden
        })
        .map(|city| PlayerCityView::from_city(city, state, actor))
        .collect()
}

pub(crate) fn city_founding_draft(
    state: &GameState,
    actor: &PlayerId,
) -> Option<CityFoundingDraftView> {
    state
        .interaction()
        .city_founding_draft()
        .filter(|draft| draft.owner_player_id() == actor)
        .map(CityFoundingDraftView::from_draft)
}
