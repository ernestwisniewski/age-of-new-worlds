final class ClientPerformanceSettings {
  const ClientPerformanceSettings({
    this.showFps = false,
    this.showMapZoom = false,
  });

  final bool showFps;
  final bool showMapZoom;

  ClientPerformanceSettings copyWith({bool? showFps, bool? showMapZoom}) =>
      ClientPerformanceSettings(
        showFps: showFps ?? this.showFps,
        showMapZoom: showMapZoom ?? this.showMapZoom,
      );

  @override
  bool operator ==(Object other) =>
      other is ClientPerformanceSettings &&
      other.showFps == showFps &&
      other.showMapZoom == showMapZoom;

  @override
  int get hashCode => Object.hash(showFps, showMapZoom);
}
