use super::{
    HexAssessmentKind as K, HexAssessmentScore as Score, HexAssessmentTag as Tag,
    HexRecommendation as Recommendation,
};
use super::{kind::any, score::terrain_score};
use aonw_content::{ResourceType as R, TerrainType as T};

pub(super) fn recommend(terrain: T, kind: K, score: Score) -> Recommendation {
    if matches!(terrain, T::Ocean | T::Lake | T::Mountain) {
        Recommendation::Avoid
    } else if city(kind) || score.city >= 7 {
        Recommendation::FoundCity
    } else if defense(kind) || score.defense >= 6 {
        Recommendation::DefendHere
    } else if economy(kind) || score.economy >= 6 {
        Recommendation::ExploitEconomy
    } else if avoid(kind) || (score.city <= 0 && score.economy <= 0) {
        Recommendation::Avoid
    } else {
        Recommendation::Neutral
    }
}

pub(super) fn tags(terrain: T, river: bool, resources: &[R], kind: K, score: Score) -> Vec<Tag> {
    let mut tags = Vec::new();
    if avoid(kind) {
        tags.push(Tag::Hostile);
    }
    if fertile(kind) || score.city >= 5 || river {
        tags.push(Tag::Fertile);
    }
    if defense(kind) || score.defense >= 4 {
        tags.push(Tag::Defense);
    }
    if economy(kind) || score.economy >= 5 {
        tags.push(Tag::Trade);
    }
    if terrain_score(terrain).defense >= 2 || production(kind) {
        tags.push(Tag::Production);
    }
    if any(
        resources,
        &[
            R::Iron,
            R::Coal,
            R::Oil,
            R::Aluminium,
            R::Uranium,
            R::Horses,
            R::Marble,
        ],
    ) {
        tags.push(Tag::Strategic);
    }
    if matches!(terrain, T::Coast | T::Lake | T::Ocean) {
        tags.push(Tag::Water);
    }
    if can_found(terrain) && (city(kind) || score.city >= 5) {
        tags.push(Tag::City);
    }
    tags
}

pub(super) fn can_found(terrain: T) -> bool {
    !matches!(terrain, T::Ocean | T::Lake | T::Mountain | T::River)
}

fn city(kind: K) -> bool {
    matches!(
        kind,
        K::IdealCitySite
            | K::GoodCitySite
            | K::FertileField
            | K::FertilePlains
            | K::FertileForest
            | K::Oasis
            | K::RiverPort
            | K::RegionalPortHeart
    )
}
fn defense(kind: K) -> bool {
    matches!(
        kind,
        K::DefensivePosition
            | K::HighGround
            | K::RiverHills
            | K::IndustrialStronghold
            | K::ForestForge
            | K::NaturalBarrier
    )
}
fn economy(kind: K) -> bool {
    matches!(
        kind,
        K::RichPlain
            | K::RichWilds
            | K::ExoticBackline
            | K::RichHills
            | K::TradeOasis
            | K::DesertDeposits
            | K::ResourceOutpost
            | K::ArcticDeposits
            | K::FishingCoast
            | K::RichCoast
            | K::PromisingLand
    )
}
fn production(kind: K) -> bool {
    matches!(
        kind,
        K::ForestForge | K::IndustrialStronghold | K::HighGround | K::RiverHills
    )
}
fn fertile(kind: K) -> bool {
    matches!(
        kind,
        K::IdealCitySite
            | K::FertileField
            | K::FertilePlains
            | K::FertileForest
            | K::ForestBackline
            | K::RichWilds
            | K::ExoticBackline
            | K::ColdPastures
            | K::FishingCoast
    )
}
fn avoid(kind: K) -> bool {
    matches!(
        kind,
        K::BarrenLand
            | K::HarshLand
            | K::HostileLand
            | K::OpenSea
            | K::NaturalBarrier
            | K::WeakLand
            | K::WildLand
            | K::DifficultStrategicTerrain
    )
}
