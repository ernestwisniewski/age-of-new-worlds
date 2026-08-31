use super::{
    BOOST_DISCOUNT, Boost, BoostCondition, Building, Effect, Era, Improvement, Key, Resource, Tech,
    Unit, Unlock, Wonder,
};

pub(super) const TECHNOLOGIES: [Tech; 15] = [
    Tech::new(
        Key::Agriculture,
        Era::Foundation,
        6,
        &[],
        &[
            Unlock::Improvement(Improvement::Farm),
            Unlock::Improvement(Improvement::RiverFarm),
            Unlock::Improvement(Improvement::Orchard),
        ],
        &[],
        &[Boost::new(
            BoostCondition::ControlsAnyResource {
                resources: &[Resource::Wheat, Resource::Rice],
            },
            BOOST_DISCOUNT,
        )],
    ),
    Tech::new(
        Key::Woodworking,
        Era::Settlement,
        6,
        &[Key::Mining],
        &[Unlock::Improvement(Improvement::LumberMill)],
        &[],
        &[],
    ),
    Tech::new(
        Key::Mining,
        Era::Foundation,
        6,
        &[],
        &[
            Unlock::Improvement(Improvement::Mine),
            Unlock::Improvement(Improvement::ProspectorCamp),
        ],
        &[],
        &[Boost::new(
            BoostCondition::ControlsAnyResource {
                resources: &[Resource::Iron, Resource::Marble],
            },
            BOOST_DISCOUNT,
        )],
    ),
    Tech::new(
        Key::AnimalHusbandry,
        Era::Settlement,
        6,
        &[Key::Agriculture],
        &[
            Unlock::Improvement(Improvement::Pasture),
            Unlock::ResourceVisibility(Resource::Horses),
        ],
        &[],
        &[],
    ),
    Tech::new(
        Key::Hunting,
        Era::Foundation,
        7,
        &[],
        &[
            Unlock::Improvement(Improvement::Camp),
            Unlock::Unit(Unit::Archer),
        ],
        &[],
        &[],
    ),
    Tech::new(
        Key::Fishing,
        Era::Settlement,
        6,
        &[Key::Hunting],
        &[Unlock::Improvement(Improvement::FishingBoats)],
        &[],
        &[Boost::new(
            BoostCondition::ControlsAnyResource {
                resources: &[Resource::Fish],
            },
            BOOST_DISCOUNT,
        )],
    ),
    Tech::new(
        Key::Craftsmanship,
        Era::Settlement,
        7,
        &[Key::Mining],
        &[Unlock::Building(Building::Workshop)],
        &[],
        &[],
    ),
    Tech::new(
        Key::Trade,
        Era::Settlement,
        7,
        &[Key::Agriculture],
        &[
            Unlock::Building(Building::MerchantHall),
            Unlock::Unit(Unit::Merchant),
            Unlock::Improvement(Improvement::Vineyard),
            Unlock::Improvement(Improvement::TradingPost),
        ],
        &[],
        &[],
    ),
    Tech::new(
        Key::Storage,
        Era::Expansion,
        11,
        &[Key::Agriculture],
        &[Unlock::Building(Building::Storehouse)],
        &[],
        &[Boost::new(
            BoostCondition::ImprovementCount {
                improvement: Improvement::Farm,
                count: 2,
            },
            BOOST_DISCOUNT,
        )],
    ),
    Tech::new(
        Key::WaterEngineering,
        Era::Expansion,
        12,
        &[Key::Agriculture],
        &[
            Unlock::Building(Building::WaterMill),
            Unlock::Wonder(Wonder::HangingGardens),
        ],
        &[],
        &[],
    ),
    Tech::new(
        Key::Stoneworking,
        Era::Expansion,
        13,
        &[Key::Mining],
        &[
            Unlock::Improvement(Improvement::Quarry),
            Unlock::Building(Building::Stonemason),
            Unlock::Wonder(Wonder::Petra),
        ],
        &[],
        &[],
    ),
    Tech::new(
        Key::MilitaryOrganization,
        Era::Expansion,
        13,
        &[Key::Hunting],
        &[
            Unlock::Building(Building::Barracks),
            Unlock::Building(Building::Armory),
            Unlock::Unit(Unit::Spearman),
            Unlock::Wonder(Wonder::GreatWall),
        ],
        &[Effect::ArmyCombatStatsBonus {
            attack: 0,
            defense: 0,
            hit_points: 1,
        }],
        &[],
    ),
    Tech::new(
        Key::AdvancedTrade,
        Era::Expansion,
        14,
        &[Key::Trade],
        &[
            Unlock::Building(Building::Marketplace),
            Unlock::Improvement(Improvement::Plantation),
        ],
        &[],
        &[],
    ),
    Tech::new(
        Key::Construction,
        Era::Expansion,
        13,
        &[Key::Craftsmanship],
        &[Unlock::Building(Building::Housing)],
        &[],
        &[Boost::new(
            BoostCondition::ImprovementCount {
                improvement: Improvement::Mine,
                count: 1,
            },
            BOOST_DISCOUNT,
        )],
    ),
    Tech::new(
        Key::Navigation,
        Era::Expansion,
        12,
        &[Key::Fishing],
        &[
            Unlock::Building(Building::Port),
            Unlock::Improvement(Improvement::PearlDivers),
        ],
        &[],
        &[],
    ),
];
