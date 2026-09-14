use aonw_content::StrategicResourceCost;
use aonw_domain::{GameState, PlayerResearchState, ResourceType};

use crate::{EngineContext, TechnologyUnlockQuery};

/// Returns scarce stockpiled resource kinds for the recipient's unlocked units.
/// Any affordable alternative suppresses a unit's warning; otherwise the first
/// authored option supplies its missing kinds. Existing reservations are not
/// refunded because this is an empire warning, not a city replacement quote.
/// Results follow canonical resource order and contain no opponent information.
pub fn strategic_resource_shortages(
    state: &GameState,
    context: EngineContext<'_>,
) -> impl Iterator<Item = ResourceType> {
    let actor = context.actor_player_id();
    let empty = PlayerResearchState::default();
    let research = state.research().players().get(actor).unwrap_or(&empty);
    let technology = TechnologyUnlockQuery::new(context.ruleset(), research);
    let stockpile = state.economy().strategic_resources().get(actor);
    let amount = |resource| {
        stockpile
            .and_then(|value| value.amounts().get(&resource))
            .copied()
            .unwrap_or(0)
    };
    let oil = amount(ResourceType::Oil);
    let aluminium = amount(ResourceType::Aluminium);
    let mut missing = (false, false);
    for unit in context.ruleset().production().units() {
        if technology.is_unit_unlocked(unit.unit()) {
            let value = missing_for_options(unit.strategic_cost_options(), oil, aluminium);
            missing.0 |= value.0;
            missing.1 |= value.1;
        }
    }
    [
        missing.0.then_some(ResourceType::Oil),
        missing.1.then_some(ResourceType::Aluminium),
    ]
    .into_iter()
    .flatten()
}

fn missing_for_options(
    options: &[StrategicResourceCost],
    oil: i64,
    aluminium: i64,
) -> (bool, bool) {
    if options
        .iter()
        .any(|cost| cost.oil() <= oil && cost.aluminium() <= aluminium)
    {
        return (false, false);
    }
    options.first().map_or((false, false), |cost| {
        (cost.oil() > oil, cost.aluminium() > aluminium)
    })
}

#[cfg(test)]
mod tests {
    use aonw_content::RulesetDefinition;
    use aonw_domain::UnitKind;

    use super::missing_for_options;

    #[test]
    fn an_affordable_alternative_removes_the_first_options_shortage() {
        let production = RulesetDefinition::standard().production();
        let plane = production.unit(UnitKind::ReconPlane).unwrap();
        let options = plane.strategic_cost_options();
        assert_eq!(missing_for_options(options, 0, 0), (false, true));
        assert_eq!(missing_for_options(options, 1, 0), (false, false));
        assert_eq!(missing_for_options(options, 0, 1), (false, false));
        let tank = production.unit(UnitKind::Tank).unwrap();
        assert_eq!(
            missing_for_options(tank.strategic_cost_options(), 1, 10),
            (true, false)
        );
        assert_eq!(
            missing_for_options(tank.strategic_cost_options(), 2, 0),
            (false, false)
        );
        assert_eq!(missing_for_options(&[], 0, 0), (false, false));
    }
}
