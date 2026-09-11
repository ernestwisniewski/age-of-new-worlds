use aonw_content::TechnologyUnlock;
use aonw_contracts::client::{
    ClientQueryResultDto, ResearchOptionDto, ScienceYieldBreakdownDto, ScienceYieldSourceDto,
    ScienceYieldSourceKindDto, TechnologyAvailabilityDto, TechnologyUnlockDto,
};
use aonw_engine::{ResearchOptions, ScienceYieldSourceKind, TechnologyAvailability};
use aonw_projection::SessionStamp;

use crate::{
    encode_city_building, encode_city_wonder, encode_client_stamp, encode_improvement,
    encode_resource, encode_technology, encode_unit_kind,
};

/// Maps the same recipient research result for local and server transports.
#[must_use]
pub fn encode_research_options(
    stamp: SessionStamp,
    value: &ResearchOptions,
) -> ClientQueryResultDto {
    ClientQueryResultDto::ResearchOptions {
        stamp: encode_client_stamp(stamp),
        player_id: value.player_id().as_str().to_owned(),
        active_technology_id: value.active_technology().map(encode_technology),
        science_overflow: value.science_overflow(),
        science_yield: ScienceYieldBreakdownDto {
            total: value.science_yield().total(),
            by_city_id: value
                .science_yield()
                .by_city_id()
                .iter()
                .map(|(city, amount)| (city.as_str().to_owned(), *amount))
                .collect(),
            sources: value
                .science_yield()
                .sources()
                .iter()
                .map(|source| ScienceYieldSourceDto {
                    city_id: source.city_id().as_str().to_owned(),
                    amount: source.amount(),
                    kind: source_kind(source.kind()),
                })
                .collect(),
        },
        recommendations: encode_recommendations(value),
        options: value
            .options()
            .iter()
            .map(|option| ResearchOptionDto {
                technology_id: encode_technology(option.technology()),
                availability: availability(option.availability()),
                effective_cost: option.effective_cost(),
                progress: option.progress(),
                boost_discount_basis_points: option.boost_discount_basis_points(),
                prerequisites: option
                    .prerequisites()
                    .iter()
                    .copied()
                    .map(encode_technology)
                    .collect(),
                blocked_by: option
                    .blocked_by()
                    .iter()
                    .copied()
                    .map(encode_technology)
                    .collect(),
                unlocks: option.unlocks().iter().copied().map(unlock).collect(),
            })
            .collect(),
    }
}

const fn source_kind(value: ScienceYieldSourceKind) -> ScienceYieldSourceKindDto {
    match value {
        ScienceYieldSourceKind::CityScience => ScienceYieldSourceKindDto::CityScience,
        ScienceYieldSourceKind::CityResearchProject => {
            ScienceYieldSourceKindDto::CityResearchProject
        }
        ScienceYieldSourceKind::WorldArtifact => ScienceYieldSourceKindDto::WorldArtifact,
        ScienceYieldSourceKind::WorldWonder => ScienceYieldSourceKindDto::WorldWonder,
    }
}

const fn availability(value: TechnologyAvailability) -> TechnologyAvailabilityDto {
    match value {
        TechnologyAvailability::Unlocked => TechnologyAvailabilityDto::Unlocked,
        TechnologyAvailability::Active => TechnologyAvailabilityDto::Active,
        TechnologyAvailability::Available => TechnologyAvailabilityDto::Available,
        TechnologyAvailability::LockedByPrerequisites => {
            TechnologyAvailabilityDto::LockedByPrerequisites
        }
        TechnologyAvailability::LockedByTechnology => TechnologyAvailabilityDto::LockedByTechnology,
    }
}

const fn unlock(value: TechnologyUnlock) -> TechnologyUnlockDto {
    match value {
        TechnologyUnlock::Building(building) => TechnologyUnlockDto::Building {
            building_type: encode_city_building(building.domain()),
        },
        TechnologyUnlock::Improvement(improvement) => TechnologyUnlockDto::Improvement {
            improvement: encode_improvement(improvement.domain()),
        },
        TechnologyUnlock::ResourceVisibility(resource) => TechnologyUnlockDto::ResourceVisibility {
            resource: encode_resource(resource.domain()),
        },
        TechnologyUnlock::Unit(unit) => TechnologyUnlockDto::Unit {
            unit_type: encode_unit_kind(unit.domain()),
        },
        TechnologyUnlock::Wonder(wonder) => TechnologyUnlockDto::Wonder {
            wonder_type: encode_city_wonder(wonder.domain()),
        },
    }
}

fn encode_recommendations(
    value: &ResearchOptions,
) -> Vec<aonw_contracts::client::ResearchRecommendationDto> {
    value
        .recommendations()
        .iter()
        .map(|entry| aonw_contracts::client::ResearchRecommendationDto {
            technology_id: encode_technology(entry.technology()),
            score: entry.score(),
            turns_remaining: entry.turns_remaining(),
            reasons: entry.reasons().map(recommendation_reason).collect(),
        })
        .collect()
}

const fn recommendation_reason(
    value: aonw_engine::ResearchRecommendationReason,
) -> aonw_contracts::client::ResearchRecommendationReasonDto {
    use aonw_contracts::client::ResearchRecommendationReasonDto as Wire;
    use aonw_engine::ResearchRecommendationReason as Core;
    match value {
        Core::Boost => Wire::Boost,
        Core::WorkerYields => Wire::WorkerYields,
        Core::Unlocks => Wire::Unlocks,
        Core::Effects => Wire::Effects,
        Core::NearCompletion => Wire::NearCompletion,
    }
}
