import '../../design_system/assets/sprite_frame_id.dart';
import '../../features/map/read_model/pending_action_view.dart';
import '../../features/map/read_model/player_map_view.dart';

enum MapCitySpriteProfile {
  growthCivic,
  tradeKnowledgeMaritime,
  militaryFortified,
  industryModern,
}

final class MapUnitSpriteMetrics {
  const MapUnitSpriteMetrics({required this.width, required this.height});

  final double width;
  final double height;
}

abstract final class MapSpriteCatalog {
  static const unitFrameCount = 6;
  static const cityVisualLevelCount = 6;
  static const improvementEraCount = 4;

  static const _normalUnit = MapUnitSpriteMetrics(width: 64, height: 86);
  static const _wideUnit = MapUnitSpriteMetrics(width: 76, height: 72);

  static SpriteSequenceId idleUnitSequence(VisibleUnitKind kind) =>
      SpriteSequenceId('unit.${kind.name}.idle');

  static Iterable<SpriteFrameId> idleUnitFrames(VisibleUnitKind kind) sync* {
    final sequence = idleUnitSequence(kind);
    for (var index = 0; index < unitFrameCount; index += 1) {
      yield sequence.frame(index);
    }
  }

  static MapUnitSpriteMetrics unitMetrics(VisibleUnitKind kind) {
    return switch (kind) {
      VisibleUnitKind.catapult ||
      VisibleUnitKind.fieldCannon ||
      VisibleUnitKind.tank ||
      VisibleUnitKind.scoutShip ||
      VisibleUnitKind.warship ||
      VisibleUnitKind.reconPlane => _wideUnit,
      _ => _normalUnit,
    };
  }

  static SpriteFrameId cityFrame({
    required int visualLevel,
    MapCitySpriteProfile profile = MapCitySpriteProfile.growthCivic,
  }) {
    final level = visualLevel.clamp(0, cityVisualLevelCount - 1);
    return SpriteFrameId('city.${profile.name}.$level');
  }

  static int cityVisualLevel(int population) {
    if (population >= 14) return 5;
    if (population >= 10) return 4;
    if (population >= 8) return 3;
    if (population >= 6) return 2;
    if (population >= 4) return 1;
    return 0;
  }

  static SpriteFrameId improvementFrame(
    FieldImprovementKind kind, {
    int era = 0,
  }) {
    final column = era.clamp(0, improvementEraCount - 1);
    return SpriteFrameId('improvement.${kind.name}.$column');
  }
}
