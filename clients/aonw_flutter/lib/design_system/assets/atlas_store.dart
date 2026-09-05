import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame_texturepacker/flame_texturepacker.dart';
import 'package:flutter/painting.dart' show decodeImageFromList;
import 'package:flutter/services.dart';

/// Owns each atlas generation's pages and deduplicates concurrent loads.
final class AtlasStore {
  AtlasStore({AssetBundle? bundle}) : bundle = bundle ?? rootBundle;

  final AssetBundle bundle;
  final Map<String, _AtlasEntry> _entries = {};
  var _disposed = false;

  TexturePackerAtlas? cached(String atlasPath) => _entries[atlasPath]?.atlas;

  int decodedBytes(String atlasPath) {
    final atlas = cached(atlasPath);
    if (atlas == null) return 0;
    final pages = <ui.Image>{
      for (final sprite in atlas.sprites) sprite.region.page.texture!,
    };
    return pages.fold(0, (bytes, page) => bytes + page.width * page.height * 4);
  }

  Future<TexturePackerAtlas> load(String atlasPath) async {
    _ensureActive();
    final entry = _entries.putIfAbsent(
      atlasPath,
      () => _AtlasEntry(atlasPath, bundle),
    );
    try {
      return await entry.load();
    } catch (_) {
      if (identical(_entries[atlasPath], entry)) _entries.remove(atlasPath);
      entry.dispose();
      rethrow;
    }
  }

  void disposeAtlas(String atlasPath) {
    _ensureActive();
    _entries.remove(atlasPath)?.dispose();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final entry in _entries.values) {
      entry.dispose();
    }
    _entries.clear();
  }

  void _ensureActive() {
    if (_disposed) throw StateError('Atlas store is disposed');
  }
}

final class _AtlasEntry {
  _AtlasEntry(this.path, this.bundle)
    : _assets = AssetsCache(bundle: bundle, prefix: '');

  final String path;
  final AssetBundle bundle;
  final AssetsCache _assets;
  final Set<ui.Image> _pages = {};
  TexturePackerAtlas? atlas;
  Future<TexturePackerAtlas>? _pending;
  var _disposed = false;

  Future<TexturePackerAtlas> load() => _pending ??= _read();

  Future<TexturePackerAtlas> _read() async {
    try {
      final data = await TexturePackerAtlas.loadAtlas(
        path,
        loadImages: false,
        assets: _assets,
        assetsPrefix: '',
      );
      _ensureActive();
      final parent = path.substring(0, path.lastIndexOf('/') + 1);
      for (final page in data.pages) {
        page.texture = await _loadPage('$parent${page.textureFile}');
      }
      return atlas = TexturePackerAtlas.fromAtlas(data, useOriginalSize: true);
    } finally {
      // Metadata can finish after disposal cleared its pending cache entry.
      if (_disposed) _assets.clearCache();
    }
  }

  Future<ui.Image> _loadPage(String pagePath) async {
    final data = await bundle.load(pagePath);
    _ensureActive();
    final image = await decodeImageFromList(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    if (_disposed) {
      image.dispose();
      _ensureActive();
    }
    _pages.add(image);
    return image;
  }

  void _ensureActive() {
    if (_disposed) throw StateError('$path was disposed while loading');
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    atlas = null;
    for (final page in _pages) {
      page.dispose();
    }
    _pages.clear();
    _assets.clearCache();
  }
}
