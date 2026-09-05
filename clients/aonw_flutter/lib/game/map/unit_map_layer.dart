import 'dart:async';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../../design_system/assets/sprite_frame_repository.dart';
import '../../design_system/assets/sprite_frames.dart';
import '../../features/artifacts/read_model/artifact_view.dart';
import '../../features/map/presentation/map_palette.dart';
import '../../features/map/read_model/map_view.dart';
import '../../features/map/read_model/pending_action_view.dart';
import '../../features/map/read_model/player_map_view.dart';
import '../presentation/flame_scene_patch.dart';
import 'map_sprite_catalog.dart';
import 'map_sprite_painter.dart';
import 'map_sprite_shadow.dart';
import 'static_map_layers.dart';
import 'unit_marker_details.dart';

enum _CityUnitPlacement { none, primary, companion }

final class _MapUnitVisualState {
  const _MapUnitVisualState({
    required this.center,
    required this.ownerColor,
    required this.selected,
    required this.skippedTurn,
    required this.onCity,
    required this.workBadgeLabel,
  });

  final ui.Offset center;
  final ui.Color ownerColor;
  final bool selected;
  final bool skippedTurn;
  final bool onCity;
  final String? workBadgeLabel;
}

final class MapUnitLayerComponent extends Component with HasVisibility {
  MapUnitLayerComponent() : super(priority: 50) {
    isVisible = false;
  }

  final _unitsById = <String, MapUnitComponent>{};
  final _visualOffsetsById = <String, ui.Offset>{};
  var _createdCount = 0;
  var _updatedCount = 0;
  var _removedCount = 0;

  @visibleForTesting
  int get debugUnitCount => _unitsById.length;

  @visibleForTesting
  int get debugCreatedCount => _createdCount;

  @visibleForTesting
  int get debugUpdatedCount => _updatedCount;

  @visibleForTesting
  int get debugRemovedCount => _removedCount;

  @visibleForTesting
  int get debugSharedPaintCount => MapUnitComponent.sharedPaintCount;

  @visibleForTesting
  MapUnitComponent? debugComponentForUnit(String unitId) => _unitsById[unitId];

  MapUnitComponent? componentForUnit(String unitId) => _unitsById[unitId];

  void applyPatch(FlameScenePatch patch, MapStaticRenderCache cache) {
    final animatedIds = {for (final value in patch.movements) value.unitId};
    final changedIds = {for (final value in patch.unitUpserts) value.id};
    for (final unitId in patch.removedUnitIds) {
      final component = _unitsById.remove(unitId);
      _visualOffsetsById.remove(unitId);
      if (component != null) {
        component.removeFromParent();
        _removedCount += 1;
      }
    }
    final snapshot = patch.snapshot;
    final placements = _cityPlacements(snapshot.player);
    final ownerColors = {
      for (final participant in snapshot.player.participants)
        participant.id: ui.Color(participant.colorValue),
    };
    final excavationTurns = _excavationTurns(snapshot.player.artifacts);
    final skippedUnitId = switch (snapshot.player.turnView.pendingAction) {
      PendingUnitTurnSkipView(:final unitId) => unitId,
      _ => null,
    };
    for (final unit in snapshot.player.units) {
      final placement = placements[unit.id] ?? _CityUnitPlacement.none;
      final visual = _visualState(
        cache: cache,
        player: snapshot.player,
        unit: unit,
        placement: placement,
        ownerColors: ownerColors,
        selectedUnitId: snapshot.interaction.selectedUnitId,
        skippedUnitId: skippedUnitId,
        excavationTurns: excavationTurns,
      );
      _visualOffsetsById[unit.id] =
          visual.center - _center(cache, unit.coordinate);
      final existing = _unitsById[unit.id];
      if (existing == null) {
        final component = MapUnitComponent._(unit: unit, visual: visual);
        _unitsById[unit.id] = component;
        add(component);
        _createdCount += 1;
      } else {
        existing._applyUnit(
          unit,
          visual: visual,
          preserveVisualPosition: animatedIds.contains(unit.id),
        );
        if (changedIds.contains(unit.id)) _updatedCount += 1;
      }
    }
    isVisible = _unitsById.isNotEmpty;
  }

  void clearLayer() {
    for (final component in _unitsById.values) {
      component.removeFromParent();
    }
    _unitsById.clear();
    _visualOffsetsById.clear();
    isVisible = false;
  }

  ui.Offset centerFor(
    MapStaticRenderCache cache,
    MapHexCoordinate coordinate,
  ) => _center(cache, coordinate);

  ui.Offset visualCenterFor(
    MapStaticRenderCache cache,
    String unitId,
    MapHexCoordinate coordinate,
  ) =>
      _center(cache, coordinate) +
      (_visualOffsetsById[unitId] ?? ui.Offset.zero);

  static _MapUnitVisualState _visualState({
    required MapStaticRenderCache cache,
    required PlayerMapView player,
    required VisibleUnitView unit,
    required _CityUnitPlacement placement,
    required Map<String, ui.Color> ownerColors,
    required String? selectedUnitId,
    required String? skippedUnitId,
    required Map<String, int> excavationTurns,
  }) {
    final controlled = unit.ownerPlayerId == player.actorPlayerId;
    final ownerColor =
        ownerColors[unit.ownerPlayerId] ??
        (controlled ? MapPalette.controlledUnit : MapPalette.foreignUnit);
    final offset = switch (placement) {
      _CityUnitPlacement.none => ui.Offset.zero,
      _CityUnitPlacement.primary => const ui.Offset(26, 26),
      _CityUnitPlacement.companion => const ui.Offset(-26, 26),
    };
    return _MapUnitVisualState(
      center: _center(cache, unit.coordinate) + offset,
      ownerColor: ownerColor,
      selected: selectedUnitId == unit.id,
      skippedTurn: skippedUnitId == unit.id,
      onCity: placement != _CityUnitPlacement.none,
      workBadgeLabel: _workBadgeLabel(unit, excavationTurns[unit.id]),
    );
  }

  static Map<String, _CityUnitPlacement> _cityPlacements(PlayerMapView player) {
    final cityCenters = {for (final city in player.cities) city.center};
    if (cityCenters.isEmpty) return const {};
    final unitsByCenter = <MapHexCoordinate, List<VisibleUnitView>>{};
    for (final unit in player.units) {
      if (!cityCenters.contains(unit.coordinate)) continue;
      (unitsByCenter[unit.coordinate] ??= []).add(unit);
    }
    final result = <String, _CityUnitPlacement>{};
    for (final units in unitsByCenter.values) {
      final companionMerchant =
          units.length > 1 &&
          units.any((unit) => unit.kind == VisibleUnitKind.merchant);
      for (final unit in units) {
        result[unit.id] =
            companionMerchant && unit.kind == VisibleUnitKind.merchant
            ? _CityUnitPlacement.companion
            : _CityUnitPlacement.primary;
      }
    }
    return result;
  }

  static Map<String, int> _excavationTurns(List<WorldArtifactView> artifacts) =>
      {
        for (final artifact in artifacts)
          if (artifact.location case ExcavationArtifactLocationView(
            :final unitId,
            :final remainingTurns,
          ))
            unitId: remainingTurns,
      };

  static String? _workBadgeLabel(VisibleUnitView unit, int? excavationTurns) {
    final remainingTurns =
        unit.workerJob?.remainingTurns ??
        unit.cityFoundingRemainingTurns ??
        excavationTurns;
    if (remainingTurns != null) return '${remainingTurns}t';
    if (unit.workerAssignment != null) return '+50%';
    return null;
  }

  static ui.Offset _center(
    MapStaticRenderCache cache,
    MapHexCoordinate coordinate,
  ) {
    final center = cache.projection.hexCenter(coordinate);
    return ui.Offset(center.x, center.y - 12);
  }
}

final class MapUnitComponent extends PositionComponent
    with HasGameReference<FlameGame> {
  MapUnitComponent._({
    required VisibleUnitView unit,
    required _MapUnitVisualState visual,
  }) : _unit = unit,
       _visual = visual,
       super(
         position: Vector2(visual.center.dx, visual.center.dy),
         size: Vector2.all(_diameter),
         anchor: Anchor.center,
       );

  static const _diameter = 46.0;
  static const _idleFrameDuration = 0.9;
  static const _spriteVerticalLiftFactor = 0.16;
  static const sharedPaintCount = MapUnitMarkerDetails.sharedPaintCount;

  VisibleUnitView _unit;
  _MapUnitVisualState _visual;
  List<SpriteFrame> _frames = const [];
  var _frameIndex = 0;
  var _frameElapsed = 0.0;
  var _loadGeneration = 0;

  static final _visualBounds = const ui.Rect.fromLTRB(-64, -96, 110, 110);
  var _paintCount = 0;

  @visibleForTesting
  int get debugPaintCount => _paintCount;

  @visibleForTesting
  VisibleUnitView get debugUnit => _unit;

  @visibleForTesting
  ui.Offset get debugVisualCenter => visualCenter;

  ui.Offset get visualCenter => ui.Offset(position.x, position.y);

  @visibleForTesting
  SpriteFrame? get debugSpriteFrame => _currentFrame;

  @visibleForTesting
  ui.Color get debugOwnerColor => _visual.ownerColor;

  @visibleForTesting
  bool get debugSelected => _visual.selected;

  @visibleForTesting
  bool get debugOnCity => _visual.onCity;

  @visibleForTesting
  String? get debugWorkBadgeLabel => _visual.workBadgeLabel;

  @visibleForTesting
  double get debugHealthFraction => MapUnitMarkerDetails.healthFraction(_unit);

  @visibleForTesting
  MapUnitStateBadge? get debugStateBadge => MapUnitMarkerDetails.stateBadgeFor(
    unit: _unit,
    skippedTurn: _visual.skippedTurn,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    unawaited(_loadFrames());
  }

  void _applyUnit(
    VisibleUnitView unit, {
    required _MapUnitVisualState visual,
    required bool preserveVisualPosition,
  }) {
    final kindChanged = _unit.kind != unit.kind;
    _unit = unit;
    _visual = visual;
    if (!preserveVisualPosition) setVisualCenter(visual.center);
    if (kindChanged) _reloadFrames();
  }

  void setVisualCenter(ui.Offset center) {
    position.setValues(center.dx, center.dy);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_frames.length < 2) return;
    _frameElapsed += dt;
    while (_frameElapsed >= _idleFrameDuration) {
      _frameElapsed -= _idleFrameDuration;
      _frameIndex = (_frameIndex + 1) % _frames.length;
    }
  }

  @override
  void render(ui.Canvas canvas) {
    if (!canvas.getLocalClipBounds().overlaps(_visualBounds)) return;
    _paintCount++;
    const center = ui.Offset(_diameter / 2, _diameter / 2);
    MapSpriteShadow.paintUnit(
      canvas,
      center: center,
      compact: _visual.onCity || _visual.workBadgeLabel != null,
    );
    final metrics = MapSpriteCatalog.unitMetrics(_unit.kind);
    final destination = ui.Rect.fromCenter(
      center: ui.Offset(
        center.dx,
        center.dy - metrics.height * _spriteVerticalLiftFactor,
      ),
      width: metrics.width,
      height: metrics.height,
    );
    final frame = _currentFrame;
    if (_unit.movementUnits == 0) {
      canvas.saveLayer(
        destination.inflate(28),
        MapUnitMarkerDetails.exhaustedPaint,
      );
    }
    if (frame != null) {
      MapSpritePainter.paint(canvas, frame, destination: destination);
    } else {
      MapUnitMarkerDetails.paintFallback(
        canvas,
        center: center,
        unit: _unit,
        ownerColor: _visual.ownerColor,
        selected: _visual.selected,
      );
    }
    if (_unit.movementUnits == 0) canvas.restore();
    final compact = _visual.workBadgeLabel != null;
    final height = compact ? metrics.height * 0.72 : metrics.height;
    final statusTop =
        center.dy -
        height * (0.5 + _spriteVerticalLiftFactor) +
        (compact || _visual.onCity ? 6 : 9);
    final statusWidth = metrics.width * (compact ? 0.72 : 1) * 0.68;
    MapUnitMarkerDetails.paint(
      canvas,
      center: center,
      unit: _unit,
      ownerColor: _visual.ownerColor,
      selected: _visual.selected,
      skippedTurn: _visual.skippedTurn,
      onCity: _visual.onCity,
      statusTop: statusTop,
      statusWidth: statusWidth < 28 ? 28 : statusWidth,
      workBadgeLabel: _visual.workBadgeLabel,
    );
  }

  SpriteFrame? get _currentFrame =>
      _frames.isEmpty ? null : _frames[_frameIndex % _frames.length];

  void _reloadFrames() {
    _frames = const [];
    _frameIndex = 0;
    _frameElapsed = 0;
    _loadGeneration += 1;
    if (isLoaded) unawaited(_loadFrames());
  }

  Future<void> _loadFrames() async {
    final generation = ++_loadGeneration;
    final kind = _unit.kind;
    final List<SpriteFrame> frames;
    try {
      frames = await Future.wait(
        MapSpriteCatalog.idleUnitFrames(kind).map(SpriteFrames.load),
      );
    } on Object {
      return;
    }
    if (generation != _loadGeneration || _unit.kind != kind) return;
    _frames = List.unmodifiable(frames);
    _refreshGameWidget();
  }

  void _refreshGameWidget() {
    if (isMounted && game.isAttached && game.paused) {
      game.stepEngine(stepTime: 0);
    }
  }
}
