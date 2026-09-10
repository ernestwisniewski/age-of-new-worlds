import 'dart:async';

import 'package:aonw_flutter/features/multiplayer/application/match_history_port.dart';
import 'package:aonw_flutter/features/multiplayer/presentation/match_history_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'match_history_fixture.dart';

void main() {
  test(
    'paged history stays bounded and failed navigation keeps its cursor',
    () async {
      final port = HistoryPort();
      final controller = MatchHistoryController(port, userId: 'account');
      addTearDown(controller.dispose);
      await controller.refresh();
      expect(controller.page!.entries.single.match.matchId, 'match-first');
      expect(controller.hasNext, isTrue);
      port.failure = StateError('offline');
      await controller.next();
      expect(controller.page!.entries.single.match.matchId, 'match-first');
      expect(controller.hasPrevious, isFalse);
      port.failure = null;
      await controller.next();
      expect(controller.page!.entries.single.match.matchId, 'match-second');
      expect(controller.hasNext, isFalse);
      await controller.previous();
      expect(controller.page!.entries.single.match.matchId, 'match-first');
      expect(controller.hasPrevious, isFalse);
      expect(port.cursors, [null, 42, 42, null]);
    },
  );

  test('history ignores duplicate loads and disposed responses', () async {
    final port = HistoryPort()..pending = Completer<MatchHistoryPageView>();
    final controller = MatchHistoryController(port, userId: 'account');
    final pending = controller.refresh();
    await controller.refresh();
    expect(port.cursors, [null]);
    controller.dispose();
    port.pending!.complete(historyPage());
    await pending;
    expect(controller.page, isNull);
  });

  test('history rejects foreign accounts and a nonadvancing cursor', () async {
    final port = HistoryPort()..userId = 'foreign';
    final controller = MatchHistoryController(port, userId: 'account');
    addTearDown(controller.dispose);
    await controller.refresh();
    expect(controller.page, isNull);
    expect(controller.failureCode, 'history_session_changed');
    port.userId = 'account';
    await controller.refresh();
    port.pending = Completer<MatchHistoryPageView>()..complete(historyPage());
    await controller.next();
    expect(controller.failureCode, 'history_unavailable');
    expect(controller.hasPrevious, isFalse);
  });
}
