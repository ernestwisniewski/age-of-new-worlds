import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/map/application/map_session_port.dart';
import 'package:aonw_flutter/features/replay/application/local_replay_store.dart';
import 'package:aonw_flutter/features/replay/application/replay_session_port.dart';
import 'package:aonw_flutter/features/replay/application/replay_state.dart';
import 'package:aonw_flutter/features/replay/presentation/replay_presentation_controller.dart';
import 'package:aonw_flutter/features/replay/read_model/replay_frame_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  testWidgets('captures, opens, seeks, changes speed, and plays in order', (
    tester,
  ) async {
    final session = _ReplaySession();
    final store = _ReplayStore();
    final controller = ReplayPresentationController(
      session: session,
      store: store,
      diagnosticReporter: (_, _, _) {},
    );
    addTearDown(controller.dispose);

    await controller.captureReplay(LocalGameCatalog.entries.first);
    expect(store.document, 'engine-replay');
    expect(await controller.hasReplay(), isTrue);
    expect((await controller.openLatest()).started, isTrue);
    expect((controller.state as ReplayReady).frame.position, 0);

    controller.seek(2);
    await tester.pump();
    expect((controller.state as ReplayReady).frame.position, 2);

    controller.cycleSpeed();
    controller.cycleSpeed();
    expect((controller.state as ReplayReady).speed, ReplaySpeedView.fourTimes);
    controller.play();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    final completed = controller.state as ReplayReady;
    expect(completed.frame.position, 3);
    expect(completed.isPlaying, isFalse);
    expect(session.positions, [2, 3]);
  });

  test('falls back from corrupt primary to current backup', () async {
    final session = _ReplaySession(rejectDocument: 'corrupt');
    final store = _ReplayStore(primary: 'corrupt', backup: 'valid');
    final controller = ReplayPresentationController(
      session: session,
      store: store,
      diagnosticReporter: (_, _, _) {},
    );
    addTearDown(controller.dispose);

    expect((await controller.openLatest()).started, isTrue);
    expect(session.openedDocuments, ['corrupt', 'valid']);
    expect(controller.state, isA<ReplayReady>());
  });
}

final class _ReplaySession implements ReplaySessionPort {
  _ReplaySession({this.rejectDocument});

  final String? rejectDocument;
  final positions = <int>[];
  final openedDocuments = <String>[];

  @override
  Future<String> exportReplayDocument() async => 'engine-replay';

  @override
  Future<ReplayFrameView> openReplayDocument({
    required MapAssetPaths assets,
    required String document,
  }) async {
    openedDocuments.add(document);
    if (document == rejectDocument) {
      throw const ReplaySessionException(
        code: 'replay_open_failed',
        message: 'Rejected replay.',
      );
    }
    return _frame(0);
  }

  @override
  Future<ReplayFrameView> seekReplay(int position) async {
    positions.add(position);
    return _frame(position);
  }

  ReplayFrameView _frame(int position) =>
      ReplayFrameView(position: position, entryCount: 3, scene: testMapScene());
}

final class _ReplayStore implements LocalReplayStore {
  _ReplayStore({String? primary, this.backup}) : document = primary;

  String? document;
  final String? backup;

  @override
  Future<bool> contains(LocalGameScenarioView scenario) async =>
      document != null || backup != null;

  @override
  Future<String?> read(
    LocalGameScenarioView scenario,
    LocalReplayCopyView copy,
  ) async => switch (copy) {
    LocalReplayCopyView.primary => document,
    LocalReplayCopyView.backup => backup,
  };

  @override
  Future<void> write(LocalGameScenarioView scenario, String document) async {
    this.document = document;
  }
}
