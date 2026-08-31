use aonw_domain::{
    FieldImprovementKind, GameState, InteractionState, PendingInteraction, TroopKind, Unit,
    UnitActivity, UnitKind, UnitOccupancyPolicy, UnitPosture, WorkerJob, WorldArtifact,
    WorldArtifactLocation, WorldArtifactType,
};
mod city;
mod combat;
mod diplomacy;
mod economy;
mod infrastructure;
mod match_lifecycle;
mod objective;
mod outcome;
mod research;
mod writer;

use city::hash_city;
use combat::hash_combat;
use diplomacy::hash_diplomacy;
use economy::hash_economy;
use infrastructure::hash_infrastructure;
use match_lifecycle::hash_match_lifecycle;
use objective::hash_objectives;
use outcome::hash_outcome;
use research::hash_knowledge;
use writer::DigestWriter;

/// SHA-256 identity of the complete persisted canonical state.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct StateDigest([u8; 32]);

impl StateDigest {
    /// Returns digest bytes.
    #[must_use]
    pub const fn as_bytes(&self) -> &[u8; 32] {
        &self.0
    }
}

impl core::fmt::Display for StateDigest {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        for byte in self.0 {
            write!(formatter, "{byte:02x}")?;
        }
        Ok(())
    }
}

pub(crate) fn digest_state(state: &GameState) -> StateDigest {
    let mut writer = DigestWriter::new();
    writer.text("aonw-game-state");
    writer.u64(state.revision().get());
    writer.u32(state.turn());
    hash_match_lifecycle(&mut writer, state.match_lifecycle());
    hash_economy(&mut writer, state.economy());
    hash_knowledge(&mut writer, state.knowledge());
    hash_combat(&mut writer, state.combat());
    hash_objectives(&mut writer, state.objectives());
    hash_outcome(&mut writer, state.outcome());
    writer.u16(state.bounds().cols());
    writer.u16(state.bounds().rows());
    writer.u8(match state.occupancy_policy() {
        UnitOccupancyPolicy::Exclusive => 0,
        UnitOccupancyPolicy::FriendlyStacking => 1,
    });

    writer.usize(state.units().len());
    for unit in state.units() {
        hash_unit(&mut writer, unit);
    }

    writer.usize(state.cities().len());
    for city in state.cities() {
        hash_city(&mut writer, city);
    }

    writer.usize(state.artifacts().len());
    for artifact in state.artifacts() {
        hash_artifact(&mut writer, artifact);
    }
    hash_interaction(&mut writer, state.interaction());

    writer.usize(state.fog_of_war().players().len());
    for fog in state.fog_of_war().players() {
        writer.text(fog.player_id().as_str());
        writer.coordinates(fog.discovered_hexes());
        writer.coordinates(fog.visible_hexes());
    }

    hash_diplomacy(&mut writer, state.diplomacy());

    hash_infrastructure(&mut writer, state.infrastructure());
    StateDigest(writer.finish())
}

fn hash_unit(writer: &mut DigestWriter, unit: &Unit) {
    writer.text(unit.id().as_str());
    writer.text(unit.owner_player_id().as_str());
    writer.u8(unit_kind_tag(unit.kind()));
    writer.text(unit.name());
    writer.coordinate(unit.position());
    writer.u32(unit.movement_units().get());
    writer.usize(unit.army().len());
    for troop in unit.army() {
        writer.u8(match troop.kind() {
            TroopKind::Warrior => 0,
            TroopKind::Archer => 1,
            TroopKind::Settler => 2,
        });
        writer.u32(troop.count());
    }
    writer.optional_route(unit.queued_path());
    match unit.merchant_trade_route() {
        None => writer.u8(0),
        Some(route) => {
            writer.u8(1);
            writer.text(route.origin_city_id().as_str());
            writer.text(route.destination_city_id().as_str());
            writer.steps(route.steps());
            writer.text(route.transport_network_fingerprint());
        }
    }
    hash_activity(writer, unit.activity());
    writer.u32(unit.worker_build_charges());
    writer.optional_u32(unit.hit_points());
    writer.u32(unit.experience_points());
    writer.u8(match unit.posture() {
        UnitPosture::Active => 0,
        UnitPosture::Fortified => 1,
        UnitPosture::AutoExploring => 2,
        UnitPosture::AutoWorking => 3,
    });
    writer.optional_text(
        unit.carried_artifact_id()
            .map(aonw_domain::ArtifactId::as_str),
    );
}

fn hash_artifact(writer: &mut DigestWriter, artifact: &WorldArtifact) {
    writer.text(artifact.id().as_str());
    writer.u8(match artifact.artifact_type() {
        WorldArtifactType::AncientImperialCrown => 0,
        WorldArtifactType::AstronomersTablets => 1,
        WorldArtifactType::ProphetMask => 2,
        WorldArtifactType::HeroSword => 3,
        WorldArtifactType::MerchantsSeal => 4,
        WorldArtifactType::FirstPeoplesChronicle => 5,
        WorldArtifactType::TempleReliquary => 6,
        WorldArtifactType::QueensMirror => 7,
    });
    match artifact.location() {
        WorldArtifactLocation::Map(coordinate) => {
            writer.u8(0);
            writer.coordinate(*coordinate);
        }
        WorldArtifactLocation::Carried(unit_id) => {
            writer.u8(1);
            writer.text(unit_id.as_str());
        }
        WorldArtifactLocation::Stored(city_id) => {
            writer.u8(2);
            writer.text(city_id.as_str());
        }
        WorldArtifactLocation::Excavation {
            unit_id,
            coordinate,
            remaining_turns,
        } => {
            writer.u8(3);
            writer.text(unit_id.as_str());
            writer.coordinate(*coordinate);
            writer.u32(*remaining_turns);
        }
    }
}

fn hash_interaction(writer: &mut DigestWriter, interaction: &InteractionState) {
    match interaction.city_founding_draft() {
        None => writer.u8(0),
        Some(draft) => {
            writer.u8(1);
            writer.text(draft.unit_id().as_str());
            writer.text(draft.owner_player_id().as_str());
            writer.coordinate(draft.center());
            writer.coordinates(draft.controlled_hexes());
        }
    }
    match interaction.pending() {
        None => writer.u8(0),
        Some(PendingInteraction::ResearchSelection { owner_player_id }) => {
            writer.u8(1);
            writer.text(owner_player_id.as_str());
        }
        Some(PendingInteraction::CityWorkedHexSelection {
            owner_player_id,
            city_id,
        }) => {
            writer.u8(2);
            writer.text(owner_player_id.as_str());
            writer.text(city_id.as_str());
        }
        Some(PendingInteraction::CityExpansionSelection {
            owner_player_id,
            city_id,
        }) => {
            writer.u8(3);
            writer.text(owner_player_id.as_str());
            writer.text(city_id.as_str());
        }
        Some(PendingInteraction::WorkerActionSelection {
            owner_player_id,
            unit_id,
            improvement,
        }) => {
            writer.u8(4);
            writer.text(owner_player_id.as_str());
            writer.text(unit_id.as_str());
            match improvement {
                None => writer.u8(0),
                Some(improvement) => {
                    writer.u8(1);
                    writer.u8(improvement_tag(*improvement));
                }
            }
        }
        Some(PendingInteraction::MerchantTradeRouteSelection {
            owner_player_id,
            unit_id,
        }) => {
            writer.u8(5);
            writer.text(owner_player_id.as_str());
            writer.text(unit_id.as_str());
        }
        Some(PendingInteraction::MerchantMoveToCitySelection {
            owner_player_id,
            unit_id,
        }) => {
            writer.u8(6);
            writer.text(owner_player_id.as_str());
            writer.text(unit_id.as_str());
        }
        Some(PendingInteraction::UnitTurnSkip {
            owner_player_id,
            unit_id,
            restore_movement,
        }) => {
            writer.u8(7);
            writer.text(owner_player_id.as_str());
            writer.text(unit_id.as_str());
            writer.u32(restore_movement.get());
        }
        Some(PendingInteraction::AttackTargeting {
            owner_player_id,
            unit_id,
            defender,
        }) => {
            writer.u8(8);
            writer.text(owner_player_id.as_str());
            writer.text(unit_id.as_str());
            writer.optional_coordinate(*defender);
        }
        Some(PendingInteraction::CommanderMergeSelection {
            owner_player_id,
            unit_id,
        }) => {
            writer.u8(9);
            writer.text(owner_player_id.as_str());
            writer.text(unit_id.as_str());
        }
    }
}

fn hash_activity(writer: &mut DigestWriter, activity: &UnitActivity) {
    match activity.worker_job() {
        None => writer.u8(0),
        Some(WorkerJob::FieldImprovement {
            target,
            improvement,
            remaining_turns,
            total_turns,
        }) => {
            writer.u8(1);
            writer.coordinate(*target);
            writer.u8(improvement_tag(*improvement));
            writer.u32(*remaining_turns);
            writer.u32(*total_turns);
        }
        Some(WorkerJob::RoadConstruction {
            target,
            remaining_turns,
            total_turns,
        }) => {
            writer.u8(2);
            writer.coordinate(*target);
            writer.u32(*remaining_turns);
            writer.u32(*total_turns);
        }
    }
    match activity.city_founding_job() {
        None => writer.u8(0),
        Some(job) => {
            writer.u8(1);
            writer.coordinate(job.center());
            writer.coordinates(job.controlled_hexes());
            writer.u32(job.remaining_turns());
            writer.u32(job.total_turns());
        }
    }
    writer.optional_coordinate(activity.worker_assignment());
    writer.optional_text(
        activity
            .excavating_artifact_id()
            .map(aonw_domain::ArtifactId::as_str),
    );
}

const fn unit_kind_tag(kind: UnitKind) -> u8 {
    match kind {
        UnitKind::Commander => 0,
        UnitKind::Warrior => 1,
        UnitKind::Archer => 2,
        UnitKind::Settler => 3,
        UnitKind::Worker => 4,
        UnitKind::Merchant => 5,
        UnitKind::Scout => 6,
        UnitKind::Spearman => 7,
        UnitKind::Cavalry => 8,
        UnitKind::Catapult => 9,
        UnitKind::HeavyInfantry => 10,
        UnitKind::FieldCannon => 11,
        UnitKind::Rifleman => 12,
        UnitKind::Tank => 13,
        UnitKind::ScoutShip => 14,
        UnitKind::Warship => 15,
        UnitKind::ReconPlane => 16,
    }
}

const fn improvement_tag(kind: FieldImprovementKind) -> u8 {
    match kind {
        FieldImprovementKind::Farm => 0,
        FieldImprovementKind::RiverFarm => 1,
        FieldImprovementKind::Mine => 2,
        FieldImprovementKind::LumberMill => 3,
        FieldImprovementKind::Pasture => 4,
        FieldImprovementKind::Camp => 5,
        FieldImprovementKind::Quarry => 6,
        FieldImprovementKind::FishingBoats => 7,
        FieldImprovementKind::Orchard => 8,
        FieldImprovementKind::Plantation => 9,
        FieldImprovementKind::Vineyard => 10,
        FieldImprovementKind::TradingPost => 11,
        FieldImprovementKind::ProspectorCamp => 12,
        FieldImprovementKind::HorseRanch => 13,
        FieldImprovementKind::PearlDivers => 14,
        FieldImprovementKind::CoalShaft => 15,
        FieldImprovementKind::OilWell => 16,
        FieldImprovementKind::BauxiteMine => 17,
        FieldImprovementKind::UraniumMine => 18,
    }
}

#[cfg(test)]
mod tests;
