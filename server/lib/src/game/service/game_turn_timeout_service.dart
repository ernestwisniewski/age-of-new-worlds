import 'package:aonw_server/src/game/service/game_match_service.dart';
import 'package:aonw_server/src/game/service/game_turn_timeout_policy.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/scheduling/background_task_support.dart';
import 'package:serverpod/serverpod.dart';

final class GameTurnTimeoutService {
  const GameTurnTimeoutService({
    this.batchSize = gameTurnTimeoutBatchSize,
    GameMatchService? matches,
  }) : assert(batchSize > 0),
       _matches = matches;

  final int batchSize;
  final GameMatchService? _matches;

  Future<GameTurnTimeoutResult> run(
    Session session, {
    required DateTime now,
  }) async {
    final instant = now.toUtc();
    final candidates = await GameMatch.db.find(
      session,
      where: (table) =>
          table.state.equals('running') & (table.turnDeadlineAt <= instant),
      orderBy: (table) => table.turnDeadlineAt,
      limit: batchSize + 1,
    );
    final due = candidates.take(batchSize).toList(growable: false);
    final service = _matches ?? GameMatchService();
    var finalized = 0;
    final failures = <GameTurnTimeoutFailure>[];
    for (final match in due) {
      try {
        final applied = await service.finalizeTimedOutTurn(
          session,
          matchId: match.publicId,
          now: instant,
        );
        if (applied) finalized += 1;
      } on Object catch (error, stackTrace) {
        failures.add(
          GameTurnTimeoutFailure(
            matchId: match.publicId,
            kind: backgroundTaskErrorKind(error),
            stackTrace: stackTrace,
          ),
        );
      }
    }
    return GameTurnTimeoutResult(
      candidates: due.length,
      finalized: finalized,
      backlogRemaining: candidates.length > batchSize,
      failures: List.unmodifiable(failures),
    );
  }
}

final class GameTurnTimeoutResult {
  const GameTurnTimeoutResult({
    required this.candidates,
    required this.finalized,
    required this.backlogRemaining,
    required this.failures,
  });

  final int candidates;
  final int finalized;
  final bool backlogRemaining;
  final List<GameTurnTimeoutFailure> failures;
}

final class GameTurnTimeoutFailure {
  const GameTurnTimeoutFailure({
    required this.matchId,
    required this.kind,
    required this.stackTrace,
  });

  final String matchId;
  final BackgroundTaskErrorKind kind;
  final StackTrace stackTrace;
}
