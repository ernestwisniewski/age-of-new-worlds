use super::{HexImprovementAccess as Access, HexImprovementOption};
use crate::{EngineContext, TechnologyUnlockQuery};
use aonw_content::{ResourceType, TerrainType, WorkerImprovementDefinition};
use aonw_domain::{FogVisibility, GameState, HexCoord};

pub(super) fn access(state: &GameState, context: EngineContext<'_>, hex: HexCoord) -> Access {
    let actor = context.actor_player_id();
    let known = context.visibility_at(hex) != FogVisibility::Hidden;
    if state
        .infrastructure()
        .field_improvement_at(hex)
        .is_some_and(|improvement| {
            known
                || improvement.built_by_city_id().is_some_and(|id| {
                    state
                        .city(id)
                        .is_some_and(|city| city.owner_player_id() == actor)
                })
        })
    {
        return Access::AlreadyImproved;
    }
    if state
        .cities()
        .iter()
        .any(|city| city.center() == hex && (known || city.owner_player_id() == actor))
    {
        return Access::CityCenter;
    }
    state
        .cities()
        .iter()
        .find(|city| city.owner_player_id() == actor && city.controls(hex))
        .map_or(Access::OutsideControlledCity, |city| {
            Access::ControlledCity(city.id().clone())
        })
}

pub(super) fn options(
    state: &GameState,
    context: EngineContext<'_>,
    terrain: TerrainType,
    river: bool,
    resources: &[ResourceType],
    technology: TechnologyUnlockQuery<'_>,
    access: &Access,
) -> Vec<HexImprovementOption> {
    let worker = context.ruleset().worker();
    let pace = state
        .match_lifecycle()
        .identity()
        .match_rules()
        .game_length()
        .pace_profile();
    let mut options = worker
        .improvements()
        .iter()
        .copied()
        .filter(|definition| terrain_matches(*definition, terrain, river, resources))
        .map(|definition| {
            let required = technology.unlocking_technology_for_improvement(definition.kind());
            HexImprovementOption {
                kind: definition.kind(),
                required_technology: required,
                technology_unlocked: required
                    .is_none_or(|id| technology.is_technology_unlocked(id)),
                build_turns: worker.improvement_turns(definition.base_build_turns(), pace),
                yield_delta: definition.yield_delta().into(),
            }
        })
        .collect::<Vec<_>>();
    if matches!(access, Access::ControlledCity(_)) {
        options.sort_by_key(|option| !option.technology_unlocked);
    }
    options
}

fn terrain_matches(
    definition: WorkerImprovementDefinition,
    terrain: TerrainType,
    river: bool,
    resources: &[ResourceType],
) -> bool {
    (definition.required_base_terrains().is_empty()
        || definition.required_base_terrains().contains(&terrain))
        && (definition.required_resources().is_empty()
            || definition
                .required_resources()
                .iter()
                .any(|r| resources.contains(r)))
        && (!definition.requires_river() || river)
}
