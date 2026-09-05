import 'dart:ui' as ui;

import 'package:aonw_flutter/game/map/map_combat_feedback.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Lato')
      ..addFont(rootBundle.load('assets/fonts/Lato-Bold.ttf'));
    await loader.load();
  });

  test(
    'renders accepted damage and city embers with readable damage labels',
    () async {
      final feedback = MapCombatFeedback();
      addTearDown(feedback.dispose);
      _start(feedback);
      expect(feedback.labelCount, 2);
      expect(feedback.particleCount, 34);
      final image = await _render(feedback, 0.23);
      await expectLater(
        image,
        matchesGoldenFile('goldens/map_combat_feedback.png'),
      );
      image.dispose();
    },
  );

  test(
    'reduced motion preserves readable static damage without particles',
    () async {
      final feedback = MapCombatFeedback();
      addTearDown(feedback.dispose);
      _start(feedback);
      feedback.clearParticles();
      expect(feedback.labelCount, 2);
      expect(feedback.particleCount, 0);
      final early = await _render(feedback, 0.1, reducedMotion: true);
      final late = await _render(feedback, 0.9, reducedMotion: true);
      expect(
        (await early.toByteData())!.buffer.asUint8List(),
        (await late.toByteData())!.buffer.asUint8List(),
      );
      await expectLater(
        early,
        matchesGoldenFile('goldens/map_combat_feedback_reduced.png'),
      );
      early.dispose();
      late.dispose();
    },
  );

  test('expires damage and particles and clears state before reuse', () async {
    final feedback = MapCombatFeedback();
    addTearDown(feedback.dispose);
    _start(feedback);
    final expired = await _render(feedback, 1.08);
    feedback.clear();
    final empty = await _render(feedback, 0);
    expect(
      (await expired.toByteData())!.buffer.asUint8List(),
      (await empty.toByteData())!.buffer.asUint8List(),
    );
    expired.dispose();
    empty.dispose();
    _start(feedback, damage: 0, retaliation: 0);
    expect(feedback.labelCount, 0);
    expect(feedback.particleCount, 0);
    _start(feedback, killed: true);
    expect(feedback.particleCount, 62);
    _start(feedback);
    expect(feedback.particleCount, 34);
  });
}

void _start(
  MapCombatFeedback feedback, {
  int damage = 7,
  int retaliation = 2,
  bool killed = false,
}) => feedback.start(
  attacker: const ui.Offset(65, 120),
  defender: const ui.Offset(210, 150),
  outgoingDamage: damage,
  retaliationDamage: retaliation,
  attackerKilled: killed,
  defenderKilled: false,
  defenderIsCity: true,
  seed: 7,
);

Future<ui.Image> _render(
  MapCombatFeedback feedback,
  double elapsed, {
  bool reducedMotion = false,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    ..drawColor(const ui.Color(0xff202024), ui.BlendMode.src);
  feedback.render(canvas, elapsed, reducedMotion: reducedMotion);
  final picture = recorder.endRecording();
  final image = await picture.toImage(320, 220);
  picture.dispose();
  return image;
}
