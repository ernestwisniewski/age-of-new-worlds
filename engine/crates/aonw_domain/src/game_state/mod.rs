mod error;
pub(crate) mod turn_update;
mod validation;

pub use error::GameStateBuildError;

use crate::{
    ArtifactId, City, CityId, CombatState, Diplomacy, EconomyState, FieldImprovement, FogOfWar,
    GameOutcome, HexCoord, HexGridBounds, InfrastructureState, InteractionState, KnowledgeState,
    MatchLifecycle, ObjectiveState, PlayerId, ResearchState, StateRevision, TransportNetwork, Unit,
    UnitId, WonderRegistry, WorldArtifact,
};
use validation::{
    city_territory_indices, unit_position_indices, validate_artifact_ids, validate_artifacts,
    validate_environment, validate_interaction, validate_player_references, validate_wonder_hosts,
};

/// Occupancy policy selected by the immutable ruleset.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum UnitOccupancyPolicy {
    Exclusive,
    FriendlyStacking,
}

impl UnitOccupancyPolicy {
    /// Returns whether two owners may share a coordinate.
    #[must_use]
    pub fn permits(self, left: &PlayerId, right: &PlayerId) -> bool {
        matches!(self, Self::FriendlyStacking) && left == right
    }
}

#[cfg(test)]
mod tests;

/// Canonical aggregate root for one atomic game simulation.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct GameState {
    revision: StateRevision,
    turn: u32,
    match_lifecycle: MatchLifecycle,
    economy: EconomyState,
    knowledge: KnowledgeState,
    combat: CombatState,
    objectives: ObjectiveState,
    outcome: GameOutcome,
    bounds: HexGridBounds,
    occupancy_policy: UnitOccupancyPolicy,
    units: Box<[Unit]>,
    unit_indices_by_position: Box<[usize]>,
    cities: Box<[City]>,
    city_territory_indices: Box<[(HexCoord, usize)]>,
    artifacts: Box<[WorldArtifact]>,
    interaction: InteractionState,
    fog_of_war: FogOfWar,
    diplomacy: Diplomacy,
    infrastructure: InfrastructureState,
}

/// Incrementally assembles one canonical state without exposing a partially
/// validated [`GameState`].
#[must_use = "the state is not validated until try_build is called"]
pub struct GameStateBuilder {
    revision: StateRevision,
    turn: u32,
    match_lifecycle: MatchLifecycle,
    economy: EconomyState,
    knowledge: KnowledgeState,
    combat: CombatState,
    objectives: ObjectiveState,
    outcome: GameOutcome,
    bounds: HexGridBounds,
    occupancy_policy: UnitOccupancyPolicy,
    units: Vec<Unit>,
    cities: Vec<City>,
    artifacts: Vec<WorldArtifact>,
    interaction: InteractionState,
    fog_of_war: FogOfWar,
    diplomacy: Diplomacy,
    infrastructure: InfrastructureState,
}

impl GameStateBuilder {
    fn new(
        revision: StateRevision,
        turn: u32,
        bounds: HexGridBounds,
        occupancy_policy: UnitOccupancyPolicy,
        units: impl IntoIterator<Item = Unit>,
    ) -> Self {
        Self {
            revision,
            turn,
            match_lifecycle: MatchLifecycle::default(),
            economy: EconomyState::default(),
            knowledge: KnowledgeState::default(),
            combat: CombatState::default(),
            objectives: ObjectiveState::default(),
            outcome: GameOutcome::default(),
            bounds,
            occupancy_policy,
            units: units.into_iter().collect(),
            cities: Vec::new(),
            artifacts: Vec::new(),
            interaction: InteractionState::default(),
            fog_of_war: FogOfWar::default(),
            diplomacy: Diplomacy::default(),
            infrastructure: InfrastructureState::default(),
        }
    }

    /// Replaces the default match identity and turn lifecycle.
    pub fn with_match_lifecycle(mut self, value: MatchLifecycle) -> Self {
        self.match_lifecycle = value;
        self
    }

    /// Replaces the default economy section.
    pub fn with_economy(mut self, value: EconomyState) -> Self {
        self.economy = value;
        self
    }

    /// Replaces the default research and wonder section.
    pub fn with_knowledge(mut self, value: KnowledgeState) -> Self {
        self.knowledge = value;
        self
    }

    /// Replaces the default pending-combat section.
    pub fn with_combat(mut self, value: CombatState) -> Self {
        self.combat = value;
        self
    }

    /// Replaces the default objective-progress section.
    pub fn with_objectives(mut self, value: ObjectiveState) -> Self {
        self.objectives = value;
        self
    }

    /// Replaces the default ongoing match result.
    pub fn with_outcome(mut self, value: GameOutcome) -> Self {
        self.outcome = value;
        self
    }

    /// Replaces the empty city collection.
    pub fn with_cities(mut self, values: impl IntoIterator<Item = City>) -> Self {
        self.cities = values.into_iter().collect();
        self
    }

    /// Replaces the empty artifact collection.
    pub fn with_artifacts(mut self, values: impl IntoIterator<Item = WorldArtifact>) -> Self {
        self.artifacts = values.into_iter().collect();
        self
    }

    /// Replaces the default interaction state.
    pub fn with_interaction(mut self, value: InteractionState) -> Self {
        self.interaction = value;
        self
    }

    /// Replaces the default fog state.
    pub fn with_fog_of_war(mut self, value: FogOfWar) -> Self {
        self.fog_of_war = value;
        self
    }

    /// Replaces the default diplomacy state.
    pub fn with_diplomacy(mut self, value: Diplomacy) -> Self {
        self.diplomacy = value;
        self
    }

    /// Replaces the default infrastructure section.
    pub fn with_infrastructure(mut self, value: InfrastructureState) -> Self {
        self.infrastructure = value;
        self
    }

    /// Uses a transport-only infrastructure section.
    pub fn with_transport_network(mut self, value: TransportNetwork) -> Self {
        self.infrastructure = InfrastructureState::from_transport(value);
        self
    }

    /// Validates every local and cross-section invariant and constructs the
    /// canonical aggregate atomically.
    ///
    /// # Errors
    ///
    /// Returns [`GameStateBuildError`] when any aggregate invariant is
    /// violated. No partially validated [`GameState`] is returned.
    pub fn try_build(mut self) -> Result<GameState, GameStateBuildError> {
        if !self
            .units
            .windows(2)
            .all(|pair| pair[0].id() <= pair[1].id())
        {
            self.units
                .sort_unstable_by(|left, right| left.id().cmp(right.id()));
        }
        if !self
            .cities
            .windows(2)
            .all(|pair| pair[0].id() <= pair[1].id())
        {
            self.cities
                .sort_unstable_by(|left, right| left.id().cmp(right.id()));
        }
        if !self
            .artifacts
            .windows(2)
            .all(|pair| pair[0].id() <= pair[1].id())
        {
            self.artifacts
                .sort_unstable_by(|left, right| left.id().cmp(right.id()));
        }
        let unit_indices_by_position =
            unit_position_indices(self.bounds, self.occupancy_policy, &self.units)?;
        let city_territory_indices = city_territory_indices(self.bounds, &self.cities)?;
        validate_artifact_ids(&self.artifacts)?;
        validate_player_references(
            self.match_lifecycle.identity(),
            &self.units,
            &self.cities,
            &self.interaction,
            &self.fog_of_war,
            &self.diplomacy,
        )?;
        validate_artifacts(self.bounds, &self.units, &self.cities, &self.artifacts)?;
        validate_interaction(self.bounds, &self.units, &self.cities, &self.interaction)?;
        validate_environment(
            self.bounds,
            self.match_lifecycle.identity(),
            &self.cities,
            &self.fog_of_war,
            &self.infrastructure,
        )?;
        self.economy
            .validate_for(self.match_lifecycle.identity(), self.bounds)
            .map_err(GameStateBuildError::InvalidEconomy)?;
        self.knowledge
            .validate_for(self.match_lifecycle.identity())
            .map_err(GameStateBuildError::InvalidKnowledge)?;
        validate_wonder_hosts(&self.cities, self.knowledge.wonder_registry())?;
        self.combat
            .validate_for(self.match_lifecycle.identity(), self.bounds, &self.units)
            .map_err(GameStateBuildError::InvalidCombat)?;
        self.objectives
            .validate_for(self.match_lifecycle.identity())
            .map_err(GameStateBuildError::InvalidObjectives)?;
        self.outcome
            .validate_for(self.match_lifecycle.identity())
            .map_err(GameStateBuildError::InvalidOutcome)?;
        Ok(self.build_with_indices(unit_indices_by_position, city_territory_indices))
    }

    fn build_with_indices(
        self,
        unit_indices_by_position: Vec<usize>,
        city_territory_indices: Vec<(HexCoord, usize)>,
    ) -> GameState {
        GameState {
            revision: self.revision,
            turn: self.turn,
            match_lifecycle: self.match_lifecycle,
            economy: self.economy,
            knowledge: self.knowledge,
            combat: self.combat,
            objectives: self.objectives,
            outcome: self.outcome,
            bounds: self.bounds,
            occupancy_policy: self.occupancy_policy,
            units: self.units.into_boxed_slice(),
            unit_indices_by_position: unit_indices_by_position.into_boxed_slice(),
            cities: self.cities.into_boxed_slice(),
            city_territory_indices: city_territory_indices.into_boxed_slice(),
            artifacts: self.artifacts.into_boxed_slice(),
            interaction: self.interaction,
            fog_of_war: self.fog_of_war,
            diplomacy: self.diplomacy,
            infrastructure: self.infrastructure,
        }
    }
}

impl GameState {
    /// Starts an aggregate builder with required identity, topology and units.
    pub fn builder(
        revision: StateRevision,
        turn: u32,
        bounds: HexGridBounds,
        occupancy_policy: UnitOccupancyPolicy,
        units: impl IntoIterator<Item = Unit>,
    ) -> GameStateBuilder {
        GameStateBuilder::new(revision, turn, bounds, occupancy_policy, units)
    }

    /// Validates map bounds, unique identifiers and one-unit occupancy.
    ///
    /// # Errors
    ///
    /// Returns [`GameStateBuildError`] when aggregate invariants are violated.
    pub fn try_new(
        revision: StateRevision,
        turn: u32,
        bounds: HexGridBounds,
        occupancy_policy: UnitOccupancyPolicy,
        units: impl IntoIterator<Item = Unit>,
    ) -> Result<Self, GameStateBuildError> {
        Self::builder(revision, turn, bounds, occupancy_policy, units).try_build()
    }

    /// Consumes a scenario seed and binds complete match-start state atomically.
    ///
    /// # Errors
    ///
    /// Returns [`GameStateBuildError`] when participant ownership, fog, or any
    /// other cross-section invariant is violated by the bound match.
    pub fn into_started_match(
        self,
        match_lifecycle: MatchLifecycle,
        fog_of_war: FogOfWar,
        diplomacy: Diplomacy,
    ) -> Result<Self, GameStateBuildError> {
        self.into_builder()
            .with_match_lifecycle(match_lifecycle)
            .with_fog_of_war(fog_of_war)
            .with_diplomacy(diplomacy)
            .try_build()
    }

    /// Returns the state revision.
    #[must_use]
    pub const fn revision(&self) -> StateRevision {
        self.revision
    }
    /// Returns the current turn.
    #[must_use]
    pub const fn turn(&self) -> u32 {
        self.turn
    }
    /// Returns canonical match identity and current lifecycle.
    #[must_use]
    pub const fn match_lifecycle(&self) -> &MatchLifecycle {
        &self.match_lifecycle
    }
    /// Returns canonical player economy and match-start resource placement.
    #[must_use]
    pub const fn economy(&self) -> &EconomyState {
        &self.economy
    }
    /// Returns canonical research and global wonder state.
    #[must_use]
    pub const fn knowledge(&self) -> &KnowledgeState {
        &self.knowledge
    }
    /// Returns canonical per-player research.
    #[must_use]
    pub const fn research(&self) -> &ResearchState {
        self.knowledge.research()
    }
    /// Returns the global completed-wonder registry.
    #[must_use]
    pub const fn wonder_registry(&self) -> &WonderRegistry {
        self.knowledge.wonder_registry()
    }
    /// Returns pending simultaneous-combat declarations.
    #[must_use]
    pub const fn combat(&self) -> &CombatState {
        &self.combat
    }
    /// Returns persisted victory and map-objective hold progress.
    #[must_use]
    pub const fn objectives(&self) -> &ObjectiveState {
        &self.objectives
    }
    /// Returns the persisted authoritative match result.
    #[must_use]
    pub const fn outcome(&self) -> &GameOutcome {
        &self.outcome
    }
    /// Returns logical map bounds.
    #[must_use]
    pub const fn bounds(&self) -> HexGridBounds {
        self.bounds
    }
    /// Returns the occupancy policy validated by this aggregate.
    #[must_use]
    pub const fn occupancy_policy(&self) -> UnitOccupancyPolicy {
        self.occupancy_policy
    }
    /// Returns canonical units in identifier order.
    #[must_use]
    pub const fn units(&self) -> &[Unit] {
        &self.units
    }
    /// Returns cities in identifier order.
    #[must_use]
    pub const fn cities(&self) -> &[City] {
        &self.cities
    }
    /// Returns artifacts in identifier order.
    #[must_use]
    pub const fn artifacts(&self) -> &[WorldArtifact] {
        &self.artifacts
    }
    /// Returns rule-relevant interaction state.
    #[must_use]
    pub const fn interaction(&self) -> &InteractionState {
        &self.interaction
    }
    /// Returns canonical fog state.
    #[must_use]
    pub const fn fog_of_war(&self) -> &FogOfWar {
        &self.fog_of_war
    }
    /// Returns canonical diplomacy state.
    #[must_use]
    pub const fn diplomacy(&self) -> &Diplomacy {
        &self.diplomacy
    }
    /// Returns canonical transport infrastructure.
    #[must_use]
    pub const fn transport_network(&self) -> &TransportNetwork {
        self.infrastructure.transport_network()
    }
    /// Returns complete economic and transport infrastructure.
    #[must_use]
    pub const fn infrastructure(&self) -> &InfrastructureState {
        &self.infrastructure
    }
    /// Returns economic field improvements in coordinate order.
    #[must_use]
    pub const fn field_improvements(&self) -> &[FieldImprovement] {
        self.infrastructure.field_improvements()
    }
    /// Finds a unit through the deterministic secondary index.
    #[must_use]
    pub fn unit(&self, unit_id: &UnitId) -> Option<&Unit> {
        self.units
            .binary_search_by(|unit| unit.id().cmp(unit_id))
            .ok()
            .map(|index| &self.units[index])
    }
    /// Finds a city through the deterministic secondary index.
    #[must_use]
    pub fn city(&self, city_id: &CityId) -> Option<&City> {
        self.cities
            .binary_search_by(|city| city.id().cmp(city_id))
            .ok()
            .map(|index| &self.cities[index])
    }
    /// Finds an artifact through the deterministic secondary index.
    #[must_use]
    pub fn artifact(&self, artifact_id: &ArtifactId) -> Option<&WorldArtifact> {
        self.artifacts
            .binary_search_by(|artifact| artifact.id().cmp(artifact_id))
            .ok()
            .map(|index| &self.artifacts[index])
    }

    /// Finds the first city center at a coordinate.
    #[must_use]
    pub fn city_at(&self, coordinate: HexCoord) -> Option<&City> {
        self.city_controlling(coordinate)
            .filter(|city| city.center() == coordinate)
    }

    /// Finds the city controlling a coordinate through the revision-scoped tile index.
    #[must_use]
    pub fn city_controlling(&self, coordinate: HexCoord) -> Option<&City> {
        self.city_territory_indices
            .binary_search_by_key(&coordinate, |entry| entry.0)
            .ok()
            .map(|index| &self.cities[self.city_territory_indices[index].1])
    }

    /// Iterates units at one coordinate through the revision-scoped tile index.
    pub fn units_at(&self, coordinate: HexCoord) -> impl Iterator<Item = &Unit> {
        let start = self
            .unit_indices_by_position
            .partition_point(|index| self.units[*index].position() < coordinate);
        let end = self
            .unit_indices_by_position
            .partition_point(|index| self.units[*index].position() <= coordinate);
        self.unit_indices_by_position[start..end]
            .iter()
            .map(|index| &self.units[*index])
    }

    fn into_builder(self) -> GameStateBuilder {
        GameStateBuilder {
            revision: self.revision,
            turn: self.turn,
            match_lifecycle: self.match_lifecycle,
            economy: self.economy,
            knowledge: self.knowledge,
            combat: self.combat,
            objectives: self.objectives,
            outcome: self.outcome,
            bounds: self.bounds,
            occupancy_policy: self.occupancy_policy,
            units: self.units.into_vec(),
            cities: self.cities.into_vec(),
            artifacts: self.artifacts.into_vec(),
            interaction: self.interaction,
            fog_of_war: self.fog_of_war,
            diplomacy: self.diplomacy,
            infrastructure: self.infrastructure,
        }
    }

    /// Rebuilds the aggregate after a movement transition.
    ///
    /// # Errors
    ///
    /// Returns an error if the updated slices violate aggregate invariants.
    pub fn after_movement(
        &self,
        revision: StateRevision,
        unit: Unit,
        fog_of_war: FogOfWar,
        diplomacy: Diplomacy,
    ) -> Result<Self, GameStateBuildError> {
        self.clone()
            .into_after_movement(revision, unit, fog_of_war, diplomacy)
    }

    /// Consumes the aggregate and reuses its entity storage for a movement update.
    ///
    /// # Errors
    ///
    /// Returns an error if the updated slices violate aggregate invariants.
    pub fn into_after_movement(
        self,
        revision: StateRevision,
        unit: Unit,
        fog_of_war: FogOfWar,
        diplomacy: Diplomacy,
    ) -> Result<Self, GameStateBuildError> {
        let index = self
            .units
            .binary_search_by(|candidate| candidate.id().cmp(unit.id()))
            .map_err(|_| GameStateBuildError::UnitNotFound(unit.id().clone()))?;
        let mut builder = self.into_builder();
        builder.units[index] = unit;
        builder.revision = revision;
        builder.fog_of_war = fog_of_war;
        builder.diplomacy = diplomacy;
        builder.try_build()
    }

    /// Consumes the aggregate and applies one complete unit-action update.
    ///
    /// # Errors
    /// Returns an error if the unit is absent or the next aggregate is invalid.
    pub fn into_after_unit_action(
        self,
        revision: StateRevision,
        unit: Unit,
        interaction: InteractionState,
        cancelled_excavation: Option<ArtifactId>,
    ) -> Result<Self, GameStateBuildError> {
        let index = self
            .units
            .binary_search_by(|candidate| candidate.id().cmp(unit.id()))
            .map_err(|_| GameStateBuildError::UnitNotFound(unit.id().clone()))?;
        let mut builder = self.into_builder();
        let unit_id = unit.id().clone();
        builder.units[index] = unit;
        if let Some(artifact_id) = cancelled_excavation
            && let Some(artifact) = builder
                .artifacts
                .iter_mut()
                .find(|artifact| artifact.id() == &artifact_id)
        {
            artifact.restore_excavation(&unit_id);
        }
        builder.revision = revision;
        builder.interaction = interaction;
        builder.try_build()
    }
}
