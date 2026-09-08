use crate::{
    encode_client_stamp, encode_improvement, encode_map_resource, encode_map_terrain,
    encode_technology,
};
use aonw_contracts::CoordinateDto;
use aonw_contracts::client::{
    ClientQueryResultDto, HexAssessmentKindDto, HexAssessmentScoreDto, HexAssessmentTagDto,
    HexImprovementAccessDto, HexImprovementOptionDto, HexInspectionDto, HexRecommendationDto,
    YieldValueDto,
};
use aonw_engine::{
    HexAssessmentKind, HexAssessmentTag, HexImprovementAccess, HexInspection, HexRecommendation,
    YieldValue,
};
use aonw_projection::SessionStamp;

/// Encodes a disclosed hex profile identically for local and remote clients.
#[must_use]
pub fn encode_hex_inspection(stamp: SessionStamp, value: &HexInspection) -> ClientQueryResultDto {
    ClientQueryResultDto::HexInspection {
        stamp: encode_client_stamp(stamp),
        inspection: HexInspectionDto {
            coordinate: CoordinateDto {
                col: value.coordinate.col(),
                row: value.coordinate.row(),
            },
            base_terrain: encode_map_terrain(value.base_terrain),
            terrain_tags: value
                .terrain_tags
                .iter()
                .copied()
                .map(encode_map_terrain)
                .collect(),
            resources: value
                .resources
                .iter()
                .copied()
                .map(encode_map_resource)
                .collect(),
            height: value.height,
            has_river: value.has_river,
            can_found_city_on_terrain: value.can_found_city_on_terrain,
            yield_value: yield_value(value.yield_value),
            score: HexAssessmentScoreDto {
                city: value.score.city,
                defense: value.score.defense,
                economy: value.score.economy,
            },
            kind: kind(value.kind),
            recommendation: recommendation(value.recommendation),
            tags: value.tags.iter().copied().map(tag).collect(),
            improvement_access: match &value.improvement_access {
                HexImprovementAccess::OutsideControlledCity => {
                    HexImprovementAccessDto::OutsideControlledCity {}
                }
                HexImprovementAccess::CityCenter => HexImprovementAccessDto::CityCenter {},
                HexImprovementAccess::AlreadyImproved => {
                    HexImprovementAccessDto::AlreadyImproved {}
                }
                HexImprovementAccess::ControlledCity(id) => {
                    HexImprovementAccessDto::ControlledCity {
                        city_id: id.as_str().to_owned(),
                    }
                }
            },
            improvements: value
                .improvements
                .iter()
                .map(|option| HexImprovementOptionDto {
                    kind: encode_improvement(option.kind),
                    required_technology: option.required_technology.map(encode_technology),
                    technology_unlocked: option.technology_unlocked,
                    build_turns: option.build_turns,
                    yield_delta: yield_value(option.yield_delta),
                })
                .collect(),
        },
    }
}

const fn yield_value(value: YieldValue) -> YieldValueDto {
    YieldValueDto {
        food: value.food,
        production: value.production,
        gold: value.gold,
        defense: value.defense,
    }
}

const fn kind(value: HexAssessmentKind) -> HexAssessmentKindDto {
    match value {
        HexAssessmentKind::IdealCitySite => HexAssessmentKindDto::IdealCitySite,
        HexAssessmentKind::GoodCitySite => HexAssessmentKindDto::GoodCitySite,
        HexAssessmentKind::FertileField => HexAssessmentKindDto::FertileField,
        HexAssessmentKind::FertilePlains => HexAssessmentKindDto::FertilePlains,
        HexAssessmentKind::RichPlain => HexAssessmentKindDto::RichPlain,
        HexAssessmentKind::StrategicBorderland => HexAssessmentKindDto::StrategicBorderland,
        HexAssessmentKind::StrategicField => HexAssessmentKindDto::StrategicField,
        HexAssessmentKind::DefensivePosition => HexAssessmentKindDto::DefensivePosition,
        HexAssessmentKind::FertileForest => HexAssessmentKindDto::FertileForest,
        HexAssessmentKind::ForestBackline => HexAssessmentKindDto::ForestBackline,
        HexAssessmentKind::ForestForge => HexAssessmentKindDto::ForestForge,
        HexAssessmentKind::WildLand => HexAssessmentKindDto::WildLand,
        HexAssessmentKind::RichWilds => HexAssessmentKindDto::RichWilds,
        HexAssessmentKind::ExoticBackline => HexAssessmentKindDto::ExoticBackline,
        HexAssessmentKind::DifficultStrategicTerrain => {
            HexAssessmentKindDto::DifficultStrategicTerrain
        }
        HexAssessmentKind::HighGround => HexAssessmentKindDto::HighGround,
        HexAssessmentKind::RiverHills => HexAssessmentKindDto::RiverHills,
        HexAssessmentKind::IndustrialStronghold => HexAssessmentKindDto::IndustrialStronghold,
        HexAssessmentKind::RichHills => HexAssessmentKindDto::RichHills,
        HexAssessmentKind::BarrenLand => HexAssessmentKindDto::BarrenLand,
        HexAssessmentKind::Oasis => HexAssessmentKindDto::Oasis,
        HexAssessmentKind::TradeOasis => HexAssessmentKindDto::TradeOasis,
        HexAssessmentKind::DesertDeposits => HexAssessmentKindDto::DesertDeposits,
        HexAssessmentKind::HarshLand => HexAssessmentKindDto::HarshLand,
        HexAssessmentKind::ColdPastures => HexAssessmentKindDto::ColdPastures,
        HexAssessmentKind::ResourceOutpost => HexAssessmentKindDto::ResourceOutpost,
        HexAssessmentKind::HostileLand => HexAssessmentKindDto::HostileLand,
        HexAssessmentKind::ArcticDeposits => HexAssessmentKindDto::ArcticDeposits,
        HexAssessmentKind::Coast => HexAssessmentKindDto::Coast,
        HexAssessmentKind::FishingCoast => HexAssessmentKindDto::FishingCoast,
        HexAssessmentKind::RichCoast => HexAssessmentKindDto::RichCoast,
        HexAssessmentKind::RiverPort => HexAssessmentKindDto::RiverPort,
        HexAssessmentKind::RegionalPortHeart => HexAssessmentKindDto::RegionalPortHeart,
        HexAssessmentKind::OpenSea => HexAssessmentKindDto::OpenSea,
        HexAssessmentKind::NaturalBarrier => HexAssessmentKindDto::NaturalBarrier,
        HexAssessmentKind::PromisingLand => HexAssessmentKindDto::PromisingLand,
        HexAssessmentKind::WeakLand => HexAssessmentKindDto::WeakLand,
        HexAssessmentKind::OrdinaryLand => HexAssessmentKindDto::OrdinaryLand,
        HexAssessmentKind::MapTile => HexAssessmentKindDto::MapTile,
    }
}

const fn recommendation(value: HexRecommendation) -> HexRecommendationDto {
    match value {
        HexRecommendation::FoundCity => HexRecommendationDto::FoundCity,
        HexRecommendation::DefendHere => HexRecommendationDto::DefendHere,
        HexRecommendation::ExploitEconomy => HexRecommendationDto::ExploitEconomy,
        HexRecommendation::Avoid => HexRecommendationDto::Avoid,
        HexRecommendation::Neutral => HexRecommendationDto::Neutral,
    }
}

const fn tag(value: HexAssessmentTag) -> HexAssessmentTagDto {
    match value {
        HexAssessmentTag::City => HexAssessmentTagDto::City,
        HexAssessmentTag::Defense => HexAssessmentTagDto::Defense,
        HexAssessmentTag::Trade => HexAssessmentTagDto::Trade,
        HexAssessmentTag::Fertile => HexAssessmentTagDto::Fertile,
        HexAssessmentTag::Production => HexAssessmentTagDto::Production,
        HexAssessmentTag::Hostile => HexAssessmentTagDto::Hostile,
        HexAssessmentTag::Strategic => HexAssessmentTagDto::Strategic,
        HexAssessmentTag::Water => HexAssessmentTagDto::Water,
    }
}
