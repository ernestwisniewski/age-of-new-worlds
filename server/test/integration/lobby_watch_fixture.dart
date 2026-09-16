import 'dart:async';

import 'package:aonw_server/src/generated/protocol.dart';
import 'package:test/test.dart';

/// Hold the first live lease while a rollback-isolated test issues requests.
/// Pausing prevents heartbeat queries from overlapping its shared transaction.
Future<StreamSubscription<GameLobbyView>> watchTestLobby(
  Stream<GameLobbyView> stream,
) async {
  final first = Completer<void>();
  late final StreamSubscription<GameLobbyView> subscription;
  subscription = stream.listen(
    (_) {
      subscription.pause();
      if (!first.isCompleted) first.complete();
    },
    onError: (Object error, StackTrace stack) {
      if (!first.isCompleted) {
        first.completeError(error, stack);
      } else {
        fail('Unexpected lobby stream failure: $error');
      }
    },
  );
  addTearDown(subscription.cancel);
  await first.future;
  return subscription;
}
