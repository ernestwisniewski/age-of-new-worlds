import 'package:flutter/widgets.dart';

import '../application/client_performance_settings.dart';
import 'map_zoom_indicator.dart';
import 'performance_counter.dart';

final class ClientPerformanceHost extends StatefulWidget {
  const ClientPerformanceHost({
    required this.settings,
    required this.child,
    super.key,
  });

  final ClientPerformanceSettings settings;
  final Widget child;

  @override
  State<ClientPerformanceHost> createState() => _ClientPerformanceHostState();
}

final class _ClientPerformanceHostState extends State<ClientPerformanceHost> {
  final _zoom = MapZoomIndicator();

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MapZoomScope(
    indicator: _zoom,
    child: Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (widget.settings.showFps || widget.settings.showMapZoom)
          Positioned.fill(
            child: IgnorePointer(
              child: SafeArea(
                minimum: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: ValueListenableBuilder<double?>(
                    valueListenable: _zoom,
                    builder: (context, zoom, child) => PerformanceCounter(
                      showFps: widget.settings.showFps,
                      zoom: widget.settings.showMapZoom ? zoom : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

final class MapZoomScope extends InheritedWidget {
  const MapZoomScope({
    required this.indicator,
    required super.child,
    super.key,
  });

  final MapZoomIndicator indicator;

  static MapZoomIndicator? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MapZoomScope>()?.indicator;

  @override
  bool updateShouldNotify(MapZoomScope oldWidget) =>
      !identical(indicator, oldWidget.indicator);
}
