import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../design_system/aonw_tokens.dart';
import '../../features/map/application/map_interaction_state.dart';
import '../../features/map/read_model/map_view.dart';
import '../../features/map/read_model/player_map_view.dart';
import 'map_interaction_geometry.dart';
import 'static_map_layers.dart';

final class MapThreatOverlayLayerComponent extends Component
    with HasVisibility {
  MapThreatOverlayLayerComponent() : super(priority: 35) {
    isVisible = false;
  }

  List<_ThreatHexGeometry> _hexes = const [];
  String? _signature;
  var _dimmed = false;
  var _geometryBuildCount = 0;

  @visibleForTesting
  int get debugHexCount => _hexes.length;

  @visibleForTesting
  int get debugGeometryBuildCount => _geometryBuildCount;

  @visibleForTesting
  List<int> get debugThreatCounts =>
      List.unmodifiable(_hexes.map((value) => value.count));

  @visibleForTesting
  List<MapHexCoordinate> get debugCoordinates =>
      List.unmodifiable(_hexes.map((value) => value.coordinate));

  @visibleForTesting
  bool get debugDimmed => _dimmed;

  void applyThreats(
    MapStaticRenderCache cache,
    MapInteractionState interaction,
    PlayerMapView player,
  ) {
    final selectedId = interaction.selectedUnitId;
    final selected = selectedId == null
        ? null
        : player.controlledUnitById(selectedId);
    if (selected == null) {
      clearLayer();
      return;
    }
    final counts = <MapHexCoordinate, int>{};
    for (final unit in player.units) {
      if (unit.ownerPlayerId == player.actorPlayerId) continue;
      for (final coordinate in unit.threatenedHexes) {
        counts[coordinate] = (counts[coordinate] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) {
      clearLayer();
      return;
    }
    final dimmed = interaction.combat?.commandPending ?? false;
    final entries = counts.entries.toList()
      ..sort((left, right) {
        final leftSelected = left.key == selected.coordinate;
        final rightSelected = right.key == selected.coordinate;
        if (leftSelected != rightSelected) return leftSelected ? -1 : 1;
        final col = left.key.col.compareTo(right.key.col);
        return col == 0 ? left.key.row.compareTo(right.key.row) : col;
      });
    final signature = _threatSignature(
      cache,
      entries,
      selected.coordinate,
      dimmed,
    );
    if (_signature == signature) return;
    _signature = signature;
    _dimmed = dimmed;
    _hexes = List.unmodifiable([
      for (final entry in entries)
        _ThreatHexGeometry(
          coordinate: entry.key,
          path: mapProjectedTopFacePath(cache, entry.key, scale: 0.94),
          count: entry.value,
          selectedUnitTile: entry.key == selected.coordinate,
        ),
    ]);
    _geometryBuildCount += 1;
    isVisible = true;
  }

  void clearLayer() {
    _hexes = const [];
    _signature = null;
    _dimmed = false;
    isVisible = false;
  }

  @override
  void render(ui.Canvas canvas) {
    if (!isVisible) return;
    for (final hex in _hexes) {
      _renderHex(canvas, hex);
    }
  }

  void _renderHex(ui.Canvas canvas, _ThreatHexGeometry hex) {
    final high = hex.count >= 3;
    final color = high ? AonwColorTokens.danger : AonwColorTokens.warning;
    final fillAlpha = _visibleAlpha(high ? 90 : 60);
    final glowAlpha = _visibleAlpha(high ? 130 : 90);
    final strokeAlpha = _visibleAlpha(high ? 220 : 180);
    if (!hex.selectedUnitTile) {
      canvas.drawPath(hex.path, ui.Paint()..color = color.withAlpha(fillAlpha));
    }
    canvas
      ..drawPath(
        hex.path,
        ui.Paint()
          ..color = color.withAlpha(glowAlpha)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = hex.selectedUnitTile ? 5 : (high ? 2.8 : 2)
          ..strokeJoin = ui.StrokeJoin.round,
      )
      ..drawPath(
        hex.path,
        ui.Paint()
          ..color = color.withAlpha(strokeAlpha)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = hex.selectedUnitTile ? 2.8 : (high ? 2 : 1.5)
          ..strokeCap = ui.StrokeCap.round
          ..strokeJoin = ui.StrokeJoin.round,
      );
  }

  int _visibleAlpha(int alpha) => _dimmed ? math.min(alpha, 60) : alpha;
}

final class _ThreatHexGeometry {
  const _ThreatHexGeometry({
    required this.coordinate,
    required this.path,
    required this.count,
    required this.selectedUnitTile,
  });

  final MapHexCoordinate coordinate;
  final ui.Path path;
  final int count;
  final bool selectedUnitTile;
}

String _threatSignature(
  MapStaticRenderCache cache,
  List<MapEntry<MapHexCoordinate, int>> entries,
  MapHexCoordinate selected,
  bool dimmed,
) {
  final buffer = StringBuffer()
    ..write(identityHashCode(cache))
    ..write('|')
    ..write(selected.col)
    ..write(',')
    ..write(selected.row)
    ..write('|')
    ..write(dimmed);
  for (final entry in entries) {
    buffer
      ..write('|')
      ..write(entry.key.col)
      ..write(',')
      ..write(entry.key.row)
      ..write(':')
      ..write(entry.value);
  }
  return buffer.toString();
}
