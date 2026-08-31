use aonw_contract_mapping::decode_game_state;
use aonw_contracts::{
    AiDifficultyDto, AiPersonaDto, AiStrategyIdDto, CityBuildingTypeDto, CityConquestActionDto,
    CityProductionTargetDto, CityProjectTypeDto, CitySpecializationTypeDto,
    DiplomaticMessageCategoryDto, DiplomaticMessageResponseDto, DiplomaticMessageTopicDto,
    DiplomaticProposalKindDto, DiplomaticRelationChangeReasonDto, DiplomaticRelationStatusDto,
    DiplomaticScoreChangeReasonDto, FieldImprovementDto, FieldImprovementKindDto,
    GameLengthKindDto, GameModeDto, GameStateDto, PaceProfileDto, PendingInteractionDto,
    PlayerCountryDto, PlayerKindDto, PlayerTurnStateDto, ResourceTypeDto, RuleValueDto,
    TechnologyIdDto, TransportConditionDto, UnitOccupancyPolicyDto, WonderTypeDto,
    WorldArtifactDto, WorldArtifactLocationDto, WorldArtifactTypeDto,
};

use super::fixture::{complete_state_contract, coordinate};
use crate::state_digest::{StateDigest, digest_state};

#[test]
fn digest_changes_with_every_canonical_state_section() {
    let source = complete_state_contract();
    assert_digest_change(&source, "revision", |candidate| {
        candidate.revision += 1;
    });
    assert_digest_change(&source, "turn", |candidate| {
        candidate.turn += 1;
    });
    assert_digest_change(&source, "gold", |candidate| {
        *candidate
            .economy
            .player_gold
            .get_mut("player-1")
            .expect("gold account") += 1;
    });
    assert_digest_change(&source, "war weariness", |candidate| {
        candidate
            .economy
            .player_war_weariness
            .insert("player-2".to_owned(), 7);
    });
    assert_digest_change(&source, "stability", |candidate| {
        candidate.economy.player_stability_net.clear();
    });
    assert_digest_change(&source, "strategic stockpile", |candidate| {
        candidate
            .economy
            .strategic_resources
            .get_mut("player-1")
            .expect("stockpile")
            .0
            .insert(ResourceTypeDto::Oil, 8);
    });
    assert_digest_change(&source, "initial distribution seed", |candidate| {
        candidate.economy.initial_resource_distribution.seed += 1;
    });
    assert_digest_change(&source, "initial resource placement", |candidate| {
        candidate.economy.initial_resource_distribution.placements[0].resource =
            ResourceTypeDto::Fish;
    });
    assert_knowledge_digest_changes(&source);
    assert_combat_digest_changes(&source);
    assert_objective_digest_changes(&source);
    assert_diplomacy_digest_changes(&source);
    assert_digest_change(&source, "bounds", |candidate| {
        candidate.cols += 1;
    });
    assert_digest_change(&source, "occupancy policy", |candidate| {
        candidate.occupancy_policy = UnitOccupancyPolicyDto::Exclusive;
    });
    assert_digest_change(&source, "city", |candidate| {
        candidate.cities[0].controlled_hexes.push(coordinate(1, 0));
    });
    assert_digest_change(&source, "artifact type", |candidate| {
        candidate.artifacts[0].artifact_type = WorldArtifactTypeDto::ProphetMask;
    });
    assert_digest_change(&source, "artifact location", |candidate| {
        candidate.artifacts.push(WorldArtifactDto {
            id: "artifact-3".to_owned(),
            artifact_type: WorldArtifactTypeDto::QueensMirror,
            location: WorldArtifactLocationDto::Map {
                coordinate: coordinate(3, 3),
            },
        });
    });
    assert_digest_change(&source, "interaction draft", |candidate| {
        candidate
            .interaction
            .city_founding_draft
            .as_mut()
            .expect("draft")
            .center = coordinate(3, 2);
    });
    assert_digest_change(&source, "pending interaction", |candidate| {
        candidate.interaction.pending = Some(PendingInteractionDto::AttackTargeting {
            owner_player_id: "player-1".to_owned(),
            unit_id: "unit-1".to_owned(),
            defender: Some(coordinate(3, 3)),
        });
    });
    assert_digest_change(&source, "fog", |candidate| {
        candidate.fog_of_war[0].visible_hexes.push(coordinate(0, 0));
    });
    assert_digest_change(&source, "field improvement coordinate", |candidate| {
        candidate.field_improvements[0].coordinate = coordinate(1, 0);
    });
    assert_digest_change(&source, "field improvement kind", |candidate| {
        candidate.field_improvements[0].kind = FieldImprovementKindDto::Mine;
    });
    assert_digest_change(&source, "field improvement builder", |candidate| {
        candidate.field_improvements[0].built_by_city_id = None;
    });
    assert_digest_change(&source, "transport condition", |candidate| {
        candidate.transport_network[0].condition = TransportConditionDto::Pillaged;
    });
    assert_digest_change(&source, "transport builder", |candidate| {
        candidate.transport_network[0].built_by_city_id = None;
    });
}

fn assert_objective_digest_changes(source: &GameStateDto) {
    assert_digest_change(source, "objective progress empty", |candidate| {
        candidate.domination_hold_turns_by_player_id.clear();
        candidate.cultural_victory_hold_turns_by_player_id.clear();
        candidate.map_objective_hold_states.clear();
    });
    assert_digest_change(source, "domination hold turns", |candidate| {
        *candidate
            .domination_hold_turns_by_player_id
            .get_mut("player-1")
            .expect("domination hold") += 1;
    });
    assert_digest_change(source, "cultural hold turns", |candidate| {
        *candidate
            .cultural_victory_hold_turns_by_player_id
            .get_mut("player-2")
            .expect("cultural hold") += 1;
    });
    assert_digest_change(source, "map objective id", |candidate| {
        candidate.map_objective_hold_states[0].objective_id = "strategic-pass-2".to_owned();
    });
    assert_digest_change(source, "map objective player", |candidate| {
        candidate.map_objective_hold_states[0].player_id = "player-2".to_owned();
    });
    assert_digest_change(source, "map objective hold turns", |candidate| {
        candidate.map_objective_hold_states[0].hold_turns += 1;
    });
}

fn assert_diplomacy_digest_changes(source: &GameStateDto) {
    assert_digest_change(source, "diplomacy empty", |candidate| {
        candidate.diplomacy.contacts.clear();
        candidate.diplomacy.relations.clear();
        candidate.diplomacy.pending_proposals.clear();
        candidate.diplomacy.messages.clear();
        candidate.diplomacy.score_history.clear();
        candidate.resource_trade_agreements.clear();
    });
    assert_relation_and_proposal_digest_changes(source);
    assert_message_digest_changes(source);
    assert_score_and_trade_digest_changes(source);
}

fn assert_relation_and_proposal_digest_changes(source: &GameStateDto) {
    assert_digest_change(source, "relation status", |candidate| {
        candidate.diplomacy.relations[0].status = DiplomaticRelationStatusDto::War;
    });
    assert_digest_change(source, "relation score", |candidate| {
        candidate.diplomacy.relations[0].relation_score += 1;
    });
    assert_digest_change(source, "relation expiry", |candidate| {
        candidate.diplomacy.relations[0].status_expires_on_turn = Some(21);
    });
    assert_digest_change(source, "relation changed turn", |candidate| {
        candidate.diplomacy.relations[0].last_changed_turn = Some(4);
    });
    assert_digest_change(source, "relation reason", |candidate| {
        candidate.diplomacy.relations[0].last_change_reason =
            Some(DiplomaticRelationChangeReasonDto::Manual);
    });
    assert_digest_change(source, "proposal id", |candidate| {
        candidate.diplomacy.pending_proposals[0].id = "proposal-2".to_owned();
    });
    assert_digest_change(source, "proposal kind", |candidate| {
        candidate.diplomacy.pending_proposals[0].kind = DiplomaticProposalKindDto::Truce;
    });
    assert_digest_change(source, "proposal created turn", |candidate| {
        candidate.diplomacy.pending_proposals[0].created_turn = 2;
    });
    assert_digest_change(source, "proposal expiry", |candidate| {
        candidate.diplomacy.pending_proposals[0].expires_on_turn = 9;
    });
    assert_digest_change(source, "proposal gold", |candidate| {
        candidate.diplomacy.pending_proposals[0].gold_payment = 1;
    });
}

fn assert_message_digest_changes(source: &GameStateDto) {
    assert_digest_change(source, "message id", |candidate| {
        candidate.diplomacy.messages[0].id = "message-2".to_owned();
    });
    assert_digest_change(source, "message direction", |candidate| {
        let message = &mut candidate.diplomacy.messages[0];
        (message.from_player_id, message.to_player_id) =
            (message.to_player_id.clone(), message.from_player_id.clone());
    });
    assert_digest_change(source, "message topic and category", |candidate| {
        candidate.diplomacy.messages[0].topic = DiplomaticMessageTopicDto::PeacefulPraise;
        candidate.diplomacy.messages[0].category = DiplomaticMessageCategoryDto::Praise;
    });
    assert_digest_change(source, "message creation", |candidate| {
        candidate.diplomacy.messages[0].created_turn = 2;
    });
    assert_digest_change(source, "message expiry", |candidate| {
        candidate.diplomacy.messages[0].expires_on_turn = 9;
    });
    assert_digest_change(source, "message response", |candidate| {
        candidate.diplomacy.messages[0].response = Some(DiplomaticMessageResponseDto::Neutral);
    });
    assert_digest_change(source, "message response turn", |candidate| {
        candidate.diplomacy.messages[0].responded_turn = Some(5);
    });
    assert_digest_change(source, "message score delta", |candidate| {
        candidate.diplomacy.messages[0].relation_score_delta += 1;
    });
    assert_digest_change(source, "message score after", |candidate| {
        candidate.diplomacy.messages[0].relation_score_after = Some(25);
    });
    assert_digest_change(source, "message promise due", |candidate| {
        candidate.diplomacy.messages[0].promise_due_turn = Some(8);
    });
    assert_digest_change(source, "message promise broken", |candidate| {
        candidate.diplomacy.messages[0].promise_broken = true;
    });
}

fn assert_score_and_trade_digest_changes(source: &GameStateDto) {
    assert_digest_change(source, "score turn", |candidate| {
        candidate.diplomacy.score_history[0].turn += 1;
    });
    assert_digest_change(source, "score delta", |candidate| {
        candidate.diplomacy.score_history[0].delta += 1;
    });
    assert_digest_change(source, "score after", |candidate| {
        candidate.diplomacy.score_history[0].score_after += 1;
    });
    assert_digest_change(source, "score reason", |candidate| {
        candidate.diplomacy.score_history[0].reason = DiplomaticScoreChangeReasonDto::Manual;
    });
    assert_digest_change(source, "score source", |candidate| {
        candidate.diplomacy.score_history[0].source_id = Some("manual-1".to_owned());
    });
    assert_digest_change(source, "trade id", |candidate| {
        candidate.resource_trade_agreements[0].id = "trade-2".to_owned();
    });
    assert_digest_change(source, "trade direction", |candidate| {
        let trade = &mut candidate.resource_trade_agreements[0];
        (trade.exporter_player_id, trade.importer_player_id) = (
            trade.importer_player_id.clone(),
            trade.exporter_player_id.clone(),
        );
    });
    assert_digest_change(source, "trade resource", |candidate| {
        candidate.resource_trade_agreements[0].resource = ResourceTypeDto::Iron;
    });
    assert_digest_change(source, "trade gold", |candidate| {
        candidate.resource_trade_agreements[0].gold_per_turn += 1;
    });
    assert_digest_change(source, "trade duration", |candidate| {
        candidate.resource_trade_agreements[0].remaining_turns += 1;
    });
    assert_digest_change(source, "trade amount", |candidate| {
        candidate.resource_trade_agreements[0].amount_per_turn += 1;
    });
    assert_digest_change(source, "trade group", |candidate| {
        candidate.resource_trade_agreements[0].exchange_group_id = Some("exchange-2".to_owned());
    });
}

fn assert_combat_digest_changes(source: &GameStateDto) {
    assert_digest_change(source, "attack target", |candidate| {
        candidate.intended_attacks[0].defender_col += 1;
    });
    assert_digest_change(source, "attack declaration tick", |candidate| {
        candidate.intended_attacks[0].declared_at_tick += 1;
    });
    assert_digest_change(source, "city conquest action", |candidate| {
        candidate.intended_attacks[0].city_conquest_action = CityConquestActionDto::Capture;
    });
}

fn assert_knowledge_digest_changes(source: &GameStateDto) {
    assert_digest_change(source, "unlocked technology", |candidate| {
        candidate
            .research
            .players
            .get_mut("player-1")
            .expect("research player")
            .unlocked_technology_ids
            .push(TechnologyIdDto::Mining);
    });
    assert_digest_change(source, "active technology", |candidate| {
        candidate
            .research
            .players
            .get_mut("player-1")
            .expect("research player")
            .active_technology_id = Some(TechnologyIdDto::Mining);
    });
    assert_digest_change(source, "technology progress", |candidate| {
        candidate
            .research
            .players
            .get_mut("player-1")
            .expect("research player")
            .progress_by_technology_id
            .insert(TechnologyIdDto::Mining, 2);
    });
    assert_digest_change(source, "science overflow", |candidate| {
        candidate
            .research
            .players
            .get_mut("player-1")
            .expect("research player")
            .science_overflow += 1;
    });
    assert_digest_change(source, "wonder registry", |candidate| {
        candidate
            .wonder_registry
            .0
            .insert(WonderTypeDto::CentralBank, "player-1".to_owned());
    });
}

#[test]
fn field_improvement_digest_uses_coordinate_canonical_order() {
    let mut left = complete_state_contract();
    left.field_improvements.push(FieldImprovementDto {
        coordinate: coordinate(2, 2),
        kind: FieldImprovementKindDto::Mine,
        built_by_city_id: None,
    });
    let mut right = left.clone();
    right.field_improvements.reverse();

    assert_eq!(contract_digest(&left), contract_digest(&right));
}

#[test]
fn digest_changes_with_match_identity_and_turn_lifecycle() {
    let source = complete_state_contract();
    assert_game_length_digest_changes(&source);
    assert_victory_digest_changes(&source);
    assert_digest_change(&source, "balance rules", |candidate| {
        candidate.match_identity.match_rules.balance.insert(
            "combat".to_owned(),
            RuleValueDto::String("strict".to_owned()),
        );
    });
    assert_digest_change(&source, "game mode", |candidate| {
        candidate.match_identity.game_mode = GameModeDto::HotSeat;
    });
    assert_digest_change(&source, "participant order", |candidate| {
        candidate.match_identity.participants.reverse();
    });
    assert_digest_change(&source, "participant country", |candidate| {
        candidate.match_identity.participants[0].country = PlayerCountryDto::France;
    });
    assert_participant_ai_digest_changes(&source);
    assert_digest_change(&source, "player turn state", |candidate| {
        candidate
            .turn_lifecycle
            .turn_states_by_player_id
            .insert("player-1".to_owned(), PlayerTurnStateDto::Finished);
    });
    assert_digest_change(&source, "submitted players", |candidate| {
        candidate.turn_lifecycle.submitted_player_ids.clear();
    });
    assert_digest_change(&source, "timeout streak", |candidate| {
        *candidate
            .turn_lifecycle
            .timeout_streaks_by_player_id
            .get_mut("player-2")
            .expect("timeout streak") += 1;
    });
    assert_digest_change(&source, "AFK players", |candidate| {
        candidate.turn_lifecycle.afk_player_ids.clear();
    });
    assert_digest_change(&source, "kicked players", |candidate| {
        let turn = &mut candidate.turn_lifecycle;
        turn.kicked_player_ids.push("player-2".to_owned());
        turn.required_submission_player_ids = vec!["player-1".to_owned()];
        turn.submitted_player_ids.clear();
    });
    assert_digest_change(&source, "turn start", |candidate| {
        candidate.turn_lifecycle.turn_started_at = Some("2026-08-23T12:34:57.123456Z".to_owned());
    });
}

fn assert_game_length_digest_changes(source: &GameStateDto) {
    assert_digest_change(source, "game length kind", |candidate| {
        candidate.match_identity.match_rules.game_length.kind = GameLengthKindDto::TargetMinutes;
    });
    assert_digest_change(source, "game length target minutes", |candidate| {
        candidate
            .match_identity
            .match_rules
            .game_length
            .target_minutes = Some(60);
    });
    assert_digest_change(source, "game length turn limit", |candidate| {
        candidate.match_identity.match_rules.game_length.turn_limit = Some(100);
    });
    assert_digest_change(source, "game length pace", |candidate| {
        candidate
            .match_identity
            .match_rules
            .game_length
            .pace_profile = PaceProfileDto::Long120;
    });
    assert_digest_change(source, "game length score fallback", |candidate| {
        candidate
            .match_identity
            .match_rules
            .game_length
            .score_fallback_enabled = true;
    });
}

fn assert_victory_digest_changes(source: &GameStateDto) {
    assert_digest_change(source, "conquest enabled", |candidate| {
        candidate
            .match_identity
            .match_rules
            .victory
            .conquest_enabled = false;
    });
    assert_digest_change(source, "domination enabled", |candidate| {
        candidate
            .match_identity
            .match_rules
            .victory
            .domination_enabled = false;
    });
    assert_digest_change(source, "domination control percent", |candidate| {
        candidate
            .match_identity
            .match_rules
            .victory
            .domination_control_percent = serde_json::Number::from(61);
    });
    assert_digest_change(source, "domination hold turns", |candidate| {
        candidate
            .match_identity
            .match_rules
            .victory
            .domination_hold_turns += 1;
    });
    assert_digest_change(source, "victory score fallback", |candidate| {
        candidate
            .match_identity
            .match_rules
            .victory
            .score_fallback_enabled = true;
    });
    assert_digest_change(source, "victory turn limit", |candidate| {
        candidate.match_identity.match_rules.victory.turn_limit = Some(100);
    });
    assert_digest_change(source, "victory hard time limit", |candidate| {
        candidate
            .match_identity
            .match_rules
            .victory
            .hard_time_limit_minutes = Some(180);
    });
    assert_digest_change(source, "cultural enabled", |candidate| {
        candidate
            .match_identity
            .match_rules
            .victory
            .cultural_enabled = false;
    });
    assert_digest_change(source, "cultural required artifacts", |candidate| {
        candidate
            .match_identity
            .match_rules
            .victory
            .cultural_required_artifacts += 1;
    });
    assert_digest_change(source, "cultural hold turns", |candidate| {
        candidate
            .match_identity
            .match_rules
            .victory
            .cultural_hold_turns += 1;
    });
}

fn assert_participant_ai_digest_changes(source: &GameStateDto) {
    assert_digest_change(source, "participant kind and AI presence", |candidate| {
        let participant = &mut candidate.match_identity.participants[1];
        participant.kind = PlayerKindDto::Human;
        participant.ai = None;
    });
    assert_digest_change(source, "participant AI strategy", |candidate| {
        candidate.match_identity.participants[1]
            .ai
            .as_mut()
            .expect("AI participant")
            .strategy_id = AiStrategyIdDto::Basic;
    });
    assert_digest_change(source, "participant AI difficulty", |candidate| {
        candidate.match_identity.participants[1]
            .ai
            .as_mut()
            .expect("AI participant")
            .difficulty = AiDifficultyDto::VeryHard;
    });
    assert_digest_change(source, "participant AI persona", |candidate| {
        candidate.match_identity.participants[1]
            .ai
            .as_mut()
            .expect("AI participant")
            .persona = AiPersonaDto::Balanced;
    });
    assert_digest_change(source, "participant AI seed", |candidate| {
        candidate.match_identity.participants[1]
            .ai
            .as_mut()
            .expect("AI participant")
            .seed += 1;
    });
}

#[test]
fn digest_changes_with_every_complete_city_field() {
    let source = complete_state_contract();
    assert_digest_change(&source, "city owner", |candidate| {
        candidate.cities[0].owner_player_id = "player-2".to_owned();
    });
    assert_digest_change(&source, "city founding owner", |candidate| {
        candidate.cities[0].founding_owner_player_id = None;
    });
    assert_digest_change(&source, "city name", |candidate| {
        candidate.cities[0].name.push_str(" Prime");
    });
    assert_digest_change(&source, "city population", |candidate| {
        candidate.cities[0].population += 1;
    });
    assert_digest_change(&source, "city stored food", |candidate| {
        candidate.cities[0].stored_food -= 1;
    });
    assert_digest_change(&source, "city max hexes", |candidate| {
        candidate.cities[0].max_hexes += 1;
    });
    assert_digest_change(&source, "city territory radius", |candidate| {
        candidate.cities[0].territory_radius += 1;
    });
    assert_digest_change(&source, "city center", |candidate| {
        candidate.cities[0].center = coordinate(1, 1);
    });
    assert_digest_change(&source, "controlled hexes", |candidate| {
        candidate.cities[0].controlled_hexes.push(coordinate(1, 0));
    });
    assert_digest_change(&source, "worked hexes", |candidate| {
        candidate.cities[0].worked_hexes.clear();
    });
    assert_digest_change(&source, "city buildings", |candidate| {
        candidate.cities[0]
            .buildings
            .push(CityBuildingTypeDto::Factory);
    });
    assert_digest_change(&source, "city wonders", |candidate| {
        candidate.cities[0].wonders.push(WonderTypeDto::GreatWall);
    });
    assert_digest_change(&source, "production target", |candidate| {
        candidate.cities[0]
            .production_queue
            .as_mut()
            .expect("queue")
            .target = CityProductionTargetDto::Project {
            project_type: CityProjectTypeDto::Research,
        };
    });
    assert_digest_change(&source, "invested production", |candidate| {
        candidate.cities[0]
            .production_queue
            .as_mut()
            .expect("queue")
            .invested_production += 1;
    });
    assert_digest_change(&source, "production resource allocation", |candidate| {
        candidate.cities[0]
            .production_queue
            .as_mut()
            .expect("queue")
            .resource_allocation
            .0
            .insert(ResourceTypeDto::Aluminium, 1);
    });
    assert_digest_change(&source, "production overflow", |candidate| {
        candidate.cities[0].production_overflow += 1;
    });
    assert_digest_change(&source, "city specialization", |candidate| {
        candidate.cities[0].specialization = Some(CitySpecializationTypeDto::Military);
    });
    assert_digest_change(&source, "preferred expansion", |candidate| {
        candidate.cities[0].preferred_expansion_hex = None;
    });
    assert_digest_change(&source, "city hit points", |candidate| {
        candidate.cities[0].hit_points = Some(40);
    });
}

#[test]
fn persisted_participant_display_identity_changes_state_digest() {
    let source = complete_state_contract();
    assert_digest_change(&source, "participant name", |candidate| {
        candidate.match_identity.participants[0].name = "New display name".to_owned();
    });
    assert_digest_change(&source, "participant color", |candidate| {
        candidate.match_identity.participants[0].color_value = 0xff00_ff00;
    });
}

fn contract_digest(contract: &GameStateDto) -> StateDigest {
    digest_state(&decode_game_state(contract.clone()).expect("valid complete state"))
}

fn assert_digest_change(
    source: &GameStateDto,
    label: &str,
    change: impl FnOnce(&mut GameStateDto),
) {
    let baseline = contract_digest(source);
    let mut candidate = source.clone();
    change(&mut candidate);
    assert_ne!(
        baseline,
        contract_digest(&candidate),
        "state digest ignored {label}"
    );
}
