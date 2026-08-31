import 'package:aonw_flutter/l10n/l10n.dart';
import 'package:flutter/material.dart';

final class LocalizedTestApp extends StatelessWidget {
  const LocalizedTestApp({
    required this.home,
    this.locale = const Locale('en'),
    this.theme,
    this.navigatorObservers = const [],
    super.key,
  });

  final Widget home;
  final Locale locale;
  final ThemeData? theme;
  final List<NavigatorObserver> navigatorObservers;

  @override
  Widget build(BuildContext context) => MaterialApp(
    locale: locale,
    localizationsDelegates: AonwLocalizations.localizationsDelegates,
    supportedLocales: AonwLocalizations.supportedLocales,
    theme: theme,
    navigatorObservers: navigatorObservers,
    home: home,
  );
}
