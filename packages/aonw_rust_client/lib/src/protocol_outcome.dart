import 'package:aonw_rust_client/src/protocol_json.dart';

enum AonwGameOutcomeCondition {
  ongoing,
  conquest,
  domination,
  cultural,
  score,
  resignation,
  draw;

  factory AonwGameOutcomeCondition.fromJson(Object? source) {
    final name = readString(source, 'game outcome condition');
    return values.firstWhere(
      (value) => value.name == name,
      orElse: () =>
          throw FormatException('Unknown AoNW game outcome condition $name.'),
    );
  }
}

final class AonwGameOutcome {
  AonwGameOutcome({
    required this.condition,
    required this.winnerPlayerId,
    required Map<String, int> scoreByPlayerId,
  }) : scoreByPlayerId = Map.unmodifiable(scoreByPlayerId);

  factory AonwGameOutcome.fromJson(Object? source) {
    final value = readObject(source, 'game outcome');
    requireKeys(value, const {
      'condition',
      'winnerPlayerId',
      'scoreByPlayerId',
    }, 'game outcome');
    return AonwGameOutcome(
      condition: AonwGameOutcomeCondition.fromJson(value['condition']),
      winnerPlayerId: readNullableString(
        value['winnerPlayerId'],
        'winner player id',
      ),
      scoreByPlayerId: readStringIntMap(
        value['scoreByPlayerId'],
        'score by player id',
      ),
    );
  }

  final AonwGameOutcomeCondition condition;
  final String? winnerPlayerId;
  final Map<String, int> scoreByPlayerId;
}
