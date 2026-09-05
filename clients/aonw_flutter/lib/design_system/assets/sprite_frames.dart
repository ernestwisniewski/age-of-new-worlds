import 'package:flutter/foundation.dart';

import 'sprite_frame_repository.dart';
import 'texture_packer_sprite_frame_repository.dart';

/// Shares generated frames while their owning presentation scopes are alive.
abstract final class SpriteFrames {
  static final _repository = TexturePackerSpriteFrameRepository();

  static SpriteFrameScope createScope() => _repository.createScope();

  @visibleForTesting
  static Map<String, int> get debugAtlasBytes => _repository.atlasBytes;
}
