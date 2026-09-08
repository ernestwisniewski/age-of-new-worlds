import 'package:aonw_flutter/app/navigation/aonw_menu_popup_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only the page beneath the popup stack owns input', () {
    final routes = AonwMenuPopupRoutes();
    addTearDown(routes.dispose);
    final menu = _page();
    final settings = _page();
    final popup = _popup();
    final nested = _popup();
    routes.pushed(menu);
    routes.pushed(settings);
    routes.pushed(popup);
    expect(routes.popupFor(menu), isNull);
    expect(routes.popupFor(settings), same(popup));
    routes.pushed(nested);
    expect(routes.popupFor(settings), same(nested));
    routes.removed(nested);
    expect(routes.popupFor(settings), same(popup));
    routes.removed(popup);
    expect(routes.popupFor(settings), isNull);
  });

  test('replacement and removal do not leave a stale popup owner', () {
    final routes = AonwMenuPopupRoutes();
    addTearDown(routes.dispose);
    final first = _page();
    final second = _page();
    final popup = _popup();
    routes.pushed(first);
    routes.pushed(popup);
    routes.replaced(first, second);
    expect(routes.popupFor(first), isNull);
    expect(routes.popupFor(second), same(popup));
    routes.removed(second);
    expect(routes.popupFor(second), isNull);
    routes.removed(popup);
    expect(routes.popupFor(null), isNull);
  });
}

Route<void> _page() => MaterialPageRoute(builder: (_) => const SizedBox());
Route<void> _popup() =>
    RawDialogRoute(pageBuilder: (_, _, _) => const SizedBox());
