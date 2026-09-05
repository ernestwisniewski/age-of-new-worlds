part of 'unit_map_layer.dart';

final class MapUnitComponent extends PositionComponent
    with HasGameReference<FlameGame>
    implements MapUnitIdleParticipant {
  MapUnitComponent._({
    required VisibleUnitView unit,
    required _MapUnitVisualState visual,
    required MapSpriteShadowCache shadows,
    required void Function() onIdleChanged,
    required double Function()? idlePauseDuration,
  }) : _unit = unit,
       _visual = visual,
       _shadows = shadows,
       _onIdleChanged = onIdleChanged,
       _idlePauseDuration = idlePauseDuration,
       super(
         position: Vector2(visual.center.dx, visual.center.dy),
         size: Vector2.all(_diameter),
         anchor: Anchor.center,
       );

  static const _diameter = 46.0;
  static const _spriteVerticalLiftFactor = 0.16;
  static const sharedPaintCount = MapUnitMarkerDetails.sharedPaintCount;

  VisibleUnitView _unit;
  _MapUnitVisualState _visual;
  final MapSpriteShadowCache _shadows;
  final void Function() _onIdleChanged;
  final double Function()? _idlePauseDuration;
  late final _sprite = MapUnitSpriteAnimation(
    kind: _unit.kind,
    onLoaded: _spriteLoaded,
    idlePauseDuration: _idlePauseDuration,
  )..setIdlePausesEnabled(!_visual.selected);

  void _spriteLoaded() {
    _onIdleChanged();
    _refreshGameWidget();
  }

  bool get _canAnimateIdle =>
      isMounted &&
      !_moving &&
      _sprite.action == MapUnitSpriteAction.idle &&
      _sprite.frame != null;

  ui.Rect get _worldBounds => _visualBounds.shift(
    visualCenter - const ui.Offset(_diameter / 2, _diameter / 2),
  );
  var _moving = false;
  MapHexCoordinate? _presentedCoordinate;
  bool get _onCity =>
      !_moving &&
      _visual.onCity &&
      (_presentedCoordinate == null ||
          _presentedCoordinate == _unit.coordinate);

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
  SpriteFrame? get debugSpriteFrame => _sprite.frame;

  @visibleForTesting
  MapUnitSpriteAction get debugSpriteAction => _sprite.action;

  @visibleForTesting
  bool get debugSpriteMirrored => _sprite.mirrored;

  @visibleForTesting
  Future<void> debugLoadSprite() => _sprite.load();

  @visibleForTesting
  ui.Size get debugSpriteSize => _spriteSize;

  ui.Size get _spriteSize {
    final metrics = MapSpriteCatalog.unitMetrics(_unit.kind, onCity: _onCity);
    final scale = _visual.workBadgeLabel == null ? 1.0 : 0.72;
    return ui.Size(metrics.width * scale, metrics.height * scale);
  }

  @visibleForTesting
  ui.Color get debugOwnerColor => _visual.ownerColor;

  @visibleForTesting
  bool get debugSelected => _visual.selected;

  @visibleForTesting
  bool get debugOnCity => _onCity;

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
    unawaited(_sprite.load());
  }

  void _applyUnit(
    VisibleUnitView unit, {
    required _MapUnitVisualState visual,
    required bool preserveVisualPosition,
  }) {
    final kindChanged = _unit.kind != unit.kind;
    _unit = unit;
    _visual = visual;
    _sprite.setIdlePausesEnabled(!visual.selected);
    if (!preserveVisualPosition && !_moving) cancelMovement();
    if (kindChanged) _sprite.setKind(unit.kind);
  }

  void setVisualCenter(ui.Offset center) {
    position.setValues(center.dx, center.dy);
  }

  void beginMovement() {
    _moving = true;
    _sprite.playIdle();
    _onIdleChanged();
  }

  void advanceWalk(ui.Offset from, ui.Offset to, double dt) {
    _sprite.playWalkToward(from, to);
    _sprite.advance(dt);
  }

  void finishMovement(MapHexCoordinate coordinate, ui.Offset center) {
    setVisualCenter(center);
    _moving = false;
    _presentedCoordinate = coordinate;
    _sprite.playIdle();
    _onIdleChanged();
  }

  void cancelMovement() => finishMovement(_unit.coordinate, _visual.center);

  @override
  double get idleFrameDelay => _sprite.idleFrameDelay;

  @override
  bool advanceIdle(double dt) {
    if (!_canAnimateIdle) return false;
    final previous = _sprite.index;
    _sprite.advance(dt);
    return _sprite.index != previous;
  }

  @override
  void onMount() {
    super.onMount();
    _onIdleChanged();
  }

  @override
  void onRemove() {
    _sprite.dispose();
    _onIdleChanged();
    super.onRemove();
  }

  @override
  void render(ui.Canvas canvas) {
    if (!mapCanvasClipBounds(canvas).overlaps(_visualBounds)) return;
    _paintCount++;
    const center = ui.Offset(_diameter / 2, _diameter / 2);
    _shadows.paintUnit(
      canvas,
      center: center,
      compact: _onCity || _visual.workBadgeLabel != null,
    );
    final size = _spriteSize;
    final destination = ui.Rect.fromCenter(
      center: ui.Offset(
        center.dx,
        center.dy - size.height * _spriteVerticalLiftFactor,
      ),
      width: size.width,
      height: size.height,
    );
    final frame = _sprite.frame;
    if (_unit.movementUnits == 0) {
      canvas.saveLayer(
        destination.inflate(28),
        MapUnitMarkerDetails.exhaustedPaint,
      );
    }
    if (frame != null) {
      _sprite.paint(canvas, destination);
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
    final statusTop =
        destination.top +
        (_sprite.statusTopOffset(size) ?? (compact || _onCity ? 6 : 9));
    final statusWidth = size.width * 0.68;
    MapUnitMarkerDetails.paint(
      canvas,
      center: center,
      unit: _unit,
      ownerColor: _visual.ownerColor,
      selected: _visual.selected,
      skippedTurn: _visual.skippedTurn,
      onCity: _onCity,
      statusTop: statusTop,
      statusWidth: statusWidth < 28 ? 28 : statusWidth,
      workBadgeLabel: _visual.workBadgeLabel,
    );
  }

  void _refreshGameWidget() {
    if (isMounted && game.isAttached && game.paused) {
      game.stepEngine(stepTime: 0);
    }
  }
}
