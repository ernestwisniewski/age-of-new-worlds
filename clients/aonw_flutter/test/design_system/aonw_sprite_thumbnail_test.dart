import 'package:aonw_flutter/design_system/assets/sprite_frame_id.dart';
import 'package:aonw_flutter/design_system/assets/sprite_frames.dart';
import 'package:aonw_flutter/design_system/widgets/aonw_sprite_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('thumbnail shares pages, changes frame and releases in idle', (
    tester,
  ) async {
    final owner = SpriteFrames.createScope();
    addTearDown(owner.dispose);
    const mining = SpriteFrameId('technology.mining');
    const agriculture = SpriteFrameId('technology.agriculture');
    await tester.runAsync(() => owner.preload([mining, agriculture]));
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: AonwSpriteThumbnail(frame: mining),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsOneWidget);
    owner.dispose();
    expect(SpriteFrames.debugAtlasBytes['technologies'], 2048 * 1792 * 4);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: AonwSpriteThumbnail(frame: agriculture),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(SpriteFrames.debugAtlasBytes, isNot(contains('technologies')));
    expect(tester.takeException(), isNull);
  });
}
