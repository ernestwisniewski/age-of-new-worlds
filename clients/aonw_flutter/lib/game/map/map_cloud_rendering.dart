part of 'map_cloud_layer.dart';

extension _CloudDriftRendering on MapCloudLayerComponent {
  void _renderCloud(ui.Canvas canvas, _Cloudlet cloud) {
    final image = cloud.image;
    if (image == null || cloud.elapsed <= 0) return;
    final progress = (cloud.elapsed / cloud.duration).clamp(0.0, 1.0);
    final opacity = math.sin(progress * math.pi);
    final center = cloud.start + (cloud.end - cloud.start) * progress;
    _cloudPaint.color = const ui.Color(0xffffffff).withValues(alpha: opacity);
    canvas
      ..save()
      ..translate(center.x, center.y)
      ..rotate(cloud.angle)
      ..drawImage(image, cloud.imageOrigin, _cloudPaint)
      ..restore();
  }

  // Soft puffs have no pixel-scale details. One world pixel per texel preserves
  // their gradients and avoids repeating 33 blurred ovals per cloud each frame.
  void _cacheCloudTexture(_Cloudlet cloud) {
    final bounds = cloud.puffBounds;
    final padded = bounds
        .expandToInclude(bounds.shift(const ui.Offset(18, 22)))
        .inflate(60);
    final origin = ui.Offset(
      padded.left.floorToDouble(),
      padded.top.floorToDouble(),
    );
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)..translate(-origin.dx, -origin.dy);
    _paintCloudPuffs(canvas, cloud);
    final picture = recorder.endRecording();
    cloud.imageOrigin = origin;
    cloud.image = picture.toImageSync(
      (padded.right - origin.dx).ceil(),
      (padded.bottom - origin.dy).ceil(),
    );
    picture.dispose();
  }

  void _paintCloudPuffs(ui.Canvas canvas, _Cloudlet cloud) {
    final opacity = cloud.opacity;
    _shadowPaint.color = ui.Color.fromARGB((opacity * 16).round(), 84, 91, 102);
    _hazePaint.color = ui.Color.fromARGB((opacity * 44).round(), 235, 242, 247);
    _corePaint.color = ui.Color.fromARGB((opacity * 34).round(), 255, 255, 255);
    for (final puff in cloud.puffs) {
      final rect = ui.Rect.fromCenter(
        center: ui.Offset(puff.x, puff.y),
        width: puff.width,
        height: puff.height,
      );
      canvas
        ..drawOval(rect.shift(const ui.Offset(18, 22)), _shadowPaint)
        ..drawOval(rect, _hazePaint)
        ..drawOval(rect.deflate(puff.coreInset), _corePaint);
    }
  }
}
