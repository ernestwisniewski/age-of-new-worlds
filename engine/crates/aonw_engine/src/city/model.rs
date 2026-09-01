use aonw_domain::{CityId, HexCoord, UnitId};

/// Revision-bound request to schedule one city-founding job.
#[derive(Clone, Copy, Debug)]
pub struct FoundCityCommand<'command> {
    expected_revision: u64,
    founder_unit_id: &'command UnitId,
    controlled_hexes: &'command [HexCoord],
}

impl<'command> FoundCityCommand<'command> {
    /// Creates a self-contained city-founding command.
    #[must_use]
    pub const fn new(
        expected_revision: u64,
        founder_unit_id: &'command UnitId,
        controlled_hexes: &'command [HexCoord],
    ) -> Self {
        Self {
            expected_revision,
            founder_unit_id,
            controlled_hexes,
        }
    }

    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
    pub(crate) const fn founder_unit_id(self) -> &'command UnitId {
        self.founder_unit_id
    }
    pub(crate) const fn controlled_hexes(self) -> &'command [HexCoord] {
        self.controlled_hexes
    }
}

/// Revision-bound request to toggle one manually worked city hex.
#[derive(Clone, Copy, Debug)]
pub struct ToggleWorkedHexCommand<'command> {
    expected_revision: u64,
    city_id: &'command CityId,
    target: HexCoord,
}

impl<'command> ToggleWorkedHexCommand<'command> {
    /// Creates a worked-hex command.
    #[must_use]
    pub const fn new(expected_revision: u64, city_id: &'command CityId, target: HexCoord) -> Self {
        Self {
            expected_revision,
            city_id,
            target,
        }
    }

    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
    pub(crate) const fn city_id(self) -> &'command CityId {
        self.city_id
    }
    pub(crate) const fn target(self) -> HexCoord {
        self.target
    }
}

/// Revision-bound request to choose the preferred next territory expansion.
#[derive(Clone, Copy, Debug)]
pub struct SelectCityExpansionHexCommand<'command> {
    expected_revision: u64,
    city_id: &'command CityId,
    target: HexCoord,
}

impl<'command> SelectCityExpansionHexCommand<'command> {
    /// Creates an expansion-selection command.
    #[must_use]
    pub const fn new(expected_revision: u64, city_id: &'command CityId, target: HexCoord) -> Self {
        Self {
            expected_revision,
            city_id,
            target,
        }
    }

    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
    pub(crate) const fn city_id(self) -> &'command CityId {
        self.city_id
    }
    pub(crate) const fn target(self) -> HexCoord {
        self.target
    }
}

/// Revision-bound query for a founder's legal initial territory.
#[derive(Clone, Copy, Debug)]
pub struct CityFoundingOptionsQuery<'query> {
    expected_revision: u64,
    founder_unit_id: &'query UnitId,
}

impl<'query> CityFoundingOptionsQuery<'query> {
    /// Creates a founding-options query.
    #[must_use]
    pub const fn new(expected_revision: u64, founder_unit_id: &'query UnitId) -> Self {
        Self {
            expected_revision,
            founder_unit_id,
        }
    }
    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
    pub(crate) const fn founder_unit_id(self) -> &'query UnitId {
        self.founder_unit_id
    }
}

/// Engine-owned legal initial territory selection.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CityFoundingOptions {
    founder_unit_id: UnitId,
    center: HexCoord,
    selected_controlled_hexes: Box<[HexCoord]>,
    available_controlled_hexes: Box<[HexCoord]>,
    ranked_available_controlled_hexes: Box<[HexCoord]>,
    required_controlled_hexes: u32,
    maximum_radius: u32,
}

impl CityFoundingOptions {
    pub(crate) fn new(
        founder_unit_id: UnitId,
        center: HexCoord,
        selected_controlled_hexes: Vec<HexCoord>,
        available_controlled_hexes: Vec<HexCoord>,
        ranked_available_controlled_hexes: Vec<HexCoord>,
        required_controlled_hexes: u32,
        maximum_radius: u32,
    ) -> Self {
        Self {
            founder_unit_id,
            center,
            selected_controlled_hexes: selected_controlled_hexes.into_boxed_slice(),
            available_controlled_hexes: available_controlled_hexes.into_boxed_slice(),
            ranked_available_controlled_hexes: ranked_available_controlled_hexes.into_boxed_slice(),
            required_controlled_hexes,
            maximum_radius,
        }
    }
    /// Returns the founder identity.
    #[must_use]
    pub const fn founder_unit_id(&self) -> &UnitId {
        &self.founder_unit_id
    }
    /// Returns the immutable center.
    #[must_use]
    pub const fn center(&self) -> HexCoord {
        self.center
    }
    /// Returns the current canonical draft selection.
    #[must_use]
    pub const fn selected_controlled_hexes(&self) -> &[HexCoord] {
        &self.selected_controlled_hexes
    }
    /// Returns legal next selections in coordinate order.
    #[must_use]
    pub const fn available_controlled_hexes(&self) -> &[HexCoord] {
        &self.available_controlled_hexes
    }
    /// Returns the same legal selections ranked by engine-owned city value.
    #[must_use]
    pub const fn ranked_available_controlled_hexes(&self) -> &[HexCoord] {
        &self.ranked_available_controlled_hexes
    }
    /// Returns the exact required selection count.
    #[must_use]
    pub const fn required_controlled_hexes(&self) -> u32 {
        self.required_controlled_hexes
    }
    /// Returns the initial territory radius.
    #[must_use]
    pub const fn maximum_radius(&self) -> u32 {
        self.maximum_radius
    }
}

/// Revision-bound query for controlled and worked city hexes.
#[derive(Clone, Copy, Debug)]
pub struct CityWorkedHexOptionsQuery<'query> {
    expected_revision: u64,
    city_id: &'query CityId,
}

impl<'query> CityWorkedHexOptionsQuery<'query> {
    /// Creates a worked-hex query.
    #[must_use]
    pub const fn new(expected_revision: u64, city_id: &'query CityId) -> Self {
        Self {
            expected_revision,
            city_id,
        }
    }
    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
    pub(crate) const fn city_id(self) -> &'query CityId {
        self.city_id
    }
}

/// Engine-owned controlled/manual/effective worked-hex view.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CityWorkedHexOptions {
    city_id: CityId,
    center: HexCoord,
    controlled_hexes: Box<[HexCoord]>,
    available_hexes: Box<[HexCoord]>,
    selected_hexes: Box<[HexCoord]>,
    effective_hexes: Box<[HexCoord]>,
    limit: u32,
}

impl CityWorkedHexOptions {
    pub(crate) fn new(
        city_id: CityId,
        center: HexCoord,
        controlled_hexes: Vec<HexCoord>,
        selected_hexes: Vec<HexCoord>,
        effective_hexes: Vec<HexCoord>,
        limit: u32,
    ) -> Self {
        let available_hexes = if selected_hexes.len() < usize::try_from(limit).unwrap_or(usize::MAX)
        {
            controlled_hexes.clone()
        } else {
            selected_hexes.clone()
        };
        Self {
            city_id,
            center,
            available_hexes: available_hexes.into_boxed_slice(),
            controlled_hexes: controlled_hexes.into_boxed_slice(),
            selected_hexes: selected_hexes.into_boxed_slice(),
            effective_hexes: effective_hexes.into_boxed_slice(),
            limit,
        }
    }
    /// Returns the queried city.
    #[must_use]
    pub const fn city_id(&self) -> &CityId {
        &self.city_id
    }
    /// Returns the city center.
    #[must_use]
    pub const fn center(&self) -> HexCoord {
        self.center
    }
    /// Returns all controlled non-center hexes.
    #[must_use]
    pub const fn controlled_hexes(&self) -> &[HexCoord] {
        &self.controlled_hexes
    }
    /// Returns every coordinate legal for a toggle.
    #[must_use]
    pub const fn available_hexes(&self) -> &[HexCoord] {
        &self.available_hexes
    }
    /// Returns the normalized manual selection.
    #[must_use]
    pub const fn selected_hexes(&self) -> &[HexCoord] {
        &self.selected_hexes
    }
    /// Returns the manual selection plus deterministic automatic fill.
    #[must_use]
    pub const fn effective_hexes(&self) -> &[HexCoord] {
        &self.effective_hexes
    }
    /// Returns the population-based worked-hex limit.
    #[must_use]
    pub const fn limit(&self) -> u32 {
        self.limit
    }
}

/// Revision-bound query for legal preferred expansion coordinates.
#[derive(Clone, Copy, Debug)]
pub struct CityExpansionOptionsQuery<'query> {
    expected_revision: u64,
    city_id: &'query CityId,
}

impl<'query> CityExpansionOptionsQuery<'query> {
    /// Creates an expansion-options query.
    #[must_use]
    pub const fn new(expected_revision: u64, city_id: &'query CityId) -> Self {
        Self {
            expected_revision,
            city_id,
        }
    }
    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
    pub(crate) const fn city_id(self) -> &'query CityId {
        self.city_id
    }
}

/// One deterministically ranked territory expansion candidate.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct CityExpansionCandidate {
    coordinate: HexCoord,
    score: i32,
    distance: u32,
}

impl CityExpansionCandidate {
    pub(crate) const fn new(coordinate: HexCoord, score: i32, distance: u32) -> Self {
        Self {
            coordinate,
            score,
            distance,
        }
    }
    /// Returns the candidate coordinate.
    #[must_use]
    pub const fn coordinate(self) -> HexCoord {
        self.coordinate
    }
    /// Returns the current standard yield score.
    #[must_use]
    pub const fn score(self) -> i32 {
        self.score
    }
    /// Returns exact hex distance from the city center.
    #[must_use]
    pub const fn distance(self) -> u32 {
        self.distance
    }
}

/// Engine-owned preferred-expansion options.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CityExpansionOptions {
    city_id: CityId,
    controlled_hexes: Box<[HexCoord]>,
    preferred_hex: Option<HexCoord>,
    candidates: Box<[CityExpansionCandidate]>,
}

impl CityExpansionOptions {
    pub(crate) fn new(
        city_id: CityId,
        controlled_hexes: Vec<HexCoord>,
        preferred_hex: Option<HexCoord>,
        candidates: Vec<CityExpansionCandidate>,
    ) -> Self {
        Self {
            city_id,
            controlled_hexes: controlled_hexes.into_boxed_slice(),
            preferred_hex,
            candidates: candidates.into_boxed_slice(),
        }
    }
    /// Returns the queried city.
    #[must_use]
    pub const fn city_id(&self) -> &CityId {
        &self.city_id
    }
    /// Returns controlled non-center coordinates in canonical order.
    #[must_use]
    pub const fn controlled_hexes(&self) -> &[HexCoord] {
        &self.controlled_hexes
    }
    /// Returns the selected preference when still persisted.
    #[must_use]
    pub const fn preferred_hex(&self) -> Option<HexCoord> {
        self.preferred_hex
    }
    /// Returns legal candidates in deterministic rank order.
    #[must_use]
    pub const fn candidates(&self) -> &[CityExpansionCandidate] {
        &self.candidates
    }
}

#[cfg(test)]
mod tests {
    use aonw_domain::{CityId, HexCoord, UnitId};

    use super::{CityExpansionOptions, CityFoundingOptions, CityWorkedHexOptions};

    #[test]
    fn city_option_views_expose_their_stable_identity_and_location() {
        let founder_id = UnitId::new("founder").expect("unit id");
        let founding = CityFoundingOptions::new(
            founder_id.clone(),
            HexCoord::new(1, 2),
            Vec::new(),
            Vec::new(),
            Vec::new(),
            0,
            0,
        );
        assert_eq!(founding.founder_unit_id(), &founder_id);

        let city_id = CityId::new("city").expect("city id");
        let worked = CityWorkedHexOptions::new(
            city_id.clone(),
            HexCoord::new(2, 3),
            Vec::new(),
            Vec::new(),
            Vec::new(),
            0,
        );
        assert_eq!(worked.city_id(), &city_id);
        assert_eq!(worked.center(), HexCoord::new(2, 3));

        let expansion = CityExpansionOptions::new(city_id.clone(), Vec::new(), None, Vec::new());
        assert_eq!(expansion.city_id(), &city_id);
        assert_eq!(expansion.preferred_hex(), None);
    }
}
