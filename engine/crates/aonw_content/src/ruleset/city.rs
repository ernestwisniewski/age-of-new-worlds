use aonw_domain::PlayerCountry;
use serde::Serialize;

/// Immutable city-founding and territory progression rules.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CityBalance {
    pub(super) founding_controlled_hexes: u32,
    pub(super) founding_max_radius: u32,
    pub(super) minimum_center_distance: u32,
    pub(super) founding_turns: u32,
    pub(super) start_population: i64,
    pub(super) start_stored_food: i64,
    pub(super) start_max_hexes: i64,
    pub(super) mid_game_max_hexes: i64,
    pub(super) late_game_max_hexes: i64,
    pub(super) start_territory_radius: i64,
    pub(super) expanded_territory_radius: i64,
    pub(super) worked_hex_limit_base: i64,
    pub(super) worked_hexes_per_population: i64,
}

impl CityBalance {
    /// Returns the exact number of non-center hexes required to found a city.
    #[must_use]
    pub const fn founding_controlled_hexes(self) -> u32 {
        self.founding_controlled_hexes
    }
    /// Returns the maximum radius of an initial territory selection.
    #[must_use]
    pub const fn founding_max_radius(self) -> u32 {
        self.founding_max_radius
    }
    /// Returns the minimum distance between city centers.
    #[must_use]
    pub const fn minimum_center_distance(self) -> u32 {
        self.minimum_center_distance
    }
    /// Returns the number of turn advances required to complete founding.
    #[must_use]
    pub const fn founding_turns(self) -> u32 {
        self.founding_turns
    }
    /// Returns initial population.
    #[must_use]
    pub const fn start_population(self) -> i64 {
        self.start_population
    }
    /// Returns initial stored food.
    #[must_use]
    pub const fn start_stored_food(self) -> i64 {
        self.start_stored_food
    }
    /// Returns initial territory capacity.
    #[must_use]
    pub const fn start_max_hexes(self) -> i64 {
        self.start_max_hexes
    }
    /// Returns the territory capacity reached at population six.
    #[must_use]
    pub const fn mid_game_max_hexes(self) -> i64 {
        self.mid_game_max_hexes
    }
    /// Returns the territory capacity reached at population ten.
    #[must_use]
    pub const fn late_game_max_hexes(self) -> i64 {
        self.late_game_max_hexes
    }
    /// Returns initial territory radius.
    #[must_use]
    pub const fn start_territory_radius(self) -> i64 {
        self.start_territory_radius
    }
    /// Returns the territory radius reached at population ten.
    #[must_use]
    pub const fn expanded_territory_radius(self) -> i64 {
        self.expanded_territory_radius
    }
    /// Computes the number of manually worked non-center hexes.
    #[must_use]
    pub fn worked_hex_limit(self, population: i64) -> u32 {
        let value = self
            .worked_hex_limit_base
            .saturating_add(population.saturating_mul(self.worked_hexes_per_population));
        u32::try_from(value.max(0)).unwrap_or(u32::MAX)
    }
}

/// Ordered country-specific canonical city names.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CityNameSet {
    pub(super) country: PlayerCountryValue,
    pub(super) names: &'static [&'static str],
}

impl CityNameSet {
    /// Returns country identity.
    #[must_use]
    pub const fn country(self) -> PlayerCountry {
        self.country.domain()
    }

    /// Returns names in canonical founding sequence.
    #[must_use]
    pub const fn names(self) -> &'static [&'static str] {
        self.names
    }
}

/// Stable serialized country identity owned by ruleset canonicalization.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub(super) enum PlayerCountryValue {
    Poland,
    Ukraine,
    Germany,
    France,
    UnitedKingdom,
    Italy,
    Spain,
    Netherlands,
    Sweden,
    Russia,
    UnitedStates,
    Canada,
    China,
    Korea,
    Japan,
    Portugal,
    India,
    Brazil,
    Indonesia,
    Mexico,
    Turkey,
    SaudiArabia,
    Egypt,
    Greece,
}

impl PlayerCountryValue {
    const fn domain(self) -> PlayerCountry {
        match self {
            Self::Poland => PlayerCountry::Poland,
            Self::Ukraine => PlayerCountry::Ukraine,
            Self::Germany => PlayerCountry::Germany,
            Self::France => PlayerCountry::France,
            Self::UnitedKingdom => PlayerCountry::UnitedKingdom,
            Self::Italy => PlayerCountry::Italy,
            Self::Spain => PlayerCountry::Spain,
            Self::Netherlands => PlayerCountry::Netherlands,
            Self::Sweden => PlayerCountry::Sweden,
            Self::Russia => PlayerCountry::Russia,
            Self::UnitedStates => PlayerCountry::UnitedStates,
            Self::Canada => PlayerCountry::Canada,
            Self::China => PlayerCountry::China,
            Self::Korea => PlayerCountry::Korea,
            Self::Japan => PlayerCountry::Japan,
            Self::Portugal => PlayerCountry::Portugal,
            Self::India => PlayerCountry::India,
            Self::Brazil => PlayerCountry::Brazil,
            Self::Indonesia => PlayerCountry::Indonesia,
            Self::Mexico => PlayerCountry::Mexico,
            Self::Turkey => PlayerCountry::Turkey,
            Self::SaudiArabia => PlayerCountry::SaudiArabia,
            Self::Egypt => PlayerCountry::Egypt,
            Self::Greece => PlayerCountry::Greece,
        }
    }
}
