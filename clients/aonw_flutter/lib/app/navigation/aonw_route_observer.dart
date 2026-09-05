import 'package:flutter/material.dart';

import '../../features/audio/presentation/game_audio_actions.dart';

final class AonwRouteObserver extends RouteObserver<ModalRoute<void>> {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is PageRoute && previousRoute != null) {
      navigator?.context.playGameSound(GameSoundCue.menuBack);
    }
  }
}
