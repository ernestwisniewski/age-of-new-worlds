import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final template = _catalog('en');
  for (final locale in AonwLocalizations.supportedLocales) {
    test('${locale.languageCode} retains message arguments and ICU cases', () {
      final catalog = _catalog(locale.languageCode);
      for (final entry in template.entries) {
        if (entry.key.startsWith('@')) continue;
        final reference = _MessageContract(entry.value as String);
        final localized = _MessageContract(catalog[entry.key] as String);
        expect(localized.arguments, reference.arguments, reason: entry.key);
        for (final selector in reference.selectors.entries) {
          expect(
            localized.selectors[selector.key],
            containsAll(selector.value),
            reason: '${entry.key}: ${selector.key}',
          );
        }
      }
    });
  }

  test('French plural messages preserve zero, one and larger counts', () {
    final french = lookupAonwLocalizations(
      AonwLocalizations.supportedLocales.singleWhere(
        (l) => l.languageCode == 'fr',
      ),
    );
    expect(french.moveTurnCost(0), '0 tour');
    expect(french.moveTurnCost(1), '1 tour');
    expect(french.moveTurnCost(2), '2 tours');
    expect(french.hexInspectionBuildTurns(1), 'Durée de construction : 1 tour');
    expect(
      french.hexInspectionBuildTurns(3),
      'Durée de construction : 3 tours',
    );
    expect(
      french.artifactExcavationAt(2, 4, 1),
      'Fouilles en 2, 4 · 1 tour restant',
    );
    expect(
      french.artifactExcavationAt(2, 4, 3),
      'Fouilles en 2, 4 · 3 tours restants',
    );
  });
}

Map<String, Object?> _catalog(String language) =>
    jsonDecode(File('lib/l10n/app_$language.arb').readAsStringSync())
        as Map<String, Object?>;

final class _MessageContract {
  _MessageContract(String message) {
    _scan(message, '');
  }

  final arguments = <String>{};
  final selectors = <String, Set<String>>{};
  static final _selector = RegExp(r'^(\w+),\s*(select|plural),\s*');
  static final _argument = RegExp(r'^\w+$');
  static final _case = RegExp(r'\s*([=\w]+)\s*\{');

  void _scan(String message, String path) {
    var start = message.indexOf('{');
    while (start >= 0) {
      final end = _blockEnd(message, start);
      final body = message.substring(start + 1, end);
      final selector = _selector.firstMatch(body);
      if (selector == null) {
        if (!_argument.hasMatch(body)) {
          throw FormatException('Unknown ICU argument: $body');
        }
        arguments.add(body);
      } else {
        final name = selector.group(1)!;
        arguments.add(name);
        _cases(
          body.substring(selector.end),
          '$path/$name:${selector.group(2)}',
        );
      }
      start = message.indexOf('{', end + 1);
    }
  }

  void _cases(String body, String path) {
    final cases = selectors.putIfAbsent(path, () => <String>{});
    var offset = 0;
    while (offset < body.length && body.substring(offset).trim().isNotEmpty) {
      final match = _case.matchAsPrefix(body, offset);
      if (match == null) throw FormatException('Invalid ICU case: $body');
      final key = match.group(1)!;
      final start = match.end - 1;
      final end = _blockEnd(body, start);
      cases.add(key);
      _scan(body.substring(start + 1, end), '$path/$key');
      offset = end + 1;
    }
  }

  int _blockEnd(String text, int start) {
    var depth = 0;
    for (var i = start; i < text.length; i++) {
      if (text[i] == '{') depth += 1;
      if (text[i] == '}' && --depth == 0) return i;
    }
    throw FormatException('Unclosed ICU block: $text');
  }
}
