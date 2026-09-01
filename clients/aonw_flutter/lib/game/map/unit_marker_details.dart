import 'dart:ui' as ui;

import 'package:flutter/material.dart' show IconData, Icons, TextStyle;
import 'package:flutter/painting.dart';

import '../../features/map/presentation/map_palette.dart';
import '../../features/map/read_model/player_map_view.dart';

enum MapUnitStateBadge { fortified, healing, skippedTurn, exhausted }

const _healthHeight = 4.0;
const _healthGap = 6.0;
const _ownerGap = 2.0;
const _typeBadgeSize = 15.0;
const _strokeWidth = 1.0;
final _iconLayouts = <({int codePoint, int color, double size}), TextPainter>{};
final _workLayouts = <String, TextPainter>{};
final ui.Paint _shadowPaint = ui.Paint()..color = MapPalette.unitShadow;
final ui.Paint _surfacePaint = ui.Paint()..color = MapPalette.unitSurfaceDeep;
final ui.Paint _dynamicFillPaint = ui.Paint();
final ui.Paint _goldStrokePaint = ui.Paint()
  ..color = MapPalette.unitGoldBorder
  ..style = ui.PaintingStyle.stroke
  ..strokeWidth = _strokeWidth;
final ui.Paint _selectedGlowPaint = ui.Paint()
  ..color = MapPalette.unitSelectedGlow;
final ui.Paint _healthBackdropPaint = ui.Paint()
  ..color = MapPalette.unitHealthBackdrop;
final ui.Paint _workStrokePaint = ui.Paint()
  ..color = MapPalette.unitWorkBorder
  ..style = ui.PaintingStyle.stroke
  ..strokeWidth = _strokeWidth;
final ui.Paint _exhaustedPaint = ui.Paint()
  ..colorFilter = const ui.ColorFilter.matrix([
    0.6264,
    0.1759,
    0.0177,
    0,
    0,
    0.0524,
    0.7499,
    0.0177,
    0,
    0,
    0.0524,
    0.1759,
    0.5917,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

const _unitIcons = <VisibleUnitKind, IconData>{
  VisibleUnitKind.commander: Icons.shield,
  VisibleUnitKind.warrior: Icons.gps_fixed,
  VisibleUnitKind.spearman: Icons.gps_fixed,
  VisibleUnitKind.fieldCannon: Icons.gps_fixed,
  VisibleUnitKind.archer: Icons.arrow_upward,
  VisibleUnitKind.rifleman: Icons.arrow_upward,
  VisibleUnitKind.settler: Icons.home_outlined,
  VisibleUnitKind.worker: Icons.construction_outlined,
  VisibleUnitKind.catapult: Icons.construction_outlined,
  VisibleUnitKind.merchant: Icons.storefront_outlined,
  VisibleUnitKind.scout: Icons.explore_outlined,
  VisibleUnitKind.reconPlane: Icons.explore_outlined,
  VisibleUnitKind.cavalry: Icons.directions_run,
  VisibleUnitKind.heavyInfantry: Icons.security,
  VisibleUnitKind.tank: Icons.security,
  VisibleUnitKind.scoutShip: Icons.directions_boat_outlined,
  VisibleUnitKind.warship: Icons.directions_boat_outlined,
};

final class MapUnitMarkerDetails {
  MapUnitMarkerDetails._();

  static const sharedPaintCount = 8;
  static final exhaustedPaint = _exhaustedPaint;

  static MapUnitStateBadge? stateBadgeFor({
    required VisibleUnitView unit,
    required bool skippedTurn,
  }) {
    final fraction = healthFraction(unit);
    if (unit.posture == VisibleUnitPosture.fortified) {
      return fraction < 0.995
          ? MapUnitStateBadge.healing
          : MapUnitStateBadge.fortified;
    }
    if (skippedTurn) return MapUnitStateBadge.skippedTurn;
    if (unit.movementUnits == 0) return MapUnitStateBadge.exhausted;
    return null;
  }

  static double healthFraction(VisibleUnitView unit) {
    final current = unit.hitPoints;
    final maximum = unit.maximumHitPoints;
    if (current == null || maximum == null || maximum <= 0) return 1;
    return (current / maximum).clamp(0.0, 1.0).toDouble();
  }

  static void paint(
    ui.Canvas canvas, {
    required ui.Offset center,
    required VisibleUnitView unit,
    required ui.Color ownerColor,
    required bool selected,
    required bool skippedTurn,
    required bool onCity,
    required double statusTop,
    required double statusWidth,
    required String? workBadgeLabel,
  }) {
    _paintStatusBars(
      canvas,
      center: center,
      top: statusTop,
      width: statusWidth,
      unit: unit,
      ownerColor: ownerColor,
      selected: selected,
    );
    _paintStateBadge(
      canvas,
      center: center,
      badge: stateBadgeFor(unit: unit, skippedTurn: skippedTurn),
      onCity: onCity,
    );
    if (unit.carriedArtifactId != null) {
      _paintArtifactBadge(canvas, center: center, onCity: onCity);
    }
    if (workBadgeLabel case final label? when label.isNotEmpty) {
      _paintWorkBadge(
        canvas,
        center: center,
        top: statusTop,
        ownerColor: ownerColor,
        label: label,
      );
    }
  }

  static void paintFallback(
    ui.Canvas canvas, {
    required ui.Offset center,
    required VisibleUnitView unit,
    required ui.Color ownerColor,
    required bool selected,
  }) {
    final shadow = ui.Rect.fromCenter(
      center: center.translate(0, 12),
      width: 18,
      height: 5,
    );
    _dynamicFillPaint.color = ownerColor;
    canvas
      ..drawOval(shadow, _shadowPaint)
      ..drawCircle(center, 14, _dynamicFillPaint);
    _goldStrokePaint.strokeWidth = selected ? 2.2 : 1.7;
    canvas.drawCircle(center, 14, _goldStrokePaint);
    _goldStrokePaint.strokeWidth = _strokeWidth;
    _paintIcon(
      canvas,
      _unitIcons[unit.kind]!,
      center: center,
      size: 13,
      color: MapPalette.unitGoldLight,
    );
  }
}

void _paintStatusBars(
  ui.Canvas canvas, {
  required ui.Offset center,
  required double top,
  required double width,
  required VisibleUnitView unit,
  required ui.Color ownerColor,
  required bool selected,
}) {
  final healthRect = ui.Rect.fromLTWH(
    center.dx - width / 2,
    top - _healthGap - _healthHeight,
    width,
    _healthHeight,
  );
  final badgeRect = ui.Rect.fromCenter(
    center: ui.Offset(
      center.dx,
      healthRect.top - _ownerGap - _typeBadgeSize / 2,
    ),
    width: _typeBadgeSize,
    height: _typeBadgeSize,
  );
  final badge = ui.RRect.fromRectAndRadius(
    badgeRect,
    const ui.Radius.circular(4),
  );
  canvas.drawRRect(badge.shift(const ui.Offset(0, 1.2)), _shadowPaint);
  if (selected) {
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        badgeRect.inflate(3.2),
        const ui.Radius.circular(6.4),
      ),
      _selectedGlowPaint,
    );
  }
  _dynamicFillPaint.color = ownerColor;
  canvas
    ..drawRRect(badge, _dynamicFillPaint)
    ..drawRRect(badge, _goldStrokePaint);
  _paintIcon(
    canvas,
    _unitIcons[unit.kind]!,
    center: badgeRect.center,
    size: 9.5,
    color: MapPalette.unitGoldLight,
  );
  _paintHealth(canvas, healthRect, MapUnitMarkerDetails.healthFraction(unit));
}

void _paintHealth(ui.Canvas canvas, ui.Rect outerRect, double fraction) {
  final outer = ui.RRect.fromRectAndRadius(
    outerRect,
    const ui.Radius.circular(_healthHeight / 2),
  );
  final inner = outerRect.deflate(_strokeWidth);
  final fill = ui.Rect.fromLTWH(
    inner.left,
    inner.top,
    inner.width * fraction,
    inner.height,
  );
  canvas
    ..drawRRect(outer, _healthBackdropPaint)
    ..drawRRect(
      ui.RRect.fromRectAndRadius(fill, ui.Radius.circular(inner.height / 2)),
      _dynamicFillPaint..color = _healthColor(fraction),
    )
    ..drawRRect(outer, _goldStrokePaint);
}

void _paintStateBadge(
  ui.Canvas canvas, {
  required ui.Offset center,
  required MapUnitStateBadge? badge,
  required bool onCity,
}) {
  if (badge == null) return;
  final radius = onCity ? 5.0 : 5.5;
  final badgeCenter = center.translate(onCity ? 8 : 10, onCity ? 6.5 : 8.5);
  canvas
    ..drawCircle(badgeCenter.translate(0, 1.2), radius + 1, _shadowPaint)
    ..drawCircle(badgeCenter, radius + 0.6, _surfacePaint);
  _dynamicFillPaint.color = _stateColor(badge);
  canvas
    ..drawCircle(badgeCenter, radius, _dynamicFillPaint)
    ..drawCircle(badgeCenter, radius, _goldStrokePaint);
  _paintIcon(
    canvas,
    _stateIcon(badge),
    center: badgeCenter,
    size: radius * 1.15,
    color: MapPalette.unitGoldLight,
  );
}

void _paintArtifactBadge(
  ui.Canvas canvas, {
  required ui.Offset center,
  required bool onCity,
}) {
  final radius = onCity ? 5.2 : 5.8;
  final badgeCenter = center.translate(onCity ? -8 : -10, onCity ? 6.5 : 8.5);
  canvas
    ..drawCircle(badgeCenter.translate(0, 1.2), radius + 1, _shadowPaint)
    ..drawCircle(badgeCenter, radius + 0.8, _surfacePaint);
  _dynamicFillPaint.color = MapPalette.unitGold;
  canvas
    ..drawCircle(badgeCenter, radius, _dynamicFillPaint)
    ..drawCircle(badgeCenter, radius, _goldStrokePaint);
  _paintIcon(
    canvas,
    Icons.diamond_outlined,
    center: badgeCenter,
    size: radius * 1.2,
    color: MapPalette.unitBackground,
  );
}

void _paintWorkBadge(
  ui.Canvas canvas, {
  required ui.Offset center,
  required double top,
  required ui.Color ownerColor,
  required String label,
}) {
  final text = _workLayout(label);
  final width = text.width < 16 ? 28.0 : text.width + 12;
  final height = text.height + 6;
  final rect = ui.Rect.fromLTWH(
    center.dx - width / 2,
    top - 30 - height,
    width,
    height,
  );
  final badge = ui.RRect.fromRectAndRadius(rect, const ui.Radius.circular(5));
  canvas.drawRRect(badge.shift(const ui.Offset(0, 1.5)), _shadowPaint);
  _dynamicFillPaint.color = ownerColor.withAlpha(186);
  canvas
    ..drawRRect(badge, _dynamicFillPaint)
    ..drawRRect(badge, _workStrokePaint);
  text.paint(
    canvas,
    ui.Offset(
      rect.center.dx - text.width / 2,
      rect.center.dy - text.height / 2,
    ),
  );
}

TextPainter _workLayout(String label) {
  final cached = _workLayouts.remove(label);
  if (cached != null) {
    _workLayouts[label] = cached;
    return cached;
  }
  final result = TextPainter(
    text: TextSpan(
      text: label,
      style: const TextStyle(
        color: MapPalette.unitTextBright,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        fontFeatures: [ui.FontFeature.tabularFigures()],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  _workLayouts[label] = result;
  if (_workLayouts.length > 64) _workLayouts.remove(_workLayouts.keys.first);
  return result;
}

void _paintIcon(
  ui.Canvas canvas,
  IconData icon, {
  required ui.Offset center,
  required double size,
  required ui.Color color,
}) {
  final key = (codePoint: icon.codePoint, color: color.toARGB32(), size: size);
  final cached = _iconLayouts.remove(key);
  final painter =
      cached ??
      (TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            inherit: false,
            color: color,
            fontSize: size,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout());
  _iconLayouts[key] = painter;
  if (_iconLayouts.length > 48) _iconLayouts.remove(_iconLayouts.keys.first);
  painter.paint(
    canvas,
    ui.Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
  );
}

IconData _stateIcon(MapUnitStateBadge badge) => switch (badge) {
  MapUnitStateBadge.fortified => Icons.shield_outlined,
  MapUnitStateBadge.healing => Icons.favorite_border,
  MapUnitStateBadge.skippedTurn => Icons.skip_next,
  MapUnitStateBadge.exhausted => Icons.hourglass_empty,
};

ui.Color _stateColor(MapUnitStateBadge badge) => switch (badge) {
  MapUnitStateBadge.fortified => MapPalette.unitInfo,
  MapUnitStateBadge.healing => MapPalette.unitSuccess,
  MapUnitStateBadge.skippedTurn => MapPalette.unitTextSecondary,
  MapUnitStateBadge.exhausted => MapPalette.unitTextTertiary,
};

ui.Color _healthColor(double fraction) {
  if (fraction >= 0.5) {
    return ui.Color.lerp(
      MapPalette.unitWarning,
      MapPalette.unitSuccess,
      (fraction - 0.5) / 0.5,
    )!;
  }
  return ui.Color.lerp(
    MapPalette.unitDanger,
    MapPalette.unitWarning,
    fraction / 0.5,
  )!;
}
