part of 'map_cloud_layer.dart';

extension _CloudDriftSpawning on MapCloudLayerComponent {
  void _spawnCloudlet() {
    if (_clouds.length >= MapCloudLayerComponent._maxActiveClouds) return;
    if (_discoveredClipPath == null || _mapBounds.isEmpty) return;

    final hexRadius = _hexRadius;
    final cloudWidth = hexRadius * (2.95 + _random.nextDouble() * 1.55);
    final cloudHeight = hexRadius * (1.15 + _random.nextDouble() * 0.65);
    final padding = cloudWidth + hexRadius * 1.4;
    final fromLeft = _random.nextBool();
    final startY =
        _mapBounds.top + _random.nextDouble() * math.max(1, _mapBounds.height);
    final endY =
        (startY + (-0.5 + _random.nextDouble()) * _mapBounds.height * 0.45)
            .clamp(
              _mapBounds.top - padding * 0.25,
              _mapBounds.bottom + padding * 0.25,
            )
            .toDouble();
    final start = Vector2(
      fromLeft ? _mapBounds.left - padding : _mapBounds.right + padding,
      startY,
    );
    final end = Vector2(
      fromLeft ? _mapBounds.right + padding : _mapBounds.left - padding,
      endY,
    );
    final duration = _range(_durationSeconds);

    _clouds.add(
      _createCloudlet(
        start: start,
        end: end,
        duration: duration,
        fromLeft: fromLeft,
        cloudWidth: cloudWidth,
        cloudHeight: cloudHeight,
      ),
    );
    _maybeSpawnCompanionCloudlets(
      start: start,
      end: end,
      duration: duration,
      fromLeft: fromLeft,
      cloudWidth: cloudWidth,
      cloudHeight: cloudHeight,
    );
  }

  _Cloudlet _createCloudlet({
    required Vector2 start,
    required Vector2 end,
    required double duration,
    required bool fromLeft,
    required double cloudWidth,
    required double cloudHeight,
    double opacityScale = 1,
    double initialDelayFraction = 0,
  }) {
    final cloud = _Cloudlet(
      start: start,
      end: end,
      duration: duration,
      angle: (fromLeft ? -0.05 : 0.05) + (-0.5 + _random.nextDouble()) * 0.12,
      opacity: (0.66 + _random.nextDouble() * 0.18) * opacityScale,
      puffs: _buildPuffs(cloudWidth: cloudWidth, cloudHeight: cloudHeight),
      elapsed: -duration * initialDelayFraction,
    );
    _cacheCloudTexture(cloud);
    return cloud;
  }

  void _maybeSpawnCompanionCloudlets({
    required Vector2 start,
    required Vector2 end,
    required double duration,
    required bool fromLeft,
    required double cloudWidth,
    required double cloudHeight,
  }) {
    if (_clouds.length >= MapCloudLayerComponent._maxActiveClouds) return;
    final groupRoll = _random.nextDouble();
    if (groupRoll >= MapCloudLayerComponent._cloudGroupChance) return;

    final companionCount =
        groupRoll < MapCloudLayerComponent._cloudClusterChance ? 2 : 1;
    final travel = end - start;
    final travelLength = travel.length;
    final direction = travelLength <= 0
        ? Vector2(1, 0)
        : Vector2(travel.x / travelLength, travel.y / travelLength);
    final normal = Vector2(-direction.y, direction.x);

    for (var i = 0; i < companionCount; i++) {
      if (_clouds.length >= MapCloudLayerComponent._maxActiveClouds) return;
      final side = i.isEven ? 1.0 : -1.0;
      final along =
          cloudWidth *
          (0.34 + _random.nextDouble() * 0.52) *
          (_random.nextBool() ? 1 : -1);
      final across = side * cloudHeight * (0.72 + _random.nextDouble() * 0.74);
      final offset = Vector2(
        direction.x * along + normal.x * across,
        direction.y * along + normal.y * across,
      );
      final widthScale = 0.58 + _random.nextDouble() * 0.24;
      final heightScale = 0.70 + _random.nextDouble() * 0.22;
      final durationScale = 0.96 + _random.nextDouble() * 0.12;
      final opacityScale = 0.70 + _random.nextDouble() * 0.18;
      final delay = 0.03 + _random.nextDouble() * 0.08;

      _clouds.add(
        _createCloudlet(
          start: start + offset,
          end: end + offset,
          duration: duration * durationScale,
          fromLeft: fromLeft,
          cloudWidth: cloudWidth * widthScale,
          cloudHeight: cloudHeight * heightScale,
          opacityScale: opacityScale,
          initialDelayFraction: delay,
        ),
      );
    }
  }

  List<_CloudPuff> _buildPuffs({
    required double cloudWidth,
    required double cloudHeight,
  }) {
    final puffs = <_CloudPuff>[
      _puff(-0.42, 0.08, 0.42, 0.58, cloudWidth, cloudHeight),
      _puff(-0.22, -0.16, 0.48, 0.72, cloudWidth, cloudHeight),
      _puff(0.02, -0.08, 0.58, 0.84, cloudWidth, cloudHeight),
      _puff(0.25, 0.10, 0.50, 0.66, cloudWidth, cloudHeight),
      _puff(0.46, -0.06, 0.34, 0.54, cloudWidth, cloudHeight),
      _puff(-0.06, 0.24, 0.82, 0.50, cloudWidth, cloudHeight),
      _puff(-0.32, 0.30, 0.30, 0.40, cloudWidth, cloudHeight),
      _puff(0.32, 0.30, 0.34, 0.42, cloudWidth, cloudHeight),
    ];
    if (_random.nextBool()) {
      puffs.add(_puff(-0.66, 0.18, 0.22, 0.34, cloudWidth, cloudHeight));
    }
    if (_random.nextBool()) {
      puffs.add(_puff(0.68, 0.18, 0.24, 0.36, cloudWidth, cloudHeight));
    }
    if (_random.nextBool()) {
      puffs.add(_puff(0.58, -0.30, 0.20, 0.30, cloudWidth, cloudHeight));
    }
    return puffs;
  }

  _CloudPuff _puff(
    double x,
    double y,
    double width,
    double height,
    double cloudWidth,
    double cloudHeight,
  ) {
    final wobbleX = (-0.5 + _random.nextDouble()) * cloudWidth * 0.04;
    final wobbleY = (-0.5 + _random.nextDouble()) * cloudHeight * 0.06;
    return _CloudPuff(
      x: x * cloudWidth + wobbleX,
      y: y * cloudHeight + wobbleY,
      width: cloudWidth * width,
      height: cloudHeight * height,
      coreInset: 3.0,
    );
  }

  double _range(({double min, double max}) range) {
    return _randomRange(_random, range);
  }
}

double _randomRange(math.Random random, ({double min, double max}) range) {
  final min = range.min;
  final max = range.max;
  if (!min.isFinite || !max.isFinite) return 0;
  if (max <= min) return min;
  return min + random.nextDouble() * (max - min);
}

class _Cloudlet {
  _Cloudlet({
    required this.start,
    required this.end,
    required this.duration,
    required this.angle,
    required this.opacity,
    required this.puffs,
    this.elapsed = 0,
  });

  final Vector2 start;
  final Vector2 end;
  final double duration;
  final double angle;
  final double opacity;
  final List<_CloudPuff> puffs;
  double elapsed;
  ui.Image? image;
  ui.Offset imageOrigin = ui.Offset.zero;

  ui.Rect get puffBounds {
    if (puffs.isEmpty) return ui.Rect.zero;
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    for (final puff in puffs) {
      minX = math.min(minX, puff.x - puff.width / 2);
      minY = math.min(minY, puff.y - puff.height / 2);
      maxX = math.max(maxX, puff.x + puff.width / 2);
      maxY = math.max(maxY, puff.y + puff.height / 2);
    }
    return ui.Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}

class _CloudPuff {
  const _CloudPuff({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.coreInset,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final double coreInset;
}
