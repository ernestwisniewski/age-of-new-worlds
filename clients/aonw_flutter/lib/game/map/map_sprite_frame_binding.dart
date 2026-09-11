import 'dart:async';

import '../../design_system/assets/sprite_frame_id.dart';
import '../../design_system/assets/sprite_frame_repository.dart';
import '../../design_system/assets/sprite_frames.dart';

/// Retains a sprite atlas only while its component is near the camera clip.
final class MapSpriteFrameBinding {
  MapSpriteFrameBinding({
    required SpriteFrameId id,
    required this.onLoaded,
    SpriteFrameScope Function()? createScope,
  }) : _id = id,
       _createScope = createScope ?? SpriteFrames.createScope;

  final void Function() onLoaded;
  final SpriteFrameScope Function() _createScope;
  SpriteFrameId _id;
  SpriteFrameScope? _scope;
  SpriteFrame? _frame;
  var _visible = false;
  var _disposed = false;
  var _generation = 0;

  SpriteFrame? get frame => _frame;
  bool get visible => _visible;

  void setVisible(bool value) {
    if (_disposed || value == _visible) return;
    _visible = value;
    if (value) {
      unawaited(_load());
    } else {
      _release();
    }
  }

  void replaceFrame(SpriteFrameId id, {bool releaseAtlas = false}) {
    if (_disposed || id == _id) return;
    _id = id;
    _frame = null;
    _generation++;
    if (releaseAtlas) _release();
    if (_visible) unawaited(_load());
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final scope = _scope ??= _createScope();
    try {
      final loaded = await scope.load(_id);
      if (_disposed || !_visible || generation != _generation) return;
      _frame = loaded;
      onLoaded();
    } on Object {
      // The component keeps its vector fallback when an asset is unavailable.
    }
  }

  void _release() {
    _generation++;
    _frame = null;
    _scope?.dispose();
    _scope = null;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _visible = false;
    _release();
  }
}
