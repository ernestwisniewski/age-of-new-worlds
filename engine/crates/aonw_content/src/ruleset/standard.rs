use aonw_domain::MovementUnits;

use crate::{ScienceBalance, TechnologyCostBalance, technology::STANDARD_TECHNOLOGIES};

use super::{
    CityBalance, CityNameSet, CombatBalance, CombatStats, EconomyBalance, PlayerCountryValue,
    ProductionBalance, RulesetDefinition, UnitCapabilities, UnitDefinition, UnitKindValue,
    UnitMovementDomainValue, UnitOccupancyPolicyValue,
};

mod units;

pub(super) use units::STANDARD_UNITS;

const fn names(country: PlayerCountryValue, values: &'static [&'static str]) -> CityNameSet {
    CityNameSet {
        country,
        names: values,
    }
}

const fn caps(domain: UnitMovementDomainValue, flags: u8) -> UnitCapabilities {
    UnitCapabilities {
        movement_domain: domain,
        flags,
    }
}

const fn stats(
    attack: i32,
    defense: i32,
    hit_points: u32,
    range: u32,
    mobility: u32,
) -> CombatStats {
    CombatStats {
        attack,
        defense,
        hit_points,
        range,
        mobility,
    }
}

const fn unit(
    kind: UnitKindValue,
    points: u32,
    score_value: u32,
    capabilities: UnitCapabilities,
    combat: CombatStats,
) -> UnitDefinition {
    UnitDefinition {
        kind,
        maximum_movement_units: points * MovementUnits::PER_POINT,
        artifact_movement_units: 2 * MovementUnits::PER_POINT,
        score_value,
        capabilities,
        combat,
    }
}

const PRODUCIBLE: u8 = UnitCapabilities::PRODUCIBLE;
const EXPERIENCE: u8 = UnitCapabilities::GAINS_EXPERIENCE;
const MILITARY: u8 = UnitCapabilities::MILITARY;
const RECON: u8 = UnitCapabilities::RECON;
const TRADE: u8 = UnitCapabilities::USES_TRADE_ROUTES;
const LAND_MILITARY: UnitCapabilities = caps(
    UnitMovementDomainValue::Land,
    PRODUCIBLE | EXPERIENCE | MILITARY,
);
const LAND_CIVILIAN: UnitCapabilities = caps(UnitMovementDomainValue::Land, PRODUCIBLE);
const LAND_RECON: UnitCapabilities = caps(
    UnitMovementDomainValue::Land,
    PRODUCIBLE | EXPERIENCE | MILITARY | RECON,
);
const NAVAL_MILITARY: UnitCapabilities = caps(
    UnitMovementDomainValue::Naval,
    PRODUCIBLE | EXPERIENCE | MILITARY,
);
const NAVAL_RECON: UnitCapabilities = caps(
    UnitMovementDomainValue::Naval,
    PRODUCIBLE | EXPERIENCE | MILITARY | RECON,
);
const AIR_RECON: UnitCapabilities = caps(
    UnitMovementDomainValue::Air,
    PRODUCIBLE | EXPERIENCE | MILITARY | RECON,
);

pub(super) static STANDARD_RULESET: RulesetDefinition = RulesetDefinition {
    schema_version: 1,
    ruleset_id: "aonw-standard",
    occupancy_policy: UnitOccupancyPolicyValue::FriendlyStacking,
    combat: CombatBalance {
        variance: 2,
        ranged_retaliation_percent: 50,
        retreat_threshold_percent: 25,
        defended_city_unit_defense_bonus: 1,
        mixed_commander_army_attack_bonus: 1,
        city: stats(0, 2, 16, 1, 0),
    },
    city: CityBalance {
        founding_controlled_hexes: 2,
        founding_max_radius: 2,
        minimum_center_distance: 3,
        founding_turns: 1,
        start_population: 3,
        start_stored_food: 0,
        start_max_hexes: 6,
        mid_game_max_hexes: 8,
        late_game_max_hexes: 10,
        start_territory_radius: 2,
        expanded_territory_radius: 3,
        worked_hex_limit_base: 0,
        worked_hexes_per_population: 1,
    },
    diplomacy: super::DiplomacyBalance::STANDARD,
    economy: EconomyBalance::STANDARD,
    outcome: super::OutcomeBalance::STANDARD,
    production: ProductionBalance::STANDARD,
    worker: super::WorkerBalance::STANDARD,
    city_name_sets: &STANDARD_CITY_NAMES,
    unit_definitions: &STANDARD_UNITS,
    science_balance: ScienceBalance::STANDARD,
    technology_cost_balance: TechnologyCostBalance::STANDARD,
    technology_definitions: &STANDARD_TECHNOLOGIES,
};

const STANDARD_CITY_NAMES: [CityNameSet; 24] = [
    names(
        PlayerCountryValue::Poland,
        &[
            "Warszawa",
            "Krakow",
            "Gdansk",
            "Wroclaw",
            "Poznan",
            "Lublin",
            "Katowice",
            "Torun",
            "Poniatowa",
        ],
    ),
    names(
        PlayerCountryValue::Ukraine,
        &[
            "Kyiv",
            "Lviv",
            "Odesa",
            "Kharkiv",
            "Dnipro",
            "Zaporizhzhia",
            "Donetsk",
            "Krym",
        ],
    ),
    names(
        PlayerCountryValue::Germany,
        &[
            "Berlin",
            "Hamburg",
            "Munich",
            "Cologne",
            "Frankfurt",
            "Dresden",
            "Bremen",
            "Leipzig",
        ],
    ),
    names(
        PlayerCountryValue::France,
        &[
            "Paris",
            "Lyon",
            "Marseille",
            "Bordeaux",
            "Toulouse",
            "Nantes",
            "Strasbourg",
            "Lille",
        ],
    ),
    names(
        PlayerCountryValue::UnitedKingdom,
        &[
            "London",
            "Edinburgh",
            "Cardiff",
            "Belfast",
            "Manchester",
            "Liverpool",
            "York",
            "Bristol",
        ],
    ),
    names(
        PlayerCountryValue::Italy,
        &[
            "Rome", "Milan", "Venice", "Florence", "Naples", "Turin", "Genoa", "Bologna",
        ],
    ),
    names(
        PlayerCountryValue::Spain,
        &[
            "Madrid",
            "Barcelona",
            "Valencia",
            "Seville",
            "Granada",
            "Bilbao",
            "Zaragoza",
            "Toledo",
        ],
    ),
    names(
        PlayerCountryValue::Netherlands,
        &[
            "Amsterdam",
            "Rotterdam",
            "Utrecht",
            "The Hague",
            "Eindhoven",
            "Groningen",
            "Haarlem",
            "Leiden",
        ],
    ),
    names(
        PlayerCountryValue::Sweden,
        &[
            "Stockholm",
            "Gothenburg",
            "Malmo",
            "Uppsala",
            "Lund",
            "Umea",
            "Vasteras",
            "Orebro",
        ],
    ),
    names(
        PlayerCountryValue::Russia,
        &[
            "Moscow",
            "Saint Petersburg",
            "Novgorod",
            "Kazan",
            "Smolensk",
            "Yaroslavl",
            "Vladimir",
            "Tver",
        ],
    ),
    names(
        PlayerCountryValue::UnitedStates,
        &[
            "Washington",
            "New York",
            "Boston",
            "Philadelphia",
            "Chicago",
            "San Francisco",
            "Atlanta",
            "Seattle",
        ],
    ),
    names(
        PlayerCountryValue::Canada,
        &[
            "Ottawa",
            "Toronto",
            "Montreal",
            "Vancouver",
            "Quebec City",
            "Calgary",
            "Halifax",
            "Winnipeg",
        ],
    ),
    names(
        PlayerCountryValue::China,
        &[
            "Beijing",
            "Shanghai",
            "Nanjing",
            "Guangzhou",
            "Chengdu",
            "Xi'an",
            "Hangzhou",
            "Wuhan",
        ],
    ),
    names(
        PlayerCountryValue::Korea,
        &[
            "Seoul", "Busan", "Incheon", "Daegu", "Daejeon", "Gwangju", "Suwon", "Jeonju",
        ],
    ),
    names(
        PlayerCountryValue::Japan,
        &[
            "Tokyo",
            "Kyoto",
            "Osaka",
            "Nara",
            "Yokohama",
            "Nagoya",
            "Hiroshima",
            "Sapporo",
        ],
    ),
    names(
        PlayerCountryValue::Portugal,
        &[
            "Lisbon",
            "Porto",
            "Coimbra",
            "Braga",
            "Faro",
            "Evora",
            "Guimaraes",
            "Aveiro",
        ],
    ),
    names(
        PlayerCountryValue::India,
        &[
            "Delhi",
            "Mumbai",
            "Kolkata",
            "Chennai",
            "Bengaluru",
            "Hyderabad",
            "Jaipur",
            "Varanasi",
        ],
    ),
    names(
        PlayerCountryValue::Brazil,
        &[
            "Brasilia",
            "Rio de Janeiro",
            "Sao Paulo",
            "Salvador",
            "Recife",
            "Manaus",
            "Belo Horizonte",
            "Curitiba",
        ],
    ),
    names(
        PlayerCountryValue::Indonesia,
        &[
            "Jakarta",
            "Surabaya",
            "Bandung",
            "Medan",
            "Yogyakarta",
            "Makassar",
            "Denpasar",
            "Palembang",
        ],
    ),
    names(
        PlayerCountryValue::Mexico,
        &[
            "Mexico City",
            "Guadalajara",
            "Monterrey",
            "Puebla",
            "Oaxaca",
            "Veracruz",
            "Merida",
            "Tenochtitlan",
        ],
    ),
    names(
        PlayerCountryValue::Turkey,
        &[
            "Ankara", "Istanbul", "Izmir", "Bursa", "Konya", "Antalya", "Edirne", "Kayseri",
        ],
    ),
    names(
        PlayerCountryValue::SaudiArabia,
        &[
            "Riyadh", "Jeddah", "Mecca", "Medina", "Dammam", "Taif", "Tabuk", "Diriyah",
        ],
    ),
    names(
        PlayerCountryValue::Egypt,
        &[
            "Cairo",
            "Alexandria",
            "Memphis",
            "Thebes",
            "Giza",
            "Luxor",
            "Aswan",
            "Heliopolis",
        ],
    ),
    names(
        PlayerCountryValue::Greece,
        &[
            "Athens", "Sparta", "Corinth", "Thebes", "Argos", "Rhodes", "Delphi", "Knossos",
        ],
    ),
];
