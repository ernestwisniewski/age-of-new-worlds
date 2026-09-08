use super::{HexAssessmentKind as K, HexAssessmentScore as Score};
use aonw_content::{ResourceType as R, TerrainType as T};

pub(super) fn classify(terrain: T, river: bool, r: &[R], score: Score) -> K {
    match terrain {
        T::Mountain => K::NaturalBarrier,
        T::Ocean | T::Lake => K::OpenSea,
        T::Coast => coast(river, r),
        T::Hills => hills(river, r),
        T::Desert => desert(river, r, score),
        T::Grassland => grassland(river, r),
        T::Plains => plains(river, r),
        T::Forest => forest(river, r),
        T::Jungle | T::Wetlands => jungle(terrain, river, r),
        T::Tundra if any(r, &[R::Oil, R::Uranium, R::Coal]) => K::ResourceOutpost,
        T::Tundra if any(r, &[R::Deer, R::Sheep]) => K::ColdPastures,
        T::Tundra => K::HarshLand,
        T::Snow if any(r, &[R::Oil, R::Uranium, R::Coal]) => K::ArcticDeposits,
        T::Snow => K::HostileLand,
        T::River => K::MapTile,
    }
}

pub(super) fn any(resources: &[R], expected: &[R]) -> bool {
    resources.iter().any(|r| expected.contains(r))
}
fn coast(river: bool, r: &[R]) -> K {
    if river && any(r, &[R::Fish, R::Pearls]) {
        K::RegionalPortHeart
    } else if river {
        K::RiverPort
    } else if r.contains(&R::Fish) {
        K::FishingCoast
    } else if r.contains(&R::Pearls) {
        K::RichCoast
    } else {
        K::Coast
    }
}
fn hills(river: bool, r: &[R]) -> K {
    if any(r, &[R::Iron, R::Coal, R::Marble]) {
        K::IndustrialStronghold
    } else if any(r, &[R::Gold, R::Gems]) {
        K::RichHills
    } else if river {
        K::RiverHills
    } else {
        K::HighGround
    }
}
fn desert(river: bool, r: &[R], score: Score) -> K {
    if river && any(r, &[R::Gold, R::Silver, R::Spices, R::Cotton, R::Sugar]) {
        K::TradeOasis
    } else if r.contains(&R::Oil) {
        K::DesertDeposits
    } else if river {
        K::Oasis
    } else if r.is_empty() {
        K::BarrenLand
    } else {
        by_score(score)
    }
}
fn grassland(river: bool, r: &[R]) -> K {
    if river && any(r, &[R::Wheat, R::Rice, R::Cow, R::Sheep]) {
        K::IdealCitySite
    } else if any(r, &[R::Gold, R::Silk, R::Spices]) {
        K::RichPlain
    } else if any(r, &[R::Iron, R::Horses]) {
        K::StrategicBorderland
    } else if river {
        K::FertileField
    } else {
        K::GoodCitySite
    }
}
fn plains(river: bool, r: &[R]) -> K {
    if any(r, &[R::Wheat, R::Rice, R::Cow, R::Sheep]) {
        K::IdealCitySite
    } else if any(r, &[R::Iron, R::Horses]) {
        K::StrategicField
    } else if river {
        K::FertilePlains
    } else {
        K::GoodCitySite
    }
}
fn forest(river: bool, r: &[R]) -> K {
    if river && any(r, &[R::Deer, R::Banana, R::Cocoa]) {
        K::RichWilds
    } else if any(r, &[R::Iron, R::Coal]) {
        K::ForestForge
    } else if r.contains(&R::Deer) {
        K::ForestBackline
    } else if river {
        K::FertileForest
    } else {
        K::DefensivePosition
    }
}
fn jungle(terrain: T, river: bool, r: &[R]) -> K {
    if r.contains(&R::Oil) {
        K::DifficultStrategicTerrain
    } else if terrain == T::Jungle && river && any(r, &[R::Deer, R::Banana, R::Cocoa]) {
        K::RichWilds
    } else if any(r, &[R::Banana, R::Cocoa, R::Spices]) {
        K::ExoticBackline
    } else if river {
        K::RichWilds
    } else {
        K::WildLand
    }
}
fn by_score(score: Score) -> K {
    if score.city >= 7 {
        K::GoodCitySite
    } else if score.defense >= 6 {
        K::DefensivePosition
    } else if score.economy >= 6 {
        K::PromisingLand
    } else if score.city <= 0 && score.economy <= 0 {
        K::WeakLand
    } else {
        K::OrdinaryLand
    }
}
