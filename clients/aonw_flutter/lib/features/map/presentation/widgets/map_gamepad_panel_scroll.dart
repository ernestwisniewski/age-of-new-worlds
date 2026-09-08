part of 'map_gamepad_region.dart';

extension _MapGamepadPanelScroll on _MapGamepadRegionState {
  bool _scrollPanel(MapInputCommand direction) {
    final movement = switch (direction) {
      MapInputCommand.cursorUp => (Axis.vertical, -1),
      MapInputCommand.cursorDown => (Axis.vertical, 1),
      MapInputCommand.cursorLeft => (Axis.horizontal, -1),
      MapInputCommand.cursorRight => (Axis.horizontal, 1),
      _ => null,
    };
    if (movement == null || !mounted) return false;
    final scrollables = <ScrollableState>[];
    void visit(Element element) {
      if (element case StatefulElement(state: final ScrollableState state)) {
        scrollables.add(state);
      }
      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
    for (final scrollable in scrollables) {
      if (_scrollPosition(scrollable.position, movement.$1, movement.$2)) {
        return true;
      }
    }
    return false;
  }
}

bool _scrollPosition(ScrollPosition position, Axis axis, int step) {
  if (position.axis != axis || !position.hasContentDimensions) return false;
  final target = (position.pixels + step * position.viewportDimension * .7)
      .clamp(position.minScrollExtent, position.maxScrollExtent);
  if (target == position.pixels) return false;
  position.jumpTo(target);
  return true;
}
