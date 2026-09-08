part of 'map_automatic_turn_test.dart';

void researchCancellationTests() {
  testWidgets(
    'required research closes after acknowledgement without automatic reopening',
    (tester) async {
      final h = _Harness(actions: [_research], requiredResearch: true);
      final response = Completer<ResearchCommandResultView>();
      h.session.researchCancellationHandler = (_) => response.future;
      _currentResearchWork(h);
      await h.mount(tester, settle: false);
      await tester.tap(find.byKey(const ValueKey('close-research')));
      await tester.pump();
      expect(h.session.researchCancellationCalls, 1);
      expect(
        h.ready.recipient.pendingAction,
        isA<PendingResearchSelectionView>(),
      );
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('close-research')))
            .onPressed,
        isNull,
      );
      response.complete(_cancelledResearch());
      await _pumpResearchUi(tester);
      expect(h.ready.recipient.pendingAction, isNull);
      expect(find.byKey(const ValueKey('close-research')), findsNothing);
      final queries = h.session.pendingTurnActionsRevisions.length;
      await tester.pump(const Duration(seconds: 10));
      await _pumpResearchUi(tester);
      expect(find.byKey(const ValueKey('close-research')), findsNothing);
      expect(h.session.pendingTurnActionsRevisions, hasLength(queries));
      expect(h.session.endTurnCalls, 0);
      await tester.tap(find.byKey(const ValueKey('open-research')));
      await _pumpResearchUi(tester);
      expect(find.byKey(const ValueKey('close-research')), findsOneWidget);
      expect(h.session.researchCancellationCalls, 1);
    },
  );

  testWidgets('another HUD panel opens after required research is cancelled', (
    tester,
  ) async {
    final h = _Harness(actions: [_research], requiredResearch: true);
    final response = Completer<ResearchCommandResultView>();
    h.session.researchCancellationHandler = (_) => response.future;
    _currentResearchWork(h);
    await h.mount(tester, settle: false);
    await tester.tap(find.byKey(const ValueKey('open-objectives')));
    await tester.pump();
    expect(find.byKey(const ValueKey('close-objectives')), findsNothing);
    expect(find.byKey(const ValueKey('close-research')), findsOneWidget);
    response.complete(_cancelledResearch());
    await _pumpResearchUi(tester);
    expect(find.byKey(const ValueKey('close-objectives')), findsOneWidget);
    expect(find.byKey(const ValueKey('close-research')), findsNothing);
    expect(h.session.researchCancellationCalls, 1);
  });

  testWidgets('rejected cancellation keeps the panel open and permits retry', (
    tester,
  ) async {
    final h = _Harness(actions: [_research], requiredResearch: true);
    h.session.researchCancellationHandler = (_) async =>
        const ResearchCommandResultView.rejected(
          rejectionCode: ResearchRejectionCodeView.staleRevision,
        );
    _currentResearchWork(h);
    await h.mount(tester, settle: false);
    await tester.tap(find.byKey(const ValueKey('close-research')));
    await _pumpResearchUi(tester);
    expect(find.byKey(const ValueKey('close-research')), findsOneWidget);
    expect(h.ready.research.failure, isNotNull);
    expect(
      h.ready.recipient.pendingAction,
      isA<PendingResearchSelectionView>(),
    );
    h.session.researchCancellationHandler = (_) async => _cancelledResearch();
    await tester.tap(find.byKey(const ValueKey('close-research')));
    await _pumpResearchUi(tester);
    expect(find.byKey(const ValueKey('close-research')), findsNothing);
    expect(h.session.researchCancellationCalls, 2);
  });
}

ResearchCommandResultView _cancelledResearch() =>
    ResearchCommandResultView.accepted(
      player: PlayerMapView.preview(
        actorPlayerId: 'preview-player',
        stamp: testSessionStamp(revision: 1),
        turn: 1,
        pendingAction: null,
        units: [testVisibleUnit()],
      ),
    );

void _currentResearchWork(_Harness h) {
  h.session.pendingTurnActionsResult = null;
  h.session.pendingTurnActionsHandler = (revision) async =>
      PendingTurnActionsView(
        stamp: testSessionStamp(revision: revision),
        actorPlayerId: 'preview-player',
        canActivate: true,
        actions: [_research],
      );
}

Future<void> _pumpResearchUi(WidgetTester tester) async {
  for (var frame = 0; frame < 20; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
