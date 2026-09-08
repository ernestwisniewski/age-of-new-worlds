import 'package:aonw_flutter/features/settings/presentation/map_zoom_indicator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'new viewport ownership survives old updates and delayed removal',
    () async {
      final indicator = MapZoomIndicator();
      final first = ValueNotifier<double?>(1);
      final second = ValueNotifier<double?>(2);
      final firstOwner = Object();
      final secondOwner = Object();
      var notifications = 0;
      indicator.addListener(() => notifications++);
      indicator.attach(firstOwner, first);
      indicator.attach(secondOwner, second);
      first.value = 4;
      indicator.detach(firstOwner);
      expect(indicator.value, 2);
      second.value = 3;
      await Future<void>.delayed(Duration.zero);
      expect(indicator.value, 3);
      expect(notifications, 1);
      indicator.detach(secondOwner);
      await Future<void>.delayed(Duration.zero);
      expect(indicator.value, isNull);
      expect(notifications, 2);
      indicator.attach(firstOwner, first);
      indicator.dispose();
      first.value = 5;
      await Future<void>.delayed(Duration.zero);
      expect(notifications, 2);
      first.dispose();
      second.dispose();
    },
  );
}
