use super::{
    TechnologyBoost as Boost, TechnologyBoostCondition as BoostCondition,
    TechnologyBuilding as Building, TechnologyDefinition as Tech, TechnologyEffect as Effect,
    TechnologyEra as Era, TechnologyImprovement as Improvement, TechnologyKey as Key,
    TechnologyResource as Resource, TechnologyUnit as Unit, TechnologyUnlock as Unlock,
    TechnologyWonder as Wonder,
};

mod foundation;
mod specialization;
mod strategy;

const BOOST_DISCOUNT: u32 = 2_500;

pub(crate) const STANDARD_TECHNOLOGIES: [Tech; 54] = combine(
    &foundation::TECHNOLOGIES,
    &specialization::TECHNOLOGIES,
    &strategy::TECHNOLOGIES,
);

const fn combine(first: &[Tech; 15], second: &[Tech; 30], third: &[Tech; 9]) -> [Tech; 54] {
    let mut result = [first[0]; 54];
    let mut target = 0;
    let mut source = 0;
    while source < first.len() {
        result[target] = first[source];
        source += 1;
        target += 1;
    }
    source = 0;
    while source < second.len() {
        result[target] = second[source];
        source += 1;
        target += 1;
    }
    source = 0;
    while source < third.len() {
        result[target] = third[source];
        source += 1;
        target += 1;
    }
    result
}
