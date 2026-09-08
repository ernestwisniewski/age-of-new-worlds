import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../design_system/widgets/aonw_menu_adjustable.dart';
import 'map_gamepad_input.dart';
import 'map_input.dart';

part 'map_gamepad_focus_navigation.dart';

enum MapHudSection {
  globalActions,
  menu,
  topResources,
  rightPlayers,
  selectionActions,
}

enum MapGamepadPriority { hud, panel, popup }

final class MapGamepadRegionEntry {
  const MapGamepadRegionEntry({
    required this.scope,
    required this.section,
    required this.priority,
    required this.onCancel,
    this.bottomCommand = false,
    this.scrollBeforeFocus = false,
    this.onScroll,
  });

  final bool Function(MapInputCommand)? onScroll;
  final bool bottomCommand;
  final bool scrollBeforeFocus;
  final FocusScopeNode scope;
  final MapHudSection section;
  final MapGamepadPriority priority;
  final VoidCallback? onCancel;
}

final class MapGamepadNavigation extends ChangeNotifier {
  MapGamepadNavigation({
    required this.onOwnerChanged,
    required this.returnToMap,
  });

  final VoidCallback onOwnerChanged;
  final VoidCallback returnToMap;
  final _entries = <Object, MapGamepadRegionEntry>{};
  var _active = false;
  var _available = true;
  var _disposed = false;
  var _repairScheduled = false;
  var _restoreMapFocus = false;
  MapHudSection _section = MapHudSection.menu;
  Object? _owner;
  FocusNode? _highlighted;
  RenderBox? _highlightedBox;

  RenderBox? get highlightedBox => _highlightedBox;

  FocusNode? get highlighted => _highlighted;
  bool get capturesInput => _capture != null || _active;

  MapEntry<Object, MapGamepadRegionEntry>? get _capture {
    if (!_available) return null;
    MapEntry<Object, MapGamepadRegionEntry>? result;
    for (final entry in _entries.entries.toList().reversed) {
      if (entry.value.priority.index >
          (result?.value.priority.index ?? MapGamepadPriority.hud.index)) {
        result = entry;
      }
    }
    return result;
  }

  void register(Object key, MapGamepadRegionEntry entry) {
    if (_disposed) return;
    _entries[key] = entry;
    _synchronizeOwner();
    _scheduleRepair();
  }

  void unregister(Object key) {
    if (_disposed) return;
    _entries.remove(key);
    _synchronizeOwner();
    _scheduleRepair();
  }

  void _synchronizeOwner({bool force = false}) {
    final next = _capture?.key ?? (_active ? this : null);
    if (!force && identical(next, _owner)) return;
    _restoreMapFocus =
        _available &&
        _owner != null &&
        !identical(_owner, this) &&
        next == null;
    _owner = next;
    onOwnerChanged();
  }

  bool handleFrame(MapGamepadFrame frame) {
    if (_disposed || !_available) return false;
    final capture = _capture;
    if (capture != null) {
      _handleCapturedFrame(capture.value, frame);
      return true;
    }
    if (_handleSectionFrame(frame)) return true;
    if (!_active) return false;
    if (frame.cancelPressed) {
      deactivate();
      return true;
    }
    _repairFocus();
    if (frame.cursorStep case final direction?) _moveInHud(direction);
    if (frame.activatePressed) _activate();
    return true;
  }

  bool handleCommand(MapInputCommand command) => handleFrame(switch (command) {
    MapInputCommand.activate => const MapGamepadFrame(activatePressed: true),
    MapInputCommand.cancel => const MapGamepadFrame(cancelPressed: true),
    MapInputCommand.toggleMoveTargeting => const MapGamepadFrame(
      toggleMoveTargetingPressed: true,
    ),
    MapInputCommand.inspectHex => const MapGamepadFrame(
      inspectHexPressed: true,
    ),
    MapInputCommand.toggleMapViewMode => MapGamepadFrame.idle,
    _ => MapGamepadFrame(cursorStep: command),
  });

  bool _handleSectionFrame(MapGamepadFrame frame) {
    final next =
        frame.hudFocusNextPressed || (_active && frame.focusNextPressed);
    final previous =
        frame.hudFocusPreviousPressed ||
        (_active && frame.focusPreviousPressed);
    if (!next && !previous) return false;
    if (!_active) {
      _active = true;
      _focusFirst(
        next
            ? [MapHudSection.selectionActions, MapHudSection.menu]
            : [MapHudSection.menu],
      );
    } else {
      _stepSection(next ? 1 : -1);
    }
    _synchronizeOwner();
    return true;
  }

  void _handleCapturedFrame(
    MapGamepadRegionEntry entry,
    MapGamepadFrame frame,
  ) {
    if (frame.cancelPressed) {
      entry.onCancel?.call();
      return;
    }
    final nodes = _nodes(entry);
    final focused = _ensureFocused(nodes);
    if (frame.cursorStep case final direction?) {
      _moveInCapturedRegion(entry, nodes, direction);
    }
    if (focused && frame.activatePressed) _activate();
  }

  void _moveInCapturedRegion(
    MapGamepadRegionEntry entry,
    List<FocusNode> nodes,
    MapInputCommand direction,
  ) {
    if (entry.scrollBeforeFocus && entry.onScroll?.call(direction) == true) {
      return;
    }
    if (!_moveInPanel(nodes, direction)) entry.onScroll?.call(direction);
  }

  void setAvailable(bool available) {
    if (_disposed || _available == available) return;
    _available = available;
    if (!available) {
      _active = false;
      _highlighted = null;
      _highlightedBox = null;
    }
    _synchronizeOwner(force: true);
    _scheduleRepair();
  }

  void deactivate({bool restoreMap = true}) {
    if (_disposed) return;
    _active = false;
    _highlighted = null;
    _highlightedBox = null;
    _synchronizeOwner();
    notifyListeners();
    if (restoreMap) returnToMap();
  }

  void _scheduleRepair() {
    if (_repairScheduled) return;
    _repairScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repairScheduled = false;
      if (_disposed) return;
      _repairFocus();
      if (_restoreMapFocus) {
        _restoreMapFocus = false;
        returnToMap();
      }
      notifyListeners();
    });
  }

  void _repairFocus() {
    final capture = _capture;
    if (capture != null) {
      _ensureFocused(_nodes(capture.value));
    } else if (_active) {
      if (!_ensureFocused([
        ..._sectionNodes(_section),
        ..._sectionNodes(_section, bottomCommand: true),
      ])) {
        _focusFirst([_section]);
      }
    } else if (_highlighted != null) {
      _highlighted = null;
      _highlightedBox = null;
      notifyListeners();
    }
  }

  bool _ensureFocused(List<FocusNode> nodes) {
    if (nodes.isEmpty) {
      _highlighted = null;
      _highlightedBox = null;
      notifyListeners();
      return false;
    }
    final primary = FocusManager.instance.primaryFocus;
    if (nodes.contains(primary)) {
      _setHighlighted(primary!);
    } else {
      _focus(nodes.contains(_highlighted) ? _highlighted! : nodes.first);
    }
    return true;
  }

  void _activate() {
    final node = _highlighted;
    final context = node?.context;
    if (context == null || !node!.canRequestFocus) return;
    Actions.maybeInvoke(context, const ActivateIntent());
  }

  void _focus(FocusNode node) {
    node.requestFocus();
    _setHighlighted(node);
    final context = node.context;
    if (context != null) unawaited(Scrollable.ensureVisible(context));
  }

  void _setHighlighted(FocusNode node) {
    final renderObject = node.context?.findRenderObject();
    _highlightedBox = renderObject is RenderBox ? renderObject : null;
    if (identical(_highlighted, node)) return;
    _highlighted = node;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _entries.clear();
    super.dispose();
  }
}
