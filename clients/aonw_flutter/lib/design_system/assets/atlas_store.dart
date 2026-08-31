import 'dart:async';

import 'package:flame/cache.dart';
import 'package:flame_texturepacker/flame_texturepacker.dart';
import 'package:flutter/services.dart';

/// Owns decoded atlas pages and deduplicates concurrent page loads.
final class AtlasStore {
  AtlasStore({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle,
      _images = Images(bundle: bundle ?? rootBundle, prefix: ''),
      _assets = AssetsCache(bundle: bundle ?? rootBundle, prefix: '');

  final AssetBundle _bundle;
  final Images _images;
  final AssetsCache _assets;
  final Map<String, TexturePackerAtlas> _atlases = {};
  final Map<String, Future<TexturePackerAtlas>> _pending = {};
  final Map<String, Set<String>> _pageKeysByAtlas = {};
  final Map<String, int> _atlasGenerations = {};
  var _generation = 0;
  var _disposed = false;

  AssetBundle get bundle => _bundle;

  TexturePackerAtlas? cached(String atlasPath) => _atlases[atlasPath];

  Future<TexturePackerAtlas> load(String atlasPath) async {
    _ensureActive();
    final ready = _atlases[atlasPath];
    if (ready != null) return ready;
    final pending = _pending[atlasPath];
    if (pending != null) return pending;

    final generation = _generation;
    final atlasGeneration = _atlasGenerations[atlasPath] ?? 0;
    final future = _loadAndCache(atlasPath, generation, atlasGeneration);
    _pending[atlasPath] = future;
    try {
      return await future;
    } finally {
      if (identical(_pending[atlasPath], future)) {
        _pending.remove(atlasPath)?.ignore();
      }
    }
  }

  Future<TexturePackerAtlas> _loadAndCache(
    String atlasPath,
    int generation,
    int atlasGeneration,
  ) async {
    final atlas = await TexturePackerAtlas.load(
      atlasPath,
      useOriginalSize: true,
      images: _images,
      assets: _assets,
      assetsPrefix: '',
    );
    final pageKeys = _pageKeys(atlasPath, atlas);
    if (_disposed ||
        generation != _generation ||
        atlasGeneration != (_atlasGenerations[atlasPath] ?? 0)) {
      for (final pageKey in pageKeys) {
        _images.clear(pageKey);
      }
      throw StateError('$atlasPath was disposed while loading');
    }
    _pageKeysByAtlas[atlasPath] = pageKeys;
    return _atlases[atlasPath] = atlas;
  }

  Set<String> _pageKeys(String atlasPath, TexturePackerAtlas atlas) {
    final separator = atlasPath.lastIndexOf('/');
    final parent = separator < 0 ? '' : atlasPath.substring(0, separator);
    return {
      for (final sprite in atlas.sprites)
        parent.isEmpty
            ? sprite.region.page.textureFile
            : '$parent/${sprite.region.page.textureFile}',
    };
  }

  void disposeAtlas(String atlasPath) {
    _ensureActive();
    _atlasGenerations.update(
      atlasPath,
      (generation) => generation + 1,
      ifAbsent: () => 1,
    );
    _atlases.remove(atlasPath);
    _pending.remove(atlasPath)?.ignore();
    for (final pageKey
        in _pageKeysByAtlas.remove(atlasPath) ?? const <String>{}) {
      _images.clear(pageKey);
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation += 1;
    _atlases.clear();
    _pending.clear();
    _pageKeysByAtlas.clear();
    _atlasGenerations.clear();
    _images.clearCache();
  }

  void _ensureActive() {
    if (_disposed) throw StateError('Atlas store is disposed');
  }
}
