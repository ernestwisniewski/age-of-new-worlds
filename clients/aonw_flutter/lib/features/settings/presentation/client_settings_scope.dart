import 'package:flutter/widgets.dart';

import '../application/client_settings.dart';
import 'client_settings_controller.dart';

final class ClientSettingsScope
    extends InheritedNotifier<ClientSettingsController> {
  const ClientSettingsScope({
    required ClientSettingsController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static ClientSettings settingsOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ClientSettingsScope>()
          ?.notifier
          ?.settings ??
      ClientSettings.defaults;
}
