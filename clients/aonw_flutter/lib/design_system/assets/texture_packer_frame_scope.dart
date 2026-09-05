part of 'texture_packer_sprite_frame_repository.dart';

final class _TexturePackerFrameScope implements SpriteFrameScope {
  _TexturePackerFrameScope(this._repository);

  final TexturePackerSpriteFrameRepository _repository;
  final Set<String> _atlases = {};
  var _disposed = false;

  @override
  SpriteFrame? cached(SpriteFrameId id) {
    if (_disposed || _repository._disposed) return null;
    final atlasId = _repository._manifest?.frames[id.value]?.atlasId;
    return _atlases.contains(atlasId) ? _repository._frames[id] : null;
  }

  @override
  Future<SpriteFrame> load(SpriteFrameId id) async {
    _ensureActive();
    return _repository._load(this, id);
  }

  @override
  Future<void> preload(Iterable<SpriteFrameId> ids) async {
    await Future.wait(ids.map(load));
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final atlasId in _atlases) {
      _repository._release(atlasId);
    }
    _atlases.clear();
  }

  void _ensureActive() {
    _repository._ensureActive();
    if (_disposed) throw StateError('Sprite frame scope is disposed');
  }
}
