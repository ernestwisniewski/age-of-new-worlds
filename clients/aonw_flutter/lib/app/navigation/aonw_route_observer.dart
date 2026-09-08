import 'package:flutter/material.dart';

import '../../features/audio/presentation/game_audio_actions.dart';
import 'aonw_menu_popup_routes.dart';

final class AonwRouteObserver extends RouteObserver<ModalRoute<void>> {
  final menuPopups = AonwMenuPopupRoutes();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    menuPopups.pushed(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    menuPopups.removed(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    menuPopups.replaced(oldRoute, newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    menuPopups.removed(route);
    if (route is PageRoute && previousRoute != null) {
      navigator?.context.playGameSound(GameSoundCue.menuBack);
    }
  }
}
