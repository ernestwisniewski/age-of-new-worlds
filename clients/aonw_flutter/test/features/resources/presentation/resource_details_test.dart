import 'package:aonw_flutter/features/resources/presentation/resource_details.dart';
import 'package:aonw_flutter/features/resources/presentation/resource_strip.dart';
import 'package:aonw_flutter/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'resource_test_fixture.dart';

void main() {
  test(
    'breakdowns preserve authoritative totals without deriving gameplay',
    () async {
      final l10n = await AonwLocalizations.delegate.load(const Locale('en'));
      final player = resourcePlayerFixture();
      final gold = resourceDetails(player, ResourcePopup.gold, l10n);
      expect(gold, contains((label: 'Treasury', value: '123')));
      expect(gold, contains((label: 'Income', value: '999')));
      expect(gold, contains((label: 'Unit upkeep', value: '-32')));
      expect(gold, contains((label: 'Per turn', value: '-77')));
      final science = resourceDetails(player, ResourcePopup.science, l10n);
      expect(science, contains((label: 'Science', value: '+11')));
      expect(science, contains((label: 'Stored science', value: '19')));
      expect(
        science,
        contains((label: 'Active research', value: 'Agriculture')),
      );
      expect(science, contains((label: 'Progress', value: '7 / 31')));
    },
  );

  test('every breakdown is localized in all supported languages', () async {
    for (final locale in AonwLocalizations.supportedLocales) {
      final l10n = await AonwLocalizations.delegate.load(locale);
      for (final kind in ResourcePopup.values) {
        final rows = resourceDetails(resourcePlayerFixture(), kind, l10n);
        expect(l10n.resourceText(kind.name), isNotEmpty);
        expect(rows.every((row) => row.label.isNotEmpty), isTrue);
        expect(rows.any((row) => row.value.contains('null')), isFalse);
      }
    }
  });
}
