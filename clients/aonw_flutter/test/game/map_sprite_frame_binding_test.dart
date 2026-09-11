import 'dart:async';
import 'dart:ui' as ui;

import 'package:aonw_flutter/design_system/assets/sprite_frame_id.dart';
import 'package:aonw_flutter/design_system/assets/sprite_frame_repository.dart';
import 'package:aonw_flutter/game/map/map_sprite_frame_binding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'invisible sprites stay cold and reject loads after leaving the clip',
    () async {
      final image = await createTestImage(cache: false);
      addTearDown(image.dispose);
      final scopes = <_Scope>[];
      var loaded = 0;
      final binding = MapSpriteFrameBinding(
        id: const SpriteFrameId('city.first'),
        onLoaded: () => loaded++,
        createScope: () {
          final scope = _Scope();
          scopes.add(scope);
          return scope;
        },
      );
      addTearDown(binding.dispose);
      expect(scopes, isEmpty);
      binding.setVisible(true);
      expect(scopes, hasLength(1));
      binding.setVisible(false);
      expect(scopes.first.disposed, isTrue);
      scopes.first.requests.single.complete(_frame(image));
      await Future<void>.delayed(Duration.zero);
      expect(binding.frame, isNull);
      expect(loaded, 0);
      binding.setVisible(true);
      scopes.last.requests.single.complete(_frame(image));
      await Future<void>.delayed(Duration.zero);
      expect(binding.frame, isNotNull);
      expect(loaded, 1);
      binding.setVisible(true);
      expect(scopes, hasLength(2));
      binding.dispose();
      expect(scopes.last.disposed, isTrue);
      expect(binding.frame, isNull);
    },
  );

  test(
    'frame changes reject earlier results and preserve the current scope',
    () async {
      final image = await createTestImage(cache: false);
      addTearDown(image.dispose);
      final scope = _Scope();
      final binding = MapSpriteFrameBinding(
        id: const SpriteFrameId('city.first'),
        onLoaded: () {},
        createScope: () => scope,
      );
      addTearDown(binding.dispose);
      binding.setVisible(true);
      binding.replaceFrame(const SpriteFrameId('city.second'));
      scope.requests.first.complete(_frame(image));
      await Future<void>.delayed(Duration.zero);
      expect(binding.frame, isNull);
      final latest = _frame(image, 'city.second');
      scope.requests.last.complete(latest);
      await Future<void>.delayed(Duration.zero);
      expect(binding.frame, same(latest));
      expect(scope.disposed, isFalse);
    },
  );
}

SpriteFrame _frame(ui.Image image, [String id = 'city.first']) => SpriteFrame(
  id: SpriteFrameId(id),
  image: image,
  source: const ui.Rect.fromLTWH(0, 0, 1, 1),
  originalSize: const ui.Size(1, 1),
  trimOffset: ui.Offset.zero,
  pivot: ui.Offset.zero,
  contentBounds: const ui.Rect.fromLTWH(0, 0, 1, 1),
  statusTop: 0,
);

final class _Scope implements SpriteFrameScope {
  final requests = <Completer<SpriteFrame>>[];
  var disposed = false;
  @override
  SpriteFrame? cached(SpriteFrameId id) => null;
  @override
  Future<SpriteFrame> load(SpriteFrameId id) {
    final request = Completer<SpriteFrame>();
    requests.add(request);
    return request.future;
  }

  @override
  Future<void> preload(Iterable<SpriteFrameId> ids) async {
    await Future.wait(ids.map(load));
  }

  @override
  void dispose() => disposed = true;
}
