import 'dart:ui' as ui;

import 'package:aonw_flutter/game/map/map_path_regions.dart';
import 'package:flutter_test/flutter_test.dart';

import 'map_path_regions_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final index in [0, 1, 2, 3]) {
    test(
      'regional layer $index retains pixels and skips offscreen paths',
      () async {
        final fixture = regionalPathComparisons()[index];
        final builds = fixture.builds();
        for (final zoom in [0.2, 0.5, 1.0, 2.75, 5.0]) {
          for (final center in [
            const ui.Offset(512.3, 512.7),
            const ui.Offset(1024.1, 1023.9),
            const ui.Offset(3600, 1800),
          ]) {
            final clip = ui.Rect.fromCenter(
              center: center,
              width: 240 / zoom,
              height: 180 / zoom,
            );
            final actual = await _pixels(clip, zoom, fixture.actual);
            final expected = await _pixels(clip, zoom, fixture.expected);
            _compare(actual, expected, '${fixture.name}: $clip at $zoom');
            expect(fixture.rendered(), inInclusiveRange(1, 16));
            expect(fixture.builds(), builds);
          }
        }
        await _pixels(
          const ui.Rect.fromLTWH(-1000, -1000, 240, 180),
          1,
          fixture.actual,
        );
        expect(fixture.rendered(), 0);
        expect(fixture.builds(), builds);
      },
    );
  }

  test(
    'visible batches deduplicate paths and rebuild only across regions',
    () async {
      final shared = ui.Path()
        ..addRect(const ui.Rect.fromLTWH(490, 490, 44, 44));
      final builder = MapPathRegionBuilder<int>()
        ..add(0, shared)
        ..add(
          0,
          ui.Path()..addRect(const ui.Rect.fromLTWH(7000, 7000, 30, 30)),
        );
      final regions = builder.build();
      final paint = ui.Paint()..color = const ui.Color(0x80ffffff);
      void draw(ui.Canvas canvas) =>
          renderMapPathRegions(canvas, regions, [(0, paint)]);
      const clip = ui.Rect.fromLTWH(500, 500, 24, 24);
      final actual = await _pixels(clip, 5, draw);
      final expected = await _pixels(
        clip,
        5,
        (canvas) => canvas.drawPath(shared, paint),
      );
      expect(actual, expected);
      expect(regions.selectedPathCount, 1);
      expect(regions.totalPathCount, 2);
      expect(regions.batchBuildCount, 1);
      await _pixels(clip.shift(const ui.Offset(1, 1)), 5, draw);
      expect(regions.batchBuildCount, 1);
      await _pixels(const ui.Rect.fromLTWH(7000, 7000, 24, 24), 5, draw);
      expect(regions.selectedPathCount, 1);
      expect(regions.batchBuildCount, 2);
      await _pixels(const ui.Rect.fromLTWH(-7000, -7000, 24, 24), 5, draw);
      expect(regions.selectedPathCount, 0);
      expect(regions.batchBuildCount, 3);
      await _pixels(clip, 5, draw);
      expect(regions.selectedPathCount, 1);
      expect(regions.batchBuildCount, 4);
    },
  );
}

void _compare(List<int> actual, List<int> expected, String reason) {
  var maximum = 0;
  var total = 0;
  var changed = 0;
  for (var i = 0; i < actual.length; i++) {
    final difference = (actual[i] - expected[i]).abs();
    total += difference;
    if (difference > 1) changed++;
    if (difference > maximum) maximum = difference;
  }
  final summary =
      '$reason: mean ${total / actual.length}, '
      'changed ${changed / actual.length}, max $maximum';
  // Ordered complete paths preserve coverage; only channel rounding may differ.
  expect(total / actual.length, lessThan(0.0001), reason: summary);
  expect(changed, 0, reason: summary);
  expect(maximum, lessThanOrEqualTo(1), reason: summary);
}

Future<List<int>> _pixels(
  ui.Rect clip,
  double zoom,
  void Function(ui.Canvas) draw,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    ..drawColor(const ui.Color(0xff808080), ui.BlendMode.src)
    ..scale(zoom)
    ..translate(-clip.left, -clip.top)
    ..clipRect(clip);
  draw(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(240, 180);
  picture.dispose();
  final bytes = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  return bytes;
}
