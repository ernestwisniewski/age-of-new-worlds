import 'dart:ui' as ui;

import 'package:aonw_flutter/design_system/assets/sprite_frames.dart';
import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/workers/read_model/worker_view.dart';
import 'package:aonw_flutter/game/map/city_map_layer.dart';
import 'package:aonw_flutter/game/map/map_sprite_catalog.dart';
import 'package:aonw_flutter/game/map/worker_infrastructure_layer.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('changing city level releases the previous level page', () async {
    final warm = SpriteFrames.createScope();
    addTearDown(warm.dispose);
    await warm.load(MapSpriteCatalog.cityFrame(visualLevel: 0));
    final city = MapCityComponent(
      city: testCityView(population: 1),
      actorPlayerId: 'preview-player',
      center: ui.Offset.zero,
    );
    addTearDown(city.disposePresentation);
    _render(city.render);
    await Future<void>.delayed(Duration.zero);
    final previous = city.debugSpriteFrame!.image;
    warm.dispose();
    expect(previous.debugDisposed, isFalse);
    city.applyCity(
      testCityView(population: 6),
      actorPlayerId: 'preview-player',
      center: ui.Offset.zero,
    );
    expect(previous.debugDisposed, isTrue);
    city.disposePresentation();
  });

  test('changing improvement era releases the previous era page', () async {
    final warm = SpriteFrames.createScope();
    addTearDown(warm.dispose);
    await warm.load(
      MapSpriteCatalog.improvementFrame(FieldImprovementKind.farm),
    );
    final improvement = MapFieldImprovementComponent(
      improvement: _farm(0),
      center: ui.Offset.zero,
      selected: false,
    );
    addTearDown(improvement.disposePresentation);
    _render(improvement.render);
    await Future<void>.delayed(Duration.zero);
    final previous = improvement.debugSpriteFrame!.image;
    warm.dispose();
    expect(previous.debugDisposed, isFalse);
    improvement.applyImprovement(_farm(1), ui.Offset.zero);
    expect(previous.debugDisposed, isTrue);
    improvement.disposePresentation();
  });
}

FieldImprovementView _farm(int era) => FieldImprovementView(
  coordinate: (col: 1, row: 1),
  improvement: FieldImprovementKind.farm,
  eraColumn: era,
);

void _render(void Function(ui.Canvas) render) {
  final recorder = ui.PictureRecorder();
  render(ui.Canvas(recorder));
  recorder.endRecording().dispose();
}
