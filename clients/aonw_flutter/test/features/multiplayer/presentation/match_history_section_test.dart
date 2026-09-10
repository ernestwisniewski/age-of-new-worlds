import 'dart:async';

import 'package:aonw_flutter/design_system/aonw_theme.dart';
import 'package:aonw_flutter/features/multiplayer/application/match_history_port.dart';
import 'package:aonw_flutter/features/multiplayer/presentation/match_history_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';
import 'match_history_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Cinzel')..addFont(
          rootBundle.load('assets/fonts/Cinzel-VariableFont_wght.ttf'),
        ))
        .load();
    await (FontLoader(
      'Lato',
    )..addFont(rootBundle.load('assets/fonts/Lato-Regular.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final (language, size) in [
    ('pl', const Size(390, 844)),
    ('de', const Size(1024, 768)),
    ('en', const Size(1440, 900)),
  ]) {
    testWidgets(
      '$language online replay action is responsive and respects busy state',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final port = HistoryPort()..replayAvailable = true;
        MatchHistoryEntryView? selected;
        Future<void> open(MatchHistoryEntryView entry) async {
          selected = entry;
        }

        await tester.pumpWidget(
          _app(port, language: language, size: size, onReplay: open),
        );
        await tester.tap(find.byKey(const ValueKey('match-history-section')));
        await tester.pumpAndSettle();
        await expectLater(
          find.byKey(const ValueKey('history-golden')),
          matchesGoldenFile('goldens/match_history_replay_$language.png'),
        );
        final button = find.byKey(
          const ValueKey(('history-replay', 'match-first')),
        );
        await tester.ensureVisible(button);
        await tester.tap(button);
        expect(selected?.match.matchId, 'match-first');
        await tester.pumpWidget(
          _app(
            port,
            language: language,
            size: size,
            onReplay: open,
            replayBusy: true,
          ),
        );
        await tester.pump();
        expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final language in ['en', 'pl', 'de', 'fr', 'es', 'nl']) {
    testWidgets('$language history loads lazily and navigates bounded pages', (
      tester,
    ) async {
      final size = Size(switch (language) {
        'en' => 1440,
        'de' => 1024,
        _ => 390,
      }, 844);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final port = HistoryPort();
      await tester.pumpWidget(_app(port, language: language, size: size));
      expect(port.cursors, isEmpty);
      await tester.tap(find.byKey(const ValueKey('match-history-section')));
      await tester.pumpAndSettle();
      expect(port.cursors, [null]);
      expect(
        find.byKey(const ValueKey(('match-history-entry', 'match-first'))),
        findsOneWidget,
      );
      if (['en', 'pl', 'de'].contains(language)) {
        await expectLater(
          find.byKey(const ValueKey('history-golden')),
          matchesGoldenFile('goldens/match_history_$language.png'),
        );
      }
      final next = find.byKey(const ValueKey('history-next'));
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey(('match-history-entry', 'match-first'))),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey(('match-history-entry', 'match-second'))),
        findsOneWidget,
      );
      final previous = find.byKey(const ValueKey('history-previous'));
      await tester.ensureVisible(previous);
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(port.cursors, [null, 42, null]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('changing accounts discards the old response', (tester) async {
    final old = HistoryPort()..pending = Completer<MatchHistoryPageView>();
    await tester.pumpWidget(_app(old));
    await tester.tap(find.byKey(const ValueKey('match-history-section')));
    await tester.pump();
    final current = HistoryPort()..userId = 'new-account';
    await tester.pumpWidget(_app(current, userId: 'new-account'));
    await tester.pumpAndSettle();
    old.pending!.complete(historyPage(second: true));
    await tester.pumpAndSettle();
    expect(current.cursors, [null]);
    expect(
      find.byKey(const ValueKey(('match-history-entry', 'match-second'))),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey(('match-history-entry', 'match-first'))),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _app(
  HistoryPort port, {
  String userId = 'account',
  Future<void> Function(MatchHistoryEntryView)? onReplay,
  bool replayBusy = false,
  String language = 'en',
  Size size = const Size(800, 600),
}) => LocalizedTestApp(
  locale: Locale(language),
  theme: AonwTheme.dark,
  home: RepaintBoundary(
    key: const ValueKey('history-golden'),
    child: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: const TextScaler.linear(1.3),
        ),
        child: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: 760,
              child: MatchHistorySection(
                port: port,
                userId: userId,
                onReplay: onReplay,
                replayBusy: replayBusy,
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);
