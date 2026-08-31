import 'dart:convert';
import 'dart:io';

import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Flutter and Godot share command semantics without pixel goldens', () {
    final manifest = _fixture('gameplay_semantic_v1.json');
    expect(manifest['schemaVersion'], 1);

    final intentDocument = _fixture(manifest['intentFixture'] as String);
    final request = intentDocument['request'] as Map<String, dynamic>;
    expect(request['type'], 'dispatch');
    expect(request['command'], manifest['expectedIntent']);

    for (final rawCase in manifest['cases'] as List<dynamic>) {
      final semanticCase = rawCase as Map<String, dynamic>;
      final expected = semanticCase['expected'] as Map<String, dynamic>;
      final response = AonwClientResponse.parse(
        File(
          _fixturePath(semanticCase['responseFixture'] as String),
        ).readAsStringSync(),
      ).require<AonwCommandResponse>();
      final command = response.result;
      final patch = command.viewPatch;

      expect(command.accepted, expected['accepted']);
      expect(command.rejection?.wireCode, expected['rejection']);
      expect(command.stamp.revision, expected['revision']);
      expect({
        'fromRevision': patch.fromRevision,
        'toRevision': patch.toRevision,
        'turn': patch.turn,
        'upsertedUnitIds': patch.upsertedUnits.map((unit) => unit.id).toList(),
        'removedUnitIds': patch.removedUnitIds,
      }, expected['patch']);
      expect([
        for (var index = 0; index < command.events.length; index++)
          {
            'revision': command.stamp.revision,
            'index': index,
            'kind': command.events[index].kind.name,
          },
      ], expected['events']);
      expect(_evidenceKind(command.evidence), expected['evidenceKind']);
      expect(patch.outcome?.condition.name, expected['outcomeCondition']);
    }
  });
}

String? _evidenceKind(AonwClientEvidence? evidence) => switch (evidence) {
  null => null,
  AonwUnitMovementEvidence() => 'unitMovement',
  _ => evidence.runtimeType.toString(),
};

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File(_fixturePath(name)).readAsStringSync())
        as Map<String, dynamic>;

String _fixturePath(String name) {
  for (final root in [
    'test/fixtures/client_protocol',
    '../../test/fixtures/client_protocol',
  ]) {
    final path = '$root/$name';
    if (File(path).existsSync()) return path;
  }
  throw StateError('Shared gameplay semantic fixture not found: $name');
}
