import 'package:aonw_flutter/features/settings/application/client_language.dart';
import 'package:aonw_flutter/l10n/aonw_locale_resolution.dart';
import 'package:aonw_flutter/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'uses the first supported language from the complete preference list',
    () {
      final supported = AonwLocalizations.supportedLocales;
      expect(
        resolveAonwLocale([
          const Locale('ja'),
          const Locale('pl', 'PL'),
          const Locale('en', 'US'),
        ], supported),
        const Locale('pl'),
      );
      expect(
        resolveAonwLocale([
          const Locale('en', 'GB'),
          const Locale('pl'),
        ], supported),
        const Locale('en'),
      );
    },
  );

  test('defaults to English when no preferred language is supported', () {
    for (final preferred in [
      null,
      <Locale>[],
      [const Locale('ja')],
    ]) {
      expect(
        resolveAonwLocale(preferred, const [Locale('pl'), Locale('en')]),
        const Locale('en'),
      );
    }
  });

  test('every selectable language has a generated localization', () {
    final supported = AonwLocalizations.supportedLocales.map(
      (l) => l.languageCode,
    );
    final selectable = ClientLanguage.values
        .map((language) => language.languageCode)
        .whereType<String>();
    expect(selectable.toSet(), supported.toSet());
  });
}
