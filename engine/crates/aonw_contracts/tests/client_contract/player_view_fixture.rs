use std::collections::BTreeMap;

use aonw_contracts::client::{
    ClientSessionStampDto, CulturalVictoryProgressDto, DominationVictoryProgressDto,
    EconomyForecastDto, GoldIncomeSourceDto, MapObjectiveProgressDto, PlayerEconomyViewDto,
    PlayerResearchViewDto, PlayerUnitViewDto, PlayerVictoryViewDto, ScienceYieldBreakdownDto,
    ScienceYieldSourceDto, ScienceYieldSourceKindDto, StabilityBreakdownDto,
    StrategicResourceAmountDto, StrategicResourceSourceDto, UnitUpkeepBreakdownDto,
    UnitUpkeepSourceDto,
};
use aonw_contracts::{
    CoordinateDto, FieldImprovementKindDto, ResourceTypeDto, StabilityBandDto, TechnologyIdDto,
    UnitKindDto, UnitPostureDto,
};

pub(super) fn coordinate(col: i32, row: i32) -> CoordinateDto {
    CoordinateDto { col, row }
}

pub(super) fn stamp() -> ClientSessionStampDto {
    ClientSessionStampDto {
        revision: 8,
        state_digest: "digest-8".to_owned(),
        map_hash: "map-hash".to_owned(),
        ruleset_hash: "ruleset-hash".to_owned(),
    }
}

pub(super) fn unit() -> PlayerUnitViewDto {
    PlayerUnitViewDto {
        id: "unit-1".to_owned(),
        owner_player_id: "player-1".to_owned(),
        kind: UnitKindDto::Commander,
        name: "Commander".to_owned(),
        coordinate: coordinate(3, 4),
        movement_units: 8,
        posture: UnitPostureDto::Active,
        hit_points: Some(7),
        maximum_hit_points: Some(10),
        carried_artifact_id: None,
        owned_details: None,
    }
}

pub(super) fn economy() -> PlayerEconomyViewDto {
    PlayerEconomyViewDto {
        gold: 125,
        war_weariness: 3,
        stability_net: -2,
        strategic_resource_stockpile: vec![StrategicResourceAmountDto {
            resource: ResourceTypeDto::Oil,
            amount: 4,
        }],
        strategic_resource_output: vec![StrategicResourceAmountDto {
            resource: ResourceTypeDto::Oil,
            amount: 1,
        }],
        strategic_resource_sources: vec![StrategicResourceSourceDto {
            city_id: "city-1".to_owned(),
            coordinate: coordinate(3, 4),
            resource: ResourceTypeDto::Oil,
            improvement: FieldImprovementKindDto::OilWell,
            amount_per_turn: 1,
        }],
        forecast: EconomyForecastDto {
            treasury: 125,
            city_income: 7,
            project_income: 2,
            gross_income: 9,
            net_per_turn: 5,
            city_sources: vec![GoldIncomeSourceDto {
                city_id: "city-1".to_owned(),
                amount: 7,
            }],
            project_sources: vec![GoldIncomeSourceDto {
                city_id: "city-1".to_owned(),
                amount: 2,
            }],
            upkeep: UnitUpkeepBreakdownDto {
                upkeep_bearing_unit_count: 6,
                free_unit_count: 4,
                paid_unit_count: 2,
                total: 4,
                next_worker_upkeep: 2,
                sources: vec![UnitUpkeepSourceDto {
                    kind: UnitKindDto::Warrior,
                    paid_unit_count: 2,
                    amount: 4,
                }],
            },
            stability: StabilityBreakdownDto {
                base_order: 6,
                building_sources: 1,
                luxury_sources: 1,
                technology_sources: 2,
                artifact_sources: 1,
                wonder_sources: 0,
                city_cost: 2,
                population_cost: 1,
                cohesion_cost: 0,
                conquered_city_cost: 0,
                war_weariness_cost: 3,
                hegemony_tax: 1,
                source_total: 11,
                cost_total: 7,
                relative_standing_adjustment: -1,
                effective_net: 3,
                band: StabilityBandDto::Stable,
            },
        },
    }
}

pub(super) fn research() -> PlayerResearchViewDto {
    PlayerResearchViewDto {
        active_technology_id: Some(TechnologyIdDto::Agriculture),
        active_progress: Some(9),
        active_effective_cost: Some(42),
        science_overflow: 1,
        science_yield: ScienceYieldBreakdownDto {
            total: 3,
            by_city_id: BTreeMap::from([("city-1".to_owned(), 3)]),
            sources: vec![ScienceYieldSourceDto {
                city_id: "city-1".to_owned(),
                amount: 3,
                kind: ScienceYieldSourceKindDto::CityScience,
            }],
        },
    }
}

pub(super) fn victory() -> PlayerVictoryViewDto {
    PlayerVictoryViewDto {
        conquest_enabled: true,
        domination_enabled: true,
        domination_required_control_percent: 60.into(),
        domination_required_hold_turns: 5,
        cultural_enabled: true,
        cultural_required_artifacts: 6,
        cultural_required_hold_turns: 5,
        score_fallback_enabled: true,
        turn_limit: Some(20),
        remaining_turns: Some(13),
        score_by_player_id: BTreeMap::from([("player-1".to_owned(), 37)]),
        domination: vec![DominationVictoryProgressDto {
            player_id: "player-1".to_owned(),
            controlled_passable_hexes: 3,
            total_passable_hexes: 10,
            hold_turns: 0,
        }],
        own_cultural: CulturalVictoryProgressDto {
            unique_stored_artifacts: 2,
            hold_turns: 0,
        },
        map_objectives: vec![MapObjectiveProgressDto {
            objective_id: "central-ruins".to_owned(),
            controller_player_id: Some("player-1".to_owned()),
            hold_turns: 2,
        }],
    }
}
