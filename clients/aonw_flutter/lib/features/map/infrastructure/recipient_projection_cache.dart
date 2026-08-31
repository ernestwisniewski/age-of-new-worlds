import 'package:aonw_rust_client/aonw_rust_client.dart';

import '../read_model/map_view.dart';
import 'recipient_projection_collections.dart';
import 'recipient_projection_validator.dart';

final class RecipientProjectionCache {
  RecipientProjectionCache.open({
    required AonwPlayerViewSnapshot snapshot,
    required MapView map,
  }) : _validator = RecipientProjectionValidator(map),
       _snapshot = snapshot {
    _collections = RecipientProjectionCollections(_validator);
    _validator.validateSnapshot(snapshot);
  }

  final RecipientProjectionValidator _validator;
  late final RecipientProjectionCollections _collections;
  AonwPlayerViewSnapshot _snapshot;

  AonwPlayerViewSnapshot get snapshot => _snapshot;

  AonwPlayerViewSnapshot apply(AonwCommandResult command) {
    final before = _snapshot;
    final patch = command.viewPatch;
    _validateCommandIdentity(command, before);
    _validatePatchIdentity(patch, command: command, before: before);
    if (!command.accepted || patch.toRevision == patch.fromRevision) {
      return before;
    }

    final units = _collections.applyIdPatch(
      current: before.units,
      upserted: patch.upsertedUnits,
      removedIds: patch.removedUnitIds,
      idOf: (unit) => unit.id,
      label: 'unit',
    );
    final cities = _collections.applyIdPatch(
      current: before.cities,
      upserted: patch.upsertedCities,
      removedIds: patch.removedCityIds,
      idOf: (city) => city.id,
      label: 'city',
    );
    final artifacts = _collections.applyIdPatch(
      current: before.artifacts,
      upserted: patch.upsertedArtifacts,
      removedIds: patch.removedArtifactIds,
      idOf: (artifact) => artifact.id,
      label: 'artifact',
    );
    final fieldImprovements = _collections.applyCoordinatePatch(
      current: before.fieldImprovements,
      upserted: patch.upsertedFieldImprovements,
      removed: patch.removedFieldImprovementCoordinates,
      coordinateOf: (improvement) => improvement.coordinate,
      label: 'field improvement',
    );
    final roads = _collections.applyCoordinatePatch(
      current: before.roads,
      upserted: patch.upsertedRoads,
      removed: patch.removedRoadCoordinates,
      coordinateOf: (road) => road.coordinate,
      label: 'road',
    );

    final after = AonwPlayerViewSnapshot(
      stamp: command.stamp,
      turn: patch.turn,
      outcome: patch.outcome ?? before.outcome,
      turnLifecycle: patch.turnLifecycle ?? before.turnLifecycle,
      pendingAction: patch.pendingAction,
      cityFoundingDraft: patch.cityFoundingDraft,
      diplomacy: patch.diplomacy ?? before.diplomacy,
      units: units,
      cities: cities,
      artifacts: artifacts,
      fieldImprovements: fieldImprovements,
      roads: roads,
    );
    _validator.validateSnapshot(after);
    _snapshot = after;
    return after;
  }

  void replaceAfterResync(AonwPlayerViewSnapshot snapshot) {
    _validator.validateSnapshot(snapshot);
    if (!_validator.hasSameStaticIdentity(_snapshot.stamp, snapshot.stamp)) {
      throw const FormatException(
        'Recipient resync belongs to another session identity.',
      );
    }
    if (snapshot.stamp.revision < _snapshot.stamp.revision) {
      throw const FormatException('Recipient resync would move revision back.');
    }
    _snapshot = snapshot;
  }

  void _validateCommandIdentity(
    AonwCommandResult command,
    AonwPlayerViewSnapshot before,
  ) {
    _validator.validateStamp(command.stamp);
    if (!_validator.hasSameStaticIdentity(before.stamp, command.stamp)) {
      throw const FormatException('Command result belongs to another session.');
    }
    if (!command.accepted &&
        (command.stamp.revision != before.stamp.revision ||
            command.stamp.stateDigest != before.stamp.stateDigest)) {
      throw const FormatException('Rejected command changed session identity.');
    }
  }

  static void _validatePatchIdentity(
    AonwPlayerViewPatch patch, {
    required AonwCommandResult command,
    required AonwPlayerViewSnapshot before,
  }) {
    if (patch.fromRevision != before.stamp.revision ||
        patch.toRevision != command.stamp.revision) {
      throw const FormatException(
        'Recipient patch does not continue the cached revision.',
      );
    }
    if (command.accepted) {
      _validateAcceptedPatch(patch, command: command, before: before);
      return;
    }
    _validateRejectedPatch(patch, before);
  }

  static void _validateAcceptedPatch(
    AonwPlayerViewPatch patch, {
    required AonwCommandResult command,
    required AonwPlayerViewSnapshot before,
  }) {
    if (patch.toRevision == patch.fromRevision + 1) return;
    if (patch.toRevision != patch.fromRevision ||
        command.stamp.stateDigest != before.stamp.stateDigest ||
        _changesAuthoritativeState(patch, before)) {
      throw const FormatException('Accepted command patch is not canonical.');
    }
  }

  static void _validateRejectedPatch(
    AonwPlayerViewPatch patch,
    AonwPlayerViewSnapshot before,
  ) {
    if (patch.toRevision != patch.fromRevision ||
        _changesAuthoritativeState(patch, before)) {
      throw const FormatException(
        'Rejected command returned a mutating patch.',
      );
    }
  }

  static bool _changesAuthoritativeState(
    AonwPlayerViewPatch patch,
    AonwPlayerViewSnapshot before,
  ) =>
      patch.turn != before.turn ||
      patch.turnLifecycle != null ||
      patch.outcome != null ||
      patch.diplomacy != null ||
      !_samePendingAction(patch.pendingAction, before.pendingAction) ||
      !_sameFoundingDraft(patch.cityFoundingDraft, before.cityFoundingDraft) ||
      _changesCollections(patch);

  static bool _changesCollections(AonwPlayerViewPatch patch) => <bool>[
    patch.upsertedUnits.isNotEmpty,
    patch.removedUnitIds.isNotEmpty,
    patch.upsertedCities.isNotEmpty,
    patch.removedCityIds.isNotEmpty,
    patch.upsertedArtifacts.isNotEmpty,
    patch.removedArtifactIds.isNotEmpty,
    patch.upsertedFieldImprovements.isNotEmpty,
    patch.removedFieldImprovementCoordinates.isNotEmpty,
    patch.upsertedRoads.isNotEmpty,
    patch.removedRoadCoordinates.isNotEmpty,
  ].contains(true);
}

bool _samePendingAction(
  AonwPendingActionView? left,
  AonwPendingActionView? right,
) {
  if (identical(left, right)) return true;
  return switch ((left, right)) {
    (null, null) => true,
    (AonwPendingResearchSelection(), AonwPendingResearchSelection()) => true,
    (
      AonwPendingCityWorkedHexSelection(:final cityId),
      AonwPendingCityWorkedHexSelection(cityId: final otherCityId),
    ) =>
      cityId == otherCityId,
    (
      AonwPendingCityExpansionSelection(:final cityId),
      AonwPendingCityExpansionSelection(cityId: final otherCityId),
    ) =>
      cityId == otherCityId,
    (
      AonwPendingWorkerActionSelection(:final unitId, :final improvement),
      AonwPendingWorkerActionSelection(
        unitId: final otherUnitId,
        improvement: final otherImprovement,
      ),
    ) =>
      unitId == otherUnitId && improvement == otherImprovement,
    (
      AonwPendingMerchantTradeRouteSelection(:final unitId),
      AonwPendingMerchantTradeRouteSelection(unitId: final otherUnitId),
    ) =>
      unitId == otherUnitId,
    (
      AonwPendingMerchantMoveToCitySelection(:final unitId),
      AonwPendingMerchantMoveToCitySelection(unitId: final otherUnitId),
    ) =>
      unitId == otherUnitId,
    (
      AonwPendingUnitTurnSkip(:final unitId, :final restoreMovementUnits),
      AonwPendingUnitTurnSkip(
        unitId: final otherUnitId,
        restoreMovementUnits: final otherRestoreMovementUnits,
      ),
    ) =>
      unitId == otherUnitId &&
          restoreMovementUnits == otherRestoreMovementUnits,
    (
      AonwPendingAttackTargeting(:final unitId, :final defender),
      AonwPendingAttackTargeting(
        unitId: final otherUnitId,
        defender: final otherDefender,
      ),
    ) =>
      unitId == otherUnitId && _sameCoordinate(defender, otherDefender),
    (
      AonwPendingCommanderMergeSelection(:final unitId),
      AonwPendingCommanderMergeSelection(unitId: final otherUnitId),
    ) =>
      unitId == otherUnitId,
    _ => false,
  };
}

bool _sameFoundingDraft(
  AonwCityFoundingDraft? left,
  AonwCityFoundingDraft? right,
) {
  if (identical(left, right)) return true;
  if (left == null || right == null) return false;
  return left.founderUnitId == right.founderUnitId &&
      _sameCoordinate(left.center, right.center) &&
      _sameCoordinates(left.controlledHexes, right.controlledHexes);
}

bool _sameCoordinates(List<AonwCoordinate> left, List<AonwCoordinate> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (!_sameCoordinate(left[index], right[index])) return false;
  }
  return true;
}

bool _sameCoordinate(AonwCoordinate? left, AonwCoordinate? right) =>
    identical(left, right) ||
    (left != null &&
        right != null &&
        left.col == right.col &&
        left.row == right.row);
