import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/assets/sprite_frame_id.dart';
import '../../../design_system/widgets/aonw_sprite_thumbnail.dart';
import '../read_model/production_view.dart';

final class ProductionTargetArtwork extends StatelessWidget {
  const ProductionTargetArtwork({
    required this.target,
    this.size = 48,
    super.key,
  });

  final ProductionTargetView target;
  final double size;

  @override
  Widget build(BuildContext context) {
    final frame = switch (target) {
      BuildingProductionTargetView(:final building) => SpriteFrameId(
        'building.$building',
      ),
      UnitProductionTargetView(:final unit) => SpriteFrameId(
        'unit.${unit.name}.idle.0',
      ),
      WonderProductionTargetView(:final wonder) => SpriteFrameId(
        'wonder.$wonder',
      ),
      ProjectProductionTargetView() => null,
    };
    return ExcludeSemantics(
      child: frame == null
          ? SizedBox.square(
              dimension: size,
              child: const Icon(
                Icons.all_inclusive,
                color: AonwColorTokens.brand,
              ),
            )
          : AonwSpriteThumbnail(key: ValueKey(frame), frame: frame, size: size),
    );
  }
}
