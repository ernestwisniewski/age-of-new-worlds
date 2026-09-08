import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../settings/presentation/client_performance_host.dart';
import '../../../settings/presentation/client_settings_scope.dart';
import '../../../settings/presentation/map_zoom_indicator.dart';

final class MapZoomReporter extends StatefulWidget {
  const MapZoomReporter({required this.zoom, required this.child, super.key});

  final ValueListenable<double?> zoom;
  final Widget child;

  @override
  State<MapZoomReporter> createState() => _MapZoomReporterState();
}

final class _MapZoomReporterState extends State<MapZoomReporter> {
  MapZoomIndicator? _indicator;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _synchronize();
  }

  @override
  void didUpdateWidget(MapZoomReporter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _synchronize();
  }

  void _synchronize() {
    final indicator = MapZoomScope.maybeOf(context);
    if (!identical(_indicator, indicator)) _indicator?.detach(this);
    _indicator = indicator;
    final enabled = ClientSettingsScope.settingsOf(
      context,
    ).performance.showMapZoom;
    final visible = ModalRoute.of(context)?.isCurrent ?? true;
    if (enabled && visible) {
      indicator?.attach(this, widget.zoom);
    } else {
      indicator?.detach(this);
    }
  }

  @override
  void dispose() {
    _indicator?.detach(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
