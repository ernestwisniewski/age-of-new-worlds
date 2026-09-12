import 'package:aonw_flutter/features/local_game/presentation/local_game_launch_mode.dart';
import 'package:aonw_flutter/features/local_game/presentation/new_game_screen.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> loadLocalGameFonts() async {
  for (final font in [
    ('Cinzel', 'assets/fonts/Cinzel-VariableFont_wght.ttf'),
    ('Lato', 'assets/fonts/Lato-Regular.ttf'),
    ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
  ]) {
    await (FontLoader(font.$1)..addFont(rootBundle.load(font.$2))).load();
  }
}

Widget newGameTestRoute(
  MapPresentationController controller,
  LocalGameLaunchModeView mode,
) => Navigator(
  initialRoute: '/setup',
  onGenerateRoute: (settings) => MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => settings.name == '/setup'
        ? NewGameScreen(
            mapController: controller,
            initialMode: mode,
            onStarted: () {},
          )
        : const SizedBox.shrink(),
  ),
);
