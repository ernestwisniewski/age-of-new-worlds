import 'package:flutter/material.dart';

import 'resource_popup.dart';

/// Authored 24-unit outlines shared by the compact resource pills.
final class ResourceIcon extends StatelessWidget {
  const ResourceIcon({
    required this.kind,
    required this.color,
    required this.size,
    super.key,
  });
  final ResourcePopup kind;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _ResourceIconPainter(kind, color)),
  );
}

final class _ResourceIconPainter extends CustomPainter {
  const _ResourceIconPainter(this.kind, this.color);
  final ResourcePopup kind;
  final Color color;
  static final _paths = {
    for (final kind in ResourcePopup.values) kind: _outline(kind),
  };

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    canvas.drawPath(
      _paths[kind]!,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ResourceIconPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}

Path _outline(ResourcePopup kind) => switch (kind) {
  ResourcePopup.gold => _goldOutline(),
  ResourcePopup.turn => _turnOutline(),
  ResourcePopup.resources => _resourcesOutline(),
  ResourcePopup.stability => _stabilityOutline(),
  ResourcePopup.science => _scienceOutline(),
  ResourcePopup.victory => _victoryOutline(),
};

Path _goldOutline() => Path()
  ..addOval(const Rect.fromLTWH(4, 4, 16, 16))
  ..addOval(const Rect.fromLTWH(8, 8, 8, 8));

Path _turnOutline() => Path()
  ..addOval(const Rect.fromLTWH(3, 3, 18, 18))
  ..moveTo(12, 11)
  ..lineTo(12, 17)
  ..moveTo(12, 7)
  ..lineTo(12, 7.2);

Path _resourcesOutline() => Path()
  ..moveTo(12, 3)
  ..lineTo(19, 8)
  ..lineTo(19, 16)
  ..lineTo(12, 21)
  ..lineTo(5, 16)
  ..lineTo(5, 8)
  ..close()
  ..moveTo(12, 3)
  ..lineTo(12, 21)
  ..moveTo(5, 8)
  ..lineTo(12, 13)
  ..lineTo(19, 8);

Path _stabilityOutline() => Path()
  ..moveTo(12, 3)
  ..lineTo(20, 6)
  ..lineTo(20, 12)
  ..cubicTo(20, 16, 17, 19, 12, 21)
  ..cubicTo(7, 19, 4, 16, 4, 12)
  ..lineTo(4, 6)
  ..close();

Path _scienceOutline() => Path()
  ..moveTo(12, 3)
  ..lineTo(12, 9)
  ..moveTo(9, 21)
  ..lineTo(15, 21)
  ..moveTo(10, 9)
  ..lineTo(14, 9)
  ..lineTo(18, 18)
  ..arcToPoint(const Offset(16.2, 21), radius: const Radius.circular(2))
  ..lineTo(7.8, 21)
  ..arcToPoint(const Offset(6, 18), radius: const Radius.circular(2))
  ..lineTo(10, 9)
  ..moveTo(8.5, 16)
  ..lineTo(15.5, 16);

Path _victoryOutline() => Path()
  ..moveTo(8, 21)
  ..lineTo(16, 21)
  ..moveTo(10, 17)
  ..lineTo(14, 17)
  ..lineTo(14, 21)
  ..moveTo(7, 4)
  ..lineTo(17, 4)
  ..lineTo(17, 9)
  ..arcToPoint(const Offset(7, 9), radius: const Radius.circular(5))
  ..close()
  ..moveTo(17, 6)
  ..lineTo(20, 6)
  ..cubicTo(20, 9, 18.5, 11, 16, 11)
  ..moveTo(7, 6)
  ..lineTo(4, 6)
  ..cubicTo(4, 9, 5.5, 11, 8, 11);
