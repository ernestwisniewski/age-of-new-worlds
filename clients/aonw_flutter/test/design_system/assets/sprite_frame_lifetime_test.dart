import 'dart:ui' as ui;

import 'package:aonw_flutter/design_system/assets/atlas_store.dart';
import 'package:aonw_flutter/design_system/assets/sprite_frame_id.dart';
import 'package:aonw_flutter/design_system/assets/texture_packer_sprite_frame_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/controlled_sprite_bundle.dart';

const _worker = SpriteFrameId('unit.worker.idle.0');
const _walk = SpriteFrameId('unit.worker.walk.1');
const _city = SpriteFrameId('city.growthCivic.0');
const _atlas = 'assets/runtime/sprites/unit_worker/unit_worker.atlas';
const _page = 'assets/runtime/sprites/unit_worker/unit_worker_0.webp';
const _manifest = TexturePackerSpriteFrameRepository.manifestPath;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('scopes share pages until the last user releases the atlas', () async {
    final repository = TexturePackerSpriteFrameRepository();
    addTearDown(repository.dispose);
    final first = repository.createScope();
    final second = repository.createScope();
    final city = repository.createScope();
    final frames = await Future.wait([
      first.load(_worker),
      first.load(_walk),
      second.load(_worker),
      city.load(_city),
    ]);
    expect(frames[0], same(frames[2]));
    expect(frames[0].image, same(frames[1].image));
    expect(repository.atlasBytes['unit_worker'], 1536 * 1536 * 4);
    first.dispose();
    first.dispose();
    expect(first.cached(_worker), isNull);
    expect(second.cached(_worker), same(frames[0]));
    expect(frames[0].image.debugDisposed, isFalse);
    second.dispose();
    expect(frames[0].image.debugDisposed, isTrue);
    expect(repository.atlasBytes, isNot(contains('unit_worker')));
    expect(frames[3].image.debugDisposed, isFalse);
    final replacement = repository.createScope();
    expect(replacement.cached(_worker), isNull);
    final fresh = await replacement.load(_worker);
    expect(fresh.image, isNot(same(frames[0].image)));
    expect(fresh.image.debugDisposed, isFalse);
    replacement.dispose();
    city.dispose();
    expect(repository.atlasBytes, isEmpty);
    await expectLater(first.load(_worker), throwsStateError);
  });

  test(
    'a scope cannot read another owner\'s frame before loading it',
    () async {
      final repository = TexturePackerSpriteFrameRepository();
      addTearDown(repository.dispose);
      final owner = repository.createScope();
      final observer = repository.createScope();
      final frame = await owner.load(_worker);
      expect(observer.cached(_worker), isNull);
      await observer.preload([_worker, _walk]);
      owner.dispose();
      expect(observer.cached(_worker), same(frame));
      observer.dispose();
      expect(frame.image.debugDisposed, isTrue);
    },
  );

  for (final reacquire in [false, true]) {
    test('release during page loading, reacquire=$reacquire', () async {
      final bundle = ControlledSpriteBundle();
      final store = AtlasStore(bundle: bundle);
      final repository = TexturePackerSpriteFrameRepository(store: store);
      addTearDown(repository.dispose);
      final gate = bundle.pause(_page);
      final first = repository.createScope();
      final abandoned = expectLater(first.load(_worker), throwsStateError);
      await gate.started.future;
      first.dispose();
      final next = reacquire ? repository.createScope() : null;
      final nextFrame = next?.load(_worker);
      gate.released.complete();
      await abandoned;
      if (nextFrame != null) {
        final frame = await nextFrame;
        expect(frame.image.debugDisposed, isFalse);
        expect(bundle.reads[_page], 1);
        expect(repository.atlasBytes, contains('unit_worker'));
        next!.dispose();
        expect(frame.image.debugDisposed, isTrue);
      }
      expect(store.cached(_atlas), isNull);
      expect(repository.atlasBytes, isEmpty);
      final fresh = repository.createScope();
      expect((await fresh.load(_worker)).image.debugDisposed, isFalse);
      expect(bundle.reads[_page], 2);
      fresh.dispose();
    });
  }

  test(
    'a disposed scope cannot acquire an atlas after manifest loading',
    () async {
      final bundle = ControlledSpriteBundle();
      final repository = TexturePackerSpriteFrameRepository(
        store: AtlasStore(bundle: bundle),
      );
      addTearDown(repository.dispose);
      final gate = bundle.pause(_manifest);
      final scope = repository.createScope();
      final abandoned = expectLater(scope.load(_worker), throwsStateError);
      await gate.started.future;
      scope.dispose();
      gate.released.complete();
      await abandoned;
      expect(bundle.reads[_atlas], isNull);
      expect(repository.atlasBytes, isEmpty);
    },
  );

  for (final key in [_manifest, _atlas, _page]) {
    test('repository disposal rejects a pending read of $key', () async {
      final bundle = ControlledSpriteBundle();
      final store = AtlasStore(bundle: bundle);
      final repository = TexturePackerSpriteFrameRepository(store: store);
      final gate = bundle.pause(key);
      final scope = repository.createScope();
      final abandoned = expectLater(scope.load(_worker), throwsStateError);
      await gate.started.future;
      repository.dispose();
      scope.dispose();
      gate.released.complete();
      await abandoned;
      expect(store.cached(_atlas), isNull);
      expect(repository.atlasBytes, isEmpty);
      expect(repository.createScope, throwsStateError);
    });
  }

  for (final key in [_manifest, _atlas, _page]) {
    test('failed asset reads can be retried: $key', () async {
      final bundle = ControlledSpriteBundle()..failOnce.add(key);
      final repository = TexturePackerSpriteFrameRepository(
        store: AtlasStore(bundle: bundle),
      );
      addTearDown(repository.dispose);
      final scope = repository.createScope();
      await expectLater(scope.load(_worker), throwsStateError);
      expect((await scope.load(_worker)).image.debugDisposed, isFalse);
      expect(bundle.reads[key], 2);
      scope.dispose();
      expect(repository.atlasBytes, isEmpty);
    });
  }

  test(
    'a late atlas generation cannot dispose its replacement pages',
    () async {
      final bundle = ControlledSpriteBundle();
      final store = AtlasStore(bundle: bundle);
      addTearDown(store.dispose);
      final gate = bundle.pause(_page);
      final abandoned = expectLater(store.load(_atlas), throwsStateError);
      await gate.started.future;
      store.disposeAtlas(_atlas);
      final replacement = await store.load(_atlas);
      final image = replacement.sprites.first.region.page.texture!;
      gate.released.complete();
      await abandoned;
      expect(store.cached(_atlas), same(replacement));
      expect(image.debugDisposed, isFalse);
      store.disposeAtlas(_atlas);
      expect(image.debugDisposed, isTrue);
    },
  );
  test(
    'a decoded page is released when disposal interrupts decoding',
    () async {
      final store = AtlasStore();
      addTearDown(store.dispose);
      final previous = ui.Image.onCreate;
      addTearDown(() => ui.Image.onCreate = previous);
      ui.Image? decoded;
      ui.Image.onCreate = (image) {
        previous?.call(image);
        decoded = image;
        store.disposeAtlas(_atlas);
      };
      await expectLater(store.load(_atlas), throwsStateError);
      expect(decoded, isNotNull);
      expect(decoded!.debugDisposed, isTrue);
      expect(store.cached(_atlas), isNull);
    },
  );
}
