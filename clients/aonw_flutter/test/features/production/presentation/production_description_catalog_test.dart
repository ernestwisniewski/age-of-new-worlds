import 'dart:convert';

import 'package:aonw_flutter/l10n/generated/aonw_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'all 87 illustrated production targets have six authored descriptions',
    () async {
      final manifest =
          jsonDecode(
                await rootBundle.loadString(
                  'assets/runtime/sprites/sprite_manifest.json',
                ),
              )
              as Map<String, dynamic>;
      final frames = (manifest['frames'] as Map<String, dynamic>).keys;
      for (final locale in AonwLocalizations.supportedLocales) {
        final l10n = lookupAonwLocalizations(locale);
        var targets = 0;
        for (final frame in frames) {
          final parts = frame.split('.');
          final text = switch (parts.first) {
            'building' => l10n.productionBuildingDescription(parts[1]),
            'wonder' => l10n.productionWonderDescription(parts[1]),
            'unit' when frame.endsWith('.idle.0') =>
              l10n.productionUnitDescription(parts[1]),
            _ => null,
          };
          if (text == null) continue;
          expect(text.trim(), isNotEmpty, reason: '$locale $frame');
          targets++;
        }
        expect(targets, 87);
      }
    },
  );
}
