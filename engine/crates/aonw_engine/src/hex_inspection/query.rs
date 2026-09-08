use super::{HexInspection, HexInspectionQuery, improvements, kind, recommendation, score};
use crate::economy::rules::{checked_add, from_content, resources_at};
use crate::{EngineContext, TechnologyUnlockQuery, YieldValue};
use aonw_content::{ResourceType, TerrainType};
use aonw_domain::{GameState, PlayerResearchState};

/// Failure of a revision-bound hex inspection.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum HexInspectionError {
    StaleRevision,
    PlayerNotInMatch,
    HexOutsideMap,
    ArithmeticOverflow,
}
impl HexInspectionError {
    /// Returns a stable query error code.
    #[must_use]
    pub const fn code(self) -> &'static str {
        match self {
            Self::StaleRevision => "stale_revision",
            Self::PlayerNotInMatch => "hex_inspection_player_not_in_match",
            Self::HexOutsideMap => "hex_inspection_outside_map",
            Self::ArithmeticOverflow => "hex_inspection_arithmetic_overflow",
        }
    }
}
impl core::fmt::Display for HexInspectionError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        formatter.write_str(self.code())
    }
}
impl std::error::Error for HexInspectionError {}

pub(crate) fn inspect(
    state: &GameState,
    context: EngineContext<'_>,
    query: HexInspectionQuery,
) -> Result<HexInspection, HexInspectionError> {
    if state.revision().get() != query.expected_revision {
        return Err(HexInspectionError::StaleRevision);
    }
    if !state
        .match_lifecycle()
        .identity()
        .contains(context.actor_player_id())
    {
        return Err(HexInspectionError::PlayerNotInMatch);
    }
    let tile = context
        .map()
        .tile_at(query.coordinate)
        .ok_or(HexInspectionError::HexOutsideMap)?;
    let empty = PlayerResearchState::default();
    let research = state
        .research()
        .players()
        .get(context.actor_player_id())
        .unwrap_or(&empty);
    let technology = TechnologyUnlockQuery::new(context.ruleset(), research);
    let resources = resources_at(state, context, query.coordinate)
        .into_iter()
        .filter(|resource| technology.is_resource_revealed(*resource))
        .map(content_resource)
        .collect::<Vec<_>>();
    let terrain = tile.yield_terrain();
    let river = tile.terrain_tags().contains(&TerrainType::River);
    let score = score::score(terrain, river, &resources);
    let kind = kind::classify(terrain, river, &resources, score);
    let access = improvements::access(state, context, query.coordinate);
    let options = improvements::options(
        state, context, terrain, river, &resources, technology, &access,
    );
    Ok(HexInspection {
        coordinate: query.coordinate,
        base_terrain: terrain,
        terrain_tags: tile.terrain_tags().to_vec(),
        height: tile.height(),
        has_river: river,
        can_found_city_on_terrain: recommendation::can_found(terrain),
        yield_value: disclosed_yield(context, terrain, river, &resources)?,
        recommendation: recommendation::recommend(terrain, kind, score),
        tags: recommendation::tags(terrain, river, &resources, kind, score),
        resources,
        score,
        kind,
        improvement_access: access,
        improvements: options,
    })
}

pub(super) fn disclosed_yield(
    context: EngineContext<'_>,
    terrain: TerrainType,
    river: bool,
    resources: &[ResourceType],
) -> Result<YieldValue, HexInspectionError> {
    let balance = context.ruleset().economy();
    let mut value = from_content(balance.terrain_yield(terrain));
    if river {
        value = checked_add(value, from_content(balance.river_yield()))
            .map_err(|_| HexInspectionError::ArithmeticOverflow)?;
    }
    for resource in resources {
        value = checked_add(value, from_content(balance.resource_yield(*resource)))
            .map_err(|_| HexInspectionError::ArithmeticOverflow)?;
    }
    Ok(value)
}

fn content_resource(resource: aonw_domain::ResourceType) -> ResourceType {
    match resource {
        aonw_domain::ResourceType::Wheat => ResourceType::Wheat,
        aonw_domain::ResourceType::Fish => ResourceType::Fish,
        aonw_domain::ResourceType::Deer => ResourceType::Deer,
        aonw_domain::ResourceType::Sheep => ResourceType::Sheep,
        aonw_domain::ResourceType::Rice => ResourceType::Rice,
        aonw_domain::ResourceType::Cow => ResourceType::Cow,
        aonw_domain::ResourceType::Apple => ResourceType::Apple,
        aonw_domain::ResourceType::Banana => ResourceType::Banana,
        aonw_domain::ResourceType::Citrus => ResourceType::Citrus,
        aonw_domain::ResourceType::Gold => ResourceType::Gold,
        aonw_domain::ResourceType::Silver => ResourceType::Silver,
        aonw_domain::ResourceType::Gems => ResourceType::Gems,
        aonw_domain::ResourceType::Silk => ResourceType::Silk,
        aonw_domain::ResourceType::Spices => ResourceType::Spices,
        aonw_domain::ResourceType::Cotton => ResourceType::Cotton,
        aonw_domain::ResourceType::Grapes => ResourceType::Grapes,
        aonw_domain::ResourceType::Ivory => ResourceType::Ivory,
        aonw_domain::ResourceType::Pearls => ResourceType::Pearls,
        aonw_domain::ResourceType::Coffee => ResourceType::Coffee,
        aonw_domain::ResourceType::Cocoa => ResourceType::Cocoa,
        aonw_domain::ResourceType::Tobacco => ResourceType::Tobacco,
        aonw_domain::ResourceType::Sugar => ResourceType::Sugar,
        aonw_domain::ResourceType::Iron => ResourceType::Iron,
        aonw_domain::ResourceType::Coal => ResourceType::Coal,
        aonw_domain::ResourceType::Oil => ResourceType::Oil,
        aonw_domain::ResourceType::Aluminium => ResourceType::Aluminium,
        aonw_domain::ResourceType::Uranium => ResourceType::Uranium,
        aonw_domain::ResourceType::Horses => ResourceType::Horses,
        aonw_domain::ResourceType::Marble => ResourceType::Marble,
    }
}
