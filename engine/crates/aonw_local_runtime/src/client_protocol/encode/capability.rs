use aonw_contracts::client::{ClientFeatureDto, ClientResponseBodyDto};

use crate::LocalRuntime;

pub(crate) fn capabilities() -> ClientResponseBodyDto {
    let capabilities = LocalRuntime::capabilities();
    let mut features = vec![
        ClientFeatureDto::InspectMap,
        ClientFeatureDto::MatchStart,
        ClientFeatureDto::ActorHandoff,
        ClientFeatureDto::AiTurns,
        ClientFeatureDto::Snapshot,
    ];
    if capabilities.reachable() {
        features.push(ClientFeatureDto::Reachable);
    }
    if capabilities.route_plan() {
        features.push(ClientFeatureDto::RoutePlan);
    }
    if capabilities.move_unit() {
        features.push(ClientFeatureDto::MoveUnit);
    }
    if capabilities.unit_actions() {
        features.push(ClientFeatureDto::UnitActions);
    }
    if capabilities.turn_kernel() {
        features.push(ClientFeatureDto::TurnKernel);
    }
    if capabilities.movement_logistics() {
        features.push(ClientFeatureDto::MovementLogistics);
    }
    if capabilities.combat() {
        features.push(ClientFeatureDto::Combat);
    }
    if capabilities.cities() {
        features.push(ClientFeatureDto::Cities);
    }
    if capabilities.workers() {
        features.push(ClientFeatureDto::Workers);
    }
    if capabilities.production() {
        features.push(ClientFeatureDto::Production);
    }
    if capabilities.research() {
        features.push(ClientFeatureDto::Research);
    }
    if capabilities.diplomacy() {
        features.push(ClientFeatureDto::Diplomacy);
    }
    if capabilities.artifacts() {
        features.push(ClientFeatureDto::Artifacts);
    }
    if capabilities.save_game() {
        features.push(ClientFeatureDto::SaveGame);
    }
    if capabilities.replay_verification() {
        features.push(ClientFeatureDto::ReplayVerification);
        features.push(ClientFeatureDto::ReplayPlayback);
    }
    ClientResponseBodyDto::Capabilities { features }
}
