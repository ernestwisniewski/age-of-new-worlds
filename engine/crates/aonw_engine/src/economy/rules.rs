use std::collections::{BTreeMap, BTreeSet};

use aonw_content::{EconomyYield, TileDefinition};
use aonw_domain::{
    City, FieldImprovementKind, GameState, HexCoord, PlayerResearchState, ResourceType, UnitKind,
    WorldArtifactLocation, WorldArtifactType,
};

use crate::{CommandRejectionCode, EngineContext, TechnologyUnlockQuery};

use super::{
    CityYieldBreakdown, CityYieldContribution, CityYieldContributionKind, CityYieldQuery,
    StrategicResourceProjection, StrategicResourceProjectionQuery, StrategicResourceSource,
    YieldValue,
};

/// Failure from checked economy queries.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum EconomyQueryError {
    /// The request was rejected by stable authoritative rules.
    Rejected(CommandRejectionCode),
    /// A yield calculation exceeded the canonical integer range.
    ArithmeticOverflow,
    /// Authoritative economy state or content could not produce a forecast.
    ProjectionInvalid(Box<str>),
}

impl EconomyQueryError {
    /// Returns the stable wire-facing code.
    #[must_use]
    pub const fn code(&self) -> &'static str {
        match self {
            Self::Rejected(code) => code.as_str(),
            Self::ArithmeticOverflow => "economy_arithmetic_overflow",
            Self::ProjectionInvalid(_) => "economy_projection_invalid",
        }
    }
}

impl core::fmt::Display for EconomyQueryError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::Rejected(code) => code.fmt(formatter),
            Self::ArithmeticOverflow => formatter.write_str("economy arithmetic overflow"),
            Self::ProjectionInvalid(message) => formatter.write_str(message),
        }
    }
}

pub(crate) fn query_strategic_resource_projection(
    state: &GameState,
    context: EngineContext<'_>,
    query: StrategicResourceProjectionQuery,
) -> Result<StrategicResourceProjection, EconomyQueryError> {
    if state.revision().get() != query.expected_revision() {
        return Err(EconomyQueryError::Rejected(
            CommandRejectionCode::StaleRevision,
        ));
    }
    strategic_resource_projection_for_player(state, context, context.actor_player_id())
}

pub(crate) fn strategic_resource_projection_for_player(
    state: &GameState,
    context: EngineContext<'_>,
    player_id: &aonw_domain::PlayerId,
) -> Result<StrategicResourceProjection, EconomyQueryError> {
    let empty_research = PlayerResearchState::default();
    let research = state
        .research()
        .players()
        .get(player_id)
        .unwrap_or(&empty_research);
    let technology = TechnologyUnlockQuery::new(context.ruleset(), research);
    let mut output = BTreeMap::<ResourceType, i64>::new();
    let mut sources = Vec::new();
    for improvement in state.field_improvements() {
        let Some(city) = improvement_owner(state, player_id, improvement) else {
            continue;
        };
        for resource in resources_at(state, context, improvement.coordinate()) {
            let Some(required_improvement) = extraction_improvement(resource) else {
                continue;
            };
            if required_improvement != improvement.kind()
                || !technology.is_resource_revealed(resource)
            {
                continue;
            }
            let amount = output.entry(resource).or_default();
            *amount = amount
                .checked_add(1)
                .ok_or(EconomyQueryError::ArithmeticOverflow)?;
            sources.push(StrategicResourceSource::new(
                city.id().clone(),
                improvement.coordinate(),
                resource,
                improvement.kind(),
                1,
            ));
        }
    }
    Ok(StrategicResourceProjection::new(
        player_id.clone(),
        output,
        sources,
    ))
}

fn improvement_owner<'state>(
    state: &'state GameState,
    player_id: &aonw_domain::PlayerId,
    improvement: &aonw_domain::FieldImprovement,
) -> Option<&'state City> {
    let owns_and_controls = |city: &&City| {
        city.owner_player_id() == player_id && city.controls(improvement.coordinate())
    };
    match improvement.built_by_city_id() {
        Some(city_id) => state.city(city_id).filter(owns_and_controls),
        None => state.cities().iter().find(owns_and_controls),
    }
}

pub(crate) fn resources_at(
    state: &GameState,
    context: EngineContext<'_>,
    coordinate: HexCoord,
) -> BTreeSet<ResourceType> {
    let mut resources = context
        .map()
        .tile_at(coordinate)
        .into_iter()
        .flat_map(aonw_content::TileDefinition::resources)
        .copied()
        .map(domain_resource)
        .collect::<BTreeSet<_>>();
    resources.extend(
        state
            .economy()
            .initial_resource_distribution()
            .placements()
            .iter()
            .filter(|placement| placement.coordinate() == coordinate)
            .map(|placement| placement.resource()),
    );
    resources
}

const fn extraction_improvement(resource: ResourceType) -> Option<FieldImprovementKind> {
    match resource {
        ResourceType::Oil => Some(FieldImprovementKind::OilWell),
        ResourceType::Aluminium => Some(FieldImprovementKind::BauxiteMine),
        ResourceType::Wheat
        | ResourceType::Fish
        | ResourceType::Deer
        | ResourceType::Sheep
        | ResourceType::Rice
        | ResourceType::Cow
        | ResourceType::Apple
        | ResourceType::Banana
        | ResourceType::Citrus
        | ResourceType::Gold
        | ResourceType::Silver
        | ResourceType::Gems
        | ResourceType::Silk
        | ResourceType::Spices
        | ResourceType::Cotton
        | ResourceType::Grapes
        | ResourceType::Ivory
        | ResourceType::Pearls
        | ResourceType::Coffee
        | ResourceType::Cocoa
        | ResourceType::Tobacco
        | ResourceType::Sugar
        | ResourceType::Iron
        | ResourceType::Coal
        | ResourceType::Uranium
        | ResourceType::Horses
        | ResourceType::Marble => None,
    }
}

pub(crate) const fn domain_resource(resource: aonw_content::ResourceType) -> ResourceType {
    match resource {
        aonw_content::ResourceType::Wheat => ResourceType::Wheat,
        aonw_content::ResourceType::Fish => ResourceType::Fish,
        aonw_content::ResourceType::Deer => ResourceType::Deer,
        aonw_content::ResourceType::Sheep => ResourceType::Sheep,
        aonw_content::ResourceType::Rice => ResourceType::Rice,
        aonw_content::ResourceType::Cow => ResourceType::Cow,
        aonw_content::ResourceType::Apple => ResourceType::Apple,
        aonw_content::ResourceType::Banana => ResourceType::Banana,
        aonw_content::ResourceType::Citrus => ResourceType::Citrus,
        aonw_content::ResourceType::Gold => ResourceType::Gold,
        aonw_content::ResourceType::Silver => ResourceType::Silver,
        aonw_content::ResourceType::Gems => ResourceType::Gems,
        aonw_content::ResourceType::Silk => ResourceType::Silk,
        aonw_content::ResourceType::Spices => ResourceType::Spices,
        aonw_content::ResourceType::Cotton => ResourceType::Cotton,
        aonw_content::ResourceType::Grapes => ResourceType::Grapes,
        aonw_content::ResourceType::Ivory => ResourceType::Ivory,
        aonw_content::ResourceType::Pearls => ResourceType::Pearls,
        aonw_content::ResourceType::Coffee => ResourceType::Coffee,
        aonw_content::ResourceType::Cocoa => ResourceType::Cocoa,
        aonw_content::ResourceType::Tobacco => ResourceType::Tobacco,
        aonw_content::ResourceType::Sugar => ResourceType::Sugar,
        aonw_content::ResourceType::Iron => ResourceType::Iron,
        aonw_content::ResourceType::Coal => ResourceType::Coal,
        aonw_content::ResourceType::Oil => ResourceType::Oil,
        aonw_content::ResourceType::Aluminium => ResourceType::Aluminium,
        aonw_content::ResourceType::Uranium => ResourceType::Uranium,
        aonw_content::ResourceType::Horses => ResourceType::Horses,
        aonw_content::ResourceType::Marble => ResourceType::Marble,
    }
}

impl std::error::Error for EconomyQueryError {}

pub(crate) fn query_city_yield(
    state: &GameState,
    context: EngineContext<'_>,
    query: CityYieldQuery<'_>,
) -> Result<CityYieldBreakdown, EconomyQueryError> {
    if state.revision().get() != query.expected_revision() {
        return Err(EconomyQueryError::Rejected(
            CommandRejectionCode::StaleRevision,
        ));
    }
    let city = state
        .city(query.city_id())
        .ok_or(EconomyQueryError::Rejected(
            CommandRejectionCode::CityNotFound,
        ))?;
    if !context.can_act() || city.owner_player_id() != context.actor_player_id() {
        return Err(EconomyQueryError::Rejected(
            CommandRejectionCode::CityNotControlled,
        ));
    }

    let balance = context.ruleset().economy();
    let worked_limit = context.ruleset().city().worked_hex_limit(city.population());
    let manual = crate::city::normalized_manual_hexes(city, worked_limit);
    let worked =
        crate::city::effective_worked_hexes(city, context.map(), &manual, worked_limit, &balance);
    let assigned = assigned_worker_hexes(state, city);
    let mut full_yield_hexes = worked.iter().copied().collect::<BTreeSet<_>>();
    full_yield_hexes.extend(assigned.iter().copied());

    let mut contributions = Vec::new();
    push_contribution(
        &mut contributions,
        CityYieldContributionKind::Center,
        city.center(),
        from_content(balance.city_center_yield()),
    );
    for coordinate in &worked {
        let value = tile_yield(state, context, *coordinate)?;
        push_contribution(
            &mut contributions,
            CityYieldContributionKind::Population,
            *coordinate,
            value,
        );
    }
    for coordinate in &assigned {
        let tile = tile_yield(state, context, *coordinate)?;
        let full = if worked.binary_search(coordinate).is_ok() {
            YieldValue::default()
        } else {
            tile
        };
        let bonus = scaled_rounded_up(tile, 1, 2)?;
        let value = checked_add(full, bonus)?;
        if value != YieldValue::default() {
            push_contribution(
                &mut contributions,
                CityYieldContributionKind::Worker,
                *coordinate,
                value,
            );
        }
    }
    let (numerator, denominator) = balance.passive_improvement_scale();
    for improvement in state.field_improvements() {
        let coordinate = improvement.coordinate();
        if coordinate == city.center()
            || !city.controls(coordinate)
            || full_yield_hexes.contains(&coordinate)
        {
            continue;
        }
        let value = scaled_rounded_up(
            improvement_yield(context, improvement.kind())?,
            numerator,
            denominator,
        )?;
        if value != YieldValue::default() {
            push_contribution(
                &mut contributions,
                CityYieldContributionKind::PassiveImprovement,
                coordinate,
                value,
            );
        }
    }
    let artifact = artifact_yield(state, city)?;
    if artifact != YieldValue::default() {
        push_contribution(
            &mut contributions,
            CityYieldContributionKind::Artifact,
            city.center(),
            artifact,
        );
    }

    let total = contributions
        .iter()
        .try_fold(YieldValue::default(), |sum, contribution| {
            checked_add(sum, contribution.value())
        })?;
    Ok(CityYieldBreakdown::new(
        city.id().clone(),
        contributions,
        total,
    ))
}

pub(crate) fn tile_base_yield(
    tile: &TileDefinition,
    balance: &aonw_content::EconomyBalance,
) -> Result<YieldValue, EconomyQueryError> {
    let mut value = from_content(balance.terrain_yield(tile.yield_terrain()));
    if tile
        .terrain_tags()
        .contains(&aonw_content::TerrainType::River)
    {
        value = checked_add(value, from_content(balance.river_yield()))?;
    }
    for resource in tile.resources() {
        value = checked_add(value, from_content(balance.resource_yield(*resource)))?;
    }
    Ok(value)
}

fn tile_yield(
    state: &GameState,
    context: EngineContext<'_>,
    coordinate: HexCoord,
) -> Result<YieldValue, EconomyQueryError> {
    let mut value = context
        .map()
        .tile_at(coordinate)
        .map_or(Ok(YieldValue::default()), |tile| {
            tile_base_yield(tile, &context.ruleset().economy())
        })?;
    if let Some(improvement) = state.infrastructure().field_improvement_at(coordinate) {
        value = checked_add(value, improvement_yield(context, improvement.kind())?)?;
    }
    Ok(value)
}

fn improvement_yield(
    context: EngineContext<'_>,
    kind: FieldImprovementKind,
) -> Result<YieldValue, EconomyQueryError> {
    let value = context
        .ruleset()
        .worker()
        .improvement(kind)
        .ok_or(EconomyQueryError::ArithmeticOverflow)?
        .yield_delta();
    Ok(YieldValue::new(
        i64::from(value.food()),
        i64::from(value.production()),
        i64::from(value.gold()),
        i64::from(value.defense()),
    ))
}

fn assigned_worker_hexes(state: &GameState, city: &City) -> Vec<HexCoord> {
    state
        .units()
        .iter()
        .filter(|unit| {
            unit.kind() == UnitKind::Worker && unit.owner_player_id() == city.owner_player_id()
        })
        .filter_map(|unit| {
            let coordinate = unit.activity().worker_assignment()?;
            (unit.position() == coordinate
                && coordinate != city.center()
                && city.controls(coordinate)
                && state
                    .infrastructure()
                    .field_improvement_at(coordinate)
                    .is_some())
            .then_some(coordinate)
        })
        .collect::<BTreeSet<_>>()
        .into_iter()
        .collect()
}

fn artifact_yield(state: &GameState, city: &City) -> Result<YieldValue, EconomyQueryError> {
    state
        .artifacts()
        .iter()
        .filter(|artifact| {
            matches!(artifact.location(), WorldArtifactLocation::Stored(city_id) if city_id == city.id())
        })
        .try_fold(YieldValue::default(), |sum, artifact| {
            checked_add(sum, artifact_type_yield(artifact.artifact_type()))
        })
}

const fn artifact_type_yield(artifact: WorldArtifactType) -> YieldValue {
    match artifact {
        WorldArtifactType::AncientImperialCrown => YieldValue::new(0, 0, 0, 1),
        WorldArtifactType::AstronomersTablets | WorldArtifactType::HeroSword => {
            YieldValue::new(0, 0, 0, 0)
        }
        WorldArtifactType::ProphetMask | WorldArtifactType::QueensMirror => {
            YieldValue::new(0, 0, 1, 0)
        }
        WorldArtifactType::MerchantsSeal => YieldValue::new(0, 0, 2, 0),
        WorldArtifactType::FirstPeoplesChronicle => YieldValue::new(1, 0, 0, 0),
        WorldArtifactType::TempleReliquary => YieldValue::new(1, 0, 0, 1),
    }
}

const fn from_content(value: EconomyYield) -> YieldValue {
    YieldValue::new(
        value.food(),
        value.production(),
        value.gold(),
        value.defense(),
    )
}

fn checked_add(left: YieldValue, right: YieldValue) -> Result<YieldValue, EconomyQueryError> {
    Ok(YieldValue::new(
        left.food
            .checked_add(right.food)
            .ok_or(EconomyQueryError::ArithmeticOverflow)?,
        left.production
            .checked_add(right.production)
            .ok_or(EconomyQueryError::ArithmeticOverflow)?,
        left.gold
            .checked_add(right.gold)
            .ok_or(EconomyQueryError::ArithmeticOverflow)?,
        left.defense
            .checked_add(right.defense)
            .ok_or(EconomyQueryError::ArithmeticOverflow)?,
    ))
}

fn scaled_rounded_up(
    value: YieldValue,
    numerator: u32,
    denominator: u32,
) -> Result<YieldValue, EconomyQueryError> {
    if denominator == 0 {
        return Err(EconomyQueryError::ArithmeticOverflow);
    }
    Ok(YieldValue::new(
        scale_component(value.food, numerator, denominator)?,
        scale_component(value.production, numerator, denominator)?,
        scale_component(value.gold, numerator, denominator)?,
        scale_component(value.defense, numerator, denominator)?,
    ))
}

fn scale_component(value: i64, numerator: u32, denominator: u32) -> Result<i64, EconomyQueryError> {
    if value <= 0 || numerator == 0 {
        return Ok(0);
    }
    let numerator = i128::from(value)
        .checked_mul(i128::from(numerator))
        .ok_or(EconomyQueryError::ArithmeticOverflow)?;
    let rounded = numerator
        .checked_add(i128::from(denominator) - 1)
        .ok_or(EconomyQueryError::ArithmeticOverflow)?
        / i128::from(denominator);
    i64::try_from(rounded).map_err(|_| EconomyQueryError::ArithmeticOverflow)
}

fn push_contribution(
    contributions: &mut Vec<CityYieldContribution>,
    kind: CityYieldContributionKind,
    coordinate: HexCoord,
    value: YieldValue,
) {
    contributions.push(CityYieldContribution::new(kind, coordinate, value));
}
