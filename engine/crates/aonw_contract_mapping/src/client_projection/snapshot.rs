use aonw_contracts::client::{
    ClientSessionStampDto, CulturalVictoryProgressDto, DominationVictoryProgressDto,
    EconomyForecastDto, GoldIncomeSourceDto, MapObjectiveProgressDto, PlayerEconomyViewDto,
    PlayerFogViewDto, PlayerParticipantViewDto, PlayerResearchViewDto, PlayerVictoryViewDto,
    PlayerViewSnapshotDto, ScienceYieldBreakdownDto, ScienceYieldSourceDto,
    ScienceYieldSourceKindDto, StabilityBreakdownDto, StrategicResourceAmountDto,
    StrategicResourceSourceDto, TechnologyEraDto, UnitUpkeepBreakdownDto, UnitUpkeepSourceDto,
};

use aonw_projection::{PlayerViewSnapshot, SessionStamp};

use super::{
    artifact, city, coordinate, diplomacy, encode_pending_action, encode_turn_lifecycle,
    field_improvement, founding_draft, road, unit,
};

/// Maps a recipient-safe session identity stamp to its strict current DTO.
#[must_use]
pub fn encode_client_stamp(value: SessionStamp) -> ClientSessionStampDto {
    ClientSessionStampDto {
        revision: value.revision.get(),
        state_digest: value.state_digest.to_string(),
        map_hash: value.map_hash.to_string(),
        ruleset_hash: value.ruleset_hash.to_string(),
    }
}

/// Maps a complete recipient-safe player projection to its strict current DTO.
#[must_use]
pub fn encode_player_view_snapshot(value: &PlayerViewSnapshot) -> PlayerViewSnapshotDto {
    PlayerViewSnapshotDto {
        stamp: encode_client_stamp(*value.stamp()),
        turn: value.turn(),
        turn_mode: crate::game_state_mapping::encode_turn_mode(value.turn_mode()),
        participants: value.participants().iter().map(participant).collect(),
        fog: fog(value.fog()),
        economy: economy(value.economy()),
        research: research(value.research()),
        victory: victory(value.victory()),
        outcome: crate::encode_game_outcome(value.outcome()),
        turn_lifecycle: encode_turn_lifecycle(*value.turn_lifecycle()),
        pending_action: value.pending_action().map(encode_pending_action),
        city_founding_draft: value.city_founding_draft().map(founding_draft),
        diplomacy: diplomacy(value.diplomacy()),
        units: value.units().iter().map(unit).collect(),
        cities: value.cities().iter().map(city).collect(),
        artifacts: value.artifacts().iter().map(artifact).collect(),
        field_improvements: value
            .field_improvements()
            .iter()
            .copied()
            .map(field_improvement)
            .collect(),
        roads: value.roads().iter().copied().map(road).collect(),
    }
}

pub(super) fn victory(value: &aonw_projection::PlayerVictoryView) -> PlayerVictoryViewDto {
    PlayerVictoryViewDto {
        conquest_enabled: value.conquest_enabled(),
        domination_enabled: value.domination_enabled(),
        domination_required_control_percent: value
            .domination_required_control_percent()
            .parse()
            .expect("validated domination percentage"),
        domination_required_hold_turns: value.domination_required_hold_turns(),
        cultural_enabled: value.cultural_enabled(),
        cultural_required_artifacts: value.cultural_required_artifacts(),
        cultural_required_hold_turns: value.cultural_required_hold_turns(),
        score_fallback_enabled: value.score_fallback_enabled(),
        turn_limit: value.turn_limit(),
        remaining_turns: value.remaining_turns(),
        score_by_player_id: value
            .score_by_player_id()
            .iter()
            .map(|(player, score)| (player.as_str().to_owned(), *score))
            .collect(),
        domination: value
            .domination()
            .iter()
            .map(|progress| DominationVictoryProgressDto {
                player_id: progress.player_id().as_str().to_owned(),
                controlled_passable_hexes: progress.controlled_passable_hexes(),
                total_passable_hexes: progress.total_passable_hexes(),
                hold_turns: progress.hold_turns(),
            })
            .collect(),
        own_cultural: CulturalVictoryProgressDto {
            unique_stored_artifacts: value.own_cultural().unique_stored_artifacts(),
            hold_turns: value.own_cultural().hold_turns(),
        },
        map_objectives: value
            .map_objectives()
            .iter()
            .map(|progress| MapObjectiveProgressDto {
                objective_id: progress.objective_id().to_owned(),
                controller_player_id: progress
                    .controller_player_id()
                    .map(|player| player.as_str().to_owned()),
                hold_turns: progress.hold_turns(),
            })
            .collect(),
    }
}

pub(super) fn research(value: &aonw_projection::PlayerResearchView) -> PlayerResearchViewDto {
    PlayerResearchViewDto {
        dominant_era: technology_era(value.dominant_era()),
        active_technology_id: value.active_technology_id().map(crate::encode_technology),
        active_progress: value.active_progress(),
        active_effective_cost: value.active_effective_cost(),
        science_overflow: value.science_overflow(),
        science_yield: ScienceYieldBreakdownDto {
            total: value.science_per_turn(),
            by_city_id: value
                .science_by_city_id()
                .iter()
                .map(|(city, amount)| (city.as_str().to_owned(), *amount))
                .collect(),
            sources: value
                .science_sources()
                .iter()
                .map(|source| ScienceYieldSourceDto {
                    city_id: source.city_id().as_str().to_owned(),
                    amount: source.amount(),
                    kind: science_source_kind(source.kind()),
                })
                .collect(),
        },
    }
}

const fn science_source_kind(
    value: aonw_engine::ScienceYieldSourceKind,
) -> ScienceYieldSourceKindDto {
    match value {
        aonw_engine::ScienceYieldSourceKind::CityScience => ScienceYieldSourceKindDto::CityScience,
        aonw_engine::ScienceYieldSourceKind::CityResearchProject => {
            ScienceYieldSourceKindDto::CityResearchProject
        }
        aonw_engine::ScienceYieldSourceKind::WorldArtifact => {
            ScienceYieldSourceKindDto::WorldArtifact
        }
        aonw_engine::ScienceYieldSourceKind::WorldWonder => ScienceYieldSourceKindDto::WorldWonder,
    }
}

pub(super) fn economy(value: &aonw_projection::PlayerEconomyView) -> PlayerEconomyViewDto {
    PlayerEconomyViewDto {
        gold: value.gold(),
        war_weariness: value.war_weariness(),
        stability_net: value.stability_net(),
        strategic_resource_stockpile: value
            .strategic_resource_stockpile()
            .iter()
            .copied()
            .map(resource_amount)
            .collect(),
        strategic_resource_output: value
            .strategic_resource_output()
            .iter()
            .copied()
            .map(resource_amount)
            .collect(),
        strategic_resource_sources: value
            .strategic_resource_sources()
            .iter()
            .map(|source| StrategicResourceSourceDto {
                city_id: source.city_id().as_str().to_owned(),
                coordinate: coordinate(source.coordinate()),
                resource: crate::encode_resource(source.resource()),
                improvement: crate::encode_improvement(source.improvement()),
                amount_per_turn: source.amount_per_turn(),
            })
            .collect(),
        forecast: economy_forecast(value.forecast()),
    }
}

fn economy_forecast(value: &aonw_projection::PlayerEconomyForecastView) -> EconomyForecastDto {
    let gold_source = |source: &aonw_projection::PlayerGoldIncomeSourceView| GoldIncomeSourceDto {
        city_id: source.city_id().as_str().to_owned(),
        amount: source.amount(),
    };
    EconomyForecastDto {
        treasury: value.treasury,
        city_income: value.city_income,
        project_income: value.project_income,
        gross_income: value.gross_income,
        net_per_turn: value.net_per_turn,
        city_sources: value.city_sources.iter().map(gold_source).collect(),
        project_sources: value.project_sources.iter().map(gold_source).collect(),
        upkeep: UnitUpkeepBreakdownDto {
            upkeep_bearing_unit_count: value.upkeep.upkeep_bearing_unit_count(),
            free_unit_count: value.upkeep.free_unit_count(),
            paid_unit_count: value.upkeep.paid_unit_count(),
            total: value.upkeep.total(),
            next_worker_upkeep: value.upkeep.next_worker_upkeep(),
            sources: value
                .upkeep
                .sources()
                .iter()
                .copied()
                .map(|source| UnitUpkeepSourceDto {
                    kind: crate::encode_unit_kind(source.kind()),
                    paid_unit_count: source.paid_unit_count(),
                    amount: source.amount(),
                })
                .collect(),
        },
        stability: stability_breakdown(&value.stability),
    }
}

fn stability_breakdown(
    value: &aonw_projection::PlayerStabilityBreakdownView,
) -> StabilityBreakdownDto {
    StabilityBreakdownDto {
        base_order: value.base_order,
        building_sources: value.building_sources,
        luxury_sources: value.luxury_sources,
        technology_sources: value.technology_sources,
        artifact_sources: value.artifact_sources,
        wonder_sources: value.wonder_sources,
        city_cost: value.city_cost,
        population_cost: value.population_cost,
        cohesion_cost: value.cohesion_cost,
        conquered_city_cost: value.conquered_city_cost,
        war_weariness_cost: value.war_weariness_cost,
        hegemony_tax: value.hegemony_tax,
        source_total: value.source_total,
        cost_total: value.cost_total,
        relative_standing_adjustment: value.relative_standing_adjustment,
        effective_net: value.effective_net,
        band: stability_band(value.band),
    }
}

const fn stability_band(value: aonw_engine::StabilityBand) -> aonw_contracts::StabilityBandDto {
    match value {
        aonw_engine::StabilityBand::Content => aonw_contracts::StabilityBandDto::Content,
        aonw_engine::StabilityBand::Stable => aonw_contracts::StabilityBandDto::Stable,
        aonw_engine::StabilityBand::Strained => aonw_contracts::StabilityBandDto::Strained,
        aonw_engine::StabilityBand::Unrest => aonw_contracts::StabilityBandDto::Unrest,
    }
}

fn resource_amount(
    value: aonw_projection::PlayerStrategicResourceAmountView,
) -> StrategicResourceAmountDto {
    StrategicResourceAmountDto {
        resource: crate::encode_resource(value.resource()),
        amount: value.amount(),
    }
}

pub(super) fn fog(value: &aonw_projection::PlayerFogView) -> PlayerFogViewDto {
    PlayerFogViewDto {
        enabled: value.enabled(),
        discovered_hexes: value
            .discovered_hexes()
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
        visible_hexes: value
            .visible_hexes()
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
    }
}

fn participant(value: &aonw_projection::PlayerParticipantView) -> PlayerParticipantViewDto {
    PlayerParticipantViewDto {
        id: value.id().as_str().to_owned(),
        name: value.name().to_owned(),
        color_value: value.color_value(),
        country: crate::game_state_mapping::encode_country(value.country()),
        kind: crate::game_state_mapping::encode_player_kind(value.kind()),
    }
}

const fn technology_era(value: aonw_content::TechnologyEra) -> TechnologyEraDto {
    match value {
        aonw_content::TechnologyEra::Foundation => TechnologyEraDto::Foundation,
        aonw_content::TechnologyEra::Settlement => TechnologyEraDto::Settlement,
        aonw_content::TechnologyEra::Expansion => TechnologyEraDto::Expansion,
        aonw_content::TechnologyEra::Specialization => TechnologyEraDto::Specialization,
        aonw_content::TechnologyEra::Industry => TechnologyEraDto::Industry,
        aonw_content::TechnologyEra::Strategy => TechnologyEraDto::Strategy,
    }
}
