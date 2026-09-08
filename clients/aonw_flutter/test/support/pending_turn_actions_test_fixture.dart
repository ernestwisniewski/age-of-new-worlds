import 'package:aonw_flutter/features/turns/read_model/pending_turn_actions_view.dart';

mixin FakePendingTurnActionsSession {
  PendingTurnActionsView? pendingTurnActionsResult;
  Object? pendingTurnActionsFailure;
  Future<PendingTurnActionsView> Function(int)? pendingTurnActionsHandler;
  final pendingTurnActionsRevisions = <int>[];

  Future<PendingTurnActionsView> pendingTurnActions({
    required int expectedRevision,
  }) async {
    pendingTurnActionsRevisions.add(expectedRevision);
    final handler = pendingTurnActionsHandler;
    if (handler != null) return handler(expectedRevision);
    final error = pendingTurnActionsFailure;
    if (error != null) throw error;
    return pendingTurnActionsResult ??
        (throw StateError('No pending turn actions fixture.'));
  }
}
