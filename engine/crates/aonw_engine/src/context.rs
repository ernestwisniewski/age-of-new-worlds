use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{
    City, Diplomacy, FogOfWar, FogVisibility, GameState, HexCoord, MatchIdentity, PlayerId,
    TransportNetwork, Unit,
};

use crate::movement::{
    CompiledMovementMap, MovementAccess, MovementPlanningView, MovementVisibility,
};

/// Immutable content available only to a trusted system-command boundary.
#[derive(Clone, Copy, Debug)]
pub struct SystemContext<'context> {
    map: &'context MapDefinition,
    ruleset: &'context RulesetDefinition,
}

impl<'context> SystemContext<'context> {
    /// Constructs a trusted context without player identity or presentation state.
    #[must_use]
    pub const fn canonical(
        map: &'context MapDefinition,
        ruleset: &'context RulesetDefinition,
    ) -> Self {
        Self { map, ruleset }
    }

    /// Returns the validated logical map.
    #[must_use]
    pub const fn map(self) -> &'context MapDefinition {
        self.map
    }

    /// Returns immutable rules.
    #[must_use]
    pub const fn ruleset(self) -> &'context RulesetDefinition {
        self.ruleset
    }
}

/// Immutable inputs that are authoritative for one command or query.
#[derive(Clone, Copy, Debug)]
pub struct EngineContext<'context> {
    actor_player_id: &'context PlayerId,
    map: &'context MapDefinition,
    ruleset: &'context RulesetDefinition,
    planning_view: MovementPlanningView<'context>,
    can_act: bool,
    allow_hidden_pathing: bool,
    allow_owned_city_stacking: bool,
    excluded_path_hexes: Option<&'context BTreeSet<HexCoord>>,
    world: Option<MovementWorld<'context>>,
    compiled_movement_map: Option<&'context CompiledMovementMap>,
    movement_visibility: Option<&'context MovementVisibility>,
}

#[derive(Clone, Copy, Debug)]
struct MovementWorld<'world> {
    cities: &'world [City],
    fog_of_war: &'world FogOfWar,
    diplomacy: &'world Diplomacy,
    transport_network: &'world TransportNetwork,
    match_identity: &'world MatchIdentity,
}

impl<'world> MovementWorld<'world> {
    const fn from_state(state: &'world GameState) -> Self {
        Self {
            cities: state.cities(),
            fog_of_war: state.fog_of_war(),
            diplomacy: state.diplomacy(),
            transport_network: state.transport_network(),
            match_identity: state.match_lifecycle().identity(),
        }
    }
}

impl<'context> EngineContext<'context> {
    /// Constructs canonical context. Visibility is derived from [`GameState`]
    /// by [`crate::GameEngine::apply_player_owned`] and [`crate::GameEngine::query`].
    #[must_use]
    pub const fn canonical(
        actor_player_id: &'context PlayerId,
        map: &'context MapDefinition,
        ruleset: &'context RulesetDefinition,
    ) -> Self {
        Self {
            actor_player_id,
            map,
            ruleset,
            planning_view: MovementPlanningView::fog_disabled(),
            can_act: true,
            allow_hidden_pathing: false,
            allow_owned_city_stacking: false,
            excluded_path_hexes: None,
            world: None,
            compiled_movement_map: None,
            movement_visibility: None,
        }
    }

    #[cfg(test)]
    pub(crate) const fn new(
        actor_player_id: &'context PlayerId,
        map: &'context MapDefinition,
        planning_view: MovementPlanningView<'context>,
    ) -> Self {
        Self {
            actor_player_id,
            map,
            ruleset: RulesetDefinition::standard(),
            planning_view,
            can_act: true,
            allow_hidden_pathing: false,
            allow_owned_city_stacking: false,
            excluded_path_hexes: None,
            world: None,
            compiled_movement_map: None,
            movement_visibility: None,
        }
    }

    /// Replaces the standard ruleset with an explicit validated definition.
    #[must_use]
    pub const fn with_ruleset(mut self, ruleset: &'context RulesetDefinition) -> Self {
        self.ruleset = ruleset;
        self
    }

    #[cfg(test)]
    pub(crate) const fn with_action_permission(mut self, can_act: bool) -> Self {
        self.can_act = can_act;
        self
    }

    /// Uses movement topology and terrain costs compiled for this map and ruleset.
    #[must_use]
    pub const fn with_compiled_movement_map(
        mut self,
        compiled: &'context CompiledMovementMap,
    ) -> Self {
        self.map = compiled.map();
        self.ruleset = compiled.ruleset();
        self.compiled_movement_map = Some(compiled);
        self
    }

    /// Uses tile-indexed visibility prepared for the actor and state revision.
    #[must_use]
    pub const fn with_movement_visibility(
        mut self,
        visibility: &'context MovementVisibility,
    ) -> Self {
        self.movement_visibility = Some(visibility);
        self
    }

    /// Returns the player issuing the command or query.
    #[must_use]
    pub const fn actor_player_id(self) -> &'context PlayerId {
        self.actor_player_id
    }

    /// Returns the validated logical map used by the rules engine.
    #[must_use]
    pub const fn map(self) -> &'context MapDefinition {
        self.map
    }

    /// Returns the immutable ruleset used by the operation.
    #[must_use]
    pub const fn ruleset(self) -> &'context RulesetDefinition {
        self.ruleset
    }

    /// Returns whether the application boundary authorizes gameplay actions.
    #[must_use]
    pub const fn can_act(self) -> bool {
        self.can_act
    }

    pub(crate) const fn compiled_movement_map(self) -> Option<&'context CompiledMovementMap> {
        self.compiled_movement_map
    }

    pub(crate) fn with_world<'world>(self, world: &'world GameState) -> EngineContext<'world>
    where
        'context: 'world,
    {
        EngineContext {
            actor_player_id: self.actor_player_id,
            map: self.map,
            ruleset: self.ruleset,
            planning_view: self.planning_view,
            can_act: self.can_act,
            allow_hidden_pathing: self.allow_hidden_pathing,
            allow_owned_city_stacking: self.allow_owned_city_stacking,
            excluded_path_hexes: self.excluded_path_hexes,
            world: Some(MovementWorld::from_state(world)),
            compiled_movement_map: self.compiled_movement_map,
            movement_visibility: self.movement_visibility,
        }
    }

    pub(crate) const fn with_movement_world<'world>(
        self,
        cities: &'world [City],
        fog_of_war: &'world FogOfWar,
        diplomacy: &'world Diplomacy,
        transport_network: &'world TransportNetwork,
        match_identity: &'world MatchIdentity,
    ) -> EngineContext<'world>
    where
        'context: 'world,
    {
        EngineContext {
            actor_player_id: self.actor_player_id,
            map: self.map,
            ruleset: self.ruleset,
            planning_view: self.planning_view,
            can_act: self.can_act,
            allow_hidden_pathing: self.allow_hidden_pathing,
            allow_owned_city_stacking: self.allow_owned_city_stacking,
            excluded_path_hexes: self.excluded_path_hexes,
            world: Some(MovementWorld {
                cities,
                fog_of_war,
                diplomacy,
                transport_network,
                match_identity,
            }),
            compiled_movement_map: self.compiled_movement_map,
            movement_visibility: self.movement_visibility,
        }
    }

    pub(crate) const fn with_unrestricted_hidden_pathing(mut self) -> Self {
        self.allow_hidden_pathing = true;
        self
    }

    pub(crate) const fn with_owned_city_stacking(mut self) -> Self {
        self.allow_owned_city_stacking = true;
        self
    }

    pub(crate) const fn with_excluded_path_hexes<'world>(
        self,
        excluded_path_hexes: &'world BTreeSet<HexCoord>,
    ) -> EngineContext<'world>
    where
        'context: 'world,
    {
        EngineContext {
            actor_player_id: self.actor_player_id,
            map: self.map,
            ruleset: self.ruleset,
            planning_view: self.planning_view,
            can_act: self.can_act,
            allow_hidden_pathing: self.allow_hidden_pathing,
            allow_owned_city_stacking: self.allow_owned_city_stacking,
            excluded_path_hexes: Some(excluded_path_hexes),
            world: self.world,
            compiled_movement_map: self.compiled_movement_map,
            movement_visibility: self.movement_visibility,
        }
    }

    pub(crate) fn observes_occupancy(self, moving_unit: &Unit, candidate: &Unit) -> bool {
        if candidate.owner_player_id() == moving_unit.owner_player_id() {
            return true;
        }
        self.world.map_or_else(
            || {
                self.planning_view
                    .observes_occupancy(moving_unit, candidate)
            },
            |world| {
                self.visibility(world.fog_of_war, candidate.position()) == FogVisibility::Visible
            },
        )
    }

    pub(crate) fn can_plan_through_tile(self, moving_unit: &Unit, coordinate: HexCoord) -> bool {
        if self
            .excluded_path_hexes
            .is_some_and(|excluded| excluded.contains(&coordinate))
        {
            return false;
        }
        let Some(world) = self.world else {
            return true;
        };
        if self.visibility(world.fog_of_war, coordinate) != FogVisibility::Hidden {
            return true;
        }
        if self.allow_hidden_pathing {
            return true;
        }
        moving_unit.position().distance_to(coordinate) <= 3
    }

    pub(crate) fn prepare_movement_access(self, moving_unit: &Unit) -> MovementAccess {
        let mut access = MovementAccess::empty(self.map.bounds().tile_count());
        let Some(world) = self.world else {
            return access;
        };
        for city in world.cities {
            let policy = crate::DiplomacyPolicyQuery::between_parts(
                world.match_identity,
                world.diplomacy,
                moving_unit.owner_player_id(),
                city.owner_player_id(),
            );
            let center_visible =
                self.visibility(world.fog_of_war, city.center()) != FogVisibility::Hidden;
            let center_known = city.owner_player_id() == self.actor_player_id || center_visible;
            if center_known && let Some(index) = self.map.tile_index(city.center()) {
                access.reveal_city_center(index.get());
                if center_visible
                    && policy
                        .as_ref()
                        .map_or(true, |value| !value.can_enter_city_center())
                {
                    access.block(index.get());
                }
            }
            if policy
                .as_ref()
                .is_ok_and(|value| value.can_enter_territory())
            {
                continue;
            }
            for coordinate in
                core::iter::once(city.center()).chain(city.controlled_hexes().iter().copied())
            {
                if self.visibility(world.fog_of_war, coordinate) == FogVisibility::Hidden {
                    continue;
                }
                if let Some(index) = self.map.tile_index(coordinate) {
                    access.block(index.get());
                }
            }
        }
        for segment in world.transport_network.segments() {
            if !segment.is_operational() {
                continue;
            }
            let city_owned = segment
                .built_by_city_id()
                .and_then(|city_id| {
                    world
                        .cities
                        .binary_search_by(|city| city.id().cmp(city_id))
                        .ok()
                        .map(|index| &world.cities[index])
                })
                .is_some_and(|city| city.owner_player_id() == self.actor_player_id);
            if segment.built_by_player_id() != self.actor_player_id
                && !city_owned
                && self.visibility(world.fog_of_war, segment.coordinate()) == FogVisibility::Hidden
            {
                continue;
            }
            if let Some(index) = self.map.tile_index(segment.coordinate()) {
                access.reveal_operational_road(index.get());
            }
        }
        access
    }

    pub(crate) fn can_share_occupied_city(self, moving_unit: &Unit, coordinate: HexCoord) -> bool {
        self.allow_owned_city_stacking
            && moving_unit.kind() == aonw_domain::UnitKind::Merchant
            && self.world.is_some_and(|world| {
                world.cities.iter().any(|city| {
                    city.center() == coordinate
                        && city.owner_player_id() == moving_unit.owner_player_id()
                })
            })
    }

    pub(crate) fn city_blocks(self, moving_unit: &Unit, coordinate: HexCoord) -> bool {
        self.world
            .and_then(|world| {
                world
                    .cities
                    .iter()
                    .find(|city| city.center() == coordinate)
                    .map(|city| {
                        let policy = crate::DiplomacyPolicyQuery::between_parts(
                            world.match_identity,
                            world.diplomacy,
                            moving_unit.owner_player_id(),
                            city.owner_player_id(),
                        );
                        match policy {
                            Ok(value) => !value.can_enter_city_center(),
                            Err(_) => true,
                        }
                    })
            })
            .unwrap_or(false)
    }

    pub(crate) fn city_block_is_known(self, moving_unit: &Unit, coordinate: HexCoord) -> bool {
        if !self.city_blocks(moving_unit, coordinate) {
            return false;
        }
        self.world.is_none_or(|world| {
            self.visibility(world.fog_of_war, coordinate) != FogVisibility::Hidden
        })
    }

    pub(crate) fn territory_blocks(self, moving_unit: &Unit, coordinate: HexCoord) -> bool {
        self.world
            .and_then(|world| {
                world
                    .cities
                    .iter()
                    .find(|city| {
                        city.center() == coordinate || city.controlled_hexes().contains(&coordinate)
                    })
                    .map(|city| {
                        crate::DiplomacyPolicyQuery::between_parts(
                            world.match_identity,
                            world.diplomacy,
                            moving_unit.owner_player_id(),
                            city.owner_player_id(),
                        )
                        .map_or(true, |policy| !policy.can_enter_territory())
                    })
            })
            .unwrap_or(false)
    }

    pub(crate) fn territory_block_is_known(self, moving_unit: &Unit, coordinate: HexCoord) -> bool {
        self.territory_blocks(moving_unit, coordinate)
            && self.world.is_none_or(|world| {
                self.visibility(world.fog_of_war, coordinate) != FogVisibility::Hidden
            })
    }

    pub(crate) fn visibility_at(self, coordinate: HexCoord) -> FogVisibility {
        self.world.map_or(FogVisibility::Visible, |world| {
            self.visibility(world.fog_of_war, coordinate)
        })
    }

    pub(crate) fn routing_fingerprint(self) -> &'context str {
        self.world
            .map_or("", |world| world.transport_network.routing_fingerprint())
    }

    fn visibility(self, fog: &FogOfWar, coordinate: HexCoord) -> FogVisibility {
        self.movement_visibility.map_or_else(
            || fog.visibility(self.actor_player_id, coordinate),
            |visibility| visibility.at(self.map, coordinate),
        )
    }
}
use std::collections::BTreeSet;
