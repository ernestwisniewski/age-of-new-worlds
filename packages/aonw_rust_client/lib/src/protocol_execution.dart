import 'package:aonw_rust_client/src/protocol_event.dart';
import 'package:aonw_rust_client/src/protocol_evidence.dart';
import 'package:aonw_rust_client/src/protocol_json.dart';
import 'package:aonw_rust_client/src/protocol_player_view.dart';
import 'package:aonw_rust_client/src/protocol_values.dart';

enum AonwCommandRejectionCode {
  staleRevision('stale_revision'),
  matchFinished('match_finished'),
  unitNotFound('unit_not_found'),
  unitNotControlled('unit_not_controlled'),
  unitUnavailable('unit_unavailable'),
  unitUsesTradeRoutes('unit_uses_trade_routes'),
  unitOutOfBounds('unit_out_of_bounds'),
  moveTargetOutOfBounds('move_target_out_of_bounds'),
  moveTargetIsCurrentTile('move_target_is_current_tile'),
  moveTargetIsForeignCityCenter('move_target_is_foreign_city_center'),
  moveTargetOccupied('move_target_occupied'),
  unitMovementCapacityInsufficient('unit_movement_capacity_insufficient'),
  movePathNotFound('move_path_not_found'),
  unitNotScout('unit_not_scout'),
  unitExhausted('unit_exhausted'),
  unitHasPath('unit_has_path'),
  autoExploreNoTarget('auto_explore_no_target'),
  unitNotMerchant('unit_not_merchant'),
  merchantNotInCity('merchant_not_in_city'),
  destinationCityNotFound('destination_city_not_found'),
  destinationCityNotControlled('destination_city_not_controlled'),
  destinationCityIsOrigin('destination_city_is_origin'),
  destinationCityIsCurrent('destination_city_is_current'),
  merchantRouteNotFound('merchant_route_not_found'),
  merchantCityPathNotFound('merchant_city_path_not_found'),
  troopNotAvailable('troop_not_available'),
  detachmentSourceOutOfBounds('detachment_source_out_of_bounds'),
  detachmentDestinationUnavailable('detachment_destination_unavailable'),
  detachedUnitIdUnavailable('detached_unit_id_unavailable'),
  unitBusy('unit_busy'),
  unitDefinitionMissing('unit_definition_missing'),
  stateRevisionOverflow('state_revision_overflow'),
  invalidQueuedMovementPath('invalid_queued_movement_path'),
  invalidUnit('invalid_unit'),
  movementUnitUpdateFailed('movement_unit_update_failed'),
  turnPlayerNotControlled('turn_player_not_controlled'),
  turnPlayerNotActive('turn_player_not_active'),
  turnScopeInvalid('turn_scope_invalid'),
  turnProcessorUnsupported('turn_processor_unsupported'),
  turnNumberOverflow('turn_number_overflow'),
  attackerNotFound('attacker_not_found'),
  attackerNotControlled('attacker_not_controlled'),
  attackerUnavailable('attacker_unavailable'),
  attackerExhausted('attacker_exhausted'),
  attackerOutOfBounds('attacker_out_of_bounds'),
  attackerCannotAttack('attacker_cannot_attack'),
  attackTargetNotVisible('attack_target_not_visible'),
  attackTargetOutOfBounds('attack_target_out_of_bounds'),
  attackTargetNotFound('attack_target_not_found'),
  attackTargetNotEnemy('attack_target_not_enemy'),
  attackTargetProtectedByTreaty('attack_target_protected_by_treaty'),
  attackTargetOutOfRange('attack_target_out_of_range'),
  attackCityHasNoHealth('attack_city_has_no_health'),
  cityFounderNotFound('city_founder_not_found'),
  cityFounderNotControlled('city_founder_not_controlled'),
  cityFounderBusy('city_founder_busy'),
  cityFounderInvalid('city_founder_invalid'),
  cityFounderNoSettlers('city_founder_no_settlers'),
  citySiteInvalid('city_site_invalid'),
  cityCenterOccupied('city_center_occupied'),
  cityCenterClaimed('city_center_claimed'),
  cityCenterTooClose('city_center_too_close'),
  cityControlledHexesInvalid('city_controlled_hexes_invalid'),
  cityNotFound('city_not_found'),
  cityNotControlled('city_not_controlled'),
  workedHexUnavailable('worked_hex_unavailable'),
  workedHexLimitReached('worked_hex_limit_reached'),
  cityExpansionHexUnavailable('city_expansion_hex_unavailable'),
  buildingNotAvailable('building_not_available'),
  unitProductionInvalidResourceOption(
    'unit_production_invalid_resource_option',
  ),
  unitProductionNotAvailable('unit_production_not_available'),
  unitProductionRequiresResource('unit_production_requires_resource'),
  unitProductionMissingStrategicResource(
    'unit_production_missing_strategic_resource',
  ),
  unitProductionRequiresCoast('unit_production_requires_coast'),
  unitSupplyLimitReached('unit_supply_limit_reached'),
  wonderNotAvailable('wonder_not_available'),
  citySpecializationLocked('city_specialization_locked'),
  citySpecializationUnchanged('city_specialization_unchanged'),
  citySpecializationMissingBuilding('city_specialization_missing_building'),
  productionQueueEmpty('production_queue_empty'),
  projectCannotBeRushed('project_cannot_be_rushed'),
  rushProductionUnavailable('rush_production_unavailable'),
  unitAlreadyCarryingArtifact('unit_already_carrying_artifact'),
  artifactNotFound('artifact_not_found'),
  unitNotCarryingArtifact('unit_not_carrying_artifact'),
  unitNotInCity('unit_not_in_city'),
  cityArtifactSlotFull('city_artifact_slot_full'),
  technologyPlayerNotControlled('technology_player_not_controlled'),
  technologyNotAvailable('technology_not_available'),
  diplomacyPlayerNotControlled('diplomacy_player_not_controlled'),
  diplomacyTargetNotDiscovered('diplomacy_target_not_discovered'),
  diplomacyProposalNotAllowed('diplomacy_proposal_not_allowed'),
  diplomacyDuplicateProposal('diplomacy_duplicate_proposal'),
  diplomacyProposalNotFound('diplomacy_proposal_not_found'),
  diplomacyProposalPaymentUnavailable('diplomacy_proposal_payment_unavailable'),
  diplomacyMessageCooldown('diplomacy_message_cooldown'),
  diplomacyDuplicateMessage('diplomacy_duplicate_message'),
  diplomacyMessageNotFound('diplomacy_message_not_found'),
  diplomacyMessageUnavailable('diplomacy_message_unavailable'),
  diplomacyTruceActive('diplomacy_truce_active'),
  diplomacyWarAlreadyActive('diplomacy_war_already_active'),
  diplomacyInvalidGoldAmount('diplomacy_invalid_gold_amount'),
  diplomacyGoldGiftBlockedByRelation('diplomacy_gold_gift_blocked_by_relation'),
  diplomacyGoldUnavailable('diplomacy_gold_unavailable'),
  diplomacyGoldGiftUnavailable('diplomacy_gold_gift_unavailable'),
  invalidResourceTradeTarget('invalid_resource_trade_target'),
  invalidResourceTradeResource('invalid_resource_trade_resource'),
  invalidResourceTradeTerms('invalid_resource_trade_terms'),
  resourceTradeBlockedByWar('resource_trade_blocked_by_war'),
  resourceTradeGoldUnavailable('resource_trade_gold_unavailable'),
  resourceTradeAlreadyActive('resource_trade_already_active'),
  invalidResourceTradeAgreementId('invalid_resource_trade_agreement_id'),
  resourceTradeAgreementIdConflict('resource_trade_agreement_id_conflict'),
  resourceTradeExportUnavailable('resource_trade_export_unavailable'),
  resourceTradeOfferUnavailable('resource_trade_offer_unavailable'),
  resourceTradeRequestUnavailable('resource_trade_request_unavailable'),
  artifactTradeActorUnavailable('artifact_trade_actor_unavailable'),
  artifactTradeTargetInvalid('artifact_trade_target_invalid'),
  artifactTradeGoldInvalid('artifact_trade_gold_invalid'),
  artifactTradeBlockedByWar('artifact_trade_blocked_by_war'),
  artifactTradeGoldUnavailable('artifact_trade_gold_unavailable'),
  offeredArtifactUnavailable('offered_artifact_unavailable'),
  targetArtifactSlotUnavailable('target_artifact_slot_unavailable'),
  workerNotFound('worker_not_found'),
  workerNotControlled('worker_not_controlled'),
  workerUnavailable('worker_unavailable'),
  workerNoMovementPoints('worker_no_movement_points'),
  workerQueuedPathActive('worker_queued_path_active'),
  workerImprovementNotSelected('worker_improvement_not_selected'),
  workerActionNotControlled('worker_action_not_controlled'),
  workerImprovementUnavailable('worker_improvement_unavailable'),
  workerJobNotActive('worker_job_not_active'),
  workerAssignmentUnavailable('worker_assignment_unavailable'),
  workerAssignmentNotActive('worker_assignment_not_active'),
  workerRoadUnavailable('worker_road_unavailable'),
  roadConstructionExistingRoad('road_construction_existingRoad'),
  roadConstructionCity('road_construction_city'),
  roadConstructionEnemyTerritory('road_construction_enemyTerritory'),
  roadConstructionImpassableTerrain('road_construction_impassableTerrain'),
  workerAutomationNotActive('worker_automation_not_active'),
  workerAutomationNoTarget('worker_automation_no_target');

  const AonwCommandRejectionCode(this.wireCode);

  final String wireCode;

  static AonwCommandRejectionCode fromWire(String source) {
    for (final value in values) {
      if (value.wireCode == source) return value;
    }
    throw FormatException('Unknown AoNW command rejection code $source.');
  }
}

sealed class AonwCommandOutcome {
  const AonwCommandOutcome();

  factory AonwCommandOutcome.fromJson(Object? source) {
    final value = readObject(source, 'command outcome');
    return switch (value['status']) {
      'accepted' => _accepted(value),
      'rejected' => _rejected(value),
      final Object? status => throw FormatException(
        'Unknown AoNW command outcome $status.',
      ),
    };
  }

  static AonwCommandOutcome _accepted(Map<String, Object?> value) {
    requireKeys(value, const {'status'}, 'accepted command outcome');
    return const AonwCommandAccepted();
  }

  static AonwCommandOutcome _rejected(Map<String, Object?> value) {
    requireKeys(value, const {'status', 'code'}, 'rejected command outcome');
    return AonwCommandRejected(
      AonwCommandRejectionCode.fromWire(
        readString(value['code'], 'command rejection code'),
      ),
    );
  }
}

final class AonwCommandAccepted extends AonwCommandOutcome {
  const AonwCommandAccepted();
}

final class AonwCommandRejected extends AonwCommandOutcome {
  const AonwCommandRejected(this.code);

  final AonwCommandRejectionCode code;
}

final class AonwCommandResult {
  const AonwCommandResult({
    required this.stamp,
    required this.outcome,
    required this.events,
    required this.evidence,
    required this.viewPatch,
  });

  factory AonwCommandResult.fromJson(Object? source) {
    final value = readObject(source, 'command result');
    requireKeys(value, const {
      'stamp',
      'outcome',
      'events',
      'evidence',
      'viewPatch',
    }, 'command result');
    return AonwCommandResult(
      stamp: AonwSessionStamp.fromJson(value['stamp']),
      outcome: AonwCommandOutcome.fromJson(value['outcome']),
      events: readList(
        value['events'],
        'command events',
        (item, _) => AonwClientEvent.fromJson(item),
      ),
      evidence: value['evidence'] == null
          ? null
          : AonwClientEvidence.fromJson(value['evidence']),
      viewPatch: AonwPlayerViewPatch.fromJson(value['viewPatch']),
    );
  }

  final AonwSessionStamp stamp;
  final AonwCommandOutcome outcome;
  final List<AonwClientEvent> events;
  final AonwClientEvidence? evidence;
  final AonwPlayerViewPatch viewPatch;

  bool get accepted => outcome is AonwCommandAccepted;

  AonwCommandRejectionCode? get rejection => switch (outcome) {
    AonwCommandRejected(:final code) => code,
    AonwCommandAccepted() => null,
  };
}
