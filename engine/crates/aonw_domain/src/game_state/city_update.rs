use crate::{
    City, DiplomacyState, FogOfWarState, GameState, GameStateBuildError, InteractionState,
    StateRevision, Unit,
};

/// Complete replacements for sections affected by a city command.
///
/// Fog-of-war and diplomacy are preserved from the existing game state.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CityStateUpdate {
    /// Revision after the command.
    pub revision: StateRevision,
    /// Complete unit collection after the command, not a list of changes.
    pub units: Vec<Unit>,
    /// Complete city collection after the command, not a list of changes.
    pub cities: Vec<City>,
    /// Interaction state after the command.
    pub interaction: InteractionState,
}

/// Complete replacements produced by the city-founding turn phase.
///
/// Revision and interaction are preserved for the enclosing turn kernel.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CityFoundingStateUpdate {
    /// Complete unit collection after progressing or completing founding jobs.
    pub units: Vec<Unit>,
    /// Complete city collection, including newly founded cities.
    pub cities: Vec<City>,
    /// Visibility recomputed after founders are consumed and cities appear.
    pub fog_of_war: FogOfWarState,
    /// Diplomacy including contacts discovered by the resulting visibility.
    pub diplomacy: DiplomacyState,
}

impl GameState {
    /// Consumes the aggregate and applies one complete city command update.
    ///
    /// Unaffected sections, including fog-of-war and diplomacy, are preserved.
    ///
    /// # Errors
    /// Returns an error when any replacement violates aggregate invariants.
    pub fn into_after_city(self, update: CityStateUpdate) -> Result<Self, GameStateBuildError> {
        let mut builder = self.into_builder();
        builder.revision = update.revision;
        builder.units = update.units;
        builder.cities = update.cities;
        builder.interaction = update.interaction;
        builder.try_build()
    }

    /// Consumes the aggregate and applies one city-founding turn-phase update.
    ///
    /// # Errors
    /// Returns an error when any replacement violates aggregate invariants.
    pub fn into_after_city_founding(
        self,
        update: CityFoundingStateUpdate,
    ) -> Result<Self, GameStateBuildError> {
        let mut builder = self.into_builder();
        builder.units = update.units;
        builder.cities = update.cities;
        builder.fog_of_war = update.fog_of_war;
        builder.diplomacy = update.diplomacy;
        builder.try_build()
    }
}
