import 'package:aonw_flutter/features/map/read_model/map_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_victory_view.dart';
import 'package:aonw_flutter/features/resources/presentation/resource_details.dart';
import 'package:aonw_flutter/features/resources/presentation/resource_pill.dart';
import 'package:aonw_flutter/features/resources/presentation/resource_strip.dart';
import 'package:aonw_flutter/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/localized_test_app.dart';
import '../../../support/resource_hud_test_host.dart';
import 'resource_test_fixture.dart';

void main() {
  testWidgets('opening details preserves the scrolled warning pill', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      LocalizedTestApp(
        home: Scaffold(
          body: ResourceHudTestHost(
            player: resourcePlayerFixture(
              warning: TreasuryWarningView.deficitWithinThreeTurns,
              shortages: const [MapResource.oil],
              victory: resourceVictoryFixture(
                const VictoryStatusView(
                  kind: VictoryStatusKindView.score,
                  critical: true,
                  leaderPlayerId: 'player-1',
                ),
              ),
            ),
            sessionIdentity: 0,
          ),
        ),
      ),
    );
    final gold = find.byKey(const ValueKey('resource-gold'));
    await tester.ensureVisible(gold);
    await tester.pumpAndSettle();
    final before = tester.getRect(gold);
    await tester.tap(gold);
    await tester.pumpAndSettle();
    expect(tester.getRect(gold), before);
    expect(tester.getRect(gold).left, greaterThanOrEqualTo(8));
  });

  testWidgets('warnings follow Rust metadata without predicting treasury', (
    tester,
  ) async {
    Future<void> show(TreasuryWarningView warning) => tester.pumpWidget(
      LocalizedTestApp(
        home: Scaffold(
          body: ResourceStrip(
            player: resourcePlayerFixture(warning: warning),
            open: null,
            onOpen: (_) {},
          ),
        ),
      ),
    );
    await show(TreasuryWarningView.none);
    expect(
      tester
          .widget<ResourcePill>(find.byKey(const ValueKey('resource-gold')))
          .warning,
      isNull,
    );
    await show(TreasuryWarningView.deficitWithinThreeTurns);
    final pill = tester.widget<ResourcePill>(
      find.byKey(const ValueKey('resource-gold')),
    );
    expect(pill.warning, contains('three turns'));
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    await show(TreasuryWarningView.negativeBalance);
    expect(
      tester
          .widget<ResourcePill>(find.byKey(const ValueKey('resource-gold')))
          .warning,
      contains('negative'),
    );
    await show(TreasuryWarningView.none);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
  });

  test(
    'breakdowns retain scarcity and every authoritative victory priority',
    () async {
      final l10n = await AonwLocalizations.delegate.load(const Locale('en'));
      for (final kind in VictoryStatusKindView.values) {
        final status = VictoryStatusView(
          kind: kind,
          critical: true,
          leaderPlayerId: 'player-1',
        );
        final player = resourcePlayerFixture(
          warning: TreasuryWarningView.deficitWithinThreeTurns,
          shortages: const [MapResource.oil, MapResource.aluminium],
          victory: resourceVictoryFixture(status),
        );
        final gold = resourceDetails(player, ResourcePopup.gold, l10n);
        expect(gold.first.value, contains('three turns'));
        final resources = resourceDetails(
          player,
          ResourcePopup.resources,
          l10n,
        );
        expect(
          resources.map((row) => row.value),
          containsAll(['Oil', 'Aluminium']),
        );
        final victory = resourceDetails(player, ResourcePopup.victory, l10n);
        expect(victory.first.value, isNot(contains('null')));
        expect(victory.any((row) => row.label == 'Warning'), isTrue);
      }
    },
  );

  for (final locale in AonwLocalizations.supportedLocales) {
    for (final size in [const Size(390, 844), const Size(844, 390)]) {
      testWidgets(
        'warning semantics fit ${locale.languageCode} $size at 200%',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semantics = tester.ensureSemantics();
          final l10n = await AonwLocalizations.delegate.load(locale);
          await tester.pumpWidget(
            LocalizedTestApp(
              locale: locale,
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: const TextScaler.linear(2),
                ),
                child: Scaffold(
                  body: ResourceStrip(
                    player: resourcePlayerFixture(
                      warning: TreasuryWarningView.deficitWithinThreeTurns,
                    ),
                    open: null,
                    onOpen: (_) {},
                  ),
                ),
              ),
            ),
          );
          final gold = find.byKey(const ValueKey('resource-gold'));
          await tester.ensureVisible(gold);
          await tester.pumpAndSettle();
          expect(
            find.bySemanticsLabel(
              RegExp(
                RegExp.escape(l10n.resourceText('deficitWithinThreeTurns')),
              ),
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          expect(tester.binding.hasScheduledFrame, isFalse);
          semantics.dispose();
        },
      );
    }
  }
}
