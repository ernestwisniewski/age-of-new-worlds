import 'sprite_frame_id.dart';
import 'sprite_frame_repository.dart';
import 'texture_packer_sprite_frame_repository.dart';

/// Process-scoped access to immutable generated sprite data.
abstract final class SpriteFrames {
  static final SpriteFrameRepository _repository =
      TexturePackerSpriteFrameRepository();

  static SpriteFrame? cached(SpriteFrameId id) => _repository.cached(id);

  static Future<SpriteFrame> load(SpriteFrameId id) => _repository.load(id);

  static Future<void> preload(Iterable<SpriteFrameId> ids) =>
      _repository.preload(ids);
}
