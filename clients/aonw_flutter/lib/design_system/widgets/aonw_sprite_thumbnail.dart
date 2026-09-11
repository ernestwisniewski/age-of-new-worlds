import 'package:flutter/material.dart';

import '../assets/sprite_frame_id.dart';
import '../assets/sprite_frame_repository.dart';
import '../assets/sprite_frames.dart';

/// A static HUD image sharing the same scoped atlas pages as the map.
final class AonwSpriteThumbnail extends StatefulWidget {
  const AonwSpriteThumbnail({required this.frame, this.size = 72, super.key});

  final SpriteFrameId frame;
  final double size;

  @override
  State<AonwSpriteThumbnail> createState() => _AonwSpriteThumbnailState();
}

final class _AonwSpriteThumbnailState extends State<AonwSpriteThumbnail> {
  final _scope = SpriteFrames.createScope();
  late Future<SpriteFrame> _future;

  @override
  void initState() {
    super.initState();
    _future = _scope.load(widget.frame);
  }

  @override
  void didUpdateWidget(AonwSpriteThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frame != widget.frame) _future = _scope.load(widget.frame);
  }

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.size,
    child: FutureBuilder<SpriteFrame>(
      key: ValueKey(widget.frame),
      future: _future,
      initialData: _scope.cached(widget.frame),
      builder: (context, snapshot) => switch (snapshot.data) {
        final frame? => CustomPaint(painter: _ThumbnailPainter(frame)),
        null => const SizedBox.shrink(),
      },
    ),
  );
}

final class _ThumbnailPainter extends CustomPainter {
  const _ThumbnailPainter(this.frame);

  final SpriteFrame frame;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = frame.geometryFor(
      logicalSource: Offset.zero & frame.originalSize,
      destination: Offset.zero & size,
    );
    canvas.drawImageRect(
      frame.image,
      geometry.source,
      geometry.destination,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_ThumbnailPainter oldDelegate) =>
      !identical(frame, oldDelegate.frame);
}
