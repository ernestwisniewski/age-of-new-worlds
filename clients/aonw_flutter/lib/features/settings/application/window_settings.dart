enum WindowMode { fullscreen, windowed }

enum WindowSettingsFailure { load, apply, save, restore }

final class WindowSettings {
  const WindowSettings({
    this.mode = WindowMode.fullscreen,
    this.isBusy = false,
    this.failure,
  });

  final WindowMode mode;
  final bool isBusy;
  final WindowSettingsFailure? failure;
}

abstract interface class WindowSettingsStore {
  Future<WindowMode> load();

  Future<void> save(WindowMode mode);
}

abstract interface class GameWindowPort {
  bool get isSupported;

  Future<WindowMode> readMode();

  /// Completes once the requested native window transition has finished.
  Future<void> setMode(WindowMode mode);
}
