use super::HexAssessmentScore as Score;
use aonw_content::{ResourceType as R, TerrainType as T};

pub(super) fn score(terrain: T, river: bool, resources: &[R]) -> Score {
    let mut value = terrain_score(terrain);
    if river {
        value = value.plus(Score::new(2, 1, 2));
    }
    for resource in resources {
        value = value.plus(resource_score(*resource));
    }
    match terrain {
        T::Snow => value = value.plus(Score::new(-2, 0, -2)),
        T::Desert if !river && resources.is_empty() => value = value.plus(Score::new(-2, 0, -1)),
        T::Tundra if resources.is_empty() => value.city -= 1,
        T::Jungle if !river => value.city -= 1,
        _ => {}
    }
    value
}

pub(super) const fn terrain_score(terrain: T) -> Score {
    match terrain {
        T::Grassland => Score::new(3, 0, 3),
        T::Plains | T::Coast => Score::new(2, 0, 2),
        T::Forest => Score::new(2, 2, 1),
        T::Jungle => Score::new(1, 2, 1),
        T::Wetlands => Score::new(1, 2, 2),
        T::Hills => Score::new(1, 3, 1),
        T::Desert => Score::new(0, -1, 1),
        T::Tundra => Score::new(0, 1, 0),
        T::Snow => Score::new(-2, 1, -2),
        T::Lake | T::Ocean => Score::new(-999, -999, -999),
        T::Mountain => Score::new(-999, 4, -999),
        T::River => Score::new(0, 1, 1),
    }
}

const fn resource_score(resource: R) -> Score {
    match resource {
        R::Wheat | R::Rice | R::Fish => Score::new(3, 0, 2),
        R::Deer | R::Sheep | R::Cow | R::Marble => Score::new(2, 1, 1),
        R::Apple | R::Banana | R::Citrus => Score::new(2, 0, 2),
        R::Gold | R::Silver | R::Gems => Score::new(1, 0, 4),
        R::Silk
        | R::Spices
        | R::Cotton
        | R::Grapes
        | R::Pearls
        | R::Coffee
        | R::Cocoa
        | R::Tobacco
        | R::Sugar => Score::new(1, 0, 3),
        R::Ivory => Score::new(1, 1, 2),
        R::Iron | R::Coal | R::Oil | R::Aluminium | R::Uranium => Score::new(1, 2, 2),
        R::Horses => Score::new(1, 0, 1),
    }
}
