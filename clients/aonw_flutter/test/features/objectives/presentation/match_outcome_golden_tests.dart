part of 'match_outcome_overlay_test.dart';

void outcomeGoldenTests() {
  setUpAll(() async {
    for (final (family, path) in [
      ('Cinzel', 'assets/fonts/Cinzel-VariableFont_wght.ttf'),
      ('Lato', 'assets/fonts/Lato-Regular.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(path))).load();
    }
  });
  for (final sample in [
    (
      name: 'phone',
      size: const Size(390, 844),
      language: 'pl',
      scale: 1.0,
      winner: 'player-1',
    ),
    (
      name: 'tablet',
      size: const Size(1024, 768),
      language: 'de',
      scale: 1.0,
      winner: 'player-2',
    ),
    (
      name: 'desktop',
      size: const Size(1440, 900),
      language: 'en',
      scale: 1.0,
      winner: null,
    ),
    (
      name: 'large_text',
      size: const Size(390, 844),
      language: 'de',
      scale: 2.0,
      winner: 'player-2',
    ),
  ]) {
    testWidgets('outcome golden ${sample.name}', (tester) async {
      _size(tester, sample.size);
      await tester.pumpWidget(
        _app(
          RepaintBoundary(
            key: const ValueKey('outcome-golden'),
            child: _overlay(
              winner: sample.winner,
              condition: sample.winner == null
                  ? GameOutcomeConditionView.draw
                  : GameOutcomeConditionView.score,
              scores: sample.winner == null
                  ? const {'player-1': 420, 'player-2': 420}
                  : sample.winner == 'player-1'
                  ? const {'player-1': 420, 'player-2': 120}
                  : const {'player-1': 120, 'player-2': 420},
            ),
          ),
          language: sample.language,
          size: sample.size,
          scale: sample.scale,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.hasRunningAnimations, isFalse);
      await expectLater(
        find.byKey(const ValueKey('outcome-golden')),
        matchesGoldenFile('goldens/outcome_${sample.name}.png'),
      );
    });
  }
}
