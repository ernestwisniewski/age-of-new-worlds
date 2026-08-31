import '../../read_model/map_view.dart';

enum MapInputCommand {
  cursorUp,
  cursorDown,
  cursorLeft,
  cursorRight,
  activate,
  cancel,
  toggleReference,
}

abstract interface class MapInputSource {
  Stream<MapInputCommand> get commands;

  Future<void> close();
}

abstract interface class LifecycleAwareMapInputSource {
  void setActive(bool active);
}

abstract final class MapInputCursor {
  static MapHexCoordinate initial(MapView map) =>
      (col: map.cols ~/ 2, row: map.rows ~/ 2);

  static MapHexCoordinate move(
    MapView map,
    MapHexCoordinate current,
    MapInputCommand command,
  ) {
    final candidate = switch (command) {
      MapInputCommand.cursorUp => (col: current.col, row: current.row - 1),
      MapInputCommand.cursorDown => (col: current.col, row: current.row + 1),
      MapInputCommand.cursorLeft => (col: current.col - 1, row: current.row),
      MapInputCommand.cursorRight => (col: current.col + 1, row: current.row),
      _ => current,
    };
    return map.contains(candidate) ? candidate : current;
  }
}
