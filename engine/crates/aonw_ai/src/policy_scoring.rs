use aonw_domain::{
    CityProductionTarget, CityProjectType, DiplomaticMessageResponse, DiplomaticProposalKind,
    TechnologyId, UnitKind,
};
use aonw_engine::{ProductionOption, ResearchOption};

use crate::{
    AiPersona, AiProfile, StrategicAssessment, StrategicGoal, StrategicMode, UtilityScore,
};

pub(crate) fn research_utility(
    option: &ResearchOption,
    assessment: &StrategicAssessment,
    profile: AiProfile,
) -> UtilityScore {
    let weights = profile.weights();
    let branch = technology_branch(option.technology());
    let weight = match branch {
        UtilityBranch::Military => weights.aggression(),
        UtilityBranch::Expansion => weights.expansion(),
        UtilityBranch::Economy => weights.economy(),
        UtilityBranch::Science => weights.science(),
    };
    let goal_bonus = i64::from(branch_matches_goal(
        branch,
        assessment.primary_goal().goal(),
    )) * 12_000;
    let mode_bonus = i64::from(branch_matches_mode(branch, assessment.mode())) * 8_000;
    let progress = option.progress().clamp(0, 10_000).saturating_mul(20);
    let boost = i64::from(option.boost_discount_basis_points()) * 2;
    let cost = i64::from(option.effective_cost()) * 60;
    UtilityScore::new(i64::from(weight) * 4 + goal_bonus + mode_bonus + progress + boost - cost)
}

pub(crate) fn production_utility(
    option: ProductionOption,
    assessment: &StrategicAssessment,
    profile: AiProfile,
) -> UtilityScore {
    let weights = profile.weights();
    let empire = assessment.empire();
    let (weight, deficit_bonus) = match option.target() {
        CityProductionTarget::Unit(UnitKind::Settler) => (
            weights.expansion(),
            i64::from(empire.needs_settler()) * 32_000,
        ),
        CityProductionTarget::Unit(UnitKind::Worker) => {
            (weights.economy(), i64::from(empire.needs_worker()) * 32_000)
        }
        CityProductionTarget::Unit(UnitKind::Merchant) => (weights.economy(), 8_000),
        CityProductionTarget::Unit(UnitKind::Scout) => (weights.expansion(), 6_000),
        CityProductionTarget::Unit(_) => (
            weights.aggression(),
            i64::from(empire.needs_military()) * 32_000,
        ),
        CityProductionTarget::Project(CityProjectType::Research) => (weights.science(), 4_000),
        CityProductionTarget::Project(CityProjectType::Wealth) => (weights.economy(), 4_000),
        CityProductionTarget::Building(_) => (weights.economy(), 10_000),
        CityProductionTarget::Wonder(_) => {
            (u32::midpoint(weights.science(), weights.economy()), 12_000)
        }
    };
    let mode_bonus = production_mode_bonus(assessment.mode(), option.target());
    UtilityScore::new(
        i64::from(weight) * 4 + deficit_bonus + mode_bonus - option.cost().saturating_mul(60),
    )
}

const fn production_mode_bonus(mode: StrategicMode, target: CityProductionTarget) -> i64 {
    match (mode, target) {
        (StrategicMode::Military, CityProductionTarget::Unit(kind))
            if crate::strategy::is_military(kind) =>
        {
            16_000
        }
        (StrategicMode::Expand, CityProductionTarget::Unit(UnitKind::Settler))
        | (StrategicMode::TechRush, CityProductionTarget::Project(CityProjectType::Research)) => {
            16_000
        }
        (StrategicMode::Consolidate, CityProductionTarget::Building(_)) => 12_000,
        _ => 0,
    }
}

pub(crate) fn combat_is_acceptable(
    outgoing_maximum: u32,
    retaliation_maximum: u32,
    profile: AiProfile,
) -> bool {
    if retaliation_maximum == 0 {
        return true;
    }
    let aggression = profile.weights().aggression();
    let risk = profile.difficulty().combat_risk_basis_points();
    u128::from(outgoing_maximum) * u128::from(aggression) * u128::from(risk)
        >= u128::from(retaliation_maximum) * 100_000_000
}

pub(crate) fn accept_proposal(
    kind: DiplomaticProposalKind,
    assessment: &StrategicAssessment,
    profile: AiProfile,
) -> bool {
    match (profile.persona(), kind) {
        (AiPersona::Aggressive, DiplomaticProposalKind::Friendship) => false,
        (AiPersona::Aggressive, DiplomaticProposalKind::Truce) => {
            assessment.empire().visible_enemy_military_count()
                > assessment.empire().military_count()
        }
        _ => true,
    }
}

pub(crate) fn message_response(
    mode: StrategicMode,
    profile: AiProfile,
) -> DiplomaticMessageResponse {
    match (profile.persona(), mode) {
        (AiPersona::Aggressive, StrategicMode::Military) => DiplomaticMessageResponse::Aggressive,
        (AiPersona::Aggressive, _) => DiplomaticMessageResponse::Evasive,
        (AiPersona::Economic | AiPersona::Scientific, _) => DiplomaticMessageResponse::Conciliatory,
        (AiPersona::Balanced | AiPersona::Expansive, _) => DiplomaticMessageResponse::Neutral,
    }
}

pub(crate) const fn production_order(target: CityProductionTarget) -> (u8, u16) {
    match target {
        CityProductionTarget::Building(value) => (0, value as u16),
        CityProductionTarget::Unit(value) => (1, value as u16),
        CityProductionTarget::Project(value) => (2, value as u16),
        CityProductionTarget::Wonder(value) => (3, value as u16),
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum UtilityBranch {
    Military,
    Expansion,
    Economy,
    Science,
}

const fn technology_branch(technology: TechnologyId) -> UtilityBranch {
    use TechnologyId::{
        Administration, AdvancedTrade, Agriculture, AnimalHusbandry, Banking, Bureaucracy,
        Cartography, CivilService, CoalMining, Combustion, Construction, Craftsmanship, Economy,
        Education, Electricity, Engineering, Fishing, Flight, Fortifications, Guilds,
        HorsebackRiding, Hunting, IronWorking, Irrigation, Law, Logistics, Machinery,
        MassProduction, Mathematics, Medicine, Metallurgy, MilitaryOrganization, Mining,
        Nationalism, NavalDoctrine, Navigation, NuclearPhysics, Radio, ScientificMethod,
        Shipbuilding, Siegecraft, Specialization, SteamPower, Steel, Stoneworking, Storage,
        Strategy, Tactics, Trade, UrbanPlanning, Urbanization, WaterEngineering, Woodworking,
        Writing,
    };
    match technology {
        Hunting | MilitaryOrganization | HorsebackRiding | Logistics | Tactics | Fortifications
        | Strategy | Siegecraft | NavalDoctrine | Steel | Nationalism | Flight => {
            UtilityBranch::Military
        }
        Agriculture | AnimalHusbandry | Fishing | Storage | WaterEngineering | Navigation
        | Irrigation | Construction | Administration | Shipbuilding | Urbanization | Medicine
        | Cartography | UrbanPlanning => UtilityBranch::Expansion,
        Mining | Woodworking | Craftsmanship | Trade | Stoneworking | AdvancedTrade | Banking
        | Engineering | Metallurgy | IronWorking | CoalMining | Machinery | Economy | Guilds
        | SteamPower | Electricity | Combustion | MassProduction => UtilityBranch::Economy,
        Specialization | Writing | Mathematics | CivilService | Law | Education | Bureaucracy
        | ScientificMethod | Radio | NuclearPhysics => UtilityBranch::Science,
    }
}

const fn branch_matches_goal(branch: UtilityBranch, goal: StrategicGoal) -> bool {
    matches!(
        (branch, goal),
        (UtilityBranch::Military, StrategicGoal::Defend)
            | (UtilityBranch::Expansion, StrategicGoal::Expand)
            | (UtilityBranch::Economy, StrategicGoal::DevelopEconomy)
            | (UtilityBranch::Science, StrategicGoal::AdvanceScience)
    )
}

const fn branch_matches_mode(branch: UtilityBranch, mode: StrategicMode) -> bool {
    matches!(
        (branch, mode),
        (UtilityBranch::Military, StrategicMode::Military)
            | (UtilityBranch::Expansion, StrategicMode::Expand)
            | (UtilityBranch::Economy, StrategicMode::Consolidate)
            | (UtilityBranch::Science, StrategicMode::TechRush)
    )
}

#[cfg(test)]
mod tests {
    use aonw_domain::{
        CityId, CityProductionTarget, DiplomaticMessageResponse, DiplomaticProposalKind, UnitKind,
    };
    use aonw_local_runtime::{ProductionOptionsRequest, RuntimeQuery, RuntimeQueryResult};

    use super::{
        accept_proposal, combat_is_acceptable, message_response, production_mode_bonus,
        production_order, production_utility,
    };
    use crate::{AiDifficulty, AiPersona, AiProfile, StrategicAssessment};

    #[test]
    fn profile_changes_combat_and_diplomatic_decisions() {
        let easy = AiProfile::new(AiDifficulty::Easy, AiPersona::Balanced);
        let aggressive = AiProfile::new(AiDifficulty::VeryHard, AiPersona::Aggressive);
        assert!(!combat_is_acceptable(9, 10, easy));
        assert!(combat_is_acceptable(9, 10, aggressive));
        assert!(combat_is_acceptable(1, 0, easy));
        assert!(!combat_is_acceptable(
            10,
            10,
            AiProfile::new(AiDifficulty::Hard, AiPersona::Balanced)
        ));
        assert_eq!(
            production_order(CityProductionTarget::Unit(UnitKind::Worker)),
            (1, 4)
        );
        assert_eq!(
            production_order(CityProductionTarget::Project(
                aonw_domain::CityProjectType::Research
            )),
            (2, 1)
        );
        assert_eq!(
            production_order(CityProductionTarget::Wonder(
                aonw_domain::WonderType::GreatLibrary
            )),
            (3, 0)
        );
        assert_eq!(
            production_mode_bonus(
                crate::StrategicMode::Military,
                CityProductionTarget::Unit(UnitKind::Warrior)
            ),
            16_000
        );
        assert_eq!(
            message_response(crate::StrategicMode::Military, aggressive),
            DiplomaticMessageResponse::Aggressive
        );
    }

    #[test]
    fn utility_visits_every_production_family_and_diplomatic_profile() {
        let mut runtime = crate::mcts_search::tests::opened_runtime();
        let snapshot = runtime.snapshot().expect("snapshot");
        let profile = AiProfile::new(AiDifficulty::VeryHard, AiPersona::Expansive);
        let assessment = StrategicAssessment::from_snapshot(&snapshot, profile);
        let aggressive = AiProfile::new(AiDifficulty::VeryHard, AiPersona::Aggressive);
        let aggressive_assessment = StrategicAssessment::from_snapshot(&snapshot, aggressive);
        let result = runtime
            .query(&RuntimeQuery::ProductionOptions(ProductionOptionsRequest {
                expected_revision: 0,
                city_id: CityId::new("city-1").expect("city"),
            }))
            .expect("production options");
        let RuntimeQueryResult::ProductionOptions { options, .. } = result else {
            panic!("production result")
        };
        let scores = options
            .buildings()
            .iter()
            .copied()
            .chain(
                options
                    .units()
                    .iter()
                    .map(aonw_engine::UnitProductionOption::option),
            )
            .chain(options.projects().iter().copied())
            .chain(options.wonders().iter().copied())
            .map(|option| production_utility(option, &assessment, profile).get())
            .collect::<Vec<_>>();
        assert!(scores.len() > 20);
        let available = options
            .buildings()
            .iter()
            .copied()
            .chain(
                options
                    .units()
                    .iter()
                    .map(aonw_engine::UnitProductionOption::option),
            )
            .chain(options.wonders().iter().copied())
            .filter(|option| option.is_available())
            .collect::<Vec<_>>();
        let expansive_target = available
            .iter()
            .max_by_key(|option| production_utility(**option, &assessment, profile))
            .expect("expansive option")
            .target();
        let aggressive_target = available
            .iter()
            .max_by_key(|option| production_utility(**option, &aggressive_assessment, aggressive))
            .expect("aggressive option")
            .target();
        assert_ne!(expansive_target, aggressive_target);
        assert_eq!(
            message_response(
                assessment.mode(),
                AiProfile::new(AiDifficulty::Normal, AiPersona::Aggressive)
            ),
            DiplomaticMessageResponse::Evasive
        );
        assert_eq!(
            message_response(
                assessment.mode(),
                AiProfile::new(AiDifficulty::Normal, AiPersona::Scientific)
            ),
            DiplomaticMessageResponse::Conciliatory
        );
        assert!(!accept_proposal(
            DiplomaticProposalKind::Truce,
            &assessment,
            AiProfile::new(AiDifficulty::Hard, AiPersona::Aggressive)
        ));
    }
}
