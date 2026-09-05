import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flame_texturepacker/flame_texturepacker.dart';

import 'atlas_store.dart';
import 'sprite_frame_id.dart';
import 'sprite_frame_repository.dart';

part 'texture_packer_frame_scope.dart';
part 'texture_packer_sprite_manifest.dart';

final class TexturePackerSpriteFrameRepository
    implements SpriteFrameRepository {
  TexturePackerSpriteFrameRepository({AtlasStore? store})
    : _store = store ?? AtlasStore();

  static const manifestPath = 'assets/runtime/sprites/sprite_manifest.json';
  final AtlasStore _store;
  final Map<SpriteFrameId, SpriteFrame> _frames = {};
  final Map<SpriteFrameId, Future<SpriteFrame>> _pendingFrames = {};
  final Map<String, int> _owners = {};
  final Map<String, int> _readers = {};
  Future<_SpriteManifest>? _pendingManifest;
  _SpriteManifest? _manifest;
  var _disposed = false;

  Map<String, int> get atlasBytes => {
    for (final entry
        in _manifest?.atlases.entries ?? const <MapEntry<String, String>>[])
      if (_store.cached(entry.value) != null)
        entry.key: _store.decodedBytes(entry.value),
  };

  @override
  SpriteFrameScope createScope() {
    _ensureActive();
    return _TexturePackerFrameScope(this);
  }

  Future<SpriteFrame> _load(
    _TexturePackerFrameScope scope,
    SpriteFrameId id,
  ) async {
    final manifest = await _loadManifest();
    scope._ensureActive();
    final entry = manifest.frames[id.value];
    if (entry == null) {
      throw StateError('Missing sprite frame manifest entry: ${id.value}');
    }
    if (scope._atlases.add(entry.atlasId)) {
      _owners.update(entry.atlasId, (count) => count + 1, ifAbsent: () => 1);
    }
    final ready = _frames[id];
    if (ready != null) return ready;
    final future = _pendingFrames[id] ??= _readFrame(id, entry, manifest);
    try {
      final frame = await future;
      scope._ensureActive();
      return frame;
    } finally {
      if (identical(_pendingFrames[id], future)) _pendingFrames.remove(id);
    }
  }

  Future<SpriteFrame> _readFrame(
    SpriteFrameId id,
    _SpriteManifestEntry entry,
    _SpriteManifest manifest,
  ) async {
    final atlasId = entry.atlasId;
    _readers.update(atlasId, (count) => count + 1, ifAbsent: () => 1);
    try {
      final path = manifest.atlases[atlasId];
      if (path == null) {
        throw StateError('Missing atlas $atlasId for ${id.value}');
      }
      final atlas = await _store.load(path);
      _ensureActive();
      final sprite = atlas.findSpriteByNameIndex(entry.region, entry.index);
      if (sprite == null) {
        throw StateError(
          'Missing region ${entry.region}#${entry.index} in $path',
        );
      }
      return _frames[id] = _frameFromSprite(id, sprite, entry);
    } finally {
      _pendingFrames.remove(id);
      final readers = _readers[atlasId]! - 1;
      if (readers == 0) {
        _readers.remove(atlasId);
      } else {
        _readers[atlasId] = readers;
      }
      _evictUnowned(atlasId);
    }
  }

  void _release(String atlasId) {
    if (_disposed) return;
    final count = _owners[atlasId]! - 1;
    if (count == 0) {
      _owners.remove(atlasId);
    } else {
      _owners[atlasId] = count;
    }
    _evictUnowned(atlasId);
  }

  void _evictUnowned(String atlasId) {
    if (_disposed ||
        _owners.containsKey(atlasId) ||
        _readers.containsKey(atlasId)) {
      return;
    }
    final manifest = _manifest!;
    _frames.removeWhere(
      (id, _) => manifest.frames[id.value]?.atlasId == atlasId,
    );
    final path = manifest.atlases[atlasId];
    if (path != null) _store.disposeAtlas(path);
  }

  Future<_SpriteManifest> _loadManifest() async {
    _ensureActive();
    if (_manifest case final manifest?) return manifest;
    final future = _pendingManifest ??= _readManifest();
    try {
      final manifest = await future;
      _ensureActive();
      return _manifest = manifest;
    } finally {
      if (identical(_pendingManifest, future)) _pendingManifest = null;
    }
  }

  SpriteFrame _frameFromSprite(
    SpriteFrameId id,
    TexturePackerSprite sprite,
    _SpriteManifestEntry entry,
  ) {
    final region = sprite.region;
    final originalWidth = region.originalWidth;
    final originalHeight = region.originalHeight;
    final trimTop = originalHeight - region.offsetY - region.height;
    return SpriteFrame(
      id: id,
      image: region.page.texture!,
      source: ui.Rect.fromLTWH(
        region.left,
        region.top,
        region.width,
        region.height,
      ),
      originalSize: ui.Size(originalWidth, originalHeight),
      trimOffset: ui.Offset(region.offsetX, trimTop),
      pivot: ui.Offset(originalWidth / 2, originalHeight),
      contentBounds:
          entry.contentBounds ??
          ui.Rect.fromLTWH(0, 0, originalWidth, originalHeight),
      statusTop: entry.statusTop ?? 0,
    );
  }

  Future<_SpriteManifest> _readManifest() async {
    final json = jsonDecode(await _store.bundle.loadString(manifestPath));
    if (json is! Map<String, dynamic> || json['version'] != 1) {
      throw const FormatException('Unsupported sprite manifest');
    }
    final atlases = json['atlases'];
    final frames = json['frames'];
    if (atlases is! Map<String, dynamic> || frames is! Map<String, dynamic>) {
      throw const FormatException('Invalid sprite manifest structure');
    }
    return _SpriteManifest(
      atlases: {
        for (final entry in atlases.entries)
          entry.key: _bundledAtlasPath(entry.key, entry.value),
      },
      frames: {
        for (final entry in frames.entries)
          entry.key: _SpriteManifestEntry.fromJson(
            entry.value as Map<String, dynamic>,
          ),
      },
    );
  }

  static String _bundledAtlasPath(String atlasId, Object? value) {
    final validAtlasId = RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(atlasId);
    final expectedPath = 'assets/runtime/sprites/$atlasId/$atlasId.atlas';
    if (!validAtlasId || value is! String || value != expectedPath) {
      throw FormatException('Invalid path for sprite atlas $atlasId: $value');
    }
    return value;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _frames.clear();
    _owners.clear();
    _manifest = null;
    _pendingManifest = null;
    _store.dispose();
  }

  void _ensureActive() {
    if (_disposed) throw StateError('Sprite frame repository is disposed');
  }
}
