part of 'map_gamepad_navigation.dart';

extension MapGamepadFocusNavigation on MapGamepadNavigation {
  List<FocusNode> _nodes(MapGamepadRegionEntry entry) => [
    for (final node in entry.scope.traversalDescendants)
      if (node is! FocusScopeNode &&
          node.context != null &&
          node.rect.width > 0 &&
          node.rect.height > 0 &&
          _belongsToRegion(node, entry))
        node,
  ];

  bool _belongsToRegion(FocusNode node, MapGamepadRegionEntry entry) {
    final scopes = {for (final value in _entries.values) value.scope};
    for (final ancestor in node.ancestors) {
      if (scopes.contains(ancestor)) return identical(ancestor, entry.scope);
    }
    return false;
  }

  List<FocusNode> _sectionNodes(
    MapHudSection section, {
    bool bottomCommand = false,
  }) {
    final nodes = <FocusNode>[
      for (final entry in _entries.values)
        if (entry.priority == MapGamepadPriority.hud &&
            entry.section == section &&
            entry.bottomCommand == bottomCommand)
          ..._nodes(entry),
    ];
    nodes.sort((left, right) {
      final vertical = left.rect.top.compareTo(right.rect.top);
      return vertical == 0
          ? left.rect.left.compareTo(right.rect.left)
          : vertical;
    });
    return nodes;
  }

  bool _focusFirst(List<MapHudSection> preferred, {bool fallback = true}) {
    final sections = {...preferred, if (fallback) ...MapHudSection.values};
    for (final section in sections) {
      var nodes = _sectionNodes(section);
      if (nodes.isEmpty) nodes = _sectionNodes(section, bottomCommand: true);
      if (nodes.isEmpty) continue;
      _section = section;
      _focus(nodes.first);
      return true;
    }
    return false;
  }

  void _stepSection(int step) {
    final sections = MapHudSection.values;
    for (var offset = 1; offset <= sections.length; offset++) {
      final section =
          sections[(_section.index + offset * step) % sections.length];
      if (_focusFirst([section], fallback: false)) return;
    }
  }

  bool _moveBounded(List<FocusNode> nodes, int step) {
    if (_highlighted == null) return false;
    final index = nodes.indexOf(_highlighted!);
    final next = index + step;
    if (index < 0 || next < 0 || next >= nodes.length) return false;
    _focus(nodes[next]);
    return true;
  }

  bool _moveInPanel(List<FocusNode> nodes, MapInputCommand direction) {
    if (_adjustInPanel(direction)) return true;
    if (nodes.isEmpty) return false;
    final step = switch (direction) {
      MapInputCommand.cursorUp || MapInputCommand.cursorLeft => -1,
      _ => 1,
    };
    return _moveBounded(nodes, step);
  }

  bool _adjustInPanel(MapInputCommand direction) {
    final context = _highlighted?.context;
    final adjustment = switch (direction) {
      MapInputCommand.cursorLeft => -1,
      MapInputCommand.cursorRight => 1,
      _ => 0,
    };
    if (context != null &&
        adjustment != 0 &&
        Actions.maybeInvoke(context, AonwMenuAdjustIntent(adjustment)) ==
            true) {
      return true;
    }
    return false;
  }

  void _moveInHud(MapInputCommand direction) {
    if (_moveBottomCommand(direction)) return;
    final nodes = _sectionNodes(_section);
    if (nodes.isEmpty || _highlighted == null) return;
    final step = _sectionStep(direction);
    if (step != 0 && _moveBounded(nodes, step)) return;
    _focusFirst(_neighborSections(_section, direction), fallback: false);
  }

  int _sectionStep(MapInputCommand direction) {
    final vertical = const {
      MapHudSection.globalActions,
      MapHudSection.rightPlayers,
    }.contains(_section);
    if (vertical) {
      return switch (direction) {
        MapInputCommand.cursorUp => -1,
        MapInputCommand.cursorDown => 1,
        _ => 0,
      };
    }
    if (_section == MapHudSection.menu) return 0;
    return switch (direction) {
      MapInputCommand.cursorLeft => -1,
      MapInputCommand.cursorRight => 1,
      _ => 0,
    };
  }

  bool _moveBottomCommand(MapInputCommand direction) {
    if (_section != MapHudSection.selectionActions) return false;
    final bottom = _sectionNodes(_section, bottomCommand: true);
    if (bottom.contains(_highlighted)) {
      if (direction == MapInputCommand.cursorUp) {
        _focusFirst([
          _section,
          MapHudSection.rightPlayers,
          MapHudSection.topResources,
          MapHudSection.menu,
        ]);
      }
      return true;
    }
    if (direction != MapInputCommand.cursorDown || bottom.isEmpty) return false;
    _focus(bottom.first);
    return true;
  }
}

List<MapHudSection> _neighborSections(
  MapHudSection section,
  MapInputCommand direction,
) => _hudNeighbors[section]?[direction] ?? const [];

const _hudNeighbors = {
  MapHudSection.globalActions: {
    MapInputCommand.cursorUp: [MapHudSection.menu],
    MapInputCommand.cursorRight: [MapHudSection.menu],
    MapInputCommand.cursorDown: [
      MapHudSection.selectionActions,
      MapHudSection.topResources,
    ],
  },
  MapHudSection.menu: {
    MapInputCommand.cursorRight: [
      MapHudSection.topResources,
      MapHudSection.rightPlayers,
      MapHudSection.selectionActions,
    ],
    MapInputCommand.cursorDown: [
      MapHudSection.globalActions,
      MapHudSection.selectionActions,
    ],
    MapInputCommand.cursorLeft: [
      MapHudSection.globalActions,
      MapHudSection.selectionActions,
    ],
  },
  MapHudSection.topResources: {
    MapInputCommand.cursorLeft: [MapHudSection.menu],
    MapInputCommand.cursorUp: [MapHudSection.menu],
    MapInputCommand.cursorRight: [
      MapHudSection.rightPlayers,
      MapHudSection.selectionActions,
    ],
    MapInputCommand.cursorDown: [
      MapHudSection.rightPlayers,
      MapHudSection.selectionActions,
    ],
  },
  MapHudSection.rightPlayers: {
    MapInputCommand.cursorUp: [MapHudSection.topResources, MapHudSection.menu],
    MapInputCommand.cursorLeft: [
      MapHudSection.topResources,
      MapHudSection.menu,
    ],
    MapInputCommand.cursorDown: [
      MapHudSection.selectionActions,
      MapHudSection.globalActions,
    ],
  },
  MapHudSection.selectionActions: {
    MapInputCommand.cursorLeft: [
      MapHudSection.globalActions,
      MapHudSection.menu,
    ],
    MapInputCommand.cursorUp: [
      MapHudSection.rightPlayers,
      MapHudSection.topResources,
      MapHudSection.menu,
    ],
  },
};
