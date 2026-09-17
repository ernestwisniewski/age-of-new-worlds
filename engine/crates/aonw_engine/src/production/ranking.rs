use aonw_content::BuildingProductionDefinition;
use aonw_domain::{City, GameState};

use super::ranking_model::{ProductionBuildingRank, ProductionBuildingRanks};
use super::support::{controlled_city, invalid, technology_for, validate_revision};
use super::yield_rules::ProductionRates;
use super::{ProductionError, ProductionOption, ProductionOptionsQuery};
use crate::{EngineContext, GameEngine, YieldValue};

const UNKNOWN_TURNS: i64 = 1 << 30;

impl GameEngine {
    /// Computes reference building priorities from current owned-city rules.
    /// Ranking does not change command availability or mutate the production queue.
    ///
    /// # Errors
    ///
    /// Rejects stale revisions, uncontrolled cities and checked score overflow.
    pub fn production_building_ranks(
        state: &GameState,
        context: EngineContext<'_>,
        query: ProductionOptionsQuery<'_>,
    ) -> Result<ProductionBuildingRanks, ProductionError> {
        validate_revision(state, query.expected_revision())?;
        let city = controlled_city(state, context, query.city_id())?;
        let rates = ProductionRates::prepare(state, context, city)?;
        let river_count = crate::economy::city_river_hex_count(context, city);
        let buildings = context
            .ruleset()
            .production()
            .buildings()
            .iter()
            .copied()
            .map(|definition| building_rank(state, context, city, definition, &rates, river_count))
            .collect::<Result<_, _>>()?;
        Ok(ProductionBuildingRanks {
            revision: state.revision().get(),
            city_id: city.id().clone(),
            buildings,
        })
    }
}

fn building_rank(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    definition: BuildingProductionDefinition,
    rates: &ProductionRates,
    river_count: usize,
) -> Result<ProductionBuildingRank, ProductionError> {
    let option = super::options::building_option(
        state,
        context,
        city,
        technology_for(state, context, city),
        definition,
        rates,
    )?;
    let output = crate::economy::building_yield_for(definition, river_count)
        .map_err(|error| invalid(error.to_string()))?;
    let turns = turns_for_score(option)?;
    score(definition, output, turns)
}

fn score(
    definition: BuildingProductionDefinition,
    output: YieldValue,
    turns: i64,
) -> Result<ProductionBuildingRank, ProductionError> {
    let science = definition.science_per_turn();
    let hexes = definition.max_controlled_hexes_delta();
    let food_basis_delta = i64::from(definition.food_deposit_basis_points()) - 10_000;
    let food_percent = (food_basis_delta + 50 * food_basis_delta.signum()) / 100;
    let strategic = weighted([
        (output.food, 120),
        (output.production, 120),
        (science, 115),
        (output.gold, 90),
        (output.defense, 75),
        (hexes, 60),
        (food_percent, 4),
    ])?;
    let best_return = strategic
        .checked_mul(100)
        .and_then(|value| value.checked_div(turns))
        .ok_or_else(|| invalid("building return score overflow"))?;
    Ok(ProductionBuildingRank {
        building: definition.building(),
        turns_for_score: turns,
        recommended: weighted([(best_return, 2), (strategic, 1), (1000 / turns, 1)])?,
        best_return,
        growth: weighted([
            (output.food, 120),
            (hexes, 70),
            (food_percent, 5),
            (output.gold, 10),
        ])?,
        industry: weighted([(output.production, 130), (output.food, 10)])?,
        science: weighted([(science, 140), (output.gold, 10)])?,
        defense_military: weighted([(output.defense, 120), (output.production, 30)])?,
        economy: weighted([(output.gold, 120), (output.production, 15), (science, 10)])?,
    })
}

fn weighted(values: impl IntoIterator<Item = (i64, i64)>) -> Result<i64, ProductionError> {
    values
        .into_iter()
        .try_fold(0_i64, |total, (value, weight)| {
            value
                .checked_mul(weight)
                .and_then(|value| total.checked_add(value))
                .ok_or_else(|| invalid("building priority score overflow"))
        })
}

fn turns_for_score(option: ProductionOption) -> Result<i64, ProductionError> {
    let forecast = option.forecast();
    score_turns(
        option.cost(),
        forecast.invested_production(),
        forecast.production_per_turn(),
        forecast.estimated_turns(),
    )
}

fn score_turns(
    cost: i64,
    invested: i64,
    rate: i64,
    estimate: Option<u64>,
) -> Result<i64, ProductionError> {
    if let Some(turns) = estimate.filter(|turns| *turns > 0) {
        return i64::try_from(turns)
            .map_err(|_| invalid("building completion estimate exceeds score range"));
    }
    if rate <= 0 {
        return Ok(UNKNOWN_TURNS);
    }
    let remaining = cost
        .checked_sub(invested)
        .ok_or_else(|| invalid("building score remaining cost overflow"))?;
    let needed = if remaining > 0 { remaining } else { cost };
    if needed <= 0 {
        return Ok(1);
    }
    // Quotient/remainder avoids overflow from adding rate - 1 to the cost.
    Ok(needed / rate + i64::from(needed % rate != 0))
}

#[cfg(test)]
mod tests {
    use super::*;
    use aonw_content::RulesetDefinition;
    use aonw_domain::CityBuildingType;

    #[test]
    fn completion_scores_preserve_reference_fallbacks_without_ceil_overflow() {
        assert_eq!(score_turns(20, 3, 6, Some(99)).expect("forecast"), 99);
        assert_eq!(score_turns(20, 3, 6, None).expect("remaining cost"), 3);
        assert_eq!(
            score_turns(20, 20, 6, Some(0)).expect("completed target"),
            4
        );
        assert_eq!(
            score_turns(20, 0, 0, None).expect("no output"),
            UNKNOWN_TURNS
        );
        assert_eq!(score_turns(0, 0, 6, None).expect("zero cost"), 1);
        assert_eq!(
            score_turns(i64::MAX, 0, 2, None).expect("large cost"),
            i64::MAX / 2 + 1
        );
        assert!(score_turns(1, 0, 1, Some(u64::MAX)).is_err());
    }

    #[test]
    fn reference_weights_are_exact_and_overflow_is_rejected() {
        let workshop = RulesetDefinition::standard()
            .production()
            .building(CityBuildingType::Workshop)
            .expect("workshop");
        let rank = score(workshop, YieldValue::new(0, 2, 0, 0), 5).expect("score");
        assert_eq!(rank.best_return, 4800);
        assert_eq!(rank.recommended, 10040);
        assert_eq!(rank.industry, 260);
        assert_eq!(rank.defense_military, 60);
        assert_eq!(rank.economy, 30);
        assert!(weighted([(i64::MAX, 120)]).is_err());
        assert!(weighted([(i64::MAX, 1), (1, 1)]).is_err());
    }
}
