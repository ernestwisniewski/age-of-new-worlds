import 'dart:async';

import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_interaction_state.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/research/application/research_session_port.dart';
import 'package:aonw_flutter/features/research/application/research_state.dart';
import 'package:aonw_flutter/features/research/application/research_workflow.dart';
import 'package:aonw_flutter/features/research/read_model/research_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  test(
    'cancelling during a query ignores its late options and sends only once',
    () async {
      final h = _Harness();
      h.workflow.load(
        readState: () => h.state,
        publish: h.publish,
        isDisposed: () => h.disposed,
      );
      h.cancel();
      h.cancel();
      h.workflow.select(
        technology: TechnologyIdView.agriculture,
        readState: () => h.state,
        publish: h.publish,
        isDisposed: () => h.disposed,
      );
      expect(h.session.cancelRevisions, [0]);
      expect(h.session.selections, 0);
      expect(h.state.research.cancellingSelection, isTrue);
      h.session.options.complete(testResearchOptionsView());
      await pumpEventQueue();
      expect(h.state.research.options, isNull);
      expect(h.state.research.commandPending, isTrue);
      h.session.response.complete(
        ResearchCommandResultView.accepted(player: _player(1)),
      );
      await pumpEventQueue();
      expect(h.state.recipient.pendingAction, isNull);
      expect(h.state.interaction.researchFocused, isFalse);
      expect(h.state.research.commandPending, isFalse);
      expect(h.state.research.loading, isTrue);
      expect(h.state.recipient.stamp.revision, 1);
    },
  );

  test(
    'rejection preserves the canonical choice and releases the command',
    () async {
      final h = _Harness();
      h.cancel();
      h.session.response.complete(
        const ResearchCommandResultView.rejected(
          rejectionCode: ResearchRejectionCodeView.staleRevision,
        ),
      );
      await pumpEventQueue();
      expect(
        h.state.recipient.pendingAction,
        isA<PendingResearchSelectionView>(),
      );
      expect(h.state.interaction.researchFocused, isTrue);
      expect(h.state.research.commandPending, isFalse);
      expect(h.state.research.failure?.code, ResearchFailureCode.rejected);
    },
  );

  test(
    'transport failure keeps the pending choice available for retry',
    () async {
      final h = _Harness();
      h.cancel();
      h.session.response.completeError(
        const ResearchSessionException(code: 'offline', message: 'Unavailable'),
      );
      await pumpEventQueue();
      expect(
        h.state.recipient.pendingAction,
        isA<PendingResearchSelectionView>(),
      );
      expect(h.state.research.commandPending, isFalse);
      expect(h.state.research.failure?.code, ResearchFailureCode.requestFailed);
    },
  );

  test('a newer recipient discards the older cancellation response', () async {
    final h = _Harness();
    h.cancel();
    h.state = h.state.withRecipient(_player(2));
    final newer = h.state;
    h.session.response.complete(
      ResearchCommandResultView.accepted(player: _player(1)),
    );
    await pumpEventQueue();
    expect(h.state, same(newer));
  });

  test('disposal prevents a late cancellation from publishing', () async {
    final h = _Harness();
    h.cancel();
    final pending = h.state;
    h.disposed = true;
    h.session.response.complete(
      ResearchCommandResultView.accepted(player: _player(1)),
    );
    await pumpEventQueue();
    expect(h.state, same(pending));
  });

  test('no canonical research choice means no cancellation request', () {
    final h = _Harness();
    h.state = h.state.withRecipient(_player(0));
    h.cancel();
    expect(h.session.cancelRevisions, isEmpty);
  });
}

final class _Harness {
  _Harness() {
    workflow = ResearchWorkflow(
      session: session,
      diagnosticReporter: (_, error, stack) => fail('$error\n$stack'),
    );
  }
  final session = _Session();
  late final ResearchWorkflow workflow;
  var disposed = false;
  var state = GameSessionReady.initial(
    testMapScene(pendingAction: const PendingResearchSelectionView()),
  ).withInteraction(const MapInteractionState(researchFocused: true));
  void publish(GameSessionReady value) => state = value;
  void cancel() => workflow.cancelSelection(
    readState: () => state,
    publish: publish,
    isDisposed: () => disposed,
  );
}

final class _Session implements ResearchSessionPort {
  final options = Completer<ResearchOptionsView>();
  final response = Completer<ResearchCommandResultView>();
  final cancelRevisions = <int>[];
  var selections = 0;
  @override
  Future<ResearchOptionsView> researchOptions({
    required int expectedRevision,
  }) => options.future;
  @override
  Future<ResearchCommandResultView> cancelResearchSelection({
    required int expectedRevision,
  }) {
    cancelRevisions.add(expectedRevision);
    return response.future;
  }

  @override
  Future<ResearchCommandResultView> selectTechnology({
    required int expectedRevision,
    required TechnologyIdView technology,
  }) {
    selections += 1;
    return response.future;
  }
}

PlayerMapView _player(int revision) => PlayerMapView.preview(
  actorPlayerId: 'preview-player',
  stamp: testSessionStamp(revision: revision),
  turn: 1,
  pendingAction: null,
  units: const [],
);
