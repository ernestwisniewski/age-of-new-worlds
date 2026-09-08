import 'package:flutter/widgets.dart';

Locale resolveAonwLocale(List<Locale>? preferred, Iterable<Locale> supported) {
  for (final preference in preferred ?? const <Locale>[]) {
    for (final locale in supported) {
      if (preference.languageCode == locale.languageCode) return locale;
    }
  }
  return supported.firstWhere(
    (locale) => locale.languageCode == 'en',
    orElse: () => supported.isEmpty ? const Locale('en') : supported.first,
  );
}
