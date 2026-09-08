import 'package:flutter/widgets.dart';

/// Attributes a popup stack to the page immediately beneath it.
final class AonwMenuPopupRoutes extends ChangeNotifier {
  final _routes = <Route<dynamic>>[];

  Route<dynamic>? popupFor(Route<dynamic>? page) {
    if (_routes.isEmpty || _routes.last is! PopupRoute) return null;
    for (final route in _routes.reversed) {
      if (route is PopupRoute) continue;
      return identical(route, page) ? _routes.last : null;
    }
    return null;
  }

  void pushed(Route<dynamic> route) {
    _routes.add(route);
    notifyListeners();
  }

  void removed(Route<dynamic> route) {
    _routes.remove(route);
    notifyListeners();
  }

  void replaced(Route<dynamic>? previous, Route<dynamic>? next) {
    if (previous == null) return;
    final index = _routes.indexOf(previous);
    if (index < 0) return;
    if (next == null) {
      _routes.removeAt(index);
    } else {
      _routes[index] = next;
    }
    notifyListeners();
  }
}
