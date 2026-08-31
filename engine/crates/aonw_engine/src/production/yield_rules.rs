use aonw_domain::{
    City, CityProductionTarget, CityProjectType, CitySpecializationType, GameState, UnitKind,
};

use super::ProductionError;
use super::support::{invalid, technology_for};
use crate::EngineContext;

const BASIS_POINTS: i64 = 10_000;

pub(super) fn production_per_turn(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    target: CityProductionTarget,
) -> Result<i64, ProductionError> {
    let with_wonder = crate::economy::city_turn_output(state, context, city)
        .map_err(|error| invalid(error.to_string()))?
        .production;
    target_production(state, context, city, target, with_wonder)
}

pub(super) fn target_production(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    target: CityProductionTarget,
    with_wonder: i64,
) -> Result<i64, ProductionError> {
    let with_technology = if let CityProductionTarget::Unit(_) = target {
        unit_technology_production(state, context, city, with_wonder)?
    } else {
        with_wonder
    };
    with_target_specialization(with_technology, city.specialization(), target)
}

fn unit_technology_production(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    production: i64,
) -> Result<i64, ProductionError> {
    let basis_points = technology_for(state, context, city)
        .effect_summary()
        .map_err(|error| invalid(error.to_string()))?
        .army_production_multiplier_basis_points;
    if production <= 0 || basis_points == 0 {
        return Ok(production);
    }
    let numerator = production
        .checked_mul(i64::from(basis_points))
        .and_then(|value| value.checked_add(BASIS_POINTS / 2))
        .ok_or_else(|| invalid("unit technology production overflow"))?;
    let bonus = (numerator / BASIS_POINTS).max(1);
    production
        .checked_add(bonus)
        .ok_or_else(|| invalid("unit technology production overflow"))
}

fn with_target_specialization(
    production: i64,
    specialization: Option<CitySpecializationType>,
    target: CityProductionTarget,
) -> Result<i64, ProductionError> {
    if production <= 0 {
        return Ok(0);
    }
    let boosted = matches!(
        (specialization, target),
        (
            Some(CitySpecializationType::Growth),
            CityProductionTarget::Unit(UnitKind::Worker | UnitKind::Settler)
        ) | (
            Some(CitySpecializationType::Industry),
            CityProductionTarget::Building(_)
        ) | (
            Some(CitySpecializationType::Commerce),
            CityProductionTarget::Project(CityProjectType::Wealth)
        ) | (
            Some(CitySpecializationType::Science),
            CityProductionTarget::Project(CityProjectType::Research)
        ) | (
            Some(CitySpecializationType::Military),
            CityProductionTarget::Unit(_)
        )
    );
    if boosted {
        production
            .checked_add(1)
            .ok_or_else(|| invalid("specialized production overflow"))
    } else {
        Ok(production)
    }
}

#[cfg(test)]
mod tests {
    use aonw_domain::{
        CityBuildingType, CityProductionTarget, CityProjectType, CitySpecializationType, UnitKind,
    };

    use super::with_target_specialization;

    #[test]
    fn specialization_values_and_target_bonuses_cover_every_kind() {
        for (specialization, target) in [
            (
                CitySpecializationType::Growth,
                CityProductionTarget::Unit(UnitKind::Worker),
            ),
            (
                CitySpecializationType::Growth,
                CityProductionTarget::Unit(UnitKind::Settler),
            ),
            (
                CitySpecializationType::Industry,
                CityProductionTarget::Building(CityBuildingType::Workshop),
            ),
            (
                CitySpecializationType::Commerce,
                CityProductionTarget::Project(CityProjectType::Wealth),
            ),
            (
                CitySpecializationType::Science,
                CityProductionTarget::Project(CityProjectType::Research),
            ),
            (
                CitySpecializationType::Military,
                CityProductionTarget::Unit(UnitKind::Warrior),
            ),
        ] {
            assert_eq!(
                with_target_specialization(4, Some(specialization), target).expect("bonus"),
                5
            );
        }
        assert_eq!(
            with_target_specialization(
                4,
                Some(CitySpecializationType::Growth),
                CityProductionTarget::Building(CityBuildingType::Workshop),
            )
            .expect("no bonus"),
            4
        );
        assert_eq!(
            with_target_specialization(
                0,
                Some(CitySpecializationType::Industry),
                CityProductionTarget::Building(CityBuildingType::Workshop),
            )
            .expect("zero production"),
            0
        );
    }
}
