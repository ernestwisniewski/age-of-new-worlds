import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:test/test.dart';

void main() {
  test('retains the exact removed or retreating combat participant', () {
    for (final kind in ['unitKilled', 'unitRetreated']) {
      final document = {
        'type': kind,
        'attackerUnitId': 'attacker',
        'target': {'type': 'unit', 'unitId': 'defender'},
        'subjectUnitId': 'defender',
      };
      final event = AonwClientEvent.fromJson(document) as AonwUnitStatusEvent;
      expect(event.kind.name, kind);
      expect(event.attackerUnitId, 'attacker');
      expect(event.subjectUnitId, 'defender');
      expect((event.target as AonwUnitCombatTarget).unitId, 'defender');
      for (final key in document.keys) {
        expect(
          () => AonwClientEvent.fromJson({...document}..remove(key)),
          throwsFormatException,
        );
      }
      expect(
        () => AonwClientEvent.fromJson({...document, 'extra': true}),
        throwsFormatException,
      );
      expect(
        () => AonwClientEvent.fromJson({
          ...document,
          'target': {'type': 'unit', 'unitId': 'defender', 'extra': true},
        }),
        throwsFormatException,
      );
    }
  });
}
