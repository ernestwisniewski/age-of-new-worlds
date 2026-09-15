import 'package:aonw_engine_client/src/protocol_hud_status.dart';
import 'package:test/test.dart';

void main() {
  test('decodes authoritative warning and victory variants strictly', () {
    for (final warning in AonwTreasuryWarning.values) {
      expect(AonwTreasuryWarning.fromJson(warning.name), warning);
    }
    for (final kind in AonwVictoryStatusKind.values) {
      final status = AonwVictoryStatus.fromJson({
        'kind': kind.name,
        'critical': true,
        'leaderPlayerId': 'player-1',
      });
      expect(status.kind, kind);
      expect(status.critical, isTrue);
      expect(status.leaderPlayerId, 'player-1');
    }
    expect(
      AonwVictoryStatus.fromJson({
        'kind': 'score',
        'critical': false,
        'leaderPlayerId': null,
      }).leaderPlayerId,
      isNull,
    );
  });

  test('rejects missing, extra, unknown and mistyped HUD status fields', () {
    final valid = <String, Object?>{
      'kind': 'score',
      'critical': true,
      'leaderPlayerId': null,
    };
    for (final key in valid.keys) {
      expect(
        () => AonwVictoryStatus.fromJson({...valid}..remove(key)),
        throwsFormatException,
      );
    }
    for (final invalid in [
      {...valid, 'extra': false},
      {...valid, 'kind': 'guess'},
      {...valid, 'critical': 1},
      {...valid, 'leaderPlayerId': 7},
    ]) {
      expect(() => AonwVictoryStatus.fromJson(invalid), throwsFormatException);
    }
    for (final invalid in [null, 0, 'guess']) {
      expect(
        () => AonwTreasuryWarning.fromJson(invalid),
        throwsFormatException,
      );
    }
  });
}
