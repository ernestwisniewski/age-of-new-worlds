import 'dart:async';
import 'dart:ui' as ui;

import 'package:aonw_flutter/design_system/assets/atlas_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _path = 'assets/runtime/sprites/cities_level_0/cities_level_0.atlas';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('uses bundle buffers without a Dart byte-array page read', () async {
    final bundle = _BufferBundle();
    final store = AtlasStore(bundle: bundle);
    addTearDown(store.dispose);
    final atlas = await store.load(_path);
    expect(bundle.buffers, hasLength(1));
    expect(bundle.buffers.single.debugDisposed, isTrue);
    final image = atlas.sprites.first.region.page.texture!;
    expect(image.debugDisposed, isFalse);
    expect(store.decodedBytes(_path), 2674944);
    store.disposeAtlas(_path);
    expect(image.debugDisposed, isTrue);
  });

  test(
    'disposal while a native buffer loads releases the arriving buffer',
    () async {
      final bundle = _BufferBundle(paused: true);
      final store = AtlasStore(bundle: bundle);
      final load = expectLater(store.load(_path), throwsStateError);
      await bundle.started.future;
      store.dispose();
      bundle.release.complete();
      await load;
      expect(bundle.buffers.single.debugDisposed, isTrue);
    },
  );
}

final class _BufferBundle extends AssetBundle {
  _BufferBundle({this.paused = false});

  final bool paused;
  final buffers = <ui.ImmutableBuffer>[];
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<ByteData> load(String key) =>
      throw StateError('Atlas pages must use loadBuffer');

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      rootBundle.loadString(key, cache: cache);

  @override
  Future<ui.ImmutableBuffer> loadBuffer(String key) async {
    final buffer = await rootBundle.loadBuffer(key);
    buffers.add(buffer);
    started.complete();
    if (paused) await release.future;
    return buffer;
  }
}
