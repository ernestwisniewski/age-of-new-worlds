import 'package:aonw_engine_client/aonw_engine_client.dart';

import 'recipient_projection_validator.dart';

final class RecipientProjectionCollections {
  const RecipientProjectionCollections(this.validator);

  final RecipientProjectionValidator validator;

  List<T> applyIdPatch<T>({
    required List<T> current,
    required List<T> upserted,
    required List<String> removedIds,
    required String Function(T value) idOf,
    required String label,
  }) {
    validator.validateOrderedIds(upserted, idOf, 'upserted $label');
    validator.validateOrderedStrings(removedIds, 'removed $label id');
    final next = <String, T>{for (final value in current) idOf(value): value};
    final upsertedIds = upserted.map(idOf).toSet();
    for (final id in removedIds) {
      if (upsertedIds.contains(id) || next.remove(id) == null) {
        throw FormatException('Recipient patch has invalid $label removal.');
      }
    }
    for (final value in upserted) {
      next[idOf(value)] = value;
    }
    final ids = next.keys.toList()..sort();
    return List<T>.unmodifiable(ids.map((id) => next[id]!));
  }

  List<T> applyCoordinatePatch<T>({
    required List<T> current,
    required List<T> upserted,
    required List<AonwCoordinate> removed,
    required AonwCoordinate Function(T value) coordinateOf,
    required String label,
  }) {
    validator.validateOrderedCoordinates(
      upserted,
      coordinateOf,
      'upserted $label',
    );
    validator.validateOrderedCoordinateValues(removed, 'removed $label');
    final next = <CoordinateKey, T>{
      for (final value in current) coordinateKey(coordinateOf(value)): value,
    };
    final upsertedKeys = upserted
        .map((value) => coordinateKey(coordinateOf(value)))
        .toSet();
    for (final coordinate in removed) {
      validator.requireCoordinate(coordinate, 'removed $label');
      final key = coordinateKey(coordinate);
      if (upsertedKeys.contains(key) || next.remove(key) == null) {
        throw FormatException('Recipient patch has invalid $label removal.');
      }
    }
    for (final value in upserted) {
      final coordinate = coordinateOf(value);
      validator.requireCoordinate(coordinate, label);
      next[coordinateKey(coordinate)] = value;
    }
    final keys = next.keys.toList()..sort(compareCoordinates);
    return List<T>.unmodifiable(keys.map((key) => next[key]!));
  }
}
