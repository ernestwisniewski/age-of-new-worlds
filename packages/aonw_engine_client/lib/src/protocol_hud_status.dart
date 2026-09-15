import 'package:aonw_engine_client/src/protocol_json.dart';

enum AonwTreasuryWarning {
  none,
  negativeBalance,
  deficitWithinThreeTurns;

  factory AonwTreasuryWarning.fromJson(Object? source) {
    final wire = readString(source, 'treasury warning');
    return values.firstWhere(
      (value) => value.name == wire,
      orElse: () => throw FormatException('Unknown treasury warning $wire.'),
    );
  }
}

enum AonwVictoryStatusKind {
  none,
  conquest,
  domination,
  culture,
  score;

  factory AonwVictoryStatusKind.fromJson(Object? source) {
    final wire = readString(source, 'victory status kind');
    return values.firstWhere(
      (value) => value.name == wire,
      orElse: () => throw FormatException('Unknown victory status kind $wire.'),
    );
  }
}

final class AonwVictoryStatus {
  const AonwVictoryStatus({
    required this.kind,
    required this.critical,
    required this.leaderPlayerId,
  });

  static const empty = AonwVictoryStatus(
    kind: AonwVictoryStatusKind.none,
    critical: false,
    leaderPlayerId: null,
  );

  factory AonwVictoryStatus.fromJson(Object? source) {
    final value = readObject(source, 'victory status');
    requireKeys(value, const {
      'kind',
      'critical',
      'leaderPlayerId',
    }, 'victory status');
    return AonwVictoryStatus(
      kind: AonwVictoryStatusKind.fromJson(value['kind']),
      critical: readBool(value['critical'], 'victory status critical'),
      leaderPlayerId: readNullableString(
        value['leaderPlayerId'],
        'victory status leader',
      ),
    );
  }

  final AonwVictoryStatusKind kind;
  final bool critical;
  final String? leaderPlayerId;
}
