import 'dart:async';

import 'package:flutter/widgets.dart';

import 'window_settings_controller.dart';

final class WindowSettingsHost extends StatefulWidget {
  const WindowSettingsHost({
    required this.controller,
    required this.child,
    super.key,
  });

  final WindowSettingsController? controller;
  final Widget child;

  @override
  State<WindowSettingsHost> createState() => _WindowSettingsHostState();
}

final class _WindowSettingsHostState extends State<WindowSettingsHost> {
  @override
  void initState() {
    super.initState();
    _loadAfterFrame();
  }

  @override
  void didUpdateWidget(WindowSettingsHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller?.dispose();
    _loadAfterFrame();
  }

  void _loadAfterFrame() {
    final controller = widget.controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.controller != controller) return;
      unawaited(controller?.load());
    });
  }

  @override
  void dispose() {
    widget.controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      WindowSettingsScope(controller: widget.controller, child: widget.child);
}

final class WindowSettingsScope
    extends InheritedNotifier<WindowSettingsController> {
  const WindowSettingsScope({
    required WindowSettingsController? controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static WindowSettingsController? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<WindowSettingsScope>()
      ?.notifier;
}
