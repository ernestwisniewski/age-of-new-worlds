import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flame_texturepacker/flame_texturepacker.dart';

import 'atlas_store.dart';
import 'sprite_frame_id.dart';
import 'sprite_frame_repository.dart';

final class TexturePackerSpriteFrameRepository
    implements SpriteFrameRepository {
  TexturePackerSpriteFrameRepository({AtlasStore? store})
    : _store = store ?? AtlasStore();

  static const manifestPath = 'assets/runtime/sprites/sprite_manifest.json';

  final AtlasStore _store;
  final Map<SpriteFrameId, SpriteFrame> _frames = {};
  final Map<SpriteFrameId, Future<SpriteFrame>> _pendingFrames = {};
  Future<_SpriteManifest>? _pendingManifest;
  _SpriteManifest? _manifest;
  var _generation = 0;
  var _disposed = false;

  @override
  SpriteFrame? cached(SpriteFrameId id) {
    _ensureActive();
    return _frames[id];
  }

  @override
  Future<SpriteFrame> load(SpriteFrameId id) async {
    _ensureActive();
    final ready = _frames[id];
    if (ready != null) return ready;
    final pending = _pendingFrames[id];
    if (pending != null) return pending;

    final generation = _generation;
    final future = _loadAndCache(id, generation);
    _pendingFrames[id] = future;
    try {
      return await future;
    } finally {
      if (identical(_pendingFrames[id], future)) {
        _pendingFrames.remove(id)?.ignore();
      }
    }
  }

  Future<SpriteFrame> _loadAndCache(SpriteFrameId id, int generation) async {
    final frame = await _load(id);
    if (_disposed || generation != _generation) {
      throw StateError('${id.value} was disposed while loading');
    }
    return _frames[id] = frame;
  }

  Future<SpriteFrame> _load(SpriteFrameId id) async {
    final manifest = await _loadManifest();
    final entry = manifest.frames[id.value];
    if (entry == null) {
      throw StateError('Missing sprite frame manifest entry: ${id.value}');
    }
    final atlasPath = manifest.atlases[entry.atlasId];
    if (atlasPath == null) {
      throw StateError('Missing atlas ${entry.atlasId} for ${id.value}');
    }
    final atlas = await _store.load(atlasPath);
    final sprite = atlas.findSpriteByNameIndex(entry.region, entry.index);
    if (sprite == null) {
      throw StateError(
        'Missing region ${entry.region}#${entry.index} in $atlasPath',
      );
    }
    return _frameFromSprite(id, sprite, entry);
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

  Future<_SpriteManifest> _loadManifest() async {
    _ensureActive();
    final ready = _manifest;
    if (ready != null) return ready;
    final pending = _pendingManifest;
    if (pending != null) return pending;
    final generation = _generation;
    final future = _readAndCacheManifest(generation);
    _pendingManifest = future;
    try {
      return await future;
    } finally {
      if (identical(_pendingManifest, future)) _pendingManifest = null;
    }
  }

  Future<_SpriteManifest> _readAndCacheManifest(int generation) async {
    final manifest = await _readManifest();
    if (_disposed || generation != _generation) {
      throw StateError('Sprite manifest was disposed while loading');
    }
    return _manifest = manifest;
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
  Future<void> preload(Iterable<SpriteFrameId> ids) async {
    _ensureActive();
    await Future.wait(ids.map(load));
  }

  @override
  void disposeAtlas(String atlasId) {
    _ensureActive();
    _generation += 1;
    _pendingFrames.clear();
    _pendingManifest = null;
    final manifest = _manifest;
    final atlasPath = manifest?.atlases[atlasId];
    if (atlasPath == null) return;
    _frames.removeWhere(
      (id, _) => manifest!.frames[id.value]?.atlasId == atlasId,
    );
    _store.disposeAtlas(atlasPath);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation += 1;
    _frames.clear();
    _pendingFrames.clear();
    _manifest = null;
    _pendingManifest = null;
    _store.dispose();
  }

  void _ensureActive() {
    if (_disposed) throw StateError('Sprite frame repository is disposed');
  }
}

final class _SpriteManifest {
  const _SpriteManifest({required this.atlases, required this.frames});

  final Map<String, String> atlases;
  final Map<String, _SpriteManifestEntry> frames;
}

final class _SpriteManifestEntry {
  const _SpriteManifestEntry({
    required this.atlasId,
    required this.region,
    required this.index,
    required this.contentBounds,
    required this.statusTop,
  });

  factory _SpriteManifestEntry.fromJson(Map<String, dynamic> json) {
    return _SpriteManifestEntry(
      atlasId: json['atlas'] as String,
      region: json['region'] as String,
      index: json['index'] as int,
      contentBounds: _contentBoundsFromJson(json['content']),
      statusTop: (json['statusTop'] as num?)?.toDouble(),
    );
  }

  final String atlasId;
  final String region;
  final int index;
  final ui.Rect? contentBounds;
  final double? statusTop;

  static ui.Rect? _contentBoundsFromJson(Object? value) {
    if (value is! List || value.length != 4) return null;
    final numbers = value.cast<num>();
    return ui.Rect.fromLTWH(
      numbers[0].toDouble(),
      numbers[1].toDouble(),
      numbers[2].toDouble(),
      numbers[3].toDouble(),
    );
  }
}
