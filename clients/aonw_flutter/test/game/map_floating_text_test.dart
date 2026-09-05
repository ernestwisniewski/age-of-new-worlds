import 'dart:ui' as ui;

import 'package:aonw_flutter/features/map/read_model/map_feedback_view.dart';
import 'package:aonw_flutter/game/map/map_floating_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Lato',
    )..addFont(rootBundle.load('assets/fonts/Lato-Bold.ttf'))).load();
    await (FontLoader('Cinzel')..addFont(
          rootBundle.load('assets/fonts/Cinzel-VariableFont_wght.ttf'),
        ))
        .load();
  });

  test('renders resource and status text with artifact bubbles', () async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)
      ..drawColor(const ui.Color(0xff202024), ui.BlendMode.src);
    final plain = ['+1 FOOD', '+2 ŻYW +1 PROD', 'KO', 'Odwrót'];
    final bubbles = [
      'Excavate',
      'Artifact carried',
      'Artifact stored',
      'Artefakt przenoszony',
    ];
    for (var index = 0; index < 4; index++) {
      final label = MapFloatingText();
      label.start(
        _cue(color: [0xff86efac, 0xff86efac, 0xfff87171, 0xfffbbf24][index]),
        plain[index],
      );
      label.place(ui.Offset(115 + index * 225.0, 75));
      label.update(0.25);
      label.render(canvas, reducedMotion: false);
      label.clear();
      label.start(_cue(bubble: true), bubbles[index]);
      label.place(ui.Offset(115 + index * 225.0, 175));
      label.update(0.25);
      label.render(canvas, reducedMotion: false);
      label.clear();
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(900, 240);
    picture.dispose();
    await expectLater(
      image,
      matchesGoldenFile('goldens/map_floating_text.png'),
    );
    image.dispose();
  });

  test('reduced motion keeps text fixed and skip frees the raster', () async {
    final text = MapFloatingText()..start(_cue(), '+1 FOOD');
    addTearDown(text.clear);
    text.place(const ui.Offset(100, 70));
    text.update(0.1);
    final before = await _pixels(text, reducedMotion: true);
    text.update(0.6);
    expect(await _pixels(text, reducedMotion: true), orderedEquals(before));
    expect(
      await _pixels(text, reducedMotion: false),
      isNot(orderedEquals(before)),
    );
    text.update(0.39);
    expect(text.active, isFalse);
    expect(text.hasImage, isTrue);
    text.clear();
    expect(text.hasImage, isFalse);
  });

  test(
    'clips text outside the canvas and relabels without restarting',
    () async {
      final text = MapFloatingText()..start(_cue(), '+Road');
      addTearDown(text.clear);
      text.place(const ui.Offset(1000, 1000));
      final outside = await _pixels(text, reducedMotion: true);
      text.place(const ui.Offset(100, 70));
      final english = await _pixels(text, reducedMotion: true);
      expect(english, isNot(orderedEquals(outside)));
      text.update(0.8);
      text.relabel('+Droga');
      expect(
        await _pixels(text, reducedMotion: true),
        isNot(orderedEquals(english)),
      );
      text.update(0.3);
      expect(text.active, isFalse);
    },
  );
}

MapFloatingTextCueView _cue({bool bubble = false, int color = 0xffffd166}) =>
    MapFloatingTextCueView(
      identity: (revision: 1, eventIndex: 0),
      coordinate: (col: 0, row: 0),
      content: const MapMessageTextView(MapFeedbackMessageView.roadCompleted),
      colorValue: color,
      style: bubble
          ? MapFloatingTextStyleView.bubble
          : MapFloatingTextStyleView.plain,
    );

Future<Uint8List> _pixels(
  MapFloatingText text, {
  required bool reducedMotion,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    ..clipRect(const ui.Rect.fromLTWH(0, 0, 220, 140));
  text.render(canvas, reducedMotion: reducedMotion);
  final picture = recorder.endRecording();
  final image = await picture.toImage(220, 140);
  picture.dispose();
  final bytes = await image.toByteData();
  image.dispose();
  return bytes!.buffer.asUint8List();
}
